if workspace:FindFirstChild("HardcoreITEM") then
    return
end
local marker = Instance.new("BoolValue")
marker.Name = "HardcoreITEM"
marker.Value = true
marker.Parent = workspace

task.spawn(function()
    local WorkspaceService = game:GetService("Workspace")
    local CurrentRooms = WorkspaceService:WaitForChild("CurrentRooms")

    local function loadTemplate(assetId)
        local ok, objects = pcall(function()
            return game:GetObjects("rbxassetid://" .. assetId)
        end)

        if not ok or not objects or #objects == 0 then
            return nil
        end

        local template = objects[1]
        template.Parent = nil
        return template
    end

    local LightTemplate = loadTemplate("115669442831464")
    local WindowTemplate = loadTemplate("88364164011150")
    local TallWindowTemplate = loadTemplate("126414024738813")
    local ChandelierTemplate = loadTemplate("137882841439230")

    local SpawnedLight = {}
    local SpawnedWindow = {}
    local SpawnedTallWindow = {}
    local SpawnedChandelier = {}

    local function getCFrame(object)
        if not object then
            return nil
        end

        if object:IsA("Attachment") then
            return object.WorldCFrame
        end

        if object:IsA("BasePart") then
            return object.CFrame
        end

        if object:IsA("Model") then
            return object:GetPivot()
        end

        local model = object:FindFirstChildWhichIsA("Model", true)

        if model then
            return model:GetPivot()
        end

        local part = object:FindFirstChildWhichIsA("BasePart", true)

        if part then
            return part.CFrame
        end

        return nil
    end

    local function moveObject(object, targetCFrame)
        if not object or not targetCFrame then
            return false
        end

        if object:IsA("Model") then
            object:PivotTo(targetCFrame)
            return true
        end

        if object:IsA("BasePart") then
            object.CFrame = targetCFrame
            return true
        end

        local parts = {}

        for _, descendant in ipairs(object:GetDescendants()) do
            if descendant:IsA("BasePart") then
                table.insert(parts, descendant)
            end
        end

        if #parts == 0 then
            return false
        end

        local root = parts[1]
        local rootCFrame = root.CFrame
        local offsets = {}

        for _, part in ipairs(parts) do
            offsets[part] = rootCFrame:ToObjectSpace(part.CFrame)
        end

        for part, offset in pairs(offsets) do
            part.CFrame = targetCFrame * offset
        end

        return true
    end

    local function getDirectRoom(instance)
        local current = instance

        while current and current ~= CurrentRooms do
            if current.Parent == CurrentRooms then
                return current
            end
            current = current.Parent
        end

        return nil
    end

    local function isValidLightFixture(lightFixture)
        if not lightFixture:IsA("BasePart") or lightFixture.Name ~= "LightFixture" then
            return false
        end

        local lightStand = lightFixture.Parent
        local lightFixtures = lightStand and lightStand.Parent
        local assets = lightFixtures and lightFixtures.Parent
        local room = assets and assets.Parent

        return lightStand ~= nil
            and lightStand.Name == "LightStand"
            and lightFixtures ~= nil
            and lightFixtures.Name == "Light_Fixtures"
            and assets ~= nil
            and assets.Name == "Assets"
            and room ~= nil
            and room.Parent == CurrentRooms
    end

    local function isValidWindow(window)
        if window.Name ~= "Window" then
            return false
        end

        local parent = window.Parent

        if not parent then
            return false
        end

        if parent.Name == "Assets" then
            local room = parent.Parent
            return room ~= nil and room.Parent == CurrentRooms
        end

        if parent.Name == "Windows" then
            local assets = parent.Parent
            local room = assets and assets.Parent
            return assets ~= nil
                and assets.Name == "Assets"
                and room ~= nil
                and room.Parent == CurrentRooms
        end

        return false
    end

    local function isValidTallWindow(windowTall)
        if windowTall.Name ~= "Window_Tall" then
            return false
        end

        local parent = windowTall.Parent

        if not parent then
            return false
        end

        if parent.Name == "Windowed" then
            local room = parent.Parent
            return room ~= nil and room.Parent == CurrentRooms
        end

        if parent.Name == "Assets" then
            local room = parent.Parent
            return room ~= nil and room.Parent == CurrentRooms
        end

        if parent.Name == "Windows" then
            local assets = parent.Parent
            local room = assets and assets.Parent
            return assets ~= nil
                and assets.Name == "Assets"
                and room ~= nil
                and room.Parent == CurrentRooms
        end

        return false
    end

    local function isValidChandelier(chandelier)
        if chandelier.Name ~= "Chandelier" then
            return false
        end

        local parent = chandelier.Parent

        if not parent then
            return false
        end

        if parent.Name == "Assets" then
            local room = parent.Parent
            return room ~= nil and room.Parent == CurrentRooms
        end

        if parent.Name == "Light_Fixtures" then
            local assets = parent.Parent
            local room = assets and assets.Parent
            return assets ~= nil
                and assets.Name == "Assets"
                and room ~= nil
                and room.Parent == CurrentRooms
        end

        return false
    end

    local function cleanupSpawn(map, target)
        local spawned = map[target]

        if typeof(spawned) == "Instance" and spawned.Parent then
            spawned:Destroy()
        end

        map[target] = nil
    end

    local function spawnForTarget(target, template, map, validFunction, name, cframeTarget, parentTarget)
        if not template then
            return
        end

        local existing = map[target]

        if existing then
            if existing == true then
                return
            end

            if typeof(existing) == "Instance" and existing.Parent then
                return
            end

            map[target] = nil
        end

        if not target or not target.Parent or not target:IsDescendantOf(CurrentRooms) then
            return
        end

        if not validFunction(target) then
            return
        end

        local positionTarget = cframeTarget and cframeTarget(target) or target

        if not positionTarget then
            return
        end

        local targetCFrame = getCFrame(positionTarget)

        if not targetCFrame then
            return
        end

        map[target] = true

        local clone = template:Clone()
        clone.Name = name
        clone.Parent = parentTarget and parentTarget(target) or target.Parent

        if not moveObject(clone, targetCFrame) then
            clone:Destroy()
            map[target] = nil
            return
        end

        map[target] = clone

        target.AncestryChanged:Connect(function()
            if not target:IsDescendantOf(CurrentRooms) then
                cleanupSpawn(map, target)
            end
        end)
    end

    local function spawnLight(lightFixture)
        spawnForTarget(
            lightFixture,
            LightTemplate,
            SpawnedLight,
            isValidLightFixture,
            "LoadedLight_New",
            function(target)
                return target:FindFirstChild("Neon")
            end,
            function(target)
                return target
            end
        )
    end

    local function spawnWindow(window)
        spawnForTarget(
            window,
            WindowTemplate,
            SpawnedWindow,
            isValidWindow,
            "LoadedWindow_88364164011150"
        )
    end

    local function spawnTallWindow(windowTall)
        spawnForTarget(
            windowTall,
            TallWindowTemplate,
            SpawnedTallWindow,
            isValidTallWindow,
            "LoadedWindowTall_126414024738813"
        )
    end

    local function spawnChandelier(chandelier)
        spawnForTarget(
            chandelier,
            ChandelierTemplate,
            SpawnedChandelier,
            isValidChandelier,
            "LoadedChandelier_New"
        )
    end

    local function checkInstance(instance)
        if not instance or not instance.Parent then
            return
        end

        if instance.Name == "LightFixture" and instance:IsA("BasePart") then
            task.defer(spawnLight, instance)
            return
        end

        if instance.Name == "Neon" then
            local lightFixture = instance.Parent

            if lightFixture and lightFixture.Name == "LightFixture" and lightFixture:IsA("BasePart") then
                task.defer(spawnLight, lightFixture)
            end

            return
        end

        if instance.Name == "Window" then
            task.defer(spawnWindow, instance)
            return
        end

        if instance.Name == "Window_Tall" then
            task.defer(spawnTallWindow, instance)
            return
        end

        if instance.Name == "Chandelier" then
            task.defer(spawnChandelier, instance)
        end
    end

    local function scanRoom(room)
        if not room or room.Parent ~= CurrentRooms then
            return
        end

        for _, instance in ipairs(room:GetDescendants()) do
            checkInstance(instance)
        end
    end

    for _, room in ipairs(CurrentRooms:GetChildren()) do
        task.spawn(scanRoom, room)
    end

    CurrentRooms.ChildAdded:Connect(function(room)
        task.defer(scanRoom, room)
    end)

    CurrentRooms.DescendantAdded:Connect(function(instance)
        checkInstance(instance)
    end)
end)

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
        sound.Volume = 0.1
        sound:Play()
        sound.Ended:Wait()
        sound:Destroy()
    end)
