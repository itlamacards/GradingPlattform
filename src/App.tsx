import { useEffect, useState } from 'react'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import Auth from './components/Auth'
import Dashboard from './components/Dashboard'
import AdminResults from './components/AdminResults'
import EmailConfirmation from './components/EmailConfirmation'
import { logger } from './utils/logger'

function AppContent() {
  const { user, isAdmin, loading, error, clearError } = useAuth()
  const [showEmailConfirmation, setShowEmailConfirmation] = useState(false)

  // Prüfe URL-Parameter für E-Mail-Bestätigung
  useEffect(() => {
    const hashParams = new URLSearchParams(window.location.hash.substring(1))
    const type = hashParams.get('type')
    
    if (type === 'signup' || type === 'recovery') {
      setShowEmailConfirmation(true)
      // Entferne Hash aus URL nach dem Lesen
      window.history.replaceState(null, '', window.location.pathname)
    }
  }, [])

  // Warnung in Konsole (nicht blockierend)
  if (typeof window !== 'undefined' && (!import.meta.env.VITE_SUPABASE_URL || !import.meta.env.VITE_SUPABASE_ANON_KEY)) {
    logger.warn('Supabase-Umgebungsvariablen fehlen! Die App könnte nicht funktionieren.', {
      context: 'App',
      group: '⚠️ Configuration Warning'
    })
    logger.info('Bitte setze in Vercel: VITE_SUPABASE_URL und VITE_SUPABASE_ANON_KEY', {
      context: 'App'
    })
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-white text-xl">Lädt...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* Hintergrund */}
      <img 
        src="/hintergrundkarte.png"
        alt=""
        className="fixed inset-0 w-full h-full object-cover z-0"
        style={{
          minHeight: '100vh',
          minWidth: '100vw'
        }}
      />
      
      {/* Error Modal - IMMER gerendert, unabhängig von Komponenten-Mount */}
      {error && (
        <div 
          className="fixed inset-0 z-[99999] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              clearError()
            }
          }}
        >
          <div className="bg-white rounded-2xl shadow-2xl p-6 max-w-md w-full border-2 border-red-200">
            <div className="flex items-start">
              <div className="flex-shrink-0">
                <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                  <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </div>
              </div>
              <div className="ml-4 flex-1">
                <h3 className="text-lg font-bold text-gray-900 mb-2">Fehler</h3>
                <p className="text-gray-700">{error}</p>
              </div>
              <button
                onClick={clearError}
                className="ml-4 text-gray-400 hover:text-gray-600 transition-colors"
                aria-label="Schließen"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      )}
      
      {/* Content */}
      <div className="relative z-10">
        {showEmailConfirmation ? (
          <EmailConfirmation />
        ) : !user ? (
          <Auth />
        ) : isAdmin ? (
          <AdminResults />
        ) : (
          <Dashboard />
        )}
      </div>
    </div>
  )
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  )
}

export default App

