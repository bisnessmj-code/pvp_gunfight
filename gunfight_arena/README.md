# Gunfight Arena - Version 3.0

## Nouveau dans cette version 3.0 :

### ✅ PED au lobby
- Un PNJ remplace le marqueur circulaire au point d'interaction
- Modèle par défaut : vendeur d'armes (`s_m_y_ammucity_01`)
- Animation : garde debout
- Configurable dans `config.lua`

### ✅ Spawn aléatoire
- Plus de spawn fixe à l'entrée de la zone
- Les joueurs spawn directement à un point aléatoire parmi les `respawnPoints`
- Évite les collisions entre joueurs au spawn

### ✅ Gestion des instances
- Sortie de zone : retire automatiquement de l'instance ✓
- Commande `/quittergf` : retire de l'instance ✓
- Déconnexion : nettoyage automatique ✓

## Installation

### Prérequis
- **es_extended** (ESX Framework)
- **PolyZone** (gestion des zones)
- **mysql-async** (base de données)

### Étapes

1. **Placez le dossier** `gunfight_arena` dans votre répertoire `resources/`

2. **Créez la table MySQL** :
```sql
CREATE TABLE IF NOT EXISTS `gunfight_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `kills` int(11) NOT NULL DEFAULT 0,
  `deaths` int(11) NOT NULL DEFAULT 0,
  `headshots` int(11) NOT NULL DEFAULT 0,
  `best_streak` int(11) NOT NULL DEFAULT 0,
  `total_playtime` int(11) NOT NULL DEFAULT 0,
  `last_played` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

3. **Ajoutez dans votre `server.cfg`** :
```cfg
ensure gunfight_arena
```

4. **Redémarrez votre serveur**

## Configuration

### PED du lobby
Dans `config.lua`, section `Config.LobbyPed` :
```lua
Config.LobbyPed = {
    enabled = true,
    model = "s_m_y_ammucity_01",          -- Modèle du PED
    pos = vector3(-419.907684, 1129.648316, 324.904052),
    heading = 73.70079,
    frozen = true,
    invincible = true,
    blockevents = true,
    scenario = "WORLD_HUMAN_GUARD_STAND"  -- Animation
}
```

### Zones
Chaque zone a maintenant :
- `center` : position centrale (pour le marqueur et PolyZone)
- `respawnPoints` : tableau de points de spawn aléatoires
- `image` : image pour l'UI

**Remarque** : Le champ `spawn` (spawn initial) a été supprimé au profit du spawn aléatoire.

### Instances (Routing Buckets)
```lua
Config.UseInstances = true  -- Active/désactive les instances
Config.ZoneBuckets = {
    [1] = 100,  -- Zone 1 = bucket 100
    [2] = 200,  -- Zone 2 = bucket 200
    [3] = 300,  -- Zone 3 = bucket 300
    [4] = 400   -- Zone 4 = bucket 400
}
```

## Utilisation

### Rejoindre l'arène
1. Rendez-vous au PED du lobby (marqué sur la carte)
2. Appuyez sur **E** pour ouvrir le menu
3. Sélectionnez une zone
4. Vous serez téléporté à un point aléatoire dans la zone

### Quitter l'arène
- **Méthode 1** : Sortez de la zone (téléportation automatique au lobby)
- **Méthode 2** : Utilisez la commande `/quittergf`

### Leaderboard
- **En jeu** : Appuyez sur **Suppr (pavé numérique)** pour afficher le classement
- **Au lobby** : Cliquez sur "MES STATS" ou "TOP PLAYERS" dans l'interface

## Fonctionnalités

- ✅ **4 zones configurables**
- ✅ **Spawn aléatoire** pour éviter les collisions
- ✅ **PED d'interaction** au lobby
- ✅ **Système d'instances** (routing buckets)
- ✅ **Kill feed en temps réel**
- ✅ **Statistiques** (kills, deaths, K/D, streaks, headshots)
- ✅ **Récompenses** et bonus de kill streak
- ✅ **Stamina infinie**
- ✅ **Invincibilité temporaire** au spawn
- ✅ **Classement global** sauvegardé en base de données

## Commandes

| Commande | Description |
|----------|-------------|
| `/quittergf` | Quitter l'arène manuellement |
| `/testmort` | Tester la mort (dev) |
| `/testkillfeed` | Tester le kill feed (dev) |
| `/gfdebug` | Afficher les infos de debug (console) |
| `/gfkick [playerID]` | Retirer un joueur de l'arène (admin) |

## Debug

Pour activer les logs de debug :
```lua
Config.DebugClient = true  -- Logs côté client (F8)
Config.DebugServer = true  -- Logs côté serveur (console)
```

## Support

- **Version** : 3.0.0
- **Auteur** : kichta
- **Framework** : ESX

## Changelog

### Version 3.0.0 (2025)
- ✨ Ajout du PED au lobby
- ✨ Spawn aléatoire dans les zones
- ✨ Suppression du spawn initial fixe
- ✅ Vérification de la gestion des instances
- 📝 Documentation mise à jour

### Version 2.0.0
- ✨ Système d'instances (routing buckets)
- ✨ Kill feed
- ✨ Statistiques en base de données
- ✨ Classement global

### Version 1.0.0
- 🎉 Version initiale
