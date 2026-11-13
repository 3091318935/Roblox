if workspace:FindFirstChild("HardcoreITEM") then
    return
end
local marker = Instance.new("BoolValue")
marker.Name = "HardcoreITEM"
marker.Value = true
marker.Parent = workspace
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local soundId = 73668768200808
local function setupDeathSound(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        local sound = Instance.new("Sound", workspace)
        sound.SoundId = "rbxassetid://" .. soundId
        sound.Volume = 1
        sound:Play()
        sound.Ended:Wait()
        sound:Destroy()
    end)
end
setupDeathSound(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupDeathSound)

local localEyes1 = nil
local localEyesCopy = nil
local updateConnection = nil
local originalEyesModel = nil
local removedObjects = {}

local function cleanEyesModel()
    local localEyes = workspace:FindFirstChild("AmbushMoving")
    if not localEyes or not localEyes:IsA("Model") then
        return
    end
    
    for _, obj in ipairs(removedObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    removedObjects = {}

    for _, descendant in ipairs(localEyes:GetDescendants()) do
        if descendant.Name ~= "RushNew" and descendant:IsA("BasePart") then
            descendant:Destroy()
            table.insert(removedObjects, descendant)
        end
        
        if descendant:IsA("PointLight") or descendant:IsA("Decal") or descendant:IsA("Texture") or
           descendant:IsA("Sound") or descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or
           descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") or descendant:IsA("ScreenGui") or
           descendant:IsA("SurfaceAppearance") or descendant:IsA("Sparkles") or descendant:IsA("Smoke") or descendant:IsA("Fire") then
            descendant:Destroy()
            table.insert(removedObjects, descendant)
        end
    end
end

local function checkAndCreateLocalCopy()
    originalEyesModel = workspace:FindFirstChild("AmbushMoving")
    
    if not originalEyesModel then
        if localEyesCopy then
            localEyesCopy:Destroy()
            localEyesCopy = nil
        end
        if localEyes1 then
            localEyes1:Destroy()
            localEyes1 = nil
        end
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
        return
    end

    cleanEyesModel()

    if localEyesCopy then
        localEyesCopy:Destroy()
        localEyesCopy = nil
    end
    
    if localEyes1 then
        localEyes1:Destroy()
        localEyes1 = nil
    end
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end

    local success1, eyes1Result = pcall(function()
        return game:GetObjects("rbxassetid://109143871922489")[1]
    end)
    
    if success1 and eyes1Result then
        localEyes1 = eyes1Result
        localEyes1.Name = "A-60New"
        localEyes1.Parent = workspace
    end

    local success2, eyesCopyResult = pcall(function()
        return game:GetObjects("rbxassetid://109143871922489")[1]
    end)
    
    if success2 and eyesCopyResult then
        localEyesCopy = eyesCopyResult
        localEyesCopy.Name = "AmbushMovingCopy"
        localEyesCopy.Parent = workspace

        updateConnection = runService.RenderStepped:Connect(function()
            if originalEyesModel and originalEyesModel:FindFirstChild("RushNew") and 
               localEyesCopy and localEyesCopy:IsDescendantOf(workspace) then
                
                local corePart = originalEyesModel:FindFirstChild("RushNew")
                if corePart and corePart:IsA("BasePart") then
                    localEyesCopy:PivotTo(corePart.CFrame)
                    if localEyes1 and localEyes1:IsDescendantOf(workspace) then
                        localEyes1:PivotTo(corePart.CFrame)
                    end
                end
            else
                if updateConnection then
                    updateConnection:Disconnect()
                    updateConnection = nil
                end
            end
        end)
    end
end

wait(1) 
checkAndCreateLocalCopy()

local localEyes2 = nil
local localEyesCopy2 = nil
local updateConnection2 = nil
local originalEyesModel2 = nil
local removedObjects2 = {}

local function cleanEyesModel2()
    local localEyes = workspace:FindFirstChild("Eyes")
    if not localEyes or not localEyes:IsA("Model") then
        return
    end

    for _, obj in ipairs(removedObjects2) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    removedObjects2 = {}

    for _, descendant in ipairs(localEyes:GetDescendants()) do
        if descendant.Name ~= "Core" and descendant:IsA("BasePart") then
            descendant:Destroy()
            table.insert(removedObjects2, descendant)
        end
        
        if descendant:IsA("PointLight") or descendant:IsA("Decal") or descendant:IsA("Texture") or
           descendant:IsA("Sound") or descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or
           descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") or descendant:IsA("ScreenGui") or
           descendant:IsA("SurfaceAppearance") or descendant:IsA("Sparkles") or descendant:IsA("Smoke") or descendant:IsA("Fire") then
            descendant:Destroy()
            table.insert(removedObjects2, descendant)
        end
    end
end

local function checkAndCreateLocalCopy2()
    originalEyesModel2 = workspace:FindFirstChild("Eyes")
    
    if not originalEyesModel2 then
        if localEyesCopy2 then
            localEyesCopy2:Destroy()
            localEyesCopy2 = nil
        end
        if localEyes2 then
            localEyes2:Destroy()
            localEyes2 = nil
        end
        if updateConnection2 then
            updateConnection2:Disconnect()
            updateConnection2 = nil
        end
        return
    end

    cleanEyesModel2()
    
    if localEyesCopy2 then
        localEyesCopy2:Destroy()
        localEyesCopy2 = nil
    end
    
    if localEyes2 then
        localEyes2:Destroy()
        localEyes2 = nil
    end
    
    if updateConnection2 then
        updateConnection2:Disconnect()
        updateConnection2 = nil
    end

    local success1, eyes1Result = pcall(function()
        return game:GetObjects("rbxassetid://133236803369785")[1]
    end)
    
    if success1 and eyes1Result then
        localEyes2 = eyes1Result
        localEyes2.Name = "Eyes1"
        localEyes2.Parent = workspace
    end

    local success2, eyesCopyResult = pcall(function()
        return game:GetObjects("rbxassetid://133236803369785")[1]
    end)
    
    if success2 and eyesCopyResult then
        localEyesCopy2 = eyesCopyResult
        localEyesCopy2.Name = "EyesCopy"
        localEyesCopy2.Parent = workspace

        updateConnection2 = runService.RenderStepped:Connect(function()
            if originalEyesModel2 and originalEyesModel2:FindFirstChild("Core") and 
               localEyesCopy2 and localEyesCopy2:IsDescendantOf(workspace) then
                
                local corePart = originalEyesModel2:FindFirstChild("Core")
                if corePart and corePart:IsA("BasePart") then
                    localEyesCopy2:PivotTo(corePart.CFrame)
                    if localEyes2 and localEyes2:IsDescendantOf(workspace) then
                        localEyes2:PivotTo(corePart.CFrame)
                    end
                end
            else
                if updateConnection2 then
                    updateConnection2:Disconnect()
                    updateConnection2 = nil
                end
            end
        end)
    end
end

wait(1)
checkAndCreateLocalCopy2()

local eyesAddedConnection = workspace.ChildAdded:Connect(function(child)
    if child.Name == "AmbushMoving" and child:IsA("Model") then
        wait(0.2)
        checkAndCreateLocalCopy()
    elseif child.Name == "Eyes" and child:IsA("Model") then
        wait(0.2)
        checkAndCreateLocalCopy2()
    end
end)

local eyesRemovedConnection = workspace.ChildRemoved:Connect(function(child)
    if child.Name == "AmbushMoving" and child:IsA("Model") then
        if localEyesCopy then
            localEyesCopy:Destroy()
            localEyesCopy = nil
        end
        if localEyes1 then
            localEyes1:Destroy()
            localEyes1 = nil
        end
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
    elseif child.Name == "Eyes" and child:IsA("Model") then
        if localEyesCopy2 then
            localEyesCopy2:Destroy()
            localEyesCopy2 = nil
        end
        if localEyes2 then
            localEyes2:Destroy()
            localEyes2 = nil
        end
        if updateConnection2 then
            updateConnection2:Disconnect()
            updateConnection2 = nil
        end
    end
end)

local function periodicCheck()
    while true do
        wait(3)
        
        local currentEyes = workspace:FindFirstChild("AmbushMoving")
        if currentEyes and currentEyes:IsA("Model") then
            local needsCleaning = false
            for _, descendant in ipairs(currentEyes:GetDescendants()) do
                if descendant:IsA("PointLight") or descendant:IsA("Decal") or 
                   descendant:IsA("Texture") or descendant:IsA("Sound") or
                   descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or
                   (descendant:IsA("BasePart") and descendant.Name ~= "A-60New") then
                    needsCleaning = true
                    break
                end
            end
            
            if needsCleaning then
                cleanEyesModel()
            end

            if not currentEyes:FindFirstChild("A-60New") then
                local core = Instance.new("Part")
                core.Name = "A-60New"
                core.Anchored = true
                core.CanCollide = false
                core.Transparency = 1
                core.Size = Vector3.new(1, 1, 1)
                core.Parent = currentEyes
            end

            if (not localEyesCopy or not localEyesCopy:IsDescendantOf(workspace)) or 
               (not localEyes1 or not localEyes1:IsDescendantOf(workspace)) then
                checkAndCreateLocalCopy()
            end
        else
            if localEyesCopy or localEyes1 then
                if localEyesCopy then
                    localEyesCopy:Destroy()
                    localEyesCopy = nil
                end
                if localEyes1 then
                    localEyes1:Destroy()
                    localEyes1 = nil
                end
                if updateConnection then
                    updateConnection:Disconnect()
                    updateConnection = nil
                end
            end
        end
        
        local currentEyes2 = workspace:FindFirstChild("Eyes")
        if currentEyes2 and currentEyes2:IsA("Model") then
            local needsCleaning2 = false
            for _, descendant in ipairs(currentEyes2:GetDescendants()) do
                if descendant:IsA("PointLight") or descendant:IsA("Decal") or 
                   descendant:IsA("Texture") or descendant:IsA("Sound") or
                   descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or
                   (descendant:IsA("BasePart") and descendant.Name ~= "Core") then
                    needsCleaning2 = true
                    break
                end
            end
            
            if needsCleaning2 then
                cleanEyesModel2()
            end

            if not currentEyes2:FindFirstChild("Core") then
                local core = Instance.new("Part")
                core.Name = "Core"
                core.Anchored = true
                core.CanCollide = false
                core.Transparency = 1
                core.Size = Vector3.new(1, 1, 1)
                core.Parent = currentEyes2
            end

            if (not localEyesCopy2 or not localEyesCopy2:IsDescendantOf(workspace)) or 
               (not localEyes2 or not localEyes2:IsDescendantOf(workspace)) then
                checkAndCreateLocalCopy2()
            end
        else
            if localEyesCopy2 or localEyes2 then
                if localEyesCopy2 then
                    localEyesCopy2:Destroy()
                    localEyesCopy2 = nil
                end
                if localEyes2 then
                    localEyes2:Destroy()
                    localEyes2 = nil
                end
                if updateConnection2 then
                    updateConnection2:Disconnect()
                    updateConnection2 = nil
                end
            end
        end
    end
end

spawn(periodicCheck)

local function removeScreechFromEntities()
    local Entities = ReplicatedStorage:FindFirstChild("Entities")
    if not Entities then
        return
    end
    
    local screechInstances = {}
    
    for _, child in ipairs(Entities:GetChildren()) do
        if child.Name == "Screech" then
            table.insert(screechInstances, child)
        end
    end
    
    for _, screech in ipairs(screechInstances) do
        screech:Destroy()
    end
end

removeScreechFromEntities()

local Entities = ReplicatedStorage:FindFirstChild("Entities") or Instance.new("Folder")
Entities.Name = "Entities"
Entities.Parent = ReplicatedStorage

local MODEL_ID = 118003122248349
local model = game:GetObjects("rbxassetid://" .. MODEL_ID)[1]
model.Parent = Entities

game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("By Mr.Key",true)
require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).titlelocation("The HardCord Mines",true)
require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).remind("⚠❗This Mode is quite challenging and is recommended for 5-10 players.❗⚠", true)

