fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Mooons'
description 'Enhanced Trash Bin Looting System for QBCore'
version '2.0.0'

shared_script {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'oxmysql'
}
