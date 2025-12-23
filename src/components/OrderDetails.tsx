interface Card {
  id: string
  name: string
  type: string
  status: 'pending' | 'grading' | 'completed'
  grade?: string
  notes?: string
}

interface OrderDetailsProps {
  orderNumber: string
  submissionDate: string
  estimatedCompletion: string
  items: Card[]
  onClose: () => void
}

function OrderDetails({ orderNumber, submissionDate, estimatedCompletion, items, onClose }: OrderDetailsProps) {
  const getCardStatusColor = (status: Card['status']) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800 border-yellow-300',
      grading: 'bg-blue-100 text-blue-800 border-blue-300',
      completed: 'bg-green-100 text-green-800 border-green-300',
    }
    return colors[status]
  }

  const getCardStatusText = (status: Card['status']) => {
    const texts = {
      pending: 'Ausstehend',
      grading: 'Wird bewertet',
      completed: 'Abgeschlossen',
    }
    return texts[status]
  }

  const getCardProgress = (status: Card['status']) => {
    const progress = {
      pending: 20,
      grading: 60,
      completed: 100,
    }
    return progress[status]
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 animate-fadeIn">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal */}
      <div className="relative bg-white/95 backdrop-blur-md rounded-2xl shadow-2xl border border-white/30 max-w-4xl w-full max-h-[90vh] overflow-hidden animate-slideDown">
        {/* Header */}
        <div className="bg-gradient-to-r from-blue-600 to-purple-600 p-6 text-white">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold mb-1">Auftragsdetails</h2>
              <p className="text-blue-100 text-sm">{orderNumber}</p>
            </div>
            <button
              onClick={onClose}
              className="text-white hover:text-gray-200 transition-colors duration-200 p-2 hover:bg-white/20 rounded-lg"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto max-h-[calc(90vh-120px)]">
          {/* Order Info */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="text-sm text-gray-600 mb-1">Eingereicht am</div>
              <div className="text-lg font-semibold text-gray-800">
                {new Date(submissionDate).toLocaleDateString('de-DE', { 
                  day: '2-digit', 
                  month: 'long', 
                  year: 'numeric' 
                })}
              </div>
            </div>
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="text-sm text-gray-600 mb-1">Geschätzte Fertigstellung</div>
              <div className="text-lg font-semibold text-gray-800">
                {new Date(estimatedCompletion).toLocaleDateString('de-DE', { 
                  day: '2-digit', 
                  month: 'long', 
                  year: 'numeric' 
                })}
              </div>
            </div>
          </div>

          {/* Cards List */}
          <div className="mb-4">
            <h3 className="text-xl font-bold text-gray-800 mb-4">
              Eingereichte Karten ({items.length})
            </h3>
            <div className="space-y-4">
              {items.map((card, index) => {
                const progress = getCardProgress(card.status)
                return (
                  <div
                    key={card.id}
                    className="bg-white border border-gray-200 rounded-xl p-5 hover:shadow-lg transition-all duration-300 hover:border-blue-300 animate-fadeIn"
                    style={{ animationDelay: `${index * 0.1}s` }}
                  >
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1">
                        <h4 className="text-lg font-bold text-gray-800 mb-1">{card.name}</h4>
                        <p className="text-sm text-gray-600">{card.type}</p>
                      </div>
                      <span className={`px-3 py-1 text-xs font-semibold rounded-full border ${getCardStatusColor(card.status)}`}>
                        {getCardStatusText(card.status)}
                      </span>
                    </div>

                    {/* Progress Bar */}
                    <div className="mb-4">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm text-gray-600">Fortschritt</span>
                        <span className="text-sm font-semibold text-gray-800">{progress}%</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2.5 overflow-hidden">
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

                    {/* Grade (if completed) */}
                    {card.grade && (
                      <div className="mb-3">
                        <div className="inline-flex items-center px-4 py-2 bg-gradient-to-r from-green-500 to-green-600 text-white rounded-lg">
                          <span className="text-sm font-medium mr-2">Grade:</span>
                          <span className="text-lg font-bold">{card.grade}</span>
                        </div>
                      </div>
                    )}

                    {/* Notes */}
                    {card.notes && (
                      <div className="mt-3 pt-3 border-t border-gray-200">
                        <p className="text-sm text-gray-600 italic">"{card.notes}"</p>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="bg-gray-50 px-6 py-4 border-t border-gray-200 flex justify-end">
          <button
            onClick={onClose}
            className="px-6 py-2 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg hover:from-blue-700 hover:to-blue-800 transition-all duration-200 font-medium shadow-md hover:shadow-lg transform hover:scale-105"
          >
            Schließen
          </button>
        </div>
      </div>
    </div>
  )
}

export default OrderDetails

