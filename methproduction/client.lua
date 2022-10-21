local QBCore = exports['qb-core']:GetCoreObject() 


--FUNCTIONS

--EVENTS
RegisterNetEvent("ph-drugs:client:processIngredient", function(ingredients, time, progress_message, resultants)
    QBCore.Functions.TriggerCallback('ph-drugs:server:validate_items', function(result)
		if result then
			--Crush suda
            local ped = PlayerPedId()
        
            TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
            QBCore.Functions.Progressbar("processing_drugs", progress_message, time, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                TriggerServerEvent("ph-drugs:server:processIngredient", ingredients, resultants)
        
                ClearPedTasks(ped)
            end, function()
                ClearPedTasks(ped)
            end)
		else
			QBCore.Functions.Notify("Cannot do this", 'error')
		end
	end, ingredients)
end)

RegisterNetEvent("ph-drugs:client:failProcess", function(ingredientLose)
    QBCore.Functions.Notify("Fail", 'error')
    TriggerServerEvent("QBCore:Server:RemoveItem", ingredientLose, 1)
    TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items[ingredientLose], "remove")
end)

RegisterNetEvent("ph-drugs:client:emptyBeaker", function(data) 
    local lab = data.lab
    local place = data.place
    TriggerServerEvent("ph-drugs:server:emptyBeaker", lab, place)
end)
RegisterNetEvent("ph-drugs:client:addBeakerLogic", function(data) 
    local lab = data.lab
    local place = data.place
    local itemname = data.itemname
    exports['ps-ui']:Circle(function(success)
        if success then
            local ped = PlayerPedId()
        
            TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
            QBCore.Functions.Progressbar("processing_drugs", "Adding to beaker", 1500, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                TriggerServerEvent("ph-drugs:server:addBeaker", lab, place, itemname)
        
                ClearPedTasks(ped)
            end, function()
                ClearPedTasks(ped)
            end)
            
        else
            if CrimBalance.Drugs_Production_Meth["beakerExplodableIngredients"][itemname] then
                --check explosion chance, otherwise reduce quality
                if math.random(100) <= CrimBalance.Drugs_Production_Meth["failSkillExplodeChance"] then
                    QBCore.Functions.Notify("The air feels warmer...", 'error')
                    local ped = PlayerPedId()
                    local coords = vector3(GetEntityCoords(ped).x, GetEntityCoords(ped).y, GetEntityCoords(ped).z+0.5) 
                    Wait(3000)

                    AddExplosion(coords, 49, 1, 1, 0, 1)
                    TriggerServerEvent("ph-drugs:server:emptyBeaker", lab, "beaker1")
                    TriggerServerEvent("ph-drugs:server:emptyBeaker", lab, "beaker2")
                else
                    --add to beaker but quality worse
                    TriggerServerEvent("ph-drugs:server:addBeaker", lab, place, itemname, 
                    CrimBalance.Drugs_Production_Meth["hydroiodicacidFailQualityReduce"])
                end
            elseif CrimBalance.Drugs_Production_Meth["beakerSensitiveIngredients"][itemname] then
                TriggerServerEvent("ph-drugs:server:addBeaker", lab, place, itemname, 
                CrimBalance.Drugs_Production_Meth["beakerSensitiveIngredients"][itemname])
            end
        end
    end, math.random(1,3), math.random(10, 14)) -- NumberOfCircles, MS
end)
RegisterNetEvent("ph-drugs:client:addBeakerMenu", function(data) 
    local lab = data.lab
    local place = data.place
    --what would you like to add?
    QBCore.Functions.TriggerCallback('ph-drugs:server:getBeakerableItems', function(result)
        local beaker = {{header = 'Add to beaker:', isMenuHeader = true}}
		if result then
            for _, k in pairs(result) do
                if k.name then
                    beaker[#beaker + 1] = {
                        header = QBCore.Shared.Items[k.name].label,
                        params = {
                            event = "ph-drugs:client:addBeakerLogic",
                            args = {
                                lab = lab,
                                place = place,
                                itemname = k.name,
                            }
                        }
                    }
                else
                    beaker[#beaker + 1] = {
                        header = Config.NonItemNameToLabel[k],
                        params = {
                            event = "ph-drugs:client:addBeakerLogic",
                            args = {
                                lab = lab,
                                place = place,
                                itemname = k,
                            }
                        }
                    }
                end
               
            end
          
        end
        exports['qb-menu']:openMenu(beaker)
	end)
   
end)
RegisterNetEvent("ph-drugs:client:extractSolutionBeaker", function(data) 
    local lab = data.lab
    local place = data.place
    local ped = PlayerPedId()
        
    TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
    QBCore.Functions.Progressbar("processing_drugs", "Reaction finishing", math.random(6000, 12000), false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        TriggerServerEvent("ph-drugs:server:extractSolution", lab, place)

        ClearPedTasks(ped)
    end, function()
        ClearPedTasks(ped)
    end)
   
end)

