# 🚀 Vollständige Deployment-Anleitung

## ✅ Was bereits vorbereitet wurde:

- ✅ Umgebungsvariablen konfiguriert (`.env.local`, `.env.example`)
- ✅ Supabase-Integration auf neue Keys umgestellt
- ✅ Vercel-Konfiguration (`vercel.json`) erstellt
- ✅ `.gitignore` erweitert (schützt sensible Daten)
- ✅ Git Repository initialisiert

---

## 📋 Schritt-für-Schritt Anleitung

### SCHRITT 1: GitHub SSH-Key erstellen

#### 1.1 SSH-Key generieren

Öffne das Terminal und führe aus:

```bash
ssh-keygen -t ed25519 -C "deine-email@example.com"
```

**Wichtig:**
- Drücke **Enter** für den Standard-Speicherort (`~/.ssh/id_ed25519`)
- Wähle ein sicheres Passwort (optional, aber empfohlen)
- Bestätige das Passwort nochmal

#### 1.2 Public Key kopieren

```bash
cat ~/.ssh/id_ed25519.pub
```

**Kopiere den gesamten Output** (beginnt mit `ssh-ed25519 ...`)

#### 1.3 SSH-Key zu GitHub hinzufügen

1. Gehe zu: **https://github.com/settings/keys**
2. Klicke auf **"New SSH key"** (grüner Button oben rechts)
3. **Title:** z.B. "MacBook Pro" oder "Development Machine"
4. **Key:** Füge den kopierten Public Key ein
5. Klicke auf **"Add SSH key"**
6. Bestätige mit deinem GitHub-Passwort

#### 1.4 SSH-Verbindung testen

```bash
ssh -T git@github.com
```

**Erwartete Ausgabe:**
```
Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access.
```

✅ Wenn du diese Meldung siehst, funktioniert alles!

---

### SCHRITT 2: GitHub Repository erstellen

#### 2.1 Neues Repository auf GitHub erstellen

1. Gehe zu: **https://github.com/new**
2. **Repository name:** z.B. `grading-login` oder `lamacards-portal`
3. **Description:** (optional) "Grading Login Portal für Lama Cards"
4. **Visibility:** Wähle **Private** (empfohlen) oder **Public**
5. **WICHTIG:** Lasse alle Checkboxen **UNGEHÄCKT**:
   - ❌ Add a README file
   - ❌ Add .gitignore
   - ❌ Choose a license
6. Klicke auf **"Create repository"**

#### 2.2 Lokales Repository zu GitHub pushen

**Führe diese Befehle im Terminal aus** (im Projektverzeichnis):

```bash
# Stelle sicher, dass du im Projektverzeichnis bist
cd /Users/antonantipin/Desktop/Dev/GradingLogin

# Alle Änderungen hinzufügen
git add .

# Ersten Commit erstellen
git commit -m "Initial commit: Grading Login Portal"

# Branch auf 'main' umbenennen (falls nötig)
git branch -M main

# GitHub Repository als Remote hinzufügen
# ERsetze USERNAME und REPO-NAME mit deinen Werten!
git remote add origin git@github.com:USERNAME/REPO-NAME.git

# Code zu GitHub pushen
git push -u origin main
```

**Beispiel:**
```bash
git remote add origin git@github.com:antonantipin/grading-login.git
```

✅ Wenn der Push erfolgreich war, siehst du deinen Code auf GitHub!

---

### SCHRITT 3: Vercel Account erstellen & Projekt verbinden

#### 3.1 Vercel Account erstellen

1. Gehe zu: **https://vercel.com**
2. Klicke auf **"Sign Up"**
3. Wähle **"Continue with GitHub"**
4. Autorisiere Vercel, auf dein GitHub-Konto zuzugreifen

#### 3.2 Projekt zu Vercel hinzufügen

1. Nach dem Login klicke auf **"Add New..."** → **"Project"**
2. Du siehst eine Liste deiner GitHub-Repositories
3. **Finde dein Repository** (z.B. `grading-login`)
4. Klicke auf **"Import"**

#### 3.3 Framework-Konfiguration

Vercel sollte automatisch **Vite** erkennen. Falls nicht:

- **Framework Preset:** Wähle **"Vite"** aus dem Dropdown
- **Root Directory:** `.` (Standard)
- **Build Command:** `npm run build` (sollte automatisch erkannt werden)
- **Output Directory:** `dist` (sollte automatisch erkannt werden)
- **Install Command:** `npm install` (sollte automatisch erkannt werden)

#### 3.4 Umgebungsvariablen setzen

**WICHTIG:** Mache das **VOR** dem ersten Deploy!

1. In der Vercel-Konfiguration findest du **"Environment Variables"**
2. Klicke darauf
3. Füge folgende Variablen hinzu:

