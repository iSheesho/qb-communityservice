fx_version 'adamant'

game 'gta5'

description 'Community service. Converted from ESX to QBCore'

author 'Sheesho // Apostolos_Iatridis'

version '1.1'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'locale.lua',
	'locales/en.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'locale.lua',
	'locales/en.lua',
	'config.lua',
	'client/main.lua'
}

