-- Supabase Datenbank-Schema für Grading-Kundenportal
-- Basierend auf dem tatsächlichen Geschäftsprozess
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
-- Ein Auftrag = Ein Kunde kauft ein Grading
CREATE TABLE IF NOT EXISTS grading_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    order_number TEXT UNIQUE NOT NULL, -- Interne Auftragsnummer
    
    -- Abgabe
    submission_date TIMESTAMP WITH TIME ZONE NOT NULL, -- Abgabe Datum karten kunde
    
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
        'stored',              -- Gelagert (Karten sind bei uns)
        'in_charge',           -- In Charge (Karten sind in einer Charge)
        'sent_to_grading',     -- Versendet an PSA/CGC (Charge wurde versendet)
        'arrived_at_grading',  -- Angekommen bei PSA/CGC
        'in_grading',         -- In Bearbeitung
        'grading_completed',   -- Grading abgeschlossen
        'sent_back',          -- Versendet zurück
        'arrived_back',       -- Angekommen bei uns
        'ready_for_pickup',   -- Bereit zur Abholung
        'completed'           -- Vollständig abgeschlossen (Kunde hat abgeholt)
    )),
    
    -- Zahlungsstatus
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
-- TABELLE 4: cards (Karten)
-- ============================================
-- Einzelne Karten, die der Kunde abgegeben hat
CREATE TABLE IF NOT EXISTS cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    
    -- Karten-Beschreibung
    card_description TEXT NOT NULL, -- Beschreibung der Karte (z.B. "Pikachu VMAX", "Charizard Base Set")
    card_type TEXT, -- Optional: Typ (z.B. "Pokemon Card", "Sports Card", "Comic")
    
    -- Status der einzelnen Karte
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN (
        'submitted',           -- Abgegeben
        'stored',              -- Gelagert
        'in_charge',           -- In Charge
        'sent_to_grading',     -- Versendet
        'arrived_at_grading',  -- Angekommen
        'in_grading',         -- In Bearbeitung
        'grading_completed',   -- Grading abgeschlossen
        'sent_back',          -- Versendet zurück
        'arrived_back',       -- Angekommen
        'ready_for_pickup',   -- Bereit zur Abholung
        'completed'           -- Abgeholt
    )),
    
    -- Notizen
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELLE 5: charges (Charges)
-- ============================================
-- Eine Charge = Viele Karten von verschiedenen Kunden werden zusammen geschickt
CREATE TABLE IF NOT EXISTS charges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    charge_number TEXT UNIQUE NOT NULL, -- Interne Charge-Nummer
    
    -- Grading Service für diese Charge
    grading_service_id UUID NOT NULL REFERENCES grading_services(id),
    grading_provider TEXT NOT NULL CHECK (grading_provider IN ('PSA', 'CGC')),
    
    -- Grading-ID von PSA/CGC (wird NACH Versand zugewiesen, vorher NULL)
    -- Diese ID wird verwendet, um die Grading-Daten von PSA/CGC per API abzurufen
    grading_id TEXT, -- PSA/CGC Charge-ID (für API-Aufruf, nur gesetzt wenn versendet)
    
    -- Status der Charge
    status TEXT NOT NULL DEFAULT 'prepared' CHECK (status IN (
        'prepared',            -- Vorbereitet (Karten zugeordnet)
        'sent_to_grading',     -- Versendet an PSA/CGC
        'arrived_at_grading',   -- Angekommen bei PSA/CGC
        'in_grading',         -- In Bearbeitung
        'grading_completed',   -- Grading abgeschlossen
        'sent_back',          -- Versendet zurück
        'arrived_back',       -- Angekommen bei uns
        'distributed'         -- An Kunden verteilt
    )),
    
    -- Tracking
    tracking_number_outbound TEXT, -- Trackingnummer Hinversand
    tracking_number_return TEXT,   -- Trackingnummer Rückversand
    
    -- Daten
    sent_date TIMESTAMP WITH TIME ZONE, -- Wann wurde diese Charge versendet
    arrived_date TIMESTAMP WITH TIME ZONE, -- Wann ist sie angekommen
    completed_date TIMESTAMP WITH TIME ZONE, -- Wann wurde sie abgeschlossen
    
    -- Notizen
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- TABELLE 6: charge_cards (Charge-Karten-Zuordnung)
-- ============================================
-- Welche Karten gehören zu welcher Charge
CREATE TABLE IF NOT EXISTS charge_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    charge_id UUID NOT NULL REFERENCES charges(id) ON DELETE CASCADE,
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    
    -- Position in der Charge (optional, für Reihenfolge)
    position INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(charge_id, card_id)
);

