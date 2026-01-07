-- ============================================
-- AUTOMATISCHE SYNCHRONISATION
-- Auth Users ↔ Customers
-- ============================================
-- Dieses Script erstellt Triggers und Functions für automatische Synchronisation
-- zwischen Supabase Auth Users und der customers Tabelle
-- ============================================

-- ============================================
-- FUNCTION 1: Erstelle Kunde wenn Auth User erstellt wird
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
DECLARE
    v_customer_number TEXT;
    v_first_name TEXT;
    v_last_name TEXT;
    v_existing_customer_id UUID;
BEGIN
    -- Prüfe ob Kunde bereits existiert
    SELECT id INTO v_existing_customer_id
    FROM public.customers
    WHERE email = NEW.email OR id = NEW.id;
    
    -- Wenn Kunde bereits existiert, nur ID synchronisieren falls nötig
    IF v_existing_customer_id IS NOT NULL THEN
        UPDATE public.customers
        SET
            id = NEW.id,  -- Stelle sicher, dass ID synchronisiert ist
            email = NEW.email,
            phone = COALESCE(NEW.phone, phone),
            updated_at = NOW()
        WHERE id = v_existing_customer_id OR email = NEW.email;
        
        RETURN NEW;
    END IF;
    
    -- Extrahiere Name aus user_metadata falls vorhanden
    v_first_name := COALESCE(
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'name',
        SPLIT_PART(NEW.email, '@', 1)
    );
    v_last_name := COALESCE(
        NEW.raw_user_meta_data->>'last_name',
        ''
    );
    
    -- Generiere Kundennummer (sicherer mit einfacherer Logik)
    BEGIN
        SELECT 'K-' || TO_CHAR(NOW(), 'YYYY') || '-' || 
               LPAD(
                   COALESCE(
                       (SELECT MAX(CAST(SUBSTRING(customer_number FROM '[0-9]+$') AS INTEGER)) 
                        FROM customers 
                        WHERE customer_number ~ ('^K-' || TO_CHAR(NOW(), 'YYYY') || '-[0-9]+$')),
                       0
                   ) + 1,
                   4, '0'
               ) INTO v_customer_number;
    EXCEPTION WHEN OTHERS THEN
        -- Fallback: Verwende Timestamp-basierte Nummer
        v_customer_number := 'K-' || TO_CHAR(NOW(), 'YYYY') || '-' || 
                            TO_CHAR(EXTRACT(EPOCH FROM NOW())::BIGINT, 'FM0000');
    END;
    
    -- Erstelle Kunde in customers Tabelle
    -- WICHTIG: id muss mit auth.users id übereinstimmen für RLS!
    BEGIN
        -- Versuche zuerst INSERT
        INSERT INTO public.customers (
            id,  -- Verwende die gleiche UUID wie auth.users
            customer_number,
            first_name,
            last_name,
            email,
            phone,
            status,  -- Status basierend auf email_confirmed_at
            email_verified_at
        ) VALUES (
            NEW.id,  -- Gleiche UUID wie Auth User
            v_customer_number,
            v_first_name,
            v_last_name,
            NEW.email,
            COALESCE(NEW.phone, NULL),
            CASE 
                WHEN NEW.email_confirmed_at IS NOT NULL THEN 'ACTIVE'
                ELSE 'UNVERIFIED'
            END,  -- Status
            NEW.email_confirmed_at  -- E-Mail-Verifikation
        )
        ON CONFLICT (id) DO UPDATE SET
            email = NEW.email,
            customer_number = COALESCE(EXCLUDED.customer_number, customers.customer_number),
            first_name = COALESCE(EXCLUDED.first_name, customers.first_name),
            last_name = COALESCE(EXCLUDED.last_name, customers.last_name),
            phone = COALESCE(EXCLUDED.phone, customers.phone),
            status = CASE 
                WHEN NEW.email_confirmed_at IS NOT NULL THEN 'ACTIVE'
                WHEN customers.status = 'UNVERIFIED' OR customers.status IS NULL THEN 'UNVERIFIED'
                ELSE customers.status
            END,
            email_verified_at = COALESCE(NEW.email_confirmed_at, customers.email_verified_at),
            updated_at = NOW();
    EXCEPTION WHEN OTHERS THEN
        -- Bei jedem Fehler: Versuche Update falls Kunde mit anderer ID oder E-Mail existiert
        BEGIN
            -- Versuche Update über E-Mail
            UPDATE public.customers
            SET 
                id = NEW.id,
                email = NEW.email,
                phone = COALESCE(NEW.phone, phone),
                updated_at = NOW()
            WHERE email = NEW.email;
            
            -- Falls kein Update stattfand, versuche über ID
            IF NOT FOUND THEN
                UPDATE public.customers
                SET 
                    email = NEW.email,
                    phone = COALESCE(NEW.phone, phone),
                    updated_at = NOW()
                WHERE id = NEW.id;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- Ignoriere Update-Fehler - Auth User soll trotzdem erstellt werden
            RAISE WARNING 'Konnte Kunde nicht erstellen oder aktualisieren für %: %', NEW.email, SQLERRM;
        END;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER 1: Auf neuen Auth User reagieren
