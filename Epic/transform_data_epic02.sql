-- ==========================================
-- SCRIPT DE TRANSFORMATION : EPIC 02
-- Projet : SoumiaTech Data Pipeline
-- ==========================================

-- 1. Fonction de nettoyage des dates
-- Gère les formats 'YYYY-MM-DD' et 'DD/MM/YYYY'
CREATE OR REPLACE FUNCTION fn_clean_date(date_str TEXT) 
RETURNS DATE AS $$
BEGIN
    IF date_str IS NULL OR date_str = '' OR date_str = 'None' THEN 
        RETURN NULL; 
    END IF;
    
    -- Tentative format ISO (YYYY-MM-DD)
    BEGIN
        RETURN date_str::DATE;
    EXCEPTION WHEN OTHERS THEN
        -- Tentative format DD/MM/YYYY ou DD-MM-YYYY
        BEGIN
            RETURN to_date(date_str, 'DD/MM/YYYY');
        EXCEPTION WHEN OTHERS THEN
            BEGIN
                RETURN to_date(date_str, 'DD-MM-YYYY');
            EXCEPTION WHEN OTHERS THEN
                -- Tentative format DD-Mon-YYYY (ex: 18-Nov-2022)
                BEGIN
                    RETURN to_date(date_str, 'DD-Mon-YYYY');
                EXCEPTION WHEN OTHERS THEN
                    RETURN NULL;
                END;
            END;
        END;
    END;
END;
$$ LANGUAGE plpgsql;

-- 2. Fonction de robustesse JSON
-- Tente de parser le JSON, retourne un objet vide {} si corrompu
CREATE OR REPLACE FUNCTION fn_fix_json(json_str TEXT) 
RETURNS JSONB AS $$
BEGIN
    IF json_str IS NULL OR json_str = '' OR json_str = 'None' THEN 
        RETURN '{}'::JSONB; 
    END IF;
    
    BEGIN
        RETURN json_str::JSONB;
    EXCEPTION WHEN OTHERS THEN
        -- En cas de JSON tronqué/invalide, on retourne un objet avec une trace d'erreur
        -- On pourrait aussi tenter une réparation par regex ici si besoin.
        RETURN jsonb_build_object('raw_error', json_str, 'corrupted', true);
    END;
END;
$$ LANGUAGE plpgsql;

-- 3. Procédure de transformation orchestrée
-- Remplit les dimensions puis la table de faits avec UPSERT
CREATE OR REPLACE PROCEDURE sp_transform_staging_to_core()
AS $$
BEGIN
    -- A. Alimentation de dim_clients (Uniquement les nouveaux)
    INSERT INTO dim_clients (client_id, client_name)
    SELECT DISTINCT client_id, client_name
    FROM staging_orders
    WHERE client_id IS NOT NULL
    ON CONFLICT (client_id) DO NOTHING;

    -- B. Alimentation de dim_products (Uniquement les nouveaux)
    INSERT INTO dim_products (product_id, product_name)
    SELECT DISTINCT product_id, product_name
    FROM staging_orders
    WHERE product_id IS NOT NULL
    ON CONFLICT (product_id) DO NOTHING;

    -- C. Alimentation de fact_orders (Transformation et UPSERT)
    INSERT INTO fact_orders (
        order_id, client_key, product_key, quantity, unit_price, 
        order_date, delivery_date, status, region, sales_rep, operational_data
    )
    SELECT 
        s.order_id,
        c.client_key,
        p.product_key,
        NULLIF(regexp_replace(s.quantity, '[^0-9.]', '', 'g'), '')::NUMERIC::INT, -- Nettoyage quantité
        NULLIF(regexp_replace(s.unit_price, '[^0-9.]', '', 'g'), '')::NUMERIC,    -- Nettoyage prix
        fn_clean_date(s.order_date),
        fn_clean_date(s.delivery_date),
        LOWER(s.status),
        s.region,
        s.sales_rep,
        fn_fix_json(s.operational_data)
    FROM staging_orders s
    JOIN dim_clients c ON s.client_id = c.client_id
    JOIN dim_products p ON s.product_id = p.product_id
    ON CONFLICT (order_id) DO UPDATE SET
        status = EXCLUDED.status,
        delivery_date = EXCLUDED.delivery_date,
        operational_data = EXCLUDED.operational_data,
        quantity = EXCLUDED.quantity,
        unit_price = EXCLUDED.unit_price;

    RAISE NOTICE 'Transformation terminée avec succès.';
END;
$$ LANGUAGE plpgsql;
