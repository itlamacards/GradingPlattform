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

  // Bekannte Fehlercodes
  const errorMessages: Record<string, string> = {
    'PGRST116': 'Keine Daten gefunden',
    '23505': 'Dieser Eintrag existiert bereits',
    '23503': 'Referenzfehler - Verwandte Daten fehlen',
    '42501': 'Zugriff verweigert - Sie haben keine Berechtigung',
    'invalid_credentials': 'Ungültige Anmeldedaten',
    'email_not_confirmed': 'E-Mail-Adresse nicht bestätigt',
    'too_many_requests': 'Zu viele Anfragen - Bitte versuchen Sie es später erneut',
  }

  if (parsed.code && errorMessages[parsed.code]) {
    return errorMessages[parsed.code]
  }

  // Fallback auf Original-Message
  return parsed.message
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

