// ============================================
// Error Handling Utilities
// ============================================

import { AppError } from '../types'
import { PostgrestError } from '@supabase/supabase-js'

// ============================================
// ERROR PARSING
// ============================================

export const parseError = (error: unknown): AppError => {
  // Supabase PostgrestError
  if (error && typeof error === 'object' && 'message' in error) {
    const supabaseError = error as PostgrestError
    return {
      message: supabaseError.message || 'Ein Fehler ist aufgetreten',
      code: supabaseError.code,
      details: supabaseError.details,
    }
  }

  // Standard Error
  if (error instanceof Error) {
    return {
      message: error.message,
    }
  }

  // String
  if (typeof error === 'string') {
    return {
      message: error,
    }
  }

  // Unknown
  return {
    message: 'Ein unbekannter Fehler ist aufgetreten',
    details: error,
  }
}

// ============================================
// USER-FRIENDLY ERROR MESSAGES
// ============================================

export const getUserFriendlyErrorMessage = (error: unknown): string => {
  const parsed = parseError(error)
  const message = parsed.message.toLowerCase()

  // Spezifische Fehlermeldungen für Login/Registrierung
  // Prüfe zuerst die Message (da wir custom Messages verwenden)
  
  // Login-Fehler
  if (message.includes('e-mail oder passwort ist falsch') || 
      message.includes('invalid login credentials') ||
      message.includes('invalid_credentials')) {
    return 'E-Mail oder Passwort ist falsch. Bitte versuchen Sie es erneut.'
  }
  
  if (message.includes('bitte bestätigen sie zuerst ihre e-mail') ||
      message.includes('email not confirmed') ||
      message.includes('email_not_confirmed')) {
    return 'Bitte bestätigen Sie zuerst Ihre E-Mail-Adresse. Prüfen Sie Ihr Postfach.'
  }
  
  if (message.includes('zu viele fehlversuche') ||
      message.includes('account gesperrt') ||
      message.includes('locked')) {
    return parsed.message // Verwende die spezifische Meldung mit Zeit
  }
  
  if (message.includes('account wurde gesperrt') ||
      message.includes('suspended')) {
    return 'Ihr Account wurde gesperrt. Bitte kontaktieren Sie den Support.'
  }
  
  // Registrierungs-Fehler
  if (message.includes('ein account mit dieser e-mail existiert bereits') ||
      message.includes('user already registered') ||
      message.includes('email already exists') ||
      message.includes('email already registered')) {
    return 'Diese E-Mail-Adresse ist bereits mit einem Account verknüpft. Bitte loggen Sie sich ein oder verwenden Sie die Funktion "Passwort vergessen".'
  }
  
  if (message.includes('bitte warten sie, bevor sie eine neue e-mail anfordern') ||
      message.includes('rate limit') ||
      message.includes('too many requests')) {
    return 'Bitte warten Sie, bevor Sie eine neue E-Mail anfordern. Versuchen Sie es in einer Minute erneut.'
  }
  
  if (message.includes('passwort') && message.includes('schwach')) {
    return 'Das Passwort ist zu schwach. Bitte verwenden Sie ein stärkeres Passwort.'
  }
  
  // Supabase Auth Fehler
  if (message.includes('email address is not authorized')) {
    return 'Diese E-Mail-Adresse ist nicht autorisiert.'
  }
  
  if (message.includes('signup is disabled')) {
    return 'Registrierungen sind derzeit deaktiviert.'
  }
  
  // Bekannte Fehlercodes
  const errorMessages: Record<string, string> = {
    'PGRST116': 'Keine Daten gefunden',
    '23505': 'Diese E-Mail-Adresse ist bereits mit einem Account verknüpft. Bitte loggen Sie sich ein oder verwenden Sie die Funktion "Passwort vergessen".',
    '23503': 'Referenzfehler - Verwandte Daten fehlen',
    '42501': 'Zugriff verweigert - Sie haben keine Berechtigung',
    'invalid_credentials': 'E-Mail oder Passwort ist falsch. Bitte versuchen Sie es erneut.',
    'email_not_confirmed': 'Bitte bestätigen Sie zuerst Ihre E-Mail-Adresse. Prüfen Sie Ihr Postfach.',
    'too_many_requests': 'Zu viele Anfragen - Bitte versuchen Sie es später erneut',
    'user_not_found': 'E-Mail oder Passwort ist falsch. Bitte versuchen Sie es erneut.',
    'wrong_password': 'E-Mail oder Passwort ist falsch. Bitte versuchen Sie es erneut.',
  }

  if (parsed.code && errorMessages[parsed.code]) {
    return errorMessages[parsed.code]
  }

  // Fallback auf Original-Message (falls sie bereits benutzerfreundlich ist)
  return parsed.message || 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.'
}

// ============================================
// ERROR LOGGING
// ============================================

import { logger } from './logger'

export const logError = (context: string, error: unknown): void => {
  const parsed = parseError(error)
  
  logger.error(`Fehler in ${context}`, {
    context,
    data: {
      message: parsed.message,
      code: parsed.code,
      details: parsed.details,
      originalError: error,
      stack: error instanceof Error ? error.stack : undefined
    },
    group: `❌ Error: ${context}`,
    collapsed: false
  })
}

