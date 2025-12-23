# Kundenportal für Grading-Käufer - Projektplan

## 📋 Projektübersicht

Ein modernes Kundenportal, das Grading-Käufern ermöglicht, den Status ihrer Grading-Aufträge in Echtzeit zu verfolgen.

## 🎯 Hauptfunktionen

1. **Kunden-Login/Authentifizierung**
   - Sichere Anmeldung per E-Mail/Passwort
   - Passwort-Reset-Funktionalität
   - Session-Management

2. **Dashboard**
   - Übersicht aller Grading-Aufträge
   - Status-Anzeige (z.B. "In Bearbeitung", "Abgeschlossen", "Versandt")
   - Filter und Sortierung

3. **Auftragsdetails**
   - Detaillierte Informationen zu jedem Grading-Auftrag
   - Fortschrittsanzeige
   - Geschätzte Fertigstellung
   - Bilder/Vorschau (falls verfügbar)

4. **Benachrichtigungen**
   - Status-Updates
   - E-Mail-Benachrichtigungen bei Statusänderungen

## 🗄️ Datenbank-Schema (Supabase)

### Tabelle: `customers`
```sql
- id (uuid, primary key)
- email (text, unique, not null)
- password_hash (text, not null)
- full_name (text)
- phone (text)
- created_at (timestamp)
- updated_at (timestamp)
```

### Tabelle: `grading_orders`
```sql
- id (uuid, primary key)
- customer_id (uuid, foreign key -> customers.id)
- order_number (text, unique, not null)
- status (text, not null) -- 'pending', 'in_progress', 'completed', 'shipped', 'delivered'
- submission_date (timestamp)
- estimated_completion_date (timestamp)
- actual_completion_date (timestamp)
- shipping_date (timestamp)
- delivery_date (timestamp)
- notes (text)
- created_at (timestamp)
- updated_at (timestamp)
```

### Tabelle: `grading_items`
```sql
- id (uuid, primary key)
- order_id (uuid, foreign key -> grading_orders.id)
- item_name (text)
- item_type (text) -- z.B. 'Pokemon Card', 'Sports Card', etc.
- grade (text) -- z.B. 'PSA 10', 'BGS 9.5', etc.
- images (jsonb) -- Array von Bild-URLs
- notes (text)
- created_at (timestamp)
- updated_at (timestamp)
```

### Tabelle: `order_status_history`
```sql
- id (uuid, primary key)
- order_id (uuid, foreign key -> grading_orders.id)
- status (text, not null)
- changed_by (text) -- 'system' oder 'admin'
- notes (text)
- created_at (timestamp)
```

### Row Level Security (RLS) Policies:
- Kunden können nur ihre eigenen Aufträge sehen
- Kunden können nur ihre eigenen Daten ändern
- Admin-Benutzer haben vollständigen Zugriff

## 🛠️ Technologie-Stack

### Frontend
- **Framework**: React mit TypeScript
- **Styling**: Tailwind CSS für modernes, responsives Design
- **Routing**: React Router
- **State Management**: React Context API oder Zustand
- **Form Handling**: React Hook Form
- **HTTP Client**: Axios oder Fetch API
- **UI Components**: 
  - Shadcn/ui oder Headless UI für wiederverwendbare Komponenten
  - React Icons für Icons

### Backend/Datenbank
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage (für Bilder)
- **Real-time**: Supabase Realtime (für Live-Updates)

### Deployment
- **Frontend**: Vercel, Netlify oder GitHub Pages
- **Backend**: Supabase (gehostet)

## 🎨 UI/UX Konzept

### Design-Prinzipien
- **Modern & Clean**: Minimalistisches Design mit klarer Hierarchie
- **Responsive**: Funktioniert auf Desktop, Tablet und Mobile
- **Intuitive Navigation**: Einfache Menüstruktur
- **Status-Visualisierung**: Farbcodierte Status-Badges
- **Dark Mode**: Optional (für bessere UX)

