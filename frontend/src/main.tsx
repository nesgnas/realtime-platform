import { Component, StrictMode, type ErrorInfo, type ReactNode } from 'react'
import { createRoot } from 'react-dom/client'
import { AuthProvider } from './context/AuthContext'
import App from './App'
import './styles.css'

class ErrorBoundary extends Component<{ children: ReactNode }, { error: Error | null }> {
  state = { error: null as Error | null }

  static getDerivedStateFromError(error: Error) { return { error } }

  componentDidCatch(error: Error, info: ErrorInfo) {
    localStorage.setItem('relay_last_error', JSON.stringify({ message: error.message, stack: error.stack, componentStack: info.componentStack, at: new Date().toISOString() }))
  }

  render() {
    if (!this.state.error) return this.props.children
    return <main className="crash"><div className="logo-mark">R</div><p className="eyebrow">RELAY RECOVERY</p><h1>Something interrupted this view.</h1><code>{this.state.error.message}</code><button className="primary compact" onClick={() => location.reload()}>Reload Relay</button></main>
  }
}

createRoot(document.getElementById('root')!).render(<StrictMode><ErrorBoundary><AuthProvider><App /></AuthProvider></ErrorBoundary></StrictMode>)
