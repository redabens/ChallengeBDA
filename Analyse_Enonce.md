# Analyse de l'Énoncé - Challenge BDA

## Contexte
Vous avez été recruté en tant que **Junior Data Engineer** chez **SoumiaTech Solutions**, une entreprise technologique gérant des commandes de produits et des opérations clients à travers plusieurs bureaux régionaux.

## Problématique
L'entreprise migre son système legacy vers une nouvelle base de données relationnelle **PostgreSQL**. Un volume important de données historiques doit être transféré à partir d'un export de fichiers plats (Flat-file).

## Caractéristiques du Fichier Source
- **Format** : Fichier plat (export généré automatiquement).
- **État** : Non nettoyé, non validé, non documenté.
- **Schéma** : Aucun document de schéma ni dictionnaire de données n'est fourni. Vous devez déduire la structure vous-même.

## Exigences Techniques
1. **Conception de la Base de Données** : Concevoir les objets de base de données appropriés (tables, types, contraintes).
2. **Pipeline d'Importation** :
    - Entièrement automatisé à l'aide de **SQL**.
    - Conçu comme un processus **récurrent quotidien** (et non un import ponctuel).
    - Le fichier arrive chaque jour à **06h00** sur le serveur.
3. **Gestion des Données** :
    - Réfléchir à l'accumulation des données dans les tables cibles.
    - Gérer le déclenchement automatique sans intervention manuelle.
    - Prévoir le comportement en cas d'erreur ou d'échec du traitement.
4. **Couche d'Accès (Wrangling)** :
    - Proposer une solution de Data Wrangling.
    - Créer une couche permettant aux utilisateurs **non experts en JSON** d'interroger les tables facilement (ce qui implique l'extraction et l'aplatissement des champs JSON).

## Livrable Attendu
Une solution complète de data wrangling et un pipeline d'importation robuste vers PostgreSQL.
