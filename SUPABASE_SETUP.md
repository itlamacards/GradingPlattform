# Supabase Schema Setup Anleitung

## Schema zu Supabase pushen

Die Supabase REST API unterstützt keine direkte SQL-Ausführung für DDL-Statements (CREATE TABLE, etc.). 
Du musst das Schema manuell im Supabase Dashboard ausführen.

## Methode 1: Supabase Dashboard (Empfohlen)

1. **Gehe zum Supabase Dashboard:**
   - URL: https://supabase.com/dashboard/project/ebfvbqppnpxfcijzkita
   - Oder: https://ebfvbqppnpxfcijzkita.supabase.co

2. **Öffne den SQL Editor:**
   - Klicke auf "SQL Editor" im linken Menü
   - Oder gehe direkt zu: https://supabase.com/dashboard/project/ebfvbqppnpxfcijzkita/sql/new

3. **Führe das Schema aus:**
   - Öffne die Datei `database-schema-final.sql` in diesem Projekt
   - Kopiere den gesamten Inhalt
   - Füge ihn in den SQL Editor ein
   - Klicke auf "Run" oder drücke `Cmd+Enter` (Mac) / `Ctrl+Enter` (Windows)

## Methode 2: Supabase CLI (Falls installiert)

```bash
# Installiere Supabase CLI (falls nicht vorhanden)
npm install -g supabase

# Verbinde mit deinem Projekt
supabase link --project-ref ebfvbqppnpxfcijzkita

# Pushe das Schema
supabase db push < database-schema-final.sql
```

## Methode 3: psql (Falls PostgreSQL Client installiert)

Du benötigst die Datenbank-Verbindungsdaten von Supabase:
- Host: db.ebfvbqppnpxfcijzkita.supabase.co
- Port: 5432
- Database: postgres
- User: postgres
- Password: (findest du in Supabase Dashboard unter Settings > Database)

```bash
psql -h db.ebfvbqppnpxfcijzkita.supabase.co -p 5432 -U postgres -d postgres -f database-schema-final.sql
```

## Überprüfung

Nach dem Ausführen des Schemas kannst du überprüfen, ob alle Tabellen erstellt wurden:

1. Gehe zu "Table Editor" im Supabase Dashboard
2. Du solltest folgende Tabellen sehen:
   - customers
   - grading_services
   - grading_orders
   - grading_batches
   - grading_numbers
   - grading_results
   - invoices
   - order_status_history

## Wichtige Hinweise

- **Service Role Key**: Der Service Role Key sollte NIEMALS öffentlich geteilt werden
- **Row Level Security**: RLS ist aktiviert - stelle sicher, dass die Policies korrekt konfiguriert sind
- **Backup**: Erstelle ein Backup, bevor du das Schema auf einer Produktions-Datenbank ausführst

## Nächste Schritte

Nach dem Schema-Setup:
1. Verbinde die React-App mit Supabase
2. Konfiguriere die Supabase Client-Konfiguration
3. Implementiere die Authentifizierung
4. Teste die Datenbank-Verbindung


