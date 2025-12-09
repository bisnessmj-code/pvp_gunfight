shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'

-- Importation recommandée pour ESX
shared_script '@es_extended/imports.lua'

description 'Gestion d\'Arène Gunfight - Version PED + Spawn Aléatoire'
author 'kichta'
version '3.0.0'

shared_script 'config.lua'

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client.lua',
    'custom_revive.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
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
