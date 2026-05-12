# Analyse Technique des Données

## Fichier : `soumiaTech_orders_export.csv.xlsx`

Après inspection du fichier, voici la structure identifiée et les problèmes de qualité de données relevés.

### 1. Structure des Colonnes

| Nom de Colonne | Description | Type Déduit | Exemple |
| :--- | :--- | :--- | :--- |
| `order_id` | Identifiant unique de la commande | String (Pattern: `ORD-XXXX`) | `ORD-001782` |
| `client_id` | Identifiant du client | String (Pattern: `CLI-XXXX`) | `CLI-0121` |
| `client_name` | Nom de l'entreprise cliente | String | `Offshore Dynamics` |
| `product_id` | Identifiant du produit | String (Pattern: `PRD-XXXX`) | `PRD-0007` |
| `product_name` | Nom du produit | String | `Temperature Unit T3` |
| `quantity` | Quantité commandée | Float / Integer | `413.0` |
| `unit_price` | Prix unitaire | Float | `8651.03` |
| `order_date` | Date de la commande | Date / Datetime | `2022-06-11` |
| `delivery_date`| Date de livraison | Date / String | `2022-11-18` ou `18/07/2023` |
| `status` | État de la commande | String | `confirmed`, `shipped`, `pending` |
| `region` | Région de vente | String | `West`, `Central`, `South`, `East` |
| `sales_rep` | Représentant commercial | String | `James Ford` |
| `operational_data`| Données techniques (JSON) | JSON String / Null | See below |

### 2. Analyse du champ `operational_data` (JSON)
Ce champ contient des informations imbriquées qui doivent être aplaties pour les utilisateurs non-experts.
- **Structure type** :
  ```json
  {
    "shipping": {
      "method": "economy",
      "priority": 2,
      "instructions": "Fragile"
    },
    "device": {
      "fingerprint": "...",
      "platform": "api",
      "version": "3.8.19"
    },
    "flags": {
      "is_bulk": true,
      "is_international": false
    }
  }
  ```

### 3. Problèmes de Qualité de Données (Data Quality Issues)
L'analyse révèle plusieurs "saletés" dans les données, confirmant l'énoncé :
- **Incohérence de format de date** : `delivery_date` contient parfois des objets datetime ISO et parfois des chaînes au format `DD/MM/YYYY`.
- **Données JSON corrompues/tronquées** : Exemple `ORD-001556` où le JSON s'arrête brusquement (`{"shipping": {"method": "express", "priority": 2`). Un parser JSON standard échouera ici.
- **Valeurs manquantes (NULL)** : Certaines lignes ont `operational_data` à `None` (ex: `ORD-001848`).
- **Types flottants pour des entiers** : `quantity` est exporté en tant que float (ex: `413.0`) alors qu'il s'agit d'une quantité discrète.

### 4. Recommandations pour le Schéma PostgreSQL
- Utiliser le type `DATE` pour les colonnes temporelles.
- Utiliser `JSONB` pour `operational_data` afin de bénéficier de l'indexation, mais prévoir un nettoyage préalable.
- Créer des vues SQL (Views) pour aplatir les champs JSON (`shipping_method`, `device_platform`, etc.).
