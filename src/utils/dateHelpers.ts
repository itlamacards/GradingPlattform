// ============================================
// Date Helper Functions
// ============================================

// ============================================
// DATE FORMATTING
// ============================================

export const formatDate = (date: string | Date, format: 'short' | 'long' = 'short'): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date

  if (format === 'long') {
    return dateObj.toLocaleDateString('de-DE', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
    })
  }

  return dateObj.toLocaleDateString('de-DE')
}

export const formatDateTime = (date: string | Date): string => {
  const dateObj = typeof date === 'string' ? new Date(date) : date
  return dateObj.toLocaleString('de-DE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// ============================================
// DATE CALCULATIONS
// ============================================

export const calculateEstimatedCompletion = (
  submissionDate: string | Date,
  serviceDays: number = 30
): Date => {
  const date = typeof submissionDate === 'string' ? new Date(submissionDate) : submissionDate
  const estimated = new Date(date)
  estimated.setDate(estimated.getDate() + serviceDays)
  return estimated
}

export const getDaysUntil = (date: string | Date): number => {
  const target = typeof date === 'string' ? new Date(date) : date
  const now = new Date()
  const diff = target.getTime() - now.getTime()
  return Math.ceil(diff / (1000 * 60 * 60 * 24))
}

export const isOverdue = (date: string | Date): boolean => {
  return getDaysUntil(date) < 0
}

