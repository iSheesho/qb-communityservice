local QBCore = exports['qb-core']:GetCoreObject()


QBCore.Commands.Add("comserv", _U('give_player_community'), {{name = "id", help = _U('target_id')}, {name = "actions", help = _U('action_count_suggested')}}, false, function(source, args, user)
	local Player = QBCore.Functions.GetPlayer(source)
	if args[1] and GetPlayerName(args[1]) ~= nil and tonumber(args[2]) then
		TriggerEvent('qb-communityservice:sendToCommunityService', tonumber(args[1]), tonumber(args[2]))
	else
		TriggerClientEvent('chat:addMessage', source, { args = { _U('system_msn'), _U('invalid_player_id_or_actions') } } )
	end
end,"admin")

QBCore.Commands.Add("endcomserv", "End Community Service", { { name = "id", help = _U('target_id') } }, false, function(source, args, user)
    local Player = QBCore.Functions.GetPlayer(source)

    if args[1] then
        if args[1] ~= nil then
            TriggerEvent('qb-communityservice:endCommunityServiceCommand', tonumber(args[1]))
        else
            TriggerClientEvent('chat:addMessage', source, { args = { _U('system_msn'), _U('invalid_player_id') } })
        end      
    end
end, "admin")


QBCore.Commands.Add("pcomserv", _U('give_player_community'), { { name = "id", help = _U('target_id') } }, false, function(source, args, user)
    local Player = QBCore.Functions.GetPlayer(source)

    local job = Player.PlayerData.job.name

    if job == Config.PoliceJobName then

	    if args[1] and GetPlayerName(args[1]) ~= nil and tonumber(args[2]) then

		TriggerEvent('qb-communityservice:sendToCommunityService', tonumber(args[1]), tonumber(args[2]))

		else

		TriggerClientEvent('chat:addMessage', source, { args = { _U('system_msn'), _U('invalid_player_id_or_actions') } } )

		end

	end
end, "user")


-- unjail after time served
RegisterServerEvent('qb-communityservice:finishCommunityService')
AddEventHandler('qb-communityservice:finishCommunityService', function()
	releaseFromCommunityService(source)
end)


RegisterServerEvent('qb-communityservice:endCommunityServiceCommand')
AddEventHandler('qb-communityservice:endCommunityServiceCommand', function(source)
	if source ~= nil then
		releaseFromCommunityService(source)
	end
end)


RegisterServerEvent('qb-communityservice:completeService')
AddEventHandler('qb-communityservice:completeService', function()

	local _source = source
	local identifier = QBCore.Functions.GetPlayer(_source).PlayerData.citizenid

		MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)

		if result[1] then
				MySQL.Async.fetchAll('UPDATE communityservice SET actions_remaining = actions_remaining - 1 WHERE identifier = @identifier', {
				['@identifier'] = identifier
			})
		else
			print ("qb-communityservice :: Problem matching player identifier in database to reduce actions.")
		end
	end)
end)


RegisterServerEvent('qb-communityservice:extendService')
AddEventHandler('qb-communityservice:extendService', function()

	local _source = source
	local identifier = QBCore.Functions.GetPlayer(_source).PlayerData.citizenid

		MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)

		if result[1] then
				MySQL.Async.fetchAll('UPDATE communityservice SET actions_remaining = actions_remaining + @extension_value WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@extension_value'] = Config.ServiceExtensionOnEscape
			})
		else
			print ("qb-communityservice :: Problem matching player identifier in database to reduce actions.")
		end
	end)
end)


RegisterServerEvent('qb-communityservice:sendToCommunityService')
AddEventHandler('qb-communityservice:sendToCommunityService', function(target, actions_count)

	local identifier = QBCore.Functions.GetPlayer(target).PlayerData.citizenid

		MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
				MySQL.Async.fetchAll('UPDATE communityservice SET actions_remaining = @actions_remaining WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@actions_remaining'] = actions_count
			})
		else
				MySQL.Async.fetchAll('INSERT INTO communityservice (identifier, actions_remaining) VALUES (@identifier, @actions_remaining)', {
				['@identifier'] = identifier,
				['@actions_remaining'] = actions_count
			})
		end
	end)

	TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_msg', GetPlayerName(target), actions_count) }, color = { 147, 196, 109 } })
	TriggerClientEvent('qb-communityservice:inCommunityService', target, actions_count)
end)


RegisterServerEvent('qb-communityservice:checkIfSentenced')
AddEventHandler('qb-communityservice:checkIfSentenced', function()
	local _source = source -- cannot parse source to client trigger for some weird reason
	local identifier = QBCore.Functions.GetPlayer(_source).PlayerData.citizenid -- get steam identifier

		MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] ~= nil and result[1].actions_remaining > 0 then
			TriggerClientEvent('qb-communityservice:inCommunityService', _source, tonumber(result[1].actions_remaining))
		end
	end)
end)


function releaseFromCommunityService(target)

	local identifier = QBCore.Functions.GetPlayer(target).PlayerData.citizenid
		MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
				MySQL.Async.fetchAll('DELETE from communityservice WHERE identifier = @identifier', {
				['@identifier'] = identifier
			})

			TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_finished', GetPlayerName(target)) }, color = { 147, 196, 109 } })
		end
	end)

	TriggerClientEvent('qb-communityservice:finishCommunityService', target)
end
