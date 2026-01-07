# 🔐 Account State Machine - Analyse & Vorschlag

## 📋 Übersicht

Dieses Dokument analysiert, wie eine vollständige Account State Machine mit Supabase implementiert werden kann, basierend auf den Best Practices.

---

## 🔍 Was bietet Supabase bereits?

### ✅ Bereits vorhanden in Supabase Auth:

1. **E-Mail-Verifikation**
   - ✅ `email_confirmed_at` (Timestamp oder null)
   - ✅ Automatische E-Mail-Versendung
   - ✅ Token-Handling (intern)
   - ✅ Redirect-URLs konfigurierbar

2. **Passwort-Reset**
   - ✅ `recovery_token` (intern verwaltet)
   - ✅ Automatische E-Mail-Versendung
   - ✅ Token-Ablaufzeit konfigurierbar

3. **Session-Management**
   - ✅ JWT-basiert (Access + Refresh Token)
   - ✅ Session-Rotation möglich
   - ✅ `onAuthStateChange` für State-Updates

4. **User-Metadaten**
   - ✅ `user_metadata` (JSONB) - für Custom-Daten
   - ✅ `raw_user_meta_data` - für App-spezifische Daten

5. **Basis-User-States (implizit)**
   - ✅ `email_confirmed_at IS NULL` = unverifiziert
   - ✅ `email_confirmed_at IS NOT NULL` = verifiziert
   - ✅ `banned_until` (in `auth.users`) - temporäres Ban

### ❌ Was Supabase NICHT bietet:

1. **Explizite Status-Felder**
   - ❌ Kein `status` Feld (PENDING_INVITE, UNVERIFIED, ACTIVE, etc.)
   - ❌ Kein `locked_until` Feld
   - ❌ Kein `failed_login_count` Feld

2. **Erweiterte Lockout-Logik**
   - ❌ Keine automatische Account-Sperrung nach Fehlversuchen
   - ❌ Keine exponentiellen Backoffs

3. **Token-Management**
   - ❌ Keine eigene `user_tokens` Tabelle
   - ❌ Keine Token-Historie/Audit

4. **Session-Management (erweitert)**
   - ❌ Keine "Geräte anzeigen" Funktionalität
   - ❌ Keine "Logout all devices" ohne Custom-Implementierung
   - ❌ Keine Session-Versionierung

5. **Rate-Limiting**
   - ❌ Kein eingebautes Rate-Limiting für Resend-Verification
   - ❌ Kein IP-basiertes Rate-Limiting

---

## 🎯 Vorschlag: Hybrid-Ansatz

### Strategie: Supabase Auth + Custom State Machine

**Prinzip:**
- Supabase Auth für: E-Mail-Verifikation, Passwort-Reset, Session-Management
- Custom `customers` Tabelle für: Status, Lockout, Failed-Login-Count, etc.
- Synchronisation zwischen beiden Systemen

---

## 📊 Datenmodell-Erweiterung

### 1. `customers` Tabelle erweitern

```sql
-- Neue Spalten für customers Tabelle
ALTER TABLE customers ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'UNVERIFIED' 
  CHECK (status IN ('PENDING_INVITE', 'UNVERIFIED', 'ACTIVE', 'LOCKED', 'SUSPENDED', 'DELETED', 'PASSWORD_RESET_REQUIRED'));

ALTER TABLE customers ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS failed_login_count INTEGER DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS failed_login_last_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS suspended_reason TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS last_verification_sent_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS session_version INTEGER DEFAULT 1;
```

### 2. Neue Tabelle: `user_tokens` (optional, für erweiterte Token-Verwaltung)

```sql
CREATE TABLE IF NOT EXISTS user_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('EMAIL_VERIFY', 'PASSWORD_RESET', 'INVITE')),
  token_hash TEXT NOT NULL, -- bcrypt/argon2 hash des Tokens
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used_at TIMESTAMP WITH TIME ZONE,
  sent_to_email TEXT,
  request_ip INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT token_unique_per_type UNIQUE (user_id, type, token_hash)
);

CREATE INDEX idx_user_tokens_user_id ON user_tokens(user_id);
CREATE INDEX idx_user_tokens_type ON user_tokens(type);
CREATE INDEX idx_user_tokens_expires_at ON user_tokens(expires_at);
```

**Hinweis:** Wenn wir Supabase's eingebautes Token-System nutzen, können wir diese Tabelle optional machen (nur für Audit/Logging).

---

## 🔄 State-Übergänge implementieren

### Funktionen für State-Transitions

