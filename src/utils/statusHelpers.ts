// ============================================
// Status-Helper-Funktionen
// ============================================

import { OrderStatusType, CardStatusType } from '../types'

// ============================================
// ORDER STATUS HELPERS
// ============================================

export const getOrderStatusColor = (status: OrderStatusType): string => {
  const colors: Record<OrderStatusType, string> = {
    pending: 'bg-yellow-100 text-yellow-800 border-yellow-300',
    in_progress: 'bg-blue-100 text-blue-800 border-blue-300',
    completed: 'bg-green-100 text-green-800 border-green-300',
    shipped: 'bg-purple-100 text-purple-800 border-purple-300',
    delivered: 'bg-gray-100 text-gray-800 border-gray-300',
  }
  return colors[status] || colors.pending
}

export const getOrderStatusText = (status: OrderStatusType): string => {
  const texts: Record<OrderStatusType, string> = {
    pending: 'Ausstehend',
    in_progress: 'In Bearbeitung',
    completed: 'Abgeschlossen',
    shipped: 'Versandt',
    delivered: 'Geliefert',
  }
  return texts[status] || texts.pending
}

export const getOrderProgressPercentage = (status: OrderStatusType): number => {
  const progress: Record<OrderStatusType, number> = {
    pending: 10,
    in_progress: 60,
    completed: 100,
    shipped: 100,
    delivered: 100,
  }
  return progress[status] || 0
}

// ============================================
// CARD STATUS HELPERS
// ============================================

export const getCardStatusColor = (status: CardStatusType): string => {
  const colors: Record<CardStatusType, string> = {
    pending: 'bg-yellow-100 text-yellow-800 border-yellow-300',
    grading: 'bg-blue-100 text-blue-800 border-blue-300',
    completed: 'bg-green-100 text-green-800 border-green-300',
  }
  return colors[status] || colors.pending
}

export const getCardStatusText = (status: CardStatusType): string => {
  const texts: Record<CardStatusType, string> = {
    pending: 'Ausstehend',
    grading: 'Wird bewertet',
    completed: 'Abgeschlossen',
  }
  return texts[status] || texts.pending
}

export const getCardProgress = (status: CardStatusType): number => {
  const progress: Record<CardStatusType, number> = {
    pending: 20,
    grading: 60,
    completed: 100,
  }
  return progress[status] || 0
}

// ============================================
// STATUS MAPPING (DB → UI)
// ============================================

export const mapDbStatusToOrderStatus = (dbStatus: string): OrderStatusType => {
  const statusMap: Record<string, OrderStatusType> = {
    'submitted': 'pending',
    'sent_to_grading': 'in_progress',
    'arrived_at_grading': 'in_progress',
    'in_grading': 'in_progress',
    'grading_completed': 'completed',
    'sent_back': 'shipped',
    'arrived_back': 'delivered',
    'completed': 'completed',
  }
  return statusMap[dbStatus] || 'pending'
}

export const mapDbStatusToCardStatus = (dbStatus: string): CardStatusType => {
  const statusMap: Record<string, CardStatusType> = {
    'submitted': 'pending',
    'stored': 'pending',
    'in_charge': 'pending',
    'sent_to_grading': 'grading',
    'arrived_at_grading': 'grading',
    'in_grading': 'grading',
    'grading_completed': 'completed',
    'sent_back': 'completed',
    'arrived_back': 'completed',
    'ready_for_pickup': 'completed',
    'completed': 'completed',
  }
  return statusMap[dbStatus] || 'pending'
}

