import { AuthProvider, useAuth } from './contexts/AuthContext'
import Login from './components/Login'
import Dashboard from './components/Dashboard'
import AdminResults from './components/AdminResults'

function AppContent() {
  const { user, isAdmin, loading } = useAuth()

  // Prüfe Umgebungsvariablen
  const hasEnvVars = import.meta.env.VITE_SUPABASE_URL && import.meta.env.VITE_SUPABASE_ANON_KEY

  if (!hasEnvVars) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-red-50 p-4">
        <div className="bg-white p-8 rounded-lg shadow-lg max-w-md">
          <h1 className="text-2xl font-bold text-red-600 mb-4">⚠️ Konfigurationsfehler</h1>
          <p className="text-gray-700 mb-4">
            Die Supabase-Umgebungsvariablen fehlen. Bitte prüfe die Vercel-Konfiguration.
          </p>
          <div className="bg-gray-100 p-4 rounded text-sm mb-4">
            <p className="font-semibold mb-2">Benötigte Variablen:</p>
            <ul className="list-disc list-inside space-y-1">
              <li>VITE_SUPABASE_URL</li>
              <li>VITE_SUPABASE_ANON_KEY</li>
            </ul>
          </div>
          <p className="text-sm text-gray-600">
            Gehe zu Vercel Dashboard → Project Settings → Environment Variables
          </p>
        </div>
      </div>
    )
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
          <Login />
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

