if Config.Framework == 'esx' then
    local ESX = nil

    if Config.ESXversion == '1.1' or Config.ESXversion == '1.2' then
        Citizen.CreateThread(function()
            while ESX == nil do
                TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
                Citizen.Wait(0)
            end
        end)
    elseif Config.ESXversion == 'legacy' then
        ESX = exports['es_extended']:getSharedObject() 
    end

    local function SetPlayerPed(pedmodel)
        local hash = GetHashKey(pedmodel)
        RequestModel(hash)
        while not HasModelLoaded(hash) or not IsModelInCdimage(hash) do
            RequestModel(hash)
            Citizen.Wait(4)
        end
    
        SetPlayerModel(PlayerId(), hash)
        SetPedDefaultComponentVariation(PlayerPedId())
    
        SetModelAsNoLongerNeeded(hash)
    end

    local function ResetPlayerPed()
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
            local isMale = skin.sex == 0

            TriggerEvent('skinchanger:loadDefaultModel', isMale, function()
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                    TriggerEvent('skinchanger:loadSkin', skin)
                end)
            end)

        end)
    end

    RegisterNetEvent('no1-playerped:client:SetPlayerPed', SetPlayerPed)
    RegisterNetEvent('no1-playerped:client:ResetPlayerPed', ResetPlayerPed)

    AddEventHandler('playerSpawned', function()
        ESX.TriggerServerCallback('no1-playerped:server:GetPlayerPed', function(pedmodel)
            local hashkey = GetHashKey(pedmodel)

            if pedmodel ~= 'none' then
                if GetEntityModel(PlayerPedId()) ~= hashkey then
                    SetPlayerPed(pedmodel)
                 end
            end
        end)
    end)
    
elseif Config.Framework == "qbcore" then
    -- Not done yet
end