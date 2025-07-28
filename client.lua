function PickupPackage()
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped, true)
    
    -- Load the animation dictionary
    RequestAnimDict("anim@heists@box_carry@")
    while (not HasAnimDictLoaded("anim@heists@box_carry@")) do
        Citizen.Wait(7)
    end
    
    -- Load the box model
    local model = GetHashKey("prop_cs_cardbox_01")
    RequestModel(model)
    while not HasModelLoaded(model) do 
        Citizen.Wait(0) 
    end
    
    -- Create the box object
    local object = CreateObject(model, pos.x, pos.y, pos.z, true, true, true)
    
    -- Start the carrying animation
    TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -1, -1, 50, 0, false, false, false)
    
    -- Wait a moment for the animation to start
    Citizen.Wait(200)
    
    -- Attach the box to the player's hands
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
    
    carryPackage = object
    
    -- Keep the animation playing while carrying
    Citizen.CreateThread(function()
        while carryPackage ~= nil do
            if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "idle", 3) then
                TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, -1, -1, 50, 0, false, false, false)
            end
            Citizen.Wait(1000)
        end
    end)
end

function DropPackage()
    local ped = GetPlayerPed(-1)
    
    -- Stop the carrying animation
    StopAnimTask(ped, "anim@heists@box_carry@", "idle", 1.0)
    ClearPedTasks(ped)
    
    -- Detach and delete the package
    if carryPackage ~= nil then
        DetachEntity(carryPackage, true, true)
        DeleteObject(carryPackage)
        carryPackage = nil
    end
end