end
setupDeathSound(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(setupDeathSound)

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
task.spawn(function()
    local playerGui = game.Players.LocalPlayer.PlayerGui
    local mainUI = playerGui:WaitForChild("MainUI")

    local image = Instance.new("ImageLabel")
    image.Name = "HardCoreImage"
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://96795082386229"
    image.ImageTransparency = 1
    image.AnchorPoint = Vector2.new(0.5, 0)
    image.Position = UDim2.new(0.5, 0, 0, 20)
    image.Size = UDim2.new(0, 650, 0, 220)
    image.ScaleType = Enum.ScaleType.Fit
    image.ZIndex = 100
    image.Parent = mainUI

    pcall(function()
        game:GetService("ContentProvider"):PreloadAsync({image})
    end)

    local TweenService = game:GetService("TweenService")

    local fadeIn = TweenService:Create(
        image,
        TweenInfo.new(0.5, Enum.EasingStyle.Linear),
        {ImageTransparency = 0}
    )
    fadeIn:Play()
    fadeIn.Completed:Wait()

    task.wait(5)

    local fadeOut = TweenService:Create(
        image,
        TweenInfo.new(1, Enum.EasingStyle.Linear),
        {ImageTransparency = 1}
    )
    fadeOut:Play()
    fadeOut.Completed:Wait()

    image:Destroy()
end)

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