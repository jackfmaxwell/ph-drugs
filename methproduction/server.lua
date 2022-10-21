local QBCore = exports['qb-core']:GetCoreObject() 


--Variables
  --need var to manage beaker state
local labStates = {
    ["lowtierlab"] = {
        ["beaker1"] = {

        },
        ["beaker1Quality"] = 100,
        ["beaker2"] = {
    
        },
        ["beaker2Quality"] = 100,
        ["boiling"] = {

        },
        ["boilingQuality"] = 100,
    },
    ["cokelab1"] = {
        ["beaker1"] = {

        },
        ["beaker1Quality"] = 100,
        ["beaker2"] = {
    
        },
        ["beaker2Quality"] = 100,
        ["boiling"] = {

        },
        ["boilingQuality"] = 100,
    },
}


--Checks for items and quantity, (even non stacked)
QBCore.Functions.CreateCallback('ph-drugs:server:validate_items', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

	local hasItems = true
	for name,amount in pairs(data) do
		local items = Player.Functions.GetItemsByName(name)
        if not items then
            hasItems = false
        else
            local total_amt = 0
            for _, item in pairs(items) do
                total_amt = total_amt + item.amount
            end
            if amount > total_amt then
                hasItems = false
            end
        end
		
		if not hasItems then break end
	end
	cb(hasItems)
end)

