local QBCore = exports['qb-core']:GetCoreObject()

--FUNCTIONS
local nearbyDistance = 20
local function GetNearbyPlayers()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local nearbyPlayers = {}
    local coords = GetEntityCoords(PlayerPedId())

    for i=1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)
            if distance <= nearbyDistance then
                table.insert(nearbyPlayers, GetPlayerPed(closestPlayers[i]))
            end

            
        end
	end

	return nearbyPlayers
end

function TrevorEffect()
    StartScreenEffect("DrugsTrevorClownsFightIn", 3.0, 0)
    Wait(3000)
    StartScreenEffect("DrugsTrevorClownsFight", 3.0, 0)
    Wait(3000)
	StartScreenEffect("DrugsTrevorClownsFightOut", 3.0, 0)
	StopScreenEffect("DrugsTrevorClownsFight")
	StopScreenEffect("DrugsTrevorClownsFightIn")
	StopScreenEffect("DrugsTrevorClownsFightOut")
end

function MethBagEffect(slow)
    local startStamina = 8
    if slow then startStamina = 4 end
    TrevorEffect()
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
    if slow then
        SetRunSprintMultiplierForPlayer(PlayerId(), 0.49)
    end
    while startStamina > 0 do
        Wait(1000)
        if math.random(5, 100) < 10 then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        startStamina = startStamina - 1
        if math.random(5, 100) < 51 then
            TrevorEffect()
        end
    end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end

function LSDEffect()
    local onset = Config.DrugEffectLSD["onset"]
    local duration = Config.DrugEffectLSD["duration"]
    --local Player = QBCore.Functions.GetPlayer(GetPlayerServerId(PlayerId()))

    CreateThread(function()
        local timer = 0
        ClearTimecycleModifier()
        SetTimecycleModifier("Drug_deadman")
        
        while timer < onset do
            SetTimecycleModifier("Drug_deadman")
            SetTimecycleModifierStrength((timer/onset)+0.1)

            Wait(4000)
            timer=timer+4000
        end
        --GOOD TRIP
        SetTimecycleModifier("Barry1_Stoned")
        SetTimecycleModifierStrength(1.5)
        --BAD TRIP

        timer = 0
        while timer < duration do
            SetTimecycleModifier("Barry1_Stoned")
            Wait(4000)
            timer=timer+4000
        end
        
        Wait(3000)
        ClearTimecycleModifier()
    end)
   
end

function disableEscape()
    while true do
        DisableControlAction(1, 75, true)
        Wait(1)
    end
end

