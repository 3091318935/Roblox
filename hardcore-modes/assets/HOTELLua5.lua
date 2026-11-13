if workspace:FindFirstChild("HardcoreFive") then
    return
end
local marker = Instance.new("BoolValue")
marker.Name = "HardcoreFive"
marker.Value = true
marker.Parent = workspace
local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()
local entityBehaviors = {}

function entityBehaviors.Mush()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local MODEL_ID = "rbxassetid://79993520223456"

local SPAWN_DELAY = 5
local SPAWN_HEIGHT = 5.5

local RISE_HEIGHT = 9
local RISE_DURATION = 5
local DESCEND_DURATION = 5

local SHAKE_MAGNITUDE = 0.12
local SHAKE_ROUGHNESS = 8
local SHAKE_FADE_TIME = 1

local FOG_DELAY = 7

local MUSIC_FADE_IN = 2
local MUSIC_FADE_OUT = 2

local DISAPPEAR_DELAY = 10
local DISAPPEAR_DURATION = 1.5

local DARKNESS_DURATION = 18
local RECOVERY_DURATION = 2.5
local DAMAGE_AMOUNT = 200
local SPEED_REDUCTION = 0.85

local MOVE_SOUND_ID = "rbxassetid://87388390529602"
local FOG_SOUND_ID = "rbxassetid://4772620521"
local AMBIENT_SOUND_ID = "rbxassetid://112638428800232"

local phantomImages = {
    "rbxassetid://11380666994",
    "rbxassetid://9718225621",
    "rbxassetid://1188034146"
}

local function smoothstep(value)
    value = math.clamp(value, 0, 1)
    return value * value * (3 - 2 * value)
end

local function playOneShot(soundId, playbackSpeed, onEnded)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 1
    sound.PlaybackSpeed = playbackSpeed or 1
    sound.Looped = false
    sound.Parent = SoundService

    sound.Ended:Once(function()
        sound:Destroy()

        if onEnded then
            onEnded()
        end
    end)

    sound:Play()

    return sound
end

local function fadeOutSound(sound, duration)
    if not sound or not sound.Parent then
        return
    end

    local tween = TweenService:Create(
        sound,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out
        ),
        {
            Volume = 0
        }
    )

    tween.Completed:Once(function()
        if sound.Parent then
            sound:Stop()
            sound:Destroy()
        end
    end)

    tween:Play()
end