-- ============================================
-- TABELLE 7: grading_results (PSA-/CGC-Rückmeldungen)
-- ============================================
-- Grading-Ergebnisse für jede Karte
CREATE TABLE IF NOT EXISTS grading_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    charge_id UUID NOT NULL REFERENCES charges(id) ON DELETE CASCADE,
    
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
-- TABELLE 8: invoices (Rechnungen)
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
-- TABELLE 9: order_status_history (Status-Verlauf)
-- ============================================
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES grading_orders(id) ON DELETE CASCADE,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    charge_id UUID REFERENCES charges(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_grading_orders_payment_status ON grading_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_cards_order_id ON cards(order_id);
CREATE INDEX IF NOT EXISTS idx_cards_status ON cards(status);
CREATE INDEX IF NOT EXISTS idx_charges_grading_id ON charges(grading_id);
CREATE INDEX IF NOT EXISTS idx_charges_status ON charges(status);
CREATE INDEX IF NOT EXISTS idx_charges_charge_number ON charges(charge_number);
CREATE INDEX IF NOT EXISTS idx_charge_cards_charge_id ON charge_cards(charge_id);
CREATE INDEX IF NOT EXISTS idx_charge_cards_card_id ON charge_cards(card_id);
CREATE INDEX IF NOT EXISTS idx_grading_results_card_id ON grading_results(card_id);
CREATE INDEX IF NOT EXISTS idx_grading_results_order_id ON grading_results(order_id);
CREATE INDEX IF NOT EXISTS idx_grading_results_charge_id ON grading_results(charge_id);
CREATE INDEX IF NOT EXISTS idx_invoices_order_id ON invoices(order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON invoices(invoice_number);

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

CREATE TRIGGER update_cards_updated_at BEFORE UPDATE ON cards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_charges_updated_at BEFORE UPDATE ON charges
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

CREATE OR REPLACE FUNCTION log_card_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (card_id, status, changed_by, notes)
        VALUES (NEW.id, NEW.status, 'system', 'Karten-Status automatisch geändert');
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER log_card_status_change AFTER UPDATE ON cards
    FOR EACH ROW EXECUTE FUNCTION log_card_status_change();

CREATE OR REPLACE FUNCTION log_charge_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (charge_id, status, changed_by, notes)
        VALUES (NEW.id, NEW.status, 'system', 'Charge-Status automatisch geändert');
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER log_charge_status_change AFTER UPDATE ON charges
    FOR EACH ROW EXECUTE FUNCTION log_charge_status_change();

-- ============================================
-- TRIGGER: Automatische Status-Aktualisierung
-- ============================================

-- Aktualisiere Karten-Status wenn sie einer Charge zugeordnet werden
CREATE OR REPLACE FUNCTION update_card_status_on_charge_assignment()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE cards SET status = 'in_charge' WHERE id = NEW.card_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_card_on_charge_assignment AFTER INSERT ON charge_cards
    FOR EACH ROW EXECUTE FUNCTION update_card_status_on_charge_assignment();

-- Aktualisiere Karten-Status basierend auf Charge-Status
CREATE OR REPLACE FUNCTION update_cards_from_charge_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE cards 
    SET status = CASE 
        WHEN NEW.status = 'sent_to_grading' THEN 'sent_to_grading'
        WHEN NEW.status = 'arrived_at_grading' THEN 'arrived_at_grading'
        WHEN NEW.status = 'in_grading' THEN 'in_grading'
        WHEN NEW.status = 'grading_completed' THEN 'grading_completed'
        WHEN NEW.status = 'sent_back' THEN 'sent_back'
        WHEN NEW.status = 'arrived_back' THEN 'arrived_back'
        WHEN NEW.status = 'distributed' THEN 'ready_for_pickup'
        ELSE cards.status
    END
    WHERE id IN (
        SELECT card_id FROM charge_cards WHERE charge_id = NEW.id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_cards_from_charge_status AFTER UPDATE ON charges
    FOR EACH ROW EXECUTE FUNCTION update_cards_from_charge_status();

-- Aktualisiere Auftrags-Status basierend auf Karten-Status
CREATE OR REPLACE FUNCTION update_order_status_from_cards()
RETURNS TRIGGER AS $$
DECLARE
    order_uuid UUID;
    all_completed BOOLEAN;
    any_ready_for_pickup BOOLEAN;
    any_arrived_back BOOLEAN;
    any_grading_completed BOOLEAN;
    any_in_grading BOOLEAN;
    any_arrived_at_grading BOOLEAN;
    any_sent_to_grading BOOLEAN;
    any_in_charge BOOLEAN;
BEGIN
    order_uuid := NEW.order_id;
    
    -- Prüfe Status aller Karten des Auftrags
    SELECT 
        BOOL_AND(status = 'completed'),
        BOOL_OR(status = 'ready_for_pickup'),
        BOOL_OR(status = 'arrived_back'),
        BOOL_OR(status = 'grading_completed'),
        BOOL_OR(status = 'in_grading'),
        BOOL_OR(status = 'arrived_at_grading'),
        BOOL_OR(status = 'sent_to_grading'),
        BOOL_OR(status = 'in_charge')
    INTO 
        all_completed,
        any_ready_for_pickup,
        any_arrived_back,
        any_grading_completed,
        any_in_grading,
        any_arrived_at_grading,
        any_sent_to_grading,
        any_in_charge
    FROM cards
    WHERE order_id = order_uuid;
    
    -- Aktualisiere Auftrags-Status basierend auf Karten-Status
    IF all_completed THEN
        UPDATE grading_orders SET status = 'completed' WHERE id = order_uuid;
    ELSIF any_ready_for_pickup THEN
        UPDATE grading_orders SET status = 'ready_for_pickup' WHERE id = order_uuid;
    ELSIF any_arrived_back THEN
        UPDATE grading_orders SET status = 'arrived_back' WHERE id = order_uuid;
    ELSIF any_grading_completed THEN
        UPDATE grading_orders SET status = 'grading_completed' WHERE id = order_uuid;
    ELSIF any_in_grading THEN
        UPDATE grading_orders SET status = 'in_grading' WHERE id = order_uuid;
    ELSIF any_arrived_at_grading THEN
        UPDATE grading_orders SET status = 'arrived_at_grading' WHERE id = order_uuid;
    ELSIF any_sent_to_grading THEN
        UPDATE grading_orders SET status = 'sent_to_grading' WHERE id = order_uuid;
    ELSIF any_in_charge THEN
        UPDATE grading_orders SET status = 'in_charge' WHERE id = order_uuid;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_status_on_card_change AFTER INSERT OR UPDATE ON cards
    FOR EACH ROW EXECUTE FUNCTION update_order_status_from_cards();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE charges ENABLE ROW LEVEL SECURITY;
ALTER TABLE charge_cards ENABLE ROW LEVEL SECURITY;
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

CREATE POLICY "Kunden können nur ihre eigenen Karten sehen"
    ON cards FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_orders
            WHERE grading_orders.id = cards.order_id
            AND grading_orders.customer_id::text = auth.uid()::text
        )
    );

CREATE POLICY "Kunden können nur Ergebnisse ihrer Karten sehen"
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

-- Funktion: Charge-Nummer automatisch generieren
CREATE OR REPLACE FUNCTION generate_charge_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    exists_check BOOLEAN;
BEGIN
    LOOP
        new_number := 'CHG-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        SELECT EXISTS(SELECT 1 FROM charges WHERE charge_number = new_number) INTO exists_check;
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
    stored_orders BIGINT,
    in_charge_orders BIGINT,
    in_grading_orders BIGINT,
    completed_orders BIGINT,
    total_amount_paid DECIMAL,
    pending_payment DECIMAL,
    total_cards BIGINT,
    cards_in_grading BIGINT,
    cards_completed BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT go.id) FILTER (WHERE true) as total_orders,
        COUNT(DISTINCT go.id) FILTER (WHERE go.status = 'stored') as stored_orders,
        COUNT(DISTINCT go.id) FILTER (WHERE go.status = 'in_charge') as in_charge_orders,
        COUNT(DISTINCT go.id) FILTER (WHERE go.status IN ('sent_to_grading', 'arrived_at_grading', 'in_grading')) as in_grading_orders,
        COUNT(DISTINCT go.id) FILTER (WHERE go.status = 'completed') as completed_orders,
        COALESCE(SUM(go.amount_paid), 0) as total_amount_paid,
        COALESCE(SUM(CASE WHEN go.payment_status = 'pending' THEN go.amount_paid ELSE 0 END), 0) as pending_payment,
        COUNT(c.id) as total_cards,
        COUNT(c.id) FILTER (WHERE c.status IN ('sent_to_grading', 'arrived_at_grading', 'in_grading')) as cards_in_grading,
        COUNT(c.id) FILTER (WHERE c.status = 'completed') as cards_completed
    FROM grading_orders go
    LEFT JOIN cards c ON c.order_id = go.id
    WHERE go.customer_id = customer_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funktion: Alle Karten eines Auftrags mit Status abrufen
