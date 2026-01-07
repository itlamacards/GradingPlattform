-- ============================================
-- ACCOUNT STATE MACHINE - Schema & Functions
-- ============================================
-- Erweitert die customers Tabelle um Status-Management
-- Implementiert: Lockout, Failed-Login-Count, Rate-Limiting, etc.

-- ============================================
-- SCHRITT 1: Schema erweitern
-- ============================================

-- Status-Feld hinzufügen
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'UNVERIFIED' 
CHECK (status IN ('PENDING_INVITE', 'UNVERIFIED', 'ACTIVE', 'LOCKED', 'SUSPENDED', 'DELETED', 'PASSWORD_RESET_REQUIRED'));

-- E-Mail-Verifikation
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP WITH TIME ZONE;

-- Lockout-Management
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP WITH TIME ZONE;

-- Failed-Login-Tracking
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS failed_login_count INTEGER DEFAULT 0;
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS failed_login_last_at TIMESTAMP WITH TIME ZONE;

-- Soft Delete
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Suspension
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS suspended_reason TEXT;

-- Rate-Limiting für E-Mail-Verifikation
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS last_verification_sent_at TIMESTAMP WITH TIME ZONE;

-- Passwort-Management
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMP WITH TIME ZONE;

-- Session-Versionierung (für "Logout all devices")
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS session_version INTEGER DEFAULT 1;

-- Indizes für Performance
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_locked_until ON customers(locked_until) WHERE locked_until IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_email_verified_at ON customers(email_verified_at) WHERE email_verified_at IS NOT NULL;

-- ============================================
-- SCHRITT 2: Bestehende User migrieren
-- ============================================

-- Setze Status basierend auf email_confirmed_at
UPDATE customers
SET 
  status = CASE 
    WHEN email_verified_at IS NOT NULL THEN 'ACTIVE'
    ELSE 'UNVERIFIED'
  END,
  email_verified_at = COALESCE(
    email_verified_at,
    (SELECT email_confirmed_at FROM auth.users WHERE auth.users.id = customers.id)
  )
WHERE status IS NULL OR status = 'UNVERIFIED';

-- ============================================
-- SCHRITT 3: State-Transition Functions
-- ============================================

-- Function: Status ändern
CREATE OR REPLACE FUNCTION set_customer_status(
  p_customer_id UUID,
  p_new_status VARCHAR(50),
  p_reason TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET 
    status = p_new_status,
    updated_at = NOW(),
    suspended_at = CASE WHEN p_new_status = 'SUSPENDED' THEN NOW() ELSE suspended_at END,
    suspended_reason = CASE WHEN p_new_status = 'SUSPENDED' THEN COALESCE(p_reason, suspended_reason) ELSE suspended_reason END,
    deleted_at = CASE WHEN p_new_status = 'DELETED' THEN NOW() ELSE deleted_at END,
    locked_until = CASE WHEN p_new_status != 'LOCKED' THEN NULL ELSE locked_until END
  WHERE id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Account sperren (nach Fehlversuchen)
CREATE OR REPLACE FUNCTION lock_customer_account(
  p_customer_id UUID,
  p_lock_duration_minutes INTEGER DEFAULT 15
) RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET 
    status = 'LOCKED',
    locked_until = NOW() + (p_lock_duration_minutes || ' minutes')::INTERVAL,
    updated_at = NOW()
  WHERE id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Account entsperren (wenn Zeit abgelaufen)
CREATE OR REPLACE FUNCTION unlock_customer_account_if_expired(
  p_customer_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_locked_until TIMESTAMP WITH TIME ZONE;
BEGIN
  SELECT locked_until INTO v_locked_until
  FROM customers
  WHERE id = p_customer_id AND status = 'LOCKED';
  
  IF v_locked_until IS NULL THEN
    RETURN FALSE;
  END IF;
  
  IF v_locked_until < NOW() THEN
    UPDATE customers
    SET 
      status = 'ACTIVE',
      locked_until = NULL,
      failed_login_count = 0,
      updated_at = NOW()
    WHERE id = p_customer_id;
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Failed-Login-Count erhöhen
CREATE OR REPLACE FUNCTION increment_failed_login_count(
  p_customer_id UUID
) RETURNS VOID AS $$
DECLARE
  v_new_count INTEGER;
  v_lock_threshold INTEGER := 10;
BEGIN
  UPDATE customers
  SET 
    failed_login_count = failed_login_count + 1,
    failed_login_last_at = NOW(),
    updated_at = NOW()
  WHERE id = p_customer_id
  RETURNING failed_login_count INTO v_new_count;
  
  -- Lockout nach 10 Fehlversuchen
  IF v_new_count >= v_lock_threshold THEN
    PERFORM lock_customer_account(p_customer_id, 15); -- 15 Minuten
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Failed-Login-Count zurücksetzen
CREATE OR REPLACE FUNCTION reset_failed_login_count(
  p_customer_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET 
    failed_login_count = 0,
    failed_login_last_at = NULL,
    updated_at = NOW()
  WHERE id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: E-Mail-Verifikation aktualisieren
CREATE OR REPLACE FUNCTION mark_email_as_verified(
  p_customer_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET 
    email_verified_at = NOW(),
    status = CASE 
      WHEN status = 'UNVERIFIED' THEN 'ACTIVE'
      WHEN status = 'PENDING_INVITE' THEN 'ACTIVE'
      ELSE status
    END,
    updated_at = NOW()
  WHERE id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Last Verification Sent At aktualisieren
CREATE OR REPLACE FUNCTION update_last_verification_sent_at(
  p_customer_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET 
    last_verification_sent_at = NOW(),
    updated_at = NOW()
  WHERE id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Session-Version erhöhen (für "Logout all devices")
CREATE OR REPLACE FUNCTION increment_session_version(
  p_customer_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET 
    session_version = session_version + 1,
    updated_at = NOW()
  WHERE id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Passwort geändert
CREATE OR REPLACE FUNCTION update_password_changed_at(
  p_customer_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE customers
  SET 
    password_changed_at = NOW(),
    status = CASE 
      WHEN status = 'PASSWORD_RESET_REQUIRED' THEN 'ACTIVE'
      ELSE status
    END,
    updated_at = NOW()
  WHERE id = p_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Rate-Limit für Resend Verification prüfen
CREATE OR REPLACE FUNCTION can_resend_verification(
  p_customer_id UUID,
  p_cooldown_seconds INTEGER DEFAULT 60,
  p_max_per_hour INTEGER DEFAULT 5
) RETURNS BOOLEAN AS $$
DECLARE
  v_last_sent TIMESTAMP WITH TIME ZONE;
  v_count_last_hour INTEGER;
BEGIN
  -- Hole letzte Versendung
  SELECT last_verification_sent_at INTO v_last_sent
  FROM customers
  WHERE id = p_customer_id;
  
  -- Cooldown prüfen
  IF v_last_sent IS NOT NULL AND v_last_sent > NOW() - (p_cooldown_seconds || ' seconds')::INTERVAL THEN
    RETURN FALSE;
  END IF;
  
  -- Count in letzter Stunde prüfen (vereinfacht - könnte auch in separate Tabelle)
  -- Für jetzt: Wenn letzte Versendung weniger als 1 Stunde her, prüfen wir nicht
  -- In Production: Separate Tabelle für Rate-Limit-Tracking
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHRITT 4: Sync-Triggers mit Supabase Auth
-- ============================================

-- Trigger: E-Mail-Verifikation in Supabase Auth → Status aktualisieren
CREATE OR REPLACE FUNCTION sync_email_verification_from_auth()
RETURNS TRIGGER AS $$
BEGIN
  -- Wenn email_confirmed_at gesetzt wird, markiere E-Mail als verifiziert
  IF NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at) THEN
    PERFORM mark_email_as_verified(NEW.id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger auf auth.users (via Supabase Function oder Edge Function)
-- HINWEIS: Direkte Triggers auf auth.users sind in Supabase nicht möglich
-- Alternative: Edge Function oder Webhook nutzen

-- ============================================
-- SCHRITT 5: Cleanup-Jobs
-- ============================================

-- Function: Unverifizierte Accounts älter als X Tage löschen
CREATE OR REPLACE FUNCTION cleanup_unverified_accounts(
  p_days_old INTEGER DEFAULT 30
) RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  UPDATE customers
  SET 
    status = 'DELETED',
    deleted_at = NOW(),
    updated_at = NOW()
  WHERE status = 'UNVERIFIED'
    AND created_at < NOW() - (p_days_old || ' days')::INTERVAL
    AND deleted_at IS NULL;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHRITT 6: Helper Functions für Frontend
-- ============================================

-- Function: Customer mit Status abrufen
CREATE OR REPLACE FUNCTION get_customer_with_status(
  p_email TEXT
) RETURNS TABLE (
  id UUID,
  customer_number TEXT,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  status VARCHAR(50),
  email_verified_at TIMESTAMP WITH TIME ZONE,
  locked_until TIMESTAMP WITH TIME ZONE,
  failed_login_count INTEGER,
  last_verification_sent_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.customer_number,
    c.first_name,
    c.last_name,
    c.email,
    c.status,
    c.email_verified_at,
    c.locked_until,
    c.failed_login_count,
    c.last_verification_sent_at
  FROM customers c
  WHERE c.email = LOWER(TRIM(p_email))
    AND c.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHRITT 7: RLS Policies anpassen
-- ============================================

-- Bestehende Policies bleiben, aber Status-Checks hinzufügen
-- User können nur ihre eigenen Daten sehen (bereits implementiert)

-- ============================================
-- SCHRITT 8: Kommentare für Dokumentation
-- ============================================

COMMENT ON COLUMN customers.status IS 'Account-Status: PENDING_INVITE, UNVERIFIED, ACTIVE, LOCKED, SUSPENDED, DELETED, PASSWORD_RESET_REQUIRED';
COMMENT ON COLUMN customers.locked_until IS 'Account gesperrt bis zu diesem Zeitpunkt (temporär)';
COMMENT ON COLUMN customers.failed_login_count IS 'Anzahl fehlgeschlagener Login-Versuche';
COMMENT ON COLUMN customers.session_version IS 'Wird bei Passwort-Reset erhöht, um alle Sessions zu invalidieren';


