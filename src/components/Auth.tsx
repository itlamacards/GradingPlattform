import { useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { getUserFriendlyErrorMessage, logError } from '../utils/errorHandler'
import { logComponent } from '../utils/logger'

function Auth() {
  const { signIn, signUp } = useAuth()
  const [isRegister, setIsRegister] = useState(false)
  
  // Login State
  const [loginEmail, setLoginEmail] = useState('')
  const [loginPassword, setLoginPassword] = useState('')
  const [loginError, setLoginError] = useState('')
  const [loginLoading, setLoginLoading] = useState(false)

  // Register State
  const [registerEmail, setRegisterEmail] = useState('')
  const [registerPassword, setRegisterPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [registerError, setRegisterError] = useState('')
  const [registerLoading, setRegisterLoading] = useState(false)
  const [registerSuccess, setRegisterSuccess] = useState(false)

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoginError('')
    setLoginLoading(true)
    
    logComponent('Auth', 'Login-Versuch', { email: loginEmail })
    
    try {
      await signIn(loginEmail, loginPassword)
      logComponent('Auth', 'Login erfolgreich')
    } catch (err) {
      logError('Auth.handleLogin', err)
      setLoginError(getUserFriendlyErrorMessage(err))
    } finally {
      setLoginLoading(false)
    }
  }

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setRegisterError('')
    setRegisterLoading(true)
    
    // Validierung
    if (registerPassword !== confirmPassword) {
      setRegisterError('Die Passwörter stimmen nicht überein.')
      setRegisterLoading(false)
      return
    }

    if (registerPassword.length < 6) {
      setRegisterError('Das Passwort muss mindestens 6 Zeichen lang sein.')
      setRegisterLoading(false)
      return
    }

    if (!firstName.trim() || !lastName.trim()) {
      setRegisterError('Bitte geben Sie Vor- und Nachname ein.')
      setRegisterLoading(false)
      return
    }
    
    logComponent('Auth', 'Registrierungs-Versuch', { 
      email: registerEmail, 
      firstName, 
      lastName 
    })
    
    try {
      await signUp(registerEmail, registerPassword, firstName.trim(), lastName.trim())
      logComponent('Auth', 'Registrierung erfolgreich')
      setRegisterSuccess(true)
    } catch (err) {
      logError('Auth.handleRegister', err)
      setRegisterError(getUserFriendlyErrorMessage(err))
    } finally {
      setRegisterLoading(false)
    }
  }

  if (registerSuccess) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 animate-fadeIn">
        <div className="w-full max-w-md">
          <div className="bg-white/90 backdrop-blur-md rounded-2xl shadow-2xl p-8 border border-white/30 text-center">
            <div className="mb-6">
              <div className="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
                <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
            <h2 className="text-2xl font-bold text-gray-800 mb-4">
              Registrierung erfolgreich!
            </h2>
            <p className="text-gray-600 mb-6">
              Ihr Konto wurde erstellt. Sie werden automatisch angemeldet...
            </p>
          </div>
        </div>
      </div>
    )
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

        {/* Auth Card */}
        <div className="bg-white/90 backdrop-blur-md rounded-2xl shadow-2xl p-8 border border-white/30 animate-fadeIn" style={{ animationDelay: '0.2s' }}>
          <h2 className="text-3xl font-bold text-gray-800 mb-2 text-center">
            {isRegister ? 'Neues Konto erstellen' : 'Willkommen zurück'}
          </h2>
          <p className="text-gray-600 text-center mb-8">
            {isRegister 
              ? 'Registrieren Sie sich für den Zugang zu Ihren Grading-Aufträgen'
              : 'Melden Sie sich an, um Ihre Grading-Aufträge zu verfolgen'
            }
          </p>

          {!isRegister ? (
            /* LOGIN FORM */
            <form onSubmit={handleLogin} className="space-y-6">
              <div>
                <label htmlFor="loginEmail" className="block text-sm font-medium text-gray-700 mb-2">
                  E-Mail-Adresse
                </label>
                <input
                  id="loginEmail"
                  type="email"
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
                  className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 hover:border-gray-400"
                  placeholder="ihre@email.com"
                  required
                />
              </div>

              <div>
                <label htmlFor="loginPassword" className="block text-sm font-medium text-gray-700 mb-2">
                  Passwort
                </label>
                <input
                  id="loginPassword"
                  type="password"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
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

              {loginError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm animate-shake">
                  <strong>Fehler:</strong> {loginError}
                  <br />
                  <small className="text-red-600 mt-1 block">
                    Bitte öffne die Browser-Konsole (F12) für mehr Details.
                  </small>
                </div>
              )}

              <button
                type="submit"
                disabled={loginLoading}
                className="w-full bg-gradient-to-r from-blue-600 to-blue-700 text-white py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-blue-800 transition-all duration-300 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loginLoading ? 'Wird angemeldet...' : 'Anmelden'}
              </button>
            </form>
          ) : (
            /* REGISTER FORM */
            <form onSubmit={handleRegister} className="space-y-5">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label htmlFor="firstName" className="block text-sm font-medium text-gray-700 mb-2">
                    Vorname
                  </label>
                  <input
                    id="firstName"
                    type="text"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 hover:border-gray-400"
                    placeholder="Max"
                    required
                  />
                </div>

                <div>
                  <label htmlFor="lastName" className="block text-sm font-medium text-gray-700 mb-2">
                    Nachname
                  </label>
                  <input
                    id="lastName"
                    type="text"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 hover:border-gray-400"
                    placeholder="Mustermann"
                    required
                  />
                </div>
              </div>

              <div>
                <label htmlFor="registerEmail" className="block text-sm font-medium text-gray-700 mb-2">
                  E-Mail-Adresse
                </label>
                <input
                  id="registerEmail"
                  type="email"
                  value={registerEmail}
                  onChange={(e) => setRegisterEmail(e.target.value)}
                  className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 hover:border-gray-400"
                  placeholder="ihre@email.com"
                  required
                />
              </div>

              <div>
                <label htmlFor="registerPassword" className="block text-sm font-medium text-gray-700 mb-2">
                  Passwort
                </label>
                <input
                  id="registerPassword"
                  type="password"
                  value={registerPassword}
                  onChange={(e) => setRegisterPassword(e.target.value)}
                  className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 hover:border-gray-400"
                  placeholder="••••••••"
                  required
                  minLength={6}
                />
                <p className="text-xs text-gray-500 mt-1">Mindestens 6 Zeichen</p>
              </div>

              <div>
                <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 mb-2">
                  Passwort bestätigen
                </label>
                <input
                  id="confirmPassword"
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none transition-all duration-200 hover:border-gray-400"
                  placeholder="••••••••"
                  required
                  minLength={6}
                />
              </div>

              {registerError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm animate-shake">
                  <strong>Fehler:</strong> {registerError}
                  <br />
                  <small className="text-red-600 mt-1 block">
                    Bitte öffne die Browser-Konsole (F12) für mehr Details.
                  </small>
                </div>
              )}

              <button
                type="submit"
                disabled={registerLoading}
                className="w-full bg-gradient-to-r from-blue-600 to-blue-700 text-white py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-blue-800 transition-all duration-300 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {registerLoading ? 'Wird registriert...' : 'Registrieren'}
              </button>
            </form>
          )}

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              {isRegister ? (
                <>
                  Bereits ein Konto?{' '}
                  <a 
                    href="#" 
                    onClick={(e) => {
                      e.preventDefault()
                      setIsRegister(false)
                    }}
                    className="text-blue-600 hover:text-blue-800 font-medium transition-colors duration-200 hover:underline"
                  >
                    Anmelden
                  </a>
                </>
              ) : (
                <>
                  Noch kein Konto?{' '}
                  <a 
                    href="#" 
                    onClick={(e) => {
                      e.preventDefault()
                      setIsRegister(true)
                    }}
                    className="text-blue-600 hover:text-blue-800 font-medium transition-colors duration-200 hover:underline"
                  >
                    Registrieren
                  </a>
                </>
              )}
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Auth