CREATE OR REPLACE FUNCTION get_order_cards_with_status(order_uuid UUID)
RETURNS TABLE (
    card_id UUID,
    card_description TEXT,
    card_type TEXT,
    status TEXT,
    charge_number TEXT,
    charge_grading_id TEXT,
    grade TEXT,
    grade_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id as card_id,
        c.card_description,
        c.card_type,
        c.status,
        ch.charge_number,
        ch.grading_id as charge_grading_id,
        gr.grade,
        gr.grade_date
    FROM cards c
    LEFT JOIN charge_cards cc ON cc.card_id = c.id
    LEFT JOIN charges ch ON ch.id = cc.charge_id
    LEFT JOIN grading_results gr ON gr.card_id = c.id
    WHERE c.order_id = order_uuid
    ORDER BY c.created_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funktion: Charge-Details mit allen Karten abrufen
CREATE OR REPLACE FUNCTION get_charge_details(charge_uuid UUID)
RETURNS TABLE (
    charge_number TEXT,
    grading_id TEXT,
    status TEXT,
    total_cards BIGINT,
    cards_by_customer JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ch.charge_number,
        ch.grading_id,
        ch.status,
        COUNT(DISTINCT cc.card_id) as total_cards,
        jsonb_agg(
            jsonb_build_object(
                'customer_name', c.first_name || ' ' || c.last_name,
                'order_number', go.order_number,
                'card_description', card.card_description,
                'card_status', card.status,
                'grade', gr.grade
            )
        ) as cards_by_customer
    FROM charges ch
    JOIN charge_cards cc ON cc.charge_id = ch.id
    JOIN cards card ON card.id = cc.card_id
    JOIN grading_orders go ON go.id = card.order_id
    JOIN customers c ON c.id = go.customer_id
    LEFT JOIN grading_results gr ON gr.card_id = card.id
    WHERE ch.id = charge_uuid
    GROUP BY ch.id, ch.charge_number, ch.grading_id, ch.status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

