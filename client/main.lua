ESX = nil
local isUIopen, isInleadermenuc3, draw, isLBopen, spawned = false
local selected = nil
local lastPos = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent(Config.Settings.ESXStuff.SharedObject, function(object)ESX = object end)
        Citizen.Wait(1)
    end
end)

------------------------------------------------- Events
RegisterNetEvent('c3_leadermenu:quitleadermenuc3')
AddEventHandler('c3_leadermenu:quitleadermenuc3', function()
    if inleadermenuc3() then
        if IsPlayerDead(PlayerPedId()) then
            TriggerEvent(Config.Settings.ESXStuff.Revive)
            SendNUIMessage({action = 'deathscreen', off = true})
        end
        display(false, 'selection')
        display(false, 'stats')
        ESX.Game.Teleport(PlayerPedId(), lastPos, function()
            if Config.Settings.Health.AddHealthOnLeave.Enabled then
                SetEntityHealth(PlayerPedId(), Config.Settings.Health.AddHealthOnLeave.Health)
                SetPedArmour(PlayerPedId(), Config.Settings.Health.AddHealthOnLeave.Armour)
                AddArmourToPed(PlayerPedId(), Config.Settings.Health.AddHealthOnLeave.Armour)
            end
            if Config.Settings.InfiniteAmmo then
                SetPedInfiniteAmmo(PlayerPedId(), false)
            end
        end)
        isInleadermenuc3, draw = false
        selected = nil
        lastPos = nil
        Config.Settings.CLNotify(Config.Settings.Language.Leftleadermenuc3)
    end
end)

RegisterNetEvent('c3_leadermenu:set:pos')
AddEventHandler('c3_leadermenu:set:pos', function(pos)
    ESX.Game.Teleport(PlayerPedId(), pos)
    isInleadermenuc3 = true
end)

RegisterNetEvent('c3_leadermenu:leadermenuc3:healPlayer')
AddEventHandler('c3_leadermenu:leadermenuc3:healPlayer', function()
    SetEntityHealth(PlayerPedId(), Config.Settings.Health.AddHealthOnKill.Health)
    AddArmourToPed(PlayerPedId(), Config.Settings.Health.AddHealthOnKill.Armour)
    SetPedArmour(PlayerPedId(), Config.Settings.Health.AddHealthOnKill.Armour)
end)

RegisterNetEvent('c3_leadermenu:leadermenuc3:hud')
AddEventHandler('c3_leadermenu:leadermenuc3:hud', function()
    ESX.TriggerServerCallback('c3_leadermenu:get:stats', function(data)
        for _, i in pairs(data) do
            SendNUIMessage({
                action = 'stats',
                display = true,
                kills = i.kills,
                deaths = i.deaths,
                kd = string.format('%02.2f', (i.kills / i.deaths))
            })
        end
    end)
end)

------------------------------------------------- Event Handler
AddEventHandler('playerSpawned', function()
    if not spawned then
        ESX.TriggerServerCallback('c3_leadermenu:get:stats', function(data)
            spawned = true
            for _, i in pairs(data) do
                if i.isinleadermenuc3 == 1 and not isInleadermenuc3 then
                    isUIopen, isInleadermenuc3, draw = false
                    Wait(500)
                    ExecuteCommand("quitleadermenuc3")
                end
            end
        end)
        TriggerServerEvent('c3_leadermenu:send:leadermenuc3:html')
        spawned = true
    end
end)

