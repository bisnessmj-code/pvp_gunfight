-- Mise à jour de la table pvp_stats pour ajouter les colonnes manquantes
ALTER TABLE `pvp_stats` 
ADD COLUMN IF NOT EXISTS `name` VARCHAR(50) DEFAULT 'Joueur' AFTER `identifier`,
ADD COLUMN IF NOT EXISTS `kills` INT UNSIGNED DEFAULT 0 AFTER `losses`,
ADD COLUMN IF NOT EXISTS `deaths` INT UNSIGNED DEFAULT 0 AFTER `kills`;

-- Mettre à jour les noms manquants
UPDATE `pvp_stats` SET `name` = 'Joueur' WHERE `name` IS NULL OR `name` = '';