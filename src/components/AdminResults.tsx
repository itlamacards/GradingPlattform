import { useState } from 'react'
import OrderDetails from './OrderDetails'
import { useAuth } from '../contexts/AuthContext'
import { UICard } from '../types'
import { formatDate } from '../utils/dateHelpers'

interface GradingResult {
  id: string
  orderNumber: string
  customerName: string
  itemName: string
  itemType: string
  grade: string
  submissionDate: string
  completionDate: string
  images: string[]
  notes: string
  cards?: UICard[]
}

function AdminResults() {
  const { signOut } = useAuth()
  const [selectedResult, setSelectedResult] = useState<GradingResult | null>(null)

  // Beispiel-Grading-Ergebnisse
  const results: GradingResult[] = [
    {
      id: '1',
      orderNumber: 'ORD-2024-001',
      customerName: 'Max Mustermann',
      itemName: 'Pikachu VMAX',
      itemType: 'Pokemon Card',
      grade: 'PSA 10',
      submissionDate: '2024-01-15',
      completionDate: '2024-02-10',
      images: [],
      notes: 'Perfekter Zustand, keine Kratzer oder Flecken',
      cards: [
        {
          id: '1',
          name: 'Pikachu VMAX',
          type: 'Pokemon Card',
          status: 'completed',
          grade: 'PSA 10',
          notes: 'Perfekter Zustand, keine Kratzer oder Flecken'
        },
        {
          id: '2',
          name: 'Charizard Base Set',
          type: 'Pokemon Card',
          status: 'completed',
          grade: 'PSA 9',
          notes: 'Leichte Kratzer auf der Rückseite'
        },
        {
          id: '3',
          name: 'Blastoise Base Set',
          type: 'Pokemon Card',
          status: 'completed',
          grade: 'PSA 8',
          notes: 'Guter Zustand'
        }
      ]
    },
    {
      id: '2',
      orderNumber: 'ORD-2024-001',
      customerName: 'Max Mustermann',
      itemName: 'Charizard Base Set',
      itemType: 'Pokemon Card',
      grade: 'PSA 9',
      submissionDate: '2024-01-15',
      completionDate: '2024-02-10',
      images: [],
      notes: 'Leichte Kratzer auf der Rückseite',
      cards: [
        {
          id: '1',
          name: 'Charizard Base Set',
          type: 'Pokemon Card',
          status: 'completed',
          grade: 'PSA 9',
          notes: 'Leichte Kratzer auf der Rückseite'
        }
      ]
    },
    {
      id: '3',
      orderNumber: 'ORD-2024-002',
      customerName: 'Anna Schmidt',
      itemName: 'LeBron James Rookie Card',
      itemType: 'Sports Card',
      grade: 'BGS 9.5',
      submissionDate: '2024-01-10',
      completionDate: '2024-02-05',
      images: [],
      notes: 'Ausgezeichneter Zustand',
      cards: [
        {
          id: '1',
          name: 'LeBron James Rookie Card',
          type: 'Sports Card',
          status: 'completed',
          grade: 'BGS 9.5',
          notes: 'Ausgezeichneter Zustand'
        },
        {
          id: '2',
          name: 'Michael Jordan Rookie Card',
          type: 'Sports Card',
          status: 'completed',
          grade: 'PSA 10',
          notes: 'Perfekter Zustand'
        }
      ]
    },
    {
      id: '4',
      orderNumber: 'ORD-2024-003',
      customerName: 'Tom Weber',
      itemName: 'Spider-Man #1',
      itemType: 'Comic',
      grade: 'CGC 9.8',
      submissionDate: '2024-01-20',
      completionDate: '2024-02-18',
      images: [],
      notes: 'Sehr gut erhalten, minimale Altersspuren',
      cards: [
        {
          id: '1',
          name: 'Spider-Man #1',
          type: 'Comic',
          status: 'completed',
          grade: 'CGC 9.8',
          notes: 'Sehr gut erhalten, minimale Altersspuren'
        },
        {
          id: '2',
          name: 'Batman #1',
          type: 'Comic',
          status: 'completed',
          grade: 'CGC 9.6',
          notes: 'Guter Zustand'
        }
      ]
    },
  ]

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
            <div>
              <h1 className="text-2xl md:text-3xl font-bold text-white drop-shadow-lg">
                Admin - Grading Ergebnisse
              </h1>
              <p className="text-white/80 text-sm drop-shadow">Verwaltung aller Grading-Ergebnisse</p>
            </div>
          </div>
          <button
            onClick={signOut}
            className="px-4 py-2 bg-white/20 backdrop-blur-md text-white rounded-lg hover:bg-white/30 transition-all duration-300 border border-white/30 hover:scale-105 hover:shadow-lg"
          >
            Abmelden
          </button>
        </div>
      </header>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg border border-white/30 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn" style={{ animationDelay: '0.1s' }}>
          <div className="text-sm text-gray-600 mb-1">Gesamt Ergebnisse</div>
          <div className="text-3xl font-bold text-gray-800">{results.length}</div>
        </div>
        <div className="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg border border-white/30 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn" style={{ animationDelay: '0.2s' }}>
          <div className="text-sm text-gray-600 mb-1">PSA 10</div>
          <div className="text-3xl font-bold text-green-600">
            {results.filter(r => r.grade === 'PSA 10').length}
          </div>
        </div>
        <div className="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg border border-white/30 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn" style={{ animationDelay: '0.3s' }}>
          <div className="text-sm text-gray-600 mb-1">PSA 9</div>
          <div className="text-3xl font-bold text-blue-600">
            {results.filter(r => r.grade === 'PSA 9').length}
          </div>
        </div>
        <div className="bg-white/90 backdrop-blur-md rounded-xl p-6 shadow-lg border border-white/30 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1 animate-fadeIn" style={{ animationDelay: '0.4s' }}>
          <div className="text-sm text-gray-600 mb-1">Andere</div>
          <div className="text-3xl font-bold text-purple-600">
            {results.filter(r => !r.grade.includes('PSA')).length}
          </div>
        </div>
      </div>

      {/* Results Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {results.map((result, index) => (
          <div 
            key={result.id} 
            className="bg-white/90 backdrop-blur-md rounded-xl shadow-lg border border-white/30 overflow-hidden hover:shadow-xl transition-all duration-300 transform hover:-translate-y-2 animate-fadeIn"
            style={{ animationDelay: `${0.5 + index * 0.1}s` }}
          >
            {/* Grade Badge Header */}
            <div className="bg-gradient-to-r from-blue-600 to-purple-600 p-6 text-white relative overflow-hidden">
              <div className="absolute inset-0 bg-black/10"></div>
              <div className="relative z-10">
                <div className="text-sm opacity-90 mb-1">{result.itemType}</div>
                <div className="text-3xl font-bold">{result.grade}</div>
              </div>
            </div>

            {/* Content */}
            <div className="p-6">
              <div className="mb-4">
                <h3 className="text-xl font-bold text-gray-800 mb-1">{result.itemName}</h3>
              </div>

              <div className="space-y-2 mb-4">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Auftrag:</span>
                  <span className="font-medium text-gray-800">{result.orderNumber}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Kunde:</span>
                  <span className="font-medium text-gray-800">{result.customerName}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Eingereicht:</span>
                  <span className="font-medium text-gray-800">
                    {formatDate(result.submissionDate)}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Abgeschlossen:</span>
                  <span className="font-medium text-gray-800">
                    {formatDate(result.completionDate)}
                  </span>
                </div>
              </div>

              {result.notes && (
                <div className="mt-4 pt-4 border-t border-gray-200">
                  <p className="text-sm text-gray-600 italic">"{result.notes}"</p>
                </div>
              )}

              <div className="mt-4 flex space-x-2">
                <button 
                  onClick={() => setSelectedResult(result)}
                  className="flex-1 bg-gradient-to-r from-blue-600 to-blue-700 text-white py-2 rounded-lg hover:from-blue-700 hover:to-blue-800 transition-all duration-200 text-sm font-medium shadow-md hover:shadow-lg transform hover:scale-105"
                >
                  Details
                </button>
                <button className="flex-1 bg-gray-200 text-gray-700 py-2 rounded-lg hover:bg-gray-300 transition-all duration-200 text-sm font-medium shadow-md hover:shadow-lg transform hover:scale-105">
                  Bearbeiten
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Order Details Modal */}
      {selectedResult && selectedResult.cards && (
        <OrderDetails
          orderNumber={selectedResult.orderNumber}
          submissionDate={selectedResult.submissionDate}
          estimatedCompletion={selectedResult.completionDate}
          items={selectedResult.cards}
          onClose={() => setSelectedResult(null)}
        />
      )}
    </div>
  )
}

export default AdminResults