QBCore.Functions.CreateCallback("ph-drugs:server:getBeakerableItems", function(source, cb, _)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local itemsBeakerable = {}
    for _, item in pairs(Config.BeakerableItems) do
        local hasitem = nil
        if item=="chemicalsolution" then
            local solutions = {}
            local items = Player.Functions.GetItemsByName(item)
            for _, item in pairs(items) do
                if item.info.name then
                    solutions[item.info.name] = 1
                end
            end
            for solution, _ in pairs(solutions) do
                itemsBeakerable[#itemsBeakerable+1] = solution
            end
        else
            hasitem = Player.Functions.GetItemByName(item)
        end
        
        if hasitem then
            itemsBeakerable[#itemsBeakerable+1] = hasitem
        end
    end
    for _, item in pairs(Config.BeakerableLabBasicItems) do
        itemsBeakerable[#itemsBeakerable+1] = item
    end
    cb(itemsBeakerable)
end)

QBCore.Functions.CreateCallback("ph-drugs:server:getMixtures", function(source, cb, _)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local chemicalmixtures = {}
    local solutions = {}    
    local items = Player.Functions.GetItemsByName("chemicalsolution")
    for _, item in pairs(items) do
        if item.info.name then
            solutions[item.info.name] = 1
        end
    end

    --change index list to list of strings
    for solution, _ in pairs(solutions) do
        chemicalmixtures[#chemicalmixtures+1] = solution
    end
       
    cb(chemicalmixtures)
end)

QBCore.Functions.CreateCallback('ph-drugs:server:getCuttableThings', function(source, cb, _)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local cuttable = {}
    for _, item in pairs(Config.CuttableThings) do 
        if Player.Functions.GetItemByName(item)~=nil then
            cuttable[#cuttable+1] = item
        end
    end

    cb(cuttable)
end)

QBCore.Functions.CreateCallback('ph-drugs:server:getBoilState', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    lab = data.lab

	cb(labStates[lab]["boiling"])
end)

QBCore.Functions.CreateCallback('ph-drugs:server:getLabSate', function(source, cb, data)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    lab = data.lab
    place = data.place

	cb(labStates[lab][place])
end)

RegisterNetEvent("ph-drugs:server:emptyBeaker", function(lab, place)
    labStates[lab][place] = {}
    if place=="beaker1" then
        labStates[lab]["beaker1Quality"] = 100
    end
    if place=="beaker2" then
        labStates[lab]["beaker2Quality"] = 100
    end
end)
RegisterNetEvent("ph-drugs:server:addBeaker", function(lab, place, itemname, qualityReduce)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end


    --add thing to beaker 
    if labStates[lab][place][itemname] then
        labStates[lab][place][itemname] = labStates[lab][place][itemname] + 1
    else
        labStates[lab][place][itemname] = 1
    end
    
    local itemaddedQuality = 100
    if QBCore.Shared.Items[itemname] then
        local theItem = Player.Functions.GetItemByName(itemname)
        itemaddedQuality = theItem.info.quality
        Player.Functions.RemoveItem(theItem.name, 1)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[itemname], "remove", 1)
    else
        -- not a item 
        -- could be hydroiodicacid or methmixture (remove chemical solution with that info)
        local slots = QBCore.Player.GetSlotsByItem(Player.PlayerData.items, "chemicalsolution")
        for _, itemslot in pairs(slots) do
            --look for items with info.name == itemname
            local item = Player.PlayerData.items[itemslot]
            if item.info.name then
                if item.info.name == itemname then
                    itemaddedQuality = item.info.quality
                    Player.Functions.RemoveItem("chemicalsolution", 1, itemslot)
                    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "remove", 1)
                    break
                end
            end
        end 
    end

    local qualityReduceFromIngredient = 100 - itemaddedQuality --if item is quality 80, we reduce solution quality by 20
    if place=="beaker1" then
        --beaker quality is reduced by quality of product and quality of process
        labStates[lab]["beaker1Quality"] = labStates[lab]["beaker1Quality"] - qualityReduceFromIngredient
        if qualityReduce then labStates[lab]["beaker1Quality"] = labStates[lab]["beaker1Quality"]- tonumber(qualityReduce) end
    end
    if place=="beaker2" then
        labStates[lab]["beaker2Quality"] = labStates[lab]["beaker2Quality"] - qualityReduceFromIngredient
        if qualityReduce then labStates[lab]["beaker2Quality"] = labStates[lab]["beaker2Quality"]- tonumber(qualityReduce) end
    end
    if qualityReduce then
       
    end
end)
RegisterNetEvent("ph-drugs:server:extractSolution", function(lab, place)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local canMakeHydroiodicacid = false
    local beaker = labStates[lab][place]
    local mixtureQuality = 100
    if place=="beaker1" then
        mixtureQuality = labStates[lab]["beaker1Quality"] 
        labStates[lab]["beaker1Quality"] = 100
    end
    if place=="beaker2" then
        mixtureQuality = labStates[lab]["beaker2Quality"] 
        labStates[lab]["beaker2Quality"] = 100
    end

    
    if beaker["redphosphorus"]==1 and beaker["iodinecrystals"]==1 then
        --local quantity = beaker["redphosphorus"] + beaker["iodinecrystals"]
        local info = {}
        info.label = "Hydroiodic Acid"
        info.name = "hydroiodicacid"
        info.quality = mixtureQuality
        Player.Functions.AddItem("chemicalsolution", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "add", 1)
    elseif beaker["draincleaner"]==1 and beaker["poolcleaner"]==1 and beaker["ephedrine"]==2 and beaker["hydroiodicacid"]==2 then
        local info = {}
        info.label = "Diluted Meth Chemical Mixture"
        info.name = "preboil_methsol"
        info.quality = mixtureQuality
        Player.Functions.AddItem("chemicalsolution", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "add", 1)
    elseif beaker["prefinal_methsol"] and beaker["acetone"]==2 and beaker["draincleaner"]==1 then
        local info = {}
        info.label = "Saturated Meth Chemical Mixture"
        info.name = "final_methsol"
        info.quality = mixtureQuality
        Player.Functions.AddItem("chemicalsolution", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "add", 1)
    elseif beaker["cokeleaves"] and beaker["cementpowder"] and beaker["draincleaner"] and beaker["jerry_can"] then
        local info = {}
        info.label = "Coca Mixture"
        info.name = "coke_sol"
        info.quality = mixtureQuality
        Player.Functions.AddItem("chemicalsolution", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "add", 1)
    elseif beaker["filteredcoke_sol"] and beaker["potassiumsalt"] and beaker["draincleaner"] then
        local info = {}
        info.label = "Coca Mixture"
        info.name = "finalcoke_sol"
        info.quality = mixtureQuality
        Player.Functions.AddItem("chemicalsolution", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "add", 1)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Mixture has no use..', 'error')
    end

    labStates[lab][place] = {}
end)

RegisterNetEvent("ph-drugs:server:finalMethProcess", function(mixturename)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    
    -- check quality
    --award bricks
    local slots = QBCore.Player.GetSlotsByItem(Player.PlayerData.items, "chemicalsolution")
    for _, itemslot in pairs(slots) do
        --look for items with info.name == itemname
        local item = Player.PlayerData.items[itemslot]
        if item.info.name then
            if item.info.name == mixturename then
                --give bricks
                Player.Functions.RemoveItem("chemicalsolution", 1, itemslot)
                TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "remove", 1)

                if mixturename~="final_methsol" then TriggerClientEvent('QBCore:Notify', source, 'Mixture has no use..', 'error') return end
                if item.info.quality>=CrimBalance.Drugs_Production_Meth["methQualityRanges"]["highQuality"] then
                    Player.Functions.AddItem("methbrickblue", 1)
                    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["methbrickblue"], "add", 1)
                elseif item.info.quality>=CrimBalance.Drugs_Production_Meth["methQualityRanges"]["normalQuality"] then
                    Player.Functions.AddItem("methbrickwhite", 1)
                    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["methbrickwhite"], "add", 1)
                elseif item.info.quality>=CrimBalance.Drugs_Production_Meth["methQualityRanges"]["lowQuality"] then
                    Player.Functions.AddItem("methbrickbrown", 1)
                    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["methbrickbrown"], "add", 1)
                else
                    TriggerClientEvent('QBCore:Notify', source, 'Mixture too low quality..', 'error')
                end
                
                break
            end
        end
    end
