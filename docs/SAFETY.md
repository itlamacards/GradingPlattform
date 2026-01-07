# 🔐 Sicherheits-Dokumentation

## ⚠️ Vercel-Warnung: VITE_SUPABASE_ANON_KEY

Vercel warnt, dass `VITE_SUPABASE_ANON_KEY` im Browser sichtbar ist, da alle `VITE_*` Variablen von Vite in den Client-Bundle eingebunden werden.

**WICHTIG:** Diese Warnung ist berechtigt, ABER die Supabase Anon Key ist **absichtlich** dafür designed, öffentlich zu sein.

---

## ✅ Warum die Anon Key sicher ist

### 1. Supabase Design-Prinzip

Die **Anon Key** ist explizit dafür gemacht, im Browser zu sein:
- Sie hat **nur die Rechte**, die durch Row Level Security (RLS) definiert sind
- Sie kann **KEINE Admin-Operationen** durchführen
- Sie kann **NICHT** auf Daten zugreifen, die nicht durch RLS erlaubt sind
- Sie ist **NICHT** die Service Role Key (die ist geheim!)

### 2. Row Level Security (RLS) als Schutz

**RLS ist der eigentliche Schutzmechanismus**, nicht die Geheimhaltung der Anon Key.

In unserem Schema ist RLS auf allen Tabellen aktiviert:
- ✅ `customers` - RLS aktiv
- ✅ `grading_orders` - RLS aktiv
- ✅ `grading_batches` - RLS aktiv
- ✅ `grading_numbers` - RLS aktiv
- ✅ `grading_results` - RLS aktiv
- ✅ `invoices` - RLS aktiv
- ✅ `order_status_history` - RLS aktiv

### 3. RLS Policies

Unsere Policies stellen sicher, dass:
- Kunden können **nur ihre eigenen Daten** sehen
- Kunden können **nur ihre eigenen Aufträge** sehen
- Kunden können **nur ihre eigenen Batches** sehen
- Kunden können **nur ihre eigenen Grading-Nummern** sehen
- Kunden können **nur ihre eigenen Ergebnisse** sehen
- Kunden können **nur ihre eigenen Rechnungen** sehen

**Beispiel-Policy:**
```sql
CREATE POLICY "Kunden können nur ihre eigenen Daten sehen"
    ON customers FOR SELECT
    USING (auth.uid()::text = id::text);
```

Das bedeutet: Ein User kann nur Daten sehen, wenn `auth.uid()` (seine User-ID) mit der `id` in der Tabelle übereinstimmt.

---

## 🚨 Was wirklich wichtig ist

### ✅ DO's (Richtig machen)

1. **RLS auf ALLEN Tabellen aktivieren**
   ```sql
   ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
   ```

2. **RLS Policies für jede Tabelle erstellen**
   - Jede Tabelle sollte Policies haben
   - Policies sollten nur eigenen Daten erlauben
   - Testen: Kann ein User auf fremde Daten zugreifen?

3. **Service Role Key NUR Server-Side verwenden**
   - Service Role Key ist geheim!
   - NIE im Client-Code verwenden
   - NIE in `VITE_*` Environment-Variablen
   - Nur in Edge Functions, API Routes, oder Backend-Services

4. **Anon Key im Client verwenden** ✅
   - Das ist OK und so designed
   - Solange RLS aktiv ist

### ❌ DON'Ts (Nicht machen)

1. **Service Role Key im Client** ❌
   - NIEMALS im Browser!
   - NIEMALS in `VITE_*` Variablen!

2. **Sensible Daten ohne RLS-Schutz** ❌
   - Alle Tabellen müssen RLS haben
   - Alle Policies müssen richtig konfiguriert sein

3. **Admin-Operationen mit Anon Key** ❌
   - Anon Key kann keine Admin-Operationen durchführen
   - Verwende Service Role Key (Server-Side)

---

## 🔍 Sicherheits-Checkliste

