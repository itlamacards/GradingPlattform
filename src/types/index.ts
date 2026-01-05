// ============================================
// TypeScript Types für die gesamte Anwendung
// ============================================

import { Database } from '../lib/supabase'

// ============================================
// DATENBANK-TYPEN (aus Supabase)
// ============================================

export type Customer = Database['public']['Tables']['customers']['Row']
export type GradingOrder = Database['public']['Tables']['grading_orders']['Row']
export type Card = Database['public']['Tables']['cards']['Row']
export type Charge = Database['public']['Tables']['charges']['Row']
export type GradingResult = Database['public']['Tables']['grading_results']['Row']

// ============================================
// UI-TYPEN
// ============================================

export interface OrderStatus {
  pending: 'pending'
  in_progress: 'in_progress'
  completed: 'completed'
  shipped: 'shipped'
  delivered: 'delivered'
}

export type OrderStatusType = OrderStatus[keyof OrderStatus]

export interface CardStatus {
  pending: 'pending'
  grading: 'grading'
  completed: 'completed'
}

export type CardStatusType = CardStatus[keyof CardStatus]

// ============================================
// TRANSFORMED TYPES (für UI)
// ============================================

export interface UICard {
  id: string
  name: string
  type: string
  status: CardStatusType
  grade?: string
  notes?: string
}

export interface UIOrder {
  id: string
  orderNumber: string
  status: OrderStatusType
  submissionDate: string
  estimatedCompletion: string
  items: number
  cards: UICard[]
}

// ============================================
// API RESPONSE TYPES
// ============================================

export interface GradingOrderWithService extends GradingOrder {
  grading_services?: {
    service_name: string
    service_provider: 'PSA' | 'CGC'
  }
}

export interface OrderWithCards extends UIOrder {
  batches?: Array<{
    id: string
    batch_number: number
    status: string
    cards_description: string
    grading_numbers?: Array<{
      id: string
      grading_number: string
      card_description: string
    }>
  }>
}

// ============================================
// ERROR TYPES
// ============================================

export interface AppError {
  message: string
  code?: string
  status?: number
  details?: unknown
}

// ============================================
// UTILITY TYPES
// ============================================

export type Nullable<T> = T | null
export type Optional<T> = T | undefined

