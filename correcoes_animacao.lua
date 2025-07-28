-- CORREÇÕES PARA A ANIMAÇÃO DE CARREGAR CAIXA
-- Adicionar esta variável no topo do arquivo (depois de "local onDuty = false")
local isCarrying = false -- Variável para controlar se está carregando

-- THREAD PARA MANTER A ANIMAÇÃO ATIVA
-- Adicionar esta thread após a criação dos blips
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isCarrying and carryPackage ~= nil then
            local ped = GetPlayerPed(-1)
            if not IsEntityPlayingAnim(ped, "anim@heists@box_carry@", "idle", 3) then
                TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
            end
        end
    end
end)

-- FUNÇÃO PICKUP CORRIGIDA - SUBSTITUIR A FUNÇÃO PickupPackage() EXISTENTE
function PickupPackage()
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped, true)
    
    -- Carregar o dicionário de animação
    RequestAnimDict("anim@heists@box_carry@")
    while (not HasAnimDictLoaded("anim@heists@box_carry@")) do
        Citizen.Wait(7)
    end
    
    -- Limpar qualquer animação anterior
    ClearPedTasks(ped)
    Citizen.Wait(100)
    
    -- Aplicar a animação de carregar caixa
    TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
    
    -- Criar o objeto da caixa
    local model = GetHashKey("prop_cs_cardbox_01")
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(0) end
    local object = CreateObject(model, pos.x, pos.y, pos.z, true, true, true)
    
    -- Anexar a caixa ao jogador
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, 57005), 0.05, 0.1, -0.3, 300.0, 250.0, 20.0, true, true, false, true, 1, true)
    
    carryPackage = object
    isCarrying = true -- MARCAR QUE ESTÁ CARREGANDO
    
    -- Aguardar um pouco para garantir que a animação foi aplicada
    Citizen.Wait(500)
end

-- FUNÇÃO DROP CORRIGIDA - SUBSTITUIR A FUNÇÃO DropPackage() EXISTENTE
function DropPackage()
    local ped = GetPlayerPed(-1)
    
    if carryPackage ~= nil then
        -- Parar a animação de carregar
        ClearPedTasks(ped)
        
        -- Desanexar e deletar o objeto
        DetachEntity(carryPackage, true, true)
        DeleteObject(carryPackage)
        
        carryPackage = nil
        isCarrying = false -- MARCAR QUE NÃO ESTÁ MAIS CARREGANDO
        
        -- Aguardar um pouco antes de aplicar nova animação se necessário
        Citizen.Wait(100)
    end
end

-- CORREÇÃO OPCIONAL: Adicionar proteção quando sair de serviço
-- Na função de toggle do trabalho, onde tens "onDuty = not onDuty", adicionar:
-- if not onDuty and isCarrying then
--     DropPackage()
-- end