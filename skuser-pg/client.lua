local isProgressActive = false
local progressCanCancel = false
local disableControls = {}
local currentAnimDict = nil
local currentAnimClip = nil
local currentScenario = nil
local spawnedProps = {}

local function DisableControlsLoop()
    CreateThread(function()
        while isProgressActive do
            if disableControls.mouse then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 106, true)
            end
            
            if disableControls.move then
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 36, true)
            end
            
            if disableControls.car then
                DisableControlAction(0, 63, true)
                DisableControlAction(0, 64, true)
                DisableControlAction(0, 71, true)
                DisableControlAction(0, 72, true)
            end
            
            if disableControls.combat then
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 47, true)
                DisableControlAction(0, 58, true)
            end
            
            if disableControls.sprint then
                DisableControlAction(0, 21, true)
            end
            
            Wait(0)
        end
    end)
end

local function CreateProp(ped, propData)
    local model = type(propData.model) == 'string' and GetHashKey(propData.model) or propData.model
    local bone = propData.bone or 60309
    local pos = propData.pos or vector3(0.0, 0.0, 0.0)
    local rot = propData.rot or vector3(0.0, 0.0, 0.0)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    local prop = CreateObject(model, 0.0, 0.0, 0.0, true, true, true)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, bone), pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
    
    SetModelAsNoLongerNeeded(model)
    
    return prop
end

local function CleanupProgress(playerPed, allowRagdoll, cancelled, success)
    SendNUIMessage({
        action = "stopProgress",
        cancelled = cancelled or false,
        success = success or false
    })
    
    isProgressActive = false
    progressCanCancel = false
    disableControls = {}

    if cancelled or success then
        Wait(2000)
    end
    
    if currentAnimDict and currentAnimClip then
        StopAnimTask(playerPed, currentAnimDict, currentAnimClip, 1.0)
        RemoveAnimDict(currentAnimDict)
    elseif currentScenario then
        ClearPedTasks(playerPed)
    end
    
    for _, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    
    if not allowRagdoll then
        SetPedCanRagdoll(playerPed, true)
    end
    
    currentAnimDict = nil
    currentAnimClip = nil
    currentScenario = nil
    spawnedProps = {}
end

function progressBar(data)
    if isProgressActive then
        return false
    end
    
    local playerPed = PlayerPedId()
    local duration = data.duration or 5000
    local label = data.label or "Processing..."
    local useWhileDead = data.useWhileDead or false
    local allowRagdoll = data.allowRagdoll or false
    local allowSwimming = data.allowSwimming or false
    local allowCuffed = data.allowCuffed or false
    local allowFalling = data.allowFalling or false
    local canCancel = data.canCancel or false
    local icon = data.icon or nil
    
    progressCanCancel = canCancel

    if not useWhileDead and IsEntityDead(playerPed) then
        return false
    end
    
    if not allowCuffed and IsPedCuffed(playerPed) then
        return false
    end
    
    if not allowSwimming and IsPedSwimming(playerPed) then
        return false
    end
    
    disableControls = data.disable or {}
    
    if data.anim then
        if data.anim.dict and data.anim.clip then
            currentAnimDict = data.anim.dict
            currentAnimClip = data.anim.clip
            
            RequestAnimDict(currentAnimDict)
            while not HasAnimDictLoaded(currentAnimDict) do
                Wait(0)
            end
            
            local flag = data.anim.flag or 49
            local blendIn = data.anim.blendIn or 3.0
            local blendOut = data.anim.blendOut or 1.0
            local animDuration = data.anim.duration or -1
            local playbackRate = data.anim.playbackRate or 0
            local lockX = data.anim.lockX or false
            local lockY = data.anim.lockY or false
            local lockZ = data.anim.lockZ or false
            
            TaskPlayAnim(playerPed, currentAnimDict, currentAnimClip, blendIn, blendOut, animDuration, flag, playbackRate, lockX, lockY, lockZ)
        elseif data.anim.scenario then
            currentScenario = data.anim.scenario
            local playEnter = data.anim.playEnter ~= false
            TaskStartScenarioInPlace(playerPed, currentScenario, 0, playEnter)
        end
    end
    
    if data.prop then
        local props = data.prop
        if props[1] and type(props[1]) == 'table' then
            for i, propData in ipairs(props) do
                local prop = CreateProp(playerPed, propData)
                table.insert(spawnedProps, prop)
            end
        else
            local prop = CreateProp(playerPed, props)
            table.insert(spawnedProps, prop)
        end
    end
    
    if not allowRagdoll then
        SetPedCanRagdoll(playerPed, false)
    end
    
    isProgressActive = true
    DisableControlsLoop()
    
    SendNUIMessage({
        action = "startProgress",
        duration = duration,
        label = label,
        icon = icon,
        canCancel = canCancel,
        type = "bar"
    })
    
    local startTime = GetGameTimer()
    local cancelled = false
    local success = false
    
    while isProgressActive do
        local currentTime = GetGameTimer()
        local elapsed = currentTime - startTime
        
        if elapsed >= duration then
            success = true
            break
        end
        
        if canCancel and IsControlJustPressed(0, 73) then
            cancelled = true
            break
        end
        
        if not useWhileDead and IsEntityDead(playerPed) then
            cancelled = true
            break
        end
        
        if not allowFalling and IsPedFalling(playerPed) then
            cancelled = true
            break
        end
        
        if not allowSwimming and IsPedSwimming(playerPed) then
            cancelled = true
            break
        end
        
        Wait(10)
    end
    
    CleanupProgress(playerPed, allowRagdoll, cancelled, success)
    
    return not cancelled
