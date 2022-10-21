local QBCore = exports['qb-core']:GetCoreObject() 


QBCore.Functions.CreateUseableItem("methbrown", function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
    local theItem = Player.Functions.GetItemByName(item.name)
    if theItem ~= nil then

		TriggerClientEvent("ph-drugs:client:use_meth", source, item.name)
        TriggerClientEvent("ph-drugs:client:use_lacedDrug", source, theItem.info.lacedWith)
	end
end)

QBCore.Functions.CreateUseableItem("methblue", function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
    local theItem = Player.Functions.GetItemByName(item.name)
    if theItem ~= nil then

		TriggerClientEvent("ph-drugs:client:use_meth", source, item.name)
        TriggerClientEvent("ph-drugs:client:use_lacedDrug", source, theItem.info.lacedWith)
	end
end)


QBCore.Functions.CreateUseableItem("methwhite", function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
    local theItem = Player.Functions.GetItemByName(item.name)
    if theItem ~= nil then

		TriggerClientEvent("ph-drugs:client:use_meth", source, item.name)
        TriggerClientEvent("ph-drugs:client:use_lacedDrug", source, theItem.info.lacedWith)
	end
end)

QBCore.Functions.CreateUseableItem("lsd", function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
    local theItem = Player.Functions.GetItemByName(item.name)
    if theItem ~= nil then

		TriggerClientEvent("ph-drugs:client:use_lsd", source, item.name)
        TriggerClientEvent("ph-drugs:client:use_lacedDrug", source, theItem.info.lacedWith)
	end
end)

QBCore.Functions.CreateUseableItem("fentanyl", function(source, item)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local theItem = Player.Functions.GetItemByName(item.name)
	if theItem ~= nil then
		if theItem.info.quality == nil then theItem.info.quality = 100 end
		if theItem.info.quality <= 0 then
			TriggerClientEvent('QBCore:Notify', source, "Item is broken", 'error')
			return
		end
		Player.Functions.RemoveItem('fentanyl', 1, false)
		Player.Functions.AddItem("fentanyl", 1, theItem.info, {["quality"] = theItem.info.quality - math.random(5,10)}) 
		TriggerClientEvent("ph-drugs:client:UseFentanyl", src)
	end
end)

QBCore.Commands.Add('testeffect', "Test a screen effect", {{name='effectname', help='Name of onscreen effect'}}, false, function(source, args)
    local src = source
    local effectname = args[1]
    TriggerClientEvent("ph-drugs:client:testScreenEffect", source, effectname)

end, 'god')