### Seitenstruktur
1. **Login-Seite** (`/login`)
   - E-Mail/Passwort-Eingabe
   - "Passwort vergessen?" Link
   - Registrierung (falls gewünscht)

2. **Dashboard** (`/dashboard`)
   - Übersichtskarte mit Statistiken
   - Liste aller Aufträge mit Status
   - Such- und Filterfunktionen

3. **Auftragsdetails** (`/orders/:id`)
   - Vollständige Auftragsinformationen
   - Status-Timeline
   - Item-Liste mit Details
   - Bilder-Galerie

4. **Profil** (`/profile`)
   - Kundeninformationen
   - Passwort ändern
   - Einstellungen

## 📁 Projektstruktur

```
GradingLogin/
├── public/
│   └── ...
├── src/
│   ├── components/
│   │   ├── ui/              # Wiederverwendbare UI-Komponenten
│   │   ├── layout/          # Layout-Komponenten (Header, Sidebar)
│   │   └── features/        # Feature-spezifische Komponenten
│   ├── pages/
│   │   ├── Login.tsx
│   │   ├── Dashboard.tsx
│   │   ├── OrderDetails.tsx
│   │   └── Profile.tsx
│   ├── hooks/
│   │   └── useAuth.ts
│   ├── services/
│   │   ├── supabase.ts      # Supabase Client
│   │   └── api.ts           # API-Aufrufe
│   ├── types/
│   │   └── index.ts         # TypeScript-Typen
│   ├── utils/
│   │   └── ...
│   ├── App.tsx
│   └── main.tsx
├── package.json
├── tsconfig.json
├── tailwind.config.js
└── vite.config.ts (oder ähnlich)
```

## 🚀 Implementierungs-Schritte

### Phase 1: Setup & Grundlagen
1. ✅ Projekt initialisieren (React + TypeScript + Vite)
2. ✅ Supabase-Projekt erstellen und konfigurieren
3. ✅ Datenbank-Schema erstellen
4. ✅ Basis-Routing einrichten
5. ✅ UI-Framework integrieren (Tailwind CSS)

### Phase 2: Authentifizierung
1. ✅ Login-Funktionalität implementieren
2. ✅ Registrierung (optional)
3. ✅ Passwort-Reset
4. ✅ Protected Routes
5. ✅ Session-Management

### Phase 3: Dashboard
1. ✅ Dashboard-Layout erstellen
2. ✅ Auftragsliste anzeigen
3. ✅ Status-Filter implementieren
4. ✅ Suchfunktion
5. ✅ Statistiken anzeigen

### Phase 4: Auftragsdetails
1. ✅ Detailseite für einzelne Aufträge
2. ✅ Status-Timeline
3. ✅ Item-Liste mit Details
4. ✅ Bildergalerie (falls vorhanden)

### Phase 5: Real-time Updates
1. ✅ Supabase Realtime für Live-Updates
2. ✅ Benachrichtigungen bei Statusänderungen

### Phase 6: Polishing
1. ✅ Responsive Design optimieren
2. ✅ Loading States
3. ✅ Error Handling
4. ✅ Performance-Optimierung
5. ✅ Testing

## 🔐 Sicherheit

- Row Level Security (RLS) in Supabase aktivieren
- Sichere Passwort-Hashes (Supabase Auth)
- HTTPS für alle Verbindungen
- Input-Validierung auf Client und Server
- CSRF-Schutz
- Rate Limiting für API-Aufrufe

## 📊 Status-Workflow

```
pending → in_progress → completed → shipped → delivered
```

Jeder Statuswechsel wird in `order_status_history` protokolliert.

## 🎯 Erweiterte Features (Optional)

- E-Mail-Benachrichtigungen bei Statusänderungen
- PDF-Export von Auftragsdetails
- Chat/Support-Funktion
- Bewertungssystem
- Mehrsprachigkeit
- Mobile App (React Native)

## 📝 Nächste Schritte

1. Plan überprüfen und anpassen
2. Supabase-Projekt erstellen
3. Datenbank-Schema implementieren
4. Frontend-Projekt initialisieren
5. Schrittweise Implementierung nach Phasen

