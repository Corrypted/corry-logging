local resourceName = GetCurrentResourceName()
local logFile = 'logs.json'

local function isAdmin(src, typea)
    local PlayerData = bridge.get_player(src)
    if not PlayerData then return false end
    
    local license = GetPlayerIdentifierByType(src, 'license')
    local citizenid = bridge.get_player_id(src)
    
    if typea == 'delete' then
        for _, admin in ipairs(config.deleteLogPermissions) do
            if admin == license or admin == citizenid then
                return true
            end
        end
        return false
    elseif typea == 'admin' then
        for _, admin in ipairs(config.admins) do
            if admin == license or admin == citizenid then
                return true
            end
        end
        return false
    end
    
    return false
end

lib.callback.register('corry-logging:server:checkAdmin', function(source, typea)
    return isAdmin(source, typea)
end)

local function readLogs()
	local raw = LoadResourceFile(resourceName, logFile)
	if not raw or raw == '' then
		SaveResourceFile(resourceName, logFile, '[]', -1)
		return {}
	end

	local decoded = json.decode(raw)
	if type(decoded) ~= 'table' then
		SaveResourceFile(resourceName, logFile, '[]', -1)
		return {}
	end

	local changed = false
	local seen = {}
	for i = 1, #decoded do
		local id = decoded[i].id
		if not id or seen[id] then
			decoded[i].id = string.format('%d-%d', os.time(), math.random(100000, 999999))
			changed = true
		end
		seen[decoded[i].id] = true
	end
	if changed then
		SaveResourceFile(resourceName, logFile, json.encode(decoded), -1)
	end

	return decoded
end

local function writeLogs(logs)
	SaveResourceFile(resourceName, logFile, json.encode(logs or {}), -1)
end

local function trim(value)
	return (tostring(value or ''):gsub('^%s*(.-)%s*$', '%1'))
end

local function buildClientInfo(src)
	local identity = bridge.get_identity and bridge.get_identity(src) or nil
	local rpName = ''
	if identity then
		rpName = trim((identity.first_name or '') .. ' ' .. (identity.last_name or ''))
	end

	return {
		id = src,
		name = GetPlayerName(src) or 'Unknown',
		rpName = rpName,
		license = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifierByType(src, 'license2') or '',
		citizenId = bridge.get_player_id and bridge.get_player_id(src) or ''
	}
end

local function addLogEntry(entry, src)
	local logs = readLogs()
	local clientInfo = entry and entry.clientInfo or nil
	if entry and entry.source == 'client' and src and src > 0 then
		clientInfo = clientInfo or buildClientInfo(src)
        entrytime = os.date('%d/%m/%y')..' '..os.date('%H:%M:%S')
	end

	local safeEntry = {
		id = string.format('%d-%d', os.time(), math.random(100000, 999999)),
		time = entrytime or os.date('%d/%m/%y')..' '..os.date('%H:%M:%S'),
		level = entry and entry.level or 'INFO',
		message = entry and entry.message or 'Unknown event',
		source = entry and entry.source or 'server',
		notify = entry and entry.notify or false,
		clientInfo = clientInfo
	}

	logs[#logs + 1] = safeEntry
	writeLogs(logs)
	TriggerClientEvent('corry-logging:client:logAdded', -1, safeEntry)
	if safeEntry.notify then
		TriggerClientEvent('corry-logging:client:notifyLog', -1, safeEntry)
	end
end

RegisterNetEvent('corry-logging:server:addLog', function(entry)
	addLogEntry(entry, source)
end)

exports('AddLog', function(entry)
	addLogEntry(entry, nil)
end)

RegisterNetEvent('corry-logging:server:requestLogs', function()
	local src = source
	local pageSize = config.maxUiLogs or 200
	local logs = readLogs()
	local total = #logs
	local totalPages = math.max(1, math.ceil(total / pageSize))
	local startIndex = math.max(total - pageSize + 1, 1)
	local pageLogs = {}
	for i = total, startIndex, -1 do
		pageLogs[#pageLogs + 1] = logs[i]
	end
	TriggerClientEvent('corry-logging:client:receivePage', src, pageLogs, 0, totalPages, total)
end)

RegisterNetEvent('corry-logging:server:requestPage', function(page, pageSize)
	local src = source
	local size = tonumber(pageSize) or (config.maxUiLogs or 200)
	if size < 1 then
		size = config.maxUiLogs or 200
	end

	local logs = readLogs()
	local total = #logs
	local totalPages = math.max(1, math.ceil(total / size))
	local pageIndex = math.max(0, math.min(tonumber(page) or 0, totalPages - 1))
	local stopIndex = total - (pageIndex * size)
	local startIndex = math.max(stopIndex - size + 1, 1)
	local pageLogs = {}

	if stopIndex >= 1 then
		for i = stopIndex, startIndex, -1 do
			pageLogs[#pageLogs + 1] = logs[i]
		end
	end

	TriggerClientEvent('corry-logging:client:receivePage', src, pageLogs, pageIndex, totalPages, total)
end)

RegisterNetEvent('corry-logging:server:deleteLog', function(id)
	local src = source
	if not isAdmin(src, 'delete') then
		return
	end

	local logs = readLogs()
	local target = tostring(id or '')
	if target == '' then
		return
	end

	local removed = false
	for i = #logs, 1, -1 do
		if tostring(logs[i].id) == target then
			table.remove(logs, i)
			removed = true
			break
		end
	end

	if removed then
		writeLogs(logs)
		TriggerClientEvent('corry-logging:client:logDeleted', -1, target)
	end
end)

local function matchesQuery(entry, query)
	local term = string.lower(query or '')
	if term == '' then
		return true
	end

	local fields = {
		tostring(entry.time or ''),
		tostring(entry.level or ''),
		tostring(entry.message or ''),
		tostring(entry.source or '')
	}

	if entry.clientInfo then
		fields[#fields + 1] = tostring(entry.clientInfo.name or '')
		fields[#fields + 1] = tostring(entry.clientInfo.rpName or '')
		fields[#fields + 1] = tostring(entry.clientInfo.id or '')
		fields[#fields + 1] = tostring(entry.clientInfo.license or '')
		fields[#fields + 1] = tostring(entry.clientInfo.citizenId or '')
	end

	for i = 1, #fields do
		if string.find(string.lower(fields[i]), term, 1, true) then
			return true
		end
	end

	return false
end

RegisterNetEvent('corry-logging:server:searchLogs', function(query)
	local src = source
	local term = tostring(query or '')
	if term == '' then
		TriggerClientEvent('corry-logging:client:receiveLogs', src, readLogs())
		return
	end

	local logs = readLogs()
	local results = {}
	for i = #logs, 1, -1 do
		if matchesQuery(logs[i], term) then
			results[#results + 1] = logs[i]
		end
	end

	TriggerClientEvent('corry-logging:client:receiveSearchResults', src, results, term)
end)
