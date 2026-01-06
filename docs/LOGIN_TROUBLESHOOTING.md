# 🔍 Login-Problembehandlung

## Problem: Kann mich nicht einloggen

### Schritt 1: Prüfe ob Auth User existiert

Führe diese SQL-Query im Supabase SQL Editor aus:

```sql
-- Prüfe ob Auth User existiert
SELECT 
    id,
    email,
    confirmed_at,
    created_at,
    last_sign_in_at
FROM auth.users
WHERE email = 'DEINE-EMAIL@example.com';
```

**Erwartetes Ergebnis:**
- User sollte existieren
- `confirmed_at` sollte NICHT NULL sein (sonst ist User nicht bestätigt)

**Falls `confirmed_at` NULL ist:**
- User ist nicht bestätigt → kann sich nicht einloggen
- Lösung: Im Dashboard → Authentication → Users → User auswählen → "Confirm User" klicken

---

### Schritt 2: Prüfe ob Kunde automatisch erstellt wurde

```sql
-- Prüfe ob Kunde existiert
SELECT 
    id,
    customer_number,
    email,
    first_name,
    last_name,
    created_at
FROM customers
WHERE email = 'DEINE-EMAIL@example.com';
```

**Erwartetes Ergebnis:**
- Kunde sollte existieren
- `id` sollte die GLEICHE UUID wie `auth.users.id` haben

**Falls Kunde nicht existiert:**
- Der Trigger hat nicht funktioniert
- Lösung: Manuell Kunde erstellen (siehe Schritt 3)

---

### Schritt 3: Prüfe ob IDs übereinstimmen

```sql
-- Prüfe ob IDs übereinstimmen (WICHTIG für RLS!)
SELECT 
    au.id as auth_user_id,
    au.email as auth_email,
    au.confirmed_at,
    c.id as customer_id,
    c.email as customer_email,
    CASE 
        WHEN au.id = c.id THEN '✅ IDs stimmen überein'
        ELSE '❌ IDs stimmen NICHT überein'
    END as id_match
FROM auth.users au
LEFT JOIN customers c ON c.email = au.email
WHERE au.email = 'DEINE-EMAIL@example.com';
```

**Erwartetes Ergebnis:**
- `auth_user_id` = `customer_id` (muss übereinstimmen!)
- `id_match` sollte "✅ IDs stimmen überein" sein

**Falls IDs nicht übereinstimmen:**
- RLS funktioniert nicht
- Lösung: Kunde-ID aktualisieren (siehe Schritt 4)

---

### Schritt 4: Kunde-ID synchronisieren (falls nötig)

```sql
-- Update Kunde-ID um mit Auth User ID übereinzustimmen
UPDATE customers
SET id = (
    SELECT id FROM auth.users WHERE email = customers.email
)
WHERE email = 'DEINE-EMAIL@example.com'
AND id != (SELECT id FROM auth.users WHERE email = customers.email);
```

---

### Schritt 5: Kunde manuell erstellen (falls nicht vorhanden)

```sql
-- Erstelle Kunde manuell mit korrekter Auth User ID
INSERT INTO customers (
    id,  -- WICHTIG: Gleiche UUID wie Auth User!
    customer_number,
    first_name,
    last_name,
    email,
    phone
)
SELECT 
    au.id,  -- Verwende Auth User ID
    'K-' || TO_CHAR(NOW(), 'YYYY') || '-' || 
    LPAD(
        COALESCE(
            (SELECT MAX(CAST(SUBSTRING(customer_number FROM '[0-9]+$') AS INTEGER)) 
             FROM customers 
             WHERE customer_number ~ ('^K-' || TO_CHAR(NOW(), 'YYYY') || '-[0-9]+$')),
            0
        ) + 1,
        4, '0'
    ),
    COALESCE(au.raw_user_meta_data->>'first_name', SPLIT_PART(au.email, '@', 1)),
    COALESCE(au.raw_user_meta_data->>'last_name', ''),
    au.email,
    au.phone
FROM auth.users au
WHERE au.email = 'DEINE-EMAIL@example.com'
AND NOT EXISTS (
    SELECT 1 FROM customers WHERE email = au.email
);
```

---

### Schritt 6: Prüfe RLS Policies

```sql
-- Prüfe ob RLS aktiviert ist
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'customers';
```

**Erwartetes Ergebnis:**
- RLS sollte aktiviert sein
- Es sollte eine Policy geben, die `auth.uid() = customer_id` verwendet

---

### Schritt 7: Teste Login direkt in Supabase

1. Gehe zu: **Authentication** → **Users**
2. Finde deinen User
3. Klicke auf **"Send magic link"** oder **"Reset password"**
4. Versuche dich mit dem Magic Link einzuloggen

---

## 🔧 Häufige Probleme und Lösungen

### Problem 1: "Invalid login credentials"

**Ursachen:**
- Falsches Passwort
- User nicht bestätigt (`confirmed_at` ist NULL)
- E-Mail stimmt nicht überein

**Lösung:**
- Prüfe Passwort
- Bestätige User im Dashboard
- Prüfe E-Mail-Adresse

### Problem 2: "User not found" oder "Keine Aufträge gefunden"

**Ursachen:**
- Kunde wurde nicht erstellt
- IDs stimmen nicht überein (RLS blockiert Zugriff)

**Lösung:**
- Führe Schritt 3 und 4 aus
- Erstelle Kunde manuell (Schritt 5)

### Problem 3: Login funktioniert, aber Dashboard zeigt nichts

**Ursachen:**
- RLS blockiert Zugriff
- IDs stimmen nicht überein
- Keine Aufträge vorhanden

**Lösung:**
- Prüfe Schritt 3 (ID-Übereinstimmung)
- Prüfe ob Aufträge existieren:
```sql
SELECT * FROM grading_orders 
WHERE customer_id = (SELECT id FROM customers WHERE email = 'DEINE-EMAIL@example.com');
```

---

## ✅ Quick Fix: Alles auf einmal prüfen

Führe diese Query aus, um alle Probleme auf einmal zu sehen:

```sql
-- Komplette Diagnose
SELECT 
    'Auth User' as check_type,
    CASE 
        WHEN EXISTS(SELECT 1 FROM auth.users WHERE email = 'DEINE-EMAIL@example.com') 
        THEN '✅ Existiert'
        ELSE '❌ Nicht gefunden'
    END as status,
    (SELECT id FROM auth.users WHERE email = 'DEINE-EMAIL@example.com') as id
UNION ALL
SELECT 
    'Customer' as check_type,
    CASE 
        WHEN EXISTS(SELECT 1 FROM customers WHERE email = 'DEINE-EMAIL@example.com') 
        THEN '✅ Existiert'
        ELSE '❌ Nicht gefunden'
    END as status,
    (SELECT id FROM customers WHERE email = 'DEINE-EMAIL@example.com') as id
UNION ALL
SELECT 
    'ID Match' as check_type,
    CASE 
        WHEN (SELECT id FROM auth.users WHERE email = 'DEINE-EMAIL@example.com') = 
             (SELECT id FROM customers WHERE email = 'DEINE-EMAIL@example.com')
        THEN '✅ Stimmen überein'
        ELSE '❌ Stimmen NICHT überein'
    END as status,
    NULL as id
UNION ALL
SELECT 
    'User Confirmed' as check_type,
    CASE 
        WHEN (SELECT confirmed_at FROM auth.users WHERE email = 'DEINE-EMAIL@example.com') IS NOT NULL
        THEN '✅ Bestätigt'
        ELSE '❌ Nicht bestätigt'
    END as status,
    NULL as id;
```

**Ersetze `DEINE-EMAIL@example.com` mit deiner tatsächlichen E-Mail-Adresse!**

---

## 🆘 Wenn nichts hilft

1. **Prüfe Browser-Konsole** (F12 → Console) auf Fehler
2. **Prüfe Supabase Logs** (Dashboard → Logs)
3. **Erstelle neuen Test-User** und teste erneut
4. **Deaktiviere temporär RLS** zum Testen (nur für Debugging!):
```sql
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
-- Teste Login
-- Dann wieder aktivieren:
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
```

