# Epic 04 : Couche Analytique (User Layer)

L'objectif de cet Epic est de rendre les données stockées dans le modèle de faits (fact_orders) et de dimensions accessibles et faciles à interroger pour des utilisateurs non-experts en SQL ou en JSON.

## [TASK-12] Vue SQL Aplatie (`vw_orders_analytics`)
**Problématique** : Le champ `operational_data` contient des informations cruciales (shipping method, device, flags) mais elles sont "cachées" dans un format JSONB complexe.

**Solution technique** : Créer une vue SQL qui expose ces champs comme des colonnes normales.
- **Champs à extraire** :
    - `shipping_method` (via `operational_data -> 'shipping' ->> 'method'`)
    - `shipping_priority` (via `(operational_data -> 'shipping' ->> 'priority')::INT`)
    - `device_platform` (via `operational_data -> 'device' ->> 'platform'`)
    - `is_bulk` (via `(operational_data -> 'flags' ->> 'is_bulk')::BOOLEAN`)
    - `is_international` (via `(operational_data -> 'flags' ->> 'is_international')::BOOLEAN`)

---

## [TASK-13] Documentation du Schéma
**Objectif** : Fournir aux collègues un dictionnaire de données simple pour savoir quelle table interroger.

**Contenu du dictionnaire :**
1. **`vw_orders_analytics`** : La vue principale pour tous les rapports de vente.
2. **`dim_clients`** : Pour les analyses par client.
3. **`dim_products`** : Pour les analyses par produit.
4. **`pipeline_logs`** : Pour vérifier la santé du système.

---

## [TASK-14] Requêtes de Test & Rapports Types
**Objectif** : Fournir des exemples de requêtes SQL prêtes à l'emploi pour les besoins business courants.

**Exemples :**
- **Top 5 des produits par chiffre d'affaires.**
- **Répartition des ventes par région.**
- **Analyse des méthodes d'expédition préférées.**
- **Taux de commandes internationales.**

---

## Livrables de l'Epic 04
1. **Script SQL de création de vue** : `analytics_layer_epic04.sql`.
2. **Rapport de validation** : Résultat des requêtes types sur les 5000 lignes importées.

### Exemple de création de vue :
```sql
CREATE VIEW vw_orders_analytics AS
SELECT 
    f.order_id,
    c.client_name,
    p.product_name,
    f.quantity,
    f.unit_price,
    (f.quantity * f.unit_price) AS total_revenue,
    f.order_date,
    f.status,
    f.region,
    f.operational_data -> 'shipping' ->> 'method' AS shipping_method,
    f.operational_data -> 'device' ->> 'platform' AS device_platform
FROM fact_orders f
JOIN dim_clients c ON f.client_key = c.client_key
JOIN dim_products p ON f.product_key = p.product_key;
```
