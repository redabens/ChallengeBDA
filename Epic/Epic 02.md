# Epic 02 : Data Wrangling & Nettoyage (ETL Logic)

Cet Epic est le cœur du projet. L'objectif est de transformer les données brutes et "sales" de la table `staging_orders` vers le modèle final `fact_orders`, en gérant toutes les anomalies identifiées lors de l'analyse initiale.

## [TASK-04] Nettoyage des Dates
**Problématique** : Les dates arrivent dans deux formats différents : `YYYY-MM-DD` (ISO) et `DD/MM/YYYY` (Français/UK).

**Solution technique** : Créer une fonction SQL robuste `fn_clean_date(text_date TEXT)`.
- Elle tentera d'abord un cast direct vers `DATE`.
- En cas d'échec, elle utilisera `to_date(text_date, 'DD/MM/YYYY')`.
- Elle retournera `NULL` pour les valeurs malformées persistantes.

---

## [TASK-05] Validation & Réparation JSON
**Problématique** : Le champ `operational_data` contient des chaînes JSON tronquées ou malformées (ex: `{"shipping": {"method": "express" ...`).

**Solution technique** :
- Utiliser un bloc `TRY...CATCH` (via PL/pgSQL) pour tenter de convertir le texte en `JSONB`.
- Si le JSON est invalide, extraire ce qui est possible via des Regex (si critique) ou marquer la ligne comme "corrompue" dans un champ de log.
- Pour les valeurs `NULL` ou vides, insérer un objet JSON vide `{}` par défaut.

---

## [TASK-06] Casting & Normalisation
**Actions à réaliser :**
1. **Quantités** : Convertir `quantity` (TEXT) en `INT`. Nettoyer les caractères non numériques si nécessaire.
2. **Prix** : Convertir `unit_price` en `NUMERIC(10, 2)`.
3. **Clients & Produits** :
    - Avant de peupler `fact_orders`, nous devons alimenter les tables de dimension `dim_clients` et `dim_products` en utilisant `INSERT INTO ... SELECT DISTINCT ... ON CONFLICT DO NOTHING`.

---

## [TASK-07] Déduplication & UPSERT
**Objectif** : Puisque le pipeline est quotidien, nous pouvons recevoir plusieurs fois la même commande ou des mises à jour de commandes existantes.

**Logique SQL (UPSERT)** :
```sql
INSERT INTO fact_orders (order_id, client_key, product_key, ...)
SELECT ...
FROM staging_orders
ON CONFLICT (order_id) 
DO UPDATE SET 
    status = EXCLUDED.status,
    delivery_date = EXCLUDED.delivery_date,
    operational_data = EXCLUDED.operational_data;
```

---

## Livrables de l'Epic 02
1. **Fonctions SQL de nettoyage** : Scripts pour `fn_clean_date` et `fn_fix_json`.
2. **Procédure de Transformation** : Une procédure `sp_transform_staging_to_core()` qui orchestre le nettoyage et le chargement final.

### Exemple de fonction de nettoyage de date :
```sql
CREATE OR REPLACE FUNCTION fn_clean_date(date_str TEXT) 
RETURNS DATE AS $$
BEGIN
    IF date_str IS NULL OR date_str = '' THEN RETURN NULL; END IF;
    
    -- Tentative format ISO
    BEGIN
        RETURN date_str::DATE;
    EXCEPTION WHEN OTHERS THEN
        -- Tentative format DD/MM/YYYY
        BEGIN
            RETURN to_date(date_str, 'DD/MM/YYYY');
        EXCEPTION WHEN OTHERS THEN
            RETURN NULL;
        END;
    END;
END;
$$ LANGUAGE plpgsql;
```