```sql
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
    suspended_reason = CASE WHEN p_new_status = 'SUSPENDED' THEN p_reason ELSE suspended_reason END,
    deleted_at = CASE WHEN p_new_status = 'DELETED' THEN NOW() ELSE deleted_at END
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
```

---

## 🔐 Login-Flow mit State-Machine

### Entscheidungsmatrix für Login

```typescript
// Pseudocode für Login-Flow
async function signIn(email: string, password: string) {
  // 1. Normalize Email
  const normalizedEmail = email.toLowerCase().trim();
  
  // 2. Finde Customer (mit Status)
  const customer = await getCustomerByEmail(normalizedEmail);
  
  // 3. Prüfe Status (VOR Passwort-Check!)
  if (!customer) {
    // User Enumeration Schutz: Immer generische Meldung
    await fakePasswordCheck(); // Timing-Schutz
    throw new Error('E-Mail oder Passwort ist falsch.');
  }
  
  // 4. Status-Checks
  if (customer.status === 'DELETED') {
    await fakePasswordCheck();
    throw new Error('E-Mail oder Passwort ist falsch.');
  }
  
  if (customer.status === 'SUSPENDED') {
    // Hier können wir spezifisch sein, da Account existiert
    throw new Error('Ihr Account wurde gesperrt. Bitte kontaktieren Sie den Support.');
  }
  
  if (customer.status === 'LOCKED') {
    // Prüfe ob Lock abgelaufen
    await unlockCustomerAccountIfExpired(customer.id);
    
    // Prüfe erneut
    const updatedCustomer = await getCustomerByEmail(normalizedEmail);
    if (updatedCustomer.status === 'LOCKED') {
      throw new Error(`Zu viele Fehlversuche. Account gesperrt bis ${formatDate(customer.locked_until)}.`);
    }
  }
  
  // 5. Passwort-Check (Supabase Auth)
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: normalizedEmail,
      password: password
    });
    
    if (error) {
      // Passwort falsch
      await handleFailedLogin(customer.id);
      throw new Error('E-Mail oder Passwort ist falsch.');
    }
    
    // 6. Passwort korrekt - weitere Checks
    if (customer.status === 'UNVERIFIED') {
      // Option A: Blockieren
      await supabase.auth.signOut();
      throw new Error('Bitte bestätigen Sie zuerst Ihre E-Mail-Adresse.');
      
      // Option B: Erlauben aber eingeschränkt (nicht empfohlen)
    }
    
    if (customer.status === 'PASSWORD_RESET_REQUIRED') {
      // Redirect zu Passwort-Reset-Seite
      return { requiresPasswordReset: true, userId: customer.id };
    }
    
    // 7. Erfolgreich - Reset Failed-Login-Count
    await resetFailedLoginCount(customer.id);
    
    // 8. Session-Version prüfen (für "Logout all devices")
    // Optional: Prüfe ob session_version in JWT mit customer.session_version übereinstimmt
    
    return data;
    
  } catch (error) {
    // Fehler beim Login
    await handleFailedLogin(customer.id);
    throw error;
  }
}

async function handleFailedLogin(customerId: string) {
  // Failed-Login-Count erhöhen
  await supabase.rpc('increment_failed_login_count', { 
    customer_uuid: customerId 
  });
  
  // Prüfe ob Lockout nötig
  const customer = await getCustomerById(customerId);
  if (customer.failed_login_count >= 10) {
    await lockCustomerAccount(customerId, 15); // 15 Minuten
  }
}
```

---

## 📧 E-Mail-Verifikation mit Supabase

### Option A: Supabase's eingebautes System nutzen (empfohlen)

**Vorteile:**
- ✅ Bereits implementiert
- ✅ Token-Handling automatisch
- ✅ E-Mail-Versendung automatisch
- ✅ Ablaufzeit konfigurierbar

**Nachteile:**
- ❌ Keine Token-Historie
- ❌ Kein Custom-Token-Format

**Implementierung:**
```typescript
// Registrierung
async function signUp(email: string, password: string, ...) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: `${window.location.origin}/auth/confirm`,
      data: { first_name, last_name }
    }
  });
  
  // Status in customers Tabelle setzen
  if (data?.user) {
    await setCustomerStatus(data.user.id, 'UNVERIFIED');
    await updateLastVerificationSentAt(data.user.id);
  }
}

// E-Mail erneut senden (mit Rate-Limit)
async function resendVerificationEmail(email: string) {
  // Rate-Limit prüfen
  const customer = await getCustomerByEmail(email);
  if (!customer) {
    // User Enumeration Schutz
    return { success: true }; // Fake success
  }
  
  // Cooldown prüfen
  if (customer.last_verification_sent_at && 
      customer.last_verification_sent_at > NOW() - INTERVAL '60 seconds') {
    throw new Error('Bitte warten Sie, bevor Sie eine neue E-Mail anfordern.');
  }
  
  // Supabase Resend
  const { error } = await supabase.auth.resend({
    type: 'signup',
    email: email
  });
  
  if (!error) {
    await updateLastVerificationSentAt(customer.id);
  }
  
  // Immer success zurückgeben (User Enumeration Schutz)
  return { success: true };
}
```

