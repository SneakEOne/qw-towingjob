local QBCore = exports['qb-core']:GetCoreObject()
local zoneData = {}
local isInsideEntranceTarget = false

RegisterNetEvent('qb-risingsuns:client:openPayMenu', function()
        exports['qb-menu']:openMenu({
            {
                header = Config.CompanyName..' Towing',
                icon = 'fa-solid fa-screwdriver-wrench',
                isMenuHeader = true,
            },
            {
                header = 'Check your Impounded Vehicles',
                txt = 'Check to see if you have any impounded cars, and pay them here!',
                icon = 'fa-solid fa-car',
                params = {
                    event = 'qw-risingsuns:client:getImoundedVehicles',
                }
            }
        })
end)

RegisterNetEvent('qw-risingsuns:client:getImoundedVehicles', function() 
    local Player = QBCore.Functions.GetPlayerData()
    local citizenid = Player.citizenid

    local impoundMenu = {
        {
            header = Config.CompanyName..' Towing',
            icon = 'fa-solid fa-screwdriver-wrench',
            isMenuHeader = true,
        }
    }

    QBCore.Functions.TriggerCallback('qw-risingsuns:checkImpoundedVehicles', function(result) 
    
        if result == nil then
            QBCore.Functions.Notify('No Vehicles in the Impound', "error")
        else
            for _ , v in pairs(result) do
                local enginePercent = QBCore.Shared.Round(v.engine / 10, 0)
                local currentFuel = v.fuel
                local vname = QBCore.Shared.Vehicles[v.vehicle].name

                impoundMenu[#impoundMenu+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt = 'Engine: '..enginePercent..'% | Fuel: '..currentFuel..' | Price: $'..v.depotprice,
                    params = {
                        event = "qw-risingsuns:client:TakeOutImpound",
                        args = {
                            vehicle = v,
                        }
                    }
                }
            end

            exports['qb-menu']:openMenu(impoundMenu)
        end
    
    end, citizenid)

end)

RegisterNetEvent('qb-risingsuns:client:openTowMenu', function()
    local canOpen = checkInZone()

    if canOpen then
        local closestVehicle = QBCore.Functions.GetClosestVehicle()
        local vehicleProps = QBCore.Functions.GetVehicleProperties(closestVehicle)
        exports['qb-menu']:openMenu({
            {
                header = Config.CompanyName..' Towing',
                icon = 'fa-solid fa-screwdriver-wrench',
                isMenuHeader = true,
            },
            {
                header = 'Tow Vehicle',
                txt = 'Add the Closest Vehicle to the Impound Lot ('..vehicleProps.plate..' - '..GetDisplayNameFromVehicleModel(vehicleProps.model)..')',
                icon = 'fa-solid fa-car',
                params = {
                    event = 'qb-risingsuns:client:openPricingInput',
                }
            }
        })
    else
        QBCore.Functions.Notify('You are not in a Towing Zone!', 'error')
    end
end)

RegisterNetEvent('qb-risingsuns:client:openPricingInput', function() 

    local dialog = exports['qb-input']:ShowInput({
        header = Config.CompanyName.." Towing",
        submitText = "Impound Vehicle",
        inputs = {
            {
                text = "Price for Impound ($)", -- text you want to be displayed as a place holder
                name = "towprice", -- name of the input should be unique otherwise it might override
                type = "number", -- type of the input
                isRequired = true, -- Optional [accepted values: true | false] but will submit the form if no value is inputted
                default = 500, -- Default text option, this is optional
            },
            
        },
    })

    TriggerEvent('qb-risingsuns:client:ImpoundVehicle', dialog.towprice)

end)

RegisterNetEvent('qb-risingsuns:client:ImpoundVehicle', function(price)
    local vehicle = QBCore.Functions.GetClosestVehicle()
    local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
    local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
    local totalFuel = exports[Config.FuelSystem]:GetFuel(vehicle)
    if vehicle ~= 0 and vehicle then
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local vehpos = GetEntityCoords(vehicle)
        if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(ped) then
           QBCore.Functions.Progressbar('impound', 'Impounding Vehicle', 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = 'missheistdockssetup1clipboard@base',
                anim = 'base',
                flags = 1,
            }, {
                model = 'prop_notepad_01',
                bone = 18905,
                coords = { x = 0.1, y = 0.02, z = 0.05 },
                rotation = { x = 10.0, y = 0.0, z = 0.0 },
            },{
                model = 'prop_pencil_01',
                bone = 58866,
                coords = { x = 0.11, y = -0.02, z = 0.001 },
                rotation = { x = -120.0, y = 0.0, z = 0.0 },
            }, function() -- Play When Done
                local plate = QBCore.Functions.GetPlate(vehicle)
                TriggerServerEvent("qw-risingsuns:server:Impound", plate, price, bodyDamage, engineDamage, totalFuel)
                QBCore.Functions.DeleteVehicle(vehicle)
                TriggerEvent('QBCore:Notify', 'Impounded Complete', 'success')
                ClearPedTasks(ped)
            end, function() -- Play When Cancel
                ClearPedTasks(ped)
                TriggerEvent('QBCore:Notify', 'Cancelled', 'error')
            end)
        end
    end
end)

RegisterNetEvent('qw-risingsuns:client:TakeOutImpound', function(data)
    local vehicle = data.vehicle
    TakeOutImpound(vehicle)
end)

local function doCarDamage(currentVehicle, veh)
	local smash = false
	local damageOutside = false
	local damageOutside2 = false
	local engine = veh.engine + 0.0
	local body = veh.body + 0.0

	if engine < 200.0 then engine = 200.0 end
    if engine  > 1000.0 then engine = 950.0 end
	if body < 150.0 then body = 150.0 end
	if body < 950.0 then smash = true end
	if body < 920.0 then damageOutside = true end
	if body < 920.0 then damageOutside2 = true end

    Citizen.Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)

	if smash then
		SmashVehicleWindow(currentVehicle, 0)
		SmashVehicleWindow(currentVehicle, 1)
		SmashVehicleWindow(currentVehicle, 2)
		SmashVehicleWindow(currentVehicle, 3)
		SmashVehicleWindow(currentVehicle, 4)
	end

	if damageOutside then
		SetVehicleDoorBroken(currentVehicle, 1, true)
		SetVehicleDoorBroken(currentVehicle, 6, true)
		SetVehicleDoorBroken(currentVehicle, 4, true)
	end

	if damageOutside2 then
		SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
	end

	if body < 1000 then
		SetVehicleBodyHealth(currentVehicle, 985.1)
	end
end

function closeMenuFull()
    exports['qb-menu']:closeMenu()
end

function TakeOutImpound(vehicle)
    local coords = Config.TakeoutVehicleFromImpound
    if coords then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)
                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetEntityHeading(veh, coords.w)
                exports[Config.FuelSystem]:SetFuel(veh, vehicle.fuel)
                doCarDamage(veh, vehicle)
                TriggerServerEvent('qw-risingsuns:server:TakeOutImpound', vehicle.plate, vehicle.depotprice)
                closeMenuFull()
                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                SetVehicleEngineOn(veh, true, true)
            end, vehicle.plate)
        end, vehicle.vehicle, coords, true)
    end
end

function createPolyZone() 
    local zone = PolyZone:Create(Config.TowingZone, {
        name = 'risingsuns-towing',
        minZ = 37,
        maxZ = 39,
    })

    zone:onPlayerInOut(function (isPointInside) 
        local closestVehicle = QBCore.Functions.GetClosestVehicle()
        
        if isPointInside then
            exports['ps-ui']:DisplayText(Config.CompanyName.." Towing Zone", "primary")
            
            exports['qb-target']:AddTargetEntity(closestVehicle, {
                options = {
                    {
                        type = "client",
                        event = "qb-risingsuns:client:openTowMenu",
                        icon = "fa-solid fa-screwdriver-wrench",
                        label = "Tow this Vehicle",
                        job = Config.Job,
                    },
                },
                distance = 3.0
            })
        else
            exports['ps-ui']:HideText()
            exports['qb-target']:RemoveTargetEntity(closestVehicle, 'Tow this Vehicle')
        end

        isInsideEntranceTarget = isPointInside
    end)

    zoneData.created = true
    zoneData.zone = zone
end

function checkInZone() 
    if isInsideEntranceTarget then
        return true
    else
        return false
    end
end

function setupPed()
    CreateThread(function()
        exports['qb-target']:SpawnPed({
            model = 's_m_m_ccrew_01',
            coords = Config.CheckImpoundLocation,
            minusOne = true,
            freeze = true,
            invincible = true,
            blockevents = true,
            target = {
                useModel = false,
                options = {
                    {
                        num = 1,
                        type = 'client',
                        event = 'qb-risingsuns:client:openPayMenu',
                        icon = 'fa-solid fa-comments',
                        label = 'Talk to '..Config.CompanyName..' Employee',
                    },
                },
                distance = 2.5
            },
            spawnNow = true,
            currentpednumber = 0,
        });
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createPolyZone()
    setupPed()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        createPolyZone()
        setupPed()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        zoneData.zone:destroy()
    end
end)