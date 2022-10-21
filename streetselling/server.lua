local QBCore = exports['qb-core']:GetCoreObject() 

QBCore.Functions.CreateCallback("ph-drugs:server:getDrugsInInventory", function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local drugsInInv = {}
    for _,k in pairs(Config.SellableDrugs) do
        if (type(k) == "table") then
            for _, j in pairs(k) do
                local item = Player.Functions.GetItemByName(j)
                if item then
                    hasDrugs=true
                    drugsInInv[#drugsInInv+1] = j
                end
            end
        else
            local item = Player.Functions.GetItemByName(k)
            if item then
                hasDrugs=true
                drugsInInv[#drugsInInv+1] = k
            end
        end
       
       
    end

    cb(drugsInInv)
end)

RegisterNetEvent("ph-drugs:server:getRobbedByPed", function(drugPedWants)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local drugsStolen = {}
    local numDrugsStolen = math.random(1,CrimBalance.Drugs_StreetSelling.RobAmount) 
    for i = 1, numDrugsStolen, 1 do
        for _, k in pairs(drugPedWants) do 
            local item = Player.Functions.RemoveItem(k, 1)
            if item then drugsStolen[#drugsStolen+1] = k  TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[k], "remove") end

        end
    end
    if #drugsStolen > 0 then
        TriggerClientEvent("ph-drugs:client:gotRobbedOf", src, drugsStolen)
    else
        TriggerClientEvent("ph-drugs:client:refuseOffer", src)
    end
end)

RegisterNetEvent("ph-drugs:server:whichcanweoffer", function(drugPreference)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local possibleDrugOffer = {}
    for i, k in pairs(drugPreference) do
        if (type(k) == "table") then
            for _, j in pairs(k) do
                local item = Player.Functions.GetItemByName(j)
                if item then 
                    possibleDrugOffer[#possibleDrugOffer+1] = item 
                end
            end
        else
            local item = Player.Functions.GetItemByName(k)
            if item then 
                possibleDrugOffer[#possibleDrugOffer+1] = item 
            end
        end
     
    end 
    TriggerClientEvent("ph-drugs:client:showofferoptions", src, possibleDrugOffer, #drugPreference)
end)

RegisterNetEvent("ph-drugs:server:makeOfferToLocal", function(price, drugitem, numDrugsInterested)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    --num drugs interested gives an idea of how well the person knows street prices (how tight/low range is)

    --price is the price the player is trying to offer


    --Create range using peds street knowledge
    local sellRange = {}
    local price = tonumber(price)

    if numDrugsInterested >= CrimBalance.Drugs_StreetSelling.NumDrugsToBeStreetSmart then
        sellRange = CrimBalance.Drugs_StreetSelling["drugStreetPrices"][drugitem]
    else
        sellRange = CrimBalance.Drugs_StreetSelling["drugDumbPrices"][drugitem]
    end 

    if price<= sellRange[2] then
        --PRICE IS RIGHT!
        Player.Functions.RemoveItem(drugitem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[drugitem], "remove")
        --remove drug
        --give cash
        --Player.Functions.AddMoney('cash', price) 

        local info = {}
        info.legit = false
        info.value = price
        Player.Functions.AddItem("cashbill", 1, nil, info)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["cashbill"], "add", 1) 
        TriggerClientEvent("ph-drugs:client:acceptOffer", src)
    else
        --Price too high
        --tell player price is too high
        TriggerClientEvent("ph-drugs:client:refuseOffer", src)
    end
end)