-- ============================================

-- Trigger auf auth.users Tabelle
-- WICHTIG: Muss in der auth Schema erstellt werden
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_auth_user();

-- ============================================
-- FUNCTION 2: Prüfe und synchronisiere Auth User wenn Kunde erstellt wird
-- ============================================
-- HINWEIS: Auth Users können nicht direkt über SQL erstellt werden.
-- Verwende stattdessen die Supabase Auth API (signUp) oder das Dashboard.
-- Diese Function stellt nur sicher, dass die IDs synchronisiert sind.

CREATE OR REPLACE FUNCTION public.handle_new_customer()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Prüfe ob bereits ein Auth User mit dieser E-Mail existiert
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = NEW.email;
    
    -- Wenn Auth User existiert, stelle sicher, dass die IDs übereinstimmen
    IF v_user_id IS NOT NULL THEN
        -- Update customer ID falls sie nicht übereinstimmt
        IF v_user_id != NEW.id THEN
            UPDATE public.customers
            SET id = v_user_id
            WHERE id = NEW.id;
            
            RAISE NOTICE 'Customer ID angepasst für: % (Auth User ID: %)', NEW.email, v_user_id;
        ELSE
            RAISE NOTICE 'Customer und Auth User sind bereits synchronisiert für: %', NEW.email;
        END IF;
    ELSE
        -- Wenn kein Auth User existiert, nur Warnung ausgeben
        -- Auth User muss über Supabase Auth API oder Dashboard erstellt werden
        RAISE WARNING 'Kein Auth User gefunden für: %. Bitte erstelle den Auth User über Supabase Auth API (signUp) oder Dashboard. Der Kunde wurde erstellt, aber ohne Auth User kann sich der Benutzer nicht einloggen.', NEW.email;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER 2: Auf neuen Kunden reagieren
-- ============================================

DROP TRIGGER IF EXISTS on_customer_created ON public.customers;
CREATE TRIGGER on_customer_created
    AFTER INSERT ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_customer();

-- ============================================
-- FUNCTION 3: Update Kunde wenn Auth User aktualisiert wird
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_auth_user_updated()
RETURNS TRIGGER AS $$
BEGIN
    -- Update Kunde wenn E-Mail oder andere Daten geändert wurden
    UPDATE public.customers
    SET
        email = NEW.email,
        phone = COALESCE(NEW.phone, phone),
        updated_at = NOW()
    WHERE email = OLD.email OR email = NEW.email;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER 3: Auf Auth User Updates reagieren
-- ============================================

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    WHEN (OLD.email IS DISTINCT FROM NEW.email OR OLD.phone IS DISTINCT FROM NEW.phone)
    EXECUTE FUNCTION public.handle_auth_user_updated();

