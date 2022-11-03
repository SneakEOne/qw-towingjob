local QBCore = exports['qb-core']:GetCoreObject()

local function IsVehicleOwned(plate)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    return result
end

RegisterNetEvent('qw-risingsuns:server:Impound', function(plate, price, body, engine, fuel)
    local src = source
    price = price and price or 0
    if IsVehicleOwned(plate) then
            MySQL.query(
                'UPDATE player_vehicles SET state = ?, depotprice = ?, body = ?, engine = ?, fuel = ? WHERE plate = ?',
                {3, price, body, engine, fuel, plate})
            TriggerClientEvent('QBCore:Notify', src, 'Vehicle Impounded for $'..price)

            if Config.Phone == 'gksphone' then
                TriggerClientEvent('gksphone:notifi', src, {title = Config.CompanyName.." Impound", message = "Your Vehicle has been Impounded for the small price of $"..price, img= '/html/static/img/icons/messages.png', duration = 5000})
            else
                TriggerClientEvent('qb-phone:client:CustomNotification', src, Config.CompanyName..' Impound', "Your Vehicle has been Impounded for the small price of $"..price, 'fas fa-car', '#E0EFDE', 5000)
            end
    end
end)

QBCore.Functions.CreateCallback('qw-risingsuns:checkImpoundedVehicles', function(_, cb, citizenid)
    local vehicles = {}

    local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE state = 3 AND citizenid = @citizenid', {
        ['@citizenid'] = citizenid
    })

    if result[1] then
        vehicles = result
        cb(vehicles)
    end
end)

RegisterNetEvent('qw-risingsuns:server:TakeOutImpound', function(plate, price)
    local src = source

    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveMoney('bank', price, 'impound-charge')

    if Config.BankScript == 'renewed' then
        exports['Renewed-Banking']:addAccountMoney(Config.Job, price * Config.CommissionForTow)
    else
        exports['qb-management']:AddMoney(Config.Job, price * Config.CommissionForTow)
    end

    MySQL.update('UPDATE player_vehicles SET state = ? AND depotprice = 0 WHERE plate = ?', {0, plate})
    TriggerClientEvent('QBCore:Notify', src, 'Successfully Obtained Vehicle', 'success')
end)