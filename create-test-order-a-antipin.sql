-- ============================================
-- Test-Auftrag für a.antipin@lamacards.de erstellen
-- ============================================

DO $$
DECLARE
    v_customer_id UUID := '7ce4d085-557d-43fe-a8a5-bfa17bc65f11';
    v_service_id UUID;
    v_order_id UUID;
    v_batch_id UUID;
BEGIN
    -- Prüfe ob Kunde existiert
    IF NOT EXISTS (SELECT 1 FROM customers WHERE id = v_customer_id) THEN
        RAISE EXCEPTION 'Kunde mit ID % nicht gefunden!', v_customer_id;
    END IF;
    
    -- Hole Service ID (PSA Grading Service)
    SELECT id INTO v_service_id 
    FROM grading_services 
    WHERE service_name = 'PSA Grading Service' 
    LIMIT 1;
    
    IF v_service_id IS NULL THEN
        RAISE EXCEPTION 'PSA Grading Service nicht gefunden!';
    END IF;
    
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
        'ORD-2025-TEST-' || TO_CHAR(NOW(), 'HH24MISS'),
        NOW() - INTERVAL '10 days',
        'Pikachu VMAX, Charizard Base Set, Blastoise Base Set, Venusaur Base Set',
        v_service_id,
        'PSA',
        200.00,
        'paid',
        'in_grading',
        'Test-Auftrag für a.antipin@lamacards.de - In Bearbeitung bei PSA'
    ) RETURNING id INTO v_order_id;
    
    RAISE NOTICE '✅ Auftrag erstellt: %', v_order_id;
    
    -- Erstelle einen Batch
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
        'Pikachu VMAX, Charizard Base Set, Blastoise Base Set, Venusaur Base Set',
        'in_grading',
        'TRACK-PSA-' || TO_CHAR(NOW(), 'YYYYMMDD'),
        NOW() - INTERVAL '8 days',
        NOW() - INTERVAL '5 days'
    ) RETURNING id INTO v_batch_id;
    
    RAISE NOTICE '✅ Batch erstellt: %', v_batch_id;
    
    -- Erstelle Grading-Nummern (Karten)
    INSERT INTO grading_numbers (batch_id, grading_number, card_description) VALUES
        (v_batch_id, 'PSA-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-001', 'Pikachu VMAX'),
        (v_batch_id, 'PSA-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-002', 'Charizard Base Set'),
        (v_batch_id, 'PSA-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-003', 'Blastoise Base Set'),
        (v_batch_id, 'PSA-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-004', 'Venusaur Base Set');
    
    RAISE NOTICE '✅ 4 Karten erstellt';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Test-Auftrag erfolgreich erstellt!';
    RAISE NOTICE '   Auftrag-ID: %', v_order_id;
    RAISE NOTICE '   Batch-ID: %', v_batch_id;
    RAISE NOTICE '   Karten: 4';
    RAISE NOTICE '   Status: in_grading';
    RAISE NOTICE '========================================';
    
END $$;

-- Prüfe Ergebnis
SELECT 
    o.order_number,
    o.status,
    o.cards_description,
    o.amount_paid,
    o.payment_status,
    COUNT(gn.id) as anzahl_karten,
    STRING_AGG(gn.card_description, ', ') as karten
FROM grading_orders o
JOIN grading_batches gb ON gb.order_id = o.id
LEFT JOIN grading_numbers gn ON gn.batch_id = gb.id
WHERE o.customer_id = '7ce4d085-557d-43fe-a8a5-bfa17bc65f11'
AND o.order_number LIKE 'ORD-2025-TEST-%'
GROUP BY o.id, o.order_number, o.status, o.cards_description, o.amount_paid, o.payment_status
ORDER BY o.created_at DESC
LIMIT 1;

