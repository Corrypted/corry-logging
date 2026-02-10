fx_version 'cerulean'
game 'gta5'

author 'Corry'
description 'corry_logs - Standalone Logging System for FiveM'
version '1.0.0'

shared_scripts {
    'config/config.lua',
    '@ox_lib/init.lua',
    'bridge/*.lua'
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    --'@oxmysql/lib/MySQL.lua', -- remove if not using oxmysql
    'server/main.lua',
}

ui_page 'html/ui.html'
files {
    'html/ui.html',
    'html/css/style.css',
    'html/js/app.js'
}

-- Optional: ignore files from FiveM escrow
-- escrow_ignore {
--     'config.lua'
-- }