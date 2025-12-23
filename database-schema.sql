-- Supabase Datenbank-Schema für Grading-Kundenportal
-- Diese Datei kann direkt in Supabase SQL Editor ausgeführt werden

-- Tabelle: customers (Kunden)
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL, -- Wird von Supabase Auth verwaltet
    full_name TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabelle: grading_orders (Grading-Aufträge)
CREATE TABLE IF NOT EXISTS grading_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    order_number TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'shipped', 'delivered')),
    submission_date TIMESTAMP WITH TIME ZONE,
    estimated_completion_date TIMESTAMP WITH TIME ZONE,
    actual_completion_date TIMESTAMP WITH TIME ZONE,
    shipping_date TIMESTAMP WITH TIME ZONE,
    delivery_date TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabelle: grading_items (Einzelne Items in einem Auftrag)
CREATE TABLE IF NOT EXISTS grading_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    item_type TEXT, -- z.B. 'Pokemon Card', 'Sports Card', 'Comic', etc.
    grade TEXT, -- z.B. 'PSA 10', 'BGS 9.5', 'CGC 9.8', etc.
    images JSONB DEFAULT '[]'::jsonb, -- Array von Bild-URLs
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabelle: order_status_history (Status-Verlauf)
CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES grading_orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    changed_by TEXT DEFAULT 'system', -- 'system', 'admin', oder customer_id
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indizes für bessere Performance
CREATE INDEX IF NOT EXISTS idx_grading_orders_customer_id ON grading_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_grading_orders_status ON grading_orders(status);
CREATE INDEX IF NOT EXISTS idx_grading_orders_order_number ON grading_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_grading_items_order_id ON grading_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id);

-- Trigger für updated_at
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

CREATE TRIGGER update_grading_items_updated_at BEFORE UPDATE ON grading_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger für Status-Historie (automatisch bei Statusänderung)
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

-- Row Level Security (RLS) aktivieren
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Kunden können nur ihre eigenen Daten sehen
CREATE POLICY "Kunden können nur ihre eigenen Daten sehen"
    ON customers FOR SELECT
    USING (auth.uid()::text = id::text);

CREATE POLICY "Kunden können nur ihre eigenen Aufträge sehen"
    ON grading_orders FOR SELECT
    USING (customer_id::text = auth.uid()::text);

CREATE POLICY "Kunden können nur Items ihrer eigenen Aufträge sehen"
    ON grading_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_orders
            WHERE grading_orders.id = grading_items.order_id
            AND grading_orders.customer_id::text = auth.uid()::text
        )
    );

CREATE POLICY "Kunden können nur Status-Historie ihrer eigenen Aufträge sehen"
    ON order_status_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM grading_orders
            WHERE grading_orders.id = order_status_history.order_id
            AND grading_orders.customer_id::text = auth.uid()::text
        )
    );

-- Funktionen für Statistiken (optional)
CREATE OR REPLACE FUNCTION get_customer_order_stats(customer_uuid UUID)
RETURNS TABLE (
    total_orders BIGINT,
    pending_orders BIGINT,
    in_progress_orders BIGINT,
    completed_orders BIGINT,
    shipped_orders BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) FILTER (WHERE true) as total_orders,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_orders,
        COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_orders,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_orders,
        COUNT(*) FILTER (WHERE status = 'shipped') as shipped_orders
    FROM grading_orders
    WHERE customer_id = customer_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Beispiel-Daten (für Testing - optional)
-- INSERT INTO customers (id, email, full_name) VALUES
-- ('00000000-0000-0000-0000-000000000001', 'kunde@example.com', 'Max Mustermann');

-- INSERT INTO grading_orders (customer_id, order_number, status, submission_date) VALUES
-- ('00000000-0000-0000-0000-000000000001', 'ORD-2024-001', 'in_progress', NOW() - INTERVAL '5 days');

