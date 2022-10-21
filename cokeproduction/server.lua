local QBCore = exports['qb-core']:GetCoreObject() 


RegisterNetEvent("ph-drugs:server:enterLabBucket", function(bucketnum)
    SetPlayerRoutingBucket(source, bucketnum)
end)

RegisterNetEvent("ph-drugs:server:exitLabBucket", function(bucketnum)
    SetPlayerRoutingBucket(source, 0)
end)

RegisterNetEvent("ph-drugs:server:requestCokeRun", function()
	local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    print("get cokeurn")
    local cost = CrimBalance.Drugs_CokeRun["ordercost"]
    local bankBalance = Player.PlayerData.money["bank"]
	local cashBalance = Player.PlayerData.money["cash"]
	if cashBalance >= cost or bankBalance>=cost then
		if cashBalance >= cost then
			Player.Functions.RemoveMoney('cash', cost, "coco import")
		else
			Player.Functions.RemoveMoney('bank', cost, "coco import")
		end
		
        TriggerClientEvent("ph-drugs:client:waitCokeRunEmail", source)
	else
		TriggerClientEvent('QBCore:Notify', source, "You dont have enough money ($"..cost..")", "error")
	end
end)

RegisterNetEvent("ph-drugs:server:pickupCokePackage", function()
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    --accept drug package
    --cokeleavespackage
    Player.Functions.AddItem("cokeleavespackage", 1)
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["cokeleavespackage"], "add", 1)
    
end)

QBCore.Functions.CreateUseableItem("coke_brick", function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
    local theItem = Player.Functions.GetItemByName(item.name)
    if theItem ~= nil then
		if theItem.info.quality == nil then theItem.info.quality = 100 end
		if theItem.info.quality <= 0 then
			TriggerClientEvent('QBCore:Notify', source, "Brick is all used", 'error')
            TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[item.name], "remove", 1)
            Player.Functions.RemoveItem(item.name, 1, false)
			return
		end
		Player.Functions.RemoveItem(item.name, 1, false)
		Player.Functions.AddItem(item.name, 1, theItem.info, {["quality"] = theItem.info.quality - (100/CrimBalance.Drugs_Processing_Coke)}) 

		TriggerClientEvent("ph-drugs:client:cutCokeBrick", source, "cokebaggy")
	end
end)
RegisterNetEvent("ph-drugs:server:cutCokeWith", function(cutwith, cokeitem)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local info = {}
    if cutwith then
        info.lacedWith = cutwith
        Player.Functions.RemoveItem(cutwith, 1, false)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[cutwith], "remove", 1)
    end

    Player.Functions.AddItem(cokeitem, 1, nil, info) 
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[cokeitem], "add", 1)
end)