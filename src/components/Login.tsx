import { useState } from 'react'
import { useAuth } from '../contexts/AuthContext'

function Login() {
  const { signIn } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    
    try {
      await signIn(email, password)
      // Navigation wird durch AuthContext gehandhabt
    } catch (err: any) {
      setError(err.message || 'Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 animate-fadeIn">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="flex justify-center mb-8 animate-slideDown">
          <img 
            src="/lamacards-logo.webp" 
            alt="Lama Cards Logo" 
            className="h-32 w-auto drop-shadow-2xl transform hover:scale-105 transition-transform duration-300"
          />
        </div>

        {/* Login Card */}
        <div className="bg-white/90 backdrop-blur-md rounded-2xl shadow-2xl p-8 border border-white/30 animate-fadeIn" style={{ animationDelay: '0.2s' }}>
          <h2 className="text-3xl font-bold text-gray-800 mb-2 text-center">
            Willkommen zurück
          </h2>
          <p className="text-gray-600 text-center mb-8">
            Melden Sie sich an, um Ihre Grading-Aufträge zu verfolgen
          </p>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                E-Mail-Adresse
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 hover:border-gray-400"
                placeholder="ihre@email.com"
                required
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                Passwort
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 hover:border-gray-400"
                placeholder="••••••••"
                required
              />
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center">
                <input type="checkbox" className="rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
                <span className="ml-2 text-sm text-gray-600">Angemeldet bleiben</span>
              </label>
              <a href="#" className="text-sm text-blue-600 hover:text-blue-800 transition-colors duration-200">
                Passwort vergessen?
              </a>
            </div>

            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm animate-shake">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-blue-600 to-blue-700 text-white py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-blue-800 transition-all duration-300 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Wird angemeldet...' : 'Anmelden'}
            </button>
          </form>

          <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <p className="text-xs text-blue-700 text-center">
              <strong>Demo:</strong> Admin-Login: "admin@admin.de" / "admin"
            </p>
          </div>

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Noch kein Konto?{' '}
              <a href="#" className="text-blue-600 hover:text-blue-800 font-medium transition-colors duration-200 hover:underline">
                Registrieren
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Login
