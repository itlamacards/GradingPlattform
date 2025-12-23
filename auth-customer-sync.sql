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
BEGIN
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
    
    -- Generiere Kundennummer
    v_customer_number := 'K-' || TO_CHAR(NOW(), 'YYYY') || '-' || 
        LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(customer_number FROM '[0-9]+$') AS INTEGER)), 0) + 1 
              FROM customers 
              WHERE customer_number LIKE 'K-' || TO_CHAR(NOW(), 'YYYY') || '-%')::TEXT, 4, '0');
    
    -- Erstelle Kunde in customers Tabelle
    -- WICHTIG: id muss mit auth.users id übereinstimmen für RLS!
    INSERT INTO public.customers (
        id,  -- Verwende die gleiche UUID wie auth.users
        customer_number,
        first_name,
        last_name,
        email,
        phone
    ) VALUES (
        NEW.id,  -- Gleiche UUID wie Auth User
        v_customer_number,
        v_first_name,
        v_last_name,
        NEW.email,
        COALESCE(NEW.phone, NULL)
    )
    ON CONFLICT (email) DO UPDATE SET
        id = NEW.id,  -- Stelle sicher, dass ID synchronisiert ist
        updated_at = NOW();
    
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
-- FUNCTION 2: Erstelle Auth User wenn Kunde erstellt wird
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_customer()
RETURNS TRIGGER AS $$
DECLARE
    v_password TEXT;
    v_user_id UUID;
BEGIN
    -- Prüfe ob bereits ein Auth User mit dieser E-Mail existiert
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = NEW.email;
    
    -- Wenn kein User existiert, erstelle einen
    IF v_user_id IS NULL THEN
        -- Generiere ein temporäres Passwort (User muss es ändern)
        -- Oder verwende ein Standard-Passwort
        v_password := 'TempPass123!';
        
        -- Erstelle Auth User über Supabase Auth
        -- HINWEIS: Dies funktioniert nur mit Service Role Key oder über die Management API
        -- Für direkte DB-Erstellung müssen wir die auth.users Tabelle verwenden
        
        -- Alternative: Verwende Supabase Management API oder eine Edge Function
        -- Hier erstellen wir den User direkt in auth.users (nur mit Service Role möglich)
        
        -- Erstelle Auth User mit der gleichen UUID wie der Kunde
        -- WICHTIG: id muss mit customers.id übereinstimmen für RLS!
        INSERT INTO auth.users (
            instance_id,
            id,  -- Verwende die gleiche UUID wie customers
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            invited_at,
            confirmation_token,
            confirmation_sent_at,
            recovery_token,
            recovery_sent_at,
            email_change_token_new,
            email_change,
            email_change_sent_at,
            last_sign_in_at,
            raw_app_meta_data,
            raw_user_meta_data,
            is_super_admin,
            created_at,
            updated_at,
            phone,
            phone_confirmed_at,
            phone_change,
            phone_change_token,
            phone_change_sent_at,
            confirmed_at,
            email_change_token_current,
            email_change_confirm_status,
            banned_until,
            reauthentication_token,
            reauthentication_sent_at,
            is_sso_user,
            deleted_at
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', -- instance_id
            NEW.id,  -- Gleiche UUID wie Customer
            'authenticated', -- aud
            'authenticated', -- role
            NEW.email, -- email
            crypt(v_password, gen_salt('bf')), -- encrypted_password (gehasht)
            NOW(), -- email_confirmed_at (auto-confirm)
            NULL, -- invited_at
            '', -- confirmation_token
            NULL, -- confirmation_sent_at
            '', -- recovery_token
            NULL, -- recovery_sent_at
            '', -- email_change_token_new
            '', -- email_change
            NULL, -- email_change_sent_at
            NULL, -- last_sign_in_at
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']), -- raw_app_meta_data
            jsonb_build_object(
                'first_name', NEW.first_name,
                'last_name', NEW.last_name,
                'email_verified', true
            ), -- raw_user_meta_data
            false, -- is_super_admin
            NOW(), -- created_at
            NOW(), -- updated_at
            NEW.phone, -- phone
            NULL, -- phone_confirmed_at
            '', -- phone_change
            '', -- phone_change_token
            NULL, -- phone_change_sent_at
            NOW(), -- confirmed_at (auto-confirm)
            '', -- email_change_token_current
            0, -- email_change_confirm_status
            NULL, -- banned_until
            '', -- reauthentication_token
            NULL, -- reauthentication_sent_at
            false, -- is_sso_user
            NULL -- deleted_at
        )
        ON CONFLICT (email) DO NOTHING;
        
        RAISE NOTICE 'Auth User erstellt für: %', NEW.email;
    ELSE
        RAISE NOTICE 'Auth User existiert bereits für: %', NEW.email;
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
BEGIN
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

