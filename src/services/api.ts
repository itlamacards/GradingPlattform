import { supabase } from '../lib/supabase'
import { GradingOrderWithService } from '../types'
import { logError } from '../utils/errorHandler'
import { logApiCall, logApiSuccess, logApiError } from '../utils/logger'

// ============================================
// AUTHENTIFIZIERUNG
// ============================================

import { secureSignIn } from './secureLogin'

export const authService = {
  // Login mit E-Mail und Passwort (mit vollständigem Security + Fallback)
  async signIn(email: string, password: string) {
    logApiCall('POST', 'auth/signIn', { email: email.substring(0, 3) + '***' })
    
    try {
      // Versuche secureSignIn (wenn SQL-Functions existieren)
      const result = await secureSignIn(email, password)
      
      if (!result.success) {
        // WICHTIG: Fehler immer weitergeben!
        const error = new Error(result.error || 'E-Mail oder Passwort ist falsch.')
        throw error
      }
      
      if (result.requiresPasswordReset) {
        return { ...result.data, requiresPasswordReset: true }
      }
      
      return result.data
    } catch (error: any) {
      // Fallback: Wenn secureSignIn fehlschlägt (z.B. Functions nicht vorhanden),
      // verwende einfachere Login-Logik
      logApiError('POST', 'auth/signIn.secureSignIn', error)
      
      // Fallback zu einfachem Login
      return await authService.fallbackSignIn(email, password)
    }
  },
  
  // Fallback Login (wenn Security-Functions nicht verfügbar sind)
  async fallbackSignIn(email: string, password: string) {
    const normalizedEmail = email.toLowerCase().trim()
    
    // Input-Validation
    if (!normalizedEmail || !password) {
      throw new Error('E-Mail oder Passwort ist falsch.')
    }
    
    // Prüfe Customer-Status
    let customer
    try {
      customer = await customerService.getCustomerByEmail(normalizedEmail)
    } catch (e) {
      // Fallback zu getCustomerByEmailFull
      try {
        customer = await customerService.getCustomerByEmailFull(normalizedEmail)
      } catch (e2) {
        // Timing-Schutz
        await new Promise(resolve => setTimeout(resolve, 150))
        throw new Error('E-Mail oder Passwort ist falsch.')
      }
    }
    
    // Status-Checks
    if (!customer) {
      // Timing-Schutz
      await new Promise(resolve => setTimeout(resolve, 150))
      throw new Error('E-Mail oder Passwort ist falsch.')
    }
    
    if (customer.status === 'DELETED') {
      await new Promise(resolve => setTimeout(resolve, 150))
      throw new Error('E-Mail oder Passwort ist falsch.')
    }
    
    if (customer.status === 'SUSPENDED') {
      throw new Error('Ihr Account wurde gesperrt. Bitte kontaktieren Sie den Support.')
    }
    
    if (customer.status === 'LOCKED') {
      const { data: unlocked } = await supabase.rpc('unlock_customer_account_if_expired', {
        p_customer_id: customer.id
      })
      
      if (!unlocked) {
        throw new Error('E-Mail oder Passwort ist falsch.')
      }
    }
    
    // Passwort-Check
    const { data, error } = await supabase.auth.signInWithPassword({
      email: normalizedEmail,
      password,
    })
    
    if (error) {
      // Passwort falsch
      if (customer) {
        try {
          await supabase.rpc('increment_failed_login_count', {
            p_customer_id: customer.id
          })
        } catch (e) {
          // Ignore if function doesn't exist
        }
      }
      
      throw new Error('E-Mail oder Passwort ist falsch.')
    }
    
    // Post-Password Checks
    if (customer.status === 'UNVERIFIED') {
      await supabase.auth.signOut()
      throw new Error('Bitte bestätigen Sie zuerst Ihre E-Mail-Adresse. Prüfen Sie Ihr Postfach.')
    }
    
    if (customer.status === 'PASSWORD_RESET_REQUIRED') {
      return { ...data, requiresPasswordReset: true }
    }
    
    // Erfolgreich
    if (customer) {
      try {
        await supabase.rpc('reset_failed_login_count', {
          p_customer_id: customer.id
        })
      } catch (e) {
        // Ignore if function doesn't exist
      }
    }
    
    logApiSuccess('POST', 'auth/signIn', { userId: data?.user?.id, email: data?.user?.email })
    return data
  },

  // Registrierung (mit Duplikat-Behandlung)
  async signUp(email: string, password: string, firstName: string, lastName: string) {
    logApiCall('POST', 'auth/signUp', { email, firstName, lastName })
    
    const normalizedEmail = email.toLowerCase().trim()
    
    // 1. Prüfe ob User bereits existiert
    const existingCustomer = await customerService.getCustomerByEmail(normalizedEmail)
    
    if (existingCustomer) {
      if (existingCustomer.status === 'UNVERIFIED') {
        // Strategie: "Upsert UNVERIFIED" - erlaube Re-Registrierung mit Rate-Limit
        const canResend = await supabase.rpc('can_resend_verification', {
          p_customer_id: existingCustomer.id,
          p_cooldown_seconds: 60,
          p_max_per_hour: 5
        })
        
        if (!canResend.data) {
          throw new Error('Bitte warten Sie, bevor Sie eine neue E-Mail anfordern.')
        }
        
        // Resend Verification E-Mail
        const { error: resendError } = await supabase.auth.resend({
          type: 'signup',
          email: normalizedEmail
        })
        
        if (!resendError) {
          await supabase.rpc('update_last_verification_sent_at', {
            p_customer_id: existingCustomer.id
          })
        } else {
          logApiError('POST', 'auth/resendVerification', resendError)
        }
        
        // Immer success zurückgeben (User Enumeration Schutz)
        return {
          user: { id: existingCustomer.id, email: normalizedEmail },
          session: null,
          message: 'Wenn ein Konto existiert, wurde eine E-Mail gesendet.'
        }
      } else if (existingCustomer.status === 'ACTIVE') {
        throw new Error('Ein Account mit dieser E-Mail existiert bereits. Bitte loggen Sie sich ein.')
      } else {
        // DELETED, SUSPENDED, etc. - generische Meldung
        throw new Error('E-Mail oder Passwort ist falsch.')
      }
    }
    
    // 2. Neuer User - normale Registrierung
    const { data, error } = await supabase.auth.signUp({
      email: normalizedEmail,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/confirm`,
        data: {
          first_name: firstName,
          last_name: lastName,
        }
      }
    })
    
    if (error) {
      logApiError('POST', 'auth/signUp', error)
      logError('authService.signUp', error)
      throw error
    }
    
    // 3. Status in customers Tabelle setzen (wird durch Trigger gemacht, aber sicherstellen)
    if (data?.user?.id) {
      // Trigger sollte das automatisch machen, aber wir können es auch explizit setzen
      await supabase.rpc('set_customer_status', {
        p_customer_id: data.user.id,
        p_new_status: 'UNVERIFIED'
      })
      
      await supabase.rpc('update_last_verification_sent_at', {
        p_customer_id: data.user.id
      })
    }
    
    logApiSuccess('POST', 'auth/signUp', { 
      userId: data?.user?.id, 
      email: data?.user?.email,
      emailConfirmed: data?.user?.email_confirmed_at !== null
    })
    return data
  },
  
  // E-Mail-Verifikation erneut senden (mit Rate-Limit)
  async resendVerificationEmail(email: string) {
    logApiCall('POST', 'auth/resendVerification', { email })
    
    const normalizedEmail = email.toLowerCase().trim()
    const customer = await customerService.getCustomerByEmail(normalizedEmail)
    
    // User Enumeration Schutz: Immer success zurückgeben
    if (!customer) {
      return { success: true, message: 'Wenn ein Konto existiert, wurde eine E-Mail gesendet.' }
    }
    
    // Rate-Limit prüfen
    const { data: canResend } = await supabase.rpc('can_resend_verification', {
      p_customer_id: customer.id,
      p_cooldown_seconds: 60,
      p_max_per_hour: 5
    })
    
    if (!canResend) {
      throw new Error('Bitte warten Sie, bevor Sie eine neue E-Mail anfordern.')
    }
    
    // Supabase Resend
    const { error } = await supabase.auth.resend({
      type: 'signup',
      email: normalizedEmail
    })
    
    if (!error) {
      await supabase.rpc('update_last_verification_sent_at', {
        p_customer_id: customer.id
      })
    }
    
    // Immer success (User Enumeration Schutz)
    return { success: true, message: 'Wenn ein Konto existiert, wurde eine E-Mail gesendet.' }
  },
  
  // Passwort-Reset anfordern
  async requestPasswordReset(email: string) {
    logApiCall('POST', 'auth/requestPasswordReset', { email })
    
    const normalizedEmail = email.toLowerCase().trim()
    
    // Immer success zurückgeben (User Enumeration Schutz)
    await supabase.auth.resetPasswordForEmail(normalizedEmail, {
      redirectTo: `${window.location.origin}/auth/reset-password`
    })
    
    // Immer success (auch wenn User nicht existiert)
    return { success: true, message: 'Wenn ein Konto existiert, wurde eine E-Mail gesendet.' }
  },
  
  // Passwort zurücksetzen
  async resetPassword(newPassword: string) {
    logApiCall('POST', 'auth/resetPassword')
    
    const { data, error } = await supabase.auth.updateUser({
      password: newPassword
    })
    
    if (error) {
      logApiError('POST', 'auth/resetPassword', error)
      throw error
    }
    
    // Status aktualisieren
    if (data?.user?.id) {
      await supabase.rpc('update_password_changed_at', {
        p_customer_id: data.user.id
      })
      
      await supabase.rpc('reset_failed_login_count', {
        p_customer_id: data.user.id
      })
      
      // Optional: Alle Sessions killen
      await supabase.rpc('increment_session_version', {
        p_customer_id: data.user.id
      })
    }
    
    logApiSuccess('POST', 'auth/resetPassword', { userId: data?.user?.id })
    return data
  },

  // Logout
  async signOut() {
    logApiCall('POST', 'auth/signOut')
    
    const { error } = await supabase.auth.signOut()
    if (error) {
      logApiError('POST', 'auth/signOut', error)
      logError('authService.signOut', error)
      throw error
    }
    
    logApiSuccess('POST', 'auth/signOut')
  },

  // Aktueller Benutzer
  async getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser()
    return user
  },

  // Session
  async getSession() {
    const { data: { session } } = await supabase.auth.getSession()
    return session
  }
}

// ============================================
// KUNDEN
// ============================================

export const customerService = {
  // Kunde nach E-Mail finden (mit Status)
  async getCustomerByEmail(email: string) {
    const normalizedEmail = email.toLowerCase().trim()
    
    const { data, error } = await supabase
      .rpc('get_customer_with_status', { p_email: normalizedEmail })
    
    if (error && error.code !== 'PGRST116') {
      throw error
    }
    
    return data?.[0] || null
  },
  
  // Kunde nach E-Mail finden (alle Felder)
  async getCustomerByEmailFull(email: string) {
    const normalizedEmail = email.toLowerCase().trim()
    
    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .eq('email', normalizedEmail)
      .is('deleted_at', null)
      .single()
    
    if (error && error.code !== 'PGRST116') {
      throw error
    }
    
    return data || null
  },

  // Kunde nach ID finden
  async getCustomerById(id: string) {
    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .single()
    
    if (error) throw error
    return data
  },

  // Kunden-Statistiken
  async getCustomerStats(customerId: string) {
    const { data, error } = await supabase
      .rpc('get_customer_order_stats', { customer_uuid: customerId })
    
    if (error) throw error
    return data?.[0] || null
  }
}

// ============================================
// AUFTRÄGE
// ============================================

export const orderService = {
  // Alle Aufträge eines Kunden
  async getOrdersByCustomer(customerId: string): Promise<GradingOrderWithService[]> {
    logApiCall('GET', `orders?customerId=${customerId}`)
    
    const { data, error } = await supabase
      .from('grading_orders')
      .select(`
        *,
        grading_services:grading_service_id (
          service_name,
          service_provider
        )
      `)
      .eq('customer_id', customerId)
      .order('created_at', { ascending: false })
    
    if (error) {
      logApiError('GET', 'orders', error)
      logError('orderService.getOrdersByCustomer', error)
      throw error
    }
    
    logApiSuccess('GET', 'orders', { count: data?.length || 0 })
    return (data || []) as GradingOrderWithService[]
  },

  // Einzelnen Auftrag abrufen
  async getOrderById(orderId: string): Promise<GradingOrderWithService | null> {
    const { data, error } = await supabase
      .from('grading_orders')
      .select(`
        *,
        grading_services:grading_service_id (
          service_name,
          service_provider
        )
      `)
      .eq('id', orderId)
      .single()
    
    if (error) {
      if (error.code === 'PGRST116') return null // Not found
      logError('orderService.getOrderById', error)
      throw error
    }
    return data as GradingOrderWithService
  },

  // Karten eines Auftrags abrufen
  async getOrderCards(orderId: string) {
    const { data, error } = await supabase
      .rpc('get_order_cards_with_status', { order_uuid: orderId })
    
    if (error) {
      logError('orderService.getOrderCards', error)
      throw error
    }
    return data || []
  }
}

// ============================================
// KARTEN
// ============================================

export const cardService = {
  // Alle Karten eines Auftrags
  async getCardsByOrder(orderId: string) {
    const { data, error } = await supabase
      .from('cards')
      .select(`
        *,
        charge_cards (
          charges (
            charge_number,
            grading_id,
            status,
            tracking_number_outbound,
            tracking_number_return
          )
        ),
        grading_results (
          grade,
          grade_date,
          has_upcharge,
          upcharge_amount
        )
      `)
      .eq('order_id', orderId)
      .order('created_at', { ascending: true })
    
    if (error) {
      logError('cardService.getCardsByOrder', error)
      throw error
    }
    return data || []
  }
}

// ============================================
// CHARGES
// ============================================

export const chargeService = {
  // Charge-Details abrufen
  async getChargeDetails(chargeId: string) {
    const { data, error } = await supabase
      .rpc('get_charge_details', { charge_uuid: chargeId })
    
    if (error) throw error
    return data?.[0] || null
  }
}

// ============================================
// GRADING ERGEBNISSE
// ============================================

export const gradingService = {
  // Ergebnisse für eine Karte
  async getResultsByCard(cardId: string) {
    const { data, error } = await supabase
      .from('grading_results')
      .select('*')
      .eq('card_id', cardId)
      .single()
    
    if (error) {
      if (error.code === 'PGRST116') return null // Not found
      logError('gradingService.getResultsByCard', error)
      throw error
    }
    return data
  },

  // Alle Ergebnisse eines Auftrags
  async getResultsByOrder(orderId: string) {
    const { data, error } = await supabase
      .from('grading_results')
      .select('*')
      .eq('order_id', orderId)
    
    if (error) {
      logError('gradingService.getResultsByOrder', error)
      throw error
    }
    return data || []
  }
}


