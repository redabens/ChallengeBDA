# Epic 01 : Infrastructure & Modélisation (Setup)

Cet Epic se concentre sur la mise en place de la fondation technique du projet SoumiaTech. L'objectif est de créer un environnement PostgreSQL capable de recevoir les données brutes et de les structurer efficacement.

## [TASK-01] Provisionnement de la base PostgreSQL
**Objectif** : Avoir une instance PostgreSQL opérationnelle.

**Actions à réaliser :**
1. Installer PostgreSQL (v14+) en local ou utiliser un service managé (Supabase, AWS RDS, Docker).
2. Créer une base de données nommée `soumiatech_db`.
3. Créer un utilisateur dédié `data_engineer` avec les droits de création de schémas.

---

## [TASK-02] Conception du Schéma Relationnel
Nous adoptons une architecture **Medallion modifiée** (Staging -> Core).

### A. Zone de Staging (`raw_orders`)
Cette table doit accepter toutes les données du fichier Excel sans aucune validation pour éviter les échecs d'importation.
- **Colonnes** : Toutes en `TEXT`.
- **Nom** : `staging_orders`.

### B. Zone Core (Modèle en Étoile)
- **Table `dim_clients`** :
    - `client_key` (SERIAL PK)
    - `client_id` (VARCHAR 50, Unique)
    - `client_name` (VARCHAR 255)
- **Table `dim_products`** :
    - `product_key` (SERIAL PK)
    - `product_id` (VARCHAR 50, Unique)
    - `product_name` (VARCHAR 255)
- **Table `fact_orders`** :
    - `order_id` (VARCHAR 50 PK)
    - `client_key` (FK)
    - `product_key` (FK)
    - `quantity` (INT)
    - `unit_price` (NUMERIC 10,2)
    - `order_date` (DATE)
    - `delivery_date` (DATE)
    - `status` (VARCHAR 20)
    - `region` (VARCHAR 50)
    - `sales_rep` (VARCHAR 100)
    - `operational_data` (JSONB)

---

## [TASK-03] Script DDL Initial
Voici le script à exécuter pour initialiser la structure :

```sql
-- Suppression si existant (pour le dev)
DROP TABLE IF EXISTS fact_orders;
DROP TABLE IF EXISTS dim_clients;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS staging_orders;

-- 1. Table de Staging
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

-- 2. Dimensions
CREATE TABLE dim_clients (
    client_key SERIAL PRIMARY KEY,
    client_id VARCHAR(50) UNIQUE NOT NULL,
    client_name VARCHAR(255)
);

CREATE TABLE dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255)
);

-- 3. Faits
CREATE TABLE fact_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    client_key INT REFERENCES dim_clients(client_key),
    product_key INT REFERENCES dim_products(product_key),
    quantity INT,
    unit_price NUMERIC(10,2),
    order_date DATE,
    delivery_date DATE,
    status VARCHAR(50),
    region VARCHAR(50),
    sales_rep VARCHAR(255),
    operational_data JSONB
);

-- Index pour la performance
CREATE INDEX idx_fact_orders_date ON fact_orders(order_date);
CREATE INDEX idx_fact_orders_client ON fact_orders(client_key);
```

**Livrable** : Exécution réussie de ce script dans l'environnement PostgreSQL.
