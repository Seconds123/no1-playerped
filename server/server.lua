if Config.Framework == 'esx' then
    MySQL.ready(function()
        MySQL.Async.execute("ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `ped` VARCHAR(255) DEFAULT 'none'", {})
    end)

    local ESX = nil

    if Config.ESXversion == '1.1' or Config.ESXversion == '1.2' then
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    elseif Config.ESXversion == 'legacy' then
        ESX = exports['es_extended']:getSharedObject() 
    end

    local function SetPlayerPed(identifier, model)
        MySQL.Async.execute("UPDATE `users` SET `ped` = @ped WHERE `identifier` = @identifier", {
            ['@ped'] = model,
            ['@identifier'] = identifier
        })
    end

    local function RegisterCmd(version)
        if version == '1.1' then
            TriggerEvent('es:addGroupCommand', 'setped', 'admin', function(source, args, user)
                local src = source
                local xTarget = ESX.GetPlayerFromId(tonumber(args[1]))
                local pedModel = tostring(args[2])
    
                if xTarget then
                    if ValidPedModel(pedModel) or pedModel == "none" then
                        SetPlayerPed(xTarget.identifier, pedModel)

                        if pedModel == "none" then
                            TriggerClientEvent('no1-playerped:client:ResetPlayerPed', xTarget.source)
                            TriggerClientEvent('chat:addMessage', src, {args = {'^1SYSTEM', ('You have reset %s ped to default!'):format(xTarget.name)}})
                        else
                            TriggerClientEvent('no1-playerped:client:SetPlayerPed', xTarget.source, pedModel)
                            TriggerClientEvent('chat:addMessage', src, {args = {'^1SYSTEM', ('You have set %s ped to %s!'):format(xTarget.name, pedModel)}})
                        end
                    else
                        TriggerClientEvent('chat:addMessage', xPlayer.source, {args = {'^1SYSTEM', 'Invalid Ped Model!'}})
                    end
                else
                    TriggerClientEvent('chat:addMessage', src, {args = {'^1SYSTEM', 'Invalid PlayerID!'}})
                end
            end, function(source, args, user)
                TriggerClientEvent('chat:addMessage', src, {args = { '^1SYSTEM', 'Insufficient Permissions.' }})
            end, {help = 'Set a ped to player', params = {{name = "player", help = "playerid"}, {name = "model", help = "ped model"}}})
        elseif version == '1.2' or version == 'legacy' then
            ESX.RegisterCommand('setped', 'admin', function(xPlayer, args, showError)
                local xTarget = ESX.GetPlayerFromId(args.target)
    
                if xTarget then
                    if ValidPedModel(args.model) or args.model == "none" then
                        SetPlayerPed(xTarget.identifier, args.model)
        
                        if args.model == "none" then
                            TriggerClientEvent('no1-playerped:client:ResetPlayerPed', xTarget.source)
                            TriggerClientEvent('chat:addMessage', xPlayer.source, {args = {'^1SYSTEM', ('You have reset %s ped to default!'):format(xTarget.name)}})
                        else
                            TriggerClientEvent('no1-playerped:client:SetPlayerPed', xTarget.source, args.model)
                            TriggerClientEvent('chat:addMessage', xPlayer.source, {args = {'^1SYSTEM', ('You have set %s ped to %s!'):format(xTarget.name, args.model)}})
                        end
                    else
                        TriggerClientEvent('chat:addMessage', xPlayer.source, {args = {'^1SYSTEM', 'Invalid Ped Model!'}})
                    end
                else
                    TriggerClientEvent('chat:addMessage', xPlayer.source, {args = {'^1SYSTEM', 'Invalid PlayerID!'}})
                end
            end, true, {help = 'Set a ped to player', validate = true, arguments = {
                {name = 'target', help = 'playerid', type = 'number'},
                {name = 'model', help = 'ped model', type = 'string'}
            }})
        end
    end    

    RegisterCmd(Config.ESXversion)

    ESX.RegisterServerCallback('no1-playerped:server:GetPlayerPed', function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)

        MySQL.Async.fetchScalar('SELECT `ped` FROM users WHERE `identifier` = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            cb(result)
        end)
    end)
elseif Config.Framework == 'qbcore' then
    -- Not done yet
end

local validModel = false

function ValidPedModel(pedModel)
    if pedModel and type(pedModel) == 'string' then
        for i = 1, #Peds.VanillaList do
            local validPed = Peds.VanillaList[i]
            if pedModel == validPed.modelName then
                --print("Valid Model: ["..tostring(pedModel).."] found.")
                validModel = true
                return true
            end
        end
        if Config.allowDLCPeds then
            for i = 1, #Peds.DLCList do
                local validPed = Peds.DLCList[i]
                if pedModel == validPed.modelName then
                    --print("Valid DLC Model: ["..tostring(pedModel).."] found.")
                    validModel = true
                    return true
                end
            end
        end
        validModel = false
        if not validModel then --[[print("Ped Model: "..pedModel.." failed model check.")]] return false end
    else
        --print("Invaild Model: ["..tostring(pedModel).."].")
    end
end

