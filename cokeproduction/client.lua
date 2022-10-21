local QBCore = exports['qb-core']:GetCoreObject() 
local missionblip = nil


--EVENTS
RegisterNetEvent("ph-drugs:client:waitCokeRunEmail", function()
    TriggerServerEvent('qb-phone:server:sendNewMail', {
        sender = "Coke Contact",
        subject = "Shipment",
        message = "I'll send you the pickup details shortly, finalizing details with my import guys.",
        button = {}
    })
    CreateThread(function()
        
        Wait(CrimBalance.Drugs_CokeRun["maildelay"]*1*1000)
        --send email
        --pick random pickup spot
        local numpickupspots = tonumber(#(CrimBalance.Drugs_CokeRun["pickupSpots"]))
        local pickupspot = CrimBalance.Drugs_CokeRun.pickupSpots[math.random(numpickupspots)]
        print(pickupspot)
        pickupspot = pickupspot[math.random(tonumber(#pickupspot))]
        print(pickupspot)

        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = "Coke Contact",
            subject = "Shipment",
            message = "The shipment has arrived its location is marked on your GPS",
            button = {}
        })
        --create pickup target?
        if missionblip then
            RemoveBlip(missionblip)
        end
        missionblip = AddBlipForCoord(pickupspot)
        SetBlipColour(missionblip, 1)
        SetBlipRoute(missionblip, true)
        SetBlipRouteColour(missionblip, 1)

        local randomval = math.random(100)
        exports["qb-target"]:RemoveZone("cokerun_targetlocation"..GetPlayerServerId(PlayerPedId()))
        exports['qb-target']:AddBoxZone("cokerun_targetlocation"..GetPlayerServerId(PlayerPedId()), pickupspot, 1.8, 1.8, {
            name = "cokerun_targetlocation"..GetPlayerServerId(PlayerPedId()),
            debugPoly = Config.DebugPoly,
            minZ = pickupspot.z - 1,
            maxZ = pickupspot.z + 2,
        }, {
            options = {
                {
                    icon="fas fa-box",
                    label="Take Drug Package",
                    action = function()
                        local ped = PlayerPedId()
        
                        TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
                        QBCore.Functions.Progressbar("taking_package", "Taking Package", 9000, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        }, {}, {}, {}, function()
                            TriggerServerEvent("ph-drugs:server:pickupCokePackage")
                            exports["qb-target"]:RemoveZone("cokerun_targetlocation"..GetPlayerServerId(PlayerPedId()))
                            
                            ClearPedTasks(ped)
                        end, function()
                            ClearPedTasks(ped)
                        end)
                    end,
                },
              
            },
            distance = 1.5
        })

        Wait(CrimBalance.Drugs_CokeRun["crimheadstart"]*60*1000)

        --CALL COP ALERT
        exports["ps-dispatch"]:IllegalImport(pickupspot)
    end)
end)

RegisterNetEvent("ph-drugs:client:cutCokeWith", function(data)
    local cut_thing = data.cutThing
    local meth_type = data.methtype

    local ped = PlayerPedId()
        
    TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
    QBCore.Functions.Progressbar("processing_drugs", "Bagging coke", 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        TriggerServerEvent("ph-drugs:server:cutCokeWith", cut_thing, meth_type)
        
        ClearPedTasks(ped)
    end, function()
        ClearPedTasks(ped)
    end)
end)

RegisterNetEvent("ph-drugs:client:cutCokeBrick", function(item)
    local cutbrick = {{header = 'Cut Coke with:', isMenuHeader = true}}
    cutbrick[#cutbrick + 1] = {
        header = "Nothing",
        params = {
            event = "ph-drugs:client:cutCokeWith",
            args = {
                cutThing = "",
                methtype=item,
            }
        }
    }
    QBCore.Functions.TriggerCallback('ph-drugs:server:getCuttableThings', function(result)
		if result then
            for _, k in pairs(result) do
                cutbrick[#cutbrick + 1] = {
                    header = QBCore.Shared.Items[k].label,
                    params = {
                        event = "ph-drugs:client:cutCokeWith",
                        args = {
                            cutThing = k,
                            methtype=item,
                        }
                    }
                }
            end
        end
        exports['qb-menu']:openMenu(cutbrick)
	end)
   
    
    
end)


--THREADS
    --coke lab
CreateThread(function()
    exports['qb-target']:AddBoxZone("cokeprocessing_entrance", CrimBalance.Drugs_Production_Coke.cokelab1["entrance"], 1.8, 1.8, {
        name = "cokeprocessing_entrance",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Coke.cokelab1["entrance"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Coke.cokelab1["entrance"].z + 1,
    }, {
        options = {
            {  
                icon = "fas fa-door-open",
                label = "Enter Building",
                action = function()
                    --teleport to spot, set to bucket
                    local ped = PlayerPedId()
                
                    QBCore.Functions.Progressbar("entering", "Entering Building", 3500, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function()
                        SetEntityCoords(PlayerPedId(), CrimBalance.Drugs_Production_Coke.cokelab1["inside"])
                        TriggerServerEvent("ph-drugs:server:enterLabBucket", CrimBalance.Drugs_Production_Meth.cokelab1["bucket"])
                       

                        ClearPedTasks(ped)
                    end, function()
                        ClearPedTasks(ped)
                    end)
                end,
            },
        },
        distance = 1.5
    })
    exports['qb-target']:AddBoxZone("cokeprocessing_exit", CrimBalance.Drugs_Production_Coke.cokelab1["inside"], 1.8, 1.8, {
        name = "cokeprocessing_exit",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Coke.cokelab1["inside"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Coke.cokelab1["inside"].z + 1,
    }, {
        options = {
            {  
                icon = "fas fa-door-open",
                label = "Exit Building",
                action = function()
                    --teleport to spot, set to bucket
                    local ped = PlayerPedId()
                
                    QBCore.Functions.Progressbar("entering", "Exiting Building", 3500, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function()
                        SetEntityCoords(PlayerPedId(), CrimBalance.Drugs_Production_Coke.cokelab1["entrance"])
                        TriggerServerEvent("ph-drugs:server:exitLabBucket")

                        ClearPedTasks(ped)
                    end, function()
                        ClearPedTasks(ped)
                    end)
                    
                end,
            },
        },
        distance = 1.5
    })

    exports['qb-target']:AddBoxZone("cokeprocessing_crushleaves", CrimBalance.Drugs_Production_Coke.cokelab1["leaveprocesssing"], 1.8, 1.8, {
        name = "cokeprocessing_crushleaves",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Coke.cokelab1["leaveprocesssing"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Coke.cokelab1["leaveprocesssing"].z + 1,
    }, {
        options = {
            {  
                icon = "fas fa-mortar-pestle",
                label = "Crush Leaves",
                action = function()
                    TriggerEvent("ph-drugs:client:processIngredient", {cokeleavespackage = 1}, 7500, "Crushing Coca Leaves", {cokeleaves = 1})
                end,
            },
            {  
                icon = "fas fa-flask",
                label = "Inspect Beaker", --add leaves, add cement, add gas , add drain cleaner, shows time for how long its been in barrel
                action = function()
                    TriggerEvent("ph-drugs:client:inspectBeaker", "cokelab1", "beaker1")
                end,
            },
        },
        distance = 1.5
    })

    exports['qb-target']:AddBoxZone("cokeprocessing_filtersolution", CrimBalance.Drugs_Production_Coke.cokelab1["filtersolution"], 1.8, 1.8, {
        name = "cokeprocessing_filtersolution",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Coke.cokelab1["filtersolution"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Coke.cokelab1["filtersolution"].z + 1,
    }, {
        options = {
            {  
                icon = "fas fa-filter",
                label = "Filter Solution",
                action = function()
                    TriggerEvent("ph-drugs:client:processMixture", "cokelab1", "strain")
                end,
            },
            {  
                icon = "fas fa-flask",
                label = "Inspect Barrel", --add drain cleaner, add potassium salt
                action = function()
                    TriggerEvent("ph-drugs:client:inspectBeaker", "cokelab1", "beaker2")
                end,
            },
          
        },
        distance = 1.5
    })


    exports['qb-target']:AddBoxZone("cokeprocessing_heatsolution", CrimBalance.Drugs_Production_Coke.cokelab1["heatsolution"], 1.8, 1.8, {
        name = "cokeprocessing_heatsolution",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Coke.cokelab1["heatsolution"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Coke.cokelab1["heatsolution"].z + 1,
    }, {
        options = {
            {  
                icon = "fas fa-fire",
                label = "Boil Mixture", --heat solution to get cocaine rocks
                action = function()
                    TriggerEvent("ph-drugs:client:processMixture", "cokelab1", "boil")
                end,
            },
            {  
                icon = "fas fa-fire",
                label = "Check boiling mixture",
                action = function()
                    TriggerEvent("ph-drugs:client:checkMixture", "cokelab1", "boil")
                end,
            },
            {  
                icon = "fas fa-mortar-pestle",
                label = "Make Crack",
                action = function()
                    TriggerEvent("ph-drugs:client:processIngredient", {cokebaggy = 1, bakingsoda = 1}, 7500, "Mixing bakingsoda in", {crack_baggy = math.random(2,3)})
                end,
            },
        },
        distance = 1.5
    })

end)
    --cokeleaves run
CreateThread(function()
    RequestModel(`g_m_y_mexgang_01`)
    while not HasModelLoaded(`g_m_y_mexgang_01`) do
        Wait(1)
    end
    cokecontact = CreatePed(1, `g_m_y_mexgang_01`, CrimBalance.Drugs_CokeRun["pedcoords"], false, false) -- change here the cords for the ped 
    SetPedFleeAttributes(cokecontact, 0, 0)
    SetPedDiesWhenInjured(cokecontact, false)
    TaskStartScenarioInPlace(cokecontact, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
    SetPedKeepTask(cokecontact, true)
    SetBlockingOfNonTemporaryEvents(cokecontact, true)
    SetEntityInvincible(cokecontact, true)
    FreezeEntityPosition(cokecontact, true)


    --add target
    exports['qb-target']:AddTargetModel('g_m_y_mexgang_01', {
        options = {
            {  
                icon = "fas fa-clipboard",
                label = "Import Coca Leaves $"..CrimBalance.Drugs_CokeRun["ordercost"],
                action = function()
                    --check availablity with global crim manager
                    QBCore.Functions.TriggerCallback('ph-crimbalance:server:crimActivityAuthorize', function(valid)
                        if valid then
                            TriggerServerEvent("ph-drugs:server:requestCokeRun")
                        else
                            QBCore.Functions.Notify("No orders available", 'error')
                        end
                    end, "Coke Run")
                end,
            },
        },
        distance = 3.0
    })
end)