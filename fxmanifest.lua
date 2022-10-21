fx_version 'cerulean'

game 'gta5'

author 'JACK'

description 'CRIM VARIABLE MANAGMENT'

version '0.1'



client_scripts{
	'@PolyZone/client.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/RemoveZone',
	'streetselling/client.lua',
	'methproduction/client.lua',
	'drugeffects/client.lua',
	'cokeproduction/client.lua',
}

server_scripts{
	'streetselling/server.lua',
	'methproduction/server.lua',
	'drugeffects/server.lua',
	'cokeproduction/server.lua',
}

 shared_scripts {
	'@ph-crimbalance/config.lua',
	'config.lua',
 }

