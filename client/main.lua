Framework = nil

-- Initialise Locale --
lib.locale()
-----------------------

if Config.Framework == 'esx' then
    Framework = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'qb' then
    Framework = exports['qb-core']:GetCoreObject()
end

-- Functions --

local function IsPlayerLoaded()
    if Config.Framework == 'esx' then
        return Framework.IsPlayerLoaded()
    elseif Config.Framework == 'qb' then
        return LocalPlayer.state.isLoggedIn
    end
end

local function SetPlayerPed(model)
    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Wait(0)
    end
    SetPlayerModel(PlayerId(), hash)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(hash)
    
    if Config.Framework == 'esx' then
        TriggerEvent('esx:restoreLoadout')
    end
end

local function ResetPlayerPed()
    if Config.Framework == 'esx' then
        Framework.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
            local isMale = skin.sex == 0
            TriggerEvent('skinchanger:loadDefaultModel', isMale, function()
                Framework.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                    TriggerEvent('skinchanger:loadSkin', skin)
                end)
            end)
        end)
    elseif Config.Framework == 'qb' then
        TriggerServerEvent('qb-clothes:loadPlayerSkin')
    end
end

local function LoadDefaultPed()
    lib.callback('no1-playerped:GetDefaultPed', 2500, function(ped)
        if ped then
            SetPlayerPed(ped)
        end
    end)
end

RegisterNetEvent('no1-playerped:SetPlayerPed', SetPlayerPed)
RegisterNetEvent('no1-playerped:ResetPlayerPed', ResetPlayerPed)

-- Events --

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    while IsPlayerLoaded() do
        Wait(100)
    end

    LoadDefaultPed()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    while IsPlayerLoaded() do
        Wait(100)
    end

    LoadDefaultPed()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if IsPlayerLoaded() then
            LoadDefaultPed()
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        ResetPlayerPed()
    end
end)

RegisterNetEvent('no1-playerped:GivePedDialogue', function(data)
    local playerid = data.playerid
    local identifier = data.identifier
    local playername = data.name

    local input = lib.inputDialog(locale('pedoptions'), {
        {type = 'input', icon = 'signature', label = locale('player'), disabled = true, placeholder = string.format('%s (%s)', playername, playerid)},
        {type = 'select', icon = 'user-secret', label = locale('option'), options = {{value = 'give', label = locale('giveped')}, {value = 'remove', label = locale('removeped')}}, required = true, default = 'give', clearable = false}
    })

    if input[2] == 'give' then
        local peds = {}

        for model, image in ipairs(Config.CustomPeds) do
            peds[#peds+1] = {
                title = model,
                --icon = image,
                image = image,
                serverEvent = 'no1-playerped:SetPlayerPed',
                arrow = true,
                args = {
                    playerid = playerid,
                    identifier = identifier,
                    model = Config.VanillaPeds[i]
                }
            }
        end

        for i=1, #Config.VanillaPeds do
            local url = "https://docs.fivem.net/peds/"..Config.VanillaPeds[i]..".webp"

            peds[#peds+1] = {
                title = Config.VanillaPeds[i],
                --icon = url,
                image = url,
                serverEvent = 'no1-playerped:SetPlayerPed',
                arrow = true,
                args = {
                    playerid = playerid,
                    identifier = identifier,
                    model = Config.VanillaPeds[i]
                }
            }
        end

        lib.registerContext({
            id = 'giveped',
            title = locale('giveped'),
            options = peds
        })

        lib.showContext('giveped')
    elseif input[2] == 'remove' then
        local playerpeds = lib.callback.await('no1-playerped:GetPlayerPeds', false, playerid)
        local peds = {}

        if #playerpeds == 0 then
            TriggerEvent('no1-playerped:Notify', locale('nopeds'), 'error')
        else
            for _, v in pairs(playerpeds) do
                local url = Config.CustomPeds[v.ped] ~= nil and Config.CustomPeds[v.ped] or "https://docs.fivem.net/peds/"..v.ped..".webp"

                peds[#peds+1] = {
                    title = v.ped,
                    description = v.default == 1 and locale('playerdefault') or '',
                    image = url,
                    serverEvent = 'no1-playerped:DeletePlayerPed',
                    arrow = true,
                    args = {
                        identifier = identifier,
                        id = v.id
                    }
                }
            end

            lib.registerContext({
                id = 'removeped',
                title = locale('removepedplayer', playername, locale('removeped')),
                options = peds
            })

            lib.showContext('removeped')
        end
    end
end)


-- Command --
RegisterCommand('pedmenu', function()
    if IsPlayerLoaded() then
        local playerpeds = lib.callback.await('no1-playerped:GetPlayerPeds', false)
        local peds = {}

        if #playerpeds == 0 then
            TriggerEvent('no1-playerped:Notify', locale('nopeds'), 'error')
        else
            for _, v in pairs(playerpeds) do
                local url = Config.CustomPeds[v.ped] ~= nil and Config.CustomPeds[v.ped] or "https://docs.fivem.net/peds/"..v.ped..".webp"

                peds[#peds+1] = {
                    title = v.ped,
                    description = (v.default == 1 or v.default == true) and locale('defaultped') or locale('setdefault'),
                    --icon = url,
                    image = url,
                    serverEvent = 'no1-playerped:SetDefaultPed', 
                    arrow = (v.default == 0 or v.default == false) and true or false,
                    args = { id = v.id, ped = v.ped }
                }
            end

            peds[#peds+1] = {
                title = locale('resetped'),
                description = locale('resetped_description'),
                icon = 'power-off',
                iconColor = 'tomato',
                event = 'no1-playerped:ResetPlayerPed'
            }

            lib.registerContext({
                id = 'yourpeds',
                title = locale('yourpeds'),
                options = peds
            })
            
            lib.showContext('yourpeds')
        end
    end
end, false)

-- Notification --

RegisterNetEvent('no1-playerped:Notify', function(msg, sort, duration)
    local message = msg
    local type = sort
    local length = duration or 5000

    if Config.Framework == 'esx' then
        Framework.ShowNotification(message, type, length)
    elseif Config.Framework == 'qb' then
        if type == 'info' then
            type = 'primary'
        end

        Framework.Functions.Notify(message, type, length)
    end
end)