local function createVisionEffects()
    local playerGui = player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MushHallucinationEffects"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local darkness = Instance.new("Frame")
    darkness.Name = "Darkness"
    darkness.Size = UDim2.fromScale(1, 1)
    darkness.Position = UDim2.fromScale(0, 0)
    darkness.BackgroundColor3 = Color3.new(0, 0, 0)
    darkness.BackgroundTransparency = 1
    darkness.BorderSizePixel = 0
    darkness.ZIndex = 5
    darkness.Parent = screenGui

    local edges = {}

    local function createEdge(name, position, size, rotation)
        local edge = Instance.new("Frame")
        edge.Name = name
        edge.Position = position
        edge.Size = size
        edge.BackgroundColor3 = Color3.new(0, 0, 0)
        edge.BackgroundTransparency = 1
        edge.BorderSizePixel = 0
        edge.ZIndex = 6
        edge.Parent = screenGui

        local gradient = Instance.new("UIGradient")
        gradient.Rotation = rotation
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.25, 0.08),
            NumberSequenceKeypoint.new(0.6, 0.48),
            NumberSequenceKeypoint.new(1, 1)
        })
        gradient.Parent = edge

        table.insert(edges, edge)
    end

    createEdge(
        "Left",
        UDim2.fromScale(0, 0),
        UDim2.fromScale(0.48, 1),
        0
    )

    createEdge(
        "Right",
        UDim2.fromScale(0.52, 0),
        UDim2.fromScale(0.48, 1),
        180
    )

    createEdge(
        "Top",
        UDim2.fromScale(0, 0),
        UDim2.fromScale(1, 0.48),
        90
    )

    createEdge(
        "Bottom",
        UDim2.fromScale(0, 0.52),
        UDim2.fromScale(1, 0.48),
        270
    )

    local blur = Instance.new("BlurEffect")
    blur.Name = "MushVisionBlur"
    blur.Size = 0
    blur.Parent = Lighting

    local colorEffect = Instance.new("ColorCorrectionEffect")
    colorEffect.Name = "MushVisionColor"
    colorEffect.Brightness = 0
    colorEffect.Contrast = 0
    colorEffect.Saturation = 0
    colorEffect.Parent = Lighting

    local function applyVision(strength)
        strength = math.clamp(strength, 0, 1)

        darkness.BackgroundTransparency = 1 - strength * 0.27

        for _, edge in ipairs(edges) do
            edge.BackgroundTransparency = 1 - strength * 0.98
        end

        blur.Size = strength * 9
        colorEffect.Brightness = -strength * 0.12
        colorEffect.Contrast = strength * 0.18
        colorEffect.Saturation = -strength * 0.7
    end

    local function createPhantom()
        if not screenGui.Parent then
            return
        end

        local side = math.random(1, 2)
        local x

        if side == 1 then
            x = math.random(8, 38) / 100
        else
            x = math.random(62, 92) / 100
        end

        local y = math.random(25, 75) / 100

        local ghost = Instance.new("ImageLabel")
        ghost.Name = "Phantom"
        ghost.AnchorPoint = Vector2.new(0.5, 0.5)
        ghost.Position = UDim2.fromScale(x, y)
        ghost.Size = UDim2.fromOffset(
            math.random(130, 210),
            math.random(180, 280)
        )
        ghost.BackgroundTransparency = 1
        ghost.Image = phantomImages[
            math.random(1, #phantomImages)
        ]
        ghost.ImageTransparency = 1
        ghost.ImageColor3 = Color3.fromRGB(190, 195, 215)
        ghost.ScaleType = Enum.ScaleType.Fit
        ghost.ZIndex = 8
        ghost.Parent = screenGui

        local targetTransparency = math.random(35, 60) / 100

        local appearTween = TweenService:Create(
            ghost,
            TweenInfo.new(
                0.18,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.Out
            ),
            {
                ImageTransparency = targetTransparency
            }
        )

        appearTween:Play()

        local driftTween = TweenService:Create(
            ghost,
            TweenInfo.new(
                1.5,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.Out
            ),
            {
                Position = UDim2.fromScale(
                    x + math.random(-4, 4) / 100,
                    y - math.random(2, 6) / 100
                )
            }
        )

        driftTween:Play()

        task.spawn(function()
            task.wait(math.random(15, 35) / 100)

            if not ghost.Parent then
                return
            end

            for i = 1, math.random(1, 3) do
                ghost.ImageTransparency = math.min(
                    1,
                    targetTransparency + 0.35
                )

                task.wait(0.06)

                if not ghost.Parent then
                    return
                end

                ghost.ImageTransparency = targetTransparency

                task.wait(0.08)
            end

            task.wait(0.3)

            if ghost.Parent then
                local disappearTween = TweenService:Create(
                    ghost,
                    TweenInfo.new(
                        0.75,
                        Enum.EasingStyle.Sine,
                        Enum.EasingDirection.Out
                    ),
                    {
                        ImageTransparency = 1
                    }
                )

                disappearTween:Play()
                disappearTween.Completed:Wait()

                if ghost.Parent then
                    ghost:Destroy()
                end
            end
        end)
    end

    local function destroyEffects()
        if screenGui.Parent then
            screenGui:Destroy()
        end

        if blur.Parent then
            blur:Destroy()
        end

        if colorEffect.Parent then
            colorEffect:Destroy()
        end
    end

    return applyVision, createPhantom, destroyEffects
end

task.spawn(function()
    local currentRooms = workspace:WaitForChild("CurrentRooms")

    if workspace:FindFirstChild("SeekMovingNewClone")
        or currentRooms:FindFirstChild("50") then
        return
    end

    local latestRoom = ReplicatedStorage
        :WaitForChild("GameData")
        :WaitForChild("LatestRoom")

    local objects = game:GetObjects(MODEL_ID)
    local model = objects[1]

    if not model then
        return
    end

    local room = currentRooms:FindFirstChild(
        tostring(latestRoom.Value)
    )

    if not room then
        model:Destroy()
        return
    end

    local nodeFolder = room:FindFirstChild("Nodes")
        or room:FindFirstChild("PathfindNodes")

    local spawnPart

    if nodeFolder then
        local nodes = {}

        for _, node in ipairs(nodeFolder:GetChildren()) do
            if node:IsA("BasePart") then
                table.insert(nodes, node)
            end
        end

        table.sort(nodes, function(a, b)
            local na = tonumber(a.Name)
            local nb = tonumber(b.Name)

            if na and nb then
                return na < nb
            elseif na then
                return true
            elseif nb then
                return false
            end

            return a.Name < b.Name
        end)

        local middle = math.max(
            1,
            math.floor(#nodes / 2)
        )

        spawnPart = nodes[middle]
    end

    if not spawnPart then
        for _, name in ipairs({
            room.Name,
            "RoomEntrance",
            "RoomExit"
        }) do
            local candidate = room:FindFirstChild(name)

            if candidate and candidate:IsA("BasePart") then
                spawnPart = candidate
                break
            end
        end

        if not spawnPart then
            spawnPart = room.PrimaryPart
        end
    end

    if not spawnPart then
        model:Destroy()
        return
    end

    model.Parent = workspace

    model:PivotTo(
        spawnPart.CFrame + Vector3.new(0, SPAWN_HEIGHT, 0)
    )

    local mush = model:FindFirstChild("Mush", true)
    local lowFog = model:FindFirstChild("LowFog", true)
    local fog = lowFog and lowFog:FindFirstChild("Fog")

    if not mush or not mush:IsA("MeshPart") then
        warn("Mush MeshPart not found")
        model:Destroy()
        return
    end

    if not fog then
        warn("LowFog.Fog not found")
        model:Destroy()
        return
    end

    mush.Anchored = true

    local CameraShaker = require(
        ReplicatedStorage:WaitForChild("CameraShaker")
    )

    local shaker = CameraShaker.new(
        Enum.RenderPriority.Camera.Value,
        function(shakeCFrame)
            local camera = workspace.CurrentCamera

            if camera then
                camera.CFrame = camera.CFrame * shakeCFrame
            end
        end
    )

    task.wait(SPAWN_DELAY)

    local riseTween = TweenService:Create(
        mush,
        TweenInfo.new(
            RISE_DURATION,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out
        ),
        {
            CFrame = mush.CFrame
                + Vector3.new(0, RISE_HEIGHT, 0)
        }
    )

    shaker:Start()

    local shakeInstance = shaker:StartShake(
        SHAKE_MAGNITUDE,
        SHAKE_ROUGHNESS,
        0
    )

    playOneShot(MOVE_SOUND_ID, 0.8)

    riseTween:Play()

    task.delay(
        math.max(0, RISE_DURATION - SHAKE_FADE_TIME),
        function()
            if shakeInstance
                and riseTween.PlaybackState
                    == Enum.PlaybackState.Playing then

                shakeInstance:StartFadeOut(
                    SHAKE_FADE_TIME
                )
            end
        end
    )

    riseTween.Completed:Wait()

    shaker:Stop()

    task.wait(FOG_DELAY)

    local character = player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")

    local originalWalkSpeed = humanoid
        and humanoid.WalkSpeed or 16

    local applyVision, createPhantom, destroyEffects =
        createVisionEffects()

    local exitTriggered = false
    local damageApplied = false

    local recovering = false
    local recoveryStart = 0
    local recoveryFrom = 0

    local visionStrength = 0
    local effectStart = 0

    local ambientSound = nil
    local ambientFadeInTween = nil
    local renderConnection

    local function updateWalkSpeed(strength)
        if humanoid and humanoid.Parent
            and humanoid.Health > 0 then

            humanoid.WalkSpeed =
                originalWalkSpeed * (1 - SPEED_REDUCTION * strength)
        end
    end

    fog.Enabled = true

    effectStart = os.clock()

    task.delay(DARKNESS_DURATION, function()
        if not exitTriggered and not damageApplied then
            damageApplied = true

            if humanoid and humanoid.Parent
                and humanoid.Health > 0 then

                humanoid:TakeDamage(DAMAGE_AMOUNT)
            end
        end
    end)

    playOneShot(FOG_SOUND_ID, 1, function()
        if exitTriggered then
            return
        end

        ambientSound = Instance.new("Sound")
        ambientSound.SoundId = AMBIENT_SOUND_ID
        ambientSound.Volume = 0
        ambientSound.PlaybackSpeed = 1
        ambientSound.Looped = true
        ambientSound.Parent = SoundService

        ambientSound:Play()

        ambientFadeInTween = TweenService:Create(
            ambientSound,
            TweenInfo.new(
                MUSIC_FADE_IN,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.Out
            ),
            {
                Volume = 1
            }
        )

        ambientFadeInTween:Play()
    end)

    renderConnection = RunService.RenderStepped:Connect(function()
        if recovering then
            local elapsed = os.clock() - recoveryStart

            local progress = math.clamp(
                elapsed / RECOVERY_DURATION,
                0,
                1
            )

            local eased = smoothstep(progress)

            visionStrength = recoveryFrom * (1 - eased)

            applyVision(visionStrength)
            updateWalkSpeed(visionStrength)

            if progress >= 1 then
                applyVision(0)

                if humanoid and humanoid.Parent then
                    humanoid.WalkSpeed = originalWalkSpeed
                end

                renderConnection:Disconnect()
                destroyEffects()
            end

            return
        end

        local elapsed = os.clock() - effectStart

        local progress = math.clamp(
            elapsed / DARKNESS_DURATION,
            0,
            1
        )

        visionStrength = smoothstep(progress)

        applyVision(visionStrength)
        updateWalkSpeed(visionStrength)
    end)

    task.spawn(function()
        while not exitTriggered do
            local interval = 2.5 - visionStrength * 1.5

            task.wait(math.max(0.8, interval))

            if exitTriggered then
                break
            end

            if visionStrength >= 0.16 then
                createPhantom()

                if visionStrength >= 0.7
                    and math.random() < 0.35 then

                    task.delay(0.25, function()
                        if not exitTriggered then
                            createPhantom()
                        end
                    end)
                end
            end
        end
    end)

    latestRoom.Changed:Wait()

    exitTriggered = true

    recovering = true
    recoveryStart = os.clock()
    recoveryFrom = visionStrength

    if ambientFadeInTween then
        ambientFadeInTween:Cancel()
    end

    if ambientSound and ambientSound.Parent then
        fadeOutSound(ambientSound, MUSIC_FADE_OUT)
    end

    local descendTween = TweenService:Create(
        mush,
        TweenInfo.new(
            DESCEND_DURATION,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut
        ),
        {
            CFrame = mush.CFrame
                - Vector3.new(0, RISE_HEIGHT, 0)
        }
    )

    playOneShot(MOVE_SOUND_ID, 0.8)

    descendTween:Play()
    descendTween.Completed:Wait()

    fog.Enabled = false

    task.wait(DISAPPEAR_DELAY)

    local disappearInfo = TweenInfo.new(
        DISAPPEAR_DURATION,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.Out
    )

    local disappearTweens = {}

    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("BasePart")
            or object:IsA("Decal")
            or object:IsA("Texture") then

            local tween = TweenService:Create(
                object,
                disappearInfo,
                {
                    Transparency = 1
                }
            )

            table.insert(disappearTweens, tween)
        end
    end

    for _, tween in ipairs(disappearTweens) do
        tween:Play()
    end

    if #disappearTweens > 0 then
        disappearTweens[1].Completed:Wait()
    end

    model:Destroy()
end)
end

function entityBehaviors.Happy()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local CONFIG = {
    MODEL_ID = 72292591411637,
    END_SOUND_ID = "rbxassetid://127327591850649",
    HEIGHT_OFFSET = 0,
    SPAWN_SOUND_AT = 5,
    MOVE_AT = 10,
    START_SPEED = 500,
    BOUNCE_START_SPEED = 50,
    MAX_SPEED = 1000,
    ROUND_TRIPS = 30,
    DAMAGE = 125,
    DAMAGE_RANGE = 50,
    RAY_SAMPLE_STEP = 5,
    BLACKOUT_DURATION = 1,
    CEASE_SLOW_TIME = 2.25,
    CEASE_HOLD_TIME = 13,
    CEASE_RESUME_TIME = 2,
    END_SOUND_VOLUME = 1,
    SHAKE_RANGE = 80,
    SHAKE_INTERVAL = 0.12,
}

local EPSILON = 0.00001
local isServer = RunService:IsServer()
local monster = nil
local disposed = false
local spawnSound = nil
local modelDescendantConnection = nil
local proximityShaker = nil
local proximityShakeConnection = nil
local ceaseScale = 1
local ceaseActive = false
local ceaseStartedAt = 0
local ceaseEffects = {}
local ceaseConnection = nil
local handledCease = setmetatable({}, { __mode = "k" })
local damagedHumanoids = setmetatable({}, { __mode = "k" })

local function isAlive()
    return not disposed and monster ~= nil and monster.Parent ~= nil
end

local function stopProximityShake()
    if proximityShakeConnection then
        proximityShakeConnection:Disconnect()
        proximityShakeConnection = nil
    end
    if proximityShaker then
        local shaker = proximityShaker
        proximityShaker = nil
        pcall(function()
            shaker:Stop()
        end)
    end
end

local function startProximityShake()
    if isServer or proximityShaker or not isAlive() then
        return
    end

    local module = game:GetService("ReplicatedStorage"):FindFirstChild("CameraShaker")
    if not module then
        return
    end

    local loaded, CameraShakerModule = pcall(require, module)
    if not loaded or not isAlive() then
        return
    end

    local started = pcall(function()
        proximityShaker = CameraShakerModule.new(
            Enum.RenderPriority.Camera.Value + 1,
            function(shakerTransform)
                local camera = workspace.CurrentCamera
                if camera then
                    camera.CFrame = camera.CFrame * shakerTransform
                end
            end
        )
        proximityShaker:Start()
    end)
    if not started or not isAlive() then
        stopProximityShake()
        return
    end

    local lastProximityShake = 0
    proximityShakeConnection = RunService.RenderStepped:Connect(function()
        if not isAlive() then
            stopProximityShake()
            return
        end

        local player = Players.LocalPlayer
        local character = player and player.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart") then
            return
        end

        local distance = (monster:GetPivot().Position - rootPart.Position).Magnitude
        local now = os.clock()
        if distance > CONFIG.SHAKE_RANGE or now - lastProximityShake < CONFIG.SHAKE_INTERVAL then
            return
        end

        local alpha = math.clamp(1 - distance / CONFIG.SHAKE_RANGE, 0, 1)
        local amplitude = (0.3 + 8.2 * (alpha ^ 1.35)) * 3
        local roughness = 45 + 35 * alpha
        local positionInfluence = 0.35 + 0.4 * alpha
        local rotationInfluence = 0.3 + 0.4 * alpha

        lastProximityShake = now
        local shaken = pcall(function()
            proximityShaker:ShakeOnce(
                amplitude,
                roughness,
                0.01,
                0.16,
                positionInfluence,
                rotationInfluence
            )
        end)
        if not shaken then
            stopProximityShake()
        end
    end)
end

local function darkenRoomLights()
    local rooms = workspace:FindFirstChild("CurrentRooms")
    if not rooms then
        return
    end

    local states = {}
    local fixtureNames = {
        Chandelier = true,
        Light_Fixtures = true,
        LoadedChandelier_New = true,
    }

    for _, room in ipairs(rooms:GetChildren()) do
        local assets = room:IsA("Model") and room:FindFirstChild("Assets")
        if assets then
            for _, fixture in ipairs(assets:GetChildren()) do
                if fixtureNames[fixture.Name] then
                    for _, object in ipairs(fixture:GetDescendants()) do
                        if object:IsA("Light") then
                            table.insert(states, {
                                Object = object, Kind = "Light",
                                Color = object.Color, Brightness = object.Brightness,
                            })
                        elseif object:IsA("Beam") then
                            table.insert(states, {
                                Object = object, Kind = "Beam", Color = object.Color,
                            })
                        elseif object:IsA("BasePart") and (
                            object.Name == "Neon"
                            or object.Name == "Ok you cannot tell me this isnt good"
                        ) then
                            table.insert(states, {
                                Object = object, Kind = "Part", Color = object.Color,
                            })
                        end
                    end
                end
            end
        end
    end

    task.spawn(function()
        local startedAt = os.clock()
        local black = Color3.new(0, 0, 0)
        while true do
            local alpha = math.clamp(
                (os.clock() - startedAt) / CONFIG.BLACKOUT_DURATION, 0, 1
            )
            for _, state in ipairs(states) do
                local object = state.Object
                if object.Parent then
                    if state.Kind == "Beam" then
                        local points = {}
                        for _, keypoint in ipairs(state.Color.Keypoints) do
                            table.insert(points, ColorSequenceKeypoint.new(
                                keypoint.Time, keypoint.Value:Lerp(black, alpha)
                            ))
                        end
                        object.Color = ColorSequence.new(points)
                    else
                        object.Color = state.Color:Lerp(black, alpha)
                        if state.Kind == "Light" then
                            object.Brightness = state.Brightness * (1 - alpha)
                        end
                    end
                end
            end
            if alpha >= 1 then
                return
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

local function getOrderedRooms()
    local rooms = workspace:FindFirstChild("CurrentRooms")
    assert(rooms, "找不到 workspace.CurrentRooms")
    local result = {}
    for _, room in ipairs(rooms:GetChildren()) do
        local number = tonumber(room.Name)
        if room:IsA("Model") and number then
            table.insert(result, { Number = number, Room = room })
        end
    end
    table.sort(result, function(a, b)
        return a.Number < b.Number
    end)
    return result
end

local function getOrderedNodes(folder)
    local nodes = {}
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(nodes, child)
            end
        end
    end
    table.sort(nodes, function(a, b)
        local numberA, numberB = tonumber(a.Name), tonumber(b.Name)
        if numberA and numberB and numberA ~= numberB then
            return numberA < numberB
        elseif numberA and not numberB then
            return true
        elseif numberB and not numberA then
            return false
        end
        return a.Name < b.Name
    end)
    return nodes
end

local function captureRoute()
    local rooms = getOrderedRooms()
    assert(#rooms > 0, "CurrentRooms 内没有数字命名的房间")

    local startIndex = #rooms > 10 and (#rooms - 8) or 1
    local endIndex = math.max(1, #rooms - 1)
    local route = {}
    local rayExclusions = {}
    local heightOffset = Vector3.new(0, CONFIG.HEIGHT_OFFSET, 0)

    for index = startIndex, endIndex do
        local room = rooms[index].Room
        local folder = room:FindFirstChild("PathfindNodes")
        local nodes = getOrderedNodes(folder)
        if folder then
            table.insert(rayExclusions, folder)
        end
        if #nodes == 0 then
            local exit = room:FindFirstChild("RoomExit")
            assert(exit and exit:IsA("BasePart"),
                "房间 " .. room.Name .. " 缺少 PathfindNodes 和 RoomExit")
            nodes = { exit }
            table.insert(rayExclusions, exit)
        end
        for _, node in ipairs(nodes) do
            local target = node.CFrame + heightOffset
            local previous = route[#route]

            if previous and (previous.Position - target.Position).Magnitude <= EPSILON then
                route[#route] = target
            else
                table.insert(route, target)
            end
        end
    end

    assert(#route >= 2, "至少需要两个不同位置的路径点，才能执行终点往返")

    return route, rayExclusions
end

local function loadWholeModel()
    local objects
    if isServer then
        objects = { game:GetService("AssetService"):LoadAssetAsync(CONFIG.MODEL_ID) }
    else
        objects = game:GetObjects("rbxassetid://" .. tostring(CONFIG.MODEL_ID))
    end

    assert(objects and #objects > 0, "模型资源为空")
    local pivotSource = nil
    if #objects == 1 and objects[1]:IsA("Model") then
        monster = objects[1]
        local children = monster:GetChildren()
        if isServer and #children == 1 and children[1]:IsA("Model") then
            pivotSource = children[1]
        end
    else
        monster = Instance.new("Model")
        for _, object in ipairs(objects) do
            if not pivotSource and object:IsA("Model") then
                pivotSource = object
            end
            object.Parent = monster
        end
    end

    monster.Name = "Happy"
    assert(monster:FindFirstChildWhichIsA("BasePart", true), "怪物模型内没有 BasePart")
    if pivotSource and not monster.PrimaryPart then
        if pivotSource.PrimaryPart then
            monster.PrimaryPart = pivotSource.PrimaryPart
        else
            monster.WorldPivot = pivotSource:GetPivot()
        end
    end

    local function prepareObject(object)
        if object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
        elseif object:IsA("Sound") and object.Name == "Spwan" and not spawnSound then
            spawnSound = object
            object:Stop()
            object.Looped = false
            object.TimePosition = 0
        end
    end
    modelDescendantConnection = monster.DescendantAdded:Connect(prepareObject)
    for _, object in ipairs(monster:GetDescendants()) do
        prepareObject(object)
    end
end

local function applyEffectScale(object, saved, scale)
    if not object.Parent then
        return
    end
    if saved.Kind == "Particle" then
        object.TimeScale = saved.TimeScale * scale
    else
        object.Volume = saved.Volume * scale
        if scale <= EPSILON then

            if object.IsPlaying then
                saved.PausedByCease = true
                object:Pause()
            end
        else
            object.PlaybackSpeed = math.max(0.01, saved.PlaybackSpeed * scale)
            if saved.PausedByCease then
                saved.PausedByCease = false
                object:Resume()
            end
        end
    end
end

local function trackCeaseEffect(object)
    if ceaseEffects[object] then
        return
    end
    if object:IsA("ParticleEmitter") then
        ceaseEffects[object] = { Kind = "Particle", TimeScale = object.TimeScale }
    elseif object:IsA("Sound") then
        ceaseEffects[object] = {
            Kind = "Sound", Volume = object.Volume,
            PlaybackSpeed = object.PlaybackSpeed, PausedByCease = false,
        }
    end
    if ceaseEffects[object] then
        applyEffectScale(object, ceaseEffects[object], ceaseScale)
    end
end

local function cancelCeaseFreeze()
    if ceaseConnection then
        ceaseConnection:Disconnect()
        ceaseConnection = nil
    end
    for object, saved in pairs(ceaseEffects) do
        if object.Parent then
            applyEffectScale(object, saved, 1)
            if saved.Kind == "Sound" then
                object.PlaybackSpeed = saved.PlaybackSpeed
            end
        end
    end
    ceaseEffects = {}
    ceaseScale = 1
    ceaseActive = false
end

local function easeCease(alpha)
    alpha = math.clamp(alpha, 0, 1)
    return alpha * alpha * (3 - 2 * alpha)
end

local function updateCeaseFreeze(canStart)
    if not ceaseActive and canStart then
        local cease = workspace:FindFirstChild("Cease", true)
        if cease and cease:IsA("Model") and not handledCease[cease] then
            handledCease[cease] = true
            ceaseActive = true
            ceaseStartedAt = os.clock()
            for _, object in ipairs(monster:GetDescendants()) do
                trackCeaseEffect(object)
            end
            ceaseConnection = monster.DescendantAdded:Connect(trackCeaseEffect)
        end
    end

    if not ceaseActive then
        return
    end
    local elapsed = os.clock() - ceaseStartedAt
    local slowEnd = CONFIG.CEASE_SLOW_TIME
    local holdEnd = slowEnd + CONFIG.CEASE_HOLD_TIME
    local resumeEnd = holdEnd + CONFIG.CEASE_RESUME_TIME
    if elapsed < slowEnd then
        ceaseScale = 1 - easeCease(elapsed / CONFIG.CEASE_SLOW_TIME)
    elseif elapsed < holdEnd then
        ceaseScale = 0
    elseif elapsed < resumeEnd then
        ceaseScale = easeCease((elapsed - holdEnd) / CONFIG.CEASE_RESUME_TIME)
    else
        cancelCeaseFreeze()
        return
    end
    for object, saved in pairs(ceaseEffects) do
        applyEffectScale(object, saved, ceaseScale)
    end
end

local function rayEntryDistanceToPart(origin, directionUnit, part)
    local localOrigin = part.CFrame:PointToObjectSpace(origin)
    local localDirection = part.CFrame:VectorToObjectSpace(directionUnit)
    local half = part.Size * 0.5
    local entry, exit = 0, math.huge
    for _, axis in ipairs({ "X", "Y", "Z" }) do
        local position, velocity, extent = localOrigin[axis], localDirection[axis], half[axis]
        if math.abs(velocity) < EPSILON then
            if position < -extent or position > extent then
                return nil
            end
        else
            local near = (-extent - position) / velocity
            local far = (extent - position) / velocity
            if near > far then
                near, far = far, near
            end
            entry = math.max(entry, near)
            exit = math.min(exit, far)
            if exit < entry then
                return nil
            end
        end
    end
    return entry
end

local function collectDamageTargets()
    local targets = {}
    local players = isServer and Players:GetPlayers() or { Players.LocalPlayer }
    for _, player in ipairs(players) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and root and root:IsA("BasePart") and humanoid.Health > 0
            and not damagedHumanoids[humanoid] and not character:GetAttribute("Hiding") then
            local parts = { root }
            for _, name in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso" }) do
                local part = character:FindFirstChild(name)
                if part and part:IsA("BasePart") then
                    table.insert(parts, part)
                end
            end
            table.insert(targets, {
                Character = character, Humanoid = humanoid, Root = root, Parts = parts,
            })
        end
    end
    return targets
end

local function damageFrom(origin, targets, rayParams)
    for _, target in ipairs(targets) do
        local humanoid, character = target.Humanoid, target.Character
        if humanoid.Parent and humanoid.Health > 0 and target.Root.Parent
            and not damagedHumanoids[humanoid] and not character:GetAttribute("Hiding")
            and (target.Root.Position - origin).Magnitude <= CONFIG.DAMAGE_RANGE then
            for _, part in ipairs(target.Parts) do
                if part.Parent then
                    local direction = part.Position - origin
                    local distance = direction.Magnitude
                    local visible = distance <= EPSILON
                    if distance > EPSILON and distance <= CONFIG.DAMAGE_RANGE then
                        local result = workspace:Raycast(origin, direction, rayParams)
                        visible = result ~= nil and result.Instance:IsDescendantOf(character)
                        if not visible then
                            local entry = rayEntryDistanceToPart(origin, direction.Unit, part)
                            visible = entry ~= nil and entry <= distance + 0.01
                                and (not result or result.Distance > entry + 0.02)
                        end
                    end
                    if visible then
                        damagedHumanoids[humanoid] = true
                        humanoid:TakeDamage(CONFIG.DAMAGE)
                        break
                    end
                end
            end
        end
    end
end

local function scanTravel(fromPosition, toPosition, targets, rayParams)
    local distance = (toPosition - fromPosition).Magnitude
    local samples = math.max(1, math.ceil(distance / CONFIG.RAY_SAMPLE_STEP))
    for index = 0, samples do
        damageFrom(fromPosition:Lerp(toPosition, index / samples), targets, rayParams)
    end
end

local function buildSegments(route)
    local segments = {}
    for index = 2, #route do
        table.insert(segments, { Target = route[index], Speed = CONFIG.START_SPEED })
    end

    local previousPoint, finalPoint = route[#route - 1], route[#route]
    local totalLegs = CONFIG.ROUND_TRIPS * 2
    for leg = 1, totalLegs do
        local alpha = totalLegs > 1 and ((leg - 1) / (totalLegs - 1)) or 0
        table.insert(segments, {
            Target = leg % 2 == 1 and previousPoint or finalPoint,
            Speed = CONFIG.BOUNCE_START_SPEED + (CONFIG.MAX_SPEED - CONFIG.BOUNCE_START_SPEED) * alpha,
        })
    end
    return segments
end

local function runMovement(route, rayExclusions)
    local segments = buildSegments(route)
    local segmentIndex = 1
    table.insert(rayExclusions, monster)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = rayExclusions

    while isAlive() and segmentIndex <= #segments do
        local deltaTime = RunService.Heartbeat:Wait()
        if not isAlive() then
            break
        end
        updateCeaseFreeze(segmentIndex <= #segments)
        local targets = collectDamageTargets()
        local timeLeft = deltaTime

        damageFrom(monster:GetPivot().Position, targets, rayParams)
        while timeLeft > EPSILON and ceaseScale > EPSILON and segmentIndex <= #segments do
            local segment = segments[segmentIndex]
            local from = monster:GetPivot()
            local distance = (segment.Target.Position - from.Position).Magnitude
            if distance <= EPSILON then
                monster:PivotTo(segment.Target)
                segmentIndex = segmentIndex + 1
            else
                local speed = segment.Speed * ceaseScale
                local travel = math.min(distance, speed * timeLeft)
                local destination = from:Lerp(segment.Target, travel / distance)
                scanTravel(from.Position, destination.Position, targets, rayParams)
                monster:PivotTo(destination)
                timeLeft = math.max(0, timeLeft - travel / speed)
                if travel >= distance then
                    segmentIndex = segmentIndex + 1
                end
            end
        end

    end
    return isAlive() and segmentIndex > #segments
end

local function waitUntil(spawnedAt, seconds)
    while isAlive() and os.clock() - spawnedAt < seconds do
        RunService.Heartbeat:Wait()
    end
    return isAlive()
end

local function playFinalSound()
    local sound = Instance.new("Sound")
    sound.Name = "HappyFinalSound"
    sound.SoundId = CONFIG.END_SOUND_ID
    sound.Volume = CONFIG.END_SOUND_VOLUME
    sound.Looped = false
    sound.PlayOnRemove = false

    sound.Parent = SoundService
    sound.Ended:Once(function()
        sound:Destroy()
    end)
    sound:Play()

    task.delay(30, function()
        if sound.Parent and not sound.IsLoaded then
            sound:Destroy()
        end
    end)
end

local function cleanup()
    disposed = true
    stopProximityShake()
    if modelDescendantConnection then
        modelDescendantConnection:Disconnect()
        modelDescendantConnection = nil
    end
    cancelCeaseFreeze()
    if monster then
        monster:Destroy()
        monster = nil
    end
end

local function run()
    loadWholeModel()
    local route, rayExclusions = captureRoute()
    monster:PivotTo(route[1])
    monster.Parent = workspace
    local spawnedAt = os.clock()
    darkenRoomLights()
    task.spawn(startProximityShake)

    task.spawn(function()
        local assets = { CONFIG.END_SOUND_ID }
        for _, object in ipairs(monster:GetDescendants()) do
            if object:IsA("Sound") then
                table.insert(assets, object)
            end
        end

        pcall(function()
            ContentProvider:PreloadAsync(assets)
        end)
    end)

    if not waitUntil(spawnedAt, CONFIG.SPAWN_SOUND_AT) then
        return
    end
    if spawnSound and spawnSound.Parent then
        spawnSound.Looped = false
        spawnSound.TimePosition = 0
        spawnSound.Playing = true
    end
    if not waitUntil(spawnedAt, CONFIG.MOVE_AT) then
        return
    end

    if runMovement(route, rayExclusions) then
        cleanup()
        playFinalSound()
    end
end

pcall(run)
if not disposed then
    cleanup()
end
end
function entityBehaviors.Z19()
loadstring(game:HttpGet("https://raw.githubusercontent.com/idkman60093/Custom-Entity/refs/heads/main/Questioner-Entity"))()
end

function entityBehaviors.Bear()
local neededFiles = {}
for i = 1, 20 do
    local n = string.format("%03d", i)
    table.insert(neededFiles, "Fredscare/ezgif-frame-" .. n .. ".png")
end
table.insert(neededFiles, "Fredbear.rbxmx")

local cleanupSteps = {}
local cleaned = false

local function registerCleanup(callback)
    if cleaned then
        pcall(callback)
    else
        table.insert(cleanupSteps, callback)
    end
end

local function own(instance)
    if instance then
        registerCleanup(function() instance:Destroy() end)
    end
    return instance
end

local function trackConnection(connection)
    registerCleanup(function() connection:Disconnect() end)
    return connection
end

local function cleanup()
    if cleaned then return end
    cleaned = true
    for i = #cleanupSteps, 1, -1 do
        pcall(cleanupSteps[i])
    end
    if type(delfile) == "function" and type(isfile) == "function" then
        for _, path in ipairs(neededFiles) do
            pcall(function()
                if isfile(path) then delfile(path) end
            end)
        end
    end
end

local function ensureFredbearFiles()

    local hasFiles = true
    for _, file in ipairs(neededFiles) do
        if not isfile(file) then
            hasFiles = false
            break
        end
    end
    if hasFiles then return end

    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    if cleaned then return end
    local screenGui = own(Instance.new("ScreenGui"))
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.Parent = screenGui

    local loadingText = Instance.new("TextLabel")
    loadingText.Size = UDim2.new(1, 0, 0, 50)
    loadingText.Position = UDim2.new(0, 0, 0.3, 0)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "Loading..."
    loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadingText.TextScaled = true
    loadingText.Parent = frame

    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, 0, 0, 30)
    infoText.Position = UDim2.new(0, 0, 0.48, 0)
    infoText.BackgroundTransparency = 1
    infoText.Text = "Loading assets..."
    infoText.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoText.TextScaled = true
    infoText.Parent = frame

    local barBackground = Instance.new("Frame")
    barBackground.AnchorPoint = Vector2.new(0.5, 0.5)
    barBackground.Position = UDim2.new(0.5, 0, 0.8, 0)
    barBackground.Size = UDim2.new(0.6, 0, 0.05, 0)
    barBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    barBackground.Parent = frame

    local backgroundCorner = Instance.new("UICorner")
    backgroundCorner.CornerRadius = UDim.new(0, 12)
    backgroundCorner.Parent = barBackground

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(255, 230, 0)
    bar.Parent = barBackground

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 12)
    barCorner.Parent = bar

    if not isfolder("Fredscare") then makefolder("Fredscare") end
    local total, count = 21, 0
    local function updateBar()
        bar.Size = UDim2.new(count / total, 0, 1, 0)
    end
    for i = 1, 20 do
        local n = string.format("%03d", i)
        local path = "Fredscare/ezgif-frame-" .. n .. ".png"
        if cleaned then return end
        if not isfile(path) then
            local content = game:HttpGet("https://raw.githubusercontent.com/ian49972/IMAGES/refs/heads/main/ezgif-frame-" .. n .. ".png")
            if cleaned then return end
            writefile(path, content)
            if cleaned then
                if type(delfile) == "function" then pcall(delfile, path) end
                return
            end
        end
        count = count + 1
        updateBar()
    end
    if cleaned then return end
    if not isfile("Fredbear.rbxmx") then
        local content = game:HttpGet("https://raw.githubusercontent.com/ian49972/RBXMS/refs/heads/main/Fredbear.rbxmx")
        if cleaned then return end
        writefile("Fredbear.rbxmx", content)
        if cleaned then
            if type(delfile) == "function" then pcall(delfile, "Fredbear.rbxmx") end
            return
        end
    end
    count = count + 1
    updateBar()
    screenGui:Destroy()
end

local function runFredbear()
ensureFredbearFiles()
if cleaned then return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
if cleaned then return end

local NPC = own(game:GetObjects(getcustomasset("Fredbear.rbxmx"))[1])
if cleaned or not NPC then return end
local Fredbear = NPC:WaitForChild("Fredbear", 30)
local KeyframesFolder = NPC:WaitForChild("Keyframes", 30)
if cleaned or not Fredbear or not KeyframesFolder then return end
local RunKeyframe = KeyframesFolder:WaitForChild("Run", 30)
local WalkKeyframe = KeyframesFolder:WaitForChild("Walk", 30)
local LookAroundKeyframe = KeyframesFolder:WaitForChild("LookAround", 30)

local humanoid = Fredbear:WaitForChild("Humanoid", 30)
local rootPart = Fredbear.PrimaryPart
if cleaned or not RunKeyframe or not WalkKeyframe or not LookAroundKeyframe or not humanoid or not rootPart then return end

local EasingStyleMap = {
	[Enum.PoseEasingStyle.Linear]   = Enum.EasingStyle.Linear,
	[Enum.PoseEasingStyle.Bounce]   = Enum.EasingStyle.Bounce,
	[Enum.PoseEasingStyle.Cubic]    = Enum.EasingStyle.Cubic,
	[Enum.PoseEasingStyle.Elastic]  = Enum.EasingStyle.Elastic,
	[Enum.PoseEasingStyle.Constant] = Enum.EasingStyle.Linear,
}

local EasingDirectionMap = {
	[Enum.PoseEasingDirection.In]    = Enum.EasingDirection.In,
	[Enum.PoseEasingDirection.Out]   = Enum.EasingDirection.Out,
	[Enum.PoseEasingDirection.InOut] = Enum.EasingDirection.InOut,
}

local currentAnim = nil
local wanderThread = nil
local chaseThread = nil
local distractThread = nil
local footstepThread = nil

local Chase_Speed = 15
humanoid.WalkSpeed = Chase_Speed

local footstepSound = own(Instance.new("Sound"))
footstepSound.SoundId = "rbxassetid://107928272700538"
footstepSound.Volume = 0.8
footstepSound.Parent = rootPart

local function PlayKeyframeSequence(Model, KeyframeSequence, SpeedMult)
	SpeedMult = SpeedMult or 1
	if currentAnim and currentAnim.Stop then currentAnim:Stop() end

	local keyframes = {}
	for _, kf in ipairs(KeyframeSequence:GetKeyframes()) do
		table.insert(keyframes, {Time = kf.Time, KF = kf})
	end
	table.sort(keyframes, function(a,b) return a.Time < b.Time end)
	if #keyframes == 0 then return end

	local motorMap = {}
	local boneMap = {}
	local valueMap = {}
	local tweenList = {}

	local function ResolveInstance(pose)
		local name = pose.Name
		if motorMap[name] then return motorMap[name], "Motor6D" end
		if boneMap[name] then return boneMap[name], "Bone" end
		for _, motor in ipairs(Model:GetDescendants()) do
			if motor:IsA("Motor6D") and motor.Part1 and motor.Part0 then
				if motor.Part1.Name == name and motor.Part0.Name == pose.Parent.Name then
					motorMap[name] = motor
					return motor, "Motor6D"
				end
			end
		end
		for _, bone in ipairs(Model:GetDescendants()) do
			if bone:IsA("Bone") and bone.Name == name and bone.Parent and bone.Parent.Name == pose.Parent.Name then
				boneMap[name] = bone
				return bone, "Bone"
			end
		end
		return nil, nil
	end

	local poseTables = {}
	for i, entry in ipairs(keyframes) do
		local tab = {Time = entry.Time, Poses = {}}
		for _, pose in ipairs(entry.KF:GetDescendants()) do
			if pose:IsA("Pose") and pose.Weight > 0 then
				local instance, typ = ResolveInstance(pose)
				if instance then
					if not valueMap[pose.Name] then
						local val = Instance.new("CFrameValue")
						val.Name = "AnimValue"
						val.Parent = instance
						valueMap[pose.Name] = val
					end
					tab.Poses[pose.Name] = {
						Instance = instance,
						Type = typ,
						CFrame = pose.CFrame,
						Style = pose.EasingStyle,
						Dir = pose.EasingDirection,
					}
				end
			end
		end
		poseTables[i] = tab
	end

	for i = 1, #poseTables-1 do
		local kf1 = poseTables[i]
		local kf2 = poseTables[i+1]
		local duration = (kf2.Time - kf1.Time) / SpeedMult
		local group = {Duration = duration, Tweens = {}}
		for name, data2 in pairs(kf2.Poses) do
			local data1 = kf1.Poses[name] or poseTables[1].Poses[name]
			if data1 then
				local ti = TweenInfo.new(
					duration,
					EasingStyleMap[data2.Style] or Enum.EasingStyle.Linear,
					EasingDirectionMap[data2.Dir] or Enum.EasingDirection.InOut
				)
				local tween = TweenService:Create(valueMap[name], ti, {Value = data2.CFrame})
				group.Tweens[name] = tween
			end
		end
		table.insert(tweenList, group)
	end

	local heartbeatConn
	local playing = true
	heartbeatConn = trackConnection(RunService.Heartbeat:Connect(function()
		for name, valObj in pairs(valueMap) do
			local cf = valObj.Value
			local entry = poseTables[1].Poses[name]
			if entry then
				entry.Instance.Transform = cf
			end
		end
	end))

	local function PlayOnce()
		for _, group in ipairs(tweenList) do
			if not playing then break end
			for _, tween in pairs(group.Tweens) do
				tween:Play()
			end
			task.wait(group.Duration)
		end
	end

	task.spawn(function()
		while playing and Model and Model.Parent do
			PlayOnce()
			task.wait()
		end
	end)

	local animLength = poseTables[#poseTables].Time / SpeedMult
	currentAnim = {
		Stop = function()
			playing = false
			if heartbeatConn then heartbeatConn:Disconnect() end
			for _, group in ipairs(tweenList) do
				for _, tween in pairs(group.Tweens) do
					tween:Cancel()
				end
			end
			for _, v in pairs(valueMap) do
				v:Destroy()
			end
		end,
		Length = animLength,
		KeyframeSequence = KeyframeSequence
	}
	return currentAnim
end

local jumpscareSound = own(Instance.new("Sound"))
jumpscareSound.SoundId = "rbxassetid://85349172482807"
jumpscareSound.Volume = 2
jumpscareSound.Parent = workspace

local hitbox = own(Instance.new("Part"))
hitbox.Size = Vector3.new(8, 6, 12)
hitbox.Transparency = 1
hitbox.CanCollide = false
hitbox.Anchored = true
hitbox.Parent = workspace

local jumpscareGui = own(Instance.new("ScreenGui"))
jumpscareGui.Name = "FredbearJumpscare"
jumpscareGui.IgnoreGuiInset = true
jumpscareGui.ResetOnSpawn = false
jumpscareGui.Enabled = false
jumpscareGui.Parent = playerGui

local frameCount = 20
local frameSpeed = 0.07
local frames = {}
for i = 1, frameCount do
	local num = string.format("%03d", i)
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1,1)
	img.BackgroundTransparency = 1
	local imageAsset = getcustomasset("Fredscare/ezgif-frame-"..num..".png")
	if cleaned then img:Destroy() return end
	img.Image = imageAsset
	img.Visible = false
	img.Parent = jumpscareGui
	frames[i] = img
end

local jumpscareVersion = 0
local jumpscareFadeTween = nil

local function resetJumpscare()
    jumpscareVersion = jumpscareVersion + 1
    if jumpscareFadeTween then
        local tween = jumpscareFadeTween
        jumpscareFadeTween = nil
        tween:Cancel()
    end
    jumpscareGui.Enabled = false
    for _, frame in ipairs(frames) do
        frame.Visible = false
        frame.ImageTransparency = 0
    end
end

registerCleanup(resetJumpscare)

local function playJumpscareFrames()
    resetJumpscare()
    local version = jumpscareVersion
    jumpscareGui.Enabled = true
    task.spawn(function()
        for i = 1, frameCount do
            if version ~= jumpscareVersion then return end
            for _, frame in ipairs(frames) do frame.Visible = false end
            frames[i].Visible = true
            task.wait(frameSpeed)
        end
        if version ~= jumpscareVersion then return end
        local tween = TweenService:Create(
            frames[frameCount],
            TweenInfo.new(0.5, Enum.EasingStyle.Linear),
            {ImageTransparency = 1}
        )
        jumpscareFadeTween = tween
        tween:Play()
        tween.Completed:Wait()
        if version == jumpscareVersion then
            resetJumpscare()
        end
    end)
end

local currentConnection = nil
local currentPath = nil
local isChasing = false
local isDistracted = false
local canKill = true

registerCleanup(function()
    isChasing = false
    local function cancelThread(thread)
        if thread and thread ~= coroutine.running() then pcall(task.cancel, thread) end
    end
    cancelThread(wanderThread)
    cancelThread(chaseThread)
    cancelThread(distractThread)
    cancelThread(footstepThread)
    if currentAnim and currentAnim.Stop then pcall(function() currentAnim:Stop() end) end
    if currentPath then pcall(function() currentPath:Destroy() end) end
end)

local targetPlayer = nil
local targetCharacter = nil
local targetHumanoid = nil
local targetScanPending = false

local function chooseNearestLivingPlayer()
    local nearestPlayer, nearestCharacter, nearestHumanoid = nil, nil, nil
    local nearestDistance = math.huge
    local candidates = Players:GetPlayers()
    for _, candidate in ipairs(candidates) do
        local character = candidate.Character
        local candidateHumanoid = character and character:FindFirstChildOfClass("Humanoid")
        local candidateRoot = character and character:FindFirstChild("HumanoidRootPart")
        if candidateHumanoid and candidateHumanoid.Health > 0 and candidateRoot then
            local distance = (candidateRoot.Position - rootPart.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer, nearestCharacter, nearestHumanoid = candidate, character, candidateHumanoid
            end
        end
    end
    targetPlayer, targetCharacter, targetHumanoid = nearestPlayer, nearestCharacter, nearestHumanoid
    if targetPlayer then
        canKill = true
    end
end

local function watchPlayer(candidate)
    local function characterReady(character)
        task.spawn(function()
            local candidateHumanoid = character:WaitForChild("Humanoid", 20)
            local candidateRoot = character:WaitForChild("HumanoidRootPart", 20)
            if not cleaned and candidate.Character == character and candidateHumanoid and candidateRoot
                and candidateHumanoid.Health > 0 and not targetPlayer then
                targetScanPending = true
            end
        end)
    end
    trackConnection(candidate.CharacterAdded:Connect(characterReady))
    if candidate.Character then characterReady(candidate.Character) end
end

local function beginTargetMonitoring()
    for _, candidate in ipairs(Players:GetPlayers()) do watchPlayer(candidate) end
    trackConnection(Players.PlayerAdded:Connect(watchPlayer))
    targetScanPending = true
    trackConnection(RunService.Heartbeat:Connect(function()
        if cleaned then return end
        if targetPlayer and (targetPlayer.Parent ~= Players
            or targetPlayer.Character ~= targetCharacter
            or not targetHumanoid.Parent or targetHumanoid.Health <= 0) then
            targetPlayer, targetCharacter, targetHumanoid = nil, nil, nil
            targetScanPending = true
        end
        if targetScanPending then
            targetScanPending = false
            if not targetPlayer then chooseNearestLivingPlayer() end
        end
    end))
end

local function followPath(targetPos)
	if currentPath then currentPath:Destroy() end
	currentPath = PathfindingService:CreatePath({AgentRadius = 5, AgentHeight = 7, AgentCanJump = true, AgentMaxSlope = 50, WaypointSpacing = 4, Costs = {Water = 20}})
	local success = pcall(function() currentPath:ComputeAsync(rootPart.Position, targetPos) end)
	if not success or currentPath.Status ~= Enum.PathStatus.Success then return false end
	for _, waypoint in ipairs(currentPath:GetWaypoints()) do
		if not (isChasing or isDistracted or wanderThread) then break end
		if waypoint.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
		humanoid:MoveTo(waypoint.Position)
		humanoid.MoveToFinished:Wait(3)
	end
	return true
end

local function getSafeWanderPos()
	local rayOrigin = rootPart.Position + Vector3.new(0, 50, 0)
	local rayDirection = Vector3.new(0, -100, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {Fredbear}
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	local y = result and result.Position.Y + 5 or rootPart.Position.Y + 5
	local pos = rootPart.Position + Vector3.new(math.random(-45,45), 0, math.random(-45,45))
	return Vector3.new(pos.X, y, pos.Z)
end

local function startFootstepLoop(interval)
	if footstepThread then task.cancel(footstepThread) end
	footstepThread = task.spawn(function()
		while not cleaned and rootPart.Parent do
			footstepSound.TimePosition = 0
			footstepSound:Play()
			task.wait(interval)
		end
	end)
end

local function stopFootstepLoop()
	if footstepThread then
		task.cancel(footstepThread)
		footstepThread = nil
	end
end

local function updateFootstepLoop()
	if not currentAnim or not currentAnim.KeyframeSequence then
		stopFootstepLoop()
		return
	end
	if currentAnim.KeyframeSequence == WalkKeyframe then
		startFootstepLoop(0.6)
	elseif currentAnim.KeyframeSequence == RunKeyframe then
		startFootstepLoop(0.1)
	else
		stopFootstepLoop()
	end
end

local function startWandering()
	if wanderThread then task.cancel(wanderThread) end
	PlayKeyframeSequence(Fredbear, WalkKeyframe, 1.0)
	humanoid.WalkSpeed = Chase_Speed
	updateFootstepLoop()

	wanderThread = task.spawn(function()
		while not isChasing and not isDistracted do
			local pos = getSafeWanderPos()
			followPath(pos)
			task.wait(0.1)
		end
	end)
end

local function startChasing()
    if chaseThread then task.cancel(chaseThread) end
    if wanderThread then task.cancel(wanderThread) wanderThread = nil end
    PlayKeyframeSequence(Fredbear, RunKeyframe, 1.4)
    humanoid.WalkSpeed = Chase_Speed
    updateFootstepLoop()

    chaseThread = task.spawn(function()
        while isChasing and not cleaned and rootPart.Parent do
            local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                humanoid:MoveTo(targetRoot.Position)
            end
            task.wait(0.1)
        end
    end)
end

local function killPlayer()
    if not canKill or targetPlayer ~= player or not targetHumanoid or targetHumanoid.Health <= 0 then return end
    canKill = false
    jumpscareSound:Play()
    playJumpscareFrames()
    targetHumanoid.Health = 0
end

local function startAI()
    if currentConnection then currentConnection:Disconnect() end
    if currentPath then currentPath:Destroy() end
    if wanderThread then task.cancel(wanderThread) wanderThread = nil end
    if chaseThread then task.cancel(chaseThread) chaseThread = nil end
    if distractThread then task.cancel(distractThread) distractThread = nil end
    stopFootstepLoop()

    isChasing = false
    isDistracted = false

    currentConnection = trackConnection(RunService.Heartbeat:Connect(function()
        if cleaned or not rootPart or not rootPart.Parent then return end
        hitbox.CFrame = rootPart.CFrame * CFrame.new(0, 0, -6)

        if targetPlayer and targetHumanoid and targetHumanoid.Health > 0 then
            if isDistracted then
                isDistracted = false
                if distractThread then task.cancel(distractThread) distractThread = nil end
            end
            if not isChasing then
                isChasing = true
                startChasing()
            end
        elseif isChasing then
            isChasing = false
            if chaseThread then task.cancel(chaseThread) chaseThread = nil end
            humanoid:MoveTo(rootPart.Position)
            stopFootstepLoop()
            if currentAnim and currentAnim.Stop then currentAnim:Stop() end
            currentAnim = nil
        end
    end))

    trackConnection(hitbox.Touched:Connect(function(hit)
        if canKill and hit and targetCharacter and hit.Parent == targetCharacter then killPlayer() end
    end))
    trackConnection(rootPart.Touched:Connect(function(hit)
        if canKill and hit and targetCharacter and hit.Parent == targetCharacter then killPlayer() end
    end))
end

trackConnection(player.CharacterAdded:Connect(function()
    resetJumpscare()
end))

local function getLatestRoom()
    local rooms = workspace:WaitForChild("CurrentRooms", 30)
    local gameData = game:GetService("ReplicatedStorage"):WaitForChild("GameData", 30)
    local latestRoom = gameData and gameData:WaitForChild("LatestRoom", 30)
    if not rooms or not latestRoom then
        return nil
    end
    local deadline = os.clock() + 30
    repeat
        local room = rooms:FindFirstChild(tostring(latestRoom.Value))
        if room and room:IsA("Model") then return room end
        task.wait(0.1)
    until os.clock() >= deadline
    return nil
end

local room = getLatestRoom()
if cleaned or not room then return end
local entrance = room:WaitForChild("RoomEntrance", 30)
if cleaned or not entrance or not entrance:IsA("BasePart") then return end
Fredbear:PivotTo(entrance.CFrame * CFrame.new(0, 2, -5))
NPC.Parent = workspace

beginTargetMonitoring()
task.spawn(function()
    task.wait(10.5)
    if not cleaned then pcall(startAI) end
end)
end

task.delay(400, cleanup)
pcall(runFredbear)
end

function entityBehaviors.A20()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local function spawnShocker()
    local shockerModel = game:GetObjects("rbxassetid://100028546503408")[1]
    local camera = Workspace.CurrentCamera

    local rootPart = shockerModel:FindFirstChild("HumanoidRootPart") or shockerModel:FindFirstChildWhichIsA("BasePart", true)
    shockerModel.PrimaryPart = rootPart
    shockerModel:SetPrimaryPartCFrame(camera.CFrame * CFrame.new(0, 0, -7))
    shockerModel.Parent = Workspace

    local oogaBoogaaPart = shockerModel:WaitForChild("OOGA BOOGAAAA")
    local horrorScream = oogaBoogaaPart:WaitForChild("HORROR SCREAM 15")
    local boneSound = oogaBoogaaPart:FindFirstChild("Bone")

    local lookDuration = 2
    local awayDuration = 0.5
    local lookStart = nil
    local awayStart = nil
    local hasTriggered = false
    local hasFallen = false

    local function fallToGround()
        if hasFallen then return end
        hasFallen = true

        oogaBoogaaPart.Anchored = false
        oogaBoogaaPart.CanCollide = false

        task.delay(2, function()
            if shockerModel then
                shockerModel:Destroy()
            end
        end)
    end

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if hasTriggered or hasFallen then
            connection:Disconnect()
            return
        end

        local offset = oogaBoogaaPart.Position - camera.CFrame.Position
        if offset.Magnitude == 0 then return end

        local directionToShocker = offset.Unit
        local playerLookVector = camera.CFrame.LookVector
        local dot = directionToShocker:Dot(playerLookVector)

        if dot > 0.85 then
            awayStart = nil

            if not lookStart then
                lookStart = tick()
            elseif tick() - lookStart >= lookDuration then
                hasTriggered = true
                connection:Disconnect()
                fallToGround()
            end
        else
            lookStart = nil

            if not awayStart then
                awayStart = tick()
            elseif tick() - awayStart >= awayDuration then
                hasTriggered = true
                connection:Disconnect()

                horrorScream:Play()
                if boneSound then boneSound:Play() end

                humanoid:TakeDamage(40)

                local targetPos = character.HumanoidRootPart.Position + Vector3.new(0, 2, 0)
                local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
                local tween = TweenService:Create(oogaBoogaaPart, tweenInfo, {Position = targetPos})
                tween:Play()

                tween.Completed:Connect(function()
                    fallToGround()
                end)

                ReplicatedStorage.GameStats["Player_" .. player.Name].Total.DeathCause.Value = "A-20"

                firesignal(ReplicatedStorage.RemotesFolder.DeathHint.OnClientEvent, {
                    "You died to who you call A-20...",
                    "Keep an eye on him!"
                }, "Blue")
            end
        end
    end)

    task.delay(5, function()
        if not hasTriggered and not hasFallen then
            connection:Disconnect()
            fallToGround()
        end
    end)
end

spawnShocker()
end

function entityBehaviors.PRINCIPAL()
local RunService = game:GetService("RunService")

local MODEL_ID = 137575158482605
local MOVE_SPEED = 25
local HEIGHT_OFFSET = Vector3.new(0, 0, 0)
local RAYCAST_DISTANCE = 100
local RUNNING_SPEED = 15

local currentRooms = workspace:WaitForChild("CurrentRooms")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local movementPaused = false

local function getOrderedRooms()
    local orderedRooms = {}

    for _, room in ipairs(currentRooms:GetChildren()) do
        if room:IsA("Model") then
            local number = tonumber(room.Name)
            if number then
                table.insert(orderedRooms, {
                    Number = number,
                    Room = room
                })
            end
        end
    end

    table.sort(orderedRooms, function(a, b)
        return a.Number < b.Number
    end)

    return orderedRooms
end

local function getOrderedNodes(room)
    local orderedNodes = {}
    local pathfindNodes = room:FindFirstChild("PathfindNodes")

    if pathfindNodes then
        for _, node in ipairs(pathfindNodes:GetChildren()) do
            if node:IsA("BasePart") then
                table.insert(orderedNodes, node)
            end
        end

        table.sort(orderedNodes, function(a, b)
            local numberA = tonumber(a.Name)
            local numberB = tonumber(b.Name)

            if numberA and numberB then
                return numberA < numberB
            elseif numberA then
                return true
            elseif numberB then
                return false
            end

            return a.Name < b.Name
        end)
    end

    if #orderedNodes == 0 then
        local roomExit = room:FindFirstChild("RoomExit")
        if roomExit and roomExit:IsA("BasePart") then
            table.insert(orderedNodes, roomExit)
        end
    end

    return orderedNodes
end

local function loadModel()
    local success, asset = pcall(function()
        return game:GetObjects("rbxassetid://" .. MODEL_ID)[1]
    end)

    if not success or not asset then
        warn("模型加载失败：", asset)
        return nil
    end

    if not asset:IsA("Model") then
        asset:Destroy()
        warn("加载的资源不是 Model")
        return nil
    end

    for _, descendant in ipairs(asset:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
        elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant.Enabled = false
        end
    end

    return asset
end

local function moveModelTo(model, targetCFrame)
    local startCFrame = model:GetPivot()
    local distance = (startCFrame.Position - targetCFrame.Position).Magnitude

    if distance <= 0.001 then
        model:PivotTo(targetCFrame)
        return true
    end

    local travelled = 0

    while travelled < distance do
        local deltaTime = RunService.Heartbeat:Wait()

        if not model.Parent then
            return false
        end

        if not movementPaused then
            travelled = math.min(
                travelled + MOVE_SPEED * math.min(deltaTime, 0.1),
                distance
            )

            model:PivotTo(startCFrame:Lerp(targetCFrame, travelled / distance))
        end
    end

    return true
end

local function getCharacterFromRaycastHit(hitInstance)
    local current = hitInstance

    while current and current ~= workspace do
        if current:IsA("Model") and Players:GetPlayerFromCharacter(current) then
            return current
        end

        current = current.Parent
    end

    return nil
end

local function rayEntryDistanceToPart(origin, directionUnit, part)
    if not part or not part.Parent or not part:IsA("BasePart") then
        return nil
    end

    local localOrigin = part.CFrame:PointToObjectSpace(origin)
    local localDirection = part.CFrame:VectorToObjectSpace(directionUnit)
    local half = part.Size * 0.5
    local entry, exit = 0, math.huge

    for _, axis in ipairs({ "X", "Y", "Z" }) do
        local position = localOrigin[axis]
        local velocity = localDirection[axis]
        local extent = half[axis]

        if math.abs(velocity) < 0.00001 then
            if position < -extent or position > extent then
                return nil
            end
        else
            local near = (-extent - position) / velocity
            local far = (extent - position) / velocity

            if near > far then
                near, far = far, near
            end

            entry = math.max(entry, near)
            exit = math.min(exit, far)

            if exit < entry then
                return nil
            end
        end
    end

    return entry
end

local function findDecalSound(model, soundName)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant.Name == "DecalPart" and descendant:IsA("BasePart") then
            local sound = descendant:FindFirstChild(soundName, true)
            if sound and sound:IsA("Sound") then
                return sound
            end
        end
    end

    return nil
end

local function playSoundOnce(model, soundName, waitUntilFinished)
    local sound = findDecalSound(model, soundName)

    if not sound then
        return
    end

    sound.Looped = false
    sound.TimePosition = 0

    if not waitUntilFinished then
        sound.Playing = true
        return
    end

    local completed = false
    local connection = sound.Ended:Connect(function()
        completed = true
    end)

    sound.Playing = true
    local deadline = os.clock() + math.max(sound.TimeLength + 3, 15)

    while model.Parent and sound.Parent and not completed and os.clock() < deadline do
        task.wait(0.05)
    end

    connection:Disconnect()

    if sound.Parent and not completed then
        sound.Playing = false
    end
end

local function scanVisibleCharacters(model)
    local origin = model:GetPivot().Position
    local visibleCharacters = {}
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { model }

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character

        if character and character:IsDescendantOf(workspace)
            and not character:GetAttribute("Hiding") then
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")

            if humanoid and humanoid.Health > 0
                and rootPart and rootPart:IsA("BasePart") then
                local targets = { rootPart }

                for _, partName in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso" }) do
                    local targetPart = character:FindFirstChild(partName)
                    if targetPart and targetPart:IsA("BasePart") then
                        table.insert(targets, targetPart)
                    end
                end

                for _, targetPart in ipairs(targets) do
                    local direction = targetPart.Position - origin
                    local distance = direction.Magnitude

                    if distance > 0.001 and distance <= RAYCAST_DISTANCE then
                        local result = workspace:Raycast(origin, direction, raycastParams)
                        local hitCharacter = result
                            and getCharacterFromRaycastHit(result.Instance) or nil

                        if not hitCharacter then
                            local entryDistance = rayEntryDistanceToPart(
                                origin, direction.Unit, targetPart
                            )

                            if entryDistance and entryDistance <= distance + 0.01
                                and (not result or result.Distance > entryDistance + 0.02) then
                                hitCharacter = character
                            end
                        end

                        if hitCharacter and not hitCharacter:GetAttribute("Hiding") then
                            local hitHumanoid = hitCharacter:FindFirstChildWhichIsA("Humanoid")
                            if hitHumanoid and hitHumanoid.Health > 0 then
                                visibleCharacters[hitCharacter] = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    return visibleCharacters
end

local orderedRooms = getOrderedRooms()

if #orderedRooms == 0 then
    warn("CurrentRooms 中没有数字命名的房间")
    return
end

local startRoomIndex = 1

if #orderedRooms > 10 then
    startRoomIndex = #orderedRooms - 8
end

local targetRoomIndex = math.max(1, #orderedRooms - 1)
local lastRoomNodes = getOrderedNodes(orderedRooms[targetRoomIndex].Room)

if #lastRoomNodes == 0 then
    warn("反向起点房间没有可用节点")
    return
end

local model = loadModel()

if not model then
    return
end

model.Name = "Principal"
model:PivotTo(lastRoomNodes[#lastRoomNodes].CFrame + HEIGHT_OFFSET)
model.Parent = workspace

task.delay(2, function()
    if not model.Parent then
        return
    end

    playSoundOnce(model, "sounds", false)
end)

task.wait(3)

local warnedCharacters = setmetatable({}, { __mode = "k" })
local selfPenaltyApplied = false
local warningActive = false

local function applySelfPenalty(character)
    if selfPenaltyApplied or not localPlayer or localPlayer.Character ~= character then
        return
    end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    selfPenaltyApplied = true
    local originalWalkSpeed = humanoid.WalkSpeed
    local penaltyStartedAt = os.clock()

    task.spawn(function()
        while humanoid.Parent and os.clock() - penaltyStartedAt < 30 do
            humanoid.WalkSpeed = -100
            RunService.Heartbeat:Wait()
        end

        if humanoid.Parent then
            humanoid.WalkSpeed = originalWalkSpeed
        end
    end)
end

task.spawn(function()
    while model.Parent do
        local visibleCharacters = scanVisibleCharacters(model)
        local warningEligible = {}
        local newRunner = nil

        for character in pairs(visibleCharacters) do
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart and rootPart:IsA("BasePart") then
                local velocity = rootPart.AssemblyLinearVelocity
                local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

                if horizontalSpeed >= RUNNING_SPEED then
                    if localPlayer and localPlayer.Character == character then
                        applySelfPenalty(character)
                    end
                    warningEligible[character] = true

                    if not warningActive and not warnedCharacters[character] and not newRunner then
                        newRunner = character
                    end
                end
            end
        end

        for character in pairs(warnedCharacters) do
            if not warningEligible[character] then
                warnedCharacters[character] = nil
            end
        end

        if newRunner and not warningActive then
            warnedCharacters[newRunner] = true
            warningActive = true
            movementPaused = true

            task.spawn(function()
                playSoundOnce(model, "norunning", true)
                playSoundOnce(model, "whistle", true)
                playSoundOnce(model, "detentionforyou", true)

                if model.Parent then
                    playSoundOnce(model, "whenwillyoulearn", false)
                end

                movementPaused = false
                warningActive = false
            end)
        end

        task.wait(0.05)
    end
end)

for roomIndex = targetRoomIndex, startRoomIndex, -1 do
    local room = orderedRooms[roomIndex].Room
    local nodes = room.Parent and getOrderedNodes(room) or {}

    if #nodes == 0 then
        break
    end

    for nodeIndex = #nodes, 1, -1 do
        if not moveModelTo(model, nodes[nodeIndex].CFrame + HEIGHT_OFFSET) then
            model:Destroy()
            return
        end
    end
end

while movementPaused and model.Parent do
    task.wait(0.05)
end

model:Destroy()
end

function entityBehaviors.Scribblet()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
if not player then
    return
end

local playerGui = player:WaitForChild("PlayerGui")
local currentRooms = workspace:WaitForChild("CurrentRooms")
local hardCoreSound = workspace:WaitForChild("HardCoreSound")
local endSound = hardCoreSound:WaitForChild("EndS")
local startSound = hardCoreSound:WaitForChild("StartS")

local INTRO_DURATION = 8
local BLACKOUT_DURATION = 2
local HIDE_DURATION = 15
local ROUND_COUNT = 4
local FLYBY_MODEL_ID = 119948154036388
local FLYBY_DISTANCE = 50
local FLYBY_SPEED = 5
local FLYBY_DEPTH = 20
local COUNTDOWN_SOUND_ID = 137727855471828
local ROUND_BLACKOUT_RELEASE = 9
local BAR_HEIGHT = 1 / 3
local BAR_TWEEN_DURATION = 1.35
local BAR_IMAGE_ID = "rbxassetid://14827943434"
local FLYBY_DELAY_MIN = 6
local FLYBY_DELAY_MAX = 18

local random = Random.new()
local active = true
local filterStrength = 0
local savedObjects = setmetatable({}, { __mode = "k" })
local trackedSounds = setmetatable({}, { __mode = "k" })
local flyingModels = {}
local currentFlybyToken = nil
local soundAddedConnection = nil
local stepName = "ScribbletSway_" .. HttpService:GenerateGUID(false)
local lastCamera = nil
local lastCameraOffset = CFrame.new()
local startedAt = os.clock()

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "ScribbletColorCorrection"
colorCorrection.Saturation = 0
colorCorrection.Contrast = 0
colorCorrection.Brightness = 0
colorCorrection.Parent = Lighting

local gui = Instance.new("ScreenGui")
gui.Name = "ScribbletExperience"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 900
gui.Parent = playerGui

local barGui = Instance.new("ScreenGui")
barGui.Name = "ScribbletCinematicBars"
barGui.IgnoreGuiInset = true
barGui.ResetOnSpawn = false
barGui.DisplayOrder = -999
barGui.Parent = playerGui

local topBar = Instance.new("ImageLabel")
topBar.Name = "TopBar"
topBar.BackgroundTransparency = 1
topBar.Image = BAR_IMAGE_ID
topBar.ImageTransparency = 1
topBar.ScaleType = Enum.ScaleType.Stretch
topBar.Rotation = 180
topBar.Size = UDim2.fromScale(1, BAR_HEIGHT)
topBar.Position = UDim2.fromScale(0, -BAR_HEIGHT)
topBar.ZIndex = 20
topBar.Parent = barGui

local bottomBar = Instance.new("ImageLabel")
bottomBar.Name = "BottomBar"
bottomBar.BackgroundTransparency = 1
bottomBar.Image = BAR_IMAGE_ID
bottomBar.ImageTransparency = 1
bottomBar.ScaleType = Enum.ScaleType.Stretch
bottomBar.Size = UDim2.fromScale(1, BAR_HEIGHT)
bottomBar.AnchorPoint = Vector2.new(0, 1)
bottomBar.Position = UDim2.fromScale(0, 1 + BAR_HEIGHT)
bottomBar.ZIndex = 20
bottomBar.Parent = barGui

local hideLabel = Instance.new("TextLabel")
hideLabel.Name = "HideCountdown"
hideLabel.AnchorPoint = Vector2.new(0.5, 1)
hideLabel.Position = UDim2.fromScale(0.5, 0.94)
hideLabel.Size = UDim2.fromScale(0.8, 0.065)
hideLabel.BackgroundTransparency = 1
hideLabel.Text = ""
hideLabel.TextScaled = true
hideLabel.TextStrokeTransparency = 0.5
hideLabel.TextStrokeColor3 = Color3.fromRGB(18, 18, 18)
hideLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
hideLabel.Visible = false
hideLabel.ZIndex = 22
hideLabel.Parent = gui

local fontLoaded, customFont = pcall(function()
    return Font.fromId(8764312106, Enum.FontWeight.Bold)
end)

if fontLoaded and customFont then
    hideLabel.FontFace = customFont
else
    hideLabel.Font = Enum.Font.GothamBold
end

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(105, 105, 105)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(125, 125, 125))
})
gradient.Offset = Vector2.new(-0.4, 0)
gradient.Parent = hideLabel

local gradientTween = TweenService:Create(
    gradient,
    TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Offset = Vector2.new(0.4, 0) }
)
gradientTween:Play()

local blackoutGui = Instance.new("ScreenGui")
blackoutGui.Name = "ScribbletBlackoutLayer"
blackoutGui.IgnoreGuiInset = true
blackoutGui.ResetOnSpawn = false
blackoutGui.DisplayOrder = -1000
blackoutGui.Parent = playerGui

local blackScreen = Instance.new("Frame")
blackScreen.Name = "BlackScreen"
blackScreen.Size = UDim2.fromScale(1, 1)
blackScreen.BackgroundColor3 = Color3.new(0, 0, 0)
blackScreen.BackgroundTransparency = 1
blackScreen.BorderSizePixel = 0
blackScreen.Active = false
blackScreen.Parent = blackoutGui

local function playTween(object, duration, properties)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        properties
    )
    tween:Play()
    return tween
end

playTween(topBar, BAR_TWEEN_DURATION, {
    Position = UDim2.fromScale(0, 0),
    ImageTransparency = 0
})
playTween(bottomBar, BAR_TWEEN_DURATION, {
    Position = UDim2.fromScale(0, 1),
    ImageTransparency = 0
})

local function registerSound(sound)
    if not sound:IsA("Sound") or trackedSounds[sound]
        or sound == endSound or sound == startSound then
        return
    end

    local echo = Instance.new("EchoSoundEffect")
    echo.Name = "ScribbletEarlyEcho"
    echo.Delay = 0.25
    echo.Feedback = 0.38
    echo.DryLevel = -2
    echo.WetLevel = -80

    local reverb = Instance.new("ReverbSoundEffect")
    reverb.Name = "ScribbletCathedralReverb"
    reverb.DecayTime = 8.5
    reverb.Density = 0.96
    reverb.Diffusion = 0.92
    reverb.DryLevel = -2
    reverb.WetLevel = -80

    local success = pcall(function()
        echo.Parent = sound
        reverb.Parent = sound
    end)

    if not success then
        echo:Destroy()
        reverb:Destroy()
        return
    end

    trackedSounds[sound] = { Echo = echo, Reverb = reverb }
    echo.WetLevel = -80 + 72 * filterStrength
    reverb.WetLevel = -80 + 82 * filterStrength
end

local function setFilterStrength(strength)
    filterStrength = math.clamp(strength, 0, 1)
    colorCorrection.Saturation = -filterStrength
    colorCorrection.Contrast = 0.14 * filterStrength
    colorCorrection.Brightness = 0.035 * filterStrength

    for sound, effects in pairs(trackedSounds) do
        if sound.Parent then
            if effects.Echo.Parent then
                effects.Echo.WetLevel = -80 + 72 * filterStrength
            end
            if effects.Reverb.Parent then
                effects.Reverb.WetLevel = -80 + 82 * filterStrength
            end
        end
    end
end

for _, descendant in ipairs(game:GetDescendants()) do
    if descendant:IsA("Sound") then
        registerSound(descendant)
    end
end

soundAddedConnection = game.DescendantAdded:Connect(function(descendant)
    if active and descendant:IsA("Sound") then
        registerSound(descendant)
    end
end)

RunService:BindToRenderStep(stepName, Enum.RenderPriority.Camera.Value + 2, function()
    if not active then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    if lastCamera ~= camera then
        lastCamera = camera
        lastCameraOffset = CFrame.new()
    end

    local elapsed = os.clock() - startedAt
    local strength = 0.3 + 0.7 * filterStrength
    local nextOffset = CFrame.new(
        math.sin(elapsed * 1.65) * 0.045 * strength,
        math.sin(elapsed * 1.13 + 0.8) * 0.012 * strength,
        0
    ) * CFrame.Angles(
        0,
        0,
        math.sin(elapsed * 1.4) * math.rad(0.24) * strength
    )

    camera.CFrame = camera.CFrame * lastCameraOffset:Inverse() * nextOffset
    lastCameraOffset = nextOffset
end)

local function playSound(sound, waitForEnd)
    if not sound or not sound:IsA("Sound") then
        return
    end

    sound.Looped = false
    sound.TimePosition = 0

    if not waitForEnd then
        sound.Playing = true
        return
    end

    local finished = false
    local connection = sound.Ended:Connect(function()
        finished = true
    end)
    sound.Playing = true

    local loadDeadline = os.clock() + 5
    while active and sound.Parent and not sound.IsLoaded
        and not finished and os.clock() < loadDeadline do
        task.wait(0.05)
    end

    local deadline = os.clock() + math.max(sound.TimeLength + 3, 20)

    while active and sound.Parent and not finished and os.clock() < deadline do
        task.wait(0.05)
    end

    connection:Disconnect()
end

local function saveModelState(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if not savedObjects[descendant] then
            if descendant:IsA("BasePart") then
                savedObjects[descendant] = {
                    Kind = "Part",
                    Transparency = descendant.Transparency,
                    Color = descendant.Color,
                    CanCollide = descendant.CanCollide,
                    CanTouch = descendant.CanTouch
                }
            elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                savedObjects[descendant] = {
                    Kind = "Surface",
                    Transparency = descendant.Transparency
                }
            elseif descendant:IsA("ProximityPrompt") then
                savedObjects[descendant] = {
                    Kind = "Prompt",
                    Enabled = descendant.Enabled
                }
            elseif descendant:IsA("ClickDetector") then
                savedObjects[descendant] = {
                    Kind = "Click",
                    Distance = descendant.MaxActivationDistance
                }
            end
        end
    end
end

local function restoreObjects()
    for object, state in pairs(savedObjects) do
        if object.Parent then
            if state.Kind == "Part" then
                object.Transparency = state.Transparency
                object.Color = state.Color
                object.CanCollide = state.CanCollide
                object.CanTouch = state.CanTouch
            elseif state.Kind == "Surface" then
                object.Transparency = state.Transparency
            elseif state.Kind == "Prompt" then
                object.Enabled = state.Enabled
            elseif state.Kind == "Click" then
                object.MaxActivationDistance = state.Distance
            end
        end
    end
end

local function getHidingModels()
    local wardrobes = {}
    local beds = {}

    for _, descendant in ipairs(currentRooms:GetDescendants()) do
        if descendant:IsA("Model") then
            if descendant.Name == "Wardrobe" then
                table.insert(wardrobes, descendant)
            elseif descendant.Name == "Bed" then
                table.insert(beds, descendant)
            end
        end
    end

    return wardrobes, beds
end

local function chooseHidingModel(wardrobes, beds)
    local candidates

    if #wardrobes > 0 and #beds > 0 then
        candidates = random:NextInteger(1, 2) == 1 and wardrobes or beds
    elseif #wardrobes > 0 then
        candidates = wardrobes
    else
        candidates = beds
    end

    if #candidates == 0 then
        return nil
    end

    return candidates[random:NextInteger(1, #candidates)]
end

local function setHidingModelEnabled(model, enabled)
    for _, descendant in ipairs(model:GetDescendants()) do
        local state = savedObjects[descendant]

        if state then
            if state.Kind == "Part" then
                descendant.Transparency = enabled and state.Transparency or 1
                descendant.Color = state.Color
                descendant.CanCollide = enabled and state.CanCollide or false
                descendant.CanTouch = enabled and state.CanTouch or false
            elseif state.Kind == "Surface" then
                descendant.Transparency = enabled and state.Transparency or 1
            elseif state.Kind == "Prompt" then
                descendant.Enabled = enabled and state.Enabled or false
            elseif state.Kind == "Click" then
                descendant.MaxActivationDistance = enabled and state.Distance or 0
            end
        end
    end
end

local function disableAllHidingPrompts(models)
    for _, model in ipairs(models) do
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("ProximityPrompt") then
                descendant.Enabled = false
            elseif descendant:IsA("ClickDetector") then
                descendant.MaxActivationDistance = 0
            end
        end
    end
end

local function flickerModels(models, state)
    local parts = {}

    for _, model in ipairs(models) do
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("BasePart") then
                table.insert(parts, descendant)
            end
        end
    end

    task.spawn(function()
        while active and state.Flickering do
            for _, part in ipairs(parts) do
                if part.Parent then
                    local white = random:NextNumber() > 0.45
                    part.Color = white
                        and Color3.fromRGB(245, 245, 245)
                        or Color3.fromRGB(12, 12, 12)
                end
            end
            task.wait(0.12)
        end
    end)
end

local function loadFlybyModel()
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(FLYBY_MODEL_ID))
    end)

    local asset = success and objects and objects[1] or nil

    if not asset then
        local source = ReplicatedStorage:FindFirstChild("ScribbletModel", true)
        if source then
            asset = source:Clone()
        end
    end

    if not asset then
        return nil
    end

    if not asset:IsA("Model") then
        local wrapper = Instance.new("Model")
        asset.Parent = wrapper
        asset = wrapper
    end

    for _, descendant in ipairs(asset:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant.Enabled = false
        end
    end

    asset.Name = "A120_Scribblet"
    asset.Parent = workspace
    return asset
end

local function runFlyby(token)
    local model = loadFlybyModel()
    if not model then
        return
    end

    flyingModels[model] = true
    local height = random:NextNumber(-1.5, 1.5)
    local startTime = os.clock()
    local duration = FLYBY_DISTANCE / FLYBY_SPEED
    local camera = workspace.CurrentCamera

    if not camera then
        model:Destroy()
        flyingModels[model] = nil
        return
    end

    local fixedCameraCFrame = camera.CFrame

    while active and token.Active and model.Parent do
        local elapsed = os.clock() - startTime
        local distanceTravelled = math.min(elapsed * FLYBY_SPEED, FLYBY_DISTANCE)
        local x = FLYBY_DISTANCE / 2 - distanceTravelled
        model:PivotTo(
            fixedCameraCFrame
            * CFrame.new(x, height, -FLYBY_DEPTH)
            * CFrame.Angles(0, math.pi, 0)
        )

        if elapsed >= duration then
            break
        end

        RunService.RenderStepped:Wait()
    end

    if model.Parent then
        model:Destroy()
    end
    flyingModels[model] = nil
end

local function isHiding()
    local character = player.Character
    return (character and character:GetAttribute("Hiding") == true)
        or player:GetAttribute("Hiding") == true
end

local function isPlayerDead()
    local character = player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return not humanoid or humanoid.Health <= 0
end

local function runRoundBlackout(transition)
    local startTime = os.clock()

    while active and transition.Active do
        local elapsed = os.clock() - startTime
        local opacity

        if elapsed < 1.4 then
            local progress = math.clamp(elapsed / 1.4, 0, 1)
            local flicker = math.abs(math.sin(elapsed * 29)) * 0.22
            opacity = math.clamp(progress + flicker * (1 - progress), 0, 1)
        elseif elapsed < ROUND_BLACKOUT_RELEASE then
            opacity = 1
        elseif elapsed < ROUND_BLACKOUT_RELEASE + 1.4 then
            local progress = math.clamp(
                (elapsed - ROUND_BLACKOUT_RELEASE) / 1.4, 0, 1
            )
            local flicker = math.abs(math.sin(elapsed * 32)) * 0.2
            opacity = math.clamp(1 - progress - flicker * progress, 0, 1)
        else
            break
        end

        blackScreen.BackgroundTransparency = 1 - opacity
        RunService.RenderStepped:Wait()
    end

    blackScreen.BackgroundTransparency = 1
    transition.Done = true
end

local function playCountdownSound()
    local sound = Instance.new("Sound")
    sound.Name = "ScribbletHideCountdown"
    sound.SoundId = "rbxassetid://" .. tostring(COUNTDOWN_SOUND_ID)
    sound.Volume = 1.5
    sound.Looped = false
    sound.Parent = SoundService
    registerSound(sound)

    sound.Ended:Connect(function()
        if sound.Parent then
            sound:Destroy()
        end
    end)

    task.delay(60, function()
        if sound.Parent then
            sound:Destroy()
        end
    end)

    playSound(sound, false)
end

local function runCountdown()
    hideLabel.Visible = true
    local startTime = os.clock()
    local demonstrationOnly = isPlayerDead()
    local hasBeenOutside = demonstrationOnly or not isHiding()
    local passed = false
    local lastDisplayedSecond = nil

    while active do
        local elapsed = os.clock() - startTime
        local remaining = math.max(0, HIDE_DURATION - elapsed)
        local displayedSecond = math.ceil(remaining)

        if displayedSecond ~= lastDisplayedSecond then
            lastDisplayedSecond = displayedSecond
            hideLabel.Text = "HIDE : " .. tostring(displayedSecond) .. "s"
            if displayedSecond > 0 then
                playCountdownSound()
            end
        end

        if not demonstrationOnly then
            if isPlayerDead() then
                demonstrationOnly = true
            elseif not isHiding() then
                hasBeenOutside = true
            elseif hasBeenOutside then
                passed = true
                break
            end
        end

        if remaining <= 0 then
            break
        end

        RunService.Heartbeat:Wait()
    end

    hideLabel.Visible = false
    return passed or demonstrationOnly
end

local function runRound()
    local wardrobes, beds = getHidingModels()
    local allModels = {}

    for _, model in ipairs(wardrobes) do
        table.insert(allModels, model)
    end

    for _, model in ipairs(beds) do
        table.insert(allModels, model)
    end

    local chosen = chooseHidingModel(wardrobes, beds)
    if not chosen then
        return nil
    end

    for _, model in ipairs(allModels) do
        saveModelState(model)
    end

    restoreObjects()
    disableAllHidingPrompts(allModels)

    local state = { Flickering = true }
    local flybyToken = { Active = true }
    local transition = { Active = true, Done = false }
    currentFlybyToken = flybyToken
    flickerModels(allModels, state)
    task.spawn(function()
        task.wait(random:NextNumber(FLYBY_DELAY_MIN, FLYBY_DELAY_MAX))
        if active and flybyToken.Active then
            runFlyby(flybyToken)
        end
    end)
    task.spawn(runRoundBlackout, transition)
    playSound(startSound, true)
    while active and not transition.Done do
        task.wait(0.05)
    end
    transition.Active = false
    state.Flickering = false
    restoreObjects()

    for _, model in ipairs(allModels) do
        if model.Parent then
            setHidingModelEnabled(model, model == chosen)
        end
    end

    local passed = runCountdown()
    return passed
end

local function fadeOutAndCleanUp()
    hideLabel.Visible = false
    local start = os.clock()
    local fromStrength = filterStrength
    local fromBlack = blackScreen.BackgroundTransparency

    while os.clock() - start < 2.5 do
        local progress = math.clamp((os.clock() - start) / 2.5, 0, 1)
        local eased = progress * progress * (3 - 2 * progress)
        setFilterStrength(fromStrength * (1 - eased))
        blackScreen.BackgroundTransparency = fromBlack + (1 - fromBlack) * eased
        RunService.Heartbeat:Wait()
    end

    setFilterStrength(0)
    restoreObjects()
    active = false

    if currentFlybyToken then
        currentFlybyToken.Active = false
    end

    if soundAddedConnection then
        soundAddedConnection:Disconnect()
    end

    for model in pairs(flyingModels) do
        if model.Parent then
            model:Destroy()
        end
    end

    RunService:UnbindFromRenderStep(stepName)

    if lastCamera and lastCamera.Parent then
        lastCamera.CFrame = lastCamera.CFrame * lastCameraOffset:Inverse()
    end

    for _, effects in pairs(trackedSounds) do
        if effects.Echo.Parent then
            effects.Echo:Destroy()
        end
        if effects.Reverb.Parent then
            effects.Reverb:Destroy()
        end
    end

    colorCorrection:Destroy()
    gradientTween:Cancel()
    playTween(topBar, BAR_TWEEN_DURATION, {
        Position = UDim2.fromScale(0, -BAR_HEIGHT),
        ImageTransparency = 1
    })
    playTween(bottomBar, BAR_TWEEN_DURATION, {
        Position = UDim2.fromScale(0, 1 + BAR_HEIGHT),
        ImageTransparency = 1
    }).Completed:Wait()
    blackoutGui:Destroy()
    barGui:Destroy()
    gui:Destroy()
end

local introStarted = os.clock()

while active do
    local elapsed = os.clock() - introStarted
    local alpha = math.clamp(elapsed / INTRO_DURATION, 0, 1)
    setFilterStrength(alpha * alpha * (3 - 2 * alpha))

    if alpha >= 1 then
        break
    end

    RunService.Heartbeat:Wait()
end

setFilterStrength(1)
blackScreen.BackgroundTransparency = 0
task.wait(BLACKOUT_DURATION)
playTween(blackScreen, 0.4, { BackgroundTransparency = 1 }).Completed:Wait()
playSound(endSound, true)

local won = true
local startedRounds = 0

for round = 1, ROUND_COUNT do
    startedRounds = round
    local result = runRound()

    if result == nil then
        won = false
        break
    end

    if not result then
        won = false
        local character = player.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid:TakeDamage(400)
        end
        break
    end
end

if won and startedRounds == ROUND_COUNT then
    blackScreen.BackgroundTransparency = 0
    task.wait(0.18)
    blackScreen.BackgroundTransparency = 1
end

playSound(endSound, false)
fadeOutAndCleanUp()
end

function entityBehaviors.SLD()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
    return
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
if not camera then
    return
end

local distance = 8
local heightOffset = -5
local duration = 10
local escapeThreshold = 8

local success, objects = pcall(function()
    return game:GetObjects("rbxassetid://81308817927391")
end)

local model = success and objects and objects[1]
if not model or not model:IsA("Model") then
    return
end

for _, descendant in ipairs(model:GetDescendants()) do
    if descendant:IsA("Script") or descendant:IsA("LocalScript") then
        descendant.Enabled = false
    elseif descendant:IsA("BasePart") then
        descendant.Anchored = true
    elseif descendant:IsA("Animator") then
        for _, track in ipairs(descendant:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end
end

model.Parent = workspace

local forwardPosition = root.Position + root.CFrame.LookVector * distance
local spawnPosition = Vector3.new(forwardPosition.X, root.Position.Y + heightOffset, forwardPosition.Z)
model:PivotTo(CFrame.new(spawnPosition) * model:GetPivot().Rotation)

local frozenTransforms = {}
for _, descendant in ipairs(model:GetDescendants()) do
    if descendant:IsA("BasePart") then
        frozenTransforms[descendant] = descendant.CFrame
    end
end

local freezeConnection = RunService.Heartbeat:Connect(function()
    for part, originalCFrame in pairs(frozenTransforms) do
        if part.Parent and part.CFrame ~= originalCFrame then
            part.CFrame = originalCFrame
        end
    end
end)

local lookPart = model:FindFirstChild("Look", true)
local effectPart = model:FindFirstChild("pART", true)

if not lookPart or not lookPart:IsA("BasePart") then
    freezeConnection:Disconnect()
    model:Destroy()
    return
end

local playtime = effectPart and effectPart:FindFirstChild("Playtime", true)
local playImage
if playtime then
    if playtime:IsA("ImageLabel") then
        playImage = playtime
    else
        playImage = playtime:FindFirstChildWhichIsA("ImageLabel", true)
    end
end

if playImage and effectPart and effectPart:IsA("BasePart") then
    local billboard = playImage:FindFirstAncestorWhichIsA("BillboardGui")
    if billboard then
        local adornee = billboard.Adornee
        local center = effectPart.Position
        if adornee and adornee:IsA("BasePart") then
            center = adornee.Position
        elseif adornee and adornee:IsA("Attachment") then
            center = adornee.WorldPosition
        end

        center = center
            + effectPart.CFrame:VectorToWorldSpace(billboard.StudsOffset)
            + billboard.StudsOffsetWorldSpace

        local distanceToCamera = math.max(1, (camera.CFrame.Position - center).Magnitude)
        local viewportHeight = camera.ViewportSize.Y > 0 and camera.ViewportSize.Y or 720
        local pixelsPerStud = math.max(
            1,
            viewportHeight / (2 * distanceToCamera * math.tan(math.rad(camera.FieldOfView) / 2))
        )
        local widthPixels = math.max(64, math.abs(billboard.Size.X.Scale) * pixelsPerStud + math.abs(billboard.Size.X.Offset))
        local heightPixels = math.max(64, math.abs(billboard.Size.Y.Scale) * pixelsPerStud + math.abs(billboard.Size.Y.Offset))

        local plane = Instance.new("Part")
        plane.Name = "FixedPlaytimePlane"
        plane.Anchored = true
        plane.CanCollide = false
        plane.CanTouch = false
        plane.CanQuery = false
        plane.Transparency = 1
        plane.Size = Vector3.new(widthPixels / pixelsPerStud, heightPixels / pixelsPerStud, 0.05)
        plane.CFrame = CFrame.lookAt(center, root.Position)
        plane.Parent = model
        frozenTransforms[plane] = plane.CFrame

        local fixedGui = Instance.new("SurfaceGui")
        fixedGui.Name = "FixedPlaytime"
        fixedGui.Adornee = plane
        fixedGui.Face = Enum.NormalId.Front
        fixedGui.AlwaysOnTop = true
        fixedGui.LightInfluence = billboard.LightInfluence
        fixedGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
        fixedGui.CanvasSize = Vector2.new(math.round(widthPixels), math.round(heightPixels))
        fixedGui.ZIndexBehavior = billboard.ZIndexBehavior
        fixedGui.Parent = plane

        for _, child in ipairs(billboard:GetChildren()) do
            child.Parent = fixedGui
        end

        billboard:Destroy()
    end
end

local staticSound = effectPart and effectPart:FindFirstChild("Static", true)
if staticSound and not staticSound:IsA("Sound") then
    staticSound = nil
end

local originalWalkSpeed = humanoid.WalkSpeed
local walkSpeedRestored = false
humanoid.WalkSpeed = -20

local walkSpeedConnection = RunService.Heartbeat:Connect(function()
    if humanoid.Parent then
        humanoid.WalkSpeed = -20
    end
end)

local function restoreWalkSpeed()
    if walkSpeedRestored then
        return
    end
    walkSpeedRestored = true
    walkSpeedConnection:Disconnect()
    if humanoid.Parent then
        humanoid.WalkSpeed = originalWalkSpeed
    end
end

task.wait(1)

if humanoid.Health <= 0 or not model.Parent then
    restoreWalkSpeed()
    freezeConnection:Disconnect()
    model:Destroy()
    return
end

local oldCameraType = camera.CameraType
local oldCameraSubject = camera.CameraSubject
local oldMouseBehavior = UserInputService.MouseBehavior
local cameraPosition = camera.CFrame.Position

local gui = Instance.new("ScreenGui")
gui.Name = "LookTrapOverlay"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local blackout = Instance.new("Frame")
blackout.Name = "Blackout"
blackout.BackgroundColor3 = Color3.new(0, 0, 0)
blackout.BackgroundTransparency = 1
blackout.BorderSizePixel = 0
blackout.Size = UDim2.fromScale(1, 1)
blackout.ZIndex = 9
blackout.Parent = gui

local columns = 12
local rows = 8
local tileOrder = {}
local overlayImages = {}

for y = 0, rows - 1 do
    for x = 0, columns - 1 do
        table.insert(tileOrder, Vector2.new(x, y))
    end
end

for i = #tileOrder, 2, -1 do
    local j = math.random(1, i)
    tileOrder[i], tileOrder[j] = tileOrder[j], tileOrder[i]
end

local function fillTiles(targetCount)
    while #overlayImages < targetCount do
        local cell = tileOrder[#overlayImages + 1]
        if not cell then
            break
        end

        local image = Instance.new("ImageLabel")
        image.Name = "BlackImage"
        image.BackgroundTransparency = 1
        image.Image = "rbxassetid://12293713542"
        image.ImageColor3 = Color3.new(0, 0, 0)
        image.ScaleType = Enum.ScaleType.Crop
        image.Position = UDim2.fromScale(cell.X / columns, cell.Y / rows)
        image.Size = UDim2.fromScale(1 / columns + 0.002, 1 / rows + 0.002)
        image.ZIndex = 10
        image.Parent = gui
        table.insert(overlayImages, image)
    end
end

local imageBasePosition = playImage and playImage.Position

if playImage then
    playImage.Visible = true
end

local running = true
local resolved = false
local cleaning = false
local effort = 0
local yaw = 0
local pitch = 0
local inputConnection
local cameraConnection
local diedConnection

local function restoreCamera()
    if inputConnection then
        inputConnection:Disconnect()
        inputConnection = nil
    end
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    if diedConnection then
        diedConnection:Disconnect()
        diedConnection = nil
    end
    camera.CameraType = oldCameraType
    camera.CameraSubject = oldCameraSubject
    UserInputService.MouseBehavior = oldMouseBehavior
end

local function fadeAndRemove()
    if cleaning then
        return
    end
    cleaning = true
    running = false
    restoreWalkSpeed()
    freezeConnection:Disconnect()

    local fadeInfo = TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if blackout.Parent then
        TweenService:Create(blackout, fadeInfo, {BackgroundTransparency = 1}):Play()
    end

    for _, image in ipairs(overlayImages) do
        if image.Parent then
            TweenService:Create(image, fadeInfo, {ImageTransparency = 1}):Play()
        end
    end

    if playImage and playImage.Parent then
        TweenService:Create(playImage, fadeInfo, {ImageTransparency = 1}):Play()
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("Sound") then
            TweenService:Create(descendant, fadeInfo, {Volume = 0}):Play()
        elseif descendant:IsA("BasePart") or descendant:IsA("Decal") or descendant:IsA("Texture") then
            TweenService:Create(descendant, fadeInfo, {Transparency = 1}):Play()
        end
    end

    task.delay(0.7, function()
        if gui.Parent then
            gui:Destroy()
        end
        if model.Parent then
            model:Destroy()
        end
    end)
end

local function resolve(escaped)
    if resolved then
        return
    end
    resolved = true
    running = false
    restoreWalkSpeed()
    restoreCamera()

    if escaped then
        fadeAndRemove()
        return
    end

    fillTiles(#tileOrder)
    blackout.BackgroundTransparency = 0
    humanoid:TakeDamage(100)

    if staticSound and staticSound.Parent then
        staticSound.Looped = false
        local endedConnection
        endedConnection = staticSound.Ended:Connect(function()
            if endedConnection then
                endedConnection:Disconnect()
            end
            fadeAndRemove()
        end)
        staticSound:Play()
        task.delay(8, function()
            if endedConnection then
                endedConnection:Disconnect()
            end
            fadeAndRemove()
        end)
    else
        task.delay(0.5, fadeAndRemove)
    end
end

local function applySwipe(delta)
    if not running then
        return
    end

    local smallerSide = math.max(1, math.min(camera.ViewportSize.X, camera.ViewportSize.Y))
    local movement = delta.Magnitude
    effort = effort + math.min(movement / smallerSide, 0.8)
    yaw = math.clamp(yaw - delta.X * 0.003, -1.1, 1.1)
    pitch = math.clamp(pitch - delta.Y * 0.003, -0.85, 0.85)

    if effort >= escapeThreshold then
        resolve(true)
    end
end

camera.CameraType = Enum.CameraType.Scriptable
if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local startTime = os.clock()

task.spawn(function()
    while running do
        local progress = math.clamp((os.clock() - startTime) / duration, 0, 1)
        local targetCount = math.max(1, math.floor(#tileOrder * progress ^ 3))
        fillTiles(targetCount)
        blackout.BackgroundTransparency = 1 - progress ^ 7
        task.wait(0.05)
    end
end)

inputConnection = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        applySwipe(Vector2.new(input.Delta.X, input.Delta.Y))
    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
        applySwipe(Vector2.new(input.Delta.X, input.Delta.Y))
    end
end)

cameraConnection = RunService.RenderStepped:Connect(function(dt)
    if not running then
        return
    end

    if not lookPart.Parent then
        resolve(true)
        return
    end

    yaw = yaw * math.exp(-10 * dt)
    pitch = pitch * math.exp(-10 * dt)
    effort = math.max(0, effort - 0.08 * dt)

    camera.CFrame = CFrame.lookAt(cameraPosition, lookPart.Position) * CFrame.Angles(pitch, yaw, 0)
    camera.Focus = CFrame.new(lookPart.Position)
end)

diedConnection = humanoid.Died:Connect(function()
    if not resolved then
        resolve(true)
    end
end)

if playImage then
    task.spawn(function()
        while running and playImage.Parent do
            local dx = math.random(-3, 3)
            playImage.Position = UDim2.new(
                imageBasePosition.X.Scale,
                imageBasePosition.X.Offset + dx,
                imageBasePosition.Y.Scale,
                imageBasePosition.Y.Offset
            )
            task.wait(0.03)
        end
    end)
end

task.delay(duration, function()
    if not resolved then
        resolve(false)
    end
end)
end

function entityBehaviors.Bite()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
    return
end

local currentRooms = workspace:WaitForChild("CurrentRooms")
local latestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")
local startRoom = latestRoom.Value

if workspace:FindFirstChild("SeekMovingNewClone") or currentRooms:FindFirstChild("50") then
    return
end

local room = currentRooms:FindFirstChild(tostring(startRoom))
    or currentRooms:WaitForChild(tostring(startRoom), 5)
if not room or latestRoom.Value ~= startRoom then
    return
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local function findSpawnPart()
    local nodeFolder = room:FindFirstChild("Nodes") or room:FindFirstChild("PathfindNodes")
    if nodeFolder then
        local nodes = {}
        for _, node in ipairs(nodeFolder:GetChildren()) do
            if node:IsA("BasePart") then
                table.insert(nodes, node)
            end
        end
        table.sort(nodes, function(a, b)
            local na, nb = tonumber(a.Name), tonumber(b.Name)
            if na and nb then
                return na < nb
            elseif na then
                return true
            elseif nb then
                return false
            end
            return a.Name < b.Name
        end)
        if #nodes > 0 then
            return nodes[math.max(1, math.floor(#nodes / 2))]
        end
    end

    for _, name in ipairs({room.Name, "RoomEntrance", "RoomExit"}) do
        local part = room:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    return room.PrimaryPart
end

local spawnPart = findSpawnPart()
if not spawnPart then
    return
end

local loaded, objects = pcall(function()
    return game:GetObjects("rbxassetid://77820002550007")
end)

local model = loaded and objects and objects[1]
if not model or not model:IsA("Model") then
    return
end

local rushPart = model:FindFirstChild("RushNew", true)
if not rushPart or not rushPart:IsA("BasePart") then
    model:Destroy()
    return
end

local attachment = rushPart:FindFirstChild("Attachment", true)
local bitesTrail = attachment and attachment:FindFirstChild("Bites Trail", true)

local targetEmitter = rushPart:FindFirstChild("ParticleEmitter", true)
if not targetEmitter or not targetEmitter:IsA("ParticleEmitter") then
    targetEmitter = nil
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") and descendant.Name == "ParticleEmitter" then
            targetEmitter = descendant
            break
        end
    end
end

if not targetEmitter or not bitesTrail
    or not (bitesTrail:IsA("ParticleEmitter") or bitesTrail:IsA("Trail")) then
    model:Destroy()
    return
end

local lightSources = {}
local lightParts = {}

for _, descendant in ipairs(model:GetDescendants()) do
    if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
        descendant.Enabled = false
    elseif descendant:IsA("Light") then
        descendant.Enabled = true
        descendant.Brightness = math.max(1, descendant.Brightness)
        descendant.Range = math.max(12, descendant.Range)
        table.insert(lightSources, descendant)
    elseif descendant:IsA("BasePart") then
        descendant.Anchored = true
        if descendant.Name:lower() == "light" then
            descendant.Transparency = 0
            table.insert(lightParts, descendant)
        end
    elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
        descendant.Enabled = false
    end
end

model.Parent = workspace

local partOffset = model:GetPivot():ToObjectSpace(rushPart.CFrame)
local destination = spawnPart.CFrame + Vector3.new(0, 4, 0)
model:PivotTo(destination * partOffset:Inverse())

local monsterRoar = model:FindFirstChild("Monster Roar", true)
if monsterRoar and not monsterRoar:IsA("Sound") then
    monsterRoar = nil
end
if monsterRoar then
    monsterRoar:Stop()
end

local active = true
local cleaning = false
local roared = false
local roomConnection
local damageConnection
local diedConnection

local function playToggleSound()
    if not active or not rushPart.Parent then
        return
    end

    local sound = Instance.new("Sound")
    sound.Name = "RushSwitchSound"
    sound.SoundId = "rbxassetid://134847459602515"
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = rushPart
    sound.Ended:Once(function()
        if sound.Parent then
            sound:Destroy()
        end
    end)
    sound:Play()

    task.delay(30, function()
        if sound.Parent then
            sound:Destroy()
        end
    end)
end

local function cleanup()
    if cleaning then
        return
    end

    cleaning = true
    active = false

    if roomConnection then
        roomConnection:Disconnect()
    end
    if damageConnection then
        damageConnection:Disconnect()
    end
    if diedConnection then
        diedConnection:Disconnect()
    end

    if bitesTrail.Parent then
        bitesTrail.Enabled = false
    end
    if targetEmitter.Parent then
        targetEmitter.Enabled = false
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
            descendant.Enabled = false
        end
    end

    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    for _, light in ipairs(lightSources) do
        if light.Parent then
            TweenService:Create(light, tweenInfo, {Range = 0, Brightness = 0}):Play()
        end
    end

    for _, part in ipairs(lightParts) do
        if part.Parent then
            local size = part.Size
            TweenService:Create(part, tweenInfo, {
                Transparency = 1,
                Size = Vector3.new(
                    math.max(0.05, size.X * 0.05),
                    math.max(0.05, size.Y * 0.05),
                    math.max(0.05, size.Z * 0.05)
                )
            }):Play()
        end
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("Sound") then
            TweenService:Create(descendant, tweenInfo, {Volume = 0}):Play()
        end
    end

    task.delay(1.1, function()
        if model.Parent then
            model:Destroy()
        end
    end)
end

roomConnection = latestRoom.Changed:Connect(function(newRoom)
    if newRoom ~= startRoom then
        cleanup()
    end
end)

diedConnection = humanoid.Died:Connect(function()
    if active and not roared then
        roared = true
        if monsterRoar and monsterRoar.Parent then
            monsterRoar.Looped = false
            monsterRoar:Stop()
            monsterRoar:Play()
        end
    end
end)

damageConnection = RunService.Heartbeat:Connect(function(dt)
    if not active then
        return
    end
    if not model.Parent then
        cleanup()
        return
    end
    if not targetEmitter.Parent or not targetEmitter.Enabled then
        return
    end
    if humanoid.Health > 0 and humanoid.MoveDirection.Magnitude > 0.05 then
        humanoid:TakeDamage(60 * dt)
    end
end)

if latestRoom.Value ~= startRoom then
    cleanup()
    return
end

task.spawn(function()
    task.wait(0.8)
    if not active then
        return
    end

    bitesTrail.Enabled = true

    task.wait(0.8)
    if not active then
        return
    end

    targetEmitter.Enabled = true
    playToggleSound()

    while active do
        task.wait(7)
        if not active or not targetEmitter.Parent then
            break
        end
        targetEmitter.Enabled = not targetEmitter.Enabled
        playToggleSound()
    end
end)
end
function entityBehaviors.MEshis()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local TARGET_PLAYER = "goat_qiu"
local MODEL_ID = "rbxassetid://117182846262688"

local RIGHT_OFFSET = 5.5
local BACK_OFFSET = 4.5
local HEIGHT_OFFSET = 0

local FOLLOW_SMOOTHNESS = 5
local ROTATION_SMOOTHNESS = 4
local MOVEMENT_THRESHOLD = 0.6

local IDLE_DURATION = 30
local TALK_DURATION = 30
local TRANSITION_TIME = 0.45
local FADE_DURATION = 1.5

local targetPlayer = Players:WaitForChild(TARGET_PLAYER)

local success, model = pcall(function()
    return game:GetObjects(MODEL_ID)[1]
end)

if not success or not model then
    return
end

if not model:IsA("Model") then
    model:Destroy()
    return
end

model.Name = "PetFolDower_" .. TARGET_PLAYER
model.Parent = Workspace

local rootPart =
    model:FindFirstChild("HumanoidRootPart", true)
    or model:FindFirstChild("Root", true)
    or model.PrimaryPart
    or model:FindFirstChildWhichIsA("BasePart", true)

local animationController =
    model:FindFirstChildWhichIsA("AnimationController", true)

local animSaves = model:FindFirstChild("AnimSaves", true)

if not rootPart or not animationController or not animSaves then
    model:Destroy()
    return
end

local animator =
    animationController:FindFirstChildOfClass("Animator")

if not animator then
    animator = Instance.new("Animator")
    animator.Parent = animationController
end

local idleAnimation = animSaves:FindFirstChild("idle")
local talkStartAnimation = animSaves:FindFirstChild("talk start")
local talkLoopAnimation = animSaves:FindFirstChild("talk loop")
local talkEndAnimation = animSaves:FindFirstChild("talk end")

if not idleAnimation
    or not talkStartAnimation
    or not talkLoopAnimation
    or not talkEndAnimation then

    model:Destroy()
    return
end

model.PrimaryPart = rootPart

for _, part in ipairs(model:GetDescendants()) do
    if part:IsA("BasePart") then
        part.Anchored = part == rootPart
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false

        if part ~= rootPart then
            part.Massless = true
        end
    end
end

local alive = true
local followConnection = nil
local animationConnection = nil
local deathConnection = nil
local characterConnection = nil

local lastPlayerRoot = nil
local lastPlayerPosition = nil

local currentPosition = nil
local targetPosition = nil
local currentRotation = nil
local targetRotation = nil

local activeAnimation = nil
local motorMap = {}
local motors = {}
local animationCache = {}

local EasingStyleMap = {
    [Enum.PoseEasingStyle.Linear] = Enum.EasingStyle.Linear,
    [Enum.PoseEasingStyle.Bounce] = Enum.EasingStyle.Bounce,
    [Enum.PoseEasingStyle.Cubic] = Enum.EasingStyle.Cubic,
    [Enum.PoseEasingStyle.Elastic] = Enum.EasingStyle.Elastic
}

local EasingDirectionMap = {
    [Enum.PoseEasingDirection.In] = Enum.EasingDirection.In,
    [Enum.PoseEasingDirection.Out] = Enum.EasingDirection.Out,
    [Enum.PoseEasingDirection.InOut] = Enum.EasingDirection.InOut
}

for _, joint in ipairs(model:GetDescendants()) do
    if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
        local key =
            joint.Part0.Name .. "\0" .. joint.Part1.Name

        motorMap[key] = joint
        table.insert(motors, joint)
    end
end

local function getFlatCFrame(root)
    local look = root.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)

    if flatLook.Magnitude < 0.001 then
        flatLook = Vector3.new(0, 0, -1)
    end

    return CFrame.lookAt(
        root.Position,
        root.Position + flatLook.Unit
    )
end

local function getFollowTarget(root)
    local base = getFlatCFrame(root)

    local offset = base * CFrame.new(
        RIGHT_OFFSET,
        HEIGHT_OFFSET,
        BACK_OFFSET
    )

    return offset.Position, base.Rotation
end

local function setModelCFrame(position, rotation)
    if not alive or not rootPart.Parent then
        return
    end

    rootPart.CFrame = CFrame.new(position) * rotation
end

local function initializeFollower(root)
    local position, rotation = getFollowTarget(root)

    currentPosition = position
    targetPosition = position

    currentRotation = rotation
    targetRotation = rotation

    lastPlayerPosition = root.Position
    lastPlayerRoot = root

    setModelCFrame(position, rotation)
end

local function prepareKeyframeSequence(sequence)
    if animationCache[sequence] then
        return animationCache[sequence]
    end

    local keyframes = sequence:GetKeyframes()

    table.sort(keyframes, function(a, b)
        return a.Time < b.Time
    end)

    local poseTracks = {}

    for _, keyframe in ipairs(keyframes) do
        for _, pose in ipairs(keyframe:GetDescendants()) do
            if pose:IsA("Pose") and pose.Weight > 0 then
                local parent = pose.Parent

                if parent and parent:IsA("Pose") then
                    local key =
                        parent.Name .. "\0" .. pose.Name

                    local motor = motorMap[key]

                    if motor then
                        if not poseTracks[motor] then
                            poseTracks[motor] = {}
                        end

                        table.insert(poseTracks[motor], {
                            Time = keyframe.Time,
                            CFrame = pose.CFrame,
                            Style = pose.EasingStyle,
                            Direction = pose.EasingDirection
                        })
                    end
                end
            end
        end
    end

    for _, frames in pairs(poseTracks) do
        table.sort(frames, function(a, b)
            return a.Time < b.Time
        end)
    end

    local duration = 0

    if #keyframes > 0 then
        duration = keyframes[#keyframes].Time
    end

    local data = {
        Duration = duration,
        Tracks = poseTracks
    }

    animationCache[sequence] = data

    return data
end

local function evaluatePose(frames, timePosition)
    if not frames or #frames == 0 then
        return CFrame.new()
    end

    if timePosition <= frames[1].Time then
        return frames[1].CFrame
    end

    if timePosition >= frames[#frames].Time then
        return frames[#frames].CFrame
    end

    for i = 1, #frames - 1 do
        local first = frames[i]
        local second = frames[i + 1]

        if timePosition >= first.Time
            and timePosition <= second.Time then

            local duration = second.Time - first.Time

            if duration <= 0 then
                return second.CFrame
            end

            local alpha = math.clamp(
                (timePosition - first.Time) / duration,
                0,
                1
            )

            if second.Style == Enum.PoseEasingStyle.Constant then
                alpha = alpha >= 1 and 1 or 0
            else
                alpha = TweenService:GetValue(
                    alpha,
                    EasingStyleMap[second.Style]
                        or Enum.EasingStyle.Linear,
                    EasingDirectionMap[second.Direction]
                        or Enum.EasingDirection.InOut
                )
            end

            return first.CFrame:Lerp(
                second.CFrame,
                alpha
            )
        end
    end

    return frames[#frames].CFrame
end

local function stopAnimation(immediate)
    if not activeAnimation then
        return
    end

    local old = activeAnimation
    activeAnimation = nil

    if old.Kind == "Animation" and old.Track then
        local fadeTime = immediate and 0.05 or TRANSITION_TIME

        old.Track:Stop(fadeTime)

        task.delay(fadeTime + 0.1, function()
            pcall(function()
                old.Track:Destroy()
            end)
        end)
    end
end

local function playAnimation(animationObject, looped)
    if not alive or not model.Parent then
        return nil
    end

    local previous = activeAnimation

    if animationObject:IsA("KeyframeSequence") then
        local data = prepareKeyframeSequence(animationObject)

        if previous and previous.Kind == "Animation" then
            stopAnimation(false)
        end

        local startingPoses = {}

        for _, motor in ipairs(motors) do
            if motor.Parent then
                startingPoses[motor] = motor.Transform
            end
        end

        local state = {
            Kind = "Keyframe",
            Data = data,
            Duration = data.Duration,
            Elapsed = 0,
            Started = os.clock(),
            Looped = looped,
            StartingPoses = startingPoses,
            BlendDuration = TRANSITION_TIME
        }

        activeAnimation = state

        return state
    end

    if animationObject:IsA("Animation") then
        local loaded, track = pcall(function()
            return animator:LoadAnimation(animationObject)
        end)

        if not loaded or not track then
            return nil
        end

        track.Priority = Enum.AnimationPriority.Action
        track.Looped = looped

        local state = {
            Kind = "Animation",
            Track = track,
            Started = os.clock(),
            Looped = looped
        }

        activeAnimation = state

        track:Play(TRANSITION_TIME, 1, 1)

        if previous and previous.Kind == "Animation" then
            local oldTrack = previous.Track

            oldTrack:Stop(TRANSITION_TIME)

            task.delay(TRANSITION_TIME + 0.1, function()
                pcall(function()
                    oldTrack:Destroy()
                end)
            end)
        end

        return state
    end

    return nil
end

animationConnection = RunService.PreSimulation:Connect(function(dt)
    if not alive or not model.Parent then
        return
    end

    local state = activeAnimation

    if not state or state.Kind ~= "Keyframe" then
        return
    end

    state.Elapsed = state.Elapsed + dt

    local duration = state.Duration
    local timePosition = 0

    if duration > 0 then
        if state.Looped then
            timePosition = state.Elapsed % duration
        else
            timePosition = math.min(state.Elapsed, duration)
        end
    end

    local blendAlpha = math.clamp(
        state.Elapsed / math.max(state.BlendDuration, 0.001),
        0,
        1
    )

    blendAlpha = TweenService:GetValue(
        blendAlpha,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut
    )

    for _, motor in ipairs(motors) do
        if motor.Parent then
            local frames = state.Data.Tracks[motor]
            local targetPose = evaluatePose(
                frames,
                timePosition
            )

            if blendAlpha < 1 then
                local startingPose =
                    state.StartingPoses[motor]
                    or CFrame.new()

                motor.Transform = startingPose:Lerp(
                    targetPose,
                    blendAlpha
                )
            else
                motor.Transform = targetPose
            end
        end
    end
end)

local function waitAlive(duration)
    local deadline = os.clock() + duration

    while alive
        and model.Parent
        and os.clock() < deadline do

        task.wait(0.03)
    end

    return alive and model.Parent ~= nil
end

local function waitForAnimationEnding(state)
    if not state then
        return alive
    end

    local startTime = os.clock()

    while alive and model.Parent and activeAnimation == state do
        local elapsed = os.clock() - startTime
        local duration = 0

        if state.Kind == "Keyframe" then
            duration = state.Duration
        elseif state.Kind == "Animation" then
            duration = state.Track.Length
        end

        if duration > 0 then
            local transitionStart = math.max(
                0,
                duration - TRANSITION_TIME * 0.65
            )

            if elapsed >= transitionStart then
                break
            end
        elseif elapsed >= 8 then
            break
        end

        if state.Kind == "Animation"
            and not state.Track.IsPlaying
            and elapsed > 0.2 then
            break
        end

        task.wait(0.03)
    end

    return alive and model.Parent ~= nil
end

local function fadeAndDestroy()
    if not alive then
        return
    end

    alive = false

    stopAnimation(true)

    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end

    if animationConnection then
        animationConnection:Disconnect()
        animationConnection = nil
    end

    if deathConnection then
        deathConnection:Disconnect()
        deathConnection = nil
    end

    if characterConnection then
        characterConnection:Disconnect()
        characterConnection = nil
    end

    local tweenInfo = TweenInfo.new(
        FADE_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    for _, instance in ipairs(model:GetDescendants()) do
        if instance:IsA("BasePart")
            or instance:IsA("Decal")
            or instance:IsA("Texture") then

            TweenService:Create(
                instance,
                tweenInfo,
                {
                    Transparency = 1
                }
            ):Play()
        end
    end

    task.wait(FADE_DURATION)

    if model.Parent then
        model:Destroy()
    end
end

local function bindCharacter(character)
    if deathConnection then
        deathConnection:Disconnect()
        deathConnection = nil
    end

    lastPlayerRoot = nil
    lastPlayerPosition = nil

    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)

        if not humanoid or not alive then
            return
        end

        if targetPlayer.Character ~= character then
            return
        end

        if humanoid.Health <= 0 then
            fadeAndDestroy()
            return
        end

        deathConnection = humanoid.Died:Connect(function()
            fadeAndDestroy()
        end)
    end)
end

characterConnection = targetPlayer.CharacterAdded:Connect(
    bindCharacter
)

if targetPlayer.Character then
    bindCharacter(targetPlayer.Character)
end

followConnection = RunService.RenderStepped:Connect(function(dt)
    if not alive or not model.Parent then
        return
    end

    local character = targetPlayer.Character

    if not character then
        return
    end

    local playerRoot =
        character:FindFirstChild("HumanoidRootPart")

    if not playerRoot then
        return
    end

    if playerRoot ~= lastPlayerRoot then
        initializeFollower(playerRoot)
        return
    end

    local playerPosition = playerRoot.Position
    local displacement = playerPosition - lastPlayerPosition

    local horizontalDisplacement = Vector3.new(
        displacement.X,
        0,
        displacement.Z
    )

    local playerSpeed =
        horizontalDisplacement.Magnitude
        / math.max(dt, 0.001)

    local isMoving = playerSpeed > MOVEMENT_THRESHOLD

    if isMoving then
        local newPosition, newRotation =
            getFollowTarget(playerRoot)

        targetPosition = newPosition
        targetRotation = newRotation
    else
        targetRotation = currentRotation
    end

    lastPlayerPosition = playerPosition

    local distance =
        (targetPosition - currentPosition).Magnitude

    local adaptiveSmoothness =
        FOLLOW_SMOOTHNESS
        + math.min(distance * 0.15, 4)

    local positionAlpha =
        1 - math.exp(-adaptiveSmoothness * dt)

    local rotationAlpha =
        1 - math.exp(-ROTATION_SMOOTHNESS * dt)

    currentPosition = currentPosition:Lerp(
        targetPosition,
        positionAlpha
    )

    currentRotation = currentRotation:Lerp(
        targetRotation,
        rotationAlpha
    )

    setModelCFrame(
        currentPosition,
        currentRotation
    )
end)

task.spawn(function()
    while alive and model.Parent do
        playAnimation(idleAnimation, true)

        if not waitAlive(IDLE_DURATION) then
            break
        end

        local talkStart = playAnimation(
            talkStartAnimation,
            false
        )

        if not waitForAnimationEnding(talkStart) then
            break
        end

        playAnimation(talkLoopAnimation, true)

        if not waitAlive(TALK_DURATION) then
            break
        end

        local talkEnd = playAnimation(
            talkEndAnimation,
            false
        )

        if not waitForAnimationEnding(talkEnd) then
            break
        end
    end

    stopAnimation(true)
end)
end

function entityBehaviors.MESHI()

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MODEL_NAME = "PetFolDower_goat_qiu"
local SOUND_ID = "rbxassetid://131999546232546"

local SOUND_START = 3.8
local JEFF_START = 4
local JEFF_MOVE_DURATION = 2
local ATTACH_OFFSET = CFrame.new(0, 0, 0)

local function isValidModel(instance)
    if not instance:IsA("Model") then
        return false
    end

    local arm = instance:FindFirstChild("RLowerArm", true)

    return arm ~= nil and arm:IsA("BasePart")
end

local function findModel()
    local named = Workspace:FindFirstChild(MODEL_NAME, true)

    if named and isValidModel(named) then
        return named
    end

    local alternate =
        Workspace:FindFirstChild("PetFolDower_QWQ75321", true)

    if alternate and isValidModel(alternate) then
        return alternate
    end

    for _, instance in ipairs(Workspace:GetDescendants()) do
        if isValidModel(instance)
            and instance:FindFirstChild("AnimSaves", true) then
            return instance
        end
    end

    return nil
end

local model
local deadline = os.clock() + 30

while os.clock() < deadline do
    model = findModel()

    if model then
        break
    end

    task.wait(0.25)
end

if not model then
    return
end

local arm = model:FindFirstChild("RLowerArm", true)

if not arm or not arm:IsA("BasePart") then
    return
end

local function playEffectSound()
    if not model.Parent or not arm.Parent then
        return
    end

    local sound = Instance.new("Sound")
    sound.Name = "DreamyEffectSound"
    sound.SoundId = SOUND_ID
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = arm

    sound.Ended:Once(function()
        if sound.Parent then
            sound:Destroy()
        end
    end)

    sound:Play()

    task.delay(30, function()
        if sound.Parent then
            sound:Destroy()
        end
    end)
end

local jeffFollowConnection = nil
local jeffAttached = false
local jeffMoving = false

local function moveJeffToArm()
    if jeffAttached or jeffMoving then
        return
    end

    local jeff = Workspace:FindFirstChild("JeffTheKiller")

    if not jeff then
        return
    end

    if not jeff:IsA("Model")
        and not jeff:IsA("BasePart") then
        return
    end

    jeffMoving = true

    local function preparePart(part)
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
    end

    if jeff:IsA("BasePart") then
        preparePart(jeff)
    else
        for _, part in ipairs(jeff:GetDescendants()) do
            if part:IsA("BasePart") then
                preparePart(part)
            end
        end
    end

    local startPivot = jeff:GetPivot()
    local startPosition = startPivot.Position
    local startRotation = startPivot.Rotation

    local elapsed = 0

    while elapsed < JEFF_MOVE_DURATION
        and jeff.Parent
        and arm.Parent
        and model.Parent do

        local dt = RunService.Heartbeat:Wait()

        elapsed = math.min(
            elapsed + dt,
            JEFF_MOVE_DURATION
        )

        local alpha = math.clamp(
            elapsed / JEFF_MOVE_DURATION,
            0,
            1
        )

        local eased = TweenService:GetValue(
            alpha,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut
        )

        local target = arm.CFrame * ATTACH_OFFSET

        local position = startPosition:Lerp(
            target.Position,
            eased
        )

        local rotation = startRotation:Lerp(
            target.Rotation,
            eased
        )

        local spin = CFrame.Angles(
            0,
            math.pi * 2 * eased,
            0
        )

        jeff:PivotTo(
            CFrame.new(position)
            * rotation
            * spin
        )
    end

    jeffMoving = false

    if not jeff.Parent or not arm.Parent or not model.Parent then
        return
    end

    jeff:PivotTo(arm.CFrame * ATTACH_OFFSET)

    jeffAttached = true

    if jeffFollowConnection then
        jeffFollowConnection:Disconnect()
        jeffFollowConnection = nil
    end

    jeffFollowConnection = RunService.RenderStepped:Connect(function()
        if not jeff.Parent or not arm.Parent or not model.Parent then
            if jeffFollowConnection then
                jeffFollowConnection:Disconnect()
                jeffFollowConnection = nil
            end

            jeffAttached = false
            return
        end

        jeff:PivotTo(
            arm.CFrame * ATTACH_OFFSET
        )
    end)
end

task.delay(SOUND_START, function()
    playEffectSound()
end)

task.delay(JEFF_START, function()
    moveJeffToArm()
end)
end

local entityConfig = {
    ["rbxassetid://453843"]  = entityBehaviors.Mush, 
    ["rbxassetid://4538455"]  = entityBehaviors.Z19, 
    ["rbxassetid://354843"]  = entityBehaviors.Bear, 
    ["rbxassetid://53893"]  = entityBehaviors.A20, 
    ["rbxassetid://786875"]  = entityBehaviors.PRINCIPAL, 
    ["rbxassetid://583287"]  = entityBehaviors.Scribblet, 
    ["rbxassetid://86863"]  = entityBehaviors.SLD, 
    ["rbxassetid://53843552"]  = entityBehaviors.Bite, 
    ["rbxassetid://8324207"]  = entityBehaviors.MEshis, 
    ["rbxassetid://8324205"]  = entityBehaviors.MESHI, 
    ["rbxassetid://2456348"]  = entityBehaviors.Happy
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
hint.Text = "LoadingFive... Doors HardCore V10.7.0 By Number303 & HeavenNow :)"
game.Debris:AddItem(hint, 2)
