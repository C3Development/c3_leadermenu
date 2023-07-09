ESX = nil
TriggerEvent(Config.Settings.ESXStuff.SharedObject, function(obj)ESX = obj end)
local zones = {}
local isInleadermenuc3 = {}

RegisterCommand(Config.Settings.CMD.Quit, function(s)
	local xPlayer = ESX.GetPlayerFromId(s)
	MySQL.Async.fetchAll('SELECT * FROM leadermenuc3 WHERE identifier=@identifier', {
		['@identifier'] = xPlayer.getIdentifier(),
	}, function(res)
		for _, i in pairs(res) do
			if isInleadermenuc3[s] or i.isinleadermenuc3 == 1 then
				TriggerClientEvent('c3_leadermenu:quitleadermenuc3', s)
				SetPlayerRoutingBucket(s, Config.Settings.MainDim)
				MySQL.Async.execute('UPDATE leadermenuc3 SET name = @name, isinleadermenuc3 = @isinleadermenuc3 WHERE identifier = @identifier', {
					['@name'] = GetPlayerName(s),
					['@isinleadermenuc3'] = 0,
					['@identifier'] = xPlayer.getIdentifier(),
				})
				if not Config.Settings.UseOwnWeapons then
					RemoveAllPedWeapons(s)
					for _, i in pairs(xPlayer.getLoadout()) do
						GiveWeaponToPed(s, GetHashKey(i.name), i.ammo, false, false)
					end
				end
				isInleadermenuc3[s] = false
				if zones[s] ~= nil then
					Config.Zone[zones[s]].asd = Config.Zone[zones[s]].asd - 1
				end
			end
		end
	end)
end, false)

RegisterNetEvent('c3_leadermenu:join:leadermenuc3')
AddEventHandler('c3_leadermenu:join:leadermenuc3', function(zone)
	TriggerClientEvent('c3_leadermenu:set:pos', source, Config.Zone[zone].position[math.random(1, #Config.Zone[zone].position)])
	SetPlayerRoutingBucket(source, Config.Zone[zone].dim)
	if not Config.Settings.UseOwnWeapons then
		RemoveAllPedWeapons(source)
		for _, i in pairs(Config.Zone[zone].weapons) do
			GiveWeaponToPed(source, GetHashKey(i), 100, false, false)
		end
	end
	zones[source] = zone
	isInleadermenuc3[source] = true
	Config.Zone[zone].asd = Config.Zone[zone].asd + 1
end)

RegisterNetEvent('c3_leadermenu:leadermenuc3:killed')
AddEventHandler('c3_leadermenu:leadermenuc3:killed', function(target)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(target)
	MySQL.Async.execute('UPDATE leadermenuc3 SET deaths = deaths + 1 WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.getIdentifier(),
	})
	MySQL.Async.execute('UPDATE leadermenuc3 SET kills = kills + 1 WHERE identifier = @identifier', {
		['@identifier'] = xTarget.getIdentifier(),
	})
	TriggerClientEvent('c3_leadermenu:leadermenuc3:hud', source)
	TriggerClientEvent('c3_leadermenu:leadermenuc3:hud', target)
    if Config.Settings.Health.AddHealthOnKill.Enabled then
		TriggerClientEvent('c3_leadermenu:leadermenuc3:healPlayer', target)
	end
	if Config.Settings.Money.Enabled then
		local money = Config.Settings.Money.Count
		xTarget.addMoney(money)
		Config.Settings.SVNotify(target, (Config.Settings.Language.MoneyMSG):format(GetPlayerName(source), money))
	else
		Config.Settings.SVNotify(target, (Config.Settings.Language.KillerMSG):format(GetPlayerName(source)))
	end
end)

ESX.RegisterServerCallback('c3_leadermenu:get:count', function(src, cb)
	cb(Config.Zone)
end)

ESX.RegisterServerCallback('c3_leadermenu:get:stats', function(src, cb)
	local xPlayer = ESX.GetPlayerFromId(src)
	MySQL.Async.fetchAll('SELECT * FROM leadermenuc3 WHERE identifier=@identifier', {
		['@identifier'] = xPlayer.getIdentifier(),
	}, function(results)
		if #results > 0 then
			cb(results)
			MySQL.Async.execute('UPDATE leadermenuc3 SET name = @name, isinleadermenuc3 = @isinleadermenuc3 WHERE identifier = @identifier', {
				['@name'] = GetPlayerName(src),
				['@isinleadermenuc3'] = 1,
				['@identifier'] = xPlayer.getIdentifier(),
			})
		else
			MySQL.Async.execute('INSERT INTO leadermenuc3(name, isinleadermenuc3, identifier) VALUES (@name, @isinleadermenuc3, @identifier)', {
				['@name'] = GetPlayerName(src),
				['@isinleadermenuc3'] = 1,
				['@identifier'] = xPlayer.getIdentifier(),
			}, function()
				Wait(10)
				MySQL.Async.fetchAll('SELECT * FROM leadermenuc3 WHERE identifier=@identifier', {
					['@identifier'] = xPlayer.getIdentifier(),
				}, function(res)
					cb(res)
				end)
			end)
		end
	end)
end)

ESX.RegisterServerCallback('c3_leadermenu:get:all:stats', function(src, cb)
	MySQL.Async.fetchAll('SELECT * FROM leadermenuc3 ORDER BY kills DESC LIMIT 10', {}, function(res)
		cb(res)
		Wait(50)
	end)
end)