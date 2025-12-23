# 🔄 Automatische Synchronisation: Auth Users ↔ Customers

## Übersicht

Dieses System synchronisiert automatisch zwischen Supabase Auth Users und der `customers` Tabelle:

- ✅ **Auth User erstellt** → Automatisch Kunde erstellt
- ✅ **Kunde erstellt** → Automatisch Auth User erstellt
- ✅ **Auth User aktualisiert** → Kunde aktualisiert
- ✅ **Kunde aktualisiert** → Auth User aktualisiert

## ⚙️ Installation

### Schritt 1: SQL-Script ausführen

1. Gehe zu: **https://supabase.com/dashboard/project/kbthvenvqxnxplgixgdq**
2. Klicke auf **"SQL Editor"** im linken Menü
3. Klicke auf **"New query"**
4. Öffne die Datei `auth-customer-sync.sql`
5. Kopiere den gesamten Inhalt
6. Füge ihn in den SQL Editor ein
7. Klicke auf **"Run"** (oder `Cmd+Enter`)

✅ Die Triggers und Functions sind jetzt aktiv!

---

## 🔧 Wie es funktioniert

### 1. Auth User → Customer (Automatisch)

Wenn ein Benutzer in Supabase Auth erstellt wird:
- Trigger `on_auth_user_created` wird ausgelöst
- Function `handle_new_auth_user()` erstellt automatisch einen Kunden
- Die `customer_id` ist die gleiche UUID wie die `auth.users.id` (wichtig für RLS!)

**Beispiel:**
```sql
-- User wird in Supabase Auth erstellt
-- → Automatisch wird ein Kunde erstellt mit:
--   - Gleiche UUID wie Auth User
--   - Kundennummer wird automatisch generiert
--   - Name wird aus user_metadata extrahiert
```

### 2. Customer → Auth User (Automatisch)

Wenn ein Kunde in der `customers` Tabelle erstellt wird:
- Trigger `on_customer_created` wird ausgelöst
- Function `handle_new_customer()` erstellt automatisch einen Auth User
- Standard-Passwort: `TempPass123!` (User sollte es ändern)

**⚠️ WICHTIG:** 
- Der Auth User wird mit der **gleichen UUID** wie der Kunde erstellt
- Das Passwort ist `TempPass123!` - sollte nach erstem Login geändert werden
- User ist automatisch bestätigt (confirmed_at = NOW())

### 3. Updates werden synchronisiert

- Auth User Update → Customer Update
- Customer Update → Auth User Update

---

## 📝 Manuelle Synchronisation

Falls du bestehende Auth Users synchronisieren möchtest:

```sql
-- Führe diese Query aus:
SELECT * FROM public.sync_all_auth_users_to_customers();
```

Dies erstellt für alle Auth Users, die noch keinen Kunden haben, automatisch einen Kunden.

---

## 🔐 Wichtige Hinweise

### UUID-Synchronisation

**KRITISCH:** Die `customers.id` muss die gleiche UUID wie `auth.users.id` haben, damit RLS (Row Level Security) funktioniert!

Die RLS Policies verwenden:
```sql
auth.uid()::text = customer_id::text
```

Deshalb verwenden die Sync-Functions immer die gleiche UUID für beide Tabellen.

### Passwort-Handling

Wenn ein Kunde erstellt wird und automatisch ein Auth User erstellt wird:
- Standard-Passwort: `TempPass123!`
- User sollte nach erstem Login das Passwort ändern
- Oder Admin kann Passwort über Supabase Dashboard ändern

### E-Mail-Konflikte

Die Functions verwenden `ON CONFLICT (email) DO UPDATE` bzw. `ON CONFLICT (email) DO NOTHING`, um Duplikate zu vermeiden.

---

## 🧪 Testen

### Test 1: Auth User erstellen → Kunde wird erstellt

1. Erstelle einen neuen User in Supabase Auth Dashboard
2. Prüfe, ob automatisch ein Kunde erstellt wurde:
```sql
SELECT * FROM customers WHERE email = 'neue-email@example.com';
```

### Test 2: Kunde erstellen → Auth User wird erstellt

1. Erstelle einen neuen Kunden:
```sql
INSERT INTO customers (customer_number, first_name, last_name, email, phone)
VALUES ('K-2024-9999', 'Test', 'User', 'test@example.com', '+49 123 456789');
```

2. Prüfe, ob automatisch ein Auth User erstellt wurde:
```sql
SELECT * FROM auth.users WHERE email = 'test@example.com';
```

3. Versuche dich einzuloggen mit:
   - Email: `test@example.com`
   - Password: `TempPass123!`

---

## 🔧 Troubleshooting

### Problem: Trigger funktioniert nicht

**Lösung:**
- Prüfe, ob die Functions erstellt wurden: `\df public.handle_*`
- Prüfe, ob die Triggers existieren: `\d+ customers` und `\d+ auth.users`
- Prüfe Supabase Logs auf Fehler

### Problem: RLS funktioniert nicht

**Lösung:**
- Stelle sicher, dass `customers.id` = `auth.users.id`
- Prüfe die RLS Policies: `SELECT * FROM pg_policies WHERE tablename = 'customers';`

### Problem: Auth User wird nicht erstellt beim Kunde erstellen

**Lösung:**
- Die Function benötigt `SECURITY DEFINER` um auf `auth.users` zuzugreifen
- Prüfe, ob die Function korrekt erstellt wurde
- Prüfe Supabase Logs auf Fehler

---

## 📋 Zusammenfassung

✅ **Automatische Synchronisation aktiviert:**
- Auth User ↔ Customers
- Beide Richtungen funktionieren
- Updates werden synchronisiert
- UUIDs bleiben identisch (wichtig für RLS!)

✅ **Nach Installation:**
- Jeder neue Auth User bekommt automatisch einen Kunden
- Jeder neue Kunde bekommt automatisch einen Auth User
- Bestehende Users können manuell synchronisiert werden