function fentanylEffect()
    local onset = Config.DrugEffectFentanyl["onset"]
    local stage2onset = Config.DrugEffectFentanyl["stage2onset"]
    local duration = Config.DrugEffectFentanyl["duration"]
    --local Player = QBCore.Functions.GetPlayer(GetPlayerServerId(PlayerId()))

    
    CreateThread(function()
        local timer = 0
        ClearTimecycleModifier()
        SetTimecycleModifier("Drunk")
        
        while timer < onset do
            SetTimecycleModifier("Drunk")
            SetTimecycleModifierStrength((timer/onset)+0.23)

            Wait(4000)
            timer=timer+4000
        end

        local alone = true
        local players = GetNearbyPlayers()
        if next(players)==nil then
            alone = true
            
        end
        
        --stage 2
        timer =0
        while timer < stage2onset do
            SetTimecycleModifier("DRUG_gas_huffin")
            SetPedIsDrunk(PlayerPedId(), true)
            SetTimecycleModifierStrength((timer/stage2onset)*0.7)
            Wait(1000)
            timer = timer+1000
        end
        
        if alone then
            --kidnap
            local coords = GetEntityCoords(PlayerPedId())
            local nearestVeh = GetClosestVehicle(coords, 200.0, 0, 70)
            local nearestVehCoords = GetEntityCoords(nearestVeh)

            local model = "Speedo2"
            local model2 = "s_m_y_clown_01"
            while not HasModelLoaded(GetHashKey(model)) do
                RequestModel(GetHashKey(model))
                Wait(100)
            end
            while not HasModelLoaded(GetHashKey(model2)) do
                RequestModel(GetHashKey(model2))
                Wait(100)
            end
            DoScreenFadeOut(300)
            Wait(300)
            local kidnapper = CreatePed(1, GetHashKey(model2), nearestVehCoords, 0, true, true)
            local kidnapCar = CreateVehicle(GetHashKey(model), nearestVehCoords, 0, true, true)

            TaskWarpPedIntoVehicle(kidnapper, kidnapCar, -1)
            SetVehicleEngineOn(kidnapCar, true, false, false)
            Wait(500)
            --TaskPlayAnim(PlayerPedId(), 1500, 900, 1, GetEntityForwardVector(PlayerPedId()), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            TaskDriveBy(kidnapper, PlayerPedId(), 0, 0.0, 0.0, 2.0, 300.0, 100, 0, -753768974)
            --TaskVehicleDriveToCoord(kidnapper, kidnapCar, GetEntityCoords(PlayerPedId()), 25.0, 1.0, GetHashKey(model), 262716, 4.0)
            Wait(200)
            DoScreenFadeIn(300)
            while true do
                --hunt player
                Wait(1000)
                TaskVehicleDriveToCoord(kidnapper, kidnapCar, GetEntityCoords(PlayerPedId()), 25.0, 1.0, GetHashKey(model), 262716, 4.0)

                local kidnapperCoords = GetEntityCoords(kidnapper)
                local playerCoords = GetEntityCoords(PlayerPedId())
                if #(playerCoords-kidnapperCoords) < 6.0 then
                    --arrived at player
                    DoScreenFadeOut(300)
                    Wait(1500)
                    TaskWarpPedIntoVehicle(PlayerPedId(), kidnapCar, 1)
                    Wait(300)
                    TaskVehicleDriveToCoord(kidnapper, kidnapCar, vector3(1827.54, 3865.15, 33.69), 30.0, 1.0, GetHashKey(model), 262716, 3.0)
                    DoScreenFadeIn(1500)
                    Wait(1500)
                    print("arrived")
                    break
                end
            end
            
            TaskVehicleDriveToCoord(kidnapper, kidnapCar, vector3(1827.54, 3865.15, 33.69), 90.0, 1.0, GetHashKey(model), 786492, 3.0)
            
            CreateThread(function()
                disableEscape()
            end)
            CreateThread(function()
                timer = 0
                while timer < duration do
                    DoScreenFadeOut(300)
                    Wait(1000)
                    DoScreenFadeIn(300)
                    Wait(3000)
                    timer=timer+4000
                end
    
                DoScreenFadeOut(300)
                Wait(1000)
                TaskVehicleDriveWander(kidnapper, kidnapCar, 30.0, 319)
                SetEntityCoords(PlayerPedId(), vector3(871.96, 2878.56, 57.26), true, false, false, false)
                Wait(1000)
                DoScreenFadeIn(300)
                
            end)
            Wait(3000)
            ClearTimecycleModifier()

        end
        
       
    end)
    TriggerEvent("evidence:client:SetStatus", "confused", 200)
end

--THREADS

RegisterNetEvent('ph-drugs:client:UseFentanyl', function()
    local ped = PlayerPedId()

    QBCore.Functions.Progressbar("use_fentanyl","Taking Fentanyl", 3000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
		disableMouse = false,
		disableCombat = true,
    }, {
		animDict = "mp_suicide",
		anim = "pill",
		flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        fentanylEffect()
    end, function() -- Cancel
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        QBCore.Functions.Notify(Lang:t('error.canceled'), "error")
    end)
end)

RegisterNetEvent("ph-drugs:client:use_meth", function(itemname)
    TriggerServerEvent("QBCore:Server:RemoveItem", itemname, 1)
    TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items[itemname], "remove")
    QBCore.Functions.Progressbar("snort_meth", "Smoking Meth", 1500, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "switch@trevor@trev_smoking_meth",
        anim = "trev_smoking_meth_loop",
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), "switch@trevor@trev_smoking_meth", "trev_smoking_meth_loop", 1.0)
        TriggerEvent("evidence:client:SetStatus", "widepupils", 300)
		TriggerEvent("evidence:client:SetStatus", "agitated", 300)

        if itemname == "methbrown" then
            MethBagEffect(true)
        else
            MethBagEffect(false)
        end

    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), "switch@trevor@trev_smoking_meth", "trev_smoking_meth_loop", 1.0)
        QBCore.Functions.Notify("Canceled..", "error")
        TriggerServerEvent("QBCore:Server:AddItem", itemname, 1)
	end)
end)
RegisterNetEvent("ph-drugs:client:use_lsd", function(itemname)
    TriggerServerEvent("QBCore:Server:RemoveItem", itemname, 1)
    TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items[itemname], "remove")
    QBCore.Functions.Progressbar("snort_meth", "Taking LSD", 1500, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "mp_suicide",
		anim = "pill",
        flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(PlayerPedId(), "mp_suicide", "pill", 1.0)
        TriggerEvent("evidence:client:SetStatus", "widepupils", 300)
        LSDEffect()

    end, function() -- Cancel
        StopAnimTask(PlayerPedId(), "mp_suicide", "pill", 1.0)
        QBCore.Functions.Notify("Canceled..", "error")
        TriggerServerEvent("QBCore:Server:AddItem", itemname, 1)
	end)
end)


RegisterNetEvent("ph-drugs:client:use_lacedDrug", function(laceitem)
    print("laced with", laceitem)
    if laceitem=="rock" then
        SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) - 20)
    end
    if laceitem=="glass" then
        SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) - 90)
    end
end)


RegisterNetEvent("ph-drugs:client:testScreenEffect", function(effectname)
    QBCore.Functions.Notify("Viewing effect: "..effectname, "error")
    SetTimecycleModifier(effectname)
end)