-- ==========================================
-- SCRIPT D'INITIALISATION : EPIC 01
-- Projet : SoumiaTech Data Pipeline
-- ==========================================

-- NOTE: Exécutez d'abord la création de la base de données si elle n'existe pas.
-- CREATE DATABASE soumiatech_db;

-- Basculer sur la base soumiatech_db avant d'exécuter la suite
-- \c soumiatech_db

-- Suppression des tables existantes pour repartir à zéro
DROP TABLE IF EXISTS fact_orders CASCADE;
DROP TABLE IF EXISTS dim_clients CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS staging_orders CASCADE;

-- 1. Création de la table de Staging (Données Brutes)
-- On utilise le type TEXT pour tout pour garantir que l'importation ne plante jamais.
CREATE TABLE staging_orders (
    order_id TEXT,
    client_id TEXT,
    client_name TEXT,
    product_id TEXT,
    product_name TEXT,
    quantity TEXT,
    unit_price TEXT,
    order_date TEXT,
    delivery_date TEXT,
    status TEXT,
    region TEXT,
    sales_rep TEXT,
    operational_data TEXT
);

COMMENT ON TABLE staging_orders IS 'Table tampon pour l ingestion brute des fichiers Excel/CSV';

-- 2. Création des tables de Dimension (Modèle en Étoile)
CREATE TABLE dim_clients (
    client_key SERIAL PRIMARY KEY,
    client_id VARCHAR(50) UNIQUE NOT NULL,
    client_name VARCHAR(255) NOT NULL
);

CREATE TABLE dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL
);

-- 3. Création de la table de Faits
CREATE TABLE fact_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    client_key INT NOT NULL REFERENCES dim_clients(client_key),
    product_key INT NOT NULL REFERENCES dim_products(product_key),
    quantity INT,
    unit_price NUMERIC(10, 2),
    order_date DATE,
    delivery_date DATE,
    status VARCHAR(50),
    region VARCHAR(50),
    sales_rep VARCHAR(255),
    operational_data JSONB -- Stockage optimisé pour le JSON
);

-- 4. Création d'index pour optimiser les futures requêtes
CREATE INDEX idx_fact_orders_date ON fact_orders(order_date);
CREATE INDEX idx_fact_orders_client ON fact_orders(client_key);
CREATE INDEX idx_fact_orders_product ON fact_orders(product_key);
CREATE INDEX idx_fact_orders_region ON fact_orders(region);

-- Message de confirmation (si exécuté via psql)
-- DO $$ BEGIN RAISE NOTICE 'Initialisation de l Epic 01 terminée avec succès.'; END $$;
