# 🧪 Test-Benutzer Setup-Anleitung

## Übersicht

Dieses Dokument erklärt, wie du Test-Benutzer für das Grading-Portal einrichtest.

## 📋 Benutzer

1. **a.antipin@lamacards.de** - Hauptbenutzer mit Test-Karten
2. **it@lamacards.de** - Test-Benutzer
3. **admin@admin.de** - Admin-Benutzer (bereits hardcoded)

## 🔐 Passwörter

- **a.antipin@lamacards.de**: `Test123!`
- **it@lamacards.de**: `Test123!`
- **admin@admin.de**: `admin` (hardcoded, kein Supabase Auth nötig)

---

## 📝 Schritt-für-Schritt Anleitung

### SCHRITT 1: Supabase Auth Benutzer erstellen

Die Benutzer müssen in **Supabase Authentication** erstellt werden, da die App Supabase Auth für Login verwendet.

#### Option A: Über Supabase Dashboard (Empfohlen)

1. Gehe zu: **https://supabase.com/dashboard/project/kbthvenvqxnxplgixgdq**
2. Klicke auf **"Authentication"** im linken Menü
3. Klicke auf **"Users"** → **"Add user"** (oder **"Create new user"**)
4. Erstelle die folgenden Benutzer:

**Benutzer 1:**
- **Email**: `a.antipin@lamacards.de`
- **Password**: `Test123!`
- **Auto Confirm User**: ✅ (aktivieren)
- **Send invitation email**: ❌ (deaktivieren)

**Benutzer 2:**
- **Email**: `it@lamacards.de`
- **Password**: `Test123!`
- **Auto Confirm User**: ✅ (aktivieren)
- **Send invitation email**: ❌ (deaktivieren)

#### Option B: Über SQL (mit Service Role Key)

Falls du die Benutzer direkt über SQL erstellen möchtest, kannst du die Supabase Management API verwenden oder die `auth.users` Tabelle direkt bearbeiten (nur mit Service Role Key).

**⚠️ WICHTIG:** Die Benutzer müssen in Supabase Auth erstellt werden, bevor sie sich einloggen können!

---

### SCHRITT 2: Datenbank-Test-Daten erstellen

1. Gehe zu: **https://supabase.com/dashboard/project/kbthvenvqxnxplgixgdq**
2. Klicke auf **"SQL Editor"** im linken Menü
3. Klicke auf **"New query"**
4. Öffne die Datei `test-data-setup.sql` in deinem Projekt
5. Kopiere den gesamten Inhalt
6. Füge ihn in den SQL Editor ein
7. Klicke auf **"Run"** (oder `Cmd+Enter`)

✅ Das Script erstellt:
- Kunden in der `customers` Tabelle
- Test-Aufträge mit verschiedenen Status
- Test-Karten
- Grading-Ergebnisse (für abgeschlossene Aufträge)

---

### SCHRITT 3: Admin-Benutzer

Der Admin-Benutzer ist bereits hardcoded und benötigt **KEIN** Supabase Auth Konto:

- **Email**: `admin@admin.de`
- **Password**: `admin`

Dieser Benutzer funktioniert direkt ohne Datenbank-Setup.

---

## 📊 Was wird erstellt?

### Für a.antipin@lamacards.de:

1. **ORD-2024-001** - In Bearbeitung
   - 3 Karten (Pikachu VMAX, Charizard, Blastoise)
   - Status: `in_grading`
   - Versendet und angekommen bei PSA

2. **ORD-2024-002** - Abgeschlossen
   - 3 Karten (LeBron, Jordan, Kobe Rookie Cards)
   - Status: `completed`
   - Mit Grading-Ergebnissen (PSA 10, PSA 9, PSA 9)

3. **ORD-2024-003** - Ausstehend
   - 5 Karten (Comics: Spider-Man, Batman, Superman, X-Men, Avengers)
   - Status: `submitted`
   - Wartet auf Versand

### Für it@lamacards.de:

1. **ORD-2024-004** - Angekommen bei CGC
   - 3 Karten (Iron Man, Hulk, Thor Comics)
   - Status: `arrived_at_grading`
   - Bei CGC angekommen

---

## ✅ Testen

### Login testen:

1. Öffne deine App (lokal oder auf Vercel)
2. Versuche dich einzuloggen mit:
   - `a.antipin@lamacards.de` / `Test123!`
   - `it@lamacards.de` / `Test123!`
   - `admin@admin.de` / `admin`

### Dashboard prüfen:

- Nach dem Login solltest du die Aufträge sehen
- Klicke auf "Details" um einzelne Aufträge zu sehen
- Prüfe verschiedene Status (in Bearbeitung, abgeschlossen, ausstehend)

---

## 🔧 Troubleshooting

### Problem: "Invalid login credentials"

**Lösung:**
- Stelle sicher, dass der Benutzer in Supabase Auth erstellt wurde
- Prüfe, ob "Auto Confirm User" aktiviert war
- Prüfe, ob die E-Mail-Adresse exakt übereinstimmt

### Problem: "Keine Aufträge gefunden"

**Lösung:**
- Prüfe, ob `test-data-setup.sql` erfolgreich ausgeführt wurde
- Prüfe, ob die E-Mail in der `customers` Tabelle mit der Auth-E-Mail übereinstimmt
- Prüfe Browser-Konsole auf Fehler

### Problem: Admin-Login funktioniert nicht

**Lösung:**
- Admin-Login ist hardcoded: `admin@admin.de` / `admin`
- Kein Supabase Auth nötig
- Prüfe `src/contexts/AuthContext.tsx` falls geändert

---

## 📝 SQL-Abfragen zum Prüfen

```sql
-- Alle Kunden anzeigen
SELECT * FROM customers;

-- Alle Aufträge anzeigen
SELECT o.*, c.email, c.first_name, c.last_name 
FROM grading_orders o
JOIN customers c ON o.customer_id = c.id;

-- Alle Karten anzeigen
SELECT card.*, o.order_number, c.email
FROM cards card
JOIN grading_orders o ON card.order_id = o.id
JOIN customers c ON o.customer_id = c.id;

-- Grading-Ergebnisse anzeigen
SELECT gr.*, card.card_description, o.order_number
FROM grading_results gr
JOIN cards card ON gr.card_id = card.id
JOIN grading_orders o ON gr.order_id = o.id;
```

---

## 🎉 Fertig!

Nach diesen Schritten solltest du:
- ✅ 2 Test-Benutzer in Supabase Auth haben
- ✅ Test-Daten in der Datenbank haben
- ✅ Dich mit allen Benutzern einloggen können
- ✅ Aufträge und Karten im Dashboard sehen können

