local RSGCore = exports['rsg-core']:GetCoreObject()
local fixing = false
local position = 0
local spriteName = "feeds"
local spriteDict = "toast_bg"

Citizen.CreateThread(function()
    RequestStreamedTextureDict(spriteName)
    while not HasStreamedTextureDictLoaded(spriteName) do
        Wait(100)
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    
    if onScreen then
        local factor = (string.len(text)) / 160
        
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(255, 0, 0, 215)
        SetTextDropshadow(1, 1, 1, 1, 255)
        
        DrawSprite(spriteName, spriteDict, _x, _y + 0.0150, (0.015 + factor), 0.032, 0.1, 0, 0, 0, 190, 0)
        
        local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
        SetTextCentre(1)
        DisplayText(str, _x, _y)
    end
end


local function RegisterWagonServiceMenu(stationCoords)
    local vehicle = GetClosestVehicle(stationCoords.x, stationCoords.y, stationCoords.z, 5.0, 0, 71)
    
    if not vehicle or vehicle == 0 then
        RSGCore.Functions.Notify("No wagon found nearby to service.", "error")
        return
    end

    lib.registerContext({
        id = 'wagon_service_menu',
        title = 'Wagon Service',
        options = {
            {
                title = 'Repair Wagon',
                description = 'Fix all damages to nearby wagon',
                icon = 'wrench',
                onSelect = function()
                    TriggerEvent('carfixstation:fixCar', vehicle, true)
                    TriggerServerEvent('rsg-pay', 'repair')
                end
            },
            {
                title = 'Wash Wagon',
                description = 'Clean nearby wagon thoroughly',
                icon = 'soap',
                onSelect = function()
                    TriggerEvent('carfixstation:fixCar', vehicle, false)
                    TriggerServerEvent('rsg-pay', 'wash')
                end
            }
        }
    })
    
    lib.showContext('wagon_service_menu')
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        
        for k, v in pairs(Config.Stations) do
            if not fixing then
                local dist = Vdist(pos.x, pos.y, pos.z, v.x, v.y, v.z)
                if dist < 100 then
                    DrawMarker(36, v.x, v.y, v.z + 1.1, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 5.0, 1.0, 255, 0, 0, 100, true, true, 2, true, false, false, false)
                    DrawMarker(0, v.x, v.y, v.z - 0.4, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 5.0, 5.0, 1.0, 255, 255, 0, 100, false, false, 2, false, false, false, false)
                    
                    if dist < 2.5 then
                        position = k
                        DrawText3D(v.x, v.y, v.z + 1.0, ' PRESS G TO SERVICE WAGON ', 'INFO')
                        
                        if IsControlJustPressed(0, 0x760A9C6F) then
                            RegisterWagonServiceMenu(v)
                        end
                    end
                end
            end
        end
    end
end)



RegisterNetEvent('carfixstation:fixCar')
AddEventHandler('carfixstation:fixCar', function(vehicle, repair)
    if vehicle and vehicle ~= 0 then
        fixing = true
        local coords = GetEntityCoords(vehicle)
        local statusThread = Citizen.CreateThread(function()
            while fixing do
                DrawText3D(coords.x, coords.y, coords.z + 1.5, 'SERVICING...', 'WARNING')
                Citizen.Wait(0)
            end
        end)
        
        Citizen.Wait(Config.RepairTime)
        fixing = false
        DoScreenFadeOut(500)
        Citizen.Wait(1500)
        
        if repair then
            SetVehicleFixed(vehicle)
        end
        SetVehicleDirtLevel(vehicle, 0.0)
        DoScreenFadeIn(1800)
        
        local action = repair and "REPAIRED" or "WASHED"
        TriggerEvent('rNotify:NotifyLeft', "WAGON!", action, "generic_textures", "tick", 4000)
        
        if repair then
            SetVehicleDoorsLocked(vehicle, 1)
            TriggerEvent('rNotify:NotifyLeft', "WAGON!", "VEHICLE UNLOCKED", "generic_textures", "tick", 4000)
        end
    end
end)

RegisterNetEvent('rsg-pay-notify')
AddEventHandler('rsg-pay-notify', function(amount)
    TriggerEvent('rNotify:NotifyLeft', "WAGON!", 'You paid $' .. amount .. ' for the service.', "generic_textures", "tick", 4000)
end)


local blips = {
    { name = 'WAGON REPAIRS', sprite = 1869246576, x = -271.69, y = 687.57, z = 113.41 },
    { name = 'WAGON REPAIRS', sprite = 1869246576, x = 1052.24, y = -1123.35, z = 67.89 },
}

Citizen.CreateThread(function()
    for _, info in pairs(blips) do
        local blip = N_0x554d9d53f696d002(1664425300, info.x, info.y, info.z)
        SetBlipSprite(blip, info.sprite, 1)
        SetBlipScale(blip, 0.2)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, info.name)
    end
end)