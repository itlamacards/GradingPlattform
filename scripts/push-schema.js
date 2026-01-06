/**
 * Script zum Pushen des Datenbank-Schemas zu Supabase
 * Verwendet die Supabase Management API
 */

const fs = require('fs');
const https = require('https');

const SUPABASE_URL = 'https://ebfvbqppnpxfcijzkita.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImViZnZicXBwbnB4ZmNpanpraXRhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDEyNDAzNywiZXhwIjoyMDc5NzAwMDM3fQ.62bt1bEfZ5Aiihc4V6B_kzo3WaIOQf2IUyDdA45uBj8';

async function pushSchema() {
  try {
    // SQL-Datei lesen
    const sqlContent = fs.readFileSync('database-schema-final.sql', 'utf8');
    
    console.log('📤 Versuche Schema zu Supabase zu pushen...');
    console.log('⚠️  Hinweis: Supabase REST API unterstützt keine direkte SQL-Ausführung für DDL-Statements.');
    console.log('\n📝 Bitte führe das Schema manuell im Supabase Dashboard aus:');
    console.log('\n1. Gehe zu: https://supabase.com/dashboard/project/ebfvbqppnpxfcijzkita');
    console.log('2. Klicke auf "SQL Editor" im linken Menü');
    console.log('3. Kopiere den Inhalt von "database-schema-final.sql"');
    console.log('4. Füge ihn in den SQL Editor ein');
    console.log('5. Klicke auf "Run"');
    console.log('\n📄 Die SQL-Datei wurde bereits erstellt: database-schema-final.sql');
    
    // Versuche über PostgREST (funktioniert nicht für DDL)
    // Die beste Lösung ist das Supabase Dashboard
    
  } catch (error) {
    console.error('❌ Fehler:', error.message);
    process.exit(1);
  }
}

pushSchema();


