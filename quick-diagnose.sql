-- ============================================
-- QUICK DIAGNOSE: Login-Problem finden
-- ============================================
-- Ersetze 'DEINE-EMAIL@example.com' mit deiner E-Mail-Adresse
-- ============================================

-- 1. Prüfe Auth User
SELECT 
    'Auth User Status' as check_name,
    id as auth_user_id,
    email,
    CASE 
        WHEN confirmed_at IS NULL THEN '❌ NICHT bestätigt - Das ist wahrscheinlich das Problem!'
        ELSE '✅ Bestätigt'
    END as confirmation_status,
    created_at,
    last_sign_in_at
FROM auth.users
WHERE email = 'DEINE-EMAIL@example.com';  -- ← HIER DEINE E-MAIL EINTRAGEN

-- 2. Prüfe Customer
SELECT 
    'Customer Status' as check_name,
    id as customer_id,
    email,
    customer_number,
    first_name,
    last_name,
    created_at
FROM customers
WHERE email = 'DEINE-EMAIL@example.com';  -- ← HIER DEINE E-MAIL EINTRAGEN

-- 3. Prüfe ID-Übereinstimmung (WICHTIG für RLS!)
SELECT 
    'ID Match Check' as check_name,
    au.id as auth_user_id,
    c.id as customer_id,
    CASE 
        WHEN au.id = c.id THEN '✅ IDs stimmen überein - RLS sollte funktionieren'
        WHEN c.id IS NULL THEN '❌ Kunde wurde NICHT erstellt!'
        ELSE '❌ IDs stimmen NICHT überein - RLS blockiert Zugriff!'
    END as match_status
FROM auth.users au
LEFT JOIN customers c ON c.email = au.email
WHERE au.email = 'DEINE-EMAIL@example.com';  -- ← HIER DEINE E-MAIL EINTRAGEN

-- ============================================
-- QUICK FIX: User bestätigen (falls nicht bestätigt)
-- ============================================
-- Führe dies aus, wenn confirmed_at NULL ist:
-- UPDATE auth.users 
-- SET confirmed_at = NOW() 
-- WHERE email = 'DEINE-EMAIL@example.com';

-- ============================================
-- QUICK FIX: Kunde erstellen (falls nicht vorhanden)
-- ============================================
-- Führe dies aus, wenn kein Kunde existiert:
/*
INSERT INTO customers (
    id,
    customer_number,
    first_name,
    last_name,
    email
)
SELECT 
    au.id,
    'K-' || TO_CHAR(NOW(), 'YYYY') || '-0001',
    COALESCE(au.raw_user_meta_data->>'first_name', SPLIT_PART(au.email, '@', 1)),
    COALESCE(au.raw_user_meta_data->>'last_name', ''),
    au.email
FROM auth.users au
WHERE au.email = 'DEINE-EMAIL@example.com'
AND NOT EXISTS (SELECT 1 FROM customers WHERE email = au.email);
*/

-- ============================================
-- QUICK FIX: ID synchronisieren (falls IDs nicht übereinstimmen)
-- ============================================
-- Führe dies aus, wenn IDs nicht übereinstimmen:
/*
UPDATE customers
SET id = (SELECT id FROM auth.users WHERE email = customers.email)
WHERE email = 'DEINE-EMAIL@example.com'
AND id != (SELECT id FROM auth.users WHERE email = customers.email);
*/



