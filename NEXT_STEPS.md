# Nächste Schritte - Schritt für Schritt Anleitung

## 🎯 Übersicht

Um das Grading-Portal vollständig zum Laufen zu bringen, folge diesen Schritten in der angegebenen Reihenfolge.

---

## ✅ Schritt 1: Datenbank-Schema in Supabase ausführen

### Was zu tun ist:
1. **Öffne Supabase Dashboard:**
   - Gehe zu: https://supabase.com/dashboard/project/ebfvbqppnpxfcijzkita
   - Oder: https://ebfvbqppnpxfcijzkita.supabase.co

2. **Öffne SQL Editor:**
   - Klicke auf "SQL Editor" im linken Menü
   - Oder gehe direkt zu: https://supabase.com/dashboard/project/ebfvbqppnpxfcijzkita/sql/new

3. **Führe das Schema aus:**
   - Öffne die Datei `database-schema-process.sql` in diesem Projekt
   - Kopiere den **gesamten Inhalt** (Strg+A / Cmd+A, dann Strg+C / Cmd+C)
   - Füge ihn in den SQL Editor ein
   - Klicke auf **"Run"** oder drücke `Cmd+Enter` (Mac) / `Ctrl+Enter` (Windows)

4. **Überprüfe:**
   - Gehe zu "Table Editor" im linken Menü
   - Du solltest folgende Tabellen sehen:
     - ✅ customers
     - ✅ grading_services
     - ✅ grading_orders
     - ✅ cards
     - ✅ charges
     - ✅ charge_cards
     - ✅ grading_results
     - ✅ invoices
     - ✅ order_status_history

---

## ✅ Schritt 2: Supabase Auth konfigurieren

### Was zu tun ist:
1. **Gehe zu Authentication Settings:**
   - Im Supabase Dashboard: "Authentication" → "Settings"

2. **Aktiviere Email Provider:**
   - Stelle sicher, dass "Email" aktiviert ist
   - "Enable email confirmations" kann für Entwicklung deaktiviert werden

3. **E-Mail-Templates (optional):**
   - Konfiguriere E-Mail-Templates für bessere UX
   - Für Entwicklung können Standard-Templates verwendet werden

---

## ✅ Schritt 3: Test-Daten erstellen

### Was zu tun ist:

1. **Öffne SQL Editor erneut**

2. **Füge Test-Kunden ein:**

```sql
-- Test-Kunde 1
INSERT INTO customers (customer_number, first_name, last_name, email, phone)
VALUES ('K-2024-0001', 'Max', 'Mustermann', 'max@example.com', '+49 123 456789');

-- Test-Kunde 2
INSERT INTO customers (customer_number, first_name, last_name, email, phone)
VALUES ('K-2024-0002', 'Anna', 'Schmidt', 'anna@example.com', '+49 987 654321');
```

3. **Erstelle Supabase Auth Benutzer für Test-Kunden:**

```sql
-- Wichtig: Diese müssen über Supabase Auth erstellt werden!
-- Gehe zu: Authentication → Users → "Add user"
-- Oder verwende die Supabase Auth API
```

**Oder über das Dashboard:**
- Gehe zu "Authentication" → "Users"
- Klicke auf "Add user"
- E-Mail: `max@example.com`
- Passwort: `test123456`
- Bestätige E-Mail: ✅ (für Entwicklung)

4. **Füge Test-Aufträge ein:**

```sql
-- Test-Auftrag für Max Mustermann
INSERT INTO grading_orders (
  customer_id, 
  order_number, 
  submission_date, 
  cards_description,
  grading_service_id,
  grading_provider,
  amount_paid,
  payment_status,
  status
)
SELECT 
  c.id,
  'ORD-2024-001',
  NOW() - INTERVAL '10 days',
  'Pikachu VMAX, Charizard Base Set, Blastoise Base Set',
  gs.id,
  'PSA',
  75.00,
  'paid',
  'in_grading'
FROM customers c, grading_services gs
WHERE c.email = 'max@example.com'
AND gs.service_name = 'PSA Grading Service'
LIMIT 1;

-- Test-Karten für diesen Auftrag
INSERT INTO cards (order_id, card_description, card_type, status)
SELECT 
  go.id,
  card_name,
  'Pokemon Card',
  CASE 
    WHEN card_name LIKE '%Pikachu%' THEN 'in_grading'
    WHEN card_name LIKE '%Charizard%' THEN 'in_grading'
    ELSE 'stored'
  END
FROM grading_orders go
CROSS JOIN (VALUES 
  ('Pikachu VMAX'),
  ('Charizard Base Set'),
  ('Blastoise Base Set')
) AS cards(card_name)
WHERE go.order_number = 'ORD-2024-001';
```

---

## ✅ Schritt 4: App starten und testen

### Was zu tun ist:

1. **App starten:**
   ```bash
   npm run dev
   ```

2. **Im Browser öffnen:**
   - Gehe zu: http://localhost:5173

3. **Test-Login:**
   - **Admin:** `admin@admin.de` / `admin`
   - **Kunde:** `max@example.com` / `test123456` (oder das Passwort, das du erstellt hast)

4. **Überprüfe:**
   - ✅ Login funktioniert
   - ✅ Dashboard zeigt Aufträge (wenn Test-Daten vorhanden)
   - ✅ Details-Button öffnet Modal
   - ✅ Keine Fehler in der Browser-Konsole

---

## ✅ Schritt 5: OrderDetails mit echten Daten verbinden

### Was zu tun ist:

Die `OrderDetails` Komponente muss noch angepasst werden, um echte Daten zu laden:

1. **Öffne:** `src/components/OrderDetails.tsx`

2. **Lade Karten-Daten:**
   - Verwende `cardService.getCardsByOrder(orderId)`
   - Zeige echte Karten statt Demo-Daten

3. **Lade Grading-Ergebnisse:**
   - Verwende `gradingService.getResultsByOrder(orderId)`
   - Zeige echte Grades

---

## ✅ Schritt 6: Weitere Verbesserungen

### Optionale nächste Schritte:

1. **Karten-Anzahl pro Auftrag:**
   - Lade tatsächliche Anzahl der Karten
   - Zeige sie im Dashboard

2. **Progress-Balken:**
   - Berechne Fortschritt basierend auf echten Status
   - Verwende Status aus der Datenbank

3. **Admin-Bereich:**
   - Verbinde AdminResults mit echten Daten
   - Zeige alle Aufträge aller Kunden

4. **Error-Handling:**
   - Verbessere Fehlermeldungen
   - Zeige hilfreiche Nachrichten

5. **Loading-States:**
   - Verbessere Lade-Animationen
   - Zeige Skeleton-Screens

---

## 🐛 Troubleshooting

### Problem: "Keine Aufträge gefunden"
**Lösung:**
- Prüfe, ob Schema ausgeführt wurde
- Prüfe, ob Test-Daten erstellt wurden
- Prüfe Browser-Konsole auf Fehler
- Prüfe, ob Kunde in `customers` Tabelle existiert

### Problem: "Authentication failed"
**Lösung:**
- Prüfe Supabase Auth Settings
- Stelle sicher, dass User in Supabase Auth existiert
- Prüfe, ob E-Mail bestätigt wurde (für Entwicklung deaktivieren)

### Problem: "RLS Policy violation"
**Lösung:**
- Prüfe, ob User eingeloggt ist
- Prüfe RLS-Policies in Supabase
- Stelle sicher, dass `customer_id` korrekt gesetzt ist

### Problem: "Cannot read property 'id' of undefined"
**Lösung:**
- Prüfe, ob `customerId` im AuthContext gesetzt ist
- Prüfe, ob Kunde in `customers` Tabelle existiert
- Prüfe Browser-Konsole für detaillierte Fehler

---

## 📋 Checkliste

- [ ] Schema in Supabase ausgeführt
- [ ] Alle Tabellen erstellt (8 Tabellen)
- [ ] Supabase Auth konfiguriert
- [ ] Test-Kunden erstellt
- [ ] Test-Aufträge erstellt
- [ ] Test-Karten erstellt
- [ ] App gestartet (`npm run dev`)
- [ ] Login getestet
- [ ] Dashboard zeigt Daten
- [ ] Details funktionieren

---

## 🎉 Fertig!

Wenn alle Schritte abgeschlossen sind, sollte dein Grading-Portal vollständig funktionieren!

Bei Fragen oder Problemen, schaue in die Browser-Konsole oder in die Supabase Logs.

