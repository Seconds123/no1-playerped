fx_version 'cerulean'
game 'gta5'

author 'PlayerNo1'
description 'A player ped script'
version '2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/peds.lua'
}

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua', 
    'server/main.lua'
}

files {
    'locales/en.json'
}

lua54 'yes'

dependency 'ox_lib'