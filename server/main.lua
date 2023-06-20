Framework = nil

-- Initialise Locale --
lib.locale()
-----------------------

-- Check script version --
lib.versionCheck('Seconds123/no1-playerped')

-- MySQL queries

local insertTable = 'INSERT INTO no1_playerpeds (`identifier`, `ped`) VALUES (@identifier, @ped)'
local removeTable = 'DELETE FROM no1_playerpeds WHERE `identifier` = @identifier AND `id` = @id'
local updateTable = 'UPDATE no1_playerpeds SET `default` = 1 WHERE `identifier` = @identifier AND `id` = @id'
local cleardefaultTable = 'UPDATE no1_playerpeds SET `default` = 0 WHERE `identifier` = @identifier'

-- Ped Valid Function --
local function IsPedValid(model)
    local valid = false

    if Config.CustomPeds[model] then
        valid = true
    else
        for i=1, #Config.VanillaPeds do
            if model == Config.VanillaPeds[i] then
                valid = true
                break
            end
        end
    end

    return valid
end

-- Commands --
if Config.Framework == 'esx' then
    Framework = exports['es_extended']:getSharedObject()

    Framework.RegisterCommand('setped', 'admin', function(xPlayer, args, showError)
        if args.playerid then
            if args.model then
                if IsPedValid(args.model) then
                    MySQL.Async.insert(insertTable, {['@identifier'] = args.playerid.identifier, ['@ped'] = args.model})
                else
                    TriggerClientEvent('no1-playerped:Notify', xPlayer.source, locale('invalidmodel'), 'error')
                end
            else
                TriggerClientEvent('no1-playerped:GivePedDialogue', xPlayer.source, {
                    playerid = args.playerid.source,
                    name = args.playerid.getName(),
                    identifier = args.playerid.identifier
                })
            end
        else
            TriggerClientEvent('no1-playerped:Notify', xPlayer.source, locale('invalidplayerid'), 'error')
        end
    end, false, {help = locale('command_setped'), validate = false, arguments = {
        {name = 'playerid', help = locale('playerid'), type = 'player'},
        {name = 'model', help = locale('pedmodel'), type = 'string'}
    }})
elseif Config.Framework == 'qb' then
    Framework = exports['qb-core']:GetCoreObject()

    Framework.Commands.Add('setped', locale('command_setped'), { { name = 'playerid', help = locale('playerid') }, { name = 'model', help = locale('model') } }, false, function(source, args)
        local Player = Framework.Functions.GetPlayer(tonumber(args[1]))
        local model = args[2]

        if Player then
            if model ~= nil then
                if IsPedValid(model) then
                    MySQL.Async.insert(insertTable, {['@identifier'] = Player.PlayerData.citizenid, ['@ped'] = model})
                else
                    TriggerClientEvent('no1-playerped:Notify', source, locale('invalidmodel'), 'error')
                end
            else
                TriggerClientEvent('no1-playerped:GivePedDialogue', source, {
                    playerid = Player.PlayerData.source,
                    name = string.format('%s %s', Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname), 
                    identifier = Player.PlayerData.citizenid
                })
            end
        else
            TriggerClientEvent('no1-playerped:Notify', source, locale('invalidplayerid'), 'error')
        end
    end, Config.AdminGroups[1])
end

-- Functions --

local function GetPlayer(playerid)
    if Config.Framework == 'esx' then
        return Framework.GetPlayerFromId(playerid)
    elseif Config.Framework == 'qb' then
        return Framework.Functions.GetPlayer(playerid)
    end
end

local function GetPlayerId(playerid)
    if Config.Framework == 'esx' then
        return Framework.GetPlayerFromId(playerid).identifier
    elseif Config.Framework == 'qb' then
        return Framework.Functions.GetPlayer(playerid).PlayerData.citizenid
    end
end

local function HasPermission(playerid)
    local permission = false

    if Config.Framework == 'esx' then
        local xPlayer = GetPlayer(playerid)
        
        for i=1, #Config.AdminGroups do
            if xPlayer.getGroup() == Config.AdminGroups[i] then
                permission = true
                break
            end
        end
    elseif Config.Framework == 'qb' then
        for i=1, #Config.AdminGroups do
            if Framework.Functions.HasPermission(playerid, Config.AdminGroups[i]) then
                permission = true
                break
            end
        end
    end
    
    return permission
end

local function GetPlayerPeds(id)
    local peds = {}
    local result = MySQL.Sync.fetchAll('SELECT * FROM no1_playerpeds WHERE identifier = @identifier', {
        ['@identifier'] = id
    })

    if result and result[1] then
        for _, v in pairs(result) do
            peds[#peds+1] = v
        end
    end

    return peds
end

-- Callbacks --

lib.callback.register('no1-playerped:GetPlayerPeds', function(source, target)
    local src = target or source
    local playerid = GetPlayerId(src)
    local peds = GetPlayerPeds(playerid)
    return peds
end)

lib.callback.register('no1-playerped:GetDefaultPed', function(source)
    local src = source
    local playerid = GetPlayerId(src)
    local result = MySQL.Sync.fetchAll('SELECT * FROM no1_playerpeds WHERE identifier = @identifier AND `default` = 1', {
        ['@identifier'] = playerid
    })

    if result and result[1] then
        return result[1].ped
    else
        return false
    end
end)

-- Events --
RegisterNetEvent('no1-playerped:SetPlayerPed', function(data)
    local src = source
    local model = data.model
    local identifier = data.identifier

    if HasPermission(src) then
        if identifier then
            if IsPedValid(model) then
                local insert = MySQL.Sync.insert(insertTable, {['@identifier'] = identifier, ['@ped'] = model})
            end
        end
    end
end)

RegisterNetEvent('no1-playerped:DeletePlayerPed', function(data)
    local src = source
    local identifier = data.identifier
    local id = data.id

    if HasPermission(src) then
        MySQL.Async.execute(removeTable, {['@identifier'] = identifier, ['@id'] = id})
    end
end)

RegisterNetEvent('no1-playerped:SetDefaultPed', function(data)
    local src = source
    local identifier = GetPlayerId(src)
    local id = data.id
    local ped = data.ped

    if identifier then
        MySQL.Async.execute(cleardefaultTable, {['@identifier'] = identifier}, function()
            MySQL.Async.execute(updateTable, {['@identifier'] = identifier, ['@id'] = id})
            TriggerClientEvent('no1-playerped:SetPlayerPed', src, ped)
        end)
    end
end)


