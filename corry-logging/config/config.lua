config = {}

config.debug = true -- Set to true to enable debug prints

config.admins = {
    'license:48c794dbb03fa8ca60601b379150f25452a5b20c',
}

config.deleteLogPermissions = {
    'license:48c794dbb03fa8ca60601b379150f25452a5b20c',
}

config.notify = 'ox_lib' -- 'ox_lib', 'boii_ui', 'okokNotify', 'es_extended', or 'qb-core', 'standalone'
config.framework = 'qb-core' --     "es_extended", "ND_Core", "ox_core", "qbx_core", "qb-core",

config.openCommand = 'checkLogs' -- Command to open the logging menu
config.maxUiLogs = 10 -- Max logs shown in the UI

config.levels = {
    ['INFO'] = { label = 'Info', color = '#3498db' },
    ['WARN'] = { label = 'Warning', color = '#f1c40f' },
    ['ERROR'] = { label = 'Error', color = '#e74c3c' },
    ['INVENTORY'] = { label = 'Inventory', color = '#2ecc71' },
}

--[[
    -- Server-side (any resource)
        exports['corry-logging']:AddLog({
            level = 'INFO',
            message = 'Server started.'
        })

-- Client-side (any resource)
        @param level string - Log level (e.g. 'INFO', 'WARN', 'ERROR')
        @param message string - Log message
        @param notify boolean - Whether to send a notification to admins - optional, defaults to false
        exports['corry-logging']:AddLog(level, message, notify)
        exports['corry-logging']:AddLog('WARN', 'Player attempted restricted action.')
]]