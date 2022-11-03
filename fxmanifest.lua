fx_version 'cerulean'
game 'gta5'

description 'qw-risingsuns'
version '0.1.0'
author 'qwadebot'

server_script {
    '@oxmysql/lib/MySQL.lua',
	'server/*.lua',
}

client_scripts { 
    'client/*.lua',
    '@PolyZone/client.lua',
	'@PolyZone/PolyZone.lua',
}
shared_scripts { 'config.lua' }

lua54 'yes'