end)
                                                            --{sudafed = 1}, {ephedrine = 1}
RegisterNetEvent("ph-drugs:server:processIngredient", function(requirements, resultants)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local hasItems = true
	for name,amount in pairs(requirements) do
		local items = Player.Functions.GetItemsByName(name)
        if not items then
            hasItems = false
        else
            local total_amt = 0
            for _, item in pairs(items) do
                total_amt = total_amt + item.amount
            end
            if amount > total_amt then
                hasItems = false
            end
        end
		
		if not hasItems then break end
	end

    --has ingredients, remove and add resultants
    if hasItems then
        for name,amount in pairs(requirements) do
            Player.Functions.RemoveItem(name, amount)
            TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[name], "remove", amount)
        end
        for name,amount in pairs(resultants) do
            local info = {}
            
            if requirements["sudafed"] then
                info.quality = 80 
            end
            Player.Functions.AddItem(name, amount, nil, info)
            TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[name], "add", amount)
        end
    end

end)

RegisterNetEvent("ph-drugs:server:recieveCompleteMixture", function(lab, mixturename, process)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end



    if mixturename=="preboil_methsol" and process=="boil" then
        local info = {}
        info.label = "Colloidal Meth Chemical Mixture"
        info.name = "prefilter_methsol"
        info.quality = labStates[lab]["boilingQuality"]
        labStates[lab]["boilingQuality"] = 100
        Player.Functions.AddItem("chemicalsolution", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "add", quantity)
        labStates[lab]["boiling"] = {}
    elseif mixturename=="finalcoke_sol" and process=="boil" then
        local info = {}
        info.quality = labStates[lab]["boilingQuality"]
        labStates[lab]["boilingQuality"] = 100
        Player.Functions.AddItem("coke_brick", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["coke_brick"], "add", quantity)
        labStates[lab]["boiling"] = {}
    elseif mixturename=="prefilter_methsol" and process=="strain" then
        local info = {}
        info.label = "Acidic Meth Chemical Mixture"
        info.name = "prefinal_methsol"

        local slots = QBCore.Player.GetSlotsByItem(Player.PlayerData.items, "chemicalsolution")
        for _, itemslot in pairs(slots) do
            --look for items with info.name == itemname
            local item = Player.PlayerData.items[itemslot]
            if item.info.name then
                if item.info.name == mixturename then
                    Player.Functions.RemoveItem("chemicalsolution", 1, itemslot)
                    info.quality = item.info.quality
                    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "remove", 1)
                    break
                end
            end
        end

        Player.Functions.AddItem("chemicalsolution", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "add", 1)
    elseif mixturename=="coke_sol" and process=="strain" then
        local info = {}
        info.label = "Filtered Coca Mixture"
        info.name = "filteredcoke_sol"

        local slots = QBCore.Player.GetSlotsByItem(Player.PlayerData.items, "chemicalsolution")
        for _, itemslot in pairs(slots) do
            --look for items with info.name == itemname
            local item = Player.PlayerData.items[itemslot]
            if item.info.name then
                if item.info.name == mixturename then
                    Player.Functions.RemoveItem("chemicalsolution", 1, itemslot)
                    info.quality = item.info.quality
                    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "remove", 1)
                    break
                end
            end
        end

        Player.Functions.AddItem("chemicalsolution", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "add", 1)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Mixture has no use', 'error')
        labStates[lab]["boiling"] = {}
    end

