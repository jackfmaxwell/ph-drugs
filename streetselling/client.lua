local QBCore = exports['qb-core']:GetCoreObject() 

local availableDrugs = {}
local lastPed = {}

local stealPed = nil
local stolenItems = {}

local customerPed = nil

local numSalesRecently = 0

local refuseAnimations  = {
    {"mp_player_int_upper_nod", "mp_player_int_nod_no"},
    {"gestures@f@standing@casual", "gesture_shrug_hard"},
    {"gestures@m@standing@casual", "gesture_no_way"}
}
local acceptAnimations = {
    {"mp_common", "givetake1_a"}
}
--FUNCTIONS
function sellToPed(ped)
    for i = 1, #lastPed, 1 do
        if lastPed[i] == ped then
            return
        end
    end
    SetEntityAsNoLongerNeeded(ped)
    ClearPedTasks(ped)

    if IsPedDeadOrDying(ped) then return end

    TaskLookAtEntity(ped, PlayerPedId(), 5500.0, 2048, 3)
    TaskTurnPedToFaceEntity(ped, PlayerPedId(), 5500)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT", 0, false)

    --check which drug type the ped are
    local drugPreference = Config.LocalHashToDrugType[GetEntityModel(ped)] --{0} or {0,1}
    if not drugPreference then 
        SetPedTalk(ped)

        local chosenAnim = refuseAnimations[math.random(#refuseAnimations)]
        RequestAnimDict(chosenAnim[1])
        while not HasAnimDictLoaded(chosenAnim[1]) do
            Wait(0)
        end
        TaskPlayAnim(ped, chosenAnim[1], chosenAnim[2], 3.0, -8.0, -1, 0, 0, false, false, false)
        Wait(2000)

        ClearPedTasks(ped)

        TaskWanderStandard(ped, PlayerPedId()) 
        return 
    end
    --pick random outcome from drug preference
    local outcome = drugPreference[math.random(1,#drugPreference)]
    if outcome=="rob" or outcome==-1 then
        if math.random(100) <= CrimBalance.Drugs_StreetSelling.RobChance then
            local possibleDrugList = {}
            for _, k in pairs(drugPreference) do
                if k>0 then
                    if CrimBalance.Drugs_StreetSelling["drugClasses"][k] then
                        for _, j in pairs(CrimBalance.Drugs_StreetSelling["drugClasses"][k]) do
                            possibleDrugList[#possibleDrugList+1] = j
                        end
                    end
                   
                    
                end
            end

            TriggerServerEvent("ph-drugs:server:getRobbedByPed", availableDrugs, possibleDrugList)
            stealPed = ped
        end
        SetEntityAsNoLongerNeeded(ped)
        ClearPedTasks(ped)
        return
    elseif outcome==nil or outcome==0 then
        -- person may call cops
        SetPedTalk(ped)
        --REACT NO,
        local chosenAnim = refuseAnimations[math.random(#refuseAnimations)]
        RequestAnimDict(chosenAnim[1])
        while not HasAnimDictLoaded(chosenAnim[1]) do
            Wait(0)
        end
        TaskPlayAnim(ped, chosenAnim[1], chosenAnim[2], 3.0, -8.0, -1, 0, 0, false, false, false)

        Wait(1000)
        --keep walking
        ClearPedTasks(ped)

        if math.random(100) <= CrimBalance.Drugs_StreetSelling["SnitchCallCopsChance"] then
            --snitch
            TaskWanderStandard(ped) 
            Wait(5000)
            --SNITCH
            RequestAnimDict("cellphone@")
            while not HasAnimDictLoaded("cellphone@") do
                Wait(0)
            end
            TaskPlayAnim(ped, "cellphone@", "cellphone_call_listen_base", 8.0, -8.0, -1, 1, 0, false, false, false)
            Wait(2300)
            exports["ps-dispatch"]:SuspiciousActivity()
            ClearPedTasks(ped)

            --RUN AWAY
            TaskReactAndFleePed(ped, PlayerPedId())
            SetEntityAsNoLongerNeeded(ped)
        end
        

        return
    else 
        --preference is a drug category 
        customerPed = ped
        numSalesRecently = numSalesRecently+1
        if numSalesRecently>CrimBalance.Drugs_StreetSelling["numSalesReportHandoff"] then
            if math.random(100) <= CrimBalance.Drugs_StreetSelling["reportHandoffChance"] then
                exports["ps-dispatch"]:DrugSale()
                numSalesRecently = 0
            end
        end
        --build list of all drugs willing to buy {} but without -1 and 0
        local possibleDrugList = {}
        for _, k in pairs(drugPreference) do
            if k>0 then
                if CrimBalance.Drugs_StreetSelling["drugClasses"][k] then
                    for _, j in pairs(CrimBalance.Drugs_StreetSelling["drugClasses"][k]) do
                        possibleDrugList[#possibleDrugList+1] = j
                    end
                end
               
                
            end
        end
        TriggerServerEvent("ph-drugs:server:whichcanweoffer", possibleDrugList)
    end
   
end

function offerDrugsToNearby()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)

    local PlayerPeds = {}
    if next(PlayerPeds) == nil then
        for _, activePlayer in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(activePlayer)
            PlayerPeds[#PlayerPeds + 1] = ped
        end
    end

    local closestPed, closestDistance = QBCore.Functions.GetClosestPed(coords, PlayerPeds) --PlayerPeds ignore list
    if closestDistance < Config.SellDrugsRange and closestPed ~= 0 and not IsPedInAnyVehicle(closestPed) and GetPedType(closestPed) ~= 28 then
        sellToPed(closestPed)
    end
end



--EVENTS
RegisterNetEvent('ph-drugs:client:offerDrugs', function()
    if customerPed then
        SetEntityAsNoLongerNeeded(customerPed)
        ClearPedTasks(customerPed)
        customerPed = nil 
    end


    QBCore.Functions.TriggerCallback('ph-crimbalance:server:returnActiveCops', function(cops)
        CurrentCops = cops
        if not CurrentCops then QBCore.Functions.Notify("Cant do this right now", 'error') return end
        if CurrentCops >= Config.MinimumDrugSalePolice then
            --look for nearby locals
            QBCore.Functions.TriggerCallback('ph-drugs:server:getDrugsInInventory', function(result)
                if result then
                    availableDrugs = result
                    offerDrugsToNearby()
                else
                    QBCore.Functions.Notify("No drugs in inventory to offer", 'error')
                end
            end)
        else
            QBCore.Functions.Notify("Cant do this right now", 'error')
        end
    end)
end)

RegisterNetEvent("ph-drugs:client:offerDrug", function(data)
    local drugitem = data.item
    local drugInterested = data.drugInterested
    local dialog = exports['qb-input']:ShowInput({
        header = 'Sale price',
        submitText = 'Offer',
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'price',
                text = 'Price'
            },
            
        }
    })
    if dialog then
        if not dialog.price then return end
        TriggerServerEvent('ph-drugs:server:makeOfferToLocal', dialog.price, drugitem, drugInterested)
    end
end)

RegisterNetEvent("ph-drugs:client:showofferoptions", function(possibleDrugOffer, numDrugInterested)
    local drugOffers = {{header = 'Offer Drugs', isMenuHeader = true}}
    for i,k in pairs(possibleDrugOffer) do
        drugOffers[#drugOffers + 1] = {
            header = k.label,
            params = {
                event = 'ph-drugs:client:offerDrug',
                args = {
                    item = k.name,
                    drugInterested = numDrugInterested,
                }
            }
        }
    end
    exports['qb-menu']:openMenu(drugOffers)
end)

RegisterNetEvent("ph-drugs:client:gotRobbedOf", function(drugsRobbed)
    stolenItems = drugsRobbed
    local coords = GetEntityCoords(PlayerPedId())
    ClearPedTasksImmediately(stealPed)
  
    TaskCombatPed(stealPed, PlayerPedId())
    exports['qb-target']:RemoveZone('stealingPed')
    Wait(500)
    exports['qb-target']:AddEntityZone('stealingPed', stealPed, {
        name = 'stealingPed',
        debugPoly = false,
    }, {
        options = {
            {
                icon = 'fas fa-magnifying-glass',
                label = "Search ped",
                action = function()
                    local player = PlayerPedId()
                    RequestAnimDict("pickup_object")
                    while not HasAnimDictLoaded("pickup_object") do
                        Wait(0)
                    end
                    TaskPlayAnim(player, "pickup_object", "pickup_low", 8.0, -8.0, -1, 1, 0, false, false, false)
                    Wait(2000)
                    ClearPedTasks(player)
                    for i, k in pairs(stolenItems) do
                        TriggerServerEvent("QBCore:Server:AddItem", k, 1)
                        TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[k], "add")
                    end
                   
                    stealPed = nil
                    stolenItems = {}
                    exports['qb-target']:RemoveZone('stealingPed')
                end,
                canInteract = function(stealPed)
                    if IsEntityDead(stealPed) then
                        return true
                    end
                end
            }
        },
        distance = 1.5,
    })
    CreateThread(function()
        while stealPed do
            local playerPed = PlayerPedId()
            local pos = GetEntityCoords(playerPed)
            local pedpos = GetEntityCoords(stealPed)
            local dist = #(pos - pedpos)
            if dist > 100 then
                stealPed = nil
                stolenItems = {}
                exports['qb-target']:RemoveZone('stealingPed')
                break
            end
            Wait(2500)
        end
    end)
    Wait(1000)
    --ped Run away
    local movetoCoords = {x = coords.x + math.random(100, 500), y = coords.y + math.random(100, 500), z = coords.z, }

    --ClearPedTasksImmediately(stealPed)
    --TaskGoStraightToCoord(stealPed, movetoCoords.x, movetoCoords.y, movetoCoords.z, 15.0, -1, 0.0, 0.0)
    lastPed[#lastPed + 1] = stealPed

end)

RegisterNetEvent("ph-drugs:client:refuseOffer", function()
    lastPed[#lastPed + 1] = customerPed

    SetEntityAsNoLongerNeeded(customerPed)
    ClearPedTasks(customerPed)

    QBCore.Functions.Notify('Refuses deal', 'error')  

    local chosenAnim = refuseAnimations[math.random(#refuseAnimations)]

    RequestAnimDict(chosenAnim[1])
    while not HasAnimDictLoaded(chosenAnim[1]) do
        Wait(0)
    end
    TaskPlayAnim(customerPed, chosenAnim[1], chosenAnim[2], 3.0, -8.0, -1, 0, 0, false, false, false)

    customerPed = nil
end)

RegisterNetEvent("ph-drugs:client:acceptOffer", function()
    lastPed[#lastPed + 1] = customerPed

    SetEntityAsNoLongerNeeded(customerPed)
    ClearPedTasks(customerPed)

    RequestAnimDict(acceptAnimations[1][1])
    while not HasAnimDictLoaded(acceptAnimations[1][1]) do
        Wait(0)
    end
    TaskPlayAnim(customerPed, acceptAnimations[1][1], acceptAnimations[1][2], 3.0, -8.0, -1, 0, 0, false, false, false)

    customerPed = nil

    exports["ps-dispatch"]:DrugSale()

end)