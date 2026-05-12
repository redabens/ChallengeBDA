-- ==========================================
-- SCRIPT ANALYTIQUE : EPIC 04
-- Projet : SoumiaTech Data Pipeline
-- ==========================================

-- 1. Création de la Vue Analytique Aplatie
-- Cette vue permet d'accéder aux données JSON sans connaître la syntaxe JSONB
CREATE OR REPLACE VIEW vw_orders_analytics AS
SELECT 
    f.order_id,
    c.client_id,
    c.client_name,
    p.product_id,
    p.product_name,
    f.quantity,
    f.unit_price,
    (f.quantity * f.unit_price) AS total_revenue,
    f.order_date,
    f.delivery_date,
    f.status,
    f.region,
    f.sales_rep,
    -- Extraction du JSON
    f.operational_data -> 'shipping' ->> 'method' AS shipping_method,
    (f.operational_data -> 'shipping' ->> 'priority')::INT AS shipping_priority,
    f.operational_data -> 'shipping' ->> 'instructions' AS shipping_instructions,
    f.operational_data -> 'device' ->> 'platform' AS device_platform,
    (f.operational_data -> 'flags' ->> 'is_bulk')::BOOLEAN AS is_bulk,
    (f.operational_data -> 'flags' ->> 'is_international')::BOOLEAN AS is_international
FROM fact_orders f
JOIN dim_clients c ON f.client_key = c.client_key
JOIN dim_products p ON f.product_key = p.product_key;

COMMENT ON VIEW vw_orders_analytics IS 'Vue simplifiée pour le reporting business (JSON aplati)';

-- ==========================================
-- EXEMPLES DE RAPPORTS BUSINESS
-- ==========================================

-- A. Top 5 des produits générant le plus de revenus
-- SELECT product_name, SUM(total_revenue) as revenue
-- FROM vw_orders_analytics
-- GROUP BY product_name
-- ORDER BY revenue DESC
-- LIMIT 5;

-- B. Répartition du chiffre d'affaires par région
-- SELECT region, ROUND(SUM(total_revenue), 2) as revenue
-- FROM vw_orders_analytics
-- GROUP BY region
-- ORDER BY revenue DESC;

-- C. Utilisation des plateformes de commande (Device)
-- SELECT device_platform, COUNT(*) as nb_commandes
-- FROM vw_orders_analytics
-- GROUP BY device_platform
-- ORDER BY nb_commandes DESC;

-- D. Pourcentage de commandes internationales
-- SELECT 
--     is_international, 
--     COUNT(*) as nb,
--     ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pourcentage
-- FROM vw_orders_analytics
-- GROUP BY is_international;

-- E. Performance des représentants commerciaux (Sales Rep)
-- SELECT sales_rep, ROUND(SUM(total_revenue), 2) as revenue
-- FROM vw_orders_analytics
-- GROUP BY sales_rep
-- ORDER BY revenue DESC;
