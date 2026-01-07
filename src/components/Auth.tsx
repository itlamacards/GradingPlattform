import { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { getUserFriendlyErrorMessage, logError } from '../utils/errorHandler'
import { logComponent } from '../utils/logger'
import { authService } from '../services/api'

function Auth() {
  const { signIn, signUp } = useAuth()
  const [isRegister, setIsRegister] = useState(false)
  
  // Login State
  const [loginEmail, setLoginEmail] = useState('')
  const [loginPassword, setLoginPassword] = useState('')
  const [loginError, setLoginError] = useState('')
  const [loginLoading, setLoginLoading] = useState(false)
  const [showErrorPopup, setShowErrorPopup] = useState(false)
  const [errorPopupMessage, setErrorPopupMessage] = useState('')

  // Debug: Logge State-Änderungen
  useEffect(() => {
    console.log('🔍 showErrorPopup State geändert:', showErrorPopup)
    console.log('🔍 errorPopupMessage:', errorPopupMessage)
  }, [showErrorPopup, errorPopupMessage])

  // Register State
  const [registerEmail, setRegisterEmail] = useState('')
  const [registerPassword, setRegisterPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [registerError, setRegisterError] = useState('')
  const [registerLoading, setRegisterLoading] = useState(false)
  const [registerSuccess, setRegisterSuccess] = useState(false)
  const [needsEmailConfirmation, setNeedsEmailConfirmation] = useState(false)
  const [registeredEmail, setRegisteredEmail] = useState('')

  // Fehler-Popup anzeigen
  const showError = (message: string) => {
    console.log('🔴 showError aufgerufen:', message)
    setErrorPopupMessage(message)
    setShowErrorPopup(true)
    console.log('🔴 showErrorPopup gesetzt auf true')
    // Auto-close nach 5 Sekunden
    setTimeout(() => {
      setShowErrorPopup(false)
    }, 5000)
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    e.stopPropagation()
    console.log('🔵 handleLogin gestartet')
    setLoginError('')
    setLoginLoading(true)
    
    logComponent('Auth', 'Login-Versuch', { email: loginEmail })
    
    try {
      console.log('🔵 signIn wird aufgerufen...')
      const result = await signIn(loginEmail, loginPassword)
      console.log('🔵 signIn erfolgreich:', result)
      
      // Prüfe ob Passwort-Reset erforderlich ist
      if (result && 'requiresPasswordReset' in result && result.requiresPasswordReset) {
        const errorMsg = 'Bitte setzen Sie ein neues Passwort.'
        setLoginError(errorMsg)
        showError(errorMsg)
        setLoginLoading(false)
        return
      }
      
      logComponent('Auth', 'Login erfolgreich')
    } catch (err) {
      console.error('🔴 Login-Fehler gefangen:', err)
      logError('Auth.handleLogin', err)
      const errorMessage = getUserFriendlyErrorMessage(err)
      console.log('🔴 Fehlermeldung:', errorMessage)
      setLoginError(errorMessage)
      showError(errorMessage)
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
      const result = await signUp(registerEmail, registerPassword, firstName.trim(), lastName.trim())
      logComponent('Auth', 'Registrierung erfolgreich', { result })
      
      // Prüfe, ob E-Mail-Bestätigung nötig ist
      const isConfirmed = result?.user?.email_confirmed_at !== null
      setNeedsEmailConfirmation(!isConfirmed)
      setRegisteredEmail(registerEmail)
      setRegisterSuccess(true)
    } catch (err) {
      logError('Auth.handleRegister', err)
      const errorMessage = getUserFriendlyErrorMessage(err)
      setRegisterError(errorMessage)
      showError(errorMessage)
    } finally {
      setRegisterLoading(false)
    }
  }

  if (registerSuccess) {
    if (needsEmailConfirmation) {
      // E-Mail-Bestätigung erforderlich
      return (
        <div className="min-h-screen flex items-center justify-center p-4 animate-fadeIn">
          <div className="w-full max-w-md">
            <div className="bg-white/90 backdrop-blur-md rounded-2xl shadow-2xl p-8 border border-white/30 text-center">
              <div className="mb-6">
                <div className="mx-auto w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center">
                  <svg className="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
              </div>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">
                E-Mail-Bestätigung erforderlich
              </h2>
              <p className="text-gray-600 mb-4">
                Wir haben eine Bestätigungs-E-Mail an <strong>{registeredEmail}</strong> gesendet.
              </p>
              <p className="text-gray-600 mb-6">
                Bitte öffnen Sie Ihr E-Mail-Postfach und klicken Sie auf den Bestätigungslink, um Ihr Konto zu aktivieren.
              </p>
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6 text-left">
                <p className="text-sm text-blue-800 font-semibold mb-2">📧 Keine E-Mail erhalten?</p>
                <ul className="text-sm text-blue-700 space-y-1 list-disc list-inside">
                  <li>Prüfen Sie Ihren Spam-Ordner</li>
                  <li>Warten Sie einige Minuten</li>
                  <li>Stellen Sie sicher, dass die E-Mail-Adresse korrekt ist</li>
                </ul>
              </div>
              <div className="space-y-3">
                <button
                  onClick={async () => {
                    try {
                      await authService.resendVerificationEmail(registeredEmail)
                      setRegisterError('')
                      // Zeige Erfolgsmeldung
                      alert('E-Mail wurde erneut gesendet. Bitte prüfen Sie Ihr Postfach.')
                    } catch (err: any) {
                      setRegisterError(err.message || 'Fehler beim Senden der E-Mail.')
                    }
                  }}
                  className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors duration-200"
                >
                  E-Mail erneut senden
                </button>
                <button
                  onClick={() => {
                    setRegisterSuccess(false)
                    setNeedsEmailConfirmation(false)
                    setRegisteredEmail('')
                    setIsRegister(false)
                  }}
                  className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors duration-200"
                >
                  ← Zurück zur Anmeldung
                </button>
              </div>
            </div>
          </div>
        </div>
      )
    } else {
      // Automatisch bestätigt - User muss sich einloggen (Sicherheit!)
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
              <p className="text-gray-600 mb-4">
                Ihr Konto wurde erstellt und ist bereit zur Verwendung.
              </p>
              <p className="text-gray-600 mb-6">
                Bitte loggen Sie sich jetzt mit Ihren Zugangsdaten ein.
              </p>
              <button
                onClick={() => {
                  setRegisterSuccess(false)
                  setNeedsEmailConfirmation(false)
                  setRegisteredEmail('')
                  // Zurück zum Login-Formular
                  setIsRegister(false)
                }}
                className="w-full bg-gradient-to-r from-blue-600 to-blue-700 text-white py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-blue-800 transition-all duration-300 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 active:scale-95"
              >
                Jetzt einloggen
              </button>
            </div>
          </div>
        </div>
      )
    }
  }

  return (
    <>
      {/* Fehler-Popup - außerhalb des main containers für bessere Sichtbarkeit */}
      {showErrorPopup && (
        <div 
          className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
          style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0 }}
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              setShowErrorPopup(false)
            }
          }}
        >
          <div className="bg-white rounded-2xl shadow-2xl p-6 max-w-md w-full border-2 border-red-200 animate-slideDown">
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
                <p className="text-gray-700">{errorPopupMessage}</p>
              </div>
              <button
                onClick={() => {
                  console.log('🔴 Popup Close Button geklickt')
                  setShowErrorPopup(false)
                }}
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
                <div className="bg-red-50 border-l-4 border-red-500 text-red-700 px-4 py-3 rounded-lg text-sm animate-shake">
                  <div className="flex items-start">
                    <svg className="w-5 h-5 text-red-500 mr-2 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                    </svg>
                    <div className="flex-1">
                      <strong className="font-semibold">Fehler bei der Anmeldung:</strong>
                      <p className="mt-1">{loginError}</p>
                    </div>
                  </div>
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
                <div className="bg-red-50 border-l-4 border-red-500 text-red-700 px-4 py-3 rounded-lg text-sm animate-shake">
                  <div className="flex items-start">
                    <svg className="w-5 h-5 text-red-500 mr-2 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                    </svg>
                    <div className="flex-1">
                      <strong className="font-semibold">Fehler bei der Registrierung:</strong>
                      <p className="mt-1">{registerError}</p>
                    </div>
                  </div>
                </div>
              )}

              <button
                type="submit"
                disabled={registerLoading}
                className="w-full bg-gradient-to-r from-blue-600 to-blue-700 text-white py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-blue-800 transition-all duration-300 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {registerLoading ? 'Wird registriert...' : 'Registrieren'}
              </button>
              
              <button
                type="button"
                onClick={(e) => {
                  e.preventDefault()
                  setIsRegister(false)
                  setRegisterError('')
                  setRegisterEmail('')
                  setRegisterPassword('')
                  setConfirmPassword('')
                  setFirstName('')
                  setLastName('')
                }}
                className="w-full mt-3 text-blue-600 hover:text-blue-800 font-medium transition-colors duration-200 py-2"
              >
                ← Zurück zur Anmeldung
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
                      setRegisterError('')
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
    </>
  )
}

export default Auth

