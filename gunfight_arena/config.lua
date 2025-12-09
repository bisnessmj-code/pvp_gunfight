-- ================================================================================================
-- GUNFIGHT ARENA - CONFIGURATION v3.2 (AVEC BRIDGE INVENTAIRE)
-- ================================================================================================
-- ✅ Auto-join DÉSACTIVÉ (entrée uniquement via PED)
-- ✅ Sortie de zone = nettoyage automatique de l'instance
-- ✅ Configuration du bridge d'inventaire
-- ================================================================================================

Config = {}

-- ================================================================================================
-- DEBUG & LOGS
-- ================================================================================================
Config.Debug = false
Config.DebugClient = false
Config.DebugServer = false
Config.DebugNUI = false
Config.DebugInstance = false

-- ================================================================================================
-- 🆕 CONFIGURATION DU BRIDGE D'INVENTAIRE
-- ================================================================================================
-- Options: "auto", "qs-inventory", "ox_inventory", "qb-inventory", "vanilla"
-- "auto" = détection automatique (recommandé)
Config.InventorySystem = "qs-inventory"

-- Donner les munitions séparément de l'arme (pour certains inventaires)
Config.GiveAmmoSeparately = false

-- Retirer toutes les armes à la sortie (ou seulement celle de l'arène)
Config.RemoveAllWeaponsOnExit = false

-- Types de munitions par arme (pour les inventaires qui les gèrent séparément)
Config.WeaponAmmoTypes = {
    ["weapon_pistol50"] = "ammo-9",           -- qs-inventory
    ["weapon_pistol"] = "ammo-9",
    ["weapon_combatpistol"] = "ammo-9",
    ["weapon_appistol"] = "ammo-9",
    ["weapon_assaultrifle"] = "ammo-rifle",
    ["weapon_carbinerifle"] = "ammo-rifle",
    ["weapon_advancedrifle"] = "ammo-rifle",
    ["weapon_microsmg"] = "ammo-9",
    ["weapon_smg"] = "ammo-9",
    ["weapon_pumpshotgun"] = "ammo-shotgun",
    ["weapon_sawnoffshotgun"] = "ammo-shotgun"
}

-- ================================================================================================
-- SYSTÈME D'INSTANCES (ROUTING BUCKETS)
-- ================================================================================================
Config.UseInstances = true
Config.DefaultBucket = 0
Config.LobbyBucket = 0

Config.ZoneBuckets = {
    [1] = 100,
    [2] = 200,
    [3] = 300,
    [4] = 400
}

-- ================================================================================================
-- CONFIGURATION DU PED DU LOBBY
-- ================================================================================================
Config.LobbyPed = {
    enabled = true,
    model = "s_m_y_ammucity_01",
    pos = vector3(-2658.738526, -769.437378, 5.004760),
    heading = 73.70079,
    frozen = true,
    invincible = true,
    blockevents = true,
    scenario = "WORLD_HUMAN_GUARD_STAND"
}

Config.PedInteractDistance = 2.0
Config.InteractKey = 38

-- ================================================================================================
-- SPAWN DU LOBBY
-- ================================================================================================
Config.LobbySpawn = vector3(-2656.351562, -768.101074, 5.740722)
Config.LobbySpawnHeading = 158.740158

-- ================================================================================================
-- BLIP DU LOBBY
-- ================================================================================================
Config.LobbyBlip = {
    enabled = true,
    sprite = 311,
    color = 1,
    scale = 0.8,
    name = "Gunfight Lobby"
}

-- ================================================================================================
-- ZONE 1
-- ================================================================================================
Config.Zone1 = {
    enabled = true,
    image = "images/zone1.png",
    radius = 65.0,
    center = vector3(178.325272, -1687.437378, 28.850512),
    maxPlayers = 15,
    markerColor = {
        r = 255,
        g = 0,
        b = 0,
        a = 50
    },
    respawnPoints = {
        { pos = vector3(178.325272, -1687.437378, 29.650512), heading = 303.307098 },
        { pos = vector3(170.109894, -1725.243896, 29.279908), heading = 110.551186 },
        { pos = vector3(145.081314, -1702.087890, 29.279908), heading = 206.929122 },
        { pos = vector3(153.969238, -1652.175782, 29.279908), heading = 85.039368 },
        { pos = vector3(180.619782, -1648.931884, 29.802246), heading = 39.685040 },
        { pos = vector3(222.619782, -1674.778076, 29.313598), heading = 325.984252 },
        { pos = vector3(230.426376, -1705.134034, 29.279908), heading = 48.188972 },
        { pos = vector3(230.426376, -1705.134034, 29.279908), heading = 133.228348 },
        { pos = vector3(206.386810, -1686.197754, 29.599976), heading = 42.519684 },
        { pos = vector3(173.340652, -1659.019776, 29.802246), heading = 8.503936 }
    }
}

-- ================================================================================================
-- ZONE 2
-- ================================================================================================
Config.Zone2 = {
    enabled = true,
    image = "images/zone2.png",
    radius = 80.0,
    center = vector3(295.898896, 2857.450440, 42.444702),
    maxPlayers = 15,
    markerColor = {
        r = 255,
        g = 0,
        b = 0,
        a = 50
    },
    respawnPoints = {
        { pos = vector3(295.516480, 2879.050538, 43.619018), heading = 53.858268 },
        { pos = vector3(307.463746, 2894.848388, 43.602172), heading = 14.173228 },
        { pos = vector3(327.415374, 2879.301026, 43.450562), heading = 297.637786 },
        { pos = vector3(335.248352, 2850.250488, 43.416870), heading = 189.921264 },
        { pos = vector3(306.567048, 2823.850586, 44.242432), heading = 136.062988 },
        { pos = vector3(277.648346, 2830.325196, 43.888672), heading = 45.354328 },
        { pos = vector3(270.909882, 2858.901124, 43.619018), heading = 22.677164 },
        { pos = vector3(259.107696, 2876.399902, 43.602172), heading = 76.535438 },
        { pos = vector3(267.876922, 2867.261474, 74.167724), heading = 266.456696 }
    }
}

-- ================================================================================================
-- ZONE 3
-- ================================================================================================
Config.Zone3 = {
    enabled = true,
    image = "images/zone3.png",
    radius = 100.0,
    center = vector3(78.131866, -390.408782, 38.333374),
    maxPlayers = 15,
    markerColor = {
        r = 255,
        g = 0,
        b = 0,
        a = 50
    },
    respawnPoints = {
        { pos = vector3(71.643960, -400.760438, 37.536254), heading = 90.0 },
        { pos = vector3(54.989010, -445.134064, 37.536254), heading = 90.0 },
        { pos = vector3(11.393406, -430.167022, 39.743530), heading = 90.0 },
        { pos = vector3(48.923076, -367.107696, 39.912110), heading = 90.0 },
        { pos = vector3(91.160446, -371.564850, 42.052002), heading = 90.0 },
        { pos = vector3(74.294510, -323.156036, 44.495240), heading = 90.0 },
        { pos = vector3(67.358246, -350.597808, 42.456420), heading = 90.0 },
        { pos = vector3(40.312088, -391.213196, 39.912110), heading = 90.0 }
    }
}

-- ================================================================================================
-- ZONE 4
-- ================================================================================================
Config.Zone4 = {
    enabled = true,
    image = "images/zone4.png",
    radius = 100.0,
    center = vector3(-1693.279174, -2834.571534, 430.912110),
    maxPlayers = 15,
    markerColor = {
        r = 255,
        g = 0,
        b = 0,
        a = 50
    },
    respawnPoints = {
        { pos = vector3(-1685.050538, -2834.993408, 431.114258), heading = 0.0 },
        { pos = vector3(-1673.709838, -2831.973632, 431.114258), heading = 0.0 },
        { pos = vector3(-1700.294556, -2817.507812, 431.114258), heading = 0.0 },
        { pos = vector3(-1698.013184, -2828.268066, 431.114258), heading = 0.0 },
        { pos = vector3(-1697.564820, -2826.909912, 433.759766), heading = 0.0 },
        { pos = vector3(-1692.276978, -2845.793458, 433.759766), heading = 0.0 },
        { pos = vector3(-1689.929688, -2828.545166, 430.928956), heading = 0.0 },
        { pos = vector3(-1698.237304, -2842.575928, 430.928956), heading = 0.0 }
    }
}

-- ================================================================================================
-- ARMES
-- ================================================================================================
Config.WeaponHash = "weapon_pistol50"
Config.WeaponAmmo = 1000

-- ================================================================================================
-- RÉCOMPENSES
-- ================================================================================================
Config.RewardAmount = 5000
Config.RewardAccount = "bank"

Config.KillStreakBonus = {
    enabled = true,
    [3] = 1000,
    [5] = 2500,
    [10] = 5000
}

-- ================================================================================================
-- GAMEPLAY
-- ================================================================================================
Config.InvincibilityTime = 3000
Config.SpawnAlpha = 128
Config.SpawnAlphaDuration = 2000
Config.RespawnDelay = 5000
Config.InfiniteStamina = true

-- ================================================================================================
-- LIMITES
-- ================================================================================================
Config.MaxPlayersTotal = 60

-- ================================================================================================
-- COMMANDES
-- ================================================================================================
Config.ExitCommand = "quittergf"
Config.TestDeathCommand = "testmort"
Config.TestKillFeedCommand = "testkillfeed"

-- ================================================================================================
-- NOTIFICATIONS
-- ================================================================================================
Config.Messages = {
    arenaFull = "L'arène est pleine.",
    enterArena = "^2Vous êtes entré dans l'arène.",
    exitArena = "^1Vous avez quitté l'arène.",
    notInArena = "Vous n'êtes pas dans l'arène.",
    playerDied = "Vous êtes mort. Réapparition effectuée.",
    killRecorded = "Kill enregistré, +$",
    accessStats = "Tu dois être dans l'arène pour accéder aux statistiques.",
    instanceCreated = "^3Instance créée pour la zone",
    instanceJoined = "^3Vous avez rejoint l'instance",
    instanceLeft = "^3Vous avez quitté l'instance"
}

-- ================================================================================================
-- STATISTIQUES & LEADERBOARD
-- ================================================================================================
Config.LeaderboardKey = 183
Config.SaveStatsToDatabase = true
Config.DatabaseUpdateInterval = 60
Config.LeaderboardLimit = 20
Config.LeaderboardUpdateInterval = 30

-- ================================================================================================
-- POLYZONE
-- ================================================================================================
Config.UsePolyZone = true
Config.PolyZoneDebug = false

-- ================================================================================================
-- ⚠️ AUTO-JOIN DÉSACTIVÉ (v3.1)
-- ================================================================================================
-- IMPORTANT : Cette option est DÉSACTIVÉE pour éviter l'entrée automatique dans l'arène.
-- Les joueurs doivent OBLIGATOIREMENT passer par le PED du lobby pour rejoindre une zone.
-- Si vous voulez réactiver l'auto-join, changez cette valeur à true (non recommandé).
Config.AutoJoin = false
Config.AutoJoinCheckInterval = 500

-- ================================================================================================
-- INTERFACE (NUI)
-- ================================================================================================
Config.KillFeed = {
    enabled = true,
    duration = 5000,
    maxMessages = 5
}

-- ================================================================================================
-- PERFORMANCE
-- ================================================================================================
Config.Threads = {
    deathCheck = 0,
    staminaReset = 0,
    zoneMarker = 0,
    pedInteraction = 0,
    zoneCheck = 500,
    autoJoin = 500
}

-- ================================================================================================
-- FIN DE LA CONFIGURATION
-- ================================================================================================
print("^2[Gunfight Arena v3.2-Bridge]^0 Configuration chargée")
print("^3[Gunfight Arena v3.2-Bridge]^0 Auto-join: ^1DÉSACTIVÉ^0 (entrée via PED uniquement)")
print("^3[Gunfight Arena v3.2-Bridge]^0 Instances: " .. (Config.UseInstances and "^2ACTIVÉES" or "^1DÉSACTIVÉES"))
print("^3[Gunfight Arena v3.2-Bridge]^0 Bridge inventaire: ^2" .. (Config.InventorySystem or "auto") .. "^0")
