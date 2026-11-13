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
local Players = game:GetService("Players")

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
    image.Image = "rbxassetid://137533301381589"
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
require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("By Heaven",true)

local LIBRARY_ASSET = 71595026288153

local function deleteLibraryUIInWorkspace()
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char and char:IsDescendantOf(workspace) then
            local tool = char:FindFirstChild("LibraryHintPaper")
            if tool and tool:IsA("Tool") then
                local ui = tool:FindFirstChild("UI")
                if ui then
                    ui:Destroy()
                end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "LibraryHintPaper" and obj:IsA("Tool") then
            local ui = obj:FindFirstChild("UI")
            if ui then
                ui:Destroy()
            end
        end
    end
end

deleteLibraryUIInWorkspace()

for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then
        plr.Character.ChildAdded:Connect(function(child)
            if child.Name == "LibraryHintPaper" and child:IsA("Tool") then
                task.wait()
                local ui = child:FindFirstChild("UI")
                if ui then
                    ui:Destroy()
                end
            end
        end)
    end
    plr.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(child)
            if child.Name == "LibraryHintPaper" and child:IsA("Tool") then
                task.wait()
                local ui = child:FindFirstChild("UI")
                if ui then
                    ui:Destroy()
                end
            end
        end)
    end)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(child)
            if child.Name == "LibraryHintPaper" and child:IsA("Tool") then
                task.wait()
                local ui = child:FindFirstChild("UI")
                if ui then
                    ui:Destroy()
                end
            end
        end)
    end)
end)

task.spawn(function()
    local RunService = game:GetService("RunService")

    local REPLACEMENT_CONFIG = {
        ["tipjar"] = {assetId = 82962070519273},
        ["gweensoda"] = {assetId = 123708207888191},
        ["shakelight"] = {assetId = 71349337541000},
        ["starvial"] = {assetId = 75495333223363},
        ["starbottle"] = {assetId = 85527257914363},
        ["knockbackstick"] = {assetId = 128089163384066},
        ["libraryhintpaper"] = {assetId = LIBRARY_ASSET}
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
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char and char:IsDescendantOf(workspace) then
                local tool = char:FindFirstChild("LibraryHintPaper")
                if tool and tool:IsA("Tool") then
                    local config = getItemConfig(tool.Name)
                    if config then
                        table.insert(targets, {target = tool, config = config})
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
            if assetId == LIBRARY_ASSET then
                effectModel:PivotTo(targetCFrame * CFrame.Angles(math.rad(-90), 180, 0) * CFrame.new(1, 0, 0))
            else
                effectModel:PivotTo(targetCFrame)
            end
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
        if data.config and data.config.assetId == LIBRARY_ASSET then

            data.effect:PivotTo(targetCFrame * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, -0.5, 0))
        else
            data.effect:PivotTo(targetCFrame)
        end
        return true
    end

    local function startTrackingTarget(target, config)
        if trackedTargets[target] then return trackedTargets[target] end
        if config.assetId == LIBRARY_ASSET and target:IsA("Tool") then
            local ui = target:FindFirstChild("UI")
            if ui then
                ui:Destroy()
            end
        end
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
                deleteLibraryUIInWorkspace()
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
        if player then
            player:GetPropertyChangedSignal("Character"):Connect(function()
                cleanupDestroyedTargets()
                deleteLibraryUIInWorkspace()
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

local hint = Instance.new("Hint", Workspace)
hint.Text = "LoadingItem... Doors HardCore V10.6.5 By Mr.key & HeavenNow :)"
game.Debris:AddItem(hint, 3)