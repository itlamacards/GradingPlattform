# Scripts

Dieser Ordner enthält SQL-Scripts und Tools für das Grading Kundenportal.

## 📄 SQL-Scripts

### Wichtig - Ausführungsreihenfolge:

1. **`../database-schema.sql`** - Haupt-Datenbank-Schema (MUSS zuerst ausgeführt werden)
2. **`account-state-machine.sql`** - Account State Machine (Status, Lockout, Rate-Limiting)
3. **`auth-customer-sync.sql`** - Automatische Synchronisation Auth ↔ Customers

### Account State Machine

**`account-state-machine.sql`** - Erweitert die `customers` Tabelle um:
- ✅ Status-Feld (PENDING_INVITE, UNVERIFIED, ACTIVE, LOCKED, SUSPENDED, DELETED, PASSWORD_RESET_REQUIRED)
- ✅ Lockout-Management (locked_until, failed_login_count)
- ✅ E-Mail-Verifikation-Tracking
- ✅ Rate-Limiting für Resend-Verification
- ✅ Session-Versionierung (für "Logout all devices")
- ✅ State-Transition Functions
- ✅ Cleanup-Jobs für unverifizierte Accounts

**WICHTIG:** Führe dieses Script NACH `database-schema.sql` aus!

### Auth-Customer Synchronisation

**`auth-customer-sync.sql`** - Automatische Synchronisation:
- ✅ Auth User erstellt → Customer erstellt
- ✅ Customer erstellt → Auth User erstellt (wenn möglich)
- ✅ Status wird basierend auf `email_confirmed_at` gesetzt

**WICHTIG:** Führe dieses Script NACH `account-state-machine.sql` aus!

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

**WICHTIG:** Führe die Scripts in dieser Reihenfolge aus:
1. Haupt-Schema: `../database-schema.sql`
2. Account State Machine: `account-state-machine.sql`
3. Auth-Sync: `auth-customer-sync.sql`
4. Test-Daten (optional): `test-data-setup.sql`
