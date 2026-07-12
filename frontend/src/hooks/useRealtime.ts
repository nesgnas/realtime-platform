import { useEffect, useRef, useState } from 'react'
import type { Channel, Socket } from 'phoenix'
import { createSocket, join } from '../lib/socket'
import type { Message, Notification, User } from '../types'

export function useRealtime(token: string, userId: string, conversationId: string | null, onMessage: (m: Message) => void, onNotification: (n: Notification) => void, onCall: (call: import('../types').CallRecord) => void) {
  const socketRef = useRef<Socket | null>(null)
  const [socketState, setSocketState] = useState<Socket | null>(null)
  const [presence, setPresence] = useState<Record<string, User['status']>>({})
  const [connected, setConnected] = useState(false)
  useEffect(() => {
    const socket = createSocket(token); socket.connect(); socketRef.current = socket; setSocketState(socket)
    socket.onOpen(() => setConnected(true)); socket.onClose(() => setConnected(false))
    const userChannel = join(socket, `user:${userId}`, { notification: payload => onNotification(payload as Notification), call_invite: payload => onCall(payload as import('../types').CallRecord), presence_state: payload => setPresence(Object.fromEntries(Object.keys(payload as object).map(id => [id, 'online']))) })
    return () => { userChannel.leave(); socket.disconnect(); socketRef.current = null; setSocketState(null) }
  }, [token, userId, onNotification, onCall])
  useEffect(() => {
    if (!socketRef.current || !conversationId) return
    const channel = join(socketRef.current, `conversation:${conversationId}`, { 'message:new': payload => onMessage(payload as Message), 'call:started': payload => onCall(payload as import('../types').CallRecord) })
    return () => { channel.leave() }
  }, [conversationId, onMessage, onCall])
  return { socket: socketState, presence, connected }
}

export function useCallChannel(socket: Socket | null, callId: string | null) {
  const [active, setActive] = useState<Channel | null>(null)
  useEffect(() => { if (!socket || !callId) { setActive(null); return }; const channel = join(socket, `call:${callId}`); setActive(channel); return () => { channel.leave(); setActive(null) } }, [socket, callId])
  return active
}
