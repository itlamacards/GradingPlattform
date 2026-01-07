# 🔐 Login Security - Implementierung

## Übersicht

Diese Implementierung deckt alle Security-Fälle für Login ab:
- ✅ User Enumeration Schutz
- ✅ Rate-Limiting (IP + Identifier)
- ✅ Timing-Schutz
- ✅ Input-Validation
- ✅ Audit-Logging
- ✅ Credential Stuffing Detection

## 📋 Implementierte Fälle

### 0) Grundprinzip

- ✅ **Response-Text**: Immer identisch ("E-Mail oder Passwort ist falsch.")
- ✅ **Timing**: Möglichst ähnlich (Fake Password Verify)
- ✅ **Logging/Audit**: Intern detailliert (Grund, IP, User-Agent, Timestamp, user_id)
- ✅ **Rate-Limits**: Immer aktiv (IP + Account/Identifier)

### 1) Request / Input / Format-Fälle

- ✅ Request ohne Body / falsches Content-Type → 400, gleiche Meldung
- ✅ Felder fehlen (identifier oder password) → 400, gleiche Meldung
- ✅ Felder nur Whitespace → gleiche Meldung
- ✅ Identifier zu kurz/zu lang → gleiche Meldung (Rate-Limit trotzdem zählen)
- ✅ Passwort zu kurz/zu lang (Payload-Abuse) → gleiche Meldung
- ✅ Unicode/Normalisierung-Probleme → normalize (NFC) + trim
- ✅ Upper/Lower Case im Identifier → normalize (lowercase)
- ✅ SQL/Injection-Patterns → block + gleiche Meldung
- ✅ Mehrfach-Submit (Doppelklick) → idempotent/lock pro identifier

### 2) Lookup-Fälle (User finden)

- ✅ Identifier existiert nicht → Fake-Hash-Verify + gleiche Meldung
- ✅ Mehrere Treffer (Data Integrity) → intern loggen, gleiche Meldung
- ✅ User existiert, aber Primär-Login-Identifier fehlt → block, gleiche Meldung
- ✅ User existiert, aber Status = DELETED → behandeln wie "nicht existiert"
- ✅ User existiert, aber Status = SUSPENDED → block, gleiche Meldung (kann spezifisch sein)
- ✅ User existiert, aber Status = LOCKED → block, gleiche Meldung
- ✅ User existiert, aber Status = UNVERIFIED → block (nach Passwort-Check spezifisch)
- ✅ User existiert, aber Status = PASSWORD_RESET_REQUIRED → block oder "force reset"

### 3) Passwortprüfung-Fälle

- ✅ Passwort falsch → failed_login_count++ + gleiche Meldung
- ✅ Passwort richtig, aber Account darf trotzdem nicht → block, UI gleich
- ✅ Password-Hash fehlt → block + gleiche Meldung, intern alarm
- ✅ Password-Hash-Algorithmus unbekannt → block + gleiche Meldung
- ✅ Hash-Verify wirft Exception → treat as fail, gleiche Meldung
- ✅ Timing Side-Channel → immer gleicher Pfad: normalize → lookup → (wenn nicht gefunden) dummy verify → fail

### 4) Rate-Limits / Brute-Force / Lockout-Fälle

- ✅ Zu viele Versuche von gleicher IP → block, gleiche Meldung
- ✅ Zu viele Versuche für denselben Identifier → block, gleiche Meldung
- ✅ Zu viele Fehlversuche beim User → Lockout → gleiche Meldung
- ✅ Credential Stuffing Pattern → härter throttlen, gleiche Meldung
- ✅ Distributed Attack → block am identifier, gleiche Meldung
- ✅ Nach Lockout: Counter-Reset-Regel → failed_login_count zurücksetzen bei erfolgreichem Login
- ✅ Login-Versuche zählen trotz Formatfehler → IP-limit zählen

## 🗄️ Datenbank-Schema

### Neue Tabellen

1. **`login_rate_limits`**
   - IP-basiertes Rate-Limiting
   - Identifier-basiertes Rate-Limiting
   - Blocked-Until Tracking

2. **`login_attempts`**
   - Audit-Log für alle Login-Versuche
   - IP, User-Agent, Identifier, Success/Failure
   - Failure-Reason für interne Analyse

### Neue Functions

- `check_ip_rate_limit()` - IP-basiertes Rate-Limiting
- `check_identifier_rate_limit()` - Identifier-basiertes Rate-Limiting
- `check_credential_stuffing_pattern()` - Credential Stuffing Detection
- `validate_login_input()` - Input-Validation
- `normalize_identifier()` - Identifier-Normalisierung
- `check_user_exists()` - User-Lookup mit Data Integrity Check
- `fake_password_verify()` - Timing-Schutz
- `log_login_attempt()` - Audit-Logging
- `cleanup_old_rate_limits()` - Cleanup-Jobs
- `cleanup_old_login_attempts()` - Cleanup-Jobs

## 🔧 Frontend-Implementierung

### `src/services/secureLogin.ts`

Vollständige Security-Implementierung mit:
- Input-Validation
- Rate-Limiting-Checks
- User-Lookup mit Data Integrity
- Status-Checks (User Enumeration Schutz)
- Password-Verification
- Post-Password Status-Checks
- Audit-Logging

### Verwendung

```typescript
import { secureSignIn } from './services/secureLogin'

const result = await secureSignIn(email, password)

if (!result.success) {
  // Immer generische Meldung
  console.error(result.error) // "E-Mail oder Passwort ist falsch."
}
```

## ⚠️ Wichtige Hinweise

### IP-Adresse

**HINWEIS:** Die IP-Adresse wird aktuell Client-seitig als Placeholder gesetzt (`'client-side'`).

**Für Production:**
- IP sollte Server-seitig in einer Supabase Edge Function geholt werden
- Oder über eine API Route (Next.js, Express, etc.)
- Client-seitig kann IP nicht zuverlässig geholt werden

### Rate-Limiting

- **IP-basiert**: 20 Versuche pro Stunde
- **Identifier-basiert**: 10 Versuche pro Stunde
- **Block-Dauer**: 15 Minuten

### Timing-Schutz

- Fake Password Verify: 150ms Delay
- Wird ausgeführt wenn User nicht existiert
- Verhindert User Enumeration via Timing

## 📝 Nächste Schritte

1. **Supabase Edge Function** für IP-Handling erstellen
2. **SQL-Script ausführen**: `scripts/login-security-enhancements.sql`
3. **Testen**: Alle Security-Fälle durchgehen
4. **Monitoring**: Login-Attempts analysieren
5. **Cleanup-Jobs**: Regelmäßig ausführen

## 🔗 Referenzen

- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [User Enumeration Prevention](https://cheatsheetseries.owasp.org/cheatsheets/User_Enumeration_Cheat_Sheet.html)