end)

RegisterNetEvent("ph-drugs:server:boilMixture", function(lab, mixture)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end


    if next(labStates[lab]["boiling"]) == nil then
        local slots = QBCore.Player.GetSlotsByItem(Player.PlayerData.items, "chemicalsolution")
        for _, itemslot in pairs(slots) do
            --look for items with info.name == itemname
            local item = Player.PlayerData.items[itemslot]
            if item.info.name then
                if item.info.name == mixture then
                    Player.Functions.RemoveItem("chemicalsolution", 1, itemslot)
                    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["chemicalsolution"], "remove", 1)
                    labStates[lab]["boiling"] = {mixture, CrimBalance.Drugs_Production_Meth["boilTimeSeconds"]}
                    labStates[lab]["boilingQuality"] = item.info.quality
                    break
                end
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'Something already boiling', 'error')
    end 
end)    


QBCore.Functions.CreateUseableItem("methbrickwhite", function(source, item)
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
		Player.Functions.AddItem(item.name, 1, theItem.info, {["quality"] = theItem.info.quality - (100/CrimBalance.Drugs_Processing_Meth)}) 

		TriggerClientEvent("ph-drugs:client:cutMethBrick", source, "methwhite")
	end
end)

QBCore.Functions.CreateUseableItem("methbrickblue", function(source, item)
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
		Player.Functions.AddItem(item.name, 1, theItem.info, {["quality"] = theItem.info.quality - (100/CrimBalance.Drugs_Processing_Meth)}) 

		TriggerClientEvent("ph-drugs:client:cutMethBrick", source, "methblue")
	end
end)
QBCore.Functions.CreateUseableItem("methbrickbrown", function(source, item)
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
		Player.Functions.AddItem(item.name, 1, theItem.info, {["quality"] = theItem.info.quality - (100/CrimBalance.Drugs_Processing_Meth)}) 

		TriggerClientEvent("ph-drugs:client:cutMethBrick", source, "methbrown")
	end
end)
RegisterNetEvent("ph-drugs:server:cutMethWith", function(cutwith, methitem)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local info = {}
    if cutwith then
        info.lacedWith = cutwith
        Player.Functions.RemoveItem(cutwith, 1, false)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[cutwith], "remove", 1)
    end

    Player.Functions.AddItem(methitem, 1, nil, info) 
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[methitem], "add", 1)
end)

CreateThread(function()
    while true do
        Wait(1000)
        for lab,_ in pairs(labStates) do
            if labStates[lab] then
                if next(labStates[lab]["boiling"])~=nil then
                    if labStates[lab]["boiling"][2] > 0 then
                        labStates[lab]["boiling"][2] = labStates[lab]["boiling"][2] - 1
                    end
                end
            end
        end
    end
end)