**Variable 1:**
- **Key:** `VITE_SUPABASE_URL`
- **Value:** `https://kbthvenvqxnxplgixgdq.supabase.co`
- **Environment:** ✅ Production, ✅ Preview, ✅ Development

**Variable 2:**
- **Key:** `VITE_SUPABASE_ANON_KEY`
- **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtidGh2ZW52cXhueHBsZ2l4Z2RxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0MDIyNTgsImV4cCI6MjA4MTk3ODI1OH0.Zddtg6AdcryDFQ_OHeDSyvAKiuZemvX7Ty9qLg9e3qs`
- **Environment:** ✅ Production, ✅ Preview, ✅ Development

4. Klicke auf **"Save"**

#### 3.5 Deploy starten

1. Klicke auf **"Deploy"** (unten rechts)
2. Warte, bis der Build fertig ist (ca. 1-2 Minuten)
3. ✅ **Fertig!** Du erhältst eine URL wie: `https://grading-login.vercel.app`

---

### SCHRITT 4: Supabase konfigurieren

#### 4.1 Supabase Dashboard öffnen

1. Gehe zu: **https://supabase.com/dashboard**
2. Wähle dein Projekt: `kbthvenvqxnxplgixgdq`

#### 4.2 Datenbank-Schema ausführen

1. Klicke auf **"SQL Editor"** im linken Menü
2. Klicke auf **"New query"**
3. Öffne die Datei `database-schema-final.sql` in deinem Projekt
4. Kopiere den gesamten Inhalt
5. Füge ihn in den SQL Editor ein
6. Klicke auf **"Run"** (oder `Cmd+Enter`)

✅ Das Schema wird jetzt in deiner Supabase-Datenbank erstellt!

#### 4.3 Row Level Security (RLS) prüfen

1. Gehe zu **"Authentication"** → **"Policies"**
2. Stelle sicher, dass RLS für alle Tabellen aktiviert ist
3. Prüfe die Policies (sollten im Schema definiert sein)

#### 4.4 Test-Daten erstellen (optional)

Falls du Test-Daten brauchst, führe im SQL Editor aus:

```sql
-- Test-Kunde erstellen
INSERT INTO customers (customer_number, first_name, last_name, email, phone)
VALUES ('K-2024-0001', 'Max', 'Mustermann', 'test@example.com', '+49 123 456789');
```

---

## 🎉 Fertig! Was jetzt?

### Deine URLs:

- **Vercel (Production):** `https://dein-projekt.vercel.app`
- **Supabase Dashboard:** `https://supabase.com/dashboard/project/kbthvenvqxnxplgixgdq`
- **GitHub Repository:** `https://github.com/USERNAME/REPO-NAME`

### Automatische Deployments:

✅ **Jeder Push zu GitHub** deployed automatisch auf Vercel!

### Lokale Entwicklung:

```bash
# Server starten
npm run dev

# Build testen
npm run build
npm run preview
```

---

## 🔧 Troubleshooting

### Problem: Build schlägt auf Vercel fehl

**Lösung:**
1. Prüfe die Build-Logs in Vercel
2. Stelle sicher, dass alle Umgebungsvariablen gesetzt sind
3. Prüfe, ob `package.json` korrekt ist

### Problem: Supabase-Verbindung funktioniert nicht

**Lösung:**
1. Prüfe Browser-Konsole auf Fehler
2. Stelle sicher, dass RLS-Policies korrekt sind
3. Prüfe, ob die Keys in Vercel korrekt gesetzt sind

### Problem: SSH-Key funktioniert nicht

**Lösung:**
```bash
# SSH-Agent starten
eval "$(ssh-agent -s)"

# Key zum Agent hinzufügen
ssh-add ~/.ssh/id_ed25519

# Nochmal testen
ssh -T git@github.com
```

### Problem: Git Push schlägt fehl

**Lösung:**
```bash
# Remote-URL prüfen
git remote -v

# Falls falsch, korrigieren:
git remote set-url origin git@github.com:USERNAME/REPO-NAME.git
```

---

## 📝 Checkliste

- [ ] SSH-Key erstellt und zu GitHub hinzugefügt
- [ ] GitHub Repository erstellt
- [ ] Code zu GitHub gepusht
- [ ] Vercel Account erstellt
- [ ] Projekt zu Vercel hinzugefügt
- [ ] Umgebungsvariablen in Vercel gesetzt
- [ ] Erster Deploy erfolgreich
- [ ] Supabase Schema ausgeführt
- [ ] RLS-Policies aktiviert
- [ ] Test-Daten erstellt (optional)
- [ ] Alles funktioniert! 🎉

---

## 🆘 Hilfe benötigt?

- **Vercel Docs:** https://vercel.com/docs
- **Supabase Docs:** https://supabase.com/docs
- **GitHub Docs:** https://docs.github.com

