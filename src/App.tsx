import { AuthProvider, useAuth } from './contexts/AuthContext'
import Auth from './components/Auth'
import Dashboard from './components/Dashboard'
import AdminResults from './components/AdminResults'
import { logger } from './utils/logger'

function AppContent() {
  const { user, isAdmin, loading } = useAuth()

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
      
      {/* Content */}
      <div className="relative z-10">
        {!user ? (
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