### Option B: Custom Token-System (für erweiterte Kontrolle)

**Nur wenn nötig:**
- Eigene Token-Generierung
- Token-Historie/Audit
- Custom Token-Format

**Implementierung:**
- Eigene `user_tokens` Tabelle
- Edge Function für Token-Generierung
- Custom E-Mail-Versendung

---

## 🔄 Registrierung - Doppelte E-Mail behandeln

### Strategie: "Upsert UNVERIFIED" (empfohlen)

```typescript
async function signUp(email: string, password: string, ...) {
  const normalizedEmail = email.toLowerCase().trim();
  
  // Prüfe ob User existiert
  const existingCustomer = await getCustomerByEmail(normalizedEmail);
  
  if (existingCustomer) {
    if (existingCustomer.status === 'UNVERIFIED') {
      // Erlaube "Re-Registrierung" - aktualisiere Passwort
      // ABER: Keine neue E-Mail, wenn zu früh (Rate-Limit)
      
      const canResend = !existingCustomer.last_verification_sent_at || 
                       existingCustomer.last_verification_sent_at < NOW() - INTERVAL '60 seconds';
      
      if (canResend) {
        // Update Passwort in Supabase Auth (via Admin API)
        await updateAuthUserPassword(existingCustomer.id, password);
        
        // Resend Verification
        await resendVerificationEmail(normalizedEmail);
        
        return { 
          user: existingCustomer,
          message: 'E-Mail wurde erneut gesendet.' 
        };
      } else {
        throw new Error('Bitte warten Sie, bevor Sie eine neue E-Mail anfordern.');
      }
    } else if (existingCustomer.status === 'ACTIVE') {
      // User existiert bereits
      throw new Error('Ein Account mit dieser E-Mail existiert bereits. Bitte loggen Sie sich ein.');
    } else {
      // DELETED, SUSPENDED, etc.
      throw new Error('E-Mail oder Passwort ist falsch.'); // User Enumeration Schutz
    }
  }
  
  // Neuer User - normale Registrierung
  const { data, error } = await supabase.auth.signUp({
    email: normalizedEmail,
    password,
    options: {
      emailRedirectTo: `${window.location.origin}/auth/confirm`,
      data: { first_name, last_name }
    }
  });
  
  // Status setzen
  if (data?.user) {
    await setCustomerStatus(data.user.id, 'UNVERIFIED');
  }
  
  return data;
}
```

---

## 🔑 Passwort-Reset mit Supabase

### Supabase's eingebautes System nutzen

```typescript
// Passwort-Reset anfordern
async function requestPasswordReset(email: string) {
  // Immer success zurückgeben (User Enumeration Schutz)
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/auth/reset-password`
  });
  
  // Immer success (auch wenn User nicht existiert)
  return { success: true, message: 'Wenn ein Konto existiert, wurde eine E-Mail gesendet.' };
}

// Passwort zurücksetzen (nach Klick auf Link)
async function resetPassword(newPassword: string) {
  const { data, error } = await supabase.auth.updateUser({
    password: newPassword
  });
  
  if (!error && data?.user) {
    // Status zurücksetzen
    await setCustomerStatus(data.user.id, 'ACTIVE');
    await resetFailedLoginCount(data.user.id);
    await updatePasswordChangedAt(data.user.id);
    
    // Optional: Alle Sessions killen (Session-Version erhöhen)
    await incrementSessionVersion(data.user.id);
  }
  
  return data;
}
```

---

## 🔒 Session-Management erweitern

### Session-Versionierung für "Logout all devices"

```sql
-- Function: Session-Version erhöhen (killt alle Sessions)
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
```

**Frontend:**
```typescript
// In JWT Custom Claims speichern (via Supabase Edge Function)
// Oder in user_metadata speichern

// Bei jedem Request prüfen:
const customer = await getCustomerById(userId);
const sessionVersion = user.user_metadata?.session_version || 1;

