local isVisible = false

local function setUiVisible(state)
	isVisible = state
	SetNuiFocus(state, state)
	SendNUIMessage({ action = 'setVisible', visible = state })
end

local function sendUiConfig()
    SendNUIMessage({
        action = 'setConfig',
        maxLogs = config.maxUiLogs or 200,
        levels = config.levels or {}
    })
end

RegisterCommand(config.openCommand, function()
    lib.callback('corry-logging:server:checkAdmin', false, function(isAdmin)
        print('true')
        if isVisible then
            setUiVisible(false)
            return
        end
        if not isAdmin then
            if config.debug then
                print('corry-logging: Player is not an admin')
            end
            notify.send({type = 'error', header = "Access Denied", message = 'You do not have permission to access the logs.'})
            return
        end

        setUiVisible(true)
        sendUiConfig()
        TriggerServerEvent('corry-logging:server:requestPage', 0, config.maxUiLogs or 200)
    end, 'admin')
end, false)

local function addLog(level, message, notify)
	TriggerServerEvent('corry-logging:server:addLog', {
		level = level,
		message = message,
		source = 'client',
		notify = notify or false
	})
end

exports('AddLog', addLog)

RegisterNetEvent('corry-logging:client:notifyLog', function(entry)
    lib.callback('corry-logging:server:checkAdmin', false, function(isAdmin)
        if not isAdmin then return end
        local message = entry and entry.message or 'New log entry'
        local level = string.lower(entry and entry.level or 'info')
        PlaySoundFrontend(2, 'Pin_Good', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS', true)
        notify.send({ type = level, header = "New Log Entry", message = message })
    end)
end)

RegisterNetEvent('corry-logging:client:receiveLogs', function(logs)
	SendNUIMessage({ action = 'setLogs', logs = logs or {} })
end)

RegisterNetEvent('corry-logging:client:receivePage', function(logs, page, totalPages, total)
    SendNUIMessage({
        action = 'setPage',
        logs = logs or {},
        page = page or 0,
        totalPages = totalPages or 1,
        total = total or 0
    })
end)

RegisterNetEvent('corry-logging:client:receiveSearchResults', function(logs, query)
	SendNUIMessage({ action = 'setSearchResults', logs = logs or {}, query = query or '' })
end)

RegisterNetEvent('corry-logging:client:logAdded', function(entry)
	SendNUIMessage({ action = 'addLog', log = entry or {} })
end)

RegisterNetEvent('corry-logging:client:logDeleted', function(id)
    SendNUIMessage({ action = 'logDeleted', id = id })
end)

RegisterNUICallback('close', function(_, cb)
	setUiVisible(false)
	cb('ok')
end)

RegisterNUICallback('search', function(data, cb)
	TriggerServerEvent('corry-logging:server:searchLogs', data and data.query or '')
	cb('ok')
end)

RegisterNUICallback('clearSearch', function(_, cb)
    TriggerServerEvent('corry-logging:server:requestPage', 0, config.maxUiLogs or 200)
	cb('ok')
end)

RegisterNUICallback('deleteLog', function(data, cb)
    TriggerServerEvent('corry-logging:server:deleteLog', data and data.id or '')
    cb('ok')
end)

RegisterNUICallback('pagePrev', function(data, cb)
    TriggerServerEvent('corry-logging:server:requestPage', data and data.page or 0, config.maxUiLogs or 200)
    cb('ok')
end)

RegisterNUICallback('pageNext', function(data, cb)
    TriggerServerEvent('corry-logging:server:requestPage', data and data.page or 0, config.maxUiLogs or 200)
    cb('ok')
end)

RegisterNUICallback('copyNotify', function(data, cb)
    notify.send({
        type = 'success',
        header = 'Copied',
        message = data and data.message or 'Copied to clipboard.'
    })
    cb('ok')
end)