RegisterNetEvent("ph-drugs:client:inspectBeaker", function(sentlab, sentplace)
    --get beaker data from server, show in menu
    local data = {
        lab = sentlab,
        place = sentplace,
    }
    QBCore.Functions.TriggerCallback('ph-drugs:server:getLabSate', function(result)
		if result then
            local beakerstate = {{header = 'Beaker:', isMenuHeader = true}}
            
			for name, amount in pairs(result) do
                if QBCore.Shared.Items[name] then
                    beakerstate[#beakerstate + 1] = {
                        header = QBCore.Shared.Items[name].label .. " x" .. amount,
                        isMenuHeader = true,
                        params = {
                            event = '',
                        }
                    }
                else
                    beakerstate[#beakerstate + 1] = {
                        header = Config.NonItemNameToLabel[name] .. " x" .. amount,
                        isMenuHeader = true,
                        params = {
                            event = '',
                        }
                    }
                end
                
            end
            beakerstate[#beakerstate + 1] = {
                header = "Empty beaker",
                params = {
                    event = 'ph-drugs:client:emptyBeaker',
                    args = {
                        lab = sentlab,
                        place = sentplace,
                    },
                }
            }
            beakerstate[#beakerstate + 1] = {
                header = "Add to beaker",
                params = {
                    event = 'ph-drugs:client:addBeakerMenu',
                    args = {
                        lab = sentlab,
                        place = sentplace,
                    },
                }
            }
            beakerstate[#beakerstate + 1] = {
                header = "Extract solution",
                params = {
                    event = 'ph-drugs:client:extractSolutionBeaker',
                    args = {
                        lab = sentlab,
                        place = sentplace,
                    },
                }
            }
            exports['qb-menu']:openMenu(beakerstate)
		end
	end, data)
end)

RegisterNetEvent("ph-drugs:client:processMixtureLogic", function(data)
    exports['ps-ui']:Circle(function(success)
        if success then
            if data.process == "boil" then
                TriggerServerEvent("ph-drugs:server:boilMixture", data.lab, data.itemname)
            end
            if data.process=="strain" then
                local ped = PlayerPedId()
                
                TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
                QBCore.Functions.Progressbar("processing_drugs", "Straining solution", 1500, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function()
                    TriggerServerEvent("ph-drugs:server:recieveCompleteMixture", data.lab, data.itemname, "strain")
                    
                    ClearPedTasks(ped)
                end, function()
                    ClearPedTasks(ped)
                end)
            end
            if data.process=="bubble" then
                local ped = PlayerPedId()
                
                TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
                QBCore.Functions.Progressbar("processing_drugs", "Bubbling solution with HCI gas", 6000, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function()
                    TriggerServerEvent("ph-drugs:server:finalMethProcess", data.itemname)
                    
                    ClearPedTasks(ped)
                end, function()
                    ClearPedTasks(ped)
                end)
            end
        else
             --check explosion chance, otherwise reduce quality
             if math.random(100) <= CrimBalance.Drugs_Production_Meth["failSkillProcessMixtureExplodeChance"] then
                QBCore.Functions.Notify("The air feels warmer...", 'error')
                local ped = PlayerPedId()
                local coords = vector3(GetEntityCoords(ped).x, GetEntityCoords(ped).y, GetEntityCoords(ped).z+0.5) 
                Wait(5000)

                AddExplosion(coords, 49, 1, 1, 0, 1)
                TriggerServerEvent("ph-drugs:server:emptyBeaker", lab, "beaker1")
                TriggerServerEvent("ph-drugs:server:emptyBeaker", lab, "beaker2")
            else
                --add to beaker but quality worse
                TriggerServerEvent("ph-drugs:server:addBeaker", lab, place, itemname, CrimBalance.Drugs_Production_Meth["hydroiodicacidFailQualityReduce"])
            end
        end
    end, 2, 10) -- NumberOfCircles, MS
end)
RegisterNetEvent("ph-drugs:client:processMixture", function(lab, proc)
    --show all mixtures
    QBCore.Functions.TriggerCallback('ph-drugs:server:getMixtures', function(result)
        local solutions = {{header = 'Choose Mixture:', isMenuHeader = true}}
		if result then
            for _, k in pairs(result) do
                solutions[#solutions + 1] = {
                    header = Config.NonItemNameToLabel[k],
                    params = {
                        event = "ph-drugs:client:processMixtureLogic",
                        args = {
                            lab = lab,
                            itemname = k,
                            process = proc,
                        }
                    }
                }
            end
          
        end
        exports['qb-menu']:openMenu(solutions)
	end)
end)
RegisterNetEvent("ph-drugs:client:checkMixture", function(lab, proc)
    local data = {
        lab = lab,
    }
    QBCore.Functions.TriggerCallback('ph-drugs:server:getBoilState', function(result)
        local state = {{header = 'Boiling:', isMenuHeader = true}}
		if result then
            if result[2] then
                if result[2] <= 0 then
                    --mixture done
                    --give mixture with name result[1]
                    TriggerServerEvent("ph-drugs:server:recieveCompleteMixture", lab, result[1], "boil")
                else
                    state[#state + 1] = {
                        header = Config.NonItemNameToLabel[result[1]] .. " | " .. result[2] .. "s",
                    }
                    exports['qb-menu']:openMenu(state)
                end

            else
                QBCore.Functions.Notify("Nothing boiling", 'error')
            end
          
        end
      
	end, data)
end)

