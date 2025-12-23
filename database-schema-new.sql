-- Supabase Datenbank-Schema für Grading-Kundenportal
-- Neue Version basierend auf spezifischen Anforderungen
-- Diese Datei kann direkt in Supabase SQL Editor ausgeführt werden

-- ============================================
-- TABELLE 1: customers (Kunden)
-- ============================================
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_number TEXT UNIQUE NOT NULL, -- Kundennummer
    first_name TEXT NOT NULL, -- Name Kunde
    last_name TEXT NOT NULL, -- Nachname Kunde
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    password_hash TEXT, -- Wird von Supabase Auth verwaltet (optional für Login)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELLE 2: grading_services (Grading-Services)
-- ============================================
CREATE TABLE IF NOT EXISTS grading_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name TEXT NOT NULL UNIQUE,
    service_provider TEXT NOT NULL CHECK (service_provider IN ('PSA', 'CGC')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Grading Services einfügen
INSERT INTO grading_services (service_name, service_provider) VALUES
    ('PSA Grading Service', 'PSA'),
    ('PSA Express Grading Service', 'PSA'),
    ('PSA Booster Grading Service', 'PSA'),
    ('PSA Signature Grading Service', 'PSA'),
    ('PSA Reholder Service', 'PSA'),
    ('PSA Case Cracking Service', 'PSA'),
    ('CGC Grading Service', 'CGC'),
    ('CGC Grading Service Prio', 'CGC')
ON CONFLICT (service_name) DO NOTHING;

-- ============================================
-- TABELLE 3: grading_orders (Grading-Aufträge)
-- ============================================
CREATE TABLE IF NOT EXISTS grading_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    order_number TEXT UNIQUE NOT NULL, -- Interne Auftragsnummer
    
    -- Abgabe & Karten
    submission_date TIMESTAMP WITH TIME ZONE NOT NULL, -- Abgabe Datum karten kunde
    cards_description TEXT NOT NULL, -- Welche Karte/Karten (freies schreibbares Feld)
    
    -- Grading Service
    grading_service_id UUID NOT NULL REFERENCES grading_services(id),
    grading_provider TEXT NOT NULL CHECK (grading_provider IN ('PSA', 'CGC')), -- Wo er grading gebucht hat
    
    -- Finanzen
    amount_paid DECIMAL(10, 2) NOT NULL DEFAULT 0, -- Wie viel er bezahlt hat
    has_surcharge BOOLEAN NOT NULL DEFAULT FALSE, -- Ob es einen Aufschlag gibt
    surcharge_amount DECIMAL(10, 2) DEFAULT 0, -- Betrag des Aufschlags (falls vorhanden)
    
    -- Status
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN (
        'submitted',           -- Abgegeben
        'sent_to_grading',     -- Versendet an PSA/CGC
        'arrived_at_grading',  -- Angekommen bei PSA/CGC
        'in_grading',         -- In Bearbeitung
        'grading_completed',   -- Grading abgeschlossen
        'sent_back',          -- Versendet zurück
        'arrived_back',       -- Angekommen beim Kunden
        'completed'           -- Vollständig abgeschlossen
    )),
    
    -- Tracking
    tracking_number_outbound TEXT, -- Trackingnummer Hinversand
    tracking_number_return TEXT,   -- Trackingnummer Rückversand
    
    -- Zahlungsstatus
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN (
        'pending',      -- Offen
        'partial',      -- Teilweise bezahlt
        'paid',         -- Bezahlt
        'overdue'        -- Überfällig
    )),
    
    -- Notizen
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELLE 4: grading_numbers (Grading-Nummern)
-- ============================================
-- Separate Tabelle für Grading-Nummern (können mehrere pro Auftrag sein)
CREATE TABLE IF NOT EXISTS grading_numbers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    grading_number TEXT NOT NULL, -- PSA/CGC Grading-Nummer für API-Aufruf
    card_description TEXT, -- Optional: Beschreibung der spezifischen Karte für diese Nummer
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(order_id, grading_number)
);

-- ============================================
-- TABELLE 5: grading_results (PSA-/CGC-Rückmeldungen)
-- ============================================
CREATE TABLE IF NOT EXISTS grading_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    grading_number_id UUID REFERENCES grading_numbers(id) ON DELETE SET NULL,
    
    -- Grading-Ergebnis
    grade TEXT, -- z.B. 'PSA 10', 'CGC 9.8', etc.
    grade_date TIMESTAMP WITH TIME ZONE, -- Wann wurde das Grading abgeschlossen
    
    -- Upcharges
    has_upcharge BOOLEAN DEFAULT FALSE,
    upcharge_amount DECIMAL(10, 2) DEFAULT 0,
    upcharge_reason TEXT, -- Grund für Upcharge
    
    -- Errors
    has_error BOOLEAN DEFAULT FALSE,
    error_description TEXT, -- Fehlerbeschreibung falls vorhanden
    
    -- API Response (falls von API abgerufen)
    api_response JSONB, -- Vollständige API-Antwort für spätere Referenz
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELLE 6: invoices (Rechnungen)
-- ============================================
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    invoice_number TEXT UNIQUE NOT NULL,
    invoice_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    amount DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN (
        'pending',      -- Offen
        'partial',      -- Teilweise bezahlt
        'paid',         -- Bezahlt
        'overdue',      -- Überfällig
        'cancelled'     -- Storniert
    )),
    paid_amount DECIMAL(10, 2) DEFAULT 0,
    due_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELLE 7: order_status_history (Status-Verlauf)
