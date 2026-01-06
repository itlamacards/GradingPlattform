# Supabase Integration - Anleitung

## ✅ Was wurde implementiert:

1. **Supabase Client** - Konfiguriert und bereit
2. **Authentifizierung** - Login mit Supabase Auth + Admin-Login
3. **API Services** - Alle notwendigen Services für Datenbank-Abfragen
4. **Auth Context** - Globaler State-Management für Authentifizierung
5. **Komponenten angepasst** - Dashboard, Login, AdminResults verbunden

## 📋 Nächste Schritte:

### 1. Datenbank-Schema in Supabase ausführen

1. Gehe zu: https://supabase.com/dashboard/project/ebfvbqppnpxfcijzkita
2. Öffne "SQL Editor"
3. Kopiere den Inhalt von `database-schema-process.sql`
4. Führe das SQL aus

### 2. Supabase Auth konfigurieren

1. Gehe zu "Authentication" → "Settings"
2. Stelle sicher, dass "Email" als Provider aktiviert ist
3. Optional: Konfiguriere E-Mail-Templates

### 3. Row Level Security (RLS) testen

Die RLS-Policies sind bereits im Schema definiert. Teste:
- Kunden können nur ihre eigenen Daten sehen
- Admin kann alle Daten sehen (noch zu implementieren)

### 4. Test-Daten erstellen

Erstelle Test-Kunden und Aufträge:

```sql
-- Test-Kunde erstellen
INSERT INTO customers (customer_number, first_name, last_name, email, phone)
VALUES ('K-2024-0001', 'Max', 'Mustermann', 'test@example.com', '+49 123 456789');

-- Test-Auftrag erstellen
INSERT INTO grading_orders (
  customer_id, 
  order_number, 
  submission_date, 
  cards_description,
  grading_service_id,
  grading_provider,
  amount_paid,
  payment_status
)
SELECT 
  c.id,
  'ORD-2024-001',
  NOW(),
  'Pikachu VMAX, Charizard Base Set',
  gs.id,
  'PSA',
  50.00,
  'paid'
FROM customers c, grading_services gs
WHERE c.email = 'test@example.com'
AND gs.service_name = 'PSA Grading Service';
```

## 🔧 Wie es funktioniert:

### Authentifizierung:
- **Admin**: `admin@admin.de` / `admin` (hardcoded)
- **Kunden**: E-Mail/Passwort über Supabase Auth
- Session wird automatisch verwaltet

### Datenfluss:
1. Kunde loggt sich ein → `AuthContext` lädt Kunden-Daten
2. Dashboard lädt Aufträge → `orderService.getOrdersByCustomer()`
3. Karten werden geladen → `cardService.getCardsByOrder()`
4. Grading-Ergebnisse → `gradingService.getResultsByCard()`

### API Services:
- `authService` - Login, Logout, Session
- `customerService` - Kunden-Daten, Statistiken
- `orderService` - Aufträge abrufen
- `cardService` - Karten abrufen
- `chargeService` - Charge-Details
- `gradingService` - Grading-Ergebnisse

## ⚠️ Wichtige Hinweise:

1. **Datenbank-Schema muss zuerst ausgeführt werden** - Ohne Schema funktioniert nichts
2. **RLS ist aktiviert** - Kunden sehen nur ihre Daten
3. **Admin-Login ist hardcoded** - Später durch echte Admin-Tabelle ersetzen
4. **Demo-Daten** - Dashboard zeigt Demo-Daten, wenn keine DB-Verbindung

## 🐛 Troubleshooting:

### "Keine Aufträge gefunden"
- Prüfe, ob Schema ausgeführt wurde
- Prüfe, ob Test-Daten erstellt wurden
- Prüfe Browser-Konsole auf Fehler

### "Authentication failed"
- Prüfe Supabase Auth Settings
- Prüfe, ob Kunde in `customers` Tabelle existiert

### "RLS Policy violation"
- Prüfe, ob User eingeloggt ist
- Prüfe RLS-Policies in Supabase

## 📝 TODO:

- [ ] OrderDetails mit echten Daten verbinden
- [ ] Karten-Anzahl pro Auftrag laden
- [ ] Progress-Balken basierend auf echten Status
- [ ] Admin-Bereich mit echten Daten verbinden
- [ ] Error-Handling verbessern
- [ ] Loading-States verbessern