RegisterNetEvent("ph-drugs:client:cutMethWith", function(data)
    local cut_thing = data.cutThing
    local meth_type = data.methtype

    local ped = PlayerPedId()
        
    TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
    QBCore.Functions.Progressbar("processing_drugs", "Bagging meth", 1000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        TriggerServerEvent("ph-drugs:server:cutMethWith", cut_thing, meth_type)
        
        ClearPedTasks(ped)
    end, function()
        ClearPedTasks(ped)
    end)
end)

RegisterNetEvent("ph-drugs:client:cutMethBrick", function(item)
    local cutbrick = {{header = 'Cut Meth with:', isMenuHeader = true}}
    cutbrick[#cutbrick + 1] = {
        header = "Nothing",
        params = {
            event = "ph-drugs:client:cutMethWith",
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
                        event = "ph-drugs:client:cutMethWith",
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

--Lab targets
    --low tier
CreateThread(function()
    exports['qb-target']:AddBoxZone("methprocessing_lowquality_salvagestuff", CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["salvagestuff"], 1.8, 1.8, {
        name = "methprocessing_lowquality_salvagestuff",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["salvagestuff"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["salvagestuff"].z + 1,
    }, {
        options = {
            {  
                icon = "fas fa-mortar-pestle",
                label = "Crush Sudafed",
                action = function()
                    TriggerEvent("ph-drugs:client:processIngredient", {sudafed = 15}, 3000, "Crushing Pills", {ephedrine = 1})
                end,
            },
            {  
                icon = "fas fa-screwdriver",
                label = "Scrape matchboxes",
                action = function()
                    exports['ps-ui']:Circle(function(success)
                        if success then
                            TriggerEvent("ph-drugs:client:processIngredient", {matchbox = 8}, 3000, "Scraping matchboxes", {redphosphorus = 1})
                        else
                           TriggerEvent("ph-drugs:client:failProcess", matchbox)
                        end
                    end, 2, 15) -- NumberOfCircles, MS
                    
                end,
            },
        },
        distance = 1.5
    })

    exports['qb-target']:AddBoxZone("methprocessing_lowquality_chemposition1", CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["chemposition1"], 1.8, 1.8, {
        name = "methprocessing_lowquality_chemposition1",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["chemposition1"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["chemposition1"].z + 1,
    }, {
        options = {
            {
                icon="fas fa-flask",
                label="Inspect Beaker",
                action = function()
                    TriggerEvent("ph-drugs:client:inspectBeaker", "lowtierlab", "beaker1")
                end,
            },
          
        },
        distance = 1.5
    })


    exports['qb-target']:AddBoxZone("methprocessing_lowquality_chemposition2", CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["chemposition2"], 1.8, 1.8, {
        name = "methprocessing_lowquality_chemposition2",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["chemposition2"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["chemposition2"].z + 1,
    }, {
        options = {
            {
                icon="fas fa-flask",
                label="Inspect Beaker",
                action = function()
                    TriggerEvent("ph-drugs:client:inspectBeaker", "lowtierlab", "beaker2")
                end,
            },
        },
        distance = 1.5
    })


    exports['qb-target']:AddBoxZone("methprocessing_lowquality_boilforday", CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["boilforday"], 1.8, 1.8, {
        name = "methprocessing_lowquality_boilforday",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["boilforday"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["boilforday"].z + 1,
    }, {
        options = {
            {  
                icon = "fas fa-fire",
                label = "Boil Mixture",
                action = function()
                    TriggerEvent("ph-drugs:client:processMixture", "lowtierlab", "boil")
                end,
            },
            {  
                icon = "fas fa-fire",
                label = "Check boiling mixture",
                action = function()
                    TriggerEvent("ph-drugs:client:checkMixture", "lowtierlab", "boil")
                end,
            },
           
        },
        distance = 1.5
    })



    exports['qb-target']:AddBoxZone("methprocessing_lowquality_finalsteps", CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["finalsteps"], 1.8, 1.8, {
        name = "methprocessing_lowquality_finalsteps",
        debugPoly = Config.DebugPoly,
        minZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["finalsteps"].z - 1,
        maxZ = CrimBalance.Drugs_Production_Meth.lowTierLab_Coords["finalsteps"].z + 1,
    }, {
        options = {
            {  
                icon = "fas fa-filter",
                label = "Strain Solution",
                action = function()
                    TriggerEvent("ph-drugs:client:processMixture", "lowtierlab", "strain")
                end,
            },  
            {  
                icon = "fas fa-fire",
                label = "Bubble Mixture with gas",
                action = function()
                    TriggerEvent("ph-drugs:client:processMixture", "lowtierlab", "bubble")
                end,
            },
        },
        distance = 1.5
    })
end)