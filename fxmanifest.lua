fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'C3'
description 'LeaderMenu made for GANG SERVERS!'

files {
    'html/index.html',
    'html/**/**/*.*'
}

ui_page 'html/index.html'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'@mysql-async/lib/MySQL.lua',
    '@async/async.lua',
    'config/*.lua',
    'server/*.lua'
}

client_scripts {
    'config/sh_config.lua',
    'client/main.lua'
}

escrow_ignore {
    'config/*.lua',
    'html/index.html',
    'html/**/**/*.*'
}

export 'inleadermenuc3' -- only client sided

-- exports.ultra_leadermenuc3:inleadermenuc3() | returns true if is in leadermenuc3 and false if not