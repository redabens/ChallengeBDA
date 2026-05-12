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
DECLARE
    clean_json TEXT;
BEGIN
    IF json_str IS NULL OR json_str = '' OR json_str = 'None' THEN 
        RETURN '{}'::JSONB; 
    END IF;

    -- 1. Nettoyage des guillemets parasites et des échappements
    clean_json := json_str;
    
    -- Enlever les guillemets de début et fin si présents
    IF clean_json LIKE '"%' AND clean_json LIKE '%"' THEN
        clean_json := substr(clean_json, 2, length(clean_json) - 2);
    END IF;
    
    -- Remplacer les doubles guillemets par des simples
    clean_json := replace(clean_json, '""', '"');
    
    -- Remplacer les échappements
    clean_json := replace(clean_json, '\"', '"');

    -- 2. Tentative de conversion
    BEGIN
        RETURN clean_json::JSONB;
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('raw_error', json_str, 'clean_attempt', clean_json, 'corrupted', true);
    END;
END;
$$ LANGUAGE plpgsql;

-- 3. Procédure de transformation orchestrée
-- Remplit les dimensions puis la table de faits avec UPSERT
CREATE OR REPLACE PROCEDURE sp_transform_staging_to_core()
AS $$
BEGIN
    -- A. Alimentation de dim_clients (Gestion des noms manquants)
    INSERT INTO dim_clients (client_id, client_name)
    SELECT DISTINCT client_id, COALESCE(NULLIF(client_name, 'None'), 'Client Inconnu')
    FROM staging_orders
    WHERE client_id IS NOT NULL AND client_id <> 'None'
    ON CONFLICT (client_id) DO NOTHING;

    -- B. Alimentation de dim_products (Gestion des noms manquants)
    INSERT INTO dim_products (product_id, product_name)
    SELECT DISTINCT product_id, COALESCE(NULLIF(product_name, 'None'), 'Produit Inconnu')
    FROM staging_orders
    WHERE product_id IS NOT NULL AND product_id <> 'None'
    ON CONFLICT (product_id) DO NOTHING;

    -- C. Alimentation de fact_orders (Déduplication et UPSERT)
    INSERT INTO fact_orders (
        order_id, client_key, product_key, quantity, unit_price, 
        order_date, delivery_date, status, region, sales_rep, operational_data
    )
    SELECT DISTINCT ON (s.order_id)
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
    ORDER BY s.order_id
    ON CONFLICT (order_id) DO UPDATE SET
        status = EXCLUDED.status,
        delivery_date = EXCLUDED.delivery_date,
        operational_data = EXCLUDED.operational_data,
        quantity = EXCLUDED.quantity,
        unit_price = EXCLUDED.unit_price;

    RAISE NOTICE 'Transformation terminée avec succès.';
END;
$$ LANGUAGE plpgsql;