AddEventHandler(Config.Settings.ESXStuff.OnPlayerDeath, function(data)
    if isInleadermenuc3 then
        if data.killerServerId ~= nil then
            local killerPed = GetPlayerPed(data.killerClientId)
            TriggerServerEvent('c3_leadermenu:leadermenuc3:killed', data.killerServerId)
            if Config.Settings.Deathscreen then
                SendNUIMessage({
                    action = 'deathscreen',
                    off = false,
                    notplayer = false,
                    player = GetPlayerName(data.killerClientId),
                    health = (GetEntityHealth(killerPed) / 2),
                    armour = GetPedArmour(killerPed)
                })
            end
        else
            if Config.Settings.Deathscreen then
                SendNUIMessage({
                    action = 'deathscreen',
                    off = false,
                    notplayer = true,
                    lang = Config.Settings.Language.Died
                })
            end
        end
        
        Wait(Config.Settings.RespawnTime * 1000)
        ESX.Game.Teleport(PlayerPedId(), Config.Zone[selected].position[math.random(1, #Config.Zone[selected].position)])
        SendNUIMessage({action = 'deathscreen', off = true})
        TriggerEvent(Config.Settings.ESXStuff.Revive)
        Wait(800)
        TriggerEvent('c3_leadermenu:leadermenuc3:healPlayer')
    end
end)

------------------------------------------------- CMD + KeyMapping
if Config.Settings.CMD.Enabled then
    if Config.Settings.CMD.KeyMapping then
        RegisterKeyMapping(Config.Settings.CMD.Name, 'Open leadermenuc3', 'keyboard', Config.Settings.CMD.Standard)
    end
    RegisterCommand(Config.Settings.CMD.Name, function()
        if not isUIopen and not isInleadermenuc3 and not isLBopen then
            display(true, 'selection')
        end
    end, false)
end

RegisterKeyMapping(Config.Settings.Stats.CMD, 'Open leadermenuc3 Stats', 'keyboard', Config.Settings.Stats.KeyMapping)
RegisterCommand(Config.Settings.Stats.CMD, function()
    if not isLBopen and not isUIopen then
        ESX.TriggerServerCallback('c3_leadermenu:get:all:stats', function(data)
            for _, i in pairs(data) do
                SendNUIMessage({
                    action = 'leaderboard',
                    display = true,
                    number = ("#%s"):format(_),
                    name = i.name,
                    kills = ("Kills: %s"):format(i.kills),
                    deaths = ("deaths: %s"):format(i.deaths),
                })
                isLBopen = true
                display(true)
            end
        end)
    end
end, false)

RegisterCommand('die', function()
    SetEntityHealth(PlayerPedId(), 0)
end, false)
------------------------------------------------- Nui Callbacks
RegisterNUICallback('close', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    isUIopen, isLBopen = false
end)

RegisterNUICallback('join', function(data, cb)
    selected = string.lower(data.zone)
    ESX.TriggerServerCallback('c3_leadermenu:get:count', function(zone)
        if zone[selected].asd == zone[selected].count then
            Config.Settings.CLNotify(Config.Settings.Language.ZoneFull)
        else
            lastPos = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('c3_leadermenu:join:leadermenuc3', selected)
            drawSphere(Config.Zone[selected].middle, Config.Zone[selected].scale)
            TriggerEvent('c3_leadermenu:leadermenuc3:hud')
            if Config.Settings.Health.AddHealthOnEnter.Enabled then
                SetEntityHealth(PlayerPedId(), Config.Settings.Health.AddHealthOnEnter.Health)
                AddArmourToPed(PlayerPedId(), Config.Settings.Health.AddHealthOnEnter.Armour)
                SetPedArmour(PlayerPedId(), Config.Settings.Health.AddHealthOnEnter.Armour)
            end
            if Config.Settings.InfiniteAmmo then
                SetPedInfiniteAmmo(PlayerPedId(), true)
            end
        end
    end)
    display(false, 'selection')
    cb('ok')
end)

------------------------------------------------- functions
function drawSphere(pos, scale)
    draw = true
    notify = false
    CreateThread(function()
        while draw do
            if isInleadermenuc3 then
                DrawSphere(pos, scale, Config.Settings.Color.r, Config.Settings.Color.g, Config.Settings.Color.b, Config.Settings.Color.a)
                if checkSphere(pos, scale) then
                    if Config.Settings.KillPlayerOnZoneLeave then
                        SetEntityHealth(PlayerPedId(), 0)
                    else
                        ESX.Game.Teleport(PlayerPedId(), Config.Zone[selected].position[math.random(1, #Config.Zone[selected].position)])
                    end
                    if not notify then
                        TriggerEvent('notifications', '', 'SISTEM', Config.Settings.Language.Leftleadermenuc3)
                        notify = true
                    end
                else
                    notify = false
                end
            end
            Wait(0)
        end
    end)
end

function checkSphere(pos, scale)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local distance = #(coords - pos)
    
    if distance > scale then
        return true
    end
    
    return false
end

function nearLocation(pos, scale)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    for k, v in pairs(pos) do
        local distance = #(coords - v)
        
        if distance < scale then
            return true
        end
    end
    
    return false
end

function inleadermenuc3()
    return isInleadermenuc3
end

function display(bool, which)
    isUIopen = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({action = which, display = bool})
    ESX.TriggerServerCallback('c3_leadermenu:get:count', function(data)
        if (bool and which == 'selection') then
            for _, i in pairs(data) do
                SendNUIMessage({
                    action = 'zones',
                    name = i.name,
                    img = i.img,
                    lang = Config.Settings.Language.Player,
                    count = ("%s/%s"):format(i.asd, i.count),
                })
            end
        end
    end)
end

function respawn()
    local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)
	local formattedCoords = {
		x = ESX.Math.Round(coords.x, 1),
		y = ESX.Math.Round(coords.y, 1),
		z = ESX.Math.Round(coords.z, 1)
	}
	RespawnPed(playerPed, formattedCoords, 0.0)
end

------------------------------------------------- Main Thread
Citizen.CreateThread(function()
    for _, v in pairs(Config.Settings.Position) do
        local blip = AddBlipForCoord(v)
        SetBlipSprite(blip, Config.Settings.Blip.ID)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Settings.Blip.Scale)
        SetBlipColour(blip, Config.Settings.Blip.Colour)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Settings.Blip.Title)
        EndTextCommandSetBlipName(blip)
        if Config.Settings.Ped.Enable then
            RequestModel(GetHashKey(Config.Settings.Ped.Model))
            while not HasModelLoaded(GetHashKey(Config.Settings.Ped.Model)) do Wait(1) end
            local ped = CreatePed(4, GetHashKey(Config.Settings.Ped.Model), v, 3374176, false, true)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityHeading(ped, 100)
        end
    end
    while true do
        Citizen.Wait(0)
        local letSleep = true
        if nearLocation(Config.Settings.Position, Config.Settings.Marker.DrawDistance) and not isUIopen and not isInleadermenuc3 then
            letSleep = false
            if Config.Settings.Marker.Enable then
                for _, i in pairs(Config.Settings.Position) do
                    DrawMarker(Config.Settings.Marker.Type, i, 0, 0, 0, 0, 0, 0, Config.Settings.Marker.Size.x, Config.Settings.Marker.Size.y, Config.Settings.Marker.Size.z, Config.Settings.Color.r, Config.Settings.Color.g, Config.Settings.Color.b, 175, Config.Settings.Marker.Move, Config.Settings.Marker.RotateToCam, 0)
                end
            end
            if nearLocation(Config.Settings.Position, 1.5) then
                ESX.ShowHelpNotification((Config.Settings.Language.PressE):format("~INPUT_CONTEXT~"))
                if IsControlJustPressed(0, 38) then
                    display(true, 'selection')
                end
            end
        end
        if letSleep then
            Citizen.Wait(500)
        end
    end
end)

-- Citizen.CreateThread(function()
--     while not NetworkIsSessionStarted() do
--         Wait(0)
--     end

--     TriggerServerEvent('c3_leadermenu:send:leadermenuc3:html')
-- end)

RegisterNetEvent('c3_leadermenu:get:leadermenuc3:html')
AddEventHandler('c3_leadermenu:get:leadermenuc3:html', function(html)
    SendNUIMessage({
        ad6brKTUm_asda = "agkdlm3 :_;ad. q3 €µ@@qödm,km,",
        rha6diTZFIOmaduaODP5geub_____asdasd = html
    })
end)