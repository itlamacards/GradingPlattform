# Scripts

Dieser Ordner enthält SQL-Scripts und Tools für das Grading Kundenportal.

## 📄 SQL-Scripts

### Wichtig
- **`auth-customer-sync.sql`** - **MUSS ausgeführt werden!**  
  Erstellt automatische Synchronisation zwischen Supabase Auth und der `customers` Tabelle.  
  Führe dieses Script im Supabase SQL Editor aus.

### Test-Daten
- **`test-data-setup.sql`** - Erstellt Test-Kunden, Aufträge und Karten für Entwicklung
- **`create-test-cards.sql`** - Erstellt 3 Test-Karten für einen spezifischen Kunden
- **`create-test-order-a-antipin.sql`** - Erstellt einen Test-Auftrag mit Karten

### Diagnose
- **`quick-diagnose.sql`** - SQL-Queries zum Diagnostizieren von Login- und Datenproblemen

## 🛠️ Tools

- **`push-schema.js`** - Node.js Script zum Pushen des Schemas zu Supabase
- **`push-schema.py`** - Python Script zum Pushen des Schemas zu Supabase

## 📝 Verwendung

1. Öffne den **Supabase SQL Editor** in deinem Dashboard
2. Kopiere den Inhalt des gewünschten SQL-Scripts
3. Füge ihn in den Editor ein
4. Klicke auf **"Run"** (oder `Cmd+Enter`)

**Wichtig:** Führe die Scripts in dieser Reihenfolge aus:
1. Haupt-Schema: `../database-schema.sql`
2. Auth-Sync: `auth-customer-sync.sql`
3. Test-Daten (optional): `test-data-setup.sql`

