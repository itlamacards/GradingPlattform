# 🔐 Supabase Auth Konfiguration für Vercel

## Problem: Einladungs-URL zeigt auf localhost

Wenn Supabase Einladungs-E-Mails mit `localhost:3000` sendet, muss die **Site URL** in Supabase angepasst werden.

## ✅ Lösung: Site URL in Supabase anpassen

### Schritt 1: Supabase Dashboard öffnen

1. Gehe zu: **https://supabase.com/dashboard/project/kbthvenvqxnxplgixgdq**
2. Klicke auf **"Authentication"** im linken Menü
3. Klicke auf **"URL Configuration"** (oder **"Settings"** → **"Auth"**)

### Schritt 2: Site URL anpassen

**Site URL:**
```
https://grading-plattform-lama.vercel.app
```

### Schritt 3: Redirect URLs hinzufügen

Füge folgende URLs zu **"Redirect URLs"** hinzu:

```
https://grading-plattform-lama.vercel.app/**
https://grading-plattform-lama.vercel.app
http://localhost:5173/**
http://localhost:5173
```

**Wichtig:** 
- Die `**` am Ende bedeutet "alle Pfade unter dieser URL"
- Füge sowohl die Vercel-URL als auch localhost hinzu (für lokale Entwicklung)

### Schritt 4: Speichern

Klicke auf **"Save"** oder **"Update"**

---

## 🔄 Alternative: Benutzer ohne E-Mail-Einladung erstellen

Wenn du die E-Mail-Einladung nicht brauchst, kannst du Benutzer direkt erstellen:

### Option 1: Über Supabase Dashboard

1. Gehe zu: **Authentication** → **Users**
2. Klicke auf **"Add user"** oder **"Create new user"**
3. Fülle aus:
   - **Email**: `a.antipin@lamacards.de`
   - **Password**: `Test123!`
   - **Auto Confirm User**: ✅ **WICHTIG: Aktivieren!**
   - **Send invitation email**: ❌ **Deaktivieren**
4. Klicke auf **"Create user"**

### Option 2: Über SQL (Service Role Key)

```sql
-- Benutzer direkt in auth.users erstellen (nur mit Service Role Key möglich)
-- WICHTIG: Passwort muss gehasht werden!

-- Verwende stattdessen die Supabase Management API oder das Dashboard
```

**Empfehlung:** Verwende Option 1 (Dashboard), da es einfacher ist.

---

## 📧 E-Mail-Templates anpassen (Optional)

Falls du E-Mail-Einladungen verwenden möchtest:

1. Gehe zu: **Authentication** → **Email Templates**
2. Wähle **"Invite user"**
3. Passe die URL im Template an:
   - Ersetze `{{ .SiteURL }}` oder `localhost:3000` mit `https://grading-plattform-lama.vercel.app`

---

## ✅ Testen

Nach der Konfiguration:

1. Erstelle einen neuen Benutzer im Dashboard
2. Prüfe, ob die E-Mail die richtige URL enthält
3. Oder verwende "Auto Confirm User" und logge dich direkt ein

---

## 🔧 Troubleshooting

### Problem: "Invalid redirect URL"

**Lösung:**
- Stelle sicher, dass die Vercel-URL in "Redirect URLs" hinzugefügt wurde
- Verwende `**` am Ende für alle Pfade

### Problem: E-Mail kommt immer noch mit localhost

**Lösung:**
- Prüfe "Site URL" in Auth Settings
- Prüfe E-Mail-Templates
- Oder verwende "Auto Confirm User" und überspringe E-Mail-Einladung

### Problem: Login funktioniert nicht nach Redirect

**Lösung:**
- Stelle sicher, dass beide URLs (Vercel + localhost) in Redirect URLs sind
- Prüfe, ob die App die richtige Supabase-URL verwendet

---

## 📝 Zusammenfassung

**Wichtigste Einstellungen:**

1. **Site URL:** `https://grading-plattform-lama.vercel.app`
2. **Redirect URLs:** 
   - `https://grading-plattform-lama.vercel.app/**`
   - `http://localhost:5173/**`
3. **Auto Confirm User:** ✅ Aktivieren (für Test-Benutzer)

