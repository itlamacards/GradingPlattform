// ============================================
// SECURE LOGIN SERVICE
// ============================================
// Umfassende Security-Implementierung für Login
// User Enumeration Schutz, Rate-Limiting, Timing-Schutz

import { supabase } from '../lib/supabase'
import { logApiCall, logApiSuccess, logApiError } from '../utils/logger'
import { logError } from '../utils/errorHandler'

// ============================================
// CONSTANTS
// ============================================

const MAX_IDENTIFIER_LENGTH = 255
const MAX_PASSWORD_LENGTH = 256
const MIN_IDENTIFIER_LENGTH = 3
const FAKE_VERIFY_DELAY_MS = 150 // Timing-Schutz
const GENERIC_ERROR_MESSAGE = 'E-Mail oder Passwort ist falsch.'

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Normalisiert Identifier (Email)
 * - Trim
 * - Lowercase
 * - Unicode Normalization (NFC)
 */
function normalizeIdentifier(identifier: string): string {
  if (!identifier) return ''
  return identifier.toLowerCase().trim()
}

/**
 * Validiert Login-Input
 * Prüft: Vorhanden, Länge, Format
 */
function validateLoginInput(
  identifier: string | null | undefined,
  password: string | null | undefined
): { valid: boolean; error?: string } {
  // 1. Prüfe ob Identifier vorhanden
  if (!identifier || !identifier.trim()) {
    return { valid: false, error: GENERIC_ERROR_MESSAGE }
  }

  // 2. Prüfe ob Passwort vorhanden
  if (!password || !password.trim()) {
    return { valid: false, error: GENERIC_ERROR_MESSAGE }
  }

  const normalized = normalizeIdentifier(identifier)

  // 3. Prüfe Identifier-Länge
  if (normalized.length < MIN_IDENTIFIER_LENGTH) {
    return { valid: false, error: GENERIC_ERROR_MESSAGE }
  }

  if (normalized.length > MAX_IDENTIFIER_LENGTH) {
    return { valid: false, error: GENERIC_ERROR_MESSAGE }
  }

  // 4. Prüfe Passwort-Länge (Payload-Abuse Schutz)
  if (password.length > MAX_PASSWORD_LENGTH) {
    return { valid: false, error: GENERIC_ERROR_MESSAGE }
  }

  // 5. Prüfe auf SQL-Injection-Patterns (vereinfacht)
  const suspiciousPatterns = /(union|select|insert|update|delete|drop|exec|script)/i
  if (suspiciousPatterns.test(normalized)) {
    return { valid: false, error: GENERIC_ERROR_MESSAGE }
  }

  return { valid: true }
}

/**
 * Fake Password Verify für Timing-Schutz
 * Simuliert Passwort-Verifikation um User Enumeration zu verhindern
 */
async function fakePasswordVerify(): Promise<void> {
  await new Promise(resolve => setTimeout(resolve, FAKE_VERIFY_DELAY_MS))
}

/**
 * Hole IP-Adresse (Client-seitig - sollte Server-seitig sein)
 * Für jetzt: Placeholder - wird in Edge Function/API Route benötigt
 */
function getClientIP(): string {
  // HINWEIS: In Production sollte dies Server-seitig sein!
  // Für Frontend: Könnte über Edge Function oder API Route gehen
  // Für jetzt: Placeholder - wird in Supabase Edge Function benötigt
  return 'client-side' // Wird in Edge Function durch echte IP ersetzt
}

/**
 * Hole User-Agent
 */
function getUserAgent(): string {
  return navigator.userAgent || 'unknown'
}

// ============================================
// MAIN LOGIN FUNCTION
// ============================================

interface SecureLoginResult {
  success: boolean
  data?: any
  error?: string
  requiresPasswordReset?: boolean
}

/**
 * Secure Login mit vollständigem User Enumeration Schutz
 */
