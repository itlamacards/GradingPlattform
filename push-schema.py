#!/usr/bin/env python3
"""
Script zum Pushen des Datenbank-Schemas zu Supabase
"""

import requests
import sys

# Supabase Credentials
SUPABASE_URL = "https://ebfvbqppnpxfcijzkita.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImViZnZicXBwbnB4ZmNpanpraXRhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDEyNDAzNywiZXhwIjoyMDc5NzAwMDM3fQ.62bt1bEfZ5Aiihc4V6B_kzo3WaIOQf2IUyDdA45uBj8"

def push_schema():
    """Liest das SQL-Schema und pusht es zu Supabase"""
    
    # SQL-Datei lesen
    try:
        with open('database-schema-final.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
    except FileNotFoundError:
        print("❌ Fehler: database-schema-final.sql nicht gefunden!")
        sys.exit(1)
    
    # Supabase REST API Endpoint für SQL-Ausführung
    # Hinweis: Supabase hat keinen direkten REST-Endpoint für SQL
    # Wir müssen die Management API verwenden oder das SQL direkt im Dashboard ausführen
    
    print("⚠️  Supabase REST API unterstützt keine direkte SQL-Ausführung.")
    print("📝 Bitte führe das Schema manuell im Supabase Dashboard aus:")
    print("\n1. Gehe zu: https://supabase.com/dashboard/project/ebfvbqppnpxfcijzkita")
    print("2. Klicke auf 'SQL Editor' im linken Menü")
    print("3. Kopiere den Inhalt von 'database-schema-final.sql'")
    print("4. Füge ihn in den SQL Editor ein")
    print("5. Klicke auf 'Run'")
    print("\n📄 Oder verwende die Supabase CLI:")
    print("   supabase db push --db-url 'postgresql://postgres:[PASSWORD]@db.ebfvbqppnpxfcijzkita.supabase.co:5432/postgres' < database-schema-final.sql")
    
    # Alternative: Versuche über PostgREST (funktioniert nicht für DDL)
    # Die beste Lösung ist tatsächlich das Supabase Dashboard oder psql
    
    return False

if __name__ == "__main__":
    push_schema()


