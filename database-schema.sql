-- Supabase Datenbank-Schema für Grading-Kundenportal
-- Finale Version basierend auf spezifischen Anforderungen
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
    
    -- Status (Gesamtstatus des Auftrags)
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN (
        'submitted',           -- Abgegeben
        'sent_to_grading',     -- Versendet an PSA/CGC (mindestens ein Batch)
        'arrived_at_grading',  -- Angekommen bei PSA/CGC (mindestens ein Batch)
        'in_grading',         -- In Bearbeitung (mindestens ein Batch)
        'grading_completed',   -- Grading abgeschlossen (mindestens ein Batch)
        'sent_back',          -- Versendet zurück (mindestens ein Batch)
        'arrived_back',       -- Angekommen beim Kunden (mindestens ein Batch)
        'completed'           -- Vollständig abgeschlossen (alle Batches)
    )),
    
    -- Zahlungsstatus (vereinfacht: nur bezahlt oder offen)
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN (
        'pending',      -- Offen
        'paid'          -- Bezahlt
    )),
    
    -- Notizen
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELLE 4: grading_batches (Batches für Aufteilung)
-- ============================================
-- Ein Auftrag kann in mehrere Batches aufgeteilt werden
-- z.B. 10 Karten -> 5 Karten in Batch 1, 5 Karten in Batch 2
CREATE TABLE IF NOT EXISTS grading_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    batch_number INTEGER NOT NULL, -- Batch-Nummer innerhalb des Auftrags (1, 2, 3, ...)
    cards_description TEXT, -- Welche Karten in diesem Batch (optional, falls spezifiziert)
    
    -- Status dieses Batches
    status TEXT NOT NULL DEFAULT 'prepared' CHECK (status IN (
        'prepared',            -- Vorbereitet
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
    
    -- Datum
    sent_date TIMESTAMP WITH TIME ZONE, -- Wann wurde dieser Batch versendet
    arrived_date TIMESTAMP WITH TIME ZONE, -- Wann ist er angekommen
    completed_date TIMESTAMP WITH TIME ZONE, -- Wann wurde er abgeschlossen
    
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(order_id, batch_number)
);

-- ============================================
-- TABELLE 5: grading_numbers (Grading-Nummern)
-- ============================================
-- Separate Tabelle für Grading-Nummern
-- Jede Nummer gehört zu einem Batch
CREATE TABLE IF NOT EXISTS grading_numbers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES grading_batches(id) ON DELETE CASCADE,
    grading_number TEXT NOT NULL, -- PSA/CGC Grading-Nummer für API-Aufruf
    card_description TEXT, -- Optional: Beschreibung der spezifischen Karte für diese Nummer
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(batch_id, grading_number)
);

-- ============================================
-- TABELLE 6: grading_results (PSA-/CGC-Rückmeldungen)
-- ============================================
CREATE TABLE IF NOT EXISTS grading_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES grading_batches(id) ON DELETE SET NULL,
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
-- TABELLE 7: invoices (Rechnungen)
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
        'paid'          -- Bezahlt
    )),
    paid_amount DECIMAL(10, 2) DEFAULT 0,
    due_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELLE 8: order_status_history (Status-Verlauf)
