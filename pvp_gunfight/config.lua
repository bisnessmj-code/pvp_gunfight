Config = {}

-- Configuration du PED
Config.PedLocation = {
    coords = vector4(-2659.147216, -762.514282, 5.993408, 192.75590), -- Coordonnées devant le commissariat (exemple)
    model = 's_m_y_dealer_01', -- Modèle du PED
    scenario = 'WORLD_HUMAN_CLIPBOARD' -- Animation du PED
}

Config.InteractionDistance = 2.5 -- Distance pour interagir avec le PED
Config.DrawMarker = true -- Afficher un marker au sol

-- Configuration des arènes
Config.Arenas = {
    ['arena_industrial_1'] = {
        name = "Zone Industrielle #1",
        teamA = {
            vector4(463.107696, -1668.487916, 29.313598, 240.944886),
            vector4(464.597808, -1667.208740, 29.313598, 294.803162),
            vector4(462.224182, -1670.769288, 29.313598, 138.897628),
            vector4(460.918670, -1666.180176, 29.161866, 325.984252)
        },
        teamB = {
            vector4(486.013184, -1686.421998, 29.161866, 300.472442),
            vector4(483.969238, -1688.386840, 29.178710, 136.062988),
            vector4(486.896698, -1683.837402, 29.229248, 323.149598),
            vector4(487.450562, -1688.254882, 29.128174, 243.779526)
        }
    },
    ['arena_industrial_2'] = {
        name = "Zone Industrielle #2",
        teamA = {
            vector4(560.202210, -1788.725220, 29.195556, 306.141724),
            vector4(558.408814, -1788.039550, 29.195556, 79.370080),
            vector4(556.417602, -1786.654908, 29.195556, 14.173228),
            vector4(556.707702, -1791.679078, 29.195556, 8.503936)
        },
        teamB = {
            vector4(565.885742, -1769.960450, 29.330444, 144.566926),
            vector4(562.799988, -1771.173584, 29.347290, 130.393708),
            vector4(564.791198, -1766.901124, 29.145020, 192.755906),
            vector4(567.758240, -1768.720826, 29.145020, 212.598420)
        }
    }
}

-- Configuration des loadouts
Config.Loadouts = {
    ['classic'] = {
        name = "Classique",
        weapons = {
            {name = 'WEAPON_PISTOL', ammo = 50},
            {name = 'WEAPON_KNIFE', ammo = 1}
        }
    },
    ['assault'] = {
        name = "Assaut",
        weapons = {
            {name = 'WEAPON_ASSAULTRIFLE', ammo = 100},
            {name = 'WEAPON_PISTOL', ammo = 30}
        }
    }
}

-- Configuration des rounds
Config.RoundTime = 180 -- Temps par round en secondes
Config.MaxRounds = 5 -- Nombre de rounds pour gagner
Config.RespawnDelay = 5 -- Délai avant respawn (secondes)

-- Configuration ELO
Config.StartingELO = 1000
Config.KFactor = 32 -- Facteur K pour le calcul ELO