-- ============================================
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    changed_by TEXT DEFAULT 'system', -- 'system', 'admin', oder user_id
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEKES für bessere Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_customers_customer_number ON customers(customer_number);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_grading_orders_customer_id ON grading_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_grading_orders_status ON grading_orders(status);
CREATE INDEX IF NOT EXISTS idx_grading_orders_order_number ON grading_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_grading_orders_grading_provider ON grading_orders(grading_provider);
CREATE INDEX IF NOT EXISTS idx_grading_numbers_order_id ON grading_numbers(order_id);
CREATE INDEX IF NOT EXISTS idx_grading_numbers_grading_number ON grading_numbers(grading_number);
CREATE INDEX IF NOT EXISTS idx_grading_results_order_id ON grading_results(order_id);
CREATE INDEX IF NOT EXISTS idx_grading_results_grading_number_id ON grading_results(grading_number_id);
CREATE INDEX IF NOT EXISTS idx_invoices_order_id ON invoices(order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);

-- ============================================
-- TRIGGER für updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grading_orders_updated_at BEFORE UPDATE ON grading_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grading_numbers_updated_at BEFORE UPDATE ON grading_numbers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grading_results_updated_at BEFORE UPDATE ON grading_results
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TRIGGER für Status-Historie
-- ============================================
CREATE OR REPLACE FUNCTION log_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (order_id, status, changed_by, notes)
        VALUES (NEW.id, NEW.status, 'system', 'Status automatisch geändert');
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER log_grading_order_status_change AFTER UPDATE ON grading_orders
    FOR EACH ROW EXECUTE FUNCTION log_status_change();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_numbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Kunden können nur ihre eigenen Daten sehen
CREATE POLICY "Kunden können nur ihre eigenen Daten sehen"
    ON customers FOR SELECT
    USING (auth.uid()::text = id::text);

CREATE POLICY "Kunden können nur ihre eigenen Aufträge sehen"
    ON grading_orders FOR SELECT
    USING (customer_id::text = auth.uid()::text);

CREATE POLICY "Kunden können nur Grading-Nummern ihrer Aufträge sehen"
    ON grading_numbers FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_orders
            WHERE grading_orders.id = grading_numbers.order_id
            AND grading_orders.customer_id::text = auth.uid()::text
        )
    );

CREATE POLICY "Kunden können nur Ergebnisse ihrer Aufträge sehen"
    ON grading_results FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_orders
            WHERE grading_orders.id = grading_results.order_id
            AND grading_orders.customer_id::text = auth.uid()::text
        )
    );

CREATE POLICY "Kunden können nur Rechnungen ihrer Aufträge sehen"
    ON invoices FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_orders
            WHERE grading_orders.id = invoices.order_id
            AND grading_orders.customer_id::text = auth.uid()::text
        )
    );

CREATE POLICY "Kunden können nur Status-Historie ihrer Aufträge sehen"
    ON order_status_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_orders
            WHERE grading_orders.id = order_status_history.order_id
            AND grading_orders.customer_id::text = auth.uid()::text
        )
    );

-- ============================================
-- HILFSFUNKTIONEN
-- ============================================

-- Funktion: Kundennummer automatisch generieren
CREATE OR REPLACE FUNCTION generate_customer_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    exists_check BOOLEAN;
BEGIN
    LOOP
        new_number := 'K-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        SELECT EXISTS(SELECT 1 FROM customers WHERE customer_number = new_number) INTO exists_check;
        EXIT WHEN NOT exists_check;
    END LOOP;
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Funktion: Auftragsnummer automatisch generieren
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    exists_check BOOLEAN;
BEGIN
    LOOP
        new_number := 'ORD-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        SELECT EXISTS(SELECT 1 FROM grading_orders WHERE order_number = new_number) INTO exists_check;
        EXIT WHEN NOT exists_check;
    END LOOP;
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Funktion: Rechnungsnummer automatisch generieren
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    exists_check BOOLEAN;
BEGIN
    LOOP
        new_number := 'INV-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        SELECT EXISTS(SELECT 1 FROM invoices WHERE invoice_number = new_number) INTO exists_check;
        EXIT WHEN NOT exists_check;
    END LOOP;
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Funktion: Kunden-Statistiken abrufen
CREATE OR REPLACE FUNCTION get_customer_order_stats(customer_uuid UUID)
RETURNS TABLE (
    total_orders BIGINT,
    submitted_orders BIGINT,
    in_grading_orders BIGINT,
    completed_orders BIGINT,
    total_amount_paid DECIMAL,
    pending_payment DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE true) as total_orders,
        COUNT(*) FILTER (WHERE status = 'submitted') as submitted_orders,
        COUNT(*) FILTER (WHERE status IN ('sent_to_grading', 'arrived_at_grading', 'in_grading')) as in_grading_orders,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_orders,
        COALESCE(SUM(amount_paid), 0) as total_amount_paid,
        COALESCE(SUM(CASE WHEN payment_status != 'paid' THEN amount_paid ELSE 0 END), 0) as pending_payment
    FROM grading_orders
    WHERE customer_id = customer_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

