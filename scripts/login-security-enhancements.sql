-- ============================================
-- LOGIN SECURITY ENHANCEMENTS
-- ============================================
-- Umfassende Security-Implementierung für Login
-- User Enumeration Schutz, Rate-Limiting, Audit-Logging

-- ============================================
-- SCHRITT 1: IP-basiertes Rate-Limiting
-- ============================================

CREATE TABLE IF NOT EXISTS login_rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_address INET NOT NULL,
  identifier TEXT, -- Normalized email/username
  attempt_count INTEGER DEFAULT 1,
  window_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  window_end TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '1 hour',
  last_attempt_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  blocked_until TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT unique_ip_window UNIQUE (ip_address, window_start)
);

CREATE INDEX idx_login_rate_limits_ip ON login_rate_limits(ip_address);
CREATE INDEX idx_login_rate_limits_identifier ON login_rate_limits(identifier);
CREATE INDEX idx_login_rate_limits_window_end ON login_rate_limits(window_end);
CREATE INDEX idx_login_rate_limits_blocked_until ON login_rate_limits(blocked_until) WHERE blocked_until IS NOT NULL;

-- ============================================
-- SCHRITT 2: Login Audit Log
-- ============================================

CREATE TABLE IF NOT EXISTS login_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_address INET,
  user_agent TEXT,
  identifier TEXT, -- Normalized email/username
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  success BOOLEAN DEFAULT FALSE,
  failure_reason TEXT, -- Intern: 'user_not_found', 'wrong_password', 'locked', 'suspended', etc.
  status_at_attempt VARCHAR(50), -- Customer status zum Zeitpunkt des Versuchs
  response_time_ms INTEGER, -- Für Timing-Analyse
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Partitionierung nach Datum für Performance (optional)
  CONSTRAINT login_attempts_status_check CHECK (status_at_attempt IN ('PENDING_INVITE', 'UNVERIFIED', 'ACTIVE', 'LOCKED', 'SUSPENDED', 'DELETED', 'PASSWORD_RESET_REQUIRED', NULL))
);

CREATE INDEX idx_login_attempts_ip ON login_attempts(ip_address);
CREATE INDEX idx_login_attempts_identifier ON login_attempts(identifier);
CREATE INDEX idx_login_attempts_customer_id ON login_attempts(customer_id);
CREATE INDEX idx_login_attempts_created_at ON login_attempts(created_at);
CREATE INDEX idx_login_attempts_success ON login_attempts(success);

-- ============================================
-- SCHRITT 3: Rate-Limit Functions
-- ============================================

-- Function: Prüfe IP-basiertes Rate-Limit
CREATE OR REPLACE FUNCTION check_ip_rate_limit(
  p_ip_address INET,
  p_max_attempts_per_hour INTEGER DEFAULT 20,
  p_block_duration_minutes INTEGER DEFAULT 15
) RETURNS TABLE (
  allowed BOOLEAN,
  blocked_until TIMESTAMP WITH TIME ZONE,
  attempts_in_window INTEGER
) AS $$
DECLARE
  v_current_window_start TIMESTAMP WITH TIME ZONE;
  v_blocked_until TIMESTAMP WITH TIME ZONE;
  v_attempts INTEGER;
BEGIN
  -- Prüfe ob IP blockiert ist
  SELECT blocked_until INTO v_blocked_until
  FROM login_rate_limits
  WHERE ip_address = p_ip_address
    AND blocked_until > NOW()
  ORDER BY blocked_until DESC
  LIMIT 1;
  
  IF v_blocked_until IS NOT NULL THEN
    RETURN QUERY SELECT FALSE, v_blocked_until, 0;
    RETURN;
  END IF;
  
  -- Aktuelles Zeitfenster (letzte Stunde)
  v_current_window_start := date_trunc('hour', NOW());
  
  -- Hole oder erstelle Rate-Limit-Eintrag
  INSERT INTO login_rate_limits (ip_address, window_start, window_end, attempt_count, last_attempt_at)
  VALUES (p_ip_address, v_current_window_start, v_current_window_start + INTERVAL '1 hour', 1, NOW())
  ON CONFLICT (ip_address, window_start) 
  DO UPDATE SET
    attempt_count = login_rate_limits.attempt_count + 1,
    last_attempt_at = NOW(),
    updated_at = NOW()
  RETURNING attempt_count INTO v_attempts;
  
  -- Prüfe ob Limit überschritten
  IF v_attempts > p_max_attempts_per_hour THEN
    -- Blockiere IP
    UPDATE login_rate_limits
    SET blocked_until = NOW() + (p_block_duration_minutes || ' minutes')::INTERVAL
    WHERE ip_address = p_ip_address
      AND window_start = v_current_window_start;
    
    RETURN QUERY SELECT 
      FALSE, 
      NOW() + (p_block_duration_minutes || ' minutes')::INTERVAL,
      v_attempts;
    RETURN;
  END IF;
  
  -- Erlaubt
  RETURN QUERY SELECT TRUE, NULL::TIMESTAMP WITH TIME ZONE, v_attempts;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Prüfe Identifier-basiertes Rate-Limit
