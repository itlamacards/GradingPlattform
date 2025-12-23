# Deployment-Anleitung

## 🚀 Vercel Deployment

### Framework-Preset bei Vercel
**Wähle: `Vite`** oder **`Other`** (Vercel erkennt Vite automatisch)

### Schritte:

1. **GitHub Repository erstellen** (falls noch nicht vorhanden)
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin git@github.com:DEIN-USERNAME/DEIN-REPO.git
   git push -u origin main
   ```

2. **Vercel Account erstellen**
   - Gehe zu https://vercel.com
   - Melde dich mit GitHub an

3. **Projekt zu Vercel hinzufügen**
   - Klicke auf "New Project"
   - Wähle dein GitHub Repository
   - Vercel erkennt automatisch Vite

4. **Umgebungsvariablen in Vercel setzen**
   - Gehe zu Project Settings → Environment Variables
   - Füge folgende Variablen hinzu:
     - `VITE_SUPABASE_URL` = `https://kbthvenvqxnxplgixgdq.supabase.co`
     - `VITE_SUPABASE_ANON_KEY` = `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtidGh2ZW52cXhueHBsZ2l4Z2RxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0MDIyNTgsImV4cCI6MjA4MTk3ODI1OH0.Zddtg6AdcryDFQ_OHeDSyvAKiuZemvX7Ty9qLg9e3qs`
   - Wähle für beide: Production, Preview, Development

5. **Deploy**
   - Klicke auf "Deploy"
   - Vercel baut und deployed automatisch

### Build-Einstellungen (automatisch erkannt):
- **Framework Preset:** Vite
- **Build Command:** `npm run build`
- **Output Directory:** `dist`
- **Install Command:** `npm install`

## 🔐 GitHub SSH-Key erstellen

### SSH-Key generieren:

```bash
# Generiere einen neuen SSH-Key
ssh-keygen -t ed25519 -C "deine-email@example.com"

# Drücke Enter für den Standard-Speicherort (~/.ssh/id_ed25519)
# Wähle ein sicheres Passwort (optional, aber empfohlen)
```

### SSH-Key zu GitHub hinzufügen:

1. **Public Key kopieren:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   Kopiere den gesamten Output (beginnt mit `ssh-ed25519 ...`)

2. **Auf GitHub einfügen:**
   - Gehe zu: https://github.com/settings/keys
   - Klicke auf "New SSH key"
   - Titel: z.B. "MacBook Pro" oder "Development Machine"
   - Key: Füge den kopierten Public Key ein
   - Klicke auf "Add SSH key"

3. **Testen:**
   ```bash
   ssh -T git@github.com
   ```
   Du solltest sehen: `Hi USERNAME! You've successfully authenticated...`

### SSH-Key verwenden:
```bash
# Repository mit SSH klonen
git clone git@github.com:USERNAME/REPO.git

# Oder Remote-URL ändern
git remote set-url origin git@github.com:USERNAME/REPO.git
```

## 📝 Wichtige Hinweise

- **Service Role Key** NIE im Frontend verwenden! Nur für Backend/Server-Side
- **Anon Key** ist sicher für Frontend (Row Level Security schützt die Daten)
- `.env.local` wird nicht zu Git hinzugefügt (siehe .gitignore)
- Nach jedem Push zu GitHub deployed Vercel automatisch neu

## 🔧 Troubleshooting

### Build schlägt fehl
- Prüfe, ob alle Umgebungsvariablen in Vercel gesetzt sind
- Prüfe Build-Logs in Vercel Dashboard

### Supabase-Verbindung funktioniert nicht
- Prüfe, ob RLS (Row Level Security) in Supabase aktiviert ist
- Prüfe Browser-Konsole auf Fehler
- Prüfe, ob die Keys korrekt sind

