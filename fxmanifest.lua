fx_version 'adamant'
game 'gta5'

shared_script 'config.lua'

client_script 'client/*.lua'

server_scripts {
    '@mysql-async/lib/MySQL.lua', -- Remove this if you are on QBCore
    'server/*.lua'
}