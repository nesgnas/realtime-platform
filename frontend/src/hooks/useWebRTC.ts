import { useCallback, useEffect, useRef, useState } from 'react'
import type { Channel } from 'phoenix'
import type { Signal } from '../types'

const iceServers: RTCIceServer[] = JSON.parse(import.meta.env.VITE_ICE_SERVERS || '[{"urls":"stun:stun.l.google.com:19302"}]')
export function useWebRTC(channel: Channel | null, video: boolean, initiator: boolean, onEnded: () => void) {
  const peer = useRef<RTCPeerConnection | null>(null), local = useRef<MediaStream | null>(null)
  const peerPresent = useRef(false), pendingCandidates = useRef<RTCIceCandidateInit[]>([])
  const [remote, setRemote] = useState<MediaStream | null>(null), [localStream, setLocalStream] = useState<MediaStream | null>(null)
  const [muted, setMuted] = useState(false), [cameraOff, setCameraOff] = useState(!video), [sharing, setSharing] = useState(false)
  const send = useCallback((signal: { type: 'offer' | 'answer'; sdp: RTCSessionDescriptionInit } | { type: 'ice'; candidate: RTCIceCandidateInit } | { type: 'hangup' }) => channel?.push('signal', signal), [channel])
  const ensurePeer = useCallback(() => {
    if (peer.current) return peer.current
    const pc = new RTCPeerConnection({ iceServers }); pc.onicecandidate = e => e.candidate && send({ type: 'ice', candidate: e.candidate.toJSON() }); pc.ontrack = e => setRemote(e.streams[0]); peer.current = pc; return pc
  }, [send])
  const makeOffer = useCallback(async () => { const pc = ensurePeer(); const sdp = await pc.createOffer(); await pc.setLocalDescription(sdp); send({ type: 'offer', sdp }) }, [ensurePeer, send])
  const start = useCallback(async () => { const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video }); local.current = stream; setLocalStream(stream); const pc = ensurePeer(); stream.getTracks().forEach(track => pc.addTrack(track, stream)); if (initiator && peerPresent.current) await makeOffer() }, [ensurePeer, initiator, makeOffer, video])
  useEffect(() => {
    if (!channel) return
    const handle = async (raw: unknown) => { const signal = raw as Signal; if (signal.type === 'hangup') return onEnded(); const pc = ensurePeer(); if (signal.type === 'ice') { if (pc.remoteDescription) await pc.addIceCandidate(signal.candidate); else pendingCandidates.current.push(signal.candidate) } else { await pc.setRemoteDescription(signal.sdp); for (const candidate of pendingCandidates.current.splice(0)) await pc.addIceCandidate(candidate); if (signal.type === 'offer') { if (!local.current) await start(); const answer = await pc.createAnswer(); await pc.setLocalDescription(answer); send({ type: 'answer', sdp: answer }) } } }
    const signalRef = channel.on('signal', handle)
    const participantRef = channel.on('participant:joined', () => { peerPresent.current = true; if (initiator && local.current) void makeOffer() })
    return () => { channel.off('signal', signalRef); channel.off('participant:joined', participantRef); peerPresent.current = false; pendingCandidates.current = [] }
  }, [channel, ensurePeer, initiator, makeOffer, onEnded, send, start])
  const stop = useCallback(() => { send({ type: 'hangup' }); local.current?.getTracks().forEach(t => t.stop()); peer.current?.close(); peer.current = null; local.current = null; setLocalStream(null); setRemote(null); onEnded() }, [onEnded, send])
  useEffect(() => () => { local.current?.getTracks().forEach(t => t.stop()); peer.current?.close() }, [])
  const toggleMute = () => { local.current?.getAudioTracks().forEach(t => { t.enabled = muted }); setMuted(!muted) }
  const toggleCamera = () => { local.current?.getVideoTracks().forEach(t => { t.enabled = cameraOff }); setCameraOff(!cameraOff) }
  const shareScreen = async () => { if (sharing) return; const display = await navigator.mediaDevices.getDisplayMedia({ video: true }); const track = display.getVideoTracks()[0]; const sender = peer.current?.getSenders().find(s => s.track?.kind === 'video'); await sender?.replaceTrack(track); setSharing(true); track.onended = async () => { const camera = local.current?.getVideoTracks()[0]; if (camera) await sender?.replaceTrack(camera); setSharing(false) } }
  return { localStream, remote, muted, cameraOff, sharing, start, stop, toggleMute, toggleCamera, shareScreen }
}
