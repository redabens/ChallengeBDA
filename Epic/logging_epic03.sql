-- ==========================================
-- SCRIPT DE LOGGING : EPIC 03
-- Projet : SoumiaTech Data Pipeline
-- ==========================================

-- 1. Création de la table de logs
CREATE TABLE IF NOT EXISTS pipeline_logs (
    log_id SERIAL PRIMARY KEY,
    execution_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20), -- 'SUCCESS', 'FAILURE'
    rows_processed INT,
    error_message TEXT
);

-- 2. Procédure mise à jour avec logging
CREATE OR REPLACE PROCEDURE sp_transform_staging_to_core()
AS $$
DECLARE
    v_rows INT;
    v_error_msg TEXT;
BEGIN
    BEGIN
        -- A. Alimentation de dim_clients
        INSERT INTO dim_clients (client_id, client_name)
        SELECT DISTINCT client_id, client_name
        FROM staging_orders
        WHERE client_id IS NOT NULL
        ON CONFLICT (client_id) DO NOTHING;

        -- B. Alimentation de dim_products
        INSERT INTO dim_products (product_id, product_name)
        SELECT DISTINCT product_id, product_name
        FROM staging_orders
        WHERE product_id IS NOT NULL
        ON CONFLICT (product_id) DO NOTHING;

        -- C. Alimentation de fact_orders
        INSERT INTO fact_orders (
            order_id, client_key, product_key, quantity, unit_price, 
            order_date, delivery_date, status, region, sales_rep, operational_data
        )
        SELECT 
            s.order_id,
            c.client_key,
            p.product_key,
            NULLIF(regexp_replace(s.quantity, '[^0-9.]', '', 'g'), '')::NUMERIC::INT,
            NULLIF(regexp_replace(s.unit_price, '[^0-9.]', '', 'g'), '')::NUMERIC,
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

        GET DIAGNOSTICS v_rows = ROW_COUNT;

        -- D. Log succès
        INSERT INTO pipeline_logs (status, rows_processed)
        VALUES ('SUCCESS', v_rows);

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        -- E. Log échec
        INSERT INTO pipeline_logs (status, error_message)
        VALUES ('FAILURE', v_error_msg);
        RAISE EXCEPTION 'Erreur dans le pipeline : %', v_error_msg;
    END;
END;
$$ LANGUAGE plpgsql;