task.spawn(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local REPLACEMENT_CONFIG = {
        ["tipjar"] = {assetId = 82962070519273},
        ["gweensoda"] = {assetId = 123708207888191},
        ["shakelight"] = {assetId = 71349337541000},
        ["starvial"] = {assetId = 75495333223363},
        ["starbottle"] = {assetId = 85527257914363},
        ["knockbackstick"] = {assetId = 128089163384066}
    }

    local CHECK_INTERVAL = 0.3
    local trackedTargets = {}

    local function loadAssetLocally(assetId)
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. assetId)[1]
        end)
        if success and result then
            return result:Clone()
        end
        return nil
    end

    local function disableModelCollision(model)
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                part.CanCollide = false
                part.CanTouch = false
                part.CanQuery = false
            end
        end
    end

    local function hideTarget(target)
        if target:IsA("BasePart") or target:IsA("MeshPart") then
            if not trackedTargets[target] then
                trackedTargets[target] = {originalTransparency = target.Transparency}
            end
            target.Transparency = 1
            if target:IsA("Tool") and target:FindFirstChild("Handle") then
                local handle = target.Handle
                if not trackedTargets[target].handleTransparency then
                    trackedTargets[target].handleTransparency = handle.Transparency
                end
                handle.Transparency = 1
            end
        elseif target:IsA("Model") then
            if not trackedTargets[target] then
                trackedTargets[target] = {originalParts = {}}
            end
            for _, part in ipairs(target:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    trackedTargets[target].originalParts[part] = part.Transparency
                    part.Transparency = 1
                end
            end
        end
    end

    local function restoreTarget(target)
        local data = trackedTargets[target]
        if not data then return end
        if target:IsA("BasePart") or target:IsA("MeshPart") then
            if data.originalTransparency then
                target.Transparency = data.originalTransparency
            end
            if target:IsA("Tool") and target:FindFirstChild("Handle") and data.handleTransparency then
                target.Handle.Transparency = data.handleTransparency
            end
        elseif target:IsA("Model") and data.originalParts then
            for part, transparency in pairs(data.originalParts) do
                if part and part.Parent then
                    part.Transparency = transparency
                end
            end
        end
    end

    local function getItemConfig(itemName)
        local nameLower = itemName:lower()
        return REPLACEMENT_CONFIG[nameLower]
    end

    local function findTargetsInWorkspace()
        local targets = {}
        
        for _, item in ipairs(workspace:GetChildren()) do
            local nameLower = item.Name:lower()
            local config = getItemConfig(nameLower)
            
            if item:IsA("Model") and config and item.Name ~= "Drops" then
                table.insert(targets, {target = item, config = config})
            end
            
            if item:IsA("Tool") and config then
                table.insert(targets, {target = item, config = config})
            end
            
            if (item:IsA("BasePart") or item:IsA("MeshPart")) and config then
                table.insert(targets, {target = item, config = config})
            end
            
            if item:IsA("Model") and item.Name ~= "Drops" then
                for _, child in ipairs(item:GetDescendants()) do
                    local childNameLower = child.Name:lower()
                    local childConfig = getItemConfig(childNameLower)
                    
                    if child:IsA("Model") and childConfig then
                        table.insert(targets, {target = child, config = childConfig})
                    end
                    
                    if child:IsA("Tool") and childConfig then
                        table.insert(targets, {target = child, config = childConfig})
                    end
                    
                    if (child:IsA("BasePart") or child:IsA("MeshPart")) and childConfig then
                        table.insert(targets, {target = child, config = childConfig})
                    end
                end
            end
        end
        
        return targets
    end

    local function getTargetCFrame(target)
        if target:IsA("BasePart") or target:IsA("MeshPart") then
            return target.CFrame
        elseif target:IsA("Tool") and target:FindFirstChild("Handle") then
            return target.Handle.CFrame
        elseif target:IsA("Model") then
            if target.PrimaryPart then
                return target:GetPivot()
            elseif target:FindFirstChildWhichIsA("BasePart") then
                return target:FindFirstChildWhichIsA("BasePart").CFrame
            end
        end
        return nil
    end

    local function createFollowEffect(target, assetId)
        local effectModel = loadAssetLocally(assetId)
        if not effectModel then return nil end
        effectModel.Name = "FollowEffect"
        effectModel.Parent = workspace
        
        disableModelCollision(effectModel)
        
        if not effectModel.PrimaryPart then
            if effectModel:FindFirstChildWhichIsA("BasePart") then
                effectModel.PrimaryPart = effectModel:FindFirstChildWhichIsA("BasePart")
            else
                effectModel:Destroy()
                return nil
            end
        end
        
        local targetCFrame = getTargetCFrame(target)
        if targetCFrame then

            if assetId == 128089163384066 then
                targetCFrame = targetCFrame + Vector3.new(0, 3.0, 0)
            end
            effectModel:PivotTo(targetCFrame)
        end
        return effectModel
    end

    local function updateEffectPosition(data, target)
        if not data.effect or not data.effect.Parent or not target or not target.Parent then
            return false
        end
        local targetCFrame = getTargetCFrame(target)
        if not targetCFrame then
            return false
        end

        if data.config and data.config.assetId == 128089163384066 then
            targetCFrame = targetCFrame + Vector3.new(-1, 3.5, 1)
        end
        
        data.effect:PivotTo(targetCFrame)
        return true
    end

    local function startTrackingTarget(target, config)
        if trackedTargets[target] then return trackedTargets[target] end
        
        local effectModel = createFollowEffect(target, config.assetId)
        if not effectModel then return end
        
        hideTarget(target)
        
        trackedTargets[target] = {
            effect = effectModel, 
            target = target,
            config = config
        }
        
        local data = trackedTargets[target]
        data.connection = RunService.RenderStepped:Connect(function()
            if not updateEffectPosition(data, target) then
                if data.connection then
                    data.connection:Disconnect()
                end
                if data.effect and data.effect.Parent then
                    data.effect:Destroy()
                end
                trackedTargets[target] = nil
            end
        end)
        
        return trackedTargets[target]
    end

    local function stopTrackingTarget(target, restoreVisibility)
        local data = trackedTargets[target]
        if not data then return end
        
        if restoreVisibility then
            restoreTarget(target)
        end
        
        if data.effect and data.effect.Parent then
            data.effect:Destroy()
        end
        
        if data.connection then
            data.connection:Disconnect()
        end
        
        trackedTargets[target] = nil
    end

    local function cleanupDestroyedTargets()
        for target, data in pairs(trackedTargets) do
            if not target or not target.Parent then
                if data.effect and data.effect.Parent then
                    data.effect:Destroy()
                end
                if data.connection then
                    data.connection:Disconnect()
                end
                trackedTargets[target] = nil
            end
        end
    end

    local function findAllTargets()
        local targets = {}
        
        local workspaceTargets = findTargetsInWorkspace()
        for _, targetData in ipairs(workspaceTargets) do
            table.insert(targets, targetData)
        end
        
        local dropsFolder = workspace:FindFirstChild("Drops")
        if dropsFolder then
            for _, item in ipairs(dropsFolder:GetChildren()) do
                if item:IsA("Model") then
                    local config = getItemConfig(item.Name)
                    if config then
                        table.insert(targets, {target = item, config = config})
                    end
                end
            end
        end
        
        return targets
    end

    local function startDetection()
        local lastCheckTime = 0
        while true do
            local currentTime = tick()
            if currentTime - lastCheckTime >= CHECK_INTERVAL then
                lastCheckTime = currentTime
                cleanupDestroyedTargets()
                local allTargets = findAllTargets()
                for _, targetData in ipairs(allTargets) do
                    if not trackedTargets[targetData.target] then
                        startTrackingTarget(targetData.target, targetData.config)
                    end
                end
                for target, data in pairs(trackedTargets) do
                    if target and target.Parent then
                        local isValid = false
                        local parent = target.Parent
                        while parent do
                            if parent == workspace then
                                isValid = true
                                break
                            elseif parent.Name == "Drops" and parent.Parent == workspace then
                                isValid = true
                                break
                            elseif parent:IsA("Model") and parent.Parent == workspace then
                                isValid = true
                                break
                            end
                            parent = parent.Parent
                        end
                        if not isValid then
                            stopTrackingTarget(target, true)
                        end
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
    end

    local function initialize()
        task.spawn(startDetection)
    end

    local function cleanup()
        for target, _ in pairs(trackedTargets) do
            stopTrackingTarget(target, true)
        end
        trackedTargets = {}
    end

    local function setupPlayerEvents()
        local player = Players.LocalPlayer
        if player then
            player:GetPropertyChangedSignal("Character"):Connect(function()
                cleanupDestroyedTargets()
            end)
            player.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    cleanup()
                end
            end)
        end
    end

    initialize()
    setupPlayerEvents()
end)
-----
local hint = Instance.new("Hint", Workspace)
hint.Text = "LoadingItem... Doors HardCore V10.6 By Mr.key & HeavenNow :)"
game.Debris:AddItem(hint, 3)