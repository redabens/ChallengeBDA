# Backlog de Développement - Projet SoumiaTech Data Pipeline

Ce backlog détaille les étapes nécessaires pour répondre aux exigences du challenge.

## Epic 1 : Infrastructure & Modélisation (Setup)
*Objectif : Mettre en place l'environnement PostgreSQL et définir le schéma cible.*

- **[TASK-01] Provisionnement de la base PostgreSQL** : Installer et configurer l'instance PostgreSQL locale ou cloud.
- **[TASK-02] Conception du Schéma Relationnel** :
    - Table `raw_orders` : Pour le stockage temporaire (staging) des données brutes (tout en TEXT).
    - Table `dim_clients` : Stockage unique des clients (SCD Type 1).
    - Table `dim_products` : Stockage unique des produits.
    - Table `fact_orders` : Table de faits principale avec les types de données corrigés (DATE, NUMERIC, JSONB).
- **[TASK-03] Script DDL Initial** : Création des tables, index et contraintes de clés étrangères.

## Epic 2 : Data Wrangling & Nettoyage (ETL Logic)
*Objectif : Transformer les données sales en données de qualité.*

- **[TASK-04] Nettoyage des Dates** : Créer une fonction SQL capable de parser les différents formats identifiés (`ISO` et `DD/MM/YYYY`).
- **[TASK-05] Validation JSON** : Implémenter une logique de robustesse pour gérer les JSON tronqués (ex: ignorer ou extraire ce qui est possible).
- **[TASK-06] Casting & Normalisation** : Convertir les colonnes `quantity` en INTEGER et `unit_price` en NUMERIC(10,2).
- **[TASK-07] Déduplication** : Gérer les doublons potentiels lors de l'accumulation quotidienne (UPSERT logic sur `order_id`).

## Epic 3 : Automatisation du Pipeline (Pipeline & Scheduling)
*Objectif : Assurer que le pipeline tourne tous les jours à 6h00 sans intervention.*

- **[TASK-08] Script d'Import SQL (COPY)** : Automatiser l'ingestion du fichier Excel/CSV vers la table de staging.
- **[TASK-09] Procédure Stockée de Transformation** : Encapsuler toute la logique de nettoyage (Epic 2) dans une procédure `sp_process_daily_import()`.
- **[TASK-10] Ordonnancement (Scheduling)** :
    - Option A : Utiliser `pg_cron` (si extension disponible).
    - Option B : Utiliser un script Bash + `crontab` (Windows Task Scheduler si sous Windows).
- **[TASK-11] Journalisation & Alertes** : Créer une table `pipeline_logs` pour suivre les succès/échecs et envoyer une alerte si le fichier de 6h00 est absent.

## Epic 4 : Couche Analytique (User Layer)
*Objectif : Permettre aux non-experts d'interroger facilement les données.*

- **[TASK-12] Vue SQL Aplatie (`vw_orders_analytics`)** : Créer une vue qui extrait les champs du JSON `operational_data` vers des colonnes réelles :
    - `shipping_method`
    - `shipping_priority`
    - `is_international`
    - `device_platform`
- **[TASK-13] Documentation du Schéma** : Générer un mini-dictionnaire de données pour les utilisateurs finaux.
- **[TASK-14] Requêtes de Test/Validation** : Préparer des rapports types (CA par région, top produits, etc.).

---

## Roadmap Prioritaire (Phase 1)
1. **Jour 1** : [TASK-01] à [TASK-03] (Infrastructure & DDL).
2. **Jour 2** : [TASK-04] à [TASK-07] (Wrangling & Cleaning).
3. **Jour 3** : [TASK-08] à [TASK-11] (Automatisation).
4. **Jour 4** : [TASK-12] à [TASK-14] (Analytics & Delivery).
