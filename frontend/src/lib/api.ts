import type { CallRecord, Conversation, FriendRequest, Message, Notification, Page, Session, User } from '../types'

const API_URL = (import.meta.env.VITE_API_URL || 'http://localhost:4000/api').replace(/\/$/, '')
let token = localStorage.getItem('relay_token')
export const setToken = (value: string | null) => { token = value; if (value) localStorage.setItem('relay_token', value); else localStorage.removeItem('relay_token') }

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers)
  if (!(init.body instanceof FormData)) headers.set('Content-Type', 'application/json')
  if (token) headers.set('Authorization', `Bearer ${token}`)
  const response = await fetch(`${API_URL}${path}`, { ...init, headers })
  if (response.status === 204) return undefined as T
  const body = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(body.error?.message || body.message || `Request failed (${response.status})`)
  return (body.data ?? body) as T
}

const json = (method: string, body?: unknown): RequestInit => ({ method, body: body === undefined ? undefined : JSON.stringify(body) })
const page = async <T>(path: string): Promise<Page<T>> => {
  const result = await request<T[] | Page<T>>(path)
  return Array.isArray(result) ? { data: result } : result
}
export const api = {
  login: (email: string, password: string) => request<Session>('/auth/login', json('POST', { email, password })),
  register: (input: { username: string; email: string; password: string }) => request<Session>('/auth/register', json('POST', input)),
  me: () => request<User>('/auth/me'),
  conversations: () => page<Conversation>('/conversations'),
  createConversation: (member_ids: ID[], name?: string) => member_ids.length === 1 && !name ? request<Conversation>('/conversations/direct', json('POST', { user_id: member_ids[0] })) : request<Conversation>('/conversations/group', json('POST', { member_ids, name: name || 'Group' })),
  messages: (id: string) => page<Message>(`/conversations/${id}/messages`),
  sendMessage: (id: string, body: string, file?: File) => { const data = new FormData(); data.append('body', body); if (file) data.append('file', file); return request<Message>(`/conversations/${id}/messages`, { method: 'POST', body: data }) },
  friends: () => page<User>('/friends'),
  friendRequests: () => page<FriendRequest>('/friend-requests'),
  requestFriend: (username: string) => request<FriendRequest>('/friend-requests', json('POST', { username })),
  answerFriend: (id: string, accept: boolean) => request<FriendRequest>(`/friend-requests/${id}`, json('PATCH', { status: accept ? 'accepted' : 'declined' })),
  notifications: () => page<Notification>('/notifications'),
  readNotification: (id: string) => request<void>(`/notifications/${id}/read`, json('PATCH')),
  calls: (conversation_id: string) => page<CallRecord>(`/conversations/${conversation_id}/calls`),
  createCall: (conversation_id: string, kind: 'voice' | 'video') => request<CallRecord>(`/conversations/${conversation_id}/calls`, json('POST', { kind })),
  endCall: (id: string) => request<void>(`/calls/${id}/end`, json('PATCH')),
  moderate: (conversationId: string, userId: string, action: 'kick' | 'ban') => request<void>(`/conversations/${conversationId}/members/${userId}/${action}`, json('POST'))
}

type ID = string
