if workspace:FindFirstChild("HardcoreThree") then
    return
end
local marker = Instance.new("BoolValue")
marker.Name = "HardcoreThree"
marker.Value = true
marker.Parent = workspace
local entityBehaviors = {}
function entityBehaviors.levelrun()
local function GetRoom()
    local gruh = workspace:WaitForChild("CurrentRooms")
    local latestRoom = game.ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")

    return gruh:FindFirstChild(tostring(latestRoom.Value))
end

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()

function LoadCustomInstance(source, parent)
    local model

    while task.wait() and not model do
        if tonumber(source) then
            local success, result = pcall(function()
                return game:GetObjects("rbxassetid://" .. tostring(source))[1]
            end)

            if success and result then
                model = result
            end
        elseif typeof(source) == "string"
            and source:match("^https?://")
            and source:match("%.rbxm") then

            local success, result = pcall(function()
                return game:GetObjects(source)[1]
            end)

            if success and result then
                model = result
            end
        else
            break
        end

        if model then
            model.Parent = parent or workspace
        end
    end

    return model
end

local s = LoadCustomInstance(127433972073500, workspace)

if not s then
    return
end

local entity = s:FindFirstChildWhichIsA("BasePart", true)

if not entity then
    return
end

local room = GetRoom()

if not room then
    return
end

local entrance = room:WaitForChild("RoomEntrance")

entity.CFrame = entrance.CFrame * CFrame.new(0, 5, -15)
end

function entityBehaviors.levelrun2()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    return
end

local function findRecursive(root, name)
    if not root then
        return nil
    end
    return root:FindFirstChild(name, true)
end

local hardCoreSound = workspace:WaitForChild("HardCoreSound", 15)
local levelRUN = workspace:WaitForChild("levelRUN", 15)

if not hardCoreSound then
    return
end

if not levelRUN then
    return
end

local function waitForChild(parent, name, timeout)
    local found = parent:FindFirstChild(name, true)
    if found then
        return found
    end

    local start = os.clock()
    repeat
        task.wait(0.2)
        found = parent:FindFirstChild(name, true)
        if found then
            return found
        end
    until os.clock() - start >= timeout

    return nil
end

local RUN1 = waitForChild(hardCoreSound, "RUN1", 10)
local RUN2 = waitForChild(hardCoreSound, "RUN2", 10)
local RUN3 = waitForChild(hardCoreSound, "RUN3", 10)
local levelRunSound = waitForChild(levelRUN, "RUN", 10)

local entity = findRecursive(levelRUN, "entity") or findRecursive(workspace, "entity")
local nodes1 = findRecursive(levelRUN, "nodes1") or findRecursive(workspace, "nodes1")
local nodes2 = findRecursive(levelRUN, "nodes2") or findRecursive(workspace, "nodes2")
local door = findRecursive(levelRUN, "BackroomDOOR") or findRecursive(workspace, "BackroomDOOR")
local neon = door and findRecursive(door, "Neon")

if not RUN1 or not RUN2 or not RUN3 or not levelRunSound then
    return
end

if not entity or not (entity:IsA("Model") or entity:IsA("BasePart")) then
    return
end

if not nodes1 or not nodes1:IsA("BasePart") then
    return
end

if not nodes2 or not nodes2:IsA("BasePart") then
    return
end

if not neon then
    return
end

local promptPart
if neon:IsA("BasePart") then
    promptPart = neon
elseif neon:IsA("Attachment") then
    promptPart = neon
else
    promptPart = neon:FindFirstChildWhichIsA("BasePart", true)
end

if not promptPart then
    return
end

local ending = false
local run2Started = false
local movementStarted = false
local enSoundsStarted = false
local damageCooldowns = {}
local damageConnection
local fadeGui

local enSounds = {}
local enSoundNames = {
    EN1 = true,
    EN2 = true,
    EN3 = true,
    EN4 = true,
    EN5 = true
}

for _, descendant in ipairs(entity:GetDescendants()) do
    if descendant:IsA("Sound") and enSoundNames[descendant.Name] then
        descendant.Volume = 0.4
        table.insert(enSounds, descendant)
    end
end

if entity:IsA("Sound") and enSoundNames[entity.Name] then
    table.insert(enSounds, entity)
end

local function setSoundPlaying(sound, shouldPlay)
    if not sound or not sound:IsA("Sound") then
        return
    end

    if shouldPlay then
        sound:Play()
    else
        sound:Stop()
    end
end

local function setENSounds(shouldPlay)
    for _, sound in ipairs(enSounds) do
        if sound.Parent then
            if shouldPlay then
                sound.TimePosition = 0
                sound:Play()
            else
                sound:Stop()
            end
        end
    end
    enSoundsStarted = shouldPlay
end

local function getEntityPivot()
    if entity:IsA("Model") then
        return entity:GetPivot()
    end
    return entity.CFrame
end

local function pivotEntity(cframe)
    if entity:IsA("Model") then
        entity:PivotTo(cframe)
    else
        entity.CFrame = cframe
    end
end

local function moveEntityTo(targetPart, speed)
    if movementStarted or ending then
        return
    end

    movementStarted = true
    local verticalOffset = Vector3.new(0, 5, 0)
    pivotEntity(nodes1.CFrame + verticalOffset)

    task.spawn(function()
        local startCFrame = getEntityPivot()
        local targetCFrame = targetPart.CFrame + verticalOffset
        local distance = (targetCFrame.Position - startCFrame.Position).Magnitude
        local duration = distance / math.max(speed, 0.01)
        local startTime = os.clock()

        if duration <= 0 then
            pivotEntity(targetCFrame)
            return
        end

        while not ending and entity.Parent and os.clock() - startTime < duration do
            local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
            pivotEntity(startCFrame:Lerp(targetCFrame, alpha))
            RunService.Heartbeat:Wait()
        end

        if not ending and entity.Parent then
            pivotEntity(targetCFrame)
        end
    end)
end

local function startRaycastDetection()
    if damageConnection then
        return
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {entity}
    raycastParams.IgnoreWater = true

    local lastScan = 0

    damageConnection = RunService.Heartbeat:Connect(function()
        if ending or not RUN2.Playing or not entity.Parent then
            return
        end

        if os.clock() - lastScan < 0.1 then
            return
        end
        lastScan = os.clock()

        local origin = getEntityPivot().Position

        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if character and humanoid and root and humanoid.Health > 0 then
                local offset = root.Position - origin
                local distance = offset.Magnitude

                if distance <= 10 and distance > 0 then
                    local result = workspace:Raycast(origin, offset, raycastParams)

                    if result and result.Instance:IsDescendantOf(character) then
                        local now = os.clock()
                        if not damageCooldowns[player] or now - damageCooldowns[player] >= 1 then
                            damageCooldowns[player] = now
                            humanoid:TakeDamage(100)
                        end
                    end
                end
            end
        end
    end)
