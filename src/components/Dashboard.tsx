import { useEffect, useState, useMemo, useCallback } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { orderService } from '../services/api'
import OrderDetails from './OrderDetails'
import { UIOrder, GradingOrderWithService } from '../types'
import { 
  getOrderStatusColor, 
  getOrderStatusText, 
  getOrderProgressPercentage,
  mapDbStatusToOrderStatus 
} from '../utils/statusHelpers'
import { getUserFriendlyErrorMessage, logError } from '../utils/errorHandler'
import { formatDate, calculateEstimatedCompletion } from '../utils/dateHelpers'

function Dashboard() {
  const { signOut, customerId } = useAuth()
  const [selectedOrder, setSelectedOrder] = useState<UIOrder | null>(null)
  const [orders, setOrders] = useState<UIOrder[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadOrders = useCallback(async () => {
    if (!customerId) {
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      setError(null)
      const data = await orderService.getOrdersByCustomer(customerId) as GradingOrderWithService[]
      
      // Transformiere Daten in das erwartete Format
      const transformedOrders: UIOrder[] = data.map((order) => {
        const submissionDate = new Date(order.submission_date)
        const estimatedCompletion = calculateEstimatedCompletion(
          submissionDate,
          30 // Standard: 30 Tage (könnte aus Service kommen)
        )

        return {
          id: order.id,
          orderNumber: order.order_number,
          status: mapDbStatusToOrderStatus(order.status),
          submissionDate: order.submission_date,
          estimatedCompletion: estimatedCompletion.toISOString(),
          items: 0, // Wird später geladen wenn Karten-API verfügbar ist
          cards: [] // Wird später geladen
        }
      })
      
      setOrders(transformedOrders)
    } catch (err) {
      logError('Dashboard.loadOrders', err)
      setError(getUserFriendlyErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [customerId])

  useEffect(() => {
    loadOrders()
  }, [loadOrders])

  // Fallback: Wenn keine Daten geladen werden konnten, zeige Demo-Daten
  const displayOrders: UIOrder[] = orders.length > 0 ? orders : [
    {
      id: '1',
      orderNumber: 'ORD-2024-001',
      status: 'in_progress',
      submissionDate: '2024-01-15',
      estimatedCompletion: '2024-02-15',
      items: 5,
      cards: [
        {
          id: '1',
          name: 'Pikachu VMAX',
          type: 'Pokemon Card',
          status: 'grading',
          notes: 'In Bearbeitung bei PSA'
        },
        {
          id: '2',
          name: 'Charizard Base Set',
          type: 'Pokemon Card',
          status: 'grading',
          notes: 'Wird derzeit bewertet'
        },
        {
          id: '3',
          name: 'Blastoise Base Set',
          type: 'Pokemon Card',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        },
        {
          id: '4',
          name: 'Venusaur Base Set',
          type: 'Pokemon Card',
          status: 'grading',
          notes: 'In Bearbeitung'
        },
        {
          id: '5',
          name: 'Mewtwo Base Set',
          type: 'Pokemon Card',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        }
      ]
    },
    {
      id: '2',
      orderNumber: 'ORD-2024-002',
      status: 'completed',
      submissionDate: '2024-01-10',
      estimatedCompletion: '2024-02-10',
      items: 3,
      cards: [
        {
          id: '1',
          name: 'LeBron James Rookie Card',
          type: 'Sports Card',
          status: 'completed',
          grade: 'PSA 10',
          notes: 'Perfekter Zustand, Gem Mint'
        },
        {
          id: '2',
          name: 'Michael Jordan Rookie Card',
          type: 'Sports Card',
          status: 'completed',
          grade: 'PSA 9',
          notes: 'Sehr guter Zustand, leichte Kratzer'
        },
        {
          id: '3',
          name: 'Kobe Bryant Rookie Card',
          type: 'Sports Card',
          status: 'completed',
          grade: 'PSA 9',
          notes: 'Guter Zustand'
        }
      ]
    },
    {
      id: '3',
      orderNumber: 'ORD-2024-003',
      status: 'pending',
      submissionDate: '2024-01-20',
      estimatedCompletion: '2024-02-20',
      items: 8,
      cards: [
        {
          id: '1',
          name: 'Spider-Man #1',
          type: 'Comic',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        },
        {
          id: '2',
          name: 'Batman #1',
          type: 'Comic',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        },
        {
          id: '3',
          name: 'Superman #1',
          type: 'Comic',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        },
        {
          id: '4',
          name: 'X-Men #1',
          type: 'Comic',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        },
        {
          id: '5',
          name: 'Avengers #1',
          type: 'Comic',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        },
        {
          id: '6',
          name: 'Iron Man #1',
          type: 'Comic',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        },
        {
          id: '7',
          name: 'Hulk #1',
          type: 'Comic',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        },
        {
          id: '8',
          name: 'Thor #1',
          type: 'Comic',
          status: 'pending',
          notes: 'Wartet auf Bewertung'
        }
      ]
    },
  ]

  // Memoized Stats für bessere Performance
  const stats = useMemo(() => ({
    total: orders.length,
    inProgress: orders.filter(o => o.status === 'in_progress').length,
    completed: orders.filter(o => o.status === 'completed').length,
    pending: orders.filter(o => o.status === 'pending').length,
  }), [orders])

  return (
    <div className="min-h-screen p-4 md:p-8 animate-fadeIn">
      {/* Header */}
      <header className="mb-8 animate-slideDown">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <img 
              src="/lamacards-logo.webp" 
              alt="Lama Cards Logo" 
              className="h-16 w-auto drop-shadow-lg"
            />
            <h1 className="text-2xl md:text-3xl font-bold text-white drop-shadow-lg">
              Grading Portal
            </h1>
          </div>
          <button
            onClick={signOut}
            className="px-4 py-2 bg-white/20 backdrop-blur-md text-white rounded-lg hover:bg-white/30 transition-all duration-300 border border-white/30 hover:scale-105 hover:shadow-lg"
          >
            Abmelden
          </button>
        </div>
      </header>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg border border-white/30 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn" style={{ animationDelay: '0.1s' }}>
          <div className="text-sm text-gray-600 mb-1">Gesamt Aufträge</div>
          <div className="text-3xl font-bold text-gray-800">{stats.total}</div>
        </div>
        <div className="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg border border-white/30 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn" style={{ animationDelay: '0.2s' }}>
          <div className="text-sm text-gray-600 mb-1">In Bearbeitung</div>
          <div className="text-3xl font-bold text-blue-600">{stats.inProgress}</div>
        </div>
        <div className="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg border border-white/30 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn" style={{ animationDelay: '0.3s' }}>
          <div className="text-sm text-gray-600 mb-1">Abgeschlossen</div>
          <div className="text-3xl font-bold text-green-600">{stats.completed}</div>
        </div>
        <div className="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg border border-white/30 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn" style={{ animationDelay: '0.4s' }}>
          <div className="text-sm text-gray-600 mb-1">Ausstehend</div>
          <div className="text-3xl font-bold text-yellow-600">{stats.pending}</div>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-4">
          {error}
        </div>
      )}

      {/* Orders Table */}
      <div className="bg-white/90 backdrop-blur-md rounded-xl shadow-lg border border-white/30 overflow-hidden animate-fadeIn" style={{ animationDelay: '0.5s' }}>
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-2xl font-bold text-gray-800">Meine Aufträge</h2>
        </div>
        {loading ? (
          <div className="p-8 text-center text-gray-600">Lädt Aufträge...</div>
        ) : orders.length === 0 ? (
          <div className="p-8 text-center text-gray-600">Keine Aufträge gefunden</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Auftragsnummer
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Fortschritt
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Items
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Eingereicht
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Geschätzte Fertigstellung
                </th>
                <th className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Aktionen
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {displayOrders.map((order, index) => {
                const progress = getOrderProgressPercentage(order.status)
                return (
                  <tr 
                    key={order.id} 
                    className="hover:bg-gray-50 transition-colors duration-200 animate-fadeIn"
                    style={{ animationDelay: `${0.6 + index * 0.1}s` }}
                  >
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">{order.orderNumber}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-3 py-1 inline-flex text-xs leading-5 font-semibold rounded-full border ${getOrderStatusColor(order.status)}`}>
                        {getOrderStatusText(order.status)}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="w-32">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-xs text-gray-600">{progress}%</span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                          <div
                            className={`h-full rounded-full transition-all duration-500 ease-out ${
                              progress === 100 
                                ? 'bg-gradient-to-r from-green-500 to-green-600' 
                                : progress >= 50
                                ? 'bg-gradient-to-r from-blue-500 to-blue-600'
                                : 'bg-gradient-to-r from-yellow-500 to-yellow-600'
                            }`}
                            style={{ width: `${progress}%` }}
                          />
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {order.items} Items
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(order.submissionDate)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(order.estimatedCompletion)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button 
                        onClick={() => setSelectedOrder(order)}
                        className="text-blue-600 hover:text-blue-900 transition-colors duration-200 hover:underline font-medium"
                        aria-label={`Details für Auftrag ${order.orderNumber} anzeigen`}
                      >
                        Details
                      </button>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
          </div>
        )}
      </div>

      {/* Order Details Modal */}
      {selectedOrder && (
        <OrderDetails
          orderNumber={selectedOrder.orderNumber}
          submissionDate={selectedOrder.submissionDate}
          estimatedCompletion={selectedOrder.estimatedCompletion}
          items={selectedOrder.cards}
          onClose={() => setSelectedOrder(null)}
        />
      )}
    </div>
  )
}

export default Dashboard
