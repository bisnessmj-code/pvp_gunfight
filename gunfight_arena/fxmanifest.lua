shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

-- Importation recommandée pour ESX
shared_script '@es_extended/imports.lua'

description 'Gunfight Arena - v3.2 avec Bridge d\'Inventaire (compatible qs-inventory, ox_inventory, qb-inventory)'
author 'kichta'
version '3.2.0'

shared_script 'config.lua'

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'bridge_inventory.lua',        -- ✅ NOUVEAU : Bridge d'inventaire
    'client.lua',
    'custom_revive.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'bridge_inventory_server.lua',  -- ✅ NOUVEAU : Bridge d'inventaire serveur
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/zone1.png',
    'html/images/zone2.png',
    'html/images/zone3.png',
    'html/images/zone4.png',
    'html/images/default.png'
}

dependencies {
    'es_extended',
    'PolyZone'
}

-- Dépendances optionnelles (inventaires)
-- Aucune n'est requise, le bridge détecte automatiquement
