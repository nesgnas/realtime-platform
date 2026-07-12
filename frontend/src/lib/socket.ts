import { Socket, type Channel } from 'phoenix'

const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || 'ws://localhost:4000/socket'
export const createSocket = (token: string) => new Socket(SOCKET_URL, { params: { token } })
export const join = (socket: Socket, topic: string, handlers: Record<string, (payload: unknown) => void> = {}) => {
  const channel = socket.channel(topic, {})
  Object.entries(handlers).forEach(([event, handler]) => channel.on(event, handler))
  channel.join()
  return channel
}
export const push = <T>(channel: Channel, event: string, payload: object) => new Promise<T>((resolve, reject) => channel.push(event, payload).receive('ok', resolve).receive('error', reject).receive('timeout', () => reject(new Error('Realtime request timed out'))))