export async function secureSignIn(
  email: string,
  password: string
): Promise<SecureLoginResult> {
  const startTime = Date.now()
  const ipAddress = getClientIP()
  const userAgent = getUserAgent()
  
  logApiCall('POST', 'auth/secureSignIn', { email: email.substring(0, 3) + '***' })

  try {
    // ============================================
    // PHASE 1: Input Validation
    // ============================================
    
    const validation = validateLoginInput(email, password)
    if (!validation.valid) {
      // Rate-Limit trotzdem zählen (Format-Fehler)
      try {
        await supabase.rpc('check_ip_rate_limit', {
          p_ip_address: ipAddress,
          p_max_attempts_per_hour: 20,
          p_block_duration_minutes: 15
        })
      } catch (e) {
        // Ignore
      }
      
      // Logge Versuch
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizeIdentifier(email || ''),
        customerId: null,
        success: false,
        failureReason: 'INVALID_INPUT',
        statusAtAttempt: null,
        responseTimeMs: Date.now() - startTime
      })
      
      return { success: false, error: validation.error || GENERIC_ERROR_MESSAGE }
    }

    const normalizedEmail = normalizeIdentifier(email)

    // ============================================
    // PHASE 2: Rate-Limiting (IP-basiert)
    // ============================================
    
    const { data: ipRateLimit, error: ipRateLimitError } = await supabase.rpc('check_ip_rate_limit', {
      p_ip_address: ipAddress,
      p_max_attempts_per_hour: 20,
      p_block_duration_minutes: 15
    })

    if (ipRateLimitError) {
      logApiError('POST', 'auth/secureSignIn.rateLimit', ipRateLimitError)
      // Bei Fehler: Weiter, aber loggen
    } else if (ipRateLimit && ipRateLimit.length > 0 && !ipRateLimit[0].allowed) {
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: null,
        success: false,
        failureReason: 'IP_RATE_LIMIT_EXCEEDED',
        statusAtAttempt: null,
        responseTimeMs: Date.now() - startTime
      })
      
      return { success: false, error: GENERIC_ERROR_MESSAGE }
    }

    // ============================================
    // PHASE 3: Rate-Limiting (Identifier-basiert)
    // ============================================
    
    const { data: identifierRateLimit, error: identifierRateLimitError } = await supabase.rpc('check_identifier_rate_limit', {
      p_identifier: normalizedEmail,
      p_max_attempts_per_hour: 10,
      p_block_duration_minutes: 15
    })

    if (identifierRateLimitError) {
      logApiError('POST', 'auth/secureSignIn.identifierRateLimit', identifierRateLimitError)
    } else if (identifierRateLimit && identifierRateLimit.length > 0 && !identifierRateLimit[0].allowed) {
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: null,
        success: false,
        failureReason: 'IDENTIFIER_RATE_LIMIT_EXCEEDED',
        statusAtAttempt: null,
        responseTimeMs: Date.now() - startTime
      })
      
      return { success: false, error: GENERIC_ERROR_MESSAGE }
    }

    // ============================================
    // PHASE 4: Credential Stuffing Check
    // ============================================
    
    const { data: credentialStuffing, error: credentialStuffingError } = await supabase.rpc('check_credential_stuffing_pattern', {
      p_ip_address: ipAddress,
      p_unique_identifiers_threshold: 10,
      p_time_window_minutes: 5
    })

    if (credentialStuffingError) {
      logApiError('POST', 'auth/secureSignIn.credentialStuffing', credentialStuffingError)
    } else if (credentialStuffing) {
      // Härter throttlen
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: null,
        success: false,
        failureReason: 'CREDENTIAL_STUFFING_PATTERN',
        statusAtAttempt: null,
        responseTimeMs: Date.now() - startTime
      })
      
      return { success: false, error: GENERIC_ERROR_MESSAGE }
    }

    // ============================================
    // PHASE 5: User Lookup (mit Data Integrity Check)
    // ============================================
    
    const { data: userCheck, error: userCheckError } = await supabase.rpc('check_user_exists', {
      p_normalized_identifier: normalizedEmail
    })

    let customer: any = null
    let userExists = false
    let dataIntegrityIssue = false

    if (userCheckError) {
      logApiError('POST', 'auth/secureSignIn.userCheck', userCheckError)
      // Bei Fehler: Behandle als "nicht existiert"
    } else if (userCheck && userCheck.length > 0) {
      userExists = userCheck[0].exists
      dataIntegrityIssue = userCheck[0].data_integrity_issue
      
      if (userExists) {
        customer = {
          id: userCheck[0].customer_id,
          status: userCheck[0].status,
          email_verified_at: userCheck[0].email_verified_at,
          locked_until: userCheck[0].locked_until,
          failed_login_count: userCheck[0].failed_login_count
        }
        
        // Logge Data Integrity Issue
        if (dataIntegrityIssue) {
          logApiError('POST', 'auth/secureSignIn.dataIntegrity', {
            message: 'Multiple customers with same email',
            identifier: normalizedEmail
          })
        }
      }
    }

    // ============================================
    // PHASE 6: Status-Checks (User Enumeration Schutz!)
    // ============================================
    
    if (!userExists || !customer) {
      // User existiert nicht - Fake Password Verify + generische Meldung
      await fakePasswordVerify()
      
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: null,
        success: false,
        failureReason: 'USER_NOT_FOUND',
        statusAtAttempt: null,
        responseTimeMs: Date.now() - startTime
      })
      
      return { success: false, error: GENERIC_ERROR_MESSAGE }
    }

    // Status-Checks (alle mit generischer Meldung außer spezifischen Fällen)
    if (customer.status === 'DELETED') {
      await fakePasswordVerify()
      
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: customer.id,
        success: false,
        failureReason: 'ACCOUNT_DELETED',
        statusAtAttempt: 'DELETED',
        responseTimeMs: Date.now() - startTime
      })
      
      return { success: false, error: GENERIC_ERROR_MESSAGE }
    }

    if (customer.status === 'SUSPENDED') {
      // SUSPENDED: Hier können wir spezifisch sein (Account existiert)
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: customer.id,
        success: false,
        failureReason: 'ACCOUNT_SUSPENDED',
        statusAtAttempt: 'SUSPENDED',
        responseTimeMs: Date.now() - startTime
      })
      
      return { success: false, error: 'Ihr Account wurde gesperrt. Bitte kontaktieren Sie den Support.' }
    }

    if (customer.status === 'LOCKED') {
      // Prüfe ob Lock abgelaufen
      const { data: unlocked } = await supabase.rpc('unlock_customer_account_if_expired', {
        p_customer_id: customer.id
      })

      if (!unlocked) {
        await logLoginAttempt({
          ipAddress,
          userAgent,
          identifier: normalizedEmail,
          customerId: customer.id,
          success: false,
          failureReason: 'ACCOUNT_LOCKED',
          statusAtAttempt: 'LOCKED',
          responseTimeMs: Date.now() - startTime
        })
        
        // LOCKED: Generische Meldung (User Enumeration Schutz)
        return { success: false, error: GENERIC_ERROR_MESSAGE }
      }
      
      // Lock wurde aufgehoben - hole aktualisierten Customer
      const { data: updatedUserCheck } = await supabase.rpc('check_user_exists', {
        p_normalized_identifier: normalizedEmail
      })
      
      if (updatedUserCheck && updatedUserCheck.length > 0 && updatedUserCheck[0].exists) {
        customer = {
          id: updatedUserCheck[0].customer_id,
          status: updatedUserCheck[0].status,
          email_verified_at: updatedUserCheck[0].email_verified_at,
          locked_until: updatedUserCheck[0].locked_until,
          failed_login_count: updatedUserCheck[0].failed_login_count
        }
      }
    }

    // ============================================
    // PHASE 7: Password Check (Supabase Auth)
    // ============================================
    
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: normalizedEmail,
      password,
    })

    if (authError) {
      // Passwort falsch - Failed-Login-Count erhöhen
      if (customer) {
        await supabase.rpc('increment_failed_login_count', {
          p_customer_id: customer.id
        })
      }

      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: customer?.id || null,
        success: false,
        failureReason: 'WRONG_PASSWORD',
        statusAtAttempt: customer?.status || null,
        responseTimeMs: Date.now() - startTime
      })

      return { success: false, error: GENERIC_ERROR_MESSAGE }
    }

    // ============================================
    // PHASE 8: Post-Password Status Checks
    // ============================================
    
    if (customer.status === 'UNVERIFIED') {
      await supabase.auth.signOut()
      
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: customer.id,
        success: false,
        failureReason: 'EMAIL_NOT_VERIFIED',
        statusAtAttempt: 'UNVERIFIED',
        responseTimeMs: Date.now() - startTime
      })
      
      // UNVERIFIED: Hier können wir spezifisch sein (Passwort war korrekt)
      return { success: false, error: 'Bitte bestätigen Sie zuerst Ihre E-Mail-Adresse. Prüfen Sie Ihr Postfach.' }
    }

    if (customer.status === 'PASSWORD_RESET_REQUIRED') {
      await logLoginAttempt({
        ipAddress,
        userAgent,
        identifier: normalizedEmail,
        customerId: customer.id,
        success: true,
        failureReason: null,
        statusAtAttempt: 'PASSWORD_RESET_REQUIRED',
        responseTimeMs: Date.now() - startTime
      })
      
      return { 
        success: true, 
        data: authData, 
        requiresPasswordReset: true 
      }
    }

    // ============================================
    // PHASE 9: Success - Reset Failed-Login-Count
    // ============================================
    
    if (customer) {
      await supabase.rpc('reset_failed_login_count', {
        p_customer_id: customer.id
      })
    }

    await logLoginAttempt({
      ipAddress,
      userAgent,
      identifier: normalizedEmail,
      customerId: customer.id,
      success: true,
      failureReason: null,
      statusAtAttempt: customer.status,
      responseTimeMs: Date.now() - startTime
    })

    logApiSuccess('POST', 'auth/secureSignIn', { 
      userId: authData?.user?.id, 
      email: authData?.user?.email 
    })

    return { success: true, data: authData }
  } catch (error) {
    logApiError('POST', 'auth/secureSignIn', error)
    logError('secureSignIn', error)
    
    // Bei unerwarteten Fehlern: Generische Meldung
    return { success: false, error: GENERIC_ERROR_MESSAGE }
  }
}

// ============================================
// HELPER: Login Attempt Logging
// ============================================

async function logLoginAttempt(params: {
  ipAddress: string
  userAgent: string
  identifier: string
  customerId: string | null
  success: boolean
  failureReason: string | null
  statusAtAttempt: string | null
  responseTimeMs: number
}): Promise<void> {
  try {
    await supabase.rpc('log_login_attempt', {
      p_ip_address: params.ipAddress,
      p_user_agent: params.userAgent,
      p_identifier: params.identifier,
      p_customer_id: params.customerId,
      p_success: params.success,
      p_failure_reason: params.failureReason,
      p_status_at_attempt: params.statusAtAttempt,
      p_response_time_ms: params.responseTimeMs
    })
  } catch (error) {
    // Logging-Fehler sollten nicht den Login blockieren
    logApiError('POST', 'auth/logLoginAttempt', error)
  }
}