if (sessionVersion !== customer.session_version) {
  // Session invalid - logout
  await signOut();
  throw new Error('Ihre Session wurde beendet. Bitte loggen Sie sich erneut ein.');
}
```

---

## 🛡️ Rate-Limiting

### Implementierung mit Supabase

**Option A: In Application-Layer (Frontend/Backend)**
```typescript
// Rate-Limit für Resend Verification
const RATE_LIMIT_COOLDOWN = 60; // Sekunden
const RATE_LIMIT_MAX_PER_HOUR = 5;

async function resendVerificationEmail(email: string) {
  const customer = await getCustomerByEmail(email);
  
  if (!customer) {
    return { success: true }; // Fake
  }
  
  // Cooldown prüfen
  if (customer.last_verification_sent_at && 
      customer.last_verification_sent_at > NOW() - INTERVAL '60 seconds') {
    throw new Error('Bitte warten Sie, bevor Sie eine neue E-Mail anfordern.');
  }
  
  // Count prüfen (letzte Stunde)
  const countLastHour = await getVerificationSentCountLastHour(customer.id);
  if (countLastHour >= RATE_LIMIT_MAX_PER_HOUR) {
    throw new Error('Zu viele Anfragen. Bitte versuchen Sie es später erneut.');
  }
  
  // Supabase Resend
  await supabase.auth.resend({ type: 'signup', email });
  await updateLastVerificationSentAt(customer.id);
  
  return { success: true };
}
```

**Option B: Supabase Edge Function mit Rate-Limiting**
- Edge Function für Resend
- Rate-Limit in Redis oder DB
- IP-basiertes Rate-Limiting

---

## 🧹 Cleanup-Jobs

### Unverifizierte Accounts löschen

```sql
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
    deleted_at = NOW()
  WHERE status = 'UNVERIFIED'
    AND created_at < NOW() - (p_days_old || ' days')::INTERVAL
    AND deleted_at IS NULL;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cron-Job einrichten (Supabase Cron oder extern)
-- Täglich ausführen: SELECT cleanup_unverified_accounts(30);
```

---

## 📋 Migration-Strategie

### Schritt 1: Schema erweitern
1. Neue Spalten zu `customers` hinzufügen
2. Bestehende User auf `ACTIVE` setzen (wenn `email_confirmed_at` gesetzt)
3. Bestehende User auf `UNVERIFIED` setzen (wenn `email_confirmed_at` NULL)

### Schritt 2: Functions erstellen
1. State-Transition Functions
2. Lock/Unlock Functions
3. Failed-Login Functions

### Schritt 3: Frontend anpassen
1. Login-Flow mit Status-Checks
2. Registrierung mit Duplikat-Behandlung
3. E-Mail-Verifikation-Handling

### Schritt 4: Sync mit Supabase Auth
1. Trigger für `email_confirmed_at` → Status auf `ACTIVE`
2. Trigger für Failed-Logins → Lockout
3. Trigger für Passwort-Reset → Status auf `PASSWORD_RESET_REQUIRED`

---

## 🎯 Empfehlungen

### Was mit Supabase nutzen:
1. ✅ **E-Mail-Verifikation** - Supabase's eingebautes System
2. ✅ **Passwort-Reset** - Supabase's eingebautes System
3. ✅ **Session-Management** - Supabase JWT
4. ✅ **Token-Handling** - Supabase's internes System

### Was selbst implementieren:
1. ✅ **Status-Feld** in `customers` Tabelle
2. ✅ **Lockout-Logik** (failed_login_count, locked_until)
3. ✅ **Rate-Limiting** für Resend-Verification
4. ✅ **Session-Versionierung** für "Logout all devices"
5. ✅ **Cleanup-Jobs** für unverifizierte Accounts

### Was optional ist:
1. ⚠️ **Custom Token-Tabelle** - Nur wenn Audit/Historie nötig
2. ⚠️ **Multi-Device Management** - Nur wenn "Geräte anzeigen" gewünscht
3. ⚠️ **Re-Auth für sensitive Aktionen** - Nur wenn nötig

---

## 📝 Nächste Schritte

1. **Schema erweitern** - Neue Spalten zu `customers` hinzufügen
2. **Functions erstellen** - State-Transitions, Lock/Unlock, etc.
3. **Sync-Triggers** - Synchronisation mit Supabase Auth
4. **Frontend anpassen** - Login/Registrierung mit Status-Checks
5. **Rate-Limiting** - Resend-Verification mit Cooldown
6. **Cleanup-Jobs** - Unverifizierte Accounts löschen

---

## 🔗 Referenzen

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Auth Helpers](https://supabase.com/docs/guides/auth/auth-helpers)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

