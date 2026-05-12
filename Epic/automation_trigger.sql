-- ==========================================
-- SCRIPT DE TRIGGER : AUTOMATISATION FINALE
-- Projet : SoumiaTech Data Pipeline
-- ==========================================

-- 1. Création de la fonction qui sera appelée par le Trigger
-- Cette fonction se contente d'appeler notre procédure de transformation existante.
CREATE OR REPLACE FUNCTION fn_trigger_transform()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Trigger activé : Début de la transformation automatique...';
    CALL sp_transform_staging_to_core();
    RAISE NOTICE 'Transformation automatique terminée.';
    RETURN NULL; -- Pour un trigger AFTER STATEMENT, le retour n'a pas d'impact
END;
$$ LANGUAGE plpgsql;

-- 2. Création du Trigger sur la table de Staging
-- On utilise AFTER INSERT et FOR EACH STATEMENT pour que la transformation
-- ne se lance qu'une seule fois, après que TOUT le fichier CSV a été importé.
DROP TRIGGER IF EXISTS trg_after_ingestion ON staging_orders;

CREATE TRIGGER trg_after_ingestion
AFTER INSERT ON staging_orders
FOR EACH STATEMENT
EXECUTE FUNCTION fn_trigger_transform();

-- Message de confirmation
-- DO $$ BEGIN RAISE NOTICE 'Trigger d automatisation créé avec succès sur la table staging_orders.'; END $$;