-- ============================================
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES grading_batches(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_grading_orders_payment_status ON grading_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_grading_batches_order_id ON grading_batches(order_id);
CREATE INDEX IF NOT EXISTS idx_grading_batches_status ON grading_batches(status);
CREATE INDEX IF NOT EXISTS idx_grading_numbers_batch_id ON grading_numbers(batch_id);
CREATE INDEX IF NOT EXISTS idx_grading_numbers_grading_number ON grading_numbers(grading_number);
CREATE INDEX IF NOT EXISTS idx_grading_results_order_id ON grading_results(order_id);
CREATE INDEX IF NOT EXISTS idx_grading_results_batch_id ON grading_results(batch_id);
CREATE INDEX IF NOT EXISTS idx_grading_results_grading_number_id ON grading_results(grading_number_id);
CREATE INDEX IF NOT EXISTS idx_invoices_order_id ON invoices(order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_payment_status ON invoices(payment_status);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_batch_id ON order_status_history(batch_id);

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

CREATE TRIGGER update_grading_batches_updated_at BEFORE UPDATE ON grading_batches
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
CREATE OR REPLACE FUNCTION log_order_status_change()
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
    FOR EACH ROW EXECUTE FUNCTION log_order_status_change();

CREATE OR REPLACE FUNCTION log_batch_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (order_id, batch_id, status, changed_by, notes)
        VALUES ((SELECT order_id FROM grading_batches WHERE id = NEW.id), NEW.id, NEW.status, 'system', 'Batch-Status automatisch geändert');
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER log_grading_batch_status_change AFTER UPDATE ON grading_batches
    FOR EACH ROW EXECUTE FUNCTION log_batch_status_change();

-- ============================================
-- TRIGGER: Automatische Aktualisierung des Auftrags-Status basierend auf Batches
-- ============================================
CREATE OR REPLACE FUNCTION update_order_status_from_batches()
RETURNS TRIGGER AS $$
DECLARE
    order_uuid UUID;
    all_completed BOOLEAN;
    any_sent_back BOOLEAN;
    any_arrived_back BOOLEAN;
    any_grading_completed BOOLEAN;
    any_in_grading BOOLEAN;
    any_arrived_at_grading BOOLEAN;
    any_sent_to_grading BOOLEAN;
BEGIN
    order_uuid := NEW.order_id;
    
    -- Prüfe Status aller Batches
    SELECT 
        BOOL_AND(status = 'completed'),
        BOOL_OR(status = 'sent_back'),
        BOOL_OR(status = 'arrived_back'),
        BOOL_OR(status = 'grading_completed'),
        BOOL_OR(status = 'in_grading'),
        BOOL_OR(status = 'arrived_at_grading'),
        BOOL_OR(status = 'sent_to_grading')
    INTO 
        all_completed,
        any_sent_back,
        any_arrived_back,
        any_grading_completed,
        any_in_grading,
        any_arrived_at_grading,
        any_sent_to_grading
    FROM grading_batches
    WHERE order_id = order_uuid;
    
    -- Aktualisiere Auftrags-Status basierend auf Batch-Status
    IF all_completed THEN
        UPDATE grading_orders SET status = 'completed' WHERE id = order_uuid;
    ELSIF any_arrived_back THEN
        UPDATE grading_orders SET status = 'arrived_back' WHERE id = order_uuid;
    ELSIF any_sent_back THEN
        UPDATE grading_orders SET status = 'sent_back' WHERE id = order_uuid;
    ELSIF any_grading_completed THEN
        UPDATE grading_orders SET status = 'grading_completed' WHERE id = order_uuid;
    ELSIF any_in_grading THEN
        UPDATE grading_orders SET status = 'in_grading' WHERE id = order_uuid;
    ELSIF any_arrived_at_grading THEN
        UPDATE grading_orders SET status = 'arrived_at_grading' WHERE id = order_uuid;
    ELSIF any_sent_to_grading THEN
        UPDATE grading_orders SET status = 'sent_to_grading' WHERE id = order_uuid;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_status_on_batch_change AFTER INSERT OR UPDATE ON grading_batches
    FOR EACH ROW EXECUTE FUNCTION update_order_status_from_batches();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_batches ENABLE ROW LEVEL SECURITY;
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

CREATE POLICY "Kunden können nur Batches ihrer Aufträge sehen"
    ON grading_batches FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_orders
            WHERE grading_orders.id = grading_batches.order_id
            AND grading_orders.customer_id::text = auth.uid()::text
        )
    );

CREATE POLICY "Kunden können nur Grading-Nummern ihrer Aufträge sehen"
    ON grading_numbers FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_batches
            JOIN grading_orders ON grading_orders.id = grading_batches.order_id
            WHERE grading_batches.id = grading_numbers.batch_id
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
        COALESCE(SUM(CASE WHEN payment_status = 'pending' THEN amount_paid ELSE 0 END), 0) as pending_payment
    FROM grading_orders
    WHERE customer_id = customer_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funktion: Batch-Status für einen Auftrag abrufen
CREATE OR REPLACE FUNCTION get_order_batch_status(order_uuid UUID)
RETURNS TABLE (
    batch_number INTEGER,
    status TEXT,
    cards_description TEXT,
    tracking_number_outbound TEXT,
    tracking_number_return TEXT,
    sent_date TIMESTAMP WITH TIME ZONE,
    completed_date TIMESTAMP WITH TIME ZONE,
    grading_numbers_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        gb.batch_number,
        gb.status,
        gb.cards_description,
        gb.tracking_number_outbound,
        gb.tracking_number_return,
        gb.sent_date,
        gb.completed_date,
        COUNT(gn.id) as grading_numbers_count
    FROM grading_batches gb
    LEFT JOIN grading_numbers gn ON gn.batch_id = gb.id
    WHERE gb.order_id = order_uuid
    GROUP BY gb.id, gb.batch_number, gb.status, gb.cards_description, 
             gb.tracking_number_outbound, gb.tracking_number_return, 
             gb.sent_date, gb.completed_date
    ORDER BY gb.batch_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

