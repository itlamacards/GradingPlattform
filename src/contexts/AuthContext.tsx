import { createContext, useContext, useEffect, useState, ReactNode, useCallback } from 'react'
import { User } from '@supabase/supabase-js'
import { authService } from '../services/api'
import { supabase } from '../lib/supabase'
import { logError } from '../utils/errorHandler'
import { logAuth } from '../utils/logger'

interface AuthContextType {
  user: User | null
  customerId: string | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<any>
  signUp: (email: string, password: string, firstName: string, lastName: string) => Promise<any>
  signOut: () => Promise<void>
  isAdmin: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [customerId, setCustomerId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [isAdmin, setIsAdmin] = useState(false)

  const loadCustomerData = useCallback(async (_userId: string, email: string) => {
    try {
      // Lade Kunden-Daten
      const { data: customer, error } = await supabase
        .from('customers')
        .select('id')
        .eq('email', email)
        .single()

      if (error && error.code !== 'PGRST116') {
        // PGRST116 = no rows returned (ist OK)
        throw error
      }

      if (customer) {
        setCustomerId(customer.id)
      }
    } catch (error) {
      logError('AuthContext.loadCustomerData', error)
    }
  }, [])

  const checkUser = useCallback(async () => {
    try {
      const session = await authService.getSession()
      if (session?.user) {
        setUser(session.user)
        await loadCustomerData(session.user.id, session.user.email || '')
      }
    } catch (error) {
      logError('AuthContext.checkUser', error)
    } finally {
      setLoading(false)
    }
  }, [loadCustomerData])

  useEffect(() => {
    // Prüfe aktuelle Session
    checkUser()

    // Höre auf Auth-Änderungen
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (session?.user) {
          setUser(session.user)
          
          // E-Mail-Verifikation synchronisieren
          if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
            // Prüfe ob E-Mail bestätigt ist (via Session)
            // Supabase setzt email_confirmed_at in der Session
            if (session.user && (session.user as any).email_confirmed_at) {
              // Markiere E-Mail als verifiziert in customers Tabelle
              try {
                await supabase.rpc('mark_email_as_verified', {
                  p_customer_id: session.user.id
                })
              } catch (error) {
                logError('AuthContext.onAuthStateChange.mark_email_as_verified', error)
              }
            }
          }
          
          // Versuche Customer-ID aus user metadata zu holen oder aus customers Tabelle
          await loadCustomerData(session.user.id, session.user.email || '')
        } else {
          setUser(null)
          setCustomerId(null)
          setIsAdmin(false)
        }
        setLoading(false)
      }
    )

    return () => subscription.unsubscribe()
  }, [checkUser, loadCustomerData])

  const signIn = async (email: string, password: string) => {
    setLoading(true)
    logAuth('Login-Versuch gestartet', { email })
    
    try {
      const result = await authService.signIn(email, password)
      logAuth('Login erfolgreich', { email })
      // User wird durch onAuthStateChange gesetzt
      return result
    } catch (error) {
      logError('AuthContext.signIn', error)
      setLoading(false)
      throw error
    }
  }

  const signUp = async (email: string, password: string, firstName: string, lastName: string) => {
    setLoading(true)
    logAuth('Registrierung gestartet', { email, firstName, lastName })
    
    try {
      const data = await authService.signUp(email, password, firstName, lastName)
      
      logAuth('Registrierung erfolgreich', { 
        userId: data?.user?.id, 
        email: data?.user?.email,
        emailConfirmed: (data?.user as any)?.email_confirmed_at !== null && (data?.user as any)?.email_confirmed_at !== undefined
      })
      
      // WICHTIG: User wird NIE automatisch eingeloggt nach Registrierung (Sicherheit!)
      // Auch wenn bereits bestätigt, muss sich User explizit einloggen
      // Wir loggen den User aus, falls er durch signUp automatisch eingeloggt wurde
      if (data?.session) {
        logAuth('User wurde automatisch eingeloggt - Logout für Sicherheit', { email })
        await authService.signOut()
        setUser(null)
        setCustomerId(null)
      }
      
      setLoading(false)
      
      // Der Trigger in der Datenbank erstellt automatisch den Customer-Eintrag
      
      return data
    } catch (error) {
      logError('AuthContext.signUp', error)
      setLoading(false)
      throw error
    }
  }

  const signOut = async () => {
    setLoading(true)
    try {
      await authService.signOut()
      setUser(null)
      setCustomerId(null)
      setIsAdmin(false)
    } catch (error) {
      logError('AuthContext.signOut', error)
      throw error
    } finally {
      setLoading(false)
    }
  }

  return (
    <AuthContext.Provider value={{ user, customerId, loading, signIn, signUp, signOut, isAdmin }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}


