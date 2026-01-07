import { useEffect, useState } from 'react'
import { logger } from '../utils/logger'

function EmailConfirmation() {
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [message, setMessage] = useState('')

  useEffect(() => {
    const handleEmailConfirmation = async () => {
      try {
        // Prüfe URL-Parameter für E-Mail-Bestätigung
        const hashParams = new URLSearchParams(window.location.hash.substring(1))
        const accessToken = hashParams.get('access_token')
        const type = hashParams.get('type')

        logger.info('E-Mail-Bestätigung erkannt', {
          context: 'EmailConfirmation',
          data: { type, hasToken: !!accessToken }
        })

        if (type === 'signup' && accessToken) {
          // Supabase hat die E-Mail-Bestätigung bereits verarbeitet
          // Die Session sollte automatisch gesetzt sein
          setStatus('success')
          setMessage('Ihre E-Mail wurde erfolgreich bestätigt! Sie werden weitergeleitet...')
          
          // Kurze Verzögerung, dann weiterleiten
          setTimeout(() => {
            window.location.href = '/'
          }, 2000)
        } else if (type === 'recovery') {
          // Passwort-Reset
          setStatus('success')
          setMessage('Sie können jetzt Ihr Passwort zurücksetzen.')
        } else {
          // Keine gültigen Parameter
          setStatus('error')
          setMessage('Ungültiger Bestätigungslink. Bitte versuchen Sie es erneut.')
        }
      } catch (error) {
        logger.error('E-Mail-Bestätigung fehlgeschlagen', {
          context: 'EmailConfirmation',
          data: error
        })
        setStatus('error')
        setMessage('Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.')
      }
    }

    handleEmailConfirmation()
  }, [])

  return (
    <div className="min-h-screen flex items-center justify-center p-4 animate-fadeIn">
      <div className="w-full max-w-md">
        <div className="bg-white/90 backdrop-blur-md rounded-2xl shadow-2xl p-8 border border-white/30 text-center">
          {status === 'loading' && (
            <>
              <div className="mb-6">
                <div className="mx-auto w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center animate-spin">
                  <svg className="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                </div>
              </div>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">
                E-Mail wird bestätigt...
              </h2>
              <p className="text-gray-600">
                Bitte warten Sie einen Moment.
              </p>
            </>
          )}

          {status === 'success' && (
            <>
              <div className="mb-6">
                <div className="mx-auto w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
                  <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
              </div>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">
                Bestätigung erfolgreich!
              </h2>
              <p className="text-gray-600 mb-6">
                {message}
              </p>
            </>
          )}

          {status === 'error' && (
            <>
              <div className="mb-6">
                <div className="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
                  <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </div>
              </div>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">
                Bestätigung fehlgeschlagen
              </h2>
              <p className="text-gray-600 mb-6">
                {message}
              </p>
              <a
                href="/"
                className="text-blue-600 hover:text-blue-800 font-medium transition-colors duration-200"
              >
                Zur Startseite
              </a>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

export default EmailConfirmation

