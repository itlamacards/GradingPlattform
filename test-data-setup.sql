-- ============================================
-- TEST-DATEN SETUP
-- ============================================
-- Dieses Script erstellt Test-Benutzer, Aufträge und Karten
-- Führe es im Supabase SQL Editor aus
-- ============================================

-- ============================================
-- 1. KUNDEN ERSTELLEN
-- ============================================

-- Hauptbenutzer: a.antipin@lamacards.de
INSERT INTO customers (customer_number, first_name, last_name, email, phone)
VALUES 
    ('K-2024-0001', 'Anton', 'Antipin', 'a.antipin@lamacards.de', '+49 123 456789')
ON CONFLICT (email) DO UPDATE SET
    customer_number = EXCLUDED.customer_number,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    phone = EXCLUDED.phone,
    updated_at = NOW();

-- Test-Benutzer: it@lamacards.de
INSERT INTO customers (customer_number, first_name, last_name, email, phone)
VALUES 
    ('K-2024-0002', 'IT', 'Test', 'it@lamacards.de', '+49 987 654321')
ON CONFLICT (email) DO UPDATE SET
    customer_number = EXCLUDED.customer_number,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    phone = EXCLUDED.phone,
    updated_at = NOW();

-- ============================================
-- 2. TEST-AUFTRÄGE FÜR a.antipin@lamacards.de
-- ============================================

-- Auftrag 1: In Bearbeitung (mit mehreren Karten)
DO $$
DECLARE
    v_customer_id UUID;
    v_service_id UUID;
    v_order_id UUID;
    v_batch_id UUID;
BEGIN
    -- Hole Customer ID
    SELECT id INTO v_customer_id FROM customers WHERE email = 'a.antipin@lamacards.de';
    
    -- Hole Service ID
    SELECT id INTO v_service_id FROM grading_services WHERE service_name = 'PSA Grading Service' LIMIT 1;
    
    -- Erstelle Auftrag
    INSERT INTO grading_orders (
        customer_id,
        order_number,
        submission_date,
        cards_description,
        grading_service_id,
        grading_provider,
        amount_paid,
        payment_status,
        status,
        notes
    ) VALUES (
        v_customer_id,
        'ORD-2024-001',
        NOW() - INTERVAL '30 days',
        'Pikachu VMAX, Charizard Base Set, Blastoise Base Set',
        v_service_id,
        'PSA',
        150.00,
        'paid',
        'in_grading',
        'Erster Test-Auftrag - In Bearbeitung bei PSA'
    ) RETURNING id INTO v_order_id;
    
    -- Erstelle Batch
    INSERT INTO grading_batches (
        order_id,
        batch_number,
        cards_description,
        status,
        tracking_number_outbound,
        sent_date,
        arrived_date
    ) VALUES (
        v_order_id,
        1,
        'Pikachu VMAX, Charizard Base Set, Blastoise Base Set',
        'in_grading',
        'TRACK-001-OUT',
        NOW() - INTERVAL '25 days',
        NOW() - INTERVAL '20 days'
    ) RETURNING id INTO v_batch_id;
    
    -- Erstelle Grading-Nummern (entspricht Karten)
    INSERT INTO grading_numbers (batch_id, grading_number, card_description) VALUES
        (v_batch_id, 'PSA-001', 'Pikachu VMAX'),
        (v_batch_id, 'PSA-002', 'Charizard Base Set'),
        (v_batch_id, 'PSA-003', 'Blastoise Base Set');
END $$;

-- Auftrag 2: Abgeschlossen (mit Grading-Ergebnissen)
DO $$
DECLARE
    v_customer_id UUID;
    v_service_id UUID;
    v_order_id UUID;
    v_batch_id UUID;
    v_card1_id UUID;
    v_card2_id UUID;
    v_card3_id UUID;
