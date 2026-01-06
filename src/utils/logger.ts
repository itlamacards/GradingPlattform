// ============================================
// Development Logger
// ============================================

type LogLevel = 'debug' | 'info' | 'warn' | 'error' | 'success'

interface LogOptions {
  context?: string
  data?: any
  group?: string
  collapsed?: boolean
}

// Nur in Development aktiv
const isDevelopment = import.meta.env.DEV

// Farben für Console (nur in Development)
const colors = {
  debug: '#6B7280',    // Gray
  info: '#3B82F6',      // Blue
  warn: '#F59E0B',      // Amber
  error: '#EF4444',     // Red
  success: '#10B981',   // Green
  reset: '#000000'
}

// Emoji für verschiedene Log-Typen
const emojis = {
  debug: '🔍',
  info: 'ℹ️',
  warn: '⚠️',
  error: '❌',
  success: '✅'
}

// Format Timestamp
const getTimestamp = (): string => {
  const now = new Date()
  const time = now.toLocaleTimeString('de-DE', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
  const ms = now.getMilliseconds().toString().padStart(3, '0')
  return `${time}.${ms}`
}

// Format Log-Message
const formatMessage = (level: LogLevel, message: string, context?: string): string => {
  const emoji = emojis[level]
  const timestamp = getTimestamp()
  const contextPart = context ? `[${context}]` : ''
  return `${emoji} ${timestamp} ${contextPart} ${message}`
}

// Console-Styling
const getConsoleStyle = (level: LogLevel): string => {
  const color = colors[level]
  return `
    color: ${color};
    font-weight: bold;
    font-size: 11px;
    padding: 2px 4px;
  `.trim()
}

// Haupt-Logger-Funktion
const log = (level: LogLevel, message: string, options: LogOptions = {}) => {
  if (!isDevelopment) return

  const { context, data, group, collapsed = false } = options
  const formattedMessage = formatMessage(level, message, context)
  const style = getConsoleStyle(level)

  // Gruppierung
  if (group) {
    const groupMethod = collapsed ? console.groupCollapsed : console.group
    groupMethod(`%c${group}`, style)
  }

  // Log ausgeben
  if (data !== undefined) {
    console.log(`%c${formattedMessage}`, style, data)
  } else {
    console.log(`%c${formattedMessage}`, style)
  }

  // Gruppe schließen
  if (group) {
    console.groupEnd()
  }
}

// ============================================
// Public API
// ============================================

export const logger = {
  // Debug - für detaillierte Entwicklungs-Infos
  debug: (message: string, options?: LogOptions) => {
    log('debug', message, options)
  },

  // Info - für allgemeine Informationen
  info: (message: string, options?: LogOptions) => {
    log('info', message, options)
  },

  // Success - für erfolgreiche Operationen
  success: (message: string, options?: LogOptions) => {
    log('success', message, options)
  },

  // Warn - für Warnungen
  warn: (message: string, options?: LogOptions) => {
    log('warn', message, options)
  },

  // Error - für Fehler
  error: (message: string, options?: LogOptions) => {
    log('error', message, options)
  },

  // Gruppierte Logs für zusammengehörige Operationen
  group: (name: string, callback: () => void, collapsed = false) => {
    if (!isDevelopment) {
      callback()
      return
    }

    const style = getConsoleStyle('info')
    const groupMethod = collapsed ? console.groupCollapsed : console.group
    groupMethod(`%c${name}`, style)
    
    try {
      callback()
    } finally {
      console.groupEnd()
    }
  },

  // Table für strukturierte Daten
  table: (data: any, context?: string) => {
    if (!isDevelopment) return
    
    if (context) {
      console.group(`📊 ${context}`)
    }
    console.table(data)
    if (context) {
      console.groupEnd()
    }
  },

  // Performance-Timing
  time: (label: string) => {
    if (!isDevelopment) return
    console.time(`⏱️ ${label}`)
  },

  timeEnd: (label: string) => {
    if (!isDevelopment) return
    console.timeEnd(`⏱️ ${label}`)
  }
}

// ============================================
// Convenience-Funktionen für häufige Use-Cases
// ============================================

// API-Call Logging
export const logApiCall = (method: string, endpoint: string, data?: any) => {
  logger.info(`${method} ${endpoint}`, {
    context: 'API',
    data,
    group: `🌐 API Call: ${method} ${endpoint}`,
    collapsed: true
  })
}

// API Success
export const logApiSuccess = (method: string, endpoint: string, response?: any) => {
  logger.success(`${method} ${endpoint} erfolgreich`, {
    context: 'API',
    data: response,
    group: `🌐 API Call: ${method} ${endpoint}`,
    collapsed: true
  })
}

// API Error
export const logApiError = (method: string, endpoint: string, error: any) => {
  logger.error(`${method} ${endpoint} fehlgeschlagen`, {
    context: 'API',
    data: error,
    group: `🌐 API Call: ${method} ${endpoint}`,
    collapsed: false
  })
}

// Auth Events
export const logAuth = (event: string, data?: any) => {
  logger.info(event, {
    context: 'Auth',
    data,
    group: '🔐 Authentication',
    collapsed: true
  })
}

// Component Lifecycle
export const logComponent = (component: string, event: string, data?: any) => {
  logger.debug(`${component}: ${event}`, {
    context: 'Component',
    data,
    group: `⚛️ ${component}`,
    collapsed: true
  })
}

