# Grading Kundenportal

Ein modernes Kundenportal für Grading-Käufer, das es Kunden ermöglicht, den Status ihrer Grading-Aufträge in Echtzeit zu verfolgen.

## 📋 Projektübersicht

Dieses Portal bietet Grading-Käufern eine benutzerfreundliche Oberfläche, um:
- Ihre Grading-Aufträge einzusehen
- Den aktuellen Status zu verfolgen
- Detaillierte Informationen zu jedem Auftrag abzurufen
- Sich zu registrieren und anzumelden

## 🛠️ Technologie-Stack

- **Frontend**: React + TypeScript + Vite + Tailwind CSS
- **Backend/Datenbank**: Supabase (PostgreSQL)
- **Authentifizierung**: Supabase Auth
- **Deployment**: Vercel
- **Version Control**: GitHub

## 📁 Projektstruktur

```
GradingLogin/
├── src/
│   ├── components/      # React-Komponenten
│   ├── contexts/        # React Contexts (Auth)
│   ├── lib/            # Bibliotheken (Supabase Client)
│   ├── services/       # API-Services
│   ├── types/          # TypeScript-Typen
│   └── utils/          # Utility-Funktionen
├── docs/               # Dokumentation
├── scripts/            # SQL-Scripts und Tools
├── public/             # Statische Assets
└── database-schema.sql # Haupt-Datenbank-Schema
```

## 🚀 Schnellstart

### Voraussetzungen

- Node.js 18+ installiert
- Supabase Account
- Git

### Lokale Entwicklung

```bash
# Dependencies installieren
npm install

# Entwicklungsserver starten
npm run dev

# Build erstellen
npm run build
```

### Umgebungsvariablen

Erstelle eine `.env.local` Datei im Root-Verzeichnis:

```env
VITE_SUPABASE_URL="https://your-project.supabase.co"
VITE_SUPABASE_ANON_KEY="your-anon-key"
```

Kopiere `.env.example` zu `.env.local` und fülle die Werte aus:

```bash
cp .env.example .env.local
```

## 🗄️ Datenbank-Setup

1. **Schema ausführen**: Öffne `database-schema.sql` im Supabase SQL Editor und führe es aus
2. **Auth-Sync aktivieren**: Führe `scripts/auth-customer-sync.sql` aus (automatische Synchronisation zwischen Auth und Customers)
3. **Test-Daten** (optional): Führe `scripts/test-data-setup.sql` aus

Siehe [`docs/SUPABASE_SETUP.md`](./docs/SUPABASE_SETUP.md) für detaillierte Anweisungen.

## 🚀 Deployment

**Vollständige Deployment-Anleitung:** Siehe [`docs/DEPLOYMENT_COMPLETE.md`](./docs/DEPLOYMENT_COMPLETE.md)

Kurzfassung:
1. GitHub Repository erstellen
2. Code zu GitHub pushen
3. Vercel Account erstellen
4. Projekt mit GitHub verbinden
5. Umgebungsvariablen in Vercel setzen:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
6. Deploy!

## 📊 Status-Workflow

```
pending → in_progress → completed → shipped → delivered
```

## 🔐 Authentifizierung

- Benutzer können sich registrieren und anmelden
- Automatische Synchronisation zwischen Supabase Auth und `customers` Tabelle
- Row Level Security (RLS) aktiviert
- Kunden können nur ihre eigenen Daten einsehen

Siehe [`docs/AUTH_CUSTOMER_SYNC.md`](./docs/AUTH_CUSTOMER_SYNC.md) für Details.

## 📝 Dokumentation

Alle Dokumentation befindet sich im `docs/` Ordner:

- [`DEPLOYMENT_COMPLETE.md`](./docs/DEPLOYMENT_COMPLETE.md) - Vollständige Deployment-Anleitung
- [`SUPABASE_SETUP.md`](./docs/SUPABASE_SETUP.md) - Supabase Setup-Anleitung
- [`AUTH_CUSTOMER_SYNC.md`](./docs/AUTH_CUSTOMER_SYNC.md) - Auth-Customer Synchronisation
- [`TEST_USERS_SETUP.md`](./docs/TEST_USERS_SETUP.md) - Test-Benutzer erstellen
- [`SUPABASE_AUTH_CONFIG.md`](./docs/SUPABASE_AUTH_CONFIG.md) - Supabase Auth Konfiguration
- [`LOGIN_TROUBLESHOOTING.md`](./docs/LOGIN_TROUBLESHOOTING.md) - Login-Probleme beheben
- [`INTEGRATION.md`](./docs/INTEGRATION.md) - Integration-Details
- [`CODE_IMPROVEMENTS.md`](./docs/CODE_IMPROVEMENTS.md) - Code-Verbesserungen
- [`PROJEKTPLAN.md`](./docs/PROJEKTPLAN.md) - Projektplan

## 🛠️ Scripts

SQL-Scripts und Tools befinden sich im `scripts/` Ordner:

- `auth-customer-sync.sql` - Automatische Auth-Customer Synchronisation
- `test-data-setup.sql` - Test-Daten erstellen
- `create-test-cards.sql` - Test-Karten erstellen
- `create-test-order-a-antipin.sql` - Test-Auftrag erstellen
- `quick-diagnose.sql` - Diagnose-Queries
- `push-schema.js` / `push-schema.py` - Schema-Push-Tools

## 🧪 Development

### Logging

Das Projekt verwendet ein professionelles Console-Logging-System für Development:

```typescript
import { logger } from './utils/logger'

logger.info('Nachricht', { context: 'Component', data: {...} })
logger.success('Erfolg')
logger.warn('Warnung')
logger.error('Fehler')
```

Logs erscheinen nur in Development-Mode und sind in Production deaktiviert.

### Error Handling

Konsistentes Error-Handling über `src/utils/errorHandler.ts`:

```typescript
import { logError, getUserFriendlyErrorMessage } from './utils/errorHandler'

try {
  // ...
} catch (error) {
  logError('Context', error)
  const message = getUserFriendlyErrorMessage(error)
}
```

## 📦 Build

```bash
# Production Build
npm run build

# Build prüfen
npm run preview
```

## 🔧 Troubleshooting

Siehe [`docs/LOGIN_TROUBLESHOOTING.md`](./docs/LOGIN_TROUBLESHOOTING.md) für häufige Probleme.

## 📄 Lizenz

Proprietär - Lama Cards
