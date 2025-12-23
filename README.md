# Grading Kundenportal

Ein modernes Kundenportal für Grading-Käufer, das es Kunden ermöglicht, den Status ihrer Grading-Aufträge in Echtzeit zu verfolgen.

## 📋 Projektübersicht

Dieses Portal bietet Grading-Käufern eine benutzerfreundliche Oberfläche, um:
- Ihre Grading-Aufträge einzusehen
- Den aktuellen Status zu verfolgen
- Detaillierte Informationen zu jedem Auftrag abzurufen
- Live-Updates bei Statusänderungen zu erhalten

## 🗄️ Datenbank

Die Datenbank wird über **Supabase** verwaltet. Das vollständige Schema finden Sie in `database-schema.sql`.

### Haupttabellen:
- `customers` - Kundeninformationen
- `grading_orders` - Grading-Aufträge
- `grading_items` - Einzelne Items pro Auftrag
- `order_status_history` - Status-Verlauf für Nachverfolgung

## 🛠️ Technologie-Stack

- **Frontend**: React + TypeScript + Tailwind CSS
- **Backend/Datenbank**: Supabase (PostgreSQL)
- **Authentifizierung**: Supabase Auth
- **Real-time Updates**: Supabase Realtime

## 📁 Projektstruktur

```
GradingLogin/
├── PROJEKTPLAN.md          # Detaillierter Projektplan
├── database-schema.sql     # Supabase Datenbank-Schema
└── README.md              # Diese Datei
```

## 🚀 Schnellstart

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

Kopiere `.env.example` zu `.env.local` und fülle die Werte aus:

```bash
cp .env.example .env.local
```

## 🚀 Deployment

**Vollständige Deployment-Anleitung:** Siehe [`DEPLOYMENT_COMPLETE.md`](./DEPLOYMENT_COMPLETE.md)

Kurzfassung:
1. GitHub Repository erstellen
2. Code zu GitHub pushen
3. Vercel Account erstellen
4. Projekt mit GitHub verbinden
5. Umgebungsvariablen in Vercel setzen
6. Deploy!

## 📊 Status-Workflow

```
pending → in_progress → completed → shipped → delivered
```

## 🔐 Sicherheit

- Row Level Security (RLS) aktiviert
- Sichere Authentifizierung über Supabase Auth
- Kunden können nur ihre eigenen Daten einsehen

## 📝 Dokumentation

Für detaillierte Informationen siehe:
- `PROJEKTPLAN.md` - Vollständiger Projektplan mit Features, UI/UX-Konzept und Implementierungs-Schritten

