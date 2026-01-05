import { createContext, useContext, useEffect, useState, ReactNode, useCallback } from 'react'
import { User } from '@supabase/supabase-js'
import { authService } from '../services/api'
import { supabase } from '../lib/supabase'
import { logError } from '../utils/errorHandler'

interface AuthContextType {
  user: User | null
  customerId: string | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
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
      // Prüfe ob Admin (hardcoded für Demo)
      if (email === 'admin@admin.de') {
        setIsAdmin(true)
        return
      }

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
      async (_event, session) => {
        if (session?.user) {
          setUser(session.user)
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
    console.log('🔐 signIn aufgerufen:', { email })
    
    try {
      // Admin-Login (hardcoded für Demo)
      if (email === 'admin@admin.de' && password === 'admin') {
        console.log('✅ Admin-Login erkannt')
        setIsAdmin(true)
        setUser({ id: 'admin', email: 'admin@admin.de' } as User)
        setLoading(false)
        return
      }

      // Normaler Login mit Supabase Auth
      console.log('🔐 Versuche Supabase Auth Login...')
      await authService.signIn(email, password)
      console.log('✅ Supabase Auth Login erfolgreich')
      // User wird durch onAuthStateChange gesetzt
    } catch (error) {
      logError('AuthContext.signIn', error)
      setLoading(false)
      throw error
    }
  }

  const signOut = async () => {
    setLoading(true)
    try {
      if (isAdmin) {
        setIsAdmin(false)
        setUser(null)
        setCustomerId(null)
      } else {
        await authService.signOut()
      }
    } catch (error) {
      logError('AuthContext.signOut', error)
      throw error
    } finally {
      setLoading(false)
    }
  }

  return (
    <AuthContext.Provider value={{ user, customerId, loading, signIn, signOut, isAdmin }}>
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


