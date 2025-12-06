fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'PVP GunFight'
description 'Système PVP GunFight avec matchmaking, ELO et zones de combat - v2.1'
version '2.1.0'

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