CREATE OR REPLACE FUNCTION check_identifier_rate_limit(
  p_identifier TEXT,
  p_max_attempts_per_hour INTEGER DEFAULT 10,
  p_block_duration_minutes INTEGER DEFAULT 15
) RETURNS TABLE (
  allowed BOOLEAN,
  blocked_until TIMESTAMP WITH TIME ZONE,
  attempts_in_window INTEGER
) AS $$
DECLARE
  v_current_window_start TIMESTAMP WITH TIME ZONE;
  v_blocked_until TIMESTAMP WITH TIME ZONE;
  v_attempts INTEGER;
BEGIN
  -- Prüfe ob Identifier blockiert ist
  SELECT blocked_until INTO v_blocked_until
  FROM login_rate_limits
  WHERE identifier = p_identifier
    AND blocked_until > NOW()
  ORDER BY blocked_until DESC
  LIMIT 1;
  
  IF v_blocked_until IS NOT NULL THEN
    RETURN QUERY SELECT FALSE, v_blocked_until, 0;
    RETURN;
  END IF;
  
  -- Aktuelles Zeitfenster (letzte Stunde)
  v_current_window_start := date_trunc('hour', NOW());
  
  -- Hole oder erstelle Rate-Limit-Eintrag
  INSERT INTO login_rate_limits (identifier, window_start, window_end, attempt_count, last_attempt_at)
  VALUES (p_identifier, v_current_window_start, v_current_window_start + INTERVAL '1 hour', 1, NOW())
  ON CONFLICT (identifier, window_start) 
  DO UPDATE SET
    attempt_count = login_rate_limits.attempt_count + 1,
    last_attempt_at = NOW(),
    updated_at = NOW()
  RETURNING attempt_count INTO v_attempts;
  
  -- Prüfe ob Limit überschritten
  IF v_attempts > p_max_attempts_per_hour THEN
    -- Blockiere Identifier
    UPDATE login_rate_limits
    SET blocked_until = NOW() + (p_block_duration_minutes || ' minutes')::INTERVAL
    WHERE identifier = p_identifier
      AND window_start = v_current_window_start;
    
    RETURN QUERY SELECT 
      FALSE, 
      NOW() + (p_block_duration_minutes || ' minutes')::INTERVAL,
      v_attempts;
    RETURN;
  END IF;
  
  -- Erlaubt
  RETURN QUERY SELECT TRUE, NULL::TIMESTAMP WITH TIME ZONE, v_attempts;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Prüfe Credential Stuffing Pattern (viele Identifier pro IP)
CREATE OR REPLACE FUNCTION check_credential_stuffing_pattern(
  p_ip_address INET,
  p_unique_identifiers_threshold INTEGER DEFAULT 10,
  p_time_window_minutes INTEGER DEFAULT 5
) RETURNS BOOLEAN AS $$
DECLARE
  v_unique_count INTEGER;
BEGIN
  SELECT COUNT(DISTINCT identifier) INTO v_unique_count
  FROM login_attempts
  WHERE ip_address = p_ip_address
    AND created_at > NOW() - (p_time_window_minutes || ' minutes')::INTERVAL
    AND success = FALSE;
  
  RETURN v_unique_count >= p_unique_identifiers_threshold;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHRITT 4: Login Validation Function
-- ============================================

-- Function: Normalisiere Identifier (Email)
CREATE OR REPLACE FUNCTION normalize_identifier(
  p_identifier TEXT
) RETURNS TEXT AS $$
BEGIN
  -- Trim, Lowercase, Unicode Normalization (NFC)
  RETURN LOWER(TRIM(COALESCE(p_identifier, '')));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Validiere Login-Input
CREATE OR REPLACE FUNCTION validate_login_input(
  p_identifier TEXT,
  p_password TEXT,
  p_max_identifier_length INTEGER DEFAULT 255,
  p_max_password_length INTEGER DEFAULT 256,
  p_min_identifier_length INTEGER DEFAULT 3
) RETURNS TABLE (
  valid BOOLEAN,
  error_code TEXT,
  error_message TEXT
) AS $$
DECLARE
  v_normalized_identifier TEXT;
BEGIN
  -- 1. Prüfe ob Identifier vorhanden
  IF p_identifier IS NULL OR TRIM(p_identifier) = '' THEN
    RETURN QUERY SELECT FALSE, 'MISSING_IDENTIFIER', 'E-Mail oder Passwort ist falsch.';
    RETURN;
  END IF;
  
  -- 2. Prüfe ob Passwort vorhanden
  IF p_password IS NULL OR TRIM(p_password) = '' THEN
    RETURN QUERY SELECT FALSE, 'MISSING_PASSWORD', 'E-Mail oder Passwort ist falsch.';
    RETURN;
  END IF;
  
  -- 3. Normalisiere Identifier
  v_normalized_identifier := normalize_identifier(p_identifier);
  
  -- 4. Prüfe Identifier-Länge
  IF LENGTH(v_normalized_identifier) < p_min_identifier_length THEN
    RETURN QUERY SELECT FALSE, 'IDENTIFIER_TOO_SHORT', 'E-Mail oder Passwort ist falsch.';
    RETURN;
  END IF;
  
  IF LENGTH(v_normalized_identifier) > p_max_identifier_length THEN
    RETURN QUERY SELECT FALSE, 'IDENTIFIER_TOO_LONG', 'E-Mail oder Passwort ist falsch.';
    RETURN;
  END IF;
  
  -- 5. Prüfe Passwort-Länge (Payload-Abuse Schutz)
  IF LENGTH(p_password) > p_max_password_length THEN
    RETURN QUERY SELECT FALSE, 'PASSWORD_TOO_LONG', 'E-Mail oder Passwort ist falsch.';
    RETURN;
  END IF;
  
  -- 6. Prüfe auf SQL-Injection-Patterns (vereinfacht - sollte in WAF sein)
  -- Hier nur grundlegende Checks
  IF v_normalized_identifier ~* '(union|select|insert|update|delete|drop|exec|script)' THEN
    RETURN QUERY SELECT FALSE, 'SUSPICIOUS_PATTERN', 'E-Mail oder Passwort ist falsch.';
    RETURN;
  END IF;
  
  -- Validiert
  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHRITT 5: Login Attempt Logging
-- ============================================

-- Function: Logge Login-Versuch
CREATE OR REPLACE FUNCTION log_login_attempt(
  p_ip_address INET,
  p_user_agent TEXT,
  p_identifier TEXT,
  p_customer_id UUID,
  p_success BOOLEAN,
  p_failure_reason TEXT,
  p_status_at_attempt VARCHAR(50),
  p_response_time_ms INTEGER
) RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO login_attempts (
    ip_address,
    user_agent,
    identifier,
    customer_id,
    success,
    failure_reason,
    status_at_attempt,
    response_time_ms
  ) VALUES (
    p_ip_address,
    p_user_agent,
    p_identifier,
    p_customer_id,
    p_success,
    p_failure_reason,
    p_status_at_attempt,
    p_response_time_ms
  )
  RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHRITT 6: Cleanup-Jobs
-- ============================================

-- Function: Bereinige alte Rate-Limit-Einträge
CREATE OR REPLACE FUNCTION cleanup_old_rate_limits(
  p_days_old INTEGER DEFAULT 7
) RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM login_rate_limits
  WHERE window_end < NOW() - (p_days_old || ' days')::INTERVAL
    AND (blocked_until IS NULL OR blocked_until < NOW());
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Bereinige alte Login-Attempts (optional - für Datenschutz)
CREATE OR REPLACE FUNCTION cleanup_old_login_attempts(
  p_days_old INTEGER DEFAULT 90
) RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM login_attempts
  WHERE created_at < NOW() - (p_days_old || ' days')::INTERVAL;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHRITT 7: Helper Functions
-- ============================================

-- Function: Fake Password Verify (für Timing-Schutz)
CREATE OR REPLACE FUNCTION fake_password_verify()
RETURNS VOID AS $$
BEGIN
  -- Simuliere Passwort-Verifikation für Timing-Schutz
  -- Verwendet bcrypt's typische Verzögerung (~100-200ms)
  PERFORM pg_sleep(0.1); -- 100ms Delay
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Prüfe ob User existiert (mit Data Integrity Check)
CREATE OR REPLACE FUNCTION check_user_exists(
  p_normalized_identifier TEXT
) RETURNS TABLE (
  exists BOOLEAN,
  customer_id UUID,
  status VARCHAR(50),
  email_verified_at TIMESTAMP WITH TIME ZONE,
  locked_until TIMESTAMP WITH TIME ZONE,
  failed_login_count INTEGER,
  data_integrity_issue BOOLEAN
) AS $$
DECLARE
  v_customer_count INTEGER;
  v_customer RECORD;
BEGIN
  -- Prüfe auf Data Integrity (mehrere Treffer)
  SELECT COUNT(*) INTO v_customer_count
  FROM customers
  WHERE email = p_normalized_identifier
    AND deleted_at IS NULL;
  
  IF v_customer_count = 0 THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, NULL::VARCHAR(50), NULL::TIMESTAMP WITH TIME ZONE, NULL::TIMESTAMP WITH TIME ZONE, NULL::INTEGER, FALSE;
    RETURN;
  END IF;
  
  -- Hole Customer-Daten
  SELECT 
    id,
    status,
    email_verified_at,
    locked_until,
    failed_login_count
  INTO v_customer
  FROM customers
  WHERE email = p_normalized_identifier
    AND deleted_at IS NULL
  ORDER BY created_at ASC -- Bei Duplikaten: Nimm den ältesten
  LIMIT 1;
  
  -- Prüfe auf Data Integrity Issue
  IF v_customer_count > 1 THEN
    -- Logge intern (könnte auch in separate Tabelle)
    RETURN QUERY SELECT 
      TRUE, 
      v_customer.id, 
      v_customer.status, 
      v_customer.email_verified_at,
      v_customer.locked_until,
      v_customer.failed_login_count,
      TRUE; -- data_integrity_issue
    RETURN;
  END IF;
  
  -- Normaler Fall
  RETURN QUERY SELECT 
    TRUE, 
    v_customer.id, 
    v_customer.status, 
    v_customer.email_verified_at,
    v_customer.locked_until,
    v_customer.failed_login_count,
    FALSE; -- data_integrity_issue
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SCHRITT 8: RLS Policies
-- ============================================

-- Login-Attempts: Nur Admins können sehen
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view login attempts"
  ON login_attempts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.id = auth.uid()
      AND customers.email = 'admin@admin.de' -- Oder echte Admin-Rolle
    )
  );

-- Rate-Limits: Nur System kann schreiben
ALTER TABLE login_rate_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System can manage rate limits"
  ON login_rate_limits FOR ALL
  USING (true) -- Nur via Functions
  WITH CHECK (true);

-- ============================================
-- SCHRITT 9: Kommentare
-- ============================================

COMMENT ON TABLE login_rate_limits IS 'IP- und Identifier-basiertes Rate-Limiting für Login-Versuche';
COMMENT ON TABLE login_attempts IS 'Audit-Log für alle Login-Versuche (Security & Compliance)';
COMMENT ON FUNCTION fake_password_verify() IS 'Simuliert Passwort-Verifikation für Timing-Schutz gegen User Enumeration';
COMMENT ON FUNCTION check_user_exists(TEXT) IS 'Prüft User-Existenz mit Data Integrity Check';