### 1. RLS aktivieren (wichtigste Maßnahme)

Prüfe, ob RLS auf allen Tabellen aktiviert ist:

```sql
-- Prüfe RLS-Status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Erwartetes Ergebnis:** Alle Tabellen sollten `rls_enabled = true` haben.

### 2. RLS Policies prüfen

Prüfe, ob alle Tabellen Policies haben:

```sql
-- Zeige alle Policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Erwartetes Ergebnis:** Jede Tabelle sollte mindestens eine SELECT-Policy haben.

### 3. RLS Policies testen

Teste, ob ein User auf fremde Daten zugreifen kann:

```sql
-- Test: Kann User A auf Daten von User B zugreifen?
-- (Führe als User A aus, versuche Daten von User B zu lesen)
SELECT * FROM customers WHERE email = 'fremde-email@example.com';
```

**Erwartetes Ergebnis:** Sollte keine Daten zurückgeben (oder Fehler, wenn RLS richtig konfiguriert ist).

### 4. Service Role Key schützen

- ✅ Service Role Key NUR in Server-Side Code
- ✅ NIE in Client-Code oder `VITE_*` Variablen
- ✅ Falls nötig: Edge Functions verwenden für Admin-Operationen

---

## 🛡️ Best Practices

### 1. Anon Key im Client ✅

**Das ist OK:**
```typescript
// src/lib/supabase.ts
export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,      // ✅ OK
  import.meta.env.VITE_SUPABASE_ANON_KEY // ✅ OK - öffentlich by design
)
```

### 2. Service Role Key Server-Side ✅

**Das ist OK:**
```typescript
// Server-Side (Edge Function, API Route, etc.)
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,           // ✅ OK
  process.env.SUPABASE_SERVICE_KEY    // ✅ OK - Server-Side
)
```

**Das ist NICHT OK:**
```typescript
// Client-Side
const supabaseAdmin = createClient(
  import.meta.env.VITE_SUPABASE_URL,           // ❌ FALSCH
  import.meta.env.VITE_SUPABASE_SERVICE_KEY    // ❌ FALSCH - NIEMALS!
)
```

### 3. RLS für alle Tabellen

**Jede Tabelle sollte RLS haben:**
```sql
-- Aktivieren
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- Policy erstellen
CREATE POLICY "policy_name"
    ON table_name FOR SELECT
    USING (auth.uid()::text = user_id::text);
```

---

## 📋 Zusammenfassung

### Die Anon Key ist sicher, wenn:

1. ✅ RLS auf allen Tabellen aktiviert ist
2. ✅ RLS Policies richtig konfiguriert sind
3. ✅ Service Role Key NIE im Client verwendet wird
4. ✅ Alle Policies getestet wurden

### Die Anon Key ist NICHT sicher, wenn:

1. ❌ RLS nicht aktiviert ist
2. ❌ Keine oder falsche Policies vorhanden sind
3. ❌ Service Role Key im Client verwendet wird
4. ❌ Sensible Daten ohne RLS-Schutz

---

## 🔗 Weitere Ressourcen

- [Supabase RLS Dokumentation](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/security)
- [Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)

---

## ✅ Unser aktueller Status

### RLS Status:
- ✅ RLS auf allen Tabellen aktiviert
- ✅ Policies für alle Tabellen erstellt
- ✅ Policies testen User-ID basierte Zugriffe

### Environment Variables:
- ✅ `VITE_SUPABASE_URL` - Öffentlich (OK)
- ✅ `VITE_SUPABASE_ANON_KEY` - Öffentlich (OK, wenn RLS aktiv)
- ✅ Service Role Key - NICHT im Client (Korrekt)

### Empfehlung:
Die aktuelle Konfiguration ist **sicher**, da:
1. RLS auf allen Tabellen aktiviert ist
2. Policies richtig konfiguriert sind
3. Service Role Key nicht im Client verwendet wird

Die Vercel-Warnung kann ignoriert werden, solange RLS aktiv ist.