end

function progressCircle(data)
    if isProgressActive then
        return false
    end
    
    local playerPed = PlayerPedId()
    local duration = data.duration or 5000
    local label = data.label
    local position = data.position or "middle"
    local useWhileDead = data.useWhileDead or false
    local allowRagdoll = data.allowRagdoll or false
    local allowSwimming = data.allowSwimming or false
    local allowCuffed = data.allowCuffed or false
    local allowFalling = data.allowFalling or false
    local canCancel = data.canCancel or false
    
    progressCanCancel = canCancel
    
    if not useWhileDead and IsEntityDead(playerPed) then
        return false
    end
    
    if not allowCuffed and IsPedCuffed(playerPed) then
        return false
    end
    
    if not allowSwimming and IsPedSwimming(playerPed) then
        return false
    end
    
    disableControls = data.disable or {}
    
    if data.anim then
        if data.anim.dict and data.anim.clip then
            currentAnimDict = data.anim.dict
            currentAnimClip = data.anim.clip
            
            RequestAnimDict(currentAnimDict)
            while not HasAnimDictLoaded(currentAnimDict) do
                Wait(0)
            end
            
            local flag = data.anim.flag or 49
            local blendIn = data.anim.blendIn or 3.0
            local blendOut = data.anim.blendOut or 1.0
            local animDuration = data.anim.duration or -1
            local playbackRate = data.anim.playbackRate or 0
            local lockX = data.anim.lockX or false
            local lockY = data.anim.lockY or false
            local lockZ = data.anim.lockZ or false
            
            TaskPlayAnim(playerPed, currentAnimDict, currentAnimClip, blendIn, blendOut, animDuration, flag, playbackRate, lockX, lockY, lockZ)
        elseif data.anim.scenario then
            currentScenario = data.anim.scenario
            local playEnter = data.anim.playEnter ~= false
            TaskStartScenarioInPlace(playerPed, currentScenario, 0, playEnter)
        end
    end
    
    if data.prop then
        local props = data.prop
        if props[1] and type(props[1]) == 'table' then
            for i, propData in ipairs(props) do
                local prop = CreateProp(playerPed, propData)
                table.insert(spawnedProps, prop)
            end
        else
            local prop = CreateProp(playerPed, props)
            table.insert(spawnedProps, prop)
        end
    end
    
    if not allowRagdoll then
        SetPedCanRagdoll(playerPed, false)
    end
    
    isProgressActive = true
    DisableControlsLoop()
    
    SendNUIMessage({
        action = "startProgress",
        duration = duration,
        label = label,
        position = position,
        canCancel = canCancel,
        type = "circle"
    })
    
    local startTime = GetGameTimer()
    local cancelled = false
    local success = false
    
    while isProgressActive do
        local currentTime = GetGameTimer()
        local elapsed = currentTime - startTime
        
        if elapsed >= duration then
            success = true
            break
        end
        
        if canCancel and IsControlJustPressed(0, 73) then
            cancelled = true
            break
        end
        
        if not useWhileDead and IsEntityDead(playerPed) then
            cancelled = true
            break
        end
        
        if not allowFalling and IsPedFalling(playerPed) then
            cancelled = true
            break
        end
        
        if not allowSwimming and IsPedSwimming(playerPed) then
            cancelled = true
            break
        end
        
        Wait(10)
    end
    
    CleanupProgress(playerPed, allowRagdoll, cancelled, success)
    
    return not cancelled
end

function progressActive()
    return isProgressActive
end

function cancelProgress()
    if isProgressActive and progressCanCancel then
        local playerPed = PlayerPedId()
        CleanupProgress(playerPed, true, true, false)
    end
end

exports('progressBar', progressBar)
exports('progressCircle', progressCircle)
exports('progressActive', progressActive)
exports('cancelProgress', cancelProgress)

RegisterCommand('testbar', function()
    local success = progressBar({
        duration = 10000,
        label = 'Naprawianie silnika...',
        icon = 'fas fa-wrench',
        canCancel = true,
        useWhileDead = false,
        allowRagdoll = false,
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player'
        },
        disable = {
            move = true,
            combat = true
        }
    })  
end)

RegisterCommand('testcircle', function()
    local success = progressCircle({
        duration = 3000,
        label = 'Ładowanie',
        position = 'bottom',
        canCancel = true
    })
end)
