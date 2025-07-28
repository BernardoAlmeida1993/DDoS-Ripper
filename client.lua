function PickupPackage()
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped, true)
    
    -- Use the correct carrying animation
    RequestAnimDict("anim@heists@box_carry@")
    while (not HasAnimDictLoaded("anim@heists@box_carry@")) do
        Citizen.Wait(7)
    end
    
    -- Use the walking animation instead of idle for proper carrying
    TaskPlayAnim(ped, "anim@heists@box_carry@", "walk", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    local model = GetHashKey("prop_cs_cardbox_01")
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(0) end
    
    local object = CreateObject(model, pos.x, pos.y, pos.z, true, true, true)
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, 57005), 0.05, 0.1, -0.3, 300.0, 250.0, 20.0, true, true, false, true, 1, true)
    carryPackage = object
    
    -- Keep the animation playing while carrying
    Citizen.CreateThread(function()
        while carryPackage ~= nil do
            if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "walk", 3) then
                TaskPlayAnim(ped, "anim@heists@box_carry@", "walk", 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            Citizen.Wait(1000)
        end
    end)
end

function DropPackage()
    local ped = GetPlayerPed(-1)
    
    -- Stop the carrying animation
    StopAnimTask(ped, "anim@heists@box_carry@", "walk", 1.0)
    ClearPedTasks(ped)
    
    -- Remove the package
    if carryPackage ~= nil then
        DetachEntity(carryPackage, true, true)
        DeleteObject(carryPackage)
        carryPackage = nil
    end
end