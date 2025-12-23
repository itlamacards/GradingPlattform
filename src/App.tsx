import { AuthProvider, useAuth } from './contexts/AuthContext'
import Login from './components/Login'
import Dashboard from './components/Dashboard'
import AdminResults from './components/AdminResults'

function AppContent() {
  const { user, isAdmin, loading } = useAuth()

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

