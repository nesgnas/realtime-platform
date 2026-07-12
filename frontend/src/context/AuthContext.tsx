import { createContext, useContext, useEffect, useState, type PropsWithChildren } from 'react'
import { api, setToken } from '../lib/api'
import type { Session, User } from '../types'

type AuthValue = { user: User | null; loading: boolean; login(email: string, password: string): Promise<void>; register(input: { username: string; email: string; password: string }): Promise<void>; logout(): Promise<void> }
const AuthContext = createContext<AuthValue | null>(null)

export function AuthProvider({ children }: PropsWithChildren) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  useEffect(() => { if (!localStorage.getItem('relay_token')) { setLoading(false); return }; api.me().then(setUser).catch(() => setToken(null)).finally(() => setLoading(false)) }, [])
  const accept = (session: Session) => { setToken(session.token); setUser(session.user) }
  const logout = async () => { setToken(null); setUser(null) }
  return <AuthContext.Provider value={{ user, loading, login: async (email, password) => accept(await api.login(email, password)), register: async input => accept(await api.register(input)), logout }}>{children}</AuthContext.Provider>
}
export const useAuth = () => { const value = useContext(AuthContext); if (!value) throw new Error('useAuth must be inside AuthProvider'); return value }