end

local function createBlackScreen()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    if fadeGui then
        fadeGui:Destroy()
    end

    fadeGui = Instance.new("ScreenGui")
    fadeGui.Name = "LevelRunTeleportFade"
    fadeGui.IgnoreGuiInset = true
    fadeGui.ResetOnSpawn = false
    fadeGui.DisplayOrder = 100000
    fadeGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "BlackFrame"
    frame.Size = UDim2.fromScale(1, 1)
    frame.Position = UDim2.fromScale(0, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ZIndex = 10000
    frame.Parent = fadeGui

    local tween = TweenService:Create(
        frame,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
        {BackgroundTransparency = 0}
    )
    tween:Play()
    tween.Completed:Wait()

    return frame
end

local function fadeScreenOut(frame)
    if not frame or not frame.Parent then
        return
    end

    local tween = TweenService:Create(
        frame,
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    tween:Play()
    tween.Completed:Wait()

    if fadeGui then
        fadeGui:Destroy()
        fadeGui = nil
    end
end

local prompt = promptPart:FindFirstChild("BackroomNeonPrompt")
if not prompt then
    prompt = Instance.new("ProximityPrompt")
    prompt.Name = "BackroomNeonPrompt"
    prompt.ActionText = "进入"
    prompt.ObjectText = "Backroom"
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true
    prompt.Enabled = false
    prompt.Parent = promptPart
end

local function startRun2()
    if run2Started or ending then
        return
    end
    run2Started = true

    RUN2.Looped = true
    RUN2:Play()
    setENSounds(true)
    setSoundPlaying(levelRunSound, true)

    prompt.Enabled = true

    moveEntityTo(nodes2, 20)
    startRaycastDetection()
end

local function playRun1ThenStartRun2()
    RUN1.Looped = false
    RUN2.Looped = true
    RUN3.Looped = false

    local endedConnection
    endedConnection = RUN1.Ended:Connect(function()
        if endedConnection then
            endedConnection:Disconnect()
            endedConnection = nil
        end
        startRun2()
    end)

    levelRunSound.Looped = true
    levelRunSound:Play()

    RUN1:Play()

    task.spawn(function()
        local startAt = os.clock()
        local sawPlaying = false

        while not ending and os.clock() - startAt < 8 do
            if RUN1.Playing then
                sawPlaying = true
                break
            end
            task.wait(0.1)
        end

        if not sawPlaying then
            startRun2()
            return
        end

        local maxWait = math.max(RUN1.TimeLength + 5, 30)
        local playStart = os.clock()

        while not ending and RUN1.Playing and os.clock() - playStart < maxWait do
            task.wait(0.1)
        end

        if not ending and not run2Started then
            startRun2()
        end
    end)
end

prompt.Triggered:Connect(function(player)
    if player and player ~= LocalPlayer then
        return
    end

    if ending or not run2Started then
        return
    end

    ending = true
    prompt.Enabled = false

    if damageConnection then
        damageConnection:Disconnect()
        damageConnection = nil
    end

    RUN2:Stop()

    local frame = createBlackScreen()

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    root.CFrame = CFrame.new(-216.211105, 236.492386, -685.299927)

    RUN3.Looped = false
    RUN3:Play()

    local run3Start = os.clock()
    local run3Timeout = math.max(RUN3.TimeLength + 5, 30)

    while RUN3.Playing and os.clock() - run3Start < run3Timeout do
        task.wait(0.1)
    end

    setENSounds(false)
    setSoundPlaying(levelRunSound, false)

    fadeScreenOut(frame)
end)

playRun1ThenStartRun2()
end

function entityBehaviors.level4()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local function GetRoom()
    local gruh = workspace.CurrentRooms
    return gruh:FindFirstChild(ReplicatedStorage.GameData.LatestRoom.Value)
end

local plr = Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()

function LoadCustomInstance(source, parent)
    local model
    while task.wait() and not model do
        if tonumber(source) then
            local success, result = pcall(function()
                return game:GetObjects("rbxassetid://" .. tostring(source))[1]
            end)
            if success and result then
                model = result
            end
        elseif typeof(source) == "string" and source:match("^https?://") and source:match("%.rbxm") then
            local success, result = pcall(function()
                return game:GetObjects(source)[1]
            end)
            if success and result then
                model = result
            end
        else
            break
        end
        if model then
            model.Parent = parent or workspace
        end
    end
    return model
end

local s = LoadCustomInstance(103126472538060, workspace)
if not s then
    return
end

local entity = s:FindFirstChildWhichIsA("BasePart")
if not entity then
    return
end

local room = GetRoom()
if not room then
    return
end

entity.CFrame = room:WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 5, -15)

local containerModel = s:FindFirstChild("Model", true)
if not containerModel then
    return
end

local exitModel = containerModel:FindFirstChild("EXIT", true)
if not exitModel then
    return
end

local exitPart = exitModel:FindFirstChild("Part", true)
if not exitPart or not exitPart:IsA("BasePart") then
    return
end

local prompt = exitPart:FindFirstChild("ExitTeleportPrompt")
if not prompt then
    prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ExitTeleportPrompt"
    prompt.ActionText = "传送"
    prompt.ObjectText = "EXIT"
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 5
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true
    prompt.Enabled = true
    prompt.Parent = exitPart
end

local destination = CFrame.new(-460.707581, 1239.604126, -1737.912109)
local activated = false

local playerGui = plr:WaitForChild("PlayerGui")
local blackGui = Instance.new("ScreenGui")
blackGui.Name = "ExitTeleportFadeGui"
blackGui.IgnoreGuiInset = true
blackGui.ResetOnSpawn = false
blackGui.DisplayOrder = 1000000
blackGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
blackGui.Parent = playerGui

local blackFrame = Instance.new("Frame")
blackFrame.Name = "BlackScreen"
blackFrame.Size = UDim2.fromScale(1, 1)
blackFrame.Position = UDim2.fromScale(0, 0)
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.BackgroundTransparency = 1
blackFrame.BorderSizePixel = 0
blackFrame.ZIndex = 1000000
blackFrame.Parent = blackGui

local function fadeToBlack(duration)
    local tween = TweenService:Create(
        blackFrame,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {BackgroundTransparency = 0}
    )
    tween:Play()
    tween.Completed:Wait()
end

local function fadeFromBlack(duration)
    local tween = TweenService:Create(
        blackFrame,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {BackgroundTransparency = 1}
    )
    tween:Play()
    tween.Completed:Wait()
end

local function toggleFreecam()
    local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
    local event = remotesFolder and remotesFolder:FindFirstChild("AdminPanelRunCommand")
    if event and event:IsA("RemoteEvent") then
        pcall(function()
            event:FireServer("Freecam", {})
        end)
    end
end

prompt.Triggered:Connect(function(player)
    if player and player ~= plr then
        return
    end

    if activated then
        return
    end
    activated = true
    prompt.Enabled = false

    fadeToBlack(1)

    toggleFreecam()

    local character = plr.Character or plr.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoidRootPart.CFrame = destination

    task.wait(2)
    toggleFreecam()

    fadeFromBlack(1)
    blackGui:Destroy()
end)
end

function entityBehaviors.BackroomsDOOR2()
local s = 120946832190168
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local POSITION = Vector3.new(198.796600, -0.198376, -48.286716)
local ROTATION = CFrame.Angles(0, math.rad(-90), 0)
local MOVE_DISTANCE = 2
local MOVE_DURATION = 1.5
local FADE_DURATION = 1

local function main()
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(s))
    end)

    if not success or not objects or not objects[1] then
        return
    end

    local source = objects[1]
    local model

    if source:IsA("Model") then
        model = source
    else
        model = Instance.new("Model")
        model.Name = source.Name
        source.Parent = model
    end

    model.Parent = workspace
    model:PivotTo(CFrame.new(POSITION) * ROTATION)

    local base = model:FindFirstChild("Base", true)

    if not base then
        return
    end

    local attachment = base:FindFirstChild("Attachment542", true)

    if not attachment or not attachment:IsA("Attachment") then
        return
    end

    local circle = attachment:FindFirstChild("Circle", true)

    if not circle then
        return
    end

    local saved = {}

    local transparencyProperties = {
        "Transparency",
        "LocalTransparencyModifier",
        "FillTransparency",
        "OutlineTransparency",
        "ImageTransparency",
        "TextTransparency",
        "TextStrokeTransparency",
        "BackgroundTransparency",
        "ScrollBarImageTransparency",
        "GroupTransparency"
    }

    local function setProperty(inst, property, value)
        pcall(function()
            inst[property] = value
        end)
    end

    local function getProperty(inst, property)
        local ok, value = pcall(function()
            return inst[property]
        end)

        if ok then
            return value
        end

        return nil
    end

    local function isVisualEffect(inst)
        return inst:IsA("Light")
            or inst:IsA("ParticleEmitter")
            or inst:IsA("Beam")
            or inst:IsA("Trail")
            or inst:IsA("Fire")
            or inst:IsA("Smoke")
            or inst:IsA("Sparkles")
            or inst:IsA("Highlight")
    end

    local function capture(inst)
        local data = {
            transparency = {},
            enabled = nil,
            brightness = nil
        }

        for _, property in ipairs(transparencyProperties) do
            local value = getProperty(inst, property)

            if typeof(value) == "number"
                or typeof(value) == "NumberSequence" then
                data.transparency[property] = value
            end
        end

        if isVisualEffect(inst) then
            local value = getProperty(inst, "Enabled")

            if typeof(value) == "boolean" then
                data.enabled = value
            end
        end

        if inst:IsA("Light") then
            data.brightness = inst.Brightness
        end

        return data
    end

    local function setTransparencyOne(inst, data)
        for property, value in pairs(data.transparency) do
            if typeof(value) == "NumberSequence" then
                setProperty(inst, property, NumberSequence.new(1))
            else
                setProperty(inst, property, 1)
            end
        end
    end

    local function restoreTransparency(inst, data)
        for property, value in pairs(data.transparency) do
            setProperty(inst, property, value)
        end
    end

    local function restoreState(inst, data)
        if not inst.Parent and inst ~= model then
            return
        end

        restoreTransparency(inst, data)

        if data.brightness ~= nil then
            setProperty(inst, "Brightness", data.brightness)
        end

        if data.enabled ~= nil then
            setProperty(inst, "Enabled", data.enabled)
        end
    end

    local function hideObject(inst, data)
        setTransparencyOne(inst, data)

        if data.brightness ~= nil then
            setProperty(inst, "Brightness", 0)
        end

        if data.enabled ~= nil then
            setProperty(inst, "Enabled", false)
        end
    end

    local function alphaValue(original, alpha)
        if typeof(original) == "number" then
            return 1 + (original - 1) * alpha
        end

        if typeof(original) == "NumberSequence" then
            local points = {}

            for _, point in ipairs(original.Keypoints) do
                table.insert(
                    points,
                    NumberSequenceKeypoint.new(
                        point.Time,
                        1 + (point.Value - 1) * alpha,
                        point.Envelope * alpha
                    )
                )
            end

            return NumberSequence.new(points)
        end

        return original
    end

    local function applyAlpha(inst, data, alpha)
        if not inst.Parent then
            return
        end

        for property, original in pairs(data.transparency) do
            setProperty(
                inst,
                property,
                alphaValue(original, alpha)
            )
        end

        if data.brightness ~= nil then
            setProperty(
                inst,
                "Brightness",
                data.brightness * alpha
            )
        end
    end

    local function fadeIn(targets, duration)
        for _, item in ipairs(targets) do
            local inst = item.instance
            local data = item.data

            if inst.Parent then
                setTransparencyOne(inst, data)

                if data.brightness ~= nil then
                    setProperty(inst, "Brightness", 0)
                end

                if data.enabled ~= nil then
                    setProperty(inst, "Enabled", data.enabled)
                end
            end
        end

        local startTime = os.clock()

        while true do
            local progress = math.clamp(
                (os.clock() - startTime) / duration,
                0,
                1
            )

            local alpha = TweenService:GetValue(
                progress,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            )

            for _, item in ipairs(targets) do
                applyAlpha(item.instance, item.data, alpha)
            end

            if progress >= 1 then
                break
            end

            RunService.Heartbeat:Wait()
        end
    end

    local function restoreTree(root)
        local list = {root}

        for _, inst in ipairs(root:GetDescendants()) do
            table.insert(list, inst)
        end

        for _, inst in ipairs(list) do
            local data = saved[inst]

            if data then
                restoreState(inst, data)
            end
        end
    end

    local function hideTreeTransparency(root)
        local list = {root}

        for _, inst in ipairs(root:GetDescendants()) do
            table.insert(list, inst)
        end

        for _, inst in ipairs(list) do
            local data = saved[inst]

            if data then
                setTransparencyOne(inst, data)
            end
        end
    end

    local descendants = model:GetDescendants()
    table.insert(descendants, model)

    for _, inst in ipairs(descendants) do
        local data = capture(inst)
        saved[inst] = data
        hideObject(inst, data)
    end

    local earlyEmitters = {}

    for _, inst in ipairs(attachment:GetDescendants()) do
        if inst:IsA("ParticleEmitter") then
            earlyEmitters[inst] = true
        end
    end

    for inst in pairs(earlyEmitters) do
        if inst.Parent and saved[inst] then
            restoreState(inst, saved[inst])
        end
    end

    local parent = attachment.Parent
    local parentCFrame

    if parent:IsA("BasePart") then
        parentCFrame = parent.CFrame
    elseif parent:IsA("Attachment") then
        parentCFrame = parent.WorldCFrame
    else
        return
    end

    local localDown = parentCFrame:VectorToObjectSpace(
        Vector3.new(0, -MOVE_DISTANCE, 0)
    )

    local moveTween = TweenService:Create(
        attachment,
        TweenInfo.new(
            MOVE_DURATION,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut
        ),
        {
            Position = attachment.Position + localDown
        }
    )

    moveTween:Play()
    moveTween.Completed:Wait()

    if not model.Parent or not attachment.Parent then
        return
    end

    restoreTree(circle)

    task.wait(3)

    if not model.Parent or not attachment.Parent then
        return
    end

    local beams = {}
    local beamSet = {}

    for _, inst in ipairs(attachment:GetDescendants()) do
        if inst:IsA("Beam") then
            table.insert(beams, inst)
            beamSet[inst] = true

            if saved[inst] then
                restoreState(inst, saved[inst])
            end
        end
    end

    local function playSound(soundId)
        local sound = Instance.new("Sound")
        sound.Name = "ModelEffectSound"
        sound.SoundId = "rbxassetid://" .. tostring(soundId)
        sound.Volume = 1
        sound.Looped = false
        sound.Parent = attachment

        sound.Ended:Connect(function()
            sound:Destroy()
        end)

        sound:Play()

        return sound
    end

    playSound(139620337204036)

    local cameraShakerModule = ReplicatedStorage:FindFirstChild("CameraShaker")

    if cameraShakerModule then
        local ok, explosionCameraShaker = pcall(require, cameraShakerModule)

        if ok and explosionCameraShaker then
            local camera = workspace.CurrentCamera

            local shakerOK, explosionCamShake = pcall(function()
                return explosionCameraShaker.new(
                    Enum.RenderPriority.Camera.Value,
                    function(shakeCf)
                        local currentCamera = workspace.CurrentCamera

                        if currentCamera then
                            currentCamera.CFrame = currentCamera.CFrame * shakeCf
                        end
                    end
                )
            end)

            if shakerOK and explosionCamShake then
                explosionCamShake:Start()
                explosionCamShake:ShakeOnce(
                    13,
                    200,
                    0.02,
                    4,
                    2,
                    1
                )
            end
        end
    end

    task.wait(2)

    if not model.Parent or not attachment.Parent then
        return
    end

    playSound(120212342534790)

    local circleSet = {[circle] = true}

    for _, inst in ipairs(circle:GetDescendants()) do
        circleSet[inst] = true
    end

    local targets = {}

    for inst, data in pairs(saved) do
        if inst ~= model
            and inst ~= attachment
            and not earlyEmitters[inst]
            and not circleSet[inst]
            and not beamSet[inst]
            and (
                next(data.transparency) ~= nil
                or data.brightness ~= nil
            ) then

            table.insert(targets, {
                instance = inst,
                data = data
            })
        end
    end

    fadeIn(targets, FADE_DURATION)

    if not model.Parent then
        return
    end

    local neon = model:FindFirstChild("Neon", true)

    if neon and neon:IsA("BasePart") then
        local prompt = neon:FindFirstChildWhichIsA("ProximityPrompt", true)

        if not prompt then
            prompt = Instance.new("ProximityPrompt")
        end

        prompt.Name = "NenoInteraction"
        prompt.ActionText = "互动"
        prompt.ObjectText = "Neno"
        prompt.Style = Enum.ProximityPromptStyle.Custom
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        prompt.HoldDuration = 10
        prompt.MaxActivationDistance = 12
        prompt.RequiresLineOfSight = false
        prompt.ClickablePrompt = true
        prompt.Enabled = true
        prompt.Parent = neon

        local player = Players.LocalPlayer

        if player then
            local interactionRunning = false

            prompt.Triggered:Connect(function(triggeringPlayer)
                if triggeringPlayer and triggeringPlayer ~= player then
                    return
                end

                if interactionRunning then
                    return
                end

                interactionRunning = true
                prompt.Enabled = false

                local character = player.Character or player.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local humrootpart = character:FindFirstChild("HumanoidRootPart")
                local head = character:FindFirstChild("Head")

                if not humanoid or not humrootpart or not head then
                    interactionRunning = false
                    prompt.Enabled = true
                    return
                end

                local animator = humanoid:FindFirstChildOfClass("Animator")

                if not animator then
                    animator = Instance.new("Animator")
                    animator.Parent = humanoid
                end

                local CutsceneAnimation = Instance.new("Animation")
                CutsceneAnimation.AnimationId = "rbxassetid://10096088747"

                local loaded, animationTrack = pcall(function()
                    return animator:LoadAnimation(CutsceneAnimation)
                end)

                if not loaded or not animationTrack then
                    CutsceneAnimation:Destroy()
                    interactionRunning = false
                    prompt.Enabled = true
                    return
                end

                animationTrack.Priority = Enum.AnimationPriority.Action

                local followhead = true
                local maingame
                local cameraBindName = "NenoCutsceneCamera_" .. tostring(player.UserId)
                local transitionStarted = false
                local animationFinishedEvent = Instance.new("BindableEvent")

                local function playClientSound(soundId, volume, looped)
                    local sound = Instance.new("Sound")
                    sound.Name = "NenoCutsceneSound"
                    sound.SoundId = "rbxassetid://" .. tostring(soundId)
                    sound.Volume = volume
                    sound.Looped = looped == true
                    sound.Parent = SoundService
                    sound:Play()

                    if not sound.Looped then
                        sound.Ended:Connect(function()
                            sound:Destroy()
                        end)
                    end

                    return sound
                end

                local function runTransitionSequence()
                    if transitionStarted then
                        return
                    end
                    transitionStarted = true

                    local playerGui = player:WaitForChild("PlayerGui")
                    local blur = Instance.new("BlurEffect")
                    blur.Name = "NenoCutsceneBlur"
                    blur.Size = 0
                    blur.Parent = Lighting

                    local blurTween = TweenService:Create(
                        blur,
                        TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Size = 24}
                    )
                    blurTween:Play()

                    local transitionLoopSound = playClientSound(135454814111440, 1, true)

                    local screenGui = Instance.new("ScreenGui")
                    screenGui.Name = "NenoCutsceneTransition"
                    screenGui.IgnoreGuiInset = true
                    screenGui.ResetOnSpawn = false
                    screenGui.DisplayOrder = 1000000
                    screenGui.Parent = playerGui

                    local blackFrame = Instance.new("Frame")
                    blackFrame.Name = "Blackout"
                    blackFrame.Size = UDim2.fromScale(1, 1)
                    blackFrame.Position = UDim2.fromScale(0, 0)
                    blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
                    blackFrame.BackgroundTransparency = 1
                    blackFrame.BorderSizePixel = 0
                    blackFrame.Parent = screenGui

                    task.wait(4)

                    local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
                    local freecamEvent = remotesFolder and remotesFolder:FindFirstChild("AdminPanelRunCommand")

                    local flashStarted = os.clock()
                    local flashOn = false
                    while os.clock() - flashStarted < 1.5 do
                        flashOn = not flashOn
                        blackFrame.BackgroundTransparency = flashOn and 0 or 1
                        task.wait(0.055)
                    end

                    blackFrame.BackgroundTransparency = 0

                    if freecamEvent and freecamEvent:IsA("RemoteEvent") then
                        pcall(function()
                            freecamEvent:FireServer("Freecam", {})
                        end)
                    end

                    playClientSound(101395573137763, 1, false)

                    task.wait(0.15)

                    local destinations = {
                        Vector3.new(-355.018707, 240.160553, -897.379639),
                        Vector3.new(-514.356201, 240.160553, -776.105164),
                        Vector3.new(-632.397095, 240.160583, -570.413696),
                        Vector3.new(-778.696899, 240.160568, -918.462097)
                    }

                    local destination = destinations[math.random(1, #destinations)]
                    local currentCharacter = player.Character
                    local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                    local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")

                    if currentRoot then
                        currentRoot.CFrame = CFrame.new(destination)
                    end

                    task.wait(3)

                    animationFinishedEvent.Event:Wait()

                    followhead = false
                    pcall(function()
                        RunService:UnbindFromRenderStep(cameraBindName)
                    end)

                    if maingame then
                        pcall(function()
                            maingame.stopcam = false
                        end)
                    end

                    local currentCamera = workspace.CurrentCamera
                    if currentCamera and currentHumanoid then
                        currentCamera.CameraType = Enum.CameraType.Custom
                        currentCamera.CameraSubject = currentHumanoid
                    end

                    task.wait(2)

                    if freecamEvent and freecamEvent:IsA("RemoteEvent") then
                        pcall(function()
                            freecamEvent:FireServer("Freecam", {})
                        end)
                    end

                    if maingame then
                        pcall(function()
                            maingame.titlelocation("The Backrooms", true)
                        end)
                    else
                        pcall(function()
                            local mainUI = playerGui:FindFirstChild("MainUI")
                            local initiator = mainUI and mainUI:FindFirstChild("Initiator")
                            local module = initiator and initiator:FindFirstChild("Main_Game")
                            if module then
                                local gameModule = require(module)
                                gameModule.titlelocation("The Backrooms", true)
                            end
                        end)
                    end

                    local music = Instance.new("Sound")
                    music.Name = "BackroomsLoopMusic"
                    music.SoundId = "rbxassetid://136413104247411"
                    music.Volume = 0
                    music.Looped = true
                    music.Parent = SoundService
                    music:Play()

                    if transitionLoopSound then
                        transitionLoopSound:Stop()
                        transitionLoopSound:Destroy()
                        transitionLoopSound = nil
                    end

                    local blurOut = TweenService:Create(
                        blur,
                        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                        {Size = 0}
                    )
                    local screenOut = TweenService:Create(
                        blackFrame,
                        TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                        {BackgroundTransparency = 1}
                    )

                    blurOut:Play()
                    screenOut:Play()
                    screenOut.Completed:Wait()

                    if blur.Parent then
                        blur:Destroy()
                    end
                    if screenGui.Parent then
                        screenGui:Destroy()
                    end

                    local musicFadeIn = TweenService:Create(
                        music,
                        TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                        {Volume = 0.8}
                    )
                    musicFadeIn:Play()
                    musicFadeIn.Completed:Wait()

                    if model and model.Parent then
                        model:Destroy()
                    end

                    local level0 = workspace:FindFirstChild("level0") or workspace:FindFirstChild("Level0")
                    local doorModel = level0 and level0:FindFirstChild("BackroomDOOR", true)
                    local doorNeon = doorModel and doorModel:FindFirstChild("Neon", true)

                    if doorNeon and doorNeon:IsA("BasePart") then
                        local doorPrompt = doorNeon:FindFirstChild("BackroomDoorInteraction")

                        if not doorPrompt or not doorPrompt:IsA("ProximityPrompt") then
                            doorPrompt = Instance.new("ProximityPrompt")
                        end

                        doorPrompt.Name = "BackroomDoorInteraction"
                        doorPrompt.ActionText = "进入"
                        doorPrompt.ObjectText = "BackroomDOOR"
                        doorPrompt.Style = Enum.ProximityPromptStyle.Custom
                        doorPrompt.KeyboardKeyCode = Enum.KeyCode.E
                        doorPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
                        doorPrompt.HoldDuration = 5
                        doorPrompt.MaxActivationDistance = 12
                        doorPrompt.RequiresLineOfSight = false
                        doorPrompt.ClickablePrompt = true
                        doorPrompt.Enabled = true
                        doorPrompt.Parent = doorNeon

                        local doorInteractionRunning = false

                        doorPrompt.Triggered:Connect(function(triggeringPlayer)
                            if triggeringPlayer and triggeringPlayer ~= player then
                                return
                            end

                            if doorInteractionRunning then
                                return
                            end

                            doorInteractionRunning = true
                            doorPrompt.Enabled = false

                            task.spawn(function()
                                if music and music.Parent then
                                    music:Stop()
                                    music:Destroy()
                                end

                                local doorPlayerGui = player:WaitForChild("PlayerGui")
                                local doorScreenGui = Instance.new("ScreenGui")
                                doorScreenGui.Name = "BackroomDoorTransition"
                                doorScreenGui.IgnoreGuiInset = true
                                doorScreenGui.ResetOnSpawn = false
                                doorScreenGui.DisplayOrder = 1000001
                                doorScreenGui.Parent = doorPlayerGui

                                local doorBlackFrame = Instance.new("Frame")
                                doorBlackFrame.Name = "Blackout"
                                doorBlackFrame.Size = UDim2.fromScale(1, 1)
                                doorBlackFrame.Position = UDim2.fromScale(0, 0)
                                doorBlackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
                                doorBlackFrame.BackgroundTransparency = 1
                                doorBlackFrame.BorderSizePixel = 0
                                doorBlackFrame.Parent = doorScreenGui

                                local fadeToBlack = TweenService:Create(
                                    doorBlackFrame,
                                    TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                                    {BackgroundTransparency = 0}
                                )
                                fadeToBlack:Play()
                                fadeToBlack.Completed:Wait()

                                local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
                                local freecamEvent = remotesFolder and remotesFolder:FindFirstChild("AdminPanelRunCommand")

                                if freecamEvent and freecamEvent:IsA("RemoteEvent") then
                                    pcall(function()
                                        freecamEvent:FireServer("Freecam", {})
                                    end)
                                end

                                local doorDestinations = {
                                    Vector3.new(-613.611633, 1159.534668, -1269.960449),
                                    Vector3.new(-306.580200, 1183.534546, -1020.567139),
                                    Vector3.new(-26.853359, 1178.734741, -1242.978027),
                                    Vector3.new(-238.125473, 1159.534546, -931.585022)
                                }

                                local doorDestination = doorDestinations[math.random(1, #doorDestinations)]
                                local doorCharacter = player.Character
                                local doorRoot = doorCharacter and doorCharacter:FindFirstChild("HumanoidRootPart")

                                if doorRoot then
                                    doorRoot.CFrame = CFrame.new(doorDestination)
                                end

                                task.wait(0.15)

                                if freecamEvent and freecamEvent:IsA("RemoteEvent") then
                                    pcall(function()
                                        freecamEvent:FireServer("Freecam", {})
                                    end)
                                end

                                local fadeFromBlack = TweenService:Create(
                                    doorBlackFrame,
                                    TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                                    {BackgroundTransparency = 1}
                                )
                                fadeFromBlack:Play()
                                fadeFromBlack.Completed:Wait()

                                if doorScreenGui.Parent then
                                    doorScreenGui:Destroy()
                                end

                                local finalMusic = Instance.new("Sound")
                                finalMusic.Name = "BackroomDoorLoopMusic"
                                finalMusic.SoundId = "rbxassetid://140698715847574"
                                finalMusic.Volume = 0
                                finalMusic.Looped = true
                                finalMusic.Parent = SoundService
                                finalMusic:Play()

                                local finalMusicFade = TweenService:Create(
                                    finalMusic,
                                    TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                                    {Volume = 0.8}
                                )
                                finalMusicFade:Play()
                            end)
                        end)
                    end

                    animationFinishedEvent:Destroy()
                end

                local function cleanup()
                    followhead = false

                    pcall(function()
                        RunService:UnbindFromRenderStep(cameraBindName)
                    end)

                    if animationTrack.IsPlaying then
                        animationTrack:Stop()
                    end

                    if humrootpart.Parent then
                        humrootpart.Anchored = false
                    end

                    if maingame then
                        pcall(function()
                            maingame.stopcam = false
                        end)
                    end

                    local currentCamera = workspace.CurrentCamera
                    if currentCamera and humanoid and humanoid.Parent then
                        currentCamera.CameraType = Enum.CameraType.Custom
                        currentCamera.CameraSubject = humanoid
                    end

                    CutsceneAnimation:Destroy()
                    interactionRunning = false

                    if prompt.Parent then
                        prompt.Enabled = true
                    end
                end

                task.spawn(function()
                    pcall(function()
                        local playerGui = player:WaitForChild("PlayerGui")
                        local mainUI = playerGui:FindFirstChild("MainUI")
                        local initiator = mainUI and mainUI:FindFirstChild("Initiator")
                        local mainGameModule = initiator and initiator:FindFirstChild("Main_Game")

                        if mainGameModule then
                            local required, result = pcall(require, mainGameModule)

                            if required then
                                maingame = result
                                maingame.stopcam = true
                            end
                        end

                        humrootpart.Anchored = true
                        humrootpart.CFrame = humrootpart.CFrame + Vector3.new(0, 1, 0)

                        RunService:BindToRenderStep(
                            cameraBindName,
                            Enum.RenderPriority.Camera.Value + 1,
                            function()
                                local currentCamera = workspace.CurrentCamera

                                if followhead and currentCamera and head.Parent then
                                    currentCamera.CFrame = currentCamera.CFrame:Lerp(
                                        head.CFrame,
                                        0.3
                                    )
                                end
                            end
                        )

                        animationTrack:Play()
                        task.spawn(runTransitionSequence)
                        animationTrack:AdjustSpeed(0.8)
                        task.wait(0.5)
                        animationTrack:AdjustSpeed(0.25)
                        task.wait(3.5)
                        animationTrack:AdjustSpeed(-0.2)
                        task.wait(0.1)
                        animationTrack:AdjustSpeed(-0.4)
                        task.wait(0.2)
                        animationTrack:AdjustSpeed(0.1)
                        task.wait(0.2)
                        animationTrack:AdjustSpeed(-0.25)
                        task.wait(1.5)
                        animationTrack:AdjustSpeed(-0.15)
                        task.wait(2)
                        animationTrack:AdjustSpeed(0)
                        task.wait(2)
                        animationTrack:Stop()
                    end)

                    cleanup()
                    animationFinishedEvent:Fire()
                end)
            end)
        end
    end

    for _, beam in ipairs(beams) do
        if beam.Parent and saved[beam] then
            setTransparencyOne(beam, saved[beam])
        end
    end

    hideTreeTransparency(circle)
end
main()
end
function entityBehaviors.level0()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
if not plr then
    plr = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local function GetRoot()
    local chr = plr.Character
    if not chr then
        chr = plr.CharacterAdded:Wait()
    end
    return chr:WaitForChild("HumanoidRootPart")
end

local hrp = GetRoot()

plr.CharacterAdded:Connect(function(newChr)
    hrp = newChr:WaitForChild("HumanoidRootPart")
end)

repeat task.wait() until game:IsLoaded()

require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("WARNING!!DON'T MOVE!!", true)

task.wait(5)

local ComeBackPos = CFrame.new(217.071762, -0.158280, -48.050556)
local GoToPos = CFrame.new(151.714172, -0.158280, -48.628170)

local function Teleport(cf)
    if hrp then
        hrp.CFrame = cf
    end
end

function GetRoom()
    local gruh = workspace.CurrentRooms
    return gruh:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

function LoadCustomInstance(source, parent)
    local model

    local function NormalizeGitHubURL(url)
        if url:match("^https://github.com/.+%.rbxm$") and not url:find("?raw=true") then
            return url .. "?raw=true"
        end
        return url
    end

    while task.wait() and not model do
        if tonumber(source) then
            local success, result = pcall(function()
                return game:GetObjects("rbxassetid://" .. tostring(source))[1]
            end)
            if success and result then
                model = result
            end
        elseif typeof(source) == "string"
            and source:match("^https?://")
            and source:match("%.rbxm") then

            local url = NormalizeGitHubURL(source)
            local success, result = pcall(function()
                local filename = "temp_" .. math.random(100000, 999999) .. ".rbxm"
                local content = game:HttpGet(url)

                if writefile and (getcustomasset or getsynasset) and isfile and delfile then
                    writefile(filename, content)
                    local assetFunc = getcustomasset or getsynasset
                    local obj = game:GetObjects(assetFunc(filename))[1]
                    delfile(filename)
                    return obj
                else

                    return nil
                end
            end)

            if success and result then
                model = result
            end
        else
            break
        end

        if model then
            model.Parent = parent or workspace
            for _, obj in ipairs(model:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") then
                    obj:Destroy()
                end
            end
            pcall(function()
                model:SetAttribute("LoadedByExecutor", true)
            end)
        end
    end

    return model
end

local Event = ReplicatedStorage:WaitForChild("RemotesFolder"):WaitForChild("AdminPanelRunCommand")

Event:FireServer("Fly", {})

task.wait(0.5)

local preload = LoadCustomInstance(73412773816479, workspace)
if preload then
    preload:Destroy()
end

Teleport(GoToPos)

task.wait(0.1)

local s = LoadCustomInstance(135418599547769, workspace)
if not s then

    return
end

local entity = s:FindFirstChildWhichIsA("BasePart")
if not entity then
    return
end

local room = GetRoom()
if not room then
    return
end

local entrance = room:WaitForChild("RoomEntrance")
entity.CFrame = entrance.CFrame * CFrame.new(0, 5, -15)

if entity:FindFirstChild("Part") and entity.Part:IsA("BasePart") then
    entity.Part.CFrame = entity.CFrame
end

pcall(function()
    local roomName = tostring(game.ReplicatedStorage.GameData.LatestRoom.Value)
    local targetRoom = workspace.CurrentRooms:FindFirstChild(roomName)
    if targetRoom then
        for _, obj in ipairs(targetRoom:GetDescendants()) do
            if obj.Name == "PlaySound" and obj:IsA("Sound") then
                obj:Stop()
                obj.Playing = false
                obj.TimePosition = 0
                obj.Looped = false
            end
        end
    end
end)

task.wait(0.1)

Teleport(ComeBackPos)

Event:FireServer("Fly", {})

if plr.Name ~= "QWQ75321" then
    pcall(function()
        local doorsAdmin = plr:WaitForChild("PlayerGui"):FindFirstChild("DoorsAdmin")
        if doorsAdmin then
            doorsAdmin:Destroy()
        end
    end)
end
end

function entityBehaviors.level1()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

function GetRoom()
    local gruh = workspace.CurrentRooms
    return gruh:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()

function LoadCustomInstance(source, parent)
    local model
    while task.wait() and not model do
        if tonumber(source) then
            local success, result = pcall(function()
                return game:GetObjects("rbxassetid://" .. tostring(source))[1]
            end)
            if success and result then
                model = result
            end
        elseif typeof(source) == "string" and source:match("^https?://") and source:match("%.rbxm") then
            local success, result = pcall(function()
                return game:GetObjects(source)[1]
            end)
            if success and result then
                model = result
            end
        else
            break
        end
        if model then
            model.Parent = parent or workspace
        end
    end
    return model
end

local s = LoadCustomInstance(97111631005676, workspace)
if not s then
    return
end

local entity = s:FindFirstChildWhichIsA("BasePart")
entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 5, -15)
pcall(function()
    entity.Part.CFrame = entity.CFrame
end)

local function getPromptParent(target)
    if not target then
        return nil
    end

    if target:IsA("BasePart") or target:IsA("Attachment") then
        return target
    end

    if target:IsA("Model") or target:IsA("Folder") then
        if target:IsA("Model") and target.PrimaryPart then
            return target.PrimaryPart
        end
        return target:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function configurePrompt(prompt, name, actionText, objectText, holdDuration)
    prompt.Name = name
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = holdDuration
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true
    prompt.Enabled = true
end

local function createPrompt(target, name, actionText, objectText, holdDuration)
    local promptParent = getPromptParent(target)
    if not promptParent or not promptParent:IsDescendantOf(workspace) then
        return nil
    end

    local prompt = promptParent:FindFirstChild(name)
    if prompt and not prompt:IsA("ProximityPrompt") then
        prompt:Destroy()
        prompt = nil
    end

    if not prompt then
        prompt = Instance.new("ProximityPrompt")
        configurePrompt(prompt, name, actionText, objectText, holdDuration)
        prompt.Parent = promptParent
    else
        prompt.Enabled = false
        configurePrompt(prompt, name, actionText, objectText, holdDuration)
        prompt.Parent = promptParent
    end

    return prompt
end

local function waitForDescendant(root, name, timeout)
    local deadline = os.clock() + (timeout or 10)
    local found = root:FindFirstChild(name, true)
    while not found and os.clock() < deadline do
        task.wait(0.1)
        found = root:FindFirstChild(name, true)
    end
    return found
end

local one = waitForDescendant(s, "ONE", 10)
if one then
    local onePrompt = createPrompt(one, "ONEInteraction", "Interact", "ONE", 8)
    if onePrompt then
        onePrompt.Triggered:Connect(function(player)
            if player and player ~= plr then
                return
            end
        end)
    end
else
end

local mapFolder = waitForDescendant(s, "Map", 10)
local partsFolder = mapFolder and (mapFolder:FindFirstChild("Parts") or mapFolder:FindFirstChild("Parts", true))
local boldModel = partsFolder and (partsFolder:FindFirstChild("BOLD") or partsFolder:FindFirstChild("BOLD", true))
local solidPart = boldModel and boldModel:FindFirstChild("solid_4248", true)
local doorPrompt = nil
local doorOpened = false
local teleportPromptCreated = false

local function showAccessCardCaption()
    pcall(function()
        local playerGui = plr:WaitForChild("PlayerGui")
        local mainUI = playerGui:WaitForChild("MainUI")
        local initiator = mainUI:WaitForChild("Initiator")
        local mainGameModule = initiator:WaitForChild("Main_Game")
        require(mainGameModule).caption("Looks like I need an access card...", true)
    end)
end

local function findSound(root, soundName)
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("Sound") and string.lower(item.Name) == string.lower(soundName) then
            return item
        end
    end
    return nil
end

local function openEndDoor()
    if doorOpened or not partsFolder then
        return
    end

    local endDoor = partsFolder:FindFirstChild("ENDdoor") or partsFolder:FindFirstChild("ENDdoor", true)
    if not endDoor then
        return
    end

    local doorSound = findSound(endDoor, "metal door open")
    if doorSound then
        doorSound.Looped = false
        doorSound.TimePosition = 0
        doorSound:Play()
    end

    local moveInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    if endDoor:IsA("Model") then
        local startPivot = endDoor:GetPivot()
        local pivotValue = Instance.new("CFrameValue")
        pivotValue.Value = startPivot

        local pivotConnection = pivotValue:GetPropertyChangedSignal("Value"):Connect(function()
            if endDoor.Parent then
                endDoor:PivotTo(pivotValue.Value)
            end
        end)

        local moveTween = TweenService:Create(
            pivotValue,
            moveInfo,
            {Value = startPivot + Vector3.new(0, 8, 0)}
        )

        moveTween:Play()
        moveTween.Completed:Wait()
        pivotConnection:Disconnect()
        pivotValue:Destroy()
    elseif endDoor:IsA("BasePart") then
        local moveTween = TweenService:Create(
            endDoor,
            moveInfo,
            {CFrame = endDoor.CFrame + Vector3.new(0, 8, 0)}
        )

        moveTween:Play()
        moveTween.Completed:Wait()
    else
        return
    end

    doorOpened = true
end

local function stopPreviousBackgroundMusic()
    local targetId = "140698715847574"

    for _, inst in ipairs(game:GetDescendants()) do
        if inst:IsA("Sound") then
            local soundId = tostring(inst.SoundId)
            local numericId = soundId:match("(%d+)")

            if numericId == targetId and inst.IsPlaying then
                inst:Stop()
            end
        end
    end
end

local function getAdminCommandRemote()
    local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
    local remote = remotesFolder and remotesFolder:FindFirstChild("AdminPanelRunCommand")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

local function runFreecam()
    local remote = getAdminCommandRemote()
    if remote then
        pcall(function()
            remote:FireServer("Freecam", {})
        end)
    end
end

local function teleportWithBlackScreen()
    local playerGui = plr:WaitForChild("PlayerGui")
    local screenGui = playerGui:FindFirstChild("CustomTeleportFade")

    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "CustomTeleportFade"
        screenGui.IgnoreGuiInset = true
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 1000000
        screenGui.Parent = playerGui
    end

    local blackFrame = screenGui:FindFirstChild("BlackFrame")
    if not blackFrame then
        blackFrame = Instance.new("Frame")
        blackFrame.Name = "BlackFrame"
        blackFrame.Size = UDim2.fromScale(1, 1)
        blackFrame.Position = UDim2.fromScale(0, 0)
        blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        blackFrame.BackgroundTransparency = 1
        blackFrame.BorderSizePixel = 0
        blackFrame.ZIndex = 1000000
        blackFrame.Parent = screenGui
    end

    blackFrame.Visible = true
    blackFrame.BackgroundTransparency = 1

    local fadeIn = TweenService:Create(
        blackFrame,
        TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0}
    )
    fadeIn:Play()
    fadeIn.Completed:Wait()

    runFreecam()
    task.wait(0.2)

    local character = plr.Character or plr.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(450.359009, 975.776917, -1561.347778)
    stopPreviousBackgroundMusic()

    task.wait(0.25)
    runFreecam()
    task.wait(0.2)

    local fadeOut = TweenService:Create(
        blackFrame,
        TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    fadeOut:Play()
    fadeOut.Completed:Wait()
    blackFrame.Visible = false
end

local function createBackroomDoorPrompt()
    if teleportPromptCreated then
        return
    end

    local backroomDoor = waitForDescendant(s, "BackroomDOOR", 10)
    local neon = backroomDoor and backroomDoor:FindFirstChild("Neon", true)
    if not neon then
        return
    end

    local prompt = createPrompt(neon, "BackroomTeleportInteraction", "Enter", "Neon", 0)
    if not prompt then
        return
    end

    teleportPromptCreated = true
    local teleporting = false

    prompt.Triggered:Connect(function(player)
        if player and player ~= plr then
            return
        end
        if teleporting then
            return
        end

        teleporting = true
        prompt.Enabled = false
        teleportWithBlackScreen()
    end)
end

if solidPart and solidPart:IsA("BasePart") then
    doorPrompt = createPrompt(solidPart, "BoldDoorInteraction", "Open", "BOLD", 0)

    if doorPrompt then
        local handlingDoor = false

        doorPrompt.Triggered:Connect(function(player)
            if player and player ~= plr then
                return
            end
            if handlingDoor or doorOpened then
                return
            end

            handlingDoor = true

            local character = plr.Character or plr.CharacterAdded:Wait()
            local driveTool = character:FindFirstChild("Drive")

            if not driveTool or not driveTool:IsA("Tool") then
                showAccessCardCaption()
                handlingDoor = false
                return
            end

            openEndDoor()
            if doorOpened then
                createBackroomDoorPrompt()
                doorPrompt.Enabled = false
            end

            handlingDoor = false
        end)
    else
    end
else
end
end

local entityConfig = {
    ["rbxassetid://80"] = entityBehaviors.BackroomsDOOR2,
    ["rbxassetid://88"] = entityBehaviors.level0,
    ["rbxassetid://81"] = entityBehaviors.level1,
    ["rbxassetid://82"] = entityBehaviors.levelrun,
    ["rbxassetid://83"] = entityBehaviors.levelrun2,
    ["rbxassetid://79"] = entityBehaviors.level4
}
local checkedEntities = {}

local CONTAINER_NAMES = {"############", "Scary Entity"}

local function universalCheckSound(sound)
    if not sound:IsA("Sound") then return end

    local soundId = sound.SoundId
    local targetBehavior = entityConfig[soundId]

    if targetBehavior then
        local parent = sound.Parent

        if parent and table.find(CONTAINER_NAMES, parent.Name) then
            local grandParent = parent.Parent
            if grandParent and grandParent.Name == "CustomEntity" then
                if not checkedEntities[grandParent] then
                    checkedEntities[grandParent] = true
                    targetBehavior()
                end
            end
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    wait(0.1)
    universalCheckSound(obj)
end)

for _, entity in pairs(workspace:GetChildren()) do
    if entity.Name == "CustomEntity" then

        for _, containerName in ipairs(CONTAINER_NAMES) do
            local container = entity:FindFirstChild(containerName)
            if container then
                for _, child in pairs(container:GetChildren()) do
                    universalCheckSound(child)
                end
            end
        end
    end
end
local hint = Instance.new("Hint", Workspace)
hint.Text = "Loading... Doors HardCoreThree V10.6.5 By HeavenNow :)"
game.Debris:AddItem(hint, 3)
