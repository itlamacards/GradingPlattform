import { createClient } from '@supabase/supabase-js'

// Supabase Credentials aus Umgebungsvariablen
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// Validierung der Umgebungsvariablen
if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'Fehlende Supabase-Umgebungsvariablen. Bitte prüfe .env.local Datei.\n' +
    'Benötigt: VITE_SUPABASE_URL und VITE_SUPABASE_ANON_KEY'
  )
}

// Supabase Client erstellen
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// TypeScript Types für die Datenbank
export type Database = {
  public: {
    Tables: {
      customers: {
        Row: {
          id: string
          customer_number: string
          first_name: string
          last_name: string
          email: string
          phone: string | null
          password_hash: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          customer_number: string
          first_name: string
          last_name: string
          email: string
          phone?: string | null
          password_hash?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          customer_number?: string
          first_name?: string
          last_name?: string
          email?: string
          phone?: string | null
          password_hash?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      grading_orders: {
        Row: {
          id: string
          customer_id: string
          order_number: string
          submission_date: string
          cards_description: string
          grading_service_id: string
          grading_provider: 'PSA' | 'CGC'
          amount_paid: number
          has_surcharge: boolean
          surcharge_amount: number
          status: string
          payment_status: 'pending' | 'paid'
          notes: string | null
          created_at: string
          updated_at: string
        }
      }
      cards: {
        Row: {
          id: string
          order_id: string
          card_description: string
          card_type: string | null
          status: string
          notes: string | null
          created_at: string
          updated_at: string
        }
      }
      charges: {
        Row: {
          id: string
          charge_number: string
          grading_service_id: string
          grading_provider: 'PSA' | 'CGC'
          grading_id: string | null
          status: string
          tracking_number_outbound: string | null
          tracking_number_return: string | null
          sent_date: string | null
          arrived_date: string | null
          completed_date: string | null
          notes: string | null
          created_at: string
          updated_at: string
        }
      }
      grading_results: {
        Row: {
          id: string
          card_id: string
          order_id: string
          charge_id: string
          grade: string | null
          grade_date: string | null
          has_upcharge: boolean
          upcharge_amount: number
          upcharge_reason: string | null
          has_error: boolean
          error_description: string | null
          api_response: any | null
          created_at: string
          updated_at: string
        }
      }
    }
  }
}


