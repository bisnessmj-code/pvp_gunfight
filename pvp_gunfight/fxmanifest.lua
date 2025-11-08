fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'PVP GunFight'
description 'Système PVP GunFight avec matchmaking et ELO - v2.0'
version '2.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}