export type ID = string
export interface User { id: ID; username: string; display_name?: string; avatar_url?: string; status?: 'online' | 'idle' | 'offline'; role?: string }
export interface Session { token: string; user: User }
export interface Membership { user: User; role: string; banned_at?: string }
export interface Conversation { id: ID; name?: string; kind: 'direct' | 'group'; members: Membership[]; last_message_at?: string }
export interface Attachment { url: string; filename: string; content_type?: string; size?: number }
export interface Message { id: ID; body?: string; sender: User; conversation_id: ID; inserted_at: string; attachment?: Attachment; deleted_at?: string }
export interface FriendRequest { id: ID; sender: User; status: string; inserted_at: string }
export interface Notification { id: ID; type: string; data: Record<string, unknown>; read_at?: string; inserted_at: string }
export interface CallRecord { id: ID; conversation_id: ID; initiator: User; kind: 'voice' | 'video'; status: string; started_at?: string; inserted_at: string; ended_at?: string }
export type Signal = { type: 'offer' | 'answer'; sdp: RTCSessionDescriptionInit; from: ID } | { type: 'ice'; candidate: RTCIceCandidateInit; from: ID } | { type: 'hangup'; from: ID }
export interface Page<T> { data: T[]; meta?: { next?: string } }