BEGIN
    -- Hole Customer ID
    SELECT id INTO v_customer_id FROM customers WHERE email = 'a.antipin@lamacards.de';
    
    -- Hole Service ID
    SELECT id INTO v_service_id FROM grading_services WHERE service_name = 'PSA Grading Service' LIMIT 1;
    
    -- Erstelle Auftrag
    INSERT INTO grading_orders (
        customer_id,
        order_number,
        submission_date,
        cards_description,
        grading_service_id,
        grading_provider,
        amount_paid,
        payment_status,
        status,
        notes
    ) VALUES (
        v_customer_id,
        'ORD-2024-002',
        NOW() - INTERVAL '60 days',
        'LeBron James Rookie Card, Michael Jordan Rookie Card, Kobe Bryant Rookie Card',
        v_service_id,
        'PSA',
        120.00,
        'paid',
        'completed',
        'Abgeschlossener Test-Auftrag mit Ergebnissen'
    ) RETURNING id INTO v_order_id;
    
    -- Erstelle Batch
    INSERT INTO grading_batches (
        order_id,
        batch_number,
        cards_description,
        status,
        tracking_number_outbound,
        tracking_number_return,
        sent_date,
        arrived_date,
        completed_date
    ) VALUES (
        v_order_id,
        1,
        'LeBron James Rookie Card, Michael Jordan Rookie Card, Kobe Bryant Rookie Card',
        'completed',
        'TRACK-002-OUT',
        'TRACK-002-RETURN',
        NOW() - INTERVAL '55 days',
        NOW() - INTERVAL '50 days',
        NOW() - INTERVAL '10 days'
    ) RETURNING id INTO v_batch_id;
    
    -- Erstelle Grading-Nummern (entspricht Karten)
    INSERT INTO grading_numbers (batch_id, grading_number, card_description) VALUES
        (v_batch_id, 'PSA-101', 'LeBron James Rookie Card'),
        (v_batch_id, 'PSA-102', 'Michael Jordan Rookie Card'),
        (v_batch_id, 'PSA-103', 'Kobe Bryant Rookie Card');
    
    -- Hole die tatsächlichen Grading Number IDs
    SELECT id INTO v_card1_id FROM grading_numbers WHERE batch_id = v_batch_id AND card_description = 'LeBron James Rookie Card';
    SELECT id INTO v_card2_id FROM grading_numbers WHERE batch_id = v_batch_id AND card_description = 'Michael Jordan Rookie Card';
    SELECT id INTO v_card3_id FROM grading_numbers WHERE batch_id = v_batch_id AND card_description = 'Kobe Bryant Rookie Card';
    
    -- Erstelle Grading-Ergebnisse
    INSERT INTO grading_results (grading_number_id, order_id, batch_id, grade, grade_date, has_upcharge, upcharge_amount) VALUES
        (v_card1_id, v_order_id, v_batch_id, 'PSA 10', NOW() - INTERVAL '10 days', false, 0),
        (v_card2_id, v_order_id, v_batch_id, 'PSA 9', NOW() - INTERVAL '10 days', false, 0),
        (v_card3_id, v_order_id, v_batch_id, 'PSA 9', NOW() - INTERVAL '10 days', false, 0);
END $$;

