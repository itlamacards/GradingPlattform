import { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { User } from '@supabase/supabase-js'
import { authService } from '../services/api'
import { supabase } from '../lib/supabase'

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

  useEffect(() => {
    // Prüfe aktuelle Session
    checkUser()

    // Höre auf Auth-Änderungen
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
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
  }, [])

  const checkUser = async () => {
    try {
      const session = await authService.getSession()
      if (session?.user) {
        setUser(session.user)
        await loadCustomerData(session.user.id, session.user.email || '')
      }
    } catch (error) {
      console.error('Error checking user:', error)
    } finally {
      setLoading(false)
    }
  }

  const loadCustomerData = async (userId: string, email: string) => {
    try {
      // Prüfe ob Admin (hardcoded für Demo)
      if (email === 'admin@admin.de') {
        setIsAdmin(true)
        return
      }

      // Lade Kunden-Daten
      const { data: customer } = await supabase
        .from('customers')
        .select('id')
        .eq('email', email)
        .single()

      if (customer) {
        setCustomerId(customer.id)
      }
    } catch (error) {
      console.error('Error loading customer data:', error)
    }
  }

  const signIn = async (email: string, password: string) => {
    setLoading(true)
    try {
      // Admin-Login (hardcoded für Demo)
      if (email === 'admin@admin.de' && password === 'admin') {
        setIsAdmin(true)
        setUser({ id: 'admin', email: 'admin@admin.de' } as User)
        setLoading(false)
        return
      }

      // Normaler Login mit Supabase Auth
      await authService.signIn(email, password)
      // User wird durch onAuthStateChange gesetzt
    } catch (error) {
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
      console.error('Error signing out:', error)
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


