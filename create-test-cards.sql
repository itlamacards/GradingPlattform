-- ============================================
-- 3 Test-Karten für a.antipin@lamacards.de erstellen
-- ============================================

DO $$
DECLARE
    v_customer_id UUID;
    v_service_id UUID;
    v_order_id UUID;
    v_batch_id UUID;
BEGIN
    -- Hole Customer ID
    SELECT id INTO v_customer_id 
    FROM customers 
    WHERE email = 'a.antipin@lamacards.de';
    
    -- Prüfe ob Kunde existiert
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Kunde a.antipin@lamacards.de nicht gefunden! Bitte zuerst Kunde erstellen.';
    END IF;
    
    -- Hole Service ID (PSA Grading Service)
    SELECT id INTO v_service_id 
    FROM grading_services 
    WHERE service_name = 'PSA Grading Service' 
    LIMIT 1;
    
    -- Erstelle einen neuen Auftrag
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
        'ORD-TEST-' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MISS'),
        NOW(),
        'Test Karte 1, Test Karte 2, Test Karte 3',
        v_service_id,
        'PSA',
        75.00,
        'paid',
        'submitted',
        'Test-Auftrag mit 3 Karten'
    ) RETURNING id INTO v_order_id;
    
    -- Erstelle einen Batch
    INSERT INTO grading_batches (
        order_id,
        batch_number,
        cards_description,
        status
    ) VALUES (
        v_order_id,
        1,
        'Test Karte 1, Test Karte 2, Test Karte 3',
        'prepared'
    ) RETURNING id INTO v_batch_id;
    
    -- Erstelle 3 Grading-Nummern (Karten)
    INSERT INTO grading_numbers (batch_id, grading_number, card_description) VALUES
        (v_batch_id, 'PSA-TEST-001', 'Test Karte 1 - Pikachu VMAX'),
        (v_batch_id, 'PSA-TEST-002', 'Test Karte 2 - Charizard Base Set'),
        (v_batch_id, 'PSA-TEST-003', 'Test Karte 3 - Blastoise Base Set');
    
    RAISE NOTICE '✅ Erfolgreich erstellt:';
    RAISE NOTICE '   - Auftrag: %', v_order_id;
    RAISE NOTICE '   - Batch: %', v_batch_id;
    RAISE NOTICE '   - 3 Karten erstellt';
    
END $$;

-- Prüfe Ergebnis
SELECT 
    o.order_number,
    o.status,
    o.cards_description,
    COUNT(gn.id) as anzahl_karten,
    STRING_AGG(gn.card_description, ', ') as karten
FROM grading_orders o
JOIN grading_batches gb ON gb.order_id = o.id
LEFT JOIN grading_numbers gn ON gn.batch_id = gb.id
WHERE o.customer_id = (SELECT id FROM customers WHERE email = 'a.antipin@lamacards.de')
AND o.order_number LIKE 'ORD-TEST-%'
GROUP BY o.id, o.order_number, o.status, o.cards_description
ORDER BY o.created_at DESC
LIMIT 1;