-- Auftrag 3: Ausstehend
DO $$
DECLARE
    v_customer_id UUID;
    v_service_id UUID;
    v_order_id UUID;
    v_batch_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE email = 'a.antipin@lamacards.de';
    SELECT id INTO v_service_id FROM grading_services WHERE service_name = 'PSA Grading Service' LIMIT 1;
    
    INSERT INTO grading_orders (
        customer_id,
        order_number,
        submission_date,
        cards_description,
        grading_service_id,
        grading_provider,
        amount_paid,
        payment_status,
        status,
        notes
    ) VALUES (
        v_customer_id,
        'ORD-2024-003',
        NOW() - INTERVAL '5 days',
        'Spider-Man #1, Batman #1, Superman #1, X-Men #1, Avengers #1',
        v_service_id,
        'PSA',
        200.00,
        'paid',
        'submitted',
        'Neuer Auftrag - Wartet auf Versand'
    ) RETURNING id INTO v_order_id;
    
    -- Erstelle Batch (noch nicht versendet)
    INSERT INTO grading_batches (
        order_id,
        batch_number,
        cards_description,
        status
    ) VALUES (
        v_order_id,
        1,
        'Spider-Man #1, Batman #1, Superman #1, X-Men #1, Avengers #1',
        'prepared'
    ) RETURNING id INTO v_batch_id;
    
    -- Erstelle Grading-Nummern (entspricht Karten)
    INSERT INTO grading_numbers (batch_id, grading_number, card_description) VALUES
        (v_batch_id, 'PSA-201', 'Spider-Man #1'),
        (v_batch_id, 'PSA-202', 'Batman #1'),
        (v_batch_id, 'PSA-203', 'Superman #1'),
        (v_batch_id, 'PSA-204', 'X-Men #1'),
        (v_batch_id, 'PSA-205', 'Avengers #1');
END $$;

-- ============================================
-- 3. TEST-AUFTRAG FÜR it@lamacards.de
-- ============================================

DO $$
DECLARE
    v_customer_id UUID;
    v_service_id UUID;
    v_order_id UUID;
    v_batch_id UUID;
BEGIN
    SELECT id INTO v_customer_id FROM customers WHERE email = 'it@lamacards.de';
    SELECT id INTO v_service_id FROM grading_services WHERE service_name = 'CGC Grading Service' LIMIT 1;
    
    INSERT INTO grading_orders (
        customer_id,
        order_number,
        submission_date,
        cards_description,
        grading_service_id,
        grading_provider,
        amount_paid,
        payment_status,
        status,
        notes
    ) VALUES (
        v_customer_id,
        'ORD-2024-004',
        NOW() - INTERVAL '15 days',
        'Iron Man #1, Hulk #1, Thor #1',
        v_service_id,
        'CGC',
        90.00,
        'paid',
        'arrived_at_grading',
        'Test-Auftrag für IT-Benutzer'
    ) RETURNING id INTO v_order_id;
    
    INSERT INTO grading_batches (
        order_id,
        batch_number,
        cards_description,
        status,
        tracking_number_outbound,
        sent_date,
        arrived_date
    ) VALUES (
        v_order_id,
        1,
        'Iron Man #1, Hulk #1, Thor #1',
        'arrived_at_grading',
        'TRACK-004-OUT',
        NOW() - INTERVAL '12 days',
        NOW() - INTERVAL '8 days'
    ) RETURNING id INTO v_batch_id;
    
    INSERT INTO grading_numbers (batch_id, grading_number, card_description) VALUES
        (v_batch_id, 'CGC-301', 'Iron Man #1'),
        (v_batch_id, 'CGC-302', 'Hulk #1'),
        (v_batch_id, 'CGC-303', 'Thor #1');
END $$;

-- ============================================
-- 4. ZUSAMMENFASSUNG
-- ============================================

SELECT 
    '✅ Test-Daten erstellt!' as status,
    (SELECT COUNT(*) FROM customers WHERE email IN ('a.antipin@lamacards.de', 'it@lamacards.de')) as customers_created,
    (SELECT COUNT(*) FROM grading_orders WHERE customer_id IN (
        SELECT id FROM customers WHERE email IN ('a.antipin@lamacards.de', 'it@lamacards.de')
    )) as orders_created,
    (SELECT COUNT(*) FROM grading_numbers WHERE batch_id IN (
        SELECT id FROM grading_batches WHERE order_id IN (
            SELECT id FROM grading_orders WHERE customer_id IN (
                SELECT id FROM customers WHERE email IN ('a.antipin@lamacards.de', 'it@lamacards.de')
            )
        )
    )) as cards_created;

