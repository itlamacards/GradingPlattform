import { supabase } from '../lib/supabase'

// ============================================
// AUTHENTIFIZIERUNG
// ============================================

export const authService = {
  // Login mit E-Mail und Passwort
  async signIn(email: string, password: string) {
    console.log('🔐 authService.signIn aufgerufen:', { email })
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    
    if (error) {
      console.error('❌ Supabase Auth Fehler:', error)
      throw error
    }
    
    console.log('✅ Supabase Auth erfolgreich:', { user: data?.user?.email })
    return data
  },

  // Registrierung
  async signUp(email: string, password: string, firstName: string, lastName: string) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          first_name: firstName,
          last_name: lastName,
        }
      }
    })
    
    if (error) throw error
    return data
  },

  // Logout
  async signOut() {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
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
  // Kunde nach E-Mail finden
  async getCustomerByEmail(email: string) {
    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .eq('email', email)
      .single()
    
    if (error) throw error
    return data
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
  async getOrdersByCustomer(customerId: string) {
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
    
    if (error) throw error
    return data
  },

  // Einzelnen Auftrag abrufen
  async getOrderById(orderId: string) {
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
    
    if (error) throw error
    return data
  },

  // Karten eines Auftrags abrufen
  async getOrderCards(orderId: string) {
    const { data, error } = await supabase
      .rpc('get_order_cards_with_status', { order_uuid: orderId })
    
    if (error) throw error
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
    
    if (error) throw error
    return data
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
    
    if (error && error.code !== 'PGRST116') throw error // PGRST116 = no rows returned
    return data
  },

  // Alle Ergebnisse eines Auftrags
  async getResultsByOrder(orderId: string) {
    const { data, error } = await supabase
      .from('grading_results')
      .select('*')
      .eq('order_id', orderId)
    
    if (error) throw error
    return data
  }
}