-- ============================================
-- FUNCTION 4: Update Auth User wenn Kunde aktualisiert wird
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_customer_updated()
RETURNS TRIGGER AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    -- Prüfe ob Auth User existiert
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = OLD.email OR email = NEW.email) INTO v_user_exists;
    
    IF v_user_exists THEN
        -- Update Auth User wenn E-Mail oder andere Daten geändert wurden
        UPDATE auth.users
        SET
            email = NEW.email,
            phone = COALESCE(NEW.phone, phone),
            raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || 
                jsonb_build_object(
                    'first_name', NEW.first_name,
                    'last_name', NEW.last_name
                ),
            updated_at = NOW()
        WHERE email = OLD.email OR email = NEW.email;
    ELSE
        RAISE NOTICE 'Kein Auth User gefunden für Update: %', NEW.email;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER 4: Auf Kunden Updates reagieren
-- ============================================

DROP TRIGGER IF EXISTS on_customer_updated ON public.customers;
CREATE TRIGGER on_customer_updated
    AFTER UPDATE ON public.customers
    FOR EACH ROW
    WHEN (
        OLD.email IS DISTINCT FROM NEW.email OR 
        OLD.first_name IS DISTINCT FROM NEW.first_name OR 
        OLD.last_name IS DISTINCT FROM NEW.last_name OR
        OLD.phone IS DISTINCT FROM NEW.phone
    )
    EXECUTE FUNCTION public.handle_customer_updated();

-- ============================================
-- HILFSFUNCTION: Manuelle Synchronisation
-- ============================================

CREATE OR REPLACE FUNCTION public.sync_all_auth_users_to_customers()
RETURNS TABLE(
    email TEXT,
    action TEXT,
    customer_id UUID
) AS $$
DECLARE
    auth_user RECORD;
    v_customer_id UUID;
    v_customer_number TEXT;
BEGIN
    -- Gehe durch alle Auth Users
    FOR auth_user IN 
        SELECT * FROM auth.users
        WHERE email IS NOT NULL
    LOOP
        -- Prüfe ob Kunde existiert
        SELECT id INTO v_customer_id
        FROM public.customers
        WHERE email = auth_user.email;
        
        IF v_customer_id IS NULL THEN
            -- Erstelle Kunde
            v_customer_number := 'K-' || TO_CHAR(NOW(), 'YYYY') || '-' || 
                LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(customer_number FROM '[0-9]+$') AS INTEGER)), 0) + 1 
                      FROM customers 
                      WHERE customer_number LIKE 'K-' || TO_CHAR(NOW(), 'YYYY') || '-%')::TEXT, 4, '0');
            
            INSERT INTO public.customers (
                id,  -- Verwende die gleiche UUID wie auth.users
                customer_number,
                first_name,
                last_name,
                email,
                phone
            ) VALUES (
                auth_user.id,  -- Gleiche UUID wie Auth User
                v_customer_number,
                COALESCE(
                    auth_user.raw_user_meta_data->>'first_name',
                    SPLIT_PART(auth_user.email, '@', 1)
                ),
                COALESCE(auth_user.raw_user_meta_data->>'last_name', ''),
                auth_user.email,
                auth_user.phone
            ) RETURNING id INTO v_customer_id;
            
            email := auth_user.email;
            action := 'created';
            customer_id := v_customer_id;
            RETURN NEXT;
        ELSE
            email := auth_user.email;
            action := 'exists';
            customer_id := v_customer_id;
            RETURN NEXT;
        END IF;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- BEREchtigungen
-- ============================================

-- Funktionen müssen als SECURITY DEFINER laufen, um auf auth.users zugreifen zu können
-- Dies wird bereits durch SECURITY DEFINER in den Functions gewährleistet

-- ============================================
-- TEST: Manuelle Synchronisation ausführen
-- ============================================

-- Führe diese Query aus, um alle bestehenden Auth Users zu synchronisieren:
-- SELECT * FROM public.sync_all_auth_users_to_customers();

