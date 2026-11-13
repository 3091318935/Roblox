if workspace:FindFirstChild("HardcoreOne") then
    return
end
local marker = Instance.new("BoolValue")
marker.Name = "HardcoreOne"
marker.Value = true
marker.Parent = workspace
local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()
local entityBehaviors = {}

function entityBehaviors.ATCHRipper()
 local hardCoreSound = workspace:FindFirstChild("HardCoreSound")
    local backgroundSound = hardCoreSound and hardCoreSound:FindFirstChild("RipperBackgroundSound")
    if backgroundSound and backgroundSound:IsA("Sound") then
        backgroundSound:Stop()
        backgroundSound.TimePosition = 0
        backgroundSound:Play()
    end

    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local targetColor = Color3.fromRGB(255, 93, 93)
    local fadeDuration = 1

    local fadeInfo = TweenInfo.new(
        fadeDuration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local function createFadeTween(object)
        if object:IsA("BasePart") or object:IsA("Light") then
            local tween = TweenService:Create(
                object,
                fadeInfo,
                {
                    Color = targetColor
                }
            )

            tween:Play()
            return tween
        end

        return nil
    end

    local function modifyObjectsWithTween()
        local currentRooms = workspace:FindFirstChild("CurrentRooms")
        if not currentRooms then return end

        local lightsToModify = {}
        local originalColors = {}

        for _, room in ipairs(currentRooms:GetChildren()) do
            if room:IsA("Model") then
                local assets = room:FindFirstChild("Assets")
                if assets then
                    local lightFixtures = assets:FindFirstChild("Light_Fixtures")
                    if lightFixtures then
                        for _, ceilingLight in ipairs(lightFixtures:GetChildren()) do
                            if ceilingLight:IsA("Model") and ceilingLight.Name == "ArchivesCeilingLight" then
                                local neon = ceilingLight:FindFirstChild("Neon")
                                if neon then
                                    table.insert(lightsToModify, neon)
                                    originalColors[neon] = neon.Color

                                    local shadow = neon:FindFirstChild("SurfaceLightShadow")
                                    if shadow then
                                        table.insert(lightsToModify, shadow)
                                        originalColors[shadow] = shadow.Color
                                    end

                                    for _, attachment in ipairs(neon:GetChildren()) do
                                        if attachment:IsA("Attachment") then
                                            for _, child in ipairs(attachment:GetChildren()) do
                                                if child:IsA("PointLight") then
                                                    table.insert(lightsToModify, child)
                                                    originalColors[child] = child.Color
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    for _, floorLamp in ipairs(assets:GetChildren()) do
                        if floorLamp:IsA("Model") and floorLamp.Name == "ArchivesFloorLamp" then
                            local neon = floorLamp:FindFirstChild("Neon")
                            if neon then
                                for _, attachment in ipairs(neon:GetChildren()) do
                                    if attachment:IsA("Attachment") then
                                        for _, child in ipairs(attachment:GetChildren()) do
                                            if child:IsA("SpotLight") or child:IsA("PointLight") then
                                                table.insert(lightsToModify, child)
                                                originalColors[child] = child.Color
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        for _, light in ipairs(lightsToModify) do
            local tween = TweenService:Create(light, TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Color = targetColor})
            tween:Play()
        end

        task.spawn(function()
            task.wait(fadeDuration)

            local forceLoopRunning = true
            local connection = RunService.RenderStepped:Connect(function()
                if not forceLoopRunning then return end
                for _, light in ipairs(lightsToModify) do
                    if light and light.Parent then
                        light.Color = targetColor
                    end
                end
            end)

            task.wait(20)

            forceLoopRunning = false
            connection:Disconnect()

            for _, light in ipairs(lightsToModify) do
                if light and light.Parent then
                    local revertTween = TweenService:Create(light, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Color = originalColors[light]})
                    revertTween:Play()
                end
            end
        end)
    end

    task.spawn(modifyObjectsWithTween)

    local activeRipperTween = nil
    local isJumpScaring = false
    local ripper = nil
    local ripperAsset = nil
    local isRipperDespawning = false

    local function StopRipperMovement()
        if activeRipperTween then
            activeRipperTween:Cancel()
            activeRipperTween = nil
        end
    end

    local function TriggerRipperJumpScare(
        currentRipper,
        playerChar,
        snapshottedRipperPosition
    )
        if isJumpScaring then
            return
        end

        StopRipperMovement()
        isJumpScaring = true
        local currentRipperAsset = ripperAsset

        local player = Players:GetPlayerFromCharacter(playerChar)

        if not player then
            isJumpScaring = false
            return
        end

        local playerGui = player:FindFirstChild("PlayerGui")

        if not playerGui then
            playerGui = player:WaitForChild("PlayerGui", 5)
        end

        local camera = workspace.CurrentCamera
        local rootPart = playerChar:FindFirstChild("HumanoidRootPart")
        local humanoid = playerChar:FindFirstChildWhichIsA("Humanoid")

        if not playerGui or not camera or not rootPart or not humanoid then
            isJumpScaring = false
            return
        end

        local function prepareRipperObject(object)
            if not object then
                return
            end

            local ripe = object:FindFirstChild("ripe", true)

            if ripe then
                local face1 = ripe:FindFirstChild("Face1", true)

                if face1 then
                    if face1:IsA("Decal") or face1:IsA("Texture") then
                        face1.Texture = "rbxassetid://11816152645"
                    elseif face1:IsA("ImageLabel") or face1:IsA("ImageButton") then
                        face1.Image = "rbxassetid://11816152645"
                    end
                end
            end

            for _, desc in ipairs(object:GetDescendants()) do
                if desc:IsA("ParticleEmitter") then
                    desc.Rate = 9999
                    task.delay(0.25, function()
                        if desc and desc.Parent then
                            desc.TimeScale = 0
                        end
                    end)
                elseif desc:IsA("Sound") and string.lower(desc.Name) ~= "jumpscare" then
                    desc.Volume = 0
                end
            end
        end

        local function findJumpscareSound(object)
            if not object then
                return nil
            end

            for _, desc in ipairs(object:GetDescendants()) do
                if desc:IsA("Sound") and string.lower(desc.Name) == "jumpscare" then
                    return desc
                end
            end

            return nil
        end

        local jumpscareSource = findJumpscareSound(currentRipper)
            or findJumpscareSound(currentRipperAsset)
        local modelJumpscareSound = jumpscareSource and jumpscareSource:Clone() or nil

        if modelJumpscareSound then
            for _, desc in ipairs(modelJumpscareSound:GetDescendants()) do
                if desc:IsA("Sound") and string.lower(desc.Name) == "static" then
                    desc:Destroy()
                end
            end
        end

        prepareRipperObject(currentRipper)
        prepareRipperObject(currentRipperAsset)

        if modelJumpscareSound then
            modelJumpscareSound.Looped = false
            modelJumpscareSound.PlayOnRemove = false
            modelJumpscareSound.Parent = workspace
        end

        local noiseGui = Instance.new("ScreenGui")
        noiseGui.Name = "Noise"
        noiseGui.IgnoreGuiInset = true
        noiseGui.ResetOnSpawn = false
        noiseGui.Parent = playerGui

        local staticImg = Instance.new("ImageLabel")
        staticImg.Name = "ImageLabel"
        staticImg.BackgroundTransparency = 1
        staticImg.Size = UDim2.new(1, 0, 1, 0)
        staticImg.Image = "rbxassetid://236542974"
        staticImg.ImageTransparency = 1
        staticImg.Parent = noiseGui

        local images = {
            8482795900,
            236542974,
            184251462,
            236777652
        }

        local noiseConnection = RunService.RenderStepped:Connect(function()
            if staticImg and staticImg.Parent then
                staticImg.Image = "rbxassetid://" .. tostring(images[math.random(1, #images)])
            end
        end)

        local screamSound = Instance.new("Sound")
        screamSound.SoundId = "rbxassetid://372770465"
        screamSound.Volume = 0
        screamSound.PlaybackSpeed = 0.7
        screamSound.Parent = workspace

        local cameraShakerModule = game.ReplicatedStorage:FindFirstChild("CameraShaker")

        if cameraShakerModule then
            local success, CameraShaker = pcall(require, cameraShakerModule)

            if success and CameraShaker then
                local jumpScareCamShake = CameraShaker.new(
                    Enum.RenderPriority.Camera.Value,
                    function(shakeCf)
                        if camera then
                            camera.CFrame = camera.CFrame * shakeCf
                        end
                    end
                )

                jumpScareCamShake:Start()
                jumpScareCamShake:ShakeOnce(8, 26, 0.03, 0.28, 0.3, 0.35)
                task.delay(1, function()
                    pcall(function()
                        jumpScareCamShake:Stop()
                    end)
                end)
            end
        end

        rootPart.Anchored = true

        local originalCameraType = camera.CameraType
        camera.CameraType = Enum.CameraType.Scriptable

        local targetPart = Instance.new("Part")
        targetPart.Transparency = 1
        targetPart.CanCollide = false
        targetPart.CanTouch = false
        targetPart.CanQuery = false
        targetPart.Anchored = true
        targetPart.Position = snapshottedRipperPosition
        targetPart.Parent = workspace

        local camFocus = Instance.new("Part")
        camFocus.Transparency = 1
        camFocus.CanCollide = false
        camFocus.CanTouch = false
        camFocus.CanQuery = false
        camFocus.Anchored = true
        camFocus.CFrame = camera.CFrame
        camFocus.Parent = workspace

        local turnTween = TweenService:Create(
            camFocus,
            TweenInfo.new(
                0.69,
                Enum.EasingStyle.Circular,
                Enum.EasingDirection.InOut
            ),
            {
                CFrame = CFrame.lookAt(
                    camFocus.Position,
                    targetPart.Position
                )
            }
        )

        local renderConnection

        renderConnection = RunService.RenderStepped:Connect(function()
            if camFocus and camFocus.Parent and camera then
                camera.CFrame = camFocus.CFrame
            elseif renderConnection then
                renderConnection:Disconnect()
            end
        end)

        turnTween:Play()
        turnTween.Completed:Wait()
        task.wait(0.3)

        if modelJumpscareSound and modelJumpscareSound.Parent then
            modelJumpscareSound:Play()
        end

        if modelJumpscareSound and modelJumpscareSound.Parent then
            local soundStartedAt = os.clock()

            repeat
                RunService.Heartbeat:Wait()
            until (os.clock() - soundStartedAt >= 0.25 and not modelJumpscareSound.IsPlaying)
                or os.clock() - soundStartedAt >= 6
        end

        screamSound:Play()

        TweenService:Create(
            screamSound,
            TweenInfo.new(3),
            {
                Volume = 10
            }
        ):Play()

        task.wait(1)

        TweenService:Create(
            staticImg,
            TweenInfo.new(2),
            {
                ImageTransparency = 0
            }
        ):Play()

        task.wait(3)

        if rootPart and rootPart.Parent then
            rootPart.Anchored = false
        end

        if humanoid and humanoid.Parent and humanoid.Health > 0 then
            local damage = 125
            if humanoid.Health <= damage then
                local gameStats = game.ReplicatedStorage:FindFirstChild("GameStats")
                local playerStat = gameStats and gameStats:FindFirstChild("Player_" .. player.Name)
                local total = playerStat and playerStat:FindFirstChild("Total")
                local deathCause = total and total:FindFirstChild("DeathCause")
                if deathCause then
                    deathCause.Value = "Ripper"
                end
            end
            humanoid:TakeDamage(damage)
        end

        TweenService:Create(
            staticImg,
            TweenInfo.new(1),
            {
                ImageTransparency = 1
            }
        ):Play()

        TweenService:Create(
            screamSound,
            TweenInfo.new(1),
            {
                Volume = 0
            }
        ):Play()

        if renderConnection then
            renderConnection:Disconnect()
        end

        if noiseConnection then
            noiseConnection:Disconnect()
        end

        if camera then
            camera.CameraType = originalCameraType
        end

        if noiseGui then
            noiseGui:Destroy()
        end

        if targetPart then
            targetPart:Destroy()
        end

        if camFocus then
            camFocus:Destroy()
        end

        if screamSound then
            screamSound:Destroy()
        end

        if modelJumpscareSound then
            modelJumpscareSound:Destroy()
        end

        if currentRipper and currentRipper.Parent then
            currentRipper:Destroy()
        end

        if currentRipperAsset then
            currentRipperAsset:Destroy()
        end

        ripper = nil
        ripperAsset = nil
        isRipperDespawning = true

    end

    local function getOrderedRooms()
        local currentRooms =
            workspace:FindFirstChild("CurrentRooms")

        local orderedRooms = {}

        if not currentRooms then
            return orderedRooms
        end

        for _, room in ipairs(currentRooms:GetChildren()) do
            if room:IsA("Model") then
                local roomNumber = tonumber(room.Name)

                if roomNumber then
                    table.insert(
                        orderedRooms,
                        {
                            Number = roomNumber,
                            Room = room
                        }
                    )
                end
            end
        end

        table.sort(
            orderedRooms,
            function(a, b)
                return a.Number < b.Number
            end
        )

        return orderedRooms
    end

    local function getOrderedNodes(pathfindNodes)
        local orderedNodes = {}

        for _, node in ipairs(
            pathfindNodes:GetChildren()
        ) do
            if node:IsA("BasePart") then
                table.insert(orderedNodes, node)
            end
        end

        table.sort(
            orderedNodes,
            function(a, b)
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
            end
        )

        return orderedNodes
    end

    local function moveRipperTo(
        targetCFrame,
        speedFactor
    )
        if isJumpScaring
            or not ripper
            or not ripper.Parent
        then
            return false
        end

        local distance = (
            ripper.Position - targetCFrame.Position
        ).Magnitude

        local duration =
            math.max(distance / speedFactor, 0.01)

        local tween = TweenService:Create(
            ripper,
            TweenInfo.new(
                duration,
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.InOut
            ),
            {
                CFrame = targetCFrame
            }
        )

        activeRipperTween = tween
        tween:Play()

        local playbackState =
            tween.Completed:Wait()

        if activeRipperTween == tween then
            activeRipperTween = nil
        end

        return playbackState
                == Enum.PlaybackState.Completed
            and not isJumpScaring
            and ripper
            and ripper.Parent ~= nil
    end

    local function ExecuteRipperPathfinding()
        isRipperDespawning = false
        local RIPPER_MODEL_ID = "107119131634727"

        local success, loadedAsset = pcall(function()
            return game:GetObjects(
                "rbxassetid://" .. RIPPER_MODEL_ID
            )[1]
        end)

        if not success or not loadedAsset then
            ripperAsset = nil
            return
        end

        ripperAsset = loadedAsset

        local basePart =
            ripperAsset:FindFirstChildWhichIsA(
                "BasePart",
                true
            )

        if not basePart then
            ripperAsset:Destroy()
            ripperAsset = nil
            return
        end

        ripper = basePart:Clone()
        ripper.Anchored = true
        ripper.CanQuery = true
        ripper.Parent = workspace

        local orderedRooms = getOrderedRooms()

        if #orderedRooms == 0 then
            ripper:Destroy()
            ripper = nil
            ripperAsset:Destroy()
            ripperAsset = nil
            return
        end

        local MAX_RIPPER_ROOMS = 10
        local startRoomIndex = 1

        if #orderedRooms > MAX_RIPPER_ROOMS then
            startRoomIndex = #orderedRooms - 8
        end

        local startRoom = orderedRooms[startRoomIndex].Room
        local startNode = nil
        local startPathfindNodes =
            startRoom:FindFirstChild("PathfindNodes")

        if startPathfindNodes then
            local startNodes =
                getOrderedNodes(startPathfindNodes)

            startNode = startNodes[1]
        end

        if not startNode then
            startNode =
                startRoom:FindFirstChild("RoomExit")
        end

        if not startNode
            or not startNode:IsA("BasePart")
        then
            ripper:Destroy()
            ripper = nil
            ripperAsset:Destroy()
            ripperAsset = nil
            return
        end

        local heightOffset = Vector3.new(0, -0.3, 0)
        local speedFactor = 100

        ripper.CFrame =
            startNode.CFrame + heightOffset

        local cameraShaker = nil
        local cameraShakerModule =
            game.ReplicatedStorage:FindFirstChild(
                "CameraShaker"
            )

        if cameraShakerModule then
            local loaded, CameraShakerModule = pcall(require, cameraShakerModule)

            if loaded and CameraShakerModule then
                cameraShaker = CameraShakerModule.new(
                    Enum.RenderPriority.Camera.Value + 1,
                    function(shakerTransform)
                        local camera = workspace.CurrentCamera

                        if camera then
                            camera.CFrame = camera.CFrame * shakerTransform
                        end
                    end
                )

                cameraShaker:Start()
            end
        end

        local lastProximityShake = 0

        task.spawn(function()
            while ripper
                and ripper.Parent
                and not isJumpScaring
                and not isRipperDespawning
            do
                RunService.RenderStepped:Wait()
                if not ripper or not ripper.Parent or isJumpScaring or isRipperDespawning then
                    break
                end

                local player = Players.LocalPlayer

                if player and player.Character then
                    local character = player.Character
                    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                    local rootPart = character:FindFirstChild("HumanoidRootPart")

                    if humanoid and rootPart and humanoid.Health > 0 then
                        local distance = (ripper.Position - rootPart.Position).Magnitude

                        if distance <= 80
                            and cameraShaker
                            and os.clock() - lastProximityShake >= 0.12
                        then
                            local alpha = math.clamp(1 - distance / 80, 0, 1)
                            local amplitude = (0.3 + 8.2 * (alpha ^ 1.35)) * 3
                            local roughness = 45 + 35 * alpha
                            local positionInfluence = 0.35 + 0.4 * alpha
                            local rotationInfluence = 0.3 + 0.4 * alpha

                            cameraShaker:ShakeOnce(
                                amplitude,
                                roughness,
                                0.01,
                                0.16,
                                positionInfluence,
                                rotationInfluence
                            )

                            lastProximityShake = os.clock()
                        end

                        if not character:GetAttribute("Hiding") then
                            local camera = workspace.CurrentCamera

                            if camera then
                                local toRipper = ripper.Position - camera.CFrame.Position
                                local cameraDistance = toRipper.Magnitude

                                if cameraDistance > 0 then
                                    local lookDot = camera.CFrame.LookVector:Dot(toRipper.Unit)
                                    local raycastParams = RaycastParams.new()
                                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                    raycastParams.FilterDescendantsInstances = { character }

                                    local raycastResult = workspace:Raycast(
                                        camera.CFrame.Position,
                                        toRipper,
                                        raycastParams
                                    )

                                    local hitRipper = raycastResult
                                        and raycastResult.Instance
                                        and (
                                            raycastResult.Instance == ripper
                                            or raycastResult.Instance:IsDescendantOf(ripper)
                                        )

                                    if distance <= 50
                                        and lookDot >= 0.86
                                        and hitRipper
                                    then
                                        TriggerRipperJumpScare(
                                            ripper,
                                            character,
                                            ripper.Position
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if cameraShaker then
                pcall(function()
                    cameraShaker:Stop()
                end)
            end
        end)

        local targetRoomIndex =
            math.max(1, #orderedRooms - 1)

        local reachedFinalRoom = false
        local completedRoomIndex = 0

        for roomIndex = startRoomIndex, targetRoomIndex do
            if isJumpScaring
                or not ripper
                or not ripper.Parent
            then
                break
            end

            local roomData =
                orderedRooms[roomIndex]

            local room =
                roomData and roomData.Room

            if not room or not room.Parent then
                local refreshDeadline =
                    os.clock() + 5

                repeat
                    task.wait(0.1)

                    orderedRooms =
                        getOrderedRooms()

                    roomData =
                        orderedRooms[roomIndex]

                    room =
                        roomData and roomData.Room
                until room
                    or os.clock()
                        >= refreshDeadline
                    or isJumpScaring
                    or not ripper
                    or not ripper.Parent
            end

            if not room or not room.Parent then
                break
            end

            local roomCompleted = false
            local pathfindNodes =
                room:FindFirstChild(
                    "PathfindNodes"
                )

            if pathfindNodes then
                local orderedNodes =
                    getOrderedNodes(
                        pathfindNodes
                    )

                if #orderedNodes > 0 then
                    roomCompleted = true

                    for _, node in ipairs(
                        orderedNodes
                    ) do
                        if isJumpScaring
                            or not ripper
                            or not ripper.Parent
                        then
                            roomCompleted = false
                            break
                        end

                        local moved =
                            moveRipperTo(
                                node.CFrame
                                    + heightOffset,
                                speedFactor
                            )

                        if not moved then
                            roomCompleted = false
                            break
                        end
                    end
                end
            end

            if not roomCompleted then
                local roomExit =
                    room:FindFirstChild(
                        "RoomExit"
                    )

                if roomExit
                    and roomExit:IsA(
                        "BasePart"
                    )
                then
                    roomCompleted =
                        moveRipperTo(
                            roomExit.CFrame
                                + heightOffset,
                            speedFactor
                        )
                end
            end

            if not roomCompleted then
                break
            end

            completedRoomIndex = roomIndex

            if roomIndex
                == targetRoomIndex
            then
                reachedFinalRoom = true
            end
        end

        activeRipperTween = nil

        if isJumpScaring
            or not ripper
            or not ripper.Parent
        then
            ripper = nil
            ripperAsset = nil
            return
        end

        if isJumpScaring then
            return
        end

        if not reachedFinalRoom
            or completedRoomIndex
                < targetRoomIndex
        then
            if ripper and ripper.Parent then
                ripper:Destroy()
            end

            if ripperAsset then
                ripperAsset:Destroy()
            end

            ripper = nil
            ripperAsset = nil
            return
        end

        isRipperDespawning = true
        local NEAR_EXPLOSION_DISTANCE = 80
        local FAR_EXPLOSION_DISTANCE = 220
        local SHAKE_MAX_DISTANCE = 350
        local MAX_EXPLOSION_SHAKE = 24

        local localPlayer = Players.LocalPlayer
        local playerRoot = nil

        if localPlayer and localPlayer.Character then
            playerRoot =
                localPlayer.Character:FindFirstChild(
                    "HumanoidRootPart"
                )
        end

        local ripperDistance = math.huge

        if playerRoot and ripper and ripper.Parent then
            ripperDistance =
                (
                    playerRoot.Position
                    - ripper.Position
                ).Magnitude
        end

        local rushNew = nil

        if ripper and ripper.Parent then
            if ripper.Name == "RushNew" then
                rushNew = ripper
            else
                rushNew =
                    ripper:FindFirstChild(
                        "RushNew",
                        true
                    )
            end
        end

        if not rushNew
            and ripperAsset
        then
            rushNew =
                ripperAsset:FindFirstChild(
                    "RushNew",
                    true
                )
        end

        local explodeSound = nil

        if ripperDistance
            <= NEAR_EXPLOSION_DISTANCE
        then
            local explosionSound =
                hardCoreSound and hardCoreSound:FindFirstChild("RipperExplosionSound")

            if explosionSound
                and explosionSound:IsA("Sound")
            then
                explodeSound = Instance.new("Sound")
                explodeSound.SoundId =
                    explosionSound.SoundId
                explodeSound.Volume = 5
                explodeSound.PlaybackSpeed =
                    explosionSound.PlaybackSpeed
                explodeSound.Parent = ripper
            end
        elseif ripperDistance
            <= FAR_EXPLOSION_DISTANCE
        then
            local despawn2 =
                rushNew
                and rushNew:FindFirstChild(
                    "Despawn2"
                )

            if despawn2
                and despawn2:IsA("Sound")
            then
                explodeSound = despawn2:Clone()
                explodeSound.Volume = 10
                explodeSound.Parent = ripper
            end
        else
            local despawn3 =
                rushNew
                and rushNew:FindFirstChild(
                    "Despawn3"
                )

            if despawn3
                and despawn3:IsA("Sound")
            then
                explodeSound = despawn3:Clone()
                explodeSound.Volume = 10
                explodeSound.Parent = ripper
            end
        end

        if not explodeSound then
            local explosionSound =
                hardCoreSound and hardCoreSound:FindFirstChild("RipperExplosionSound")

            if explosionSound
                and explosionSound:IsA("Sound")
            then
                explodeSound = Instance.new("Sound")
                explodeSound.SoundId =
                    explosionSound.SoundId
                explodeSound.Volume = 5
                explodeSound.PlaybackSpeed =
                    explosionSound.PlaybackSpeed
                explodeSound.Parent = ripper
            end
        end

        if explodeSound then
            explodeSound:Play()
        end

        local shakeAmplitude = 0

        if ripperDistance
            <= NEAR_EXPLOSION_DISTANCE
        then
            shakeAmplitude = MAX_EXPLOSION_SHAKE
        elseif ripperDistance
            < SHAKE_MAX_DISTANCE
        then
            local alpha =
                1
                - (
                    ripperDistance
                    - NEAR_EXPLOSION_DISTANCE
                )
                / (
                    SHAKE_MAX_DISTANCE
                    - NEAR_EXPLOSION_DISTANCE
                )

            shakeAmplitude =
                MAX_EXPLOSION_SHAKE
                * math.clamp(alpha, 0, 1)
        end

        if cameraShakerModule
            and shakeAmplitude > 0
        then
            local endExplosionCameraShaker =
                require(cameraShakerModule)

            local endExplosionCam =
                workspace.CurrentCamera

            local endExplosionCamShake =
                endExplosionCameraShaker.new(
                    Enum.RenderPriority.Camera.Value,
                    function(shakeCf)
                        if endExplosionCam then
                            endExplosionCam.CFrame =
                                endExplosionCam.CFrame
                                * shakeCf
                        end
                    end
                )

            endExplosionCamShake:Start()

            endExplosionCamShake:ShakeOnce(
                shakeAmplitude,
                28,
                0.03,
                0.4,
                0.25,
                0.35
            )
            task.delay(1, function()
                pcall(function()
                    endExplosionCamShake:Stop()
                end)
            end)
        end

        task.wait(1)

        local finalRipperPosition = nil

        if ripper and ripper.Parent then
            finalRipperPosition = ripper.Position
            ripper.Anchored = false
            ripper.CanCollide = false
            ripper.CanTouch = false
            ripper.CanQuery = false
        end

        if isJumpScaring or not ripper or not ripper.Parent then
            return
        end

        local player = Players.LocalPlayer

        if player and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")

            if humanoid
                and humanoid.Health > 0
                and not character:GetAttribute("Hiding")
                and finalRipperPosition
            then
                TriggerRipperJumpScare(
                    ripper,
                    character,
                    finalRipperPosition
                )
                return
            end
        end

        local fallingRipper = ripper
        local fallingAsset = ripperAsset
        ripperAsset = nil

        task.delay(10, function()
            if fallingRipper and fallingRipper.Parent then
                fallingRipper:Destroy()
            end

            if fallingAsset then
                fallingAsset:Destroy()
            end

            if ripper == fallingRipper then
                ripper = nil
            end

            if ripperAsset == fallingAsset then
                ripperAsset = nil
            end
        end)
    end

    task.spawn(function()
        task.wait(7)
        ExecuteRipperPathfinding()
    end)

    local function runFinalCameraShake()
        local cameraShakerModule =
            game.ReplicatedStorage:FindFirstChild(
                "CameraShaker"
            )

        if not cameraShakerModule then
            return
        end

        local CameraShaker =
            require(cameraShakerModule)

        local camera =
            workspace.CurrentCamera

        local camShake =
            CameraShaker.new(
                Enum.RenderPriority.Camera.Value,
                function(shakeCf)
                    if camera then
                        camera.CFrame =
                            camera.CFrame
                            * shakeCf
                    end
                end
            )

        camShake:Start()

        camShake:ShakeOnce(
            10,
            200,
            0.1,
            6,
            2,
            0.5
        )
        task.delay(7, function()
            pcall(function()
                camShake:Stop()
            end)
        end)
    end
    runFinalCameraShake()
end

function entityBehaviors.A200()
local entity = spawner.Create({Entity = {Name = "A-200",Asset = "125138842800011",HeightOffset = 1},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,
Values = {1.5, 1, 0.1, 1}},Movement = {Speed = 60,Delay = 5,Reversed = true},Rebounding = {Enabled = false,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 100,Amount = 1},Crucifixion = {Enabled = true,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于A-200", "竖起耳朵仔细辨别是一个麻烦", "但你不得不这么做", "你或许会在寂静那学到点什么"},Cause = ""}})
entity:SetCallback("OnRebounding", function(startOfRebound)
	local entityModel = entity.Model
	local main = entityModel:WaitForChild("Main")
	local attachment = main:WaitForChild("Attachment")
	local AttachmentSwitch = main:WaitForChild("AttachmentSwitch")
	local sounds = {
		footsteps = main:WaitForChild("Footsteps"),
		playSound = main:WaitForChild("PlaySound"),
		switch = main:WaitForChild("Switch"),
		switchBack = main:WaitForChild("SwitchBack")
	}

	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end

	if startOfRebound == true then
		sounds.footsteps.PlaybackSpeed = 0.35
		sounds.playSound.PlaybackSpeed = 0.25
		sounds.switch:Play()
	else
		sounds.footsteps.PlaybackSpeed = 0.25
		sounds.playSound.PlaybackSpeed = 0.16
		sounds.switchBack:Play()
	end
end)
entity:Run()
local sound = Instance.new("Sound")
sound.Name = "A200"  
sound.SoundId = "rbxassetid://2306939610"
sound.Volume = 0.1
sound.Looped = true
sound.Parent = workspace
sound:Play()
task.wait(10)
sound:Stop()
sound:Destroy()
end


function entityBehaviors.AMIN60()
local entity = spawner.Create({Entity = {Name = "Amin-60",Asset = "134290844453819",HeightOffset = 0.8},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = true,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 400,Delay = 6.5,Reversed = false},Rebounding = {Enabled = true,Type = "ambush",Min = 10,Max = 10,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 100,Amount = 125},Crucifixion = {Enabled = true,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于Amin-60", "极大的嘈杂声会掩盖其他声音", "他比A60更加迅速敏捷", "仔细听取木板碎裂的声音"},Cause = ""}})
entity:SetCallback("OnRebounding", function(startOfRebound)

	local entityModel = entity.Model
	local main = entityModel:WaitForChild("Main")
	local attachment = main:WaitForChild("Attachment")
	local AttachmentSwitch = main:WaitForChild("AttachmentSwitch")
	local sounds = {
		footsteps = main:WaitForChild("Footsteps"),
		playSound = main:WaitForChild("PlaySound"),
		switch = main:WaitForChild("Switch"),
		switchBack = main:WaitForChild("SwitchBack")
	}
	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end
	if startOfRebound == true then
		sounds.footsteps.PlaybackSpeed = 0.35
		sounds.playSound.PlaybackSpeed = 0.25
		sounds.switch:Play()
	else
		sounds.footsteps.PlaybackSpeed = 0.25
		sounds.playSound.PlaybackSpeed = 0.16
		sounds.switchBack:Play()
	end
	
end)
entity:Run()
end
function entityBehaviors.Black60()
local entity = spawner.Create({Entity = {Name = "Black-A60",Asset = "96102326082560",HeightOffset = 0},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = true,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 350,Delay = 6.5,Reversed = false},Rebounding = {Enabled = true,Type = "ambush",Min = 10,Max = 10,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 100,Amount = 125},Crucifixion = {Enabled = true,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于BlackA60", "极大的嘈杂声会掩盖其他声音", "在不妥时使用十字架会更方便", "反复进柜子躲避它"},Cause = ""}})
entity:SetCallback("OnRebounding", function(startOfRebound)
	local entityModel = entity.Model
	local main = entityModel:WaitForChild("Main")
	local attachment = main:WaitForChild("Attachment")
	local AttachmentSwitch = main:WaitForChild("AttachmentSwitch")
	local sounds = {
		footsteps = main:WaitForChild("Footsteps"),
		playSound = main:WaitForChild("PlaySound"),
		switch = main:WaitForChild("Switch"),
		switchBack = main:WaitForChild("SwitchBack")
	}

	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end

	if startOfRebound == true then
		sounds.footsteps.PlaybackSpeed = 0.35
		sounds.playSound.PlaybackSpeed = 0.25
		sounds.switch:Play()
	else
		sounds.footsteps.PlaybackSpeed = 0.25
		sounds.playSound.PlaybackSpeed = 0.16
		sounds.switchBack:Play()
	end
end)
entity:Run()
end
function entityBehaviors.INGODONE()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local MODEL_ID = 107995387840479
local LOOP_SOUND_ID = 139459003161851
local END_SOUND_ID = 101395573137763
local SPECTATOR_SOUND_ID = 9041745062

local FOLLOW_TIME = 5
local TOTAL_TIME = 54
local FADE_OUT_TIME = 3

local START_SAN = 100
local SAN_LOSS_PER_SECOND = 3

local ROOM_SAN_GAIN = 8

local MONSTER_DISTANCE = 13
local MONSTER_HEIGHT_OFFSET = -1.5

local LOOP_VOLUME = 5
local END_VOLUME = 1
local SPECTATOR_VOLUME = 1

local active = false
local ending = false
local currentSan = START_SAN
local sanityDeathTriggered = false

local RENDER_NAME = "UNNAMEABLE_CAMERA_" .. tostring(player.UserId)

local function isDeadOrSpectating()
	if player:GetAttribute("Spectating") == true then
		return true
	end

	if player:GetAttribute("Alive") == false then
		return true
	end

	local character = player.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid and humanoid.Health <= 0 then
			return true
		end
	end

	return false
end

local function playSpectatorSound()
	local sound = Instance.new("Sound")
	sound.Name = "IndescribableSpectator"
	sound.SoundId = "rbxassetid://" .. SPECTATOR_SOUND_ID
	sound.Volume = SPECTATOR_VOLUME
	sound.Looped = false
	sound.Parent = SoundService

	sound.Ended:Connect(function()
		if sound.Parent then
			sound:Destroy()
		end
	end)

	sound:Play()
end

local function createLoopSound()
	local sound = Instance.new("Sound")
	sound.Name = "UnnameableLoop"
	sound.SoundId = "rbxassetid://" .. LOOP_SOUND_ID
	sound.Volume = LOOP_VOLUME
	sound.Looped = true
	sound.Parent = SoundService
	sound:Play()

	return sound
end

local function playEndingSound()
	local sound = Instance.new("Sound")
	sound.Name = "UnnameableEnding"
	sound.SoundId = "rbxassetid://" .. END_SOUND_ID
	sound.Volume = END_VOLUME
	sound.Looped = false
	sound.Parent = SoundService

	sound.Ended:Connect(function()
		if sound.Parent then
			sound:Destroy()
		end
	end)

	sound:Play()
end

local function createSanUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "UnnameableSAN"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.Parent = player:WaitForChild("PlayerGui")

	local veil = Instance.new("Frame")
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = Color3.fromRGB(175, 190, 225)
	veil.BackgroundTransparency = 0.99
	veil.BorderSizePixel = 0
	veil.ZIndex = 0
	veil.Parent = gui

	local ghostA = Instance.new("Frame")
	ghostA.Size = UDim2.new(1.1, 0, 1.1, 0)
	ghostA.AnchorPoint = Vector2.new(0.5, 0.5)
	ghostA.Position = UDim2.fromScale(0.5, 0.5)
	ghostA.BackgroundColor3 = Color3.fromRGB(125, 160, 235)
	ghostA.BackgroundTransparency = 0.997
	ghostA.BorderSizePixel = 0
	ghostA.ZIndex = 1
	ghostA.Parent = gui

	local ghostB = Instance.new("Frame")
	ghostB.Size = UDim2.new(1.1, 0, 1.1, 0)
	ghostB.AnchorPoint = Vector2.new(0.5, 0.5)
	ghostB.Position = UDim2.fromScale(0.5, 0.5)
	ghostB.BackgroundColor3 = Color3.fromRGB(235, 135, 175)
	ghostB.BackgroundTransparency = 0.998
	ghostB.BorderSizePixel = 0
	ghostB.ZIndex = 2
	ghostB.Parent = gui

	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(1, 0.5)
	holder.Position = UDim2.new(1, 220, 0.5, 0)
	holder.Size = UDim2.fromOffset(190, 65)
	holder.BackgroundColor3 = Color3.fromRGB(4, 4, 7)
	holder.BackgroundTransparency = 0.15
	holder.BorderSizePixel = 0
	holder.ZIndex = 10
	holder.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = holder

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(110, 115, 130)
	stroke.Transparency = 0.35
	stroke.Thickness = 1
	stroke.Parent = holder

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(12, 5)
	title.Size = UDim2.new(1, -24, 0, 22)
	title.Font = Enum.Font.GothamMedium
	title.Text = "SAN"
	title.TextColor3 = Color3.fromRGB(190, 190, 200)
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 11
	title.Parent = holder

	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Position = UDim2.fromOffset(12, 25)
	value.Size = UDim2.new(1, -24, 0, 29)
	value.Font = Enum.Font.GothamBold
	value.Text = "100%"
	value.TextColor3 = Color3.fromRGB(235, 235, 240)
	value.TextSize = 23
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.ZIndex = 11
	value.Parent = holder

	local barBG = Instance.new("Frame")
	barBG.Position = UDim2.new(0, 12, 1, -7)
	barBG.Size = UDim2.new(1, -24, 0, 2)
	barBG.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	barBG.BorderSizePixel = 0
	barBG.ZIndex = 11
	barBG.Parent = holder

	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = Color3.fromRGB(205, 210, 220)
	bar.BorderSizePixel = 0
	bar.ZIndex = 12
	bar.Parent = barBG

	TweenService:Create(
		holder,
		TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Position = UDim2.new(1, -35, 0.5, 0)
		}
	):Play()

	return {
		gui = gui,
		holder = holder,
		label = value,
		bar = bar,
		veil = veil,
		ghostA = ghostA,
		ghostB = ghostB
	}
end

local function createEffects()
	local blur = Instance.new("BlurEffect")
	blur.Name = "UnnameableBlur"
	blur.Size = 4
	blur.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "UnnameableColor"
	color.Brightness = 0
	color.Contrast = 0
	color.Saturation = 0
	color.TintColor = Color3.new(1, 1, 1)
	color.Parent = Lighting

	local monochrome = Instance.new("ColorCorrectionEffect")
	monochrome.Name = "UnnameableMonochrome"
	monochrome.Brightness = 0
	monochrome.Contrast = 0
	monochrome.Saturation = 0
	monochrome.TintColor = Color3.new(1, 1, 1)
	monochrome.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "UnnameableBloom"
	bloom.Intensity = 0
	bloom.Size = 36
	bloom.Threshold = 0.65
	bloom.Parent = Lighting

	local depth = Instance.new("DepthOfFieldEffect")
	depth.Name = "UnnameableDepth"
	depth.FarIntensity = 0
	depth.NearIntensity = 0
	depth.FocusDistance = 12
	depth.InFocusRadius = 8
	depth.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "UnnameableRays"
	rays.Intensity = 0
	rays.Spread = 1
	rays.Parent = Lighting

	return {
		blur = blur,
		color = color,
		monochrome = monochrome,
		bloom = bloom,
		depth = depth,
		rays = rays
	}
end

local function loadMonster()
	local success, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. MODEL_ID)
	end)

	if not success or not objects or not objects[1] then
		return nil
	end

	local monster = objects[1]
	monster.Name = "不可名状"
	monster.Parent = workspace

	if monster:IsA("BasePart") then
		monster.Anchored = true
		monster.CanCollide = false
		monster.CanTouch = false
		monster.CanQuery = false
	end

	for _, object in ipairs(monster:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
		end
	end

	return monster
end

local function setMonsterCFrame(monster, cf)
	if not monster then
		return
	end

	if monster:IsA("Model") then
		monster:PivotTo(cf)
	elseif monster:IsA("BasePart") then
		monster.CFrame = cf
	end
end

local function fadeMonster(monster, duration)
	if not monster then
		return
	end

	if monster:IsA("BasePart") then
		TweenService:Create(
			monster,
			TweenInfo.new(duration),
			{
				Transparency = 1
			}
		):Play()
	end

	for _, object in ipairs(monster:GetDescendants()) do
		if object:IsA("BasePart") then
			TweenService:Create(
				object,
				TweenInfo.new(duration),
				{
					Transparency = 1
				}
			):Play()
		elseif object:IsA("Decal") or object:IsA("Texture") then
			TweenService:Create(
				object,
				TweenInfo.new(duration),
				{
					Transparency = 1
				}
			):Play()
		end
	end
end

local function updateSanDisplay(san, ui)
	san = math.clamp(san, 0, 100)

	if ui.label then
		ui.label.Text = math.floor(san) .. "%"
	end

	if ui.bar then
		TweenService:Create(
			ui.bar,
			TweenInfo.new(0.22, Enum.EasingStyle.Sine),
			{
				Size = UDim2.fromScale(san / 100, 1)
			}
		):Play()
	end
end

local function giveAchievement()
	task.spawn(function()
		pcall(function()
			local DoorsNotify = loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/Guestly-Alt/Scripts/refs/heads/main/AchievementHolder.lua"
				)
			)()

			DoorsNotify({
				Style = "Completed!",
				Title = "Indescribable",
				Description = "A strange dream...",
				Reason = "Survive In Indescribable",
				Image = "rbxassetid://8178415737",
				Time = 5
			})
		end)
	end)
end

local function startUnnameable()
	if isDeadOrSpectating() then
		playSpectatorSound()
		return
	end

	if active or ending then
		return
	end

	active = true
	ending = false
	sanityDeathTriggered = false
	currentSan = START_SAN

	camera = workspace.CurrentCamera

	local eventStartTime = os.clock()
	local originalFOV = camera and camera.FieldOfView or 70

	local loopSound = createLoopSound()
	local monster = loadMonster()

	if not monster then
		active = false

		if loopSound then
			loopSound:Stop()
			loopSound:Destroy()
		end

		return
	end

	local ui = createSanUI()
	local effects = createEffects()

	local fadeValue = Instance.new("NumberValue")
	fadeValue.Value = 1

	local latestRoom = ReplicatedStorage
		:WaitForChild("GameData")
		:WaitForChild("LatestRoom")

	local roomConnection
	local deathConnection
	local characterConnection
	local aliveConnection
	local spectatingConnection

	local flipActive = false
	local flipStart = 0
	local flipDuration = 2
	local flipDirection = 1
	local nextFlip = os.clock() + math.random(4, 7)

	local finished = false

	local function disconnectAll()
		if roomConnection then
			roomConnection:Disconnect()
			roomConnection = nil
		end

		if deathConnection then
			deathConnection:Disconnect()
			deathConnection = nil
		end

		if characterConnection then
			characterConnection:Disconnect()
			characterConnection = nil
		end

		if aliveConnection then
			aliveConnection:Disconnect()
			aliveConnection = nil
		end

		if spectatingConnection then
			spectatingConnection:Disconnect()
			spectatingConnection = nil
		end
	end

	local function destroyImmediately()
		RunService:UnbindFromRenderStep(RENDER_NAME)

		disconnectAll()

		if loopSound then
			loopSound:Stop()
			loopSound:Destroy()
			loopSound = nil
		end

		if monster and monster.Parent then
			monster:Destroy()
		end

		for _, effect in pairs(effects) do
			if effect and effect.Parent then
				effect:Destroy()
			end
		end

		if ui.gui and ui.gui.Parent then
			ui.gui:Destroy()
		end

		if fadeValue then
			pcall(function()
				fadeValue:Destroy()
			end)
		end

		camera = workspace.CurrentCamera

		if camera then
			camera.FieldOfView = originalFOV
		end
	end

	local function failEvent()
		if finished then
			return
		end

		finished = true
		ending = true
		active = false

		destroyImmediately()

		ending = false
	end

	local function finishEvent(survived)
		if finished then
			return
		end

		finished = true
		ending = true
		active = false

		disconnectAll()

		if loopSound then
			loopSound:Stop()
			loopSound:Destroy()
			loopSound = nil
		end

		fadeMonster(monster, FADE_OUT_TIME)

		if ui.holder then
			TweenService:Create(
				ui.holder,
				TweenInfo.new(
					FADE_OUT_TIME,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{
					Position = UDim2.new(1, 230, 0.5, 0),
					BackgroundTransparency = 1
				}
			):Play()
		end

		if ui.label then
			TweenService:Create(
				ui.label,
				TweenInfo.new(FADE_OUT_TIME),
				{
					TextTransparency = 1
				}
			):Play()
		end

		local fadeTween = TweenService:Create(
			fadeValue,
			TweenInfo.new(
				FADE_OUT_TIME,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			),
			{
				Value = 0
			}
		)

		fadeTween:Play()
		fadeTween.Completed:Wait()

		RunService:UnbindFromRenderStep(RENDER_NAME)

		camera = workspace.CurrentCamera

		if camera then
			camera.FieldOfView = originalFOV
		end

		if monster and monster.Parent then
			monster:Destroy()
		end

		for _, effect in pairs(effects) do
			if effect and effect.Parent then
				effect:Destroy()
			end
		end

		if ui.gui and ui.gui.Parent then
			ui.gui:Destroy()
		end

		pcall(function()
			fadeValue:Destroy()
		end)

		playEndingSound()

		if survived and not sanityDeathTriggered then
			giveAchievement()
		end

		ending = false
	end

	local function bindHumanoid(character)
		if deathConnection then
			deathConnection:Disconnect()
			deathConnection = nil
		end

		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if not humanoid then
			humanoid = character:WaitForChild("Humanoid", 5)
		end

		if humanoid then
			deathConnection = humanoid.Died:Connect(function()
				if not active then
					return
				end

				if sanityDeathTriggered then
					return
				end

				failEvent()
			end)
		end
	end

	bindHumanoid(player.Character)

	characterConnection = player.CharacterAdded:Connect(function()
		if not active then
			return
		end

		if not sanityDeathTriggered then
			failEvent()
		end
	end)

	aliveConnection = player:GetAttributeChangedSignal("Alive"):Connect(function()
		if not active or sanityDeathTriggered then
			return
		end

		if player:GetAttribute("Alive") == false then
			failEvent()
		end
	end)

	spectatingConnection = player:GetAttributeChangedSignal("Spectating"):Connect(function()
		if not active or sanityDeathTriggered then
			return
		end

		if player:GetAttribute("Spectating") == true then
			failEvent()
		end
	end)

	roomConnection = latestRoom.Changed:Connect(function()
		if not active or sanityDeathTriggered then
			return
		end

		currentSan = math.clamp(
			currentSan + ROOM_SAN_GAIN,
			0,
			100
		)

		updateSanDisplay(currentSan, ui)

		if ui.holder then
			ui.holder.Size = UDim2.fromOffset(204, 69)

			TweenService:Create(
				ui.holder,
				TweenInfo.new(
					0.35,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),
				{
					Size = UDim2.fromOffset(190, 65)
				}
			):Play()
		end
	end)

	RunService:BindToRenderStep(
		RENDER_NAME,
		Enum.RenderPriority.Camera.Value + 1,
		function()
			camera = workspace.CurrentCamera

			if not camera then
				return
			end

			local now = os.clock()
			local elapsed = now - eventStartTime
			local fade = fadeValue.Value

			local eventProgress = math.clamp(
				elapsed / TOTAL_TIME,
				0,
				1
			)

			local insanity = math.clamp(
				1 - currentSan / 100,
				0,
				1
			)

			local lateGame = math.clamp(
				(eventProgress - 0.3) / 0.7,
				0,
				1
			)

			lateGame = lateGame ^ 1.25

			local extremeLate = math.clamp(
				(eventProgress - 0.68) / 0.32,
				0,
				1
			)

			extremeLate = extremeLate ^ 1.35

			local finalPhase = math.clamp(
				(eventProgress - 0.86) / 0.14,
				0,
				1
			)

			if effects.monochrome then
				local monochromeProgress = math.clamp(
					(elapsed - 12) / 8,
					0,
					1
				)

				monochromeProgress =
					monochromeProgress
					* monochromeProgress
					* (3 - 2 * monochromeProgress)

				effects.monochrome.Saturation =
					-1
					* monochromeProgress
					* fade

				effects.monochrome.Contrast =
					0.14
					* monochromeProgress
					* fade

				effects.monochrome.Brightness =
					-0.03
					* monochromeProgress
					* fade
			end

			local flipAngle = 0

			if active
				and eventProgress >= 0.2
				and not flipActive
				and now >= nextFlip
			then
				flipActive = true
				flipStart = now

				flipDuration =
					2.5
					+ eventProgress * 3
					+ extremeLate * 1.8

				flipDirection =
					math.random(0, 1) == 0
					and -1
					or 1
			end

			if flipActive then
				local progress =
					(now - flipStart) / flipDuration

				if progress >= 1 then
					flipActive = false

					local minDelay =
						math.max(
							1.8,
							6.5
							- lateGame * 2.5
							- extremeLate * 1.5
						)

					local maxDelay =
						math.max(
							3,
							9
							- lateGame * 3
							- extremeLate * 2
						)

					nextFlip =
						now
						+ minDelay
						+ math.random()
						* (maxDelay - minDelay)
				else
					local curve =
						math.sin(progress * math.pi) ^ 0.4

					flipAngle =
						math.rad(180)
						* curve
						* flipDirection
						* fade
				end
			end

			local curveRoll =
				math.sin(now * 0.82)
				* math.rad(
					1.8
					+ eventProgress * 2.5
					+ lateGame * 2
				)

			local curveRoll2 =
				math.sin(now * 0.39 + 1.6)
				* math.rad(
					1
					+ eventProgress * 1.7
					+ lateGame * 1.3
				)

			local violentRoll =
				math.sin(now * 1.8)
				* math.rad(
					lateGame * 4
					+ extremeLate * 8
					+ finalPhase * 7
				)

			local noiseRoll =
				math.noise(now * 8, 0, 0)
				* math.rad(
					lateGame * 2.5
					+ extremeLate * 5
					+ finalPhase * 6
				)

			local microRoll =
				math.sin(now * 28)
				* math.rad(
					extremeLate * 1.3
					+ finalPhase * 3
				)

			local pitch =
				(
					math.sin(now * 0.68)
					* math.rad(
						0.5
						+ eventProgress * 1.6
						+ lateGame * 1.5
						+ extremeLate * 2.8
						+ finalPhase * 3
					)
					+
					math.noise(0, now * 8, 0)
					* math.rad(
						lateGame * 1.5
						+ extremeLate * 3.5
						+ finalPhase * 3
					)
				)
				* fade

			local yaw =
				(
					math.sin(now * 0.49)
					* math.rad(
						0.45
						+ eventProgress
						+ lateGame
						+ extremeLate * 2.5
					)
					+
					math.noise(now * 7, 20, 0)
					* math.rad(
						extremeLate * 2
						+ finalPhase * 2.5
					)
				)
				* fade

			local shake =
				(
					0.004
					+ eventProgress * 0.006
					+ lateGame * 0.018
					+ extremeLate * 0.06
					+ finalPhase * 0.08
				)
				* fade

			local shiftX =
				(
					math.sin(now * 1.45) * 0.012
					+
					math.noise(now * 18, 10, 0) * shake
					+
					math.sin(now * 25)
					* 0.025
					* extremeLate
					+
					math.sin(now * 39)
					* 0.025
					* finalPhase
				)
				* fade

			local shiftY =
				(
					math.cos(now * 1.12) * 0.01
					+
					math.noise(10, now * 19, 0) * shake
					+
					math.cos(now * 23)
					* 0.022
					* extremeLate
					+
					math.cos(now * 35)
					* 0.025
					* finalPhase
				)
				* fade

			camera.CFrame =
				camera.CFrame
				* CFrame.new(
					shiftX,
					shiftY,
					0
				)
				* CFrame.Angles(
					pitch,
					yaw,
					(
						curveRoll
						+ curveRoll2
						+ violentRoll
						+ noiseRoll
						+ microRoll
						+ flipAngle
					)
					* fade
				)

			local fovPulse =
				math.sin(now * 1.05)
				*
				(
					1.8
					+ eventProgress * 2
					+ lateGame * 4
					+ extremeLate * 5
					+ finalPhase * 3
				)
				* fade

			local fovNoise =
				math.noise(now * 2.5, 0, 0)
				*
				(
					extremeLate * 4
					+ finalPhase * 3
				)
				* fade

			camera.FieldOfView =
				originalFOV
				+ fovPulse
				+ fovNoise

			if effects.blur then
				local blurValue =
					6
					+ eventProgress ^ 1.3 * 19
					+ lateGame ^ 1.2 * 15
					+ extremeLate * 15
					+ finalPhase * 11
					+ insanity * 8
					+
					math.sin(now * 1.7)
					*
					(
						1.4
						+ lateGame * 2
						+ extremeLate * 2.5
					)

				effects.blur.Size =
					math.clamp(
						blurValue * fade,
						0,
						52
					)
			end

			if effects.color then
				effects.color.Contrast =
					(
						0.09
						+ eventProgress * 0.14
						+ lateGame * 0.2
						+ extremeLate * 0.17
						+ finalPhase * 0.1
						+
						math.sin(now * 0.8) * 0.04
					)
					* fade

				effects.color.Saturation =
					(
						-0.1
						- eventProgress * 0.08
						- lateGame * 0.12
						- extremeLate * 0.1
					)
					* fade

				effects.color.Brightness =
					(
						math.sin(now * 0.55) * 0.025
						+
						math.sin(now * 2.6)
						* extremeLate
						* 0.02
						+
						math.sin(now * 8)
						* finalPhase
						* 0.012
					)
					* fade

				local tintStrength =
					math.clamp(
						(
							0.13
							+ eventProgress * 0.12
							+ lateGame * 0.2
							+ extremeLate * 0.2
						)
						* fade,
						0,
						0.75
					)

				effects.color.TintColor =
					Color3.new(1, 1, 1):Lerp(
						Color3.fromRGB(
							155,
							180,
							225
						),
						tintStrength
					)
			end

			if effects.bloom then
				effects.bloom.Intensity =
					(
						0.35
						+ eventProgress * 0.35
						+ lateGame * 0.75
						+ extremeLate * 0.85
						+ finalPhase * 0.4
						+
						math.sin(now * 0.75) * 0.13
					)
					* fade

				effects.bloom.Size =
					34
					+ lateGame * 12
					+ extremeLate * 16
					+ finalPhase * 8
			end

			if effects.depth then
				effects.depth.FarIntensity =
					math.clamp(
						(
							0.08
							+ eventProgress * 0.13
							+ lateGame * 0.23
							+ extremeLate * 0.2
							+ finalPhase * 0.1
						)
						* fade,
						0,
						0.72
					)

				effects.depth.NearIntensity =
					math.clamp(
						(
							0.04
							+ lateGame * 0.2
							+ extremeLate * 0.18
							+ finalPhase * 0.1
						)
						* fade,
						0,
						0.5
					)

				effects.depth.FocusDistance =
					10
					+
					math.sin(now * 0.65)
					*
					(
						3
						+ lateGame * 4
						+ extremeLate * 5
						+ finalPhase * 4
					)

				effects.depth.InFocusRadius =
					math.max(
						1.5,
						8
						- lateGame * 3
						- extremeLate * 2
						- finalPhase * 1.5
					)
			end

			if effects.rays then
				effects.rays.Intensity =
					(
						0.015
						+ lateGame * 0.05
						+ extremeLate * 0.06
						+ finalPhase * 0.03
					)
					* fade
			end

			if ui.holder then
				local uiShake =
					(
						eventProgress * 1.5
						+ lateGame * 4
						+ extremeLate * 9
						+ finalPhase * 10
					)
					* fade

				ui.holder.Position =
					UDim2.new(
						1,
						-35
						+
						math.sin(now * 14) * uiShake
						+
						math.noise(now * 18, 0, 0) * uiShake,
						0.5,
						math.cos(now * 12) * uiShake
						+
						math.noise(0, now * 17, 0) * uiShake
					)
			end

			if ui.veil then
				ui.veil.BackgroundTransparency =
					math.clamp(
						0.994
						-
						(
							eventProgress * 0.012
							+ lateGame * 0.025
							+ extremeLate * 0.028
							+ finalPhase * 0.015
						)
						* fade,
						0.9,
						1
					)
			end

			if ui.ghostA then
				ui.ghostA.Position =
					UDim2.new(
						0.5,
						math.sin(now * 1.8)
						*
						(
							6
							+ eventProgress * 7
							+ lateGame * 13
							+ extremeLate * 16
							+ finalPhase * 9
						)
						* fade,
						0.5,
						math.cos(now * 1.35)
						*
						(
							4
							+ eventProgress * 6
							+ lateGame * 10
							+ extremeLate * 12
						)
						* fade
					)

				ui.ghostA.BackgroundTransparency =
					math.clamp(
						0.997
						-
						(
							eventProgress * 0.008
							+ lateGame * 0.018
							+ extremeLate * 0.02
							+ finalPhase * 0.01
						)
						* fade,
						0.93,
						1
					)
			end

			if ui.ghostB then
				ui.ghostB.Position =
					UDim2.new(
						0.5,
						-math.sin(now * 1.55)
						*
						(
							5
							+ eventProgress * 7
							+ lateGame * 12
							+ extremeLate * 15
							+ finalPhase * 8
						)
						* fade,
						0.5,
						-math.cos(now * 1.9)
						*
						(
							4
							+ eventProgress * 5
							+ lateGame * 9
							+ extremeLate * 11
						)
						* fade
					)

				ui.ghostB.BackgroundTransparency =
					math.clamp(
						0.998
						-
						(
							eventProgress * 0.007
							+ lateGame * 0.015
							+ extremeLate * 0.018
							+ finalPhase * 0.01
						)
						* fade,
						0.94,
						1
					)
			end
		end
	)

	task.spawn(function()
		while active do
			task.wait(1)

			if not active or sanityDeathTriggered then
				break
			end

			currentSan =
				math.clamp(
					currentSan - SAN_LOSS_PER_SECOND,
					0,
					100
				)

			updateSanDisplay(currentSan, ui)

			if currentSan <= 35 and math.random() > 0.78 then
				ui.label.Text = "??%"
			end

			if currentSan <= 15 and math.random() > 0.58 then
				local fakeValues = {
					"0%",
					"???",
					"-",
					"∞",
					tostring(math.random(101, 999)) .. "%"
				}

				ui.label.Text =
					fakeValues[
						math.random(1, #fakeValues)
					]
			end

			if currentSan <= 0 then
				if not sanityDeathTriggered then
					sanityDeathTriggered = true

					ui.label.Text = "0%"

					if ui.bar then
						ui.bar.Size = UDim2.fromScale(0, 1)
					end

					replicatesignal(
						game.Players.LocalPlayer.Kill
					)

					finishEvent(false)
				end

				break
			end
		end
	end)

	local followStart = os.clock()

	while active and os.clock() - followStart < FOLLOW_TIME do
		camera = workspace.CurrentCamera

		if camera then
			local camCF = camera.CFrame

			local position =
				camCF.Position
				+ camCF.LookVector * MONSTER_DISTANCE
				+ Vector3.new(
					0,
					MONSTER_HEIGHT_OFFSET,
					0
				)

			setMonsterCFrame(
				monster,
				CFrame.lookAt(
					position,
					camCF.Position
				)
			)
		end

		RunService.RenderStepped:Wait()
	end

	while active do
		RunService.Heartbeat:Wait()

		if not sanityDeathTriggered then
			if player:GetAttribute("Alive") == false
				or player:GetAttribute("Spectating") == true
			then
				failEvent()
				return
			end

			local character = player.Character
			local humanoid =
				character
				and character:FindFirstChildOfClass("Humanoid")

			if not character
				or not humanoid
				or humanoid.Health <= 0
			then
				failEvent()
				return
			end
		end

		if os.clock() - eventStartTime >= TOTAL_TIME then
			break
		end
	end

	if active and not sanityDeathTriggered then
		finishEvent(true)
	end
end

startUnnameable()
end


function entityBehaviors.SEEKEYES()
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local flipActive = true
local flipStart = os.clock()
local flipDuration = 2
local flipDirection = 1
RunService:BindToRenderStep("ScreenFlipOnce", Enum.RenderPriority.Camera.Value + 1, function()
local now = os.clock()
local progress = (now - flipStart) / flipDuration
if progress >= 1 then
RunService:UnbindFromRenderStep("ScreenFlipOnce")
return
end
local curve = math.sin(progress * math.pi) ^ 0.4
local flipAngle = math.rad(180) * curve * flipDirection
camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, flipAngle)
end)
end

function entityBehaviors.Subspace()
local sound = Instance.new("Sound")
sound.Name = "Subspace"
sound.SoundId = "rbxassetid://108345344203629"
sound.Volume = 4
sound.Parent = workspace

sound.Ended:Connect(function()
    sound:Destroy()
end)

sound:Play()
wait(5)
    local sound = Instance.new("Sound")
sound.Name = "Subspace"
sound.SoundId = "rbxassetid://134461834055887"
sound.Volume = 4
sound.Parent = workspace

sound.Ended:Connect(function()
    sound:Destroy()
end)

sound:Play()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SHAKE_INTENSITY = 20
local SHAKE_DURATION = 7
local SHAKE_SPEED = 70
local player = Players.LocalPlayer
if not player then return end
local camera = workspace.CurrentCamera
local startTime = tick()
local originalPosition = camera.CFrame.Position
local connection
connection = RunService.RenderStepped:Connect(function()
    local elapsed = tick() - startTime
    if elapsed < SHAKE_DURATION then
        local decay = 1 - (elapsed / SHAKE_DURATION)
        local intensity = SHAKE_INTENSITY * decay
        local time = elapsed * SHAKE_SPEED
        local offset = Vector3.new(
            math.sin(time * 1.1) * intensity * 0.5 + math.random(-intensity, intensity) * 0.3,
            math.cos(time * 0.9) * intensity * 0.5 + math.random(-intensity, intensity) * 0.3,
            math.sin(time * 1.0) * intensity * 0.3
        )
        local lookVector = camera.CFrame.LookVector
        local upVector = camera.CFrame.UpVector
        local rightVector = camera.CFrame.RightVector
        local currentPos = camera.CFrame.Position
        local newPos = currentPos + offset
        camera.CFrame = CFrame.new(newPos, newPos + lookVector) * CFrame.Angles(0, 0, 0)
        
    else

        if connection then
            connection:Disconnect()
        end
    end
end)
end
function entityBehaviors.DELALL()
local function deleteDirectChildModelsAndParts()
    local workspace = game:GetService("Workspace")
    local names = { "A-200", "A60", "Amin-60", "Black-A60", "Deer god","Black Hole Particle effect","DeerGod",
        "Frostbite", "@&%^#*$Indescribable God!@$*&^!Q(* ", "LightSpeed",
        "Rebound", "Ripper", "Following_ENEMY", "Silence","Dread","Muffler","Common Sence","Fluster","Kitty","Broken eyes","Angry Munci","Shadow","LEVEL0","Him","Hunger","WH1T3","Obsession","HimMoving","smiler", "Chainsmoker" } -- 保持不变
    for _, name in ipairs(names) do
        local child = workspace:FindFirstChild(name)
        if child and (child:IsA("Model") or child:IsA("Part")) then
            child:Destroy()
        end
    end
end
deleteDirectChildModelsAndParts()
end
function entityBehaviors.Smiler()
local entity = spawner.Create({Entity = {Name = "smiler",Asset = "108450814500304",HeightOffset = 0},Lights = {Flicker = {Enabled = true,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 450,Delay = 11,Reversed = false},Rebounding = {Enabled = true,Type = "ambush",Min = 2,Max = 2,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 200,Amount = 125},Crucifixion = {Enabled = true,Range = 200,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于Smiler", "或许你需要在Ambush那学会点东西", "在闪灯数秒后他会出现", "加油,我相信你可以做到"},Cause = ""}})
entity:SetCallback("OnRebounding", function(startOfRebound)
	local entityModel = entity.Model
	local main = entityModel:WaitForChild("Main")
	local attachment = main:WaitForChild("Attachment")
	local AttachmentSwitch = main:WaitForChild("AttachmentSwitch")
	local sounds = {
		footsteps = main:WaitForChild("Footsteps"),
		playSound = main:WaitForChild("PlaySound"),
		switch = main:WaitForChild("Switch"),
		switchBack = main:WaitForChild("SwitchBack")
	}

	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end

	if startOfRebound == true then
		sounds.footsteps.PlaybackSpeed = 0.35
		sounds.playSound.PlaybackSpeed = 0.25
		sounds.switch:Play()
	else
		sounds.footsteps.PlaybackSpeed = 0.25
		sounds.playSound.PlaybackSpeed = 0.16
		sounds.switchBack:Play()
	end
	
end)
entity:Run()
end

function entityBehaviors.ChainSmoker()
local entity = spawner.Create({Entity = {Name = "Chainsmoker",Asset = "97888632834501",HeightOffset = 1},Lights = {Flicker = {Enabled = true,Duration = 1},Shatter = true,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 10,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 30,Delay = 1,Reversed = true},Rebounding = {Enabled = false,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 5,Amount = 125},Crucifixion = {Enabled = true,Range = 20,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于Chainsmoker", "......", "或许我不能告诉你他的信息", "总而言之，当心闪灯"},Cause = ""}})
entity:SetCallback("OnRebounding", function(startOfRebound)
	local entityModel = entity.Model
	local main = entityModel:WaitForChild("Main")
	local attachment = main:WaitForChild("Attachment")
	local AttachmentSwitch = main:WaitForChild("AttachmentSwitch")
	local sounds = {
		footsteps = main:WaitForChild("Footsteps"),
		playSound = main:WaitForChild("PlaySound"),
		switch = main:WaitForChild("Switch"),
		switchBack = main:WaitForChild("SwitchBack")
	}
	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end
	if startOfRebound == true then
		sounds.footsteps.PlaybackSpeed = 0.35
		sounds.playSound.PlaybackSpeed = 0.25
		sounds.switch:Play()
	else
		sounds.footsteps.PlaybackSpeed = 0.25
		sounds.playSound.PlaybackSpeed = 0.16
		sounds.switchBack:Play()
	end

end)
entity:Run()
end
function entityBehaviors.LightSpeed()
local entity = spawner.Create({Entity = {Name = "LightSpeed",Asset = "87015961601567",HeightOffset = 1},Lights = {Flicker = {Enabled = false,Duration = 0.1},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 20,Values = {90, 50, 20, 20}},Movement = {Speed = 1400,Delay = 20,Reversed = false},Rebounding = {Enabled = false,Type = "Blitz",Min = 1,Max = math.random(1, 2),Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 50,Amount = 40},Crucifixion = {Enabled = true,Range = 50,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于光速", "在他来临时保证自己以最快的速度作出反应", "伴随着灯光变黄与巨大的雷电轰鸣声", "或许并不致命但总是一个威胁"},Cause = ""}})
entity:SetCallback("OnRebounding", function(startOfRebound)
	local entityModel = entity.Model
	local main = entityModel:WaitForChild("Main")
	local attachment = main:WaitForChild("Attachment")
	local AttachmentSwitch = main:WaitForChild("AttachmentSwitch")
	local sounds = {
		footsteps = main:WaitForChild("Footsteps"),
		playSound = main:WaitForChild("PlaySound"),
		switch = main:WaitForChild("Switch"),
		switchBack = main:WaitForChild("SwitchBack")
	}
	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end
	if startOfRebound == true then
		sounds.footsteps.PlaybackSpeed = 0.35
		sounds.playSound.PlaybackSpeed = 0.25
		sounds.switch:Play()
	else
		sounds.footsteps.PlaybackSpeed = 0.25
		sounds.playSound.PlaybackSpeed = 0.16
		sounds.switchBack:Play()
	end
	
end)
entity:Run()
end
function entityBehaviors.A200Jump()
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local images = {
	113886624548165,
	16907654704,
	91100683423814
}

local function PlayA200J()
	 local hardCoreSound = workspace:FindFirstChild("HardCoreSound")
    local A2000 = hardCoreSound and hardCoreSound:FindFirstChild("A200J")
    if A2000 and A2000:IsA("Sound") then
        A2000:Stop()
        A2000.TimePosition = 0
        A2000:Play()
    end
end

local function DamagePlayer()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:TakeDamage(100)
	end
end

local function ScreenShake(power, duration)
	local start = os.clock()
	local shakeName = "A200J_Shake_" .. HttpService:GenerateGUID(false)

	RunService:BindToRenderStep(
		shakeName,
		Enum.RenderPriority.Camera.Value + 1,
		function()
			if os.clock() - start >= duration then
				RunService:UnbindFromRenderStep(shakeName)
				return
			end

			local camera = workspace.CurrentCamera

			if camera then
				camera.CFrame = camera.CFrame * CFrame.new(
					math.random(-power, power) / 100,
					math.random(-power, power) / 100,
					0
				)
			end
		end
	)
end

local function ExecuteJumpScare()
	DamagePlayer()

	local playerGui = player:WaitForChild("PlayerGui")

	local oldContainer = playerGui:FindFirstChild("A200J_Jumpscare")

	if oldContainer then
		oldContainer:Destroy()
	end

	local container = Instance.new("Folder")
	container.Name = "A200J_Jumpscare"
	container.Parent = playerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "JumpscareGui"
	gui.Parent = container
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999

	local red = Instance.new("Frame")
	red.Parent = gui
	red.Size = UDim2.fromScale(1, 1)
	red.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
	red.BackgroundTransparency = 1
	red.BorderSizePixel = 0
	red.ZIndex = 1

	local img = Instance.new("ImageLabel")
	img.Parent = gui
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Size = UDim2.fromOffset(120, 120)
	img.BackgroundTransparency = 1
	img.ImageTransparency = 1
	img.ScaleType = Enum.ScaleType.Fit
	img.ZIndex = 5

	task.spawn(PlayA200J)

	TweenService:Create(
		red,
		TweenInfo.new(0.1),
		{
			BackgroundTransparency = 0.3
		}
	):Play()

	img.Image = "rbxassetid://" .. images[1]

	TweenService:Create(
		img,
		TweenInfo.new(
			0.12,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			ImageTransparency = 0,
			Size = UDim2.fromOffset(450, 450)
		}
	):Play()

	ScreenShake(8, 0.25)

	task.wait(0.15)

	img.Image = "rbxassetid://" .. images[2]

	TweenService:Create(
		img,
		TweenInfo.new(
			0.15,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Size = UDim2.fromOffset(900, 900)
		}
	):Play()

	ScreenShake(12, 0.35)

	task.wait(0.12)

	img.Image = "rbxassetid://" .. images[3]

	local glitch = true

	task.spawn(function()
		while glitch and img.Parent do
			img.Position = UDim2.new(
				0.5,
				math.random(-35, 35),
				0.5,
				math.random(-35, 35)
			)

			img.Rotation = math.random(-15, 15)

			img.Size = UDim2.fromOffset(
				math.random(800, 1200),
				math.random(800, 1200)
			)

			img.ImageTransparency = math.random(0, 4) / 10

			task.wait(0.035)
		end
	end)

	TweenService:Create(
		img,
		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
		),
		{
			Size = UDim2.fromOffset(2200, 2200)
		}
	):Play()

	TweenService:Create(
		red,
		TweenInfo.new(0.1),
		{
			BackgroundTransparency = 0.05
		}
	):Play()

	ScreenShake(25, 0.8)

	for i = 1, 8 do
		img.ImageTransparency = 0.4
		task.wait(0.04)

		img.ImageTransparency = 0
		task.wait(0.04)
	end

	task.wait(0.8)

	glitch = false

	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Rotation = 0

	TweenService:Create(
		img,
		TweenInfo.new(0.5),
		{
			ImageTransparency = 1
		}
	):Play()

	TweenService:Create(
		red,
		TweenInfo.new(0.6),
		{
			BackgroundTransparency = 1
		}
	):Play()

	task.wait(0.7)

	container:Destroy()
end

ExecuteJumpScare()
end

function entityBehaviors.Cease()
local Event = game:GetService("ReplicatedStorage").RemotesFolder.AdminPanelRunCommand
Event:FireServer(
    "LightRoom",
    {
        ["Light Color"] = Color3.new(0, 0.098297834396362, 1)
    }
)
local entity = spawner.Create({Entity = {Name = "Cease",Asset = "74118615017772",HeightOffset = 1},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 100,Delay = 0,Reversed = false},Rebounding = {Enabled = false,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},Damage = {Enabled = false,Range = 100,Amount = 125},Crucifixion = {Enabled = true,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"CEASE", "你该学会辨别", "听取周围的声音", "反复进柜子躲避它"},Cause = ""}})
entity:SetCallback("OnRebounding", function(startOfRebound)

	local entityModel = entity.Model
	local main = entityModel:WaitForChild("Main")
	local attachment = main:WaitForChild("Attachment")
	local AttachmentSwitch = main:WaitForChild("AttachmentSwitch")
	local sounds = {
		footsteps = main:WaitForChild("Footsteps"),
		playSound = main:WaitForChild("PlaySound"),
		switch = main:WaitForChild("Switch"),
		switchBack = main:WaitForChild("SwitchBack")
	}

	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end

	if startOfRebound == true then
		sounds.footsteps.PlaybackSpeed = 0.35
		sounds.playSound.PlaybackSpeed = 0.25
		sounds.switch:Play()
	else
		sounds.footsteps.PlaybackSpeed = 0.25
		sounds.playSound.PlaybackSpeed = 0.16
		sounds.switchBack:Play()
	end
	
end)
entity:Run()
wait(40)
local Event = game:GetService("ReplicatedStorage").RemotesFolder.AdminPanelRunCommand
Event:FireServer(
    "LightRoom",
    {
        ["Light Color"] = Color3.new(0, 0, 0)
    }
)
end
function entityBehaviors.Shok()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local function spawnShocker()
    local character = player.Character or player.CharacterAdded:Wait()
    local camera = Workspace.CurrentCamera

    while not camera do
        task.wait()
        camera = Workspace.CurrentCamera
    end

    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://140037062004703")
    end)

    if not success or not objects or not objects[1] then
        return
    end

    local shockerModel = objects[1]

    local rootPart = shockerModel:FindFirstChild("HumanoidRootPart", true)

    if not rootPart or not rootPart:IsA("BasePart") then
        rootPart = shockerModel:FindFirstChildWhichIsA("BasePart", true)
    end

    if not rootPart then
        shockerModel:Destroy()
        return
    end

    shockerModel.PrimaryPart = rootPart

    for _, object in ipairs(shockerModel:GetDescendants()) do
        if object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
        end
    end

    shockerModel.Parent = Workspace

    local followOffset = CFrame.new(0, -0.7, -18)

    shockerModel:PivotTo(camera.CFrame * followOffset)

    local base = shockerModel:FindFirstChild("Base", true) or rootPart
    local playSound = base:FindFirstChild("PlaySound", true)

    local oogaBoogaaPart = shockerModel:FindFirstChild("OOGA BOOGAAAA", true) or base

    local horrorScream = oogaBoogaaPart:FindFirstChild("HORROR SCREAM 15", true)

    if not horrorScream then
        horrorScream = shockerModel:FindFirstChild("HORROR SCREAM 15", true)
    end

    local ceaseFreezeActive = false
    local ceaseSpeedScale = 1
    local ceaseFreezeSerial = 0
    local ceaseSavedEffects = {}
    local ceaseDescendantConnection = nil
    local ceaseHandledModels = setmetatable({}, { __mode = "k" })
    local shockerMoving = false
    local shockerFinished = false

    local function ceaseEase(alpha)
        alpha = math.clamp(alpha, 0, 1)
        return alpha * alpha * (3 - 2 * alpha)
    end

    local function applyCeaseSpeed(scale)
        ceaseSpeedScale = math.clamp(scale, 0, 1)

        for object, saved in pairs(ceaseSavedEffects) do
            if object.Parent then
                if saved.Type == "Particle" then
                    pcall(function()
                        object.TimeScale = saved.TimeScale * ceaseSpeedScale
                    end)
                else
                    pcall(function()
                        object.PlaybackSpeed = saved.PlaybackSpeed * ceaseSpeedScale
                        object.Volume = saved.Volume * ceaseSpeedScale
                    end)
                end
            end
        end
    end

    local function trackCeaseEffect(object)
        if ceaseSavedEffects[object] then
            return
        end

        if object:IsA("ParticleEmitter") then
            ceaseSavedEffects[object] = {
                Type = "Particle",
                TimeScale = object.TimeScale
            }
        elseif object:IsA("Sound") then
            ceaseSavedEffects[object] = {
                Type = "Sound",
                PlaybackSpeed = object.PlaybackSpeed,
                Volume = object.Volume
            }
        else
            return
        end

        if ceaseFreezeActive then
            local saved = ceaseSavedEffects[object]
            if saved.Type == "Particle" then
                pcall(function()
                    object.TimeScale = saved.TimeScale * ceaseSpeedScale
                end)
            else
                pcall(function()
                    object.PlaybackSpeed = saved.PlaybackSpeed * ceaseSpeedScale
                    object.Volume = saved.Volume * ceaseSpeedScale
                end)
            end
        end
    end

    local function setShockerSoundSpeed(sound, speed)
        if not sound or not sound.Parent then
            return
        end

        local saved = ceaseSavedEffects[sound]
        if saved and saved.Type == "Sound" then
            saved.PlaybackSpeed = speed
            sound.PlaybackSpeed = speed * ceaseSpeedScale
        else
            sound.PlaybackSpeed = speed
        end
    end

    local function cancelCeaseFreeze()
        ceaseFreezeSerial = ceaseFreezeSerial + 1

        if ceaseDescendantConnection then
            ceaseDescendantConnection:Disconnect()
            ceaseDescendantConnection = nil
        end

        for object, saved in pairs(ceaseSavedEffects) do
            if object.Parent then
                if saved.Type == "Particle" then
                    pcall(function()
                        object.TimeScale = saved.TimeScale
                    end)
                else
                    pcall(function()
                        object.PlaybackSpeed = saved.PlaybackSpeed
                        object.Volume = saved.Volume
                    end)
                end
            end
        end

        ceaseSavedEffects = {}
        ceaseSpeedScale = 1
        ceaseFreezeActive = false
    end

    local function startCeaseFreeze(ceaseModel)
        if ceaseFreezeActive or not shockerMoving or shockerFinished
            or not shockerModel.Parent or ceaseHandledModels[ceaseModel] then
            return
        end

        ceaseHandledModels[ceaseModel] = true
        ceaseFreezeActive = true
        ceaseFreezeSerial = ceaseFreezeSerial + 1
        local freezeSerial = ceaseFreezeSerial

        for _, descendant in ipairs(shockerModel:GetDescendants()) do
            trackCeaseEffect(descendant)
        end

        ceaseDescendantConnection = shockerModel.DescendantAdded:Connect(function(descendant)
            if ceaseFreezeSerial == freezeSerial and ceaseFreezeActive then
                trackCeaseEffect(descendant)
            end
        end)

        task.spawn(function()
            local function stillValid()
                return ceaseFreezeSerial == freezeSerial
                    and not shockerFinished
                    and shockerModel.Parent ~= nil
            end

            local function transition(fromScale, toScale, duration)
                local startedAt = os.clock()
                while true do
                    if not stillValid() then
                        if ceaseFreezeSerial == freezeSerial then
                            cancelCeaseFreeze()
                        end
                        return false
                    end

                    local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
                    local eased = ceaseEase(alpha)
                    applyCeaseSpeed(fromScale + (toScale - fromScale) * eased)

                    if alpha >= 1 then
                        return true
                    end

                    RunService.Heartbeat:Wait()
                end
            end

            if not transition(1, 0, 2.25) then
                return
            end

            local holdStartedAt = os.clock()
            while os.clock() - holdStartedAt < 13 do
                if not stillValid() then
                    if ceaseFreezeSerial == freezeSerial then
                        cancelCeaseFreeze()
                    end
                    return
                end
                task.wait(0.05)
            end

            if not transition(0, 1, 2) then
                return
            end

            if ceaseFreezeSerial == freezeSerial then
                cancelCeaseFreeze()
            end
        end)
    end

    task.spawn(function()
        while shockerModel.Parent and not shockerFinished do
            if shockerMoving and not ceaseFreezeActive then
                local ceaseModel = Workspace:FindFirstChild("Cease", true)
                if ceaseModel and ceaseModel:IsA("Model")
                    and not ceaseHandledModels[ceaseModel] then
                    startCeaseFreeze(ceaseModel)
                end
            end
            task.wait(0.1)
        end

        if ceaseFreezeActive then
            cancelCeaseFreeze()
        end
    end)

    local function waitShockerTime(duration)
        local elapsed = 0
        while elapsed < duration do
            if not shockerModel.Parent then
                return false
            end
            local dt = RunService.Heartbeat:Wait()
            elapsed = elapsed + math.min(dt, 0.1) * ceaseSpeedScale
        end
        return shockerModel.Parent ~= nil
    end

    local face2Emitters = {}
    local originalFaceRates = {}

    for _, object in ipairs(shockerModel:GetDescendants()) do
        if object.Name == "FACE2" and object:IsA("ParticleEmitter") then
            table.insert(face2Emitters, object)
            originalFaceRates[object] = object.Rate
            object.Enabled = false
            object:Clear()
        end
    end

    local function setFaceVisible(enabled)
        for _, emitter in ipairs(face2Emitters) do
            if emitter.Parent and emitter:IsDescendantOf(shockerModel) then
                if enabled then
                    if emitter.Rate <= 0 then
                        emitter.Rate = 18
                    end

                    emitter.Enabled = true
                    emitter:Emit(20)
                else
                    emitter.Enabled = false
                    emitter.Rate = originalFaceRates[emitter] or 0
                    emitter:Clear()
                end
            end
        end
    end

    setFaceVisible(false)

    if playSound and playSound:IsA("Sound") then
        setShockerSoundSpeed(playSound, 0.9)
        playSound:Play()
    end

    local function tweenModelTo(targetCFrame, duration, easingStyle, easingDirection)
        if not shockerModel.Parent then
            return false
        end

        local startingCFrame = shockerModel:GetPivot()
        local elapsed = 0
        shockerMoving = true

        while elapsed < duration do
            if not shockerModel.Parent then
                shockerMoving = false
                return false
            end

            local deltaTime = RunService.RenderStepped:Wait()
            elapsed = math.min(duration, elapsed + math.min(deltaTime, 0.1) * ceaseSpeedScale)
            local alpha = math.clamp(elapsed / duration, 0, 1)
            local eased = TweenService:GetValue(
                alpha,
                easingStyle or Enum.EasingStyle.Exponential,
                easingDirection or Enum.EasingDirection.Out
            )
            shockerModel:PivotTo(startingCFrame:Lerp(targetCFrame, eased))
        end

        shockerMoving = false
        return shockerModel.Parent ~= nil
    end

    local lookElapsed = 0
    shockerMoving = true

    while lookElapsed < 3 do
        local deltaTime = RunService.RenderStepped:Wait()

        if not shockerModel.Parent then
            return
        end

        camera = Workspace.CurrentCamera or camera
        lookElapsed = math.min(3, lookElapsed + math.min(deltaTime, 0.1) * ceaseSpeedScale)
        local elapsed = lookElapsed

        if playSound and playSound.Parent then
            local alpha = math.clamp(elapsed / 3, 0, 1)
            local smoothAlpha = alpha * alpha * (3 - 2 * alpha)
            setShockerSoundSpeed(playSound, 0.9 + smoothAlpha)
        end

        local sway = CFrame.new(
            math.sin(elapsed * 2.7) * 0.18,
            math.sin(elapsed * 2.1) * 0.12,
            0
        ) * CFrame.Angles(
            math.rad(math.sin(elapsed * 1.8) * 2),
            math.rad(math.sin(elapsed * 2.4) * 3),
            math.rad(math.sin(elapsed * 2.1) * 1.5)
        )

        local targetCFrame = camera.CFrame * followOffset * sway

        local currentCFrame = shockerModel:GetPivot()

        local alpha = 1 - math.exp(-deltaTime * 3.8 * ceaseSpeedScale)

        shockerModel:PivotTo(
            currentCFrame:Lerp(targetCFrame, alpha)
        )
    end

    shockerMoving = false

    if playSound and playSound.Parent then
        setShockerSoundSpeed(playSound, 1.9)
    end

    local attackCount = math.random(2, 5)

    local retreatDistance = 2.8
    local retreatDuration = 0.35
    local dashDuration = 0.7
    local hitRadius = 4.2
    local damageAmount = 30

    local hintSent = false

    local function damagePlayer()
        local currentCharacter = player.Character

        if not currentCharacter then
            return false
        end

        local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")

        if not currentHumanoid or currentHumanoid.Health <= 0 then
            return false
        end

        local willDie = currentHumanoid.Health <= damageAmount

        if willDie then
            local gameStats = ReplicatedStorage:FindFirstChild("GameStats")
            local playerStats = gameStats and gameStats:FindFirstChild("Player_" .. player.Name)
            local totalStats = playerStats and playerStats:FindFirstChild("Total")
            local deathCause = totalStats and totalStats:FindFirstChild("DeathCause")

            if deathCause then
                deathCause.Value = "Shocker"
            end
        end

        currentHumanoid:TakeDamage(damageAmount)

        return true
    end

    local function getSegmentDistance(point, startPosition, endPosition)
        local segment = endPosition - startPosition
        local lengthSquared = segment:Dot(segment)

        if lengthSquared <= 0.0001 then
            return (point - startPosition).Magnitude
        end

        local alpha = math.clamp(
            (point - startPosition):Dot(segment) / lengthSquared,
            0,
            1
        )

        local closestPoint = startPosition + segment * alpha

        return (point - closestPoint).Magnitude
    end

    local function dashTo(targetCFrame, duration)
        if not shockerModel.Parent then
            return false, false
        end

        local startCFrame = shockerModel:GetPivot()
        local previousPosition = startCFrame.Position
        local hasHit = false
        local elapsed = 0
        shockerMoving = true

        while elapsed < duration do
            if not shockerModel.Parent then
                shockerMoving = false
                return false, hasHit
            end

            local deltaTime = RunService.RenderStepped:Wait()
            local step = math.min(deltaTime, 0.1) * ceaseSpeedScale
            elapsed = math.min(duration, elapsed + step)
            local alpha = math.clamp(elapsed / duration, 0, 1)
            local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
            shockerModel:PivotTo(startCFrame:Lerp(targetCFrame, eased))
            local currentPosition = shockerModel:GetPivot().Position

            if step > 0 and not hasHit then
                local currentCharacter = player.Character
                local currentRoot = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")

                if currentRoot and currentHumanoid and currentHumanoid.Health > 0 then
                    local distance = getSegmentDistance(
                        currentRoot.Position,
                        previousPosition,
                        currentPosition
                    )

                    if distance <= hitRadius then
                        hasHit = damagePlayer()
                    end
                end
            end

            previousPosition = currentPosition
        end

        shockerMoving = false
        return shockerModel.Parent ~= nil, hasHit
    end

    for attackIndex = 1, attackCount do
        if not shockerModel.Parent then
            return
        end

        setFaceVisible(false)

        local currentCharacter = player.Character or character
        local currentRoot = currentCharacter:FindFirstChild("HumanoidRootPart")

        if not currentRoot then
            break
        end

        local currentPivot = shockerModel:GetPivot()

        local awayVector = currentPivot.Position - currentRoot.Position

        if awayVector.Magnitude < 0.001 then
            awayVector = camera.CFrame.LookVector
        end

        local awayDirection = awayVector.Unit

        local retreatPosition =
            currentPivot.Position + awayDirection * retreatDistance

        local retreatCFrame =
            CFrame.new(retreatPosition) * currentPivot.Rotation

        local retreatSuccess = tweenModelTo(
            retreatCFrame,
            retreatDuration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        )

        if not retreatSuccess then
            return
        end

        currentCharacter = player.Character or character
        currentRoot = currentCharacter:FindFirstChild("HumanoidRootPart")

        if not currentRoot then
            break
        end

        local dashStartPosition = shockerModel:GetPivot().Position
        local targetPlayerPosition = currentRoot.Position

        local dashVector = targetPlayerPosition - dashStartPosition

        if dashVector.Magnitude < 0.001 then
            dashVector = -camera.CFrame.LookVector
        end

        local dashDirection = dashVector.Unit

        local dashEndPosition =
            targetPlayerPosition + dashDirection * 5.5

        local dashCFrame =
            CFrame.new(dashEndPosition) * shockerModel:GetPivot().Rotation

        setFaceVisible(true)

        if horrorScream and horrorScream.Parent then
            pcall(function()
                horrorScream:Stop()
                horrorScream.TimePosition = 0
                horrorScream:Play()
            end)
        end

        local dashSuccess = dashTo(
            dashCFrame,
            dashDuration
        )

        setFaceVisible(false)

        if not dashSuccess then
            return
        end

        if attackIndex < attackCount then
            local randomInterval = math.random(10, 18) / 10
            if not waitShockerTime(randomInterval) then
                return
            end
        end
    end

    if not shockerModel.Parent then
        return
    end

    while ceaseFreezeActive and shockerModel.Parent do
        RunService.Heartbeat:Wait()
    end

    if not shockerModel.Parent then
        return
    end

    shockerMoving = false
    setFaceVisible(false)

    local fadeItems = {}

    local function addFade(instance, property, target, kind)
        local success, startValue = pcall(function()
            return instance[property]
        end)

        if success then
            table.insert(fadeItems, {
                instance = instance,
                property = property,
                startValue = startValue,
                target = target,
                kind = kind or "number"
            })
        end
    end

    local function fadeNumberSequence(sequence, alpha)
        local keypoints = {}

        for _, keypoint in ipairs(sequence.Keypoints) do
            local newValue =
                keypoint.Value + (1 - keypoint.Value) * alpha

            local newEnvelope =
                keypoint.Envelope * (1 - alpha)

            table.insert(
                keypoints,
                NumberSequenceKeypoint.new(
                    keypoint.Time,
                    newValue,
                    newEnvelope
                )
            )
        end

        return NumberSequence.new(keypoints)
    end

    for _, object in ipairs(shockerModel:GetDescendants()) do
        if object:IsA("BasePart") then
            addFade(object, "Transparency", 1)

        elseif object:IsA("Decal") or object:IsA("Texture") then
            addFade(object, "Transparency", 1)

        elseif object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail") then
            addFade(object, "Transparency", 1, "sequence")

        elseif object:IsA("Highlight") then
            addFade(object, "FillTransparency", 1)
            addFade(object, "OutlineTransparency", 1)

        elseif object:IsA("Sound") then
            addFade(object, "Volume", 0)

        elseif object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
            addFade(object, "Brightness", 0)

        elseif object:IsA("Fire") then
            addFade(object, "Size", 0)
            addFade(object, "Heat", 0)

        elseif object:IsA("Smoke") then
            addFade(object, "Opacity", 0)
            addFade(object, "Size", 0)

        elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
            addFade(object, "ImageTransparency", 1)
            addFade(object, "BackgroundTransparency", 1)

        elseif object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            addFade(object, "TextTransparency", 1)
            addFade(object, "TextStrokeTransparency", 1)
            addFade(object, "BackgroundTransparency", 1)

        elseif object:IsA("UIStroke") then
            addFade(object, "Transparency", 1)
        end
    end

    local fadeDuration = 0.85
    local fadeStart = os.clock()

    while shockerModel.Parent do
        local alpha = math.clamp(
            (os.clock() - fadeStart) / fadeDuration,
            0,
            1
        )

        for _, item in ipairs(fadeItems) do
            if item.instance.Parent then
                local value

                if item.kind == "sequence" then
                    value = fadeNumberSequence(item.startValue, alpha)
                else
                    value =
                        item.startValue
                        + (item.target - item.startValue) * alpha
                end

                pcall(function()
                    item.instance[item.property] = value
                end)
            end
        end

        if alpha >= 1 then
            break
        end

        RunService.RenderStepped:Wait()
    end

    if not shockerModel.Parent then
        return
    end

    for _, object in ipairs(shockerModel:GetDescendants()) do
        if object:IsA("Sound") then
            object:Stop()

        elseif object:IsA("ParticleEmitter")
            or object:IsA("Beam")
            or object:IsA("Trail")
            or object:IsA("Fire")
            or object:IsA("Smoke")
            or object:IsA("Sparkles")
            or object:IsA("Highlight")
            or object:IsA("PointLight")
            or object:IsA("SpotLight")
            or object:IsA("SurfaceLight")
            or object:IsA("BillboardGui")
            or object:IsA("SurfaceGui")
            or object:IsA("ScreenGui") then

            object.Enabled = false
        end
    end

    shockerFinished = true
    cancelCeaseFreeze()
    shockerModel:Destroy()
end

spawnShocker()

end
function entityBehaviors.LightOSs()
 function GetRoom()
    local gruh = workspace.CurrentRooms
    return gruh:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local tweenservice = game:GetService("TweenService")

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
        elseif typeof(source) == "string" and source:match("^https?://") and source:match("%.rbxm") then
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

local s = LoadCustomInstance(106818719931200, workspace)
if not s then
    return
end

local entity = s:FindFirstChildWhichIsA("BasePart")
entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 7, -15)
entity.Part.CFrame = entity.CFrame
end

function entityBehaviors.LOOKSW()
function GetRoom()
    local gruh = workspace.CurrentRooms
    return gruh:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local tweenservice = game:GetService("TweenService")

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
        elseif typeof(source) == "string" and source:match("^https?://") and source:match("%.rbxm") then
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

local s = LoadCustomInstance(124094609630783, workspace)
if not s then
    return
end

local entity = s:FindFirstChildWhichIsA("BasePart")
entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(30, 1.2, -10)
entity.Part.CFrame = entity.CFrame

pcall(function()
local room = workspace.CurrentRooms:FindFirstChild(
    tostring(game.ReplicatedStorage.GameData.LatestRoom.Value)
)
if room then
    for _, obj in ipairs(room:GetDescendants()) do
        if obj.Name == "PlaySound" and obj:IsA("Sound") then
            obj:Stop()
            obj.Playing = false
            obj.TimePosition = 0
            obj.Looped = false
        end
    end
end
end)
end

function entityBehaviors.SuperDread()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local function GetRoom()
    local gruh = workspace:WaitForChild("CurrentRooms")
    return gruh:FindFirstChild(tostring(ReplicatedStorage.GameData.LatestRoom.Value))
end

local function LoadCustomInstance(source, parent)
    local model

    for attempt = 1, 3 do
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
            break
        end
        task.wait(0.2)
    end

    if not model then
        warn("Dread model failed to load: " .. tostring(source))
        return nil
    end

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") then
            obj:Destroy()
        end
    end

    pcall(function()
        model:SetAttribute("LoadedByExecutor", true)
    end)
    model.Parent = parent or workspace
    return model
end

if not Lighting:FindFirstChild("Ambience_Dread") then
    Instance.new("ColorCorrectionEffect", Lighting).Name = "Ambience_Dread"
end

local dreadLighting = Lighting
local dreadMainCorrection = dreadLighting:FindFirstChild("MainColorCorrection")
local dreadOriginalCorrection = dreadMainCorrection and {
    Brightness = dreadMainCorrection.Brightness,
    Contrast = dreadMainCorrection.Contrast,
    Saturation = dreadMainCorrection.Saturation,
    TintColor = dreadMainCorrection.TintColor,
    Enabled = dreadMainCorrection.Enabled
}
local dreadOriginalCameraType = workspace.CurrentCamera and workspace.CurrentCamera.CameraType
local dreadShake = nil
local dreadDeadConnection = nil
local dreadCharacterConnection = nil
local dreadVisualsRestored = false
local dreadHeadFollowName = "DreadHeadFollow_" .. tostring(LocalPlayer.UserId)
    .. "_" .. tostring(math.random(100000, 999999))
local dreadHeadFollowActive = false
local dreadLockedRoot = nil
local dreadRootWasAnchored = nil
local dreadAnimationTrack = nil
local dreadAnimationObject = nil

local function stopDreadHeadFollow()
    if dreadHeadFollowActive then
        dreadHeadFollowActive = false
        RunService:UnbindFromRenderStep(dreadHeadFollowName)
    end

    if dreadLockedRoot and dreadLockedRoot.Parent and dreadRootWasAnchored ~= nil then
        dreadLockedRoot.Anchored = dreadRootWasAnchored
    end
    dreadLockedRoot = nil
    dreadRootWasAnchored = nil

    if dreadAnimationTrack then
        pcall(function()
            dreadAnimationTrack:Stop(0)
        end)
        dreadAnimationTrack = nil
    end
    if dreadAnimationObject then
        dreadAnimationObject:Destroy()
        dreadAnimationObject = nil
    end
end

local function restoreDreadVisuals()
    if dreadVisualsRestored then
        return
    end
    dreadVisualsRestored = true
    stopDreadHeadFollow()

    if dreadMainCorrection and dreadMainCorrection.Parent and dreadOriginalCorrection then
        for property, value in pairs(dreadOriginalCorrection) do
            dreadMainCorrection[property] = value
        end
    end

    local dreadAmbience = dreadLighting:FindFirstChild("Ambience_Dread")
    if dreadAmbience then
        dreadAmbience.Enabled = false
    end

    if dreadShake then
        pcall(function()
            dreadShake:Stop()
        end)
    end

    local dreadCamera = workspace.CurrentCamera
    if dreadCamera then
        dreadCamera.CameraType = dreadOriginalCameraType or Enum.CameraType.Custom
        local aliveCharacter = LocalPlayer.Character
        local aliveHumanoid = aliveCharacter and aliveCharacter:FindFirstChildOfClass("Humanoid")
        if aliveHumanoid then
            dreadCamera.CameraSubject = aliveHumanoid
        end
    end

    pcall(function()
        local mainGame = require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game)
        mainGame.stopcam = false
        mainGame.freemouse = false
    end)

    if dreadDeadConnection then
        dreadDeadConnection:Disconnect()
        dreadDeadConnection = nil
    end
    if dreadCharacterConnection then
        dreadCharacterConnection:Disconnect()
        dreadCharacterConnection = nil
    end
end

local dreadCharacter = LocalPlayer.Character
local dreadHumanoid = dreadCharacter and dreadCharacter:FindFirstChildOfClass("Humanoid")
if dreadHumanoid then
    dreadDeadConnection = dreadHumanoid.Died:Connect(restoreDreadVisuals)
end
dreadCharacterConnection = LocalPlayer.CharacterAdded:Connect(restoreDreadVisuals)

local function vu535(p530)
    local v531, v532 = workspace.CurrentCamera:WorldToViewportPoint(p530.Position)
    if v532 then
        v532 = v531.Z > 0
    end

    local v533 = RaycastParams.new()
    v533.FilterType = Enum.RaycastFilterType.Blacklist
    v533.FilterDescendantsInstances = {p530}

    local v534 = workspace:Raycast(
        p530.Position,
        LocalPlayer.Character.UpperTorso.Position - p530.Position,
        v533
    )

    if v532 then
        if v534 then
            v534 = v534.Instance
        end

        v532 = v534 ~= nil and v534.Parent == LocalPlayer.Character
    end
    return v532
end

local v536 = require(ReplicatedStorage.CameraShaker)
local vu537 = workspace.CurrentCamera
local vu539 = v536.new(Enum.RenderPriority.Camera.Value, function(p538)
    vu537.CFrame = vu537.CFrame * p538
end)
vu539:Start()
dreadShake = vu539
vu539:ShakeOnce(2, 10, 1, 1)

local vu540 = LoadCustomInstance(140017686556165, workspace)
if not vu540 then
    restoreDreadVisuals()
    return
end

local v541 = GetRoom()
local roomEntrance = v541 and v541:FindFirstChild("RoomEntrance")
local vu542 = vu540:IsA("BasePart") and vu540
    or vu540:FindFirstChildWhichIsA("BasePart", true)

if not roomEntrance or not roomEntrance:IsA("BasePart") or not vu542 then
    warn("Dread spawn failed: current room, RoomEntrance or entity BasePart is missing")
    vu540:Destroy()
    restoreDreadVisuals()
    return
end

local spawnCFrame = roomEntrance.CFrame * CFrame.new(0, 1, -15)

if vu540:IsA("Model") then

    local offset = spawnCFrame * vu542.CFrame:Inverse()
    vu540:PivotTo(offset * vu540:GetPivot())
else
    vu542.CFrame = spawnCFrame
end

local entityPart = vu542:FindFirstChild("Part")
if entityPart and entityPart:IsA("BasePart") then
    entityPart.CFrame = vu542.CFrame
end

Lighting.Ambience_Dread.Enabled = true
Lighting.Ambience_Dread.Brightness = 0
Lighting.Ambience_Dread.Contrast = 0
Lighting.Ambience_Dread.Saturation = 0
TweenService:Create(Lighting.Ambience_Dread, TweenInfo.new(2), {
    Brightness = 0.1,
    Contrast = 0.2,
    Saturation = -0.7
}):Play()

coroutine.wrap(function()
    while not dreadVisualsRestored and vu540.Parent and not vu535(vu542) do
        task.wait(0.5)
    end
    if dreadVisualsRestored or not vu540.Parent then
        return
    end
    task.wait(1.5)
    if dreadVisualsRestored or not vu540.Parent then
        return
    end

    Lighting.Ambience_Dread.Enabled = false
    require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).stopcam = true

    local v544 = workspace.CurrentCamera
    local v545 = v544.CFrame
    v544.CameraType = Enum.CameraType.Scriptable

    local v546 = TweenService:Create(
        v544,
        TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
        {CFrame = CFrame.lookAt(v545.p, vu542.Position)}
    )
    v546:Play()
    wait(0.15)

    local dreadSoundsFolder = workspace:FindFirstChild("HardCoreSound")
    local dreadJumpSource = dreadSoundsFolder and dreadSoundsFolder:FindFirstChild("DreadJump")
    if dreadJumpSource and dreadJumpSource:IsA("Sound") then
        local dreadJumpSound = dreadJumpSource:Clone()
        dreadJumpSound.Looped = false
        dreadJumpSound.TimePosition = 0
        dreadJumpSound.Parent = SoundService
        dreadJumpSound.Ended:Once(function()
            dreadJumpSound:Destroy()
        end)
        dreadJumpSound:Play()
        Debris:AddItem(dreadJumpSound, 30)
    else

    end

    v546:Pause()

    local v547, v548, v549 = pairs(workspace:GetDescendants())
    while true do
        local v550
        v549, v550 = v547(v548, v549)
        if v549 == nil then
            break
        end
        if v550.ClassName == "ParticleEmitter" then
            v550.TimeScale = 0
        end
    end

    task.wait(2)
    if dreadVisualsRestored then return end
    if dreadMainCorrection and dreadMainCorrection.Parent then
        dreadMainCorrection.Brightness = -1
        dreadMainCorrection.Contrast = -4
        dreadMainCorrection.Saturation = -1
    end

    local v551 = vu542
    local v552, v553, v554 = pairs(v551:GetDescendants())
    while true do
        local v555
        v554, v555 = v552(v553, v554)
        if v554 == nil then
            break
        end
        if v555.Name == "PointLight" then
            v555:Destroy()
        end
    end

    vu539:ShakeOnce(10, 100, 0.1, 2)
    task.wait(1)
    if dreadVisualsRestored then return end

    local v556 = require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game)
    v556.stopcam = false
    v556.freemouse = false
    task.wait(0.4)
    if dreadVisualsRestored then return end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local humrootpart = character and character:FindFirstChild("HumanoidRootPart")
    local head = character and character:FindFirstChild("Head")
    if not (humanoid and humrootpart and head) or humanoid.Health <= 0 then
        warn("Dread death animation skipped: character parts are missing")
        return
    end

    local HotSex = Instance.new("Animation")
    HotSex.AnimationId = "rbxassetid://10096088747"
    dreadAnimationObject = HotSex

    local ok, animationError = pcall(function()
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = humanoid
        end
        local HotSexOnHumanoid = animator:LoadAnimation(HotSex)
        dreadAnimationTrack = HotSexOnHumanoid
        HotSexOnHumanoid:Play()

        dreadLockedRoot = humrootpart
        dreadRootWasAnchored = humrootpart.Anchored
        humrootpart.Anchored = true

        v556.stopcam = true
        local camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Scriptable

        dreadHeadFollowActive = true
        RunService:BindToRenderStep(
            dreadHeadFollowName,
            Enum.RenderPriority.Camera.Value - 1,
            function()
                if not dreadHeadFollowActive or dreadVisualsRestored or not head.Parent then
                    return
                end
                local currentCamera = workspace.CurrentCamera
                if currentCamera then
                    currentCamera.CFrame = currentCamera.CFrame:Lerp(head.CFrame, 0.3)
                end
            end
        )

        vu539:ShakeOnce(10, 100, 0.1, 2)

        vu539:ShakeOnce(2, 12, 0.2, 10)

        humrootpart.CFrame = humrootpart.CFrame + Vector3.new(0, 1, 0)

        local function nextAnimationStep(seconds)
            task.wait(seconds)
            return not dreadVisualsRestored and humanoid.Health > 0
                and character == LocalPlayer.Character
        end

        HotSexOnHumanoid:AdjustSpeed(0.8)
        if not nextAnimationStep(0.5) then return end
        HotSexOnHumanoid:AdjustSpeed(0.25)
        if not nextAnimationStep(3.5) then return end
        HotSexOnHumanoid:AdjustSpeed(-0.2)
        if not nextAnimationStep(0.1) then return end
        HotSexOnHumanoid:AdjustSpeed(-0.4)
        if not nextAnimationStep(0.2) then return end
        HotSexOnHumanoid:AdjustSpeed(0.1)
        if not nextAnimationStep(0.2) then return end
        HotSexOnHumanoid:AdjustSpeed(-0.25)
        if not nextAnimationStep(1.5) then return end
        HotSexOnHumanoid:AdjustSpeed(-0.15)
        if not nextAnimationStep(2) then return end
        HotSexOnHumanoid:AdjustSpeed(0)
        nextAnimationStep(2)
    end)

    if not ok then
        warn("Dread death animation failed: " .. tostring(animationError))
    end

    stopDreadHeadFollow()
    if dreadVisualsRestored then return end

    v556.stopcam = false
    v556.freemouse = false

    local damage = 999
    if humanoid.Health <= damage then
        local gameStats = ReplicatedStorage:FindFirstChild("GameStats")
        local playerStats = gameStats and gameStats:FindFirstChild("Player_" .. LocalPlayer.Name)
        local total = playerStats and playerStats:FindFirstChild("Total")
        local deathCause = total and total:FindFirstChild("DeathCause")
        if deathCause then
            deathCause.Value = "Dread"
        end
    end

    humanoid:TakeDamage(damage)
end)()

coroutine.wrap(function()
    ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
    task.wait()
    ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
    task.wait()
    ReplicatedStorage.GameData.LatestRoom.Changed:Wait()

    vu540:Destroy()
    Lighting.Ambience_Dread.Enabled = false
    if not dreadVisualsRestored then
        restoreDreadVisuals()
    end
end)()
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MULTI_MONSTER_VOLUME = 2

local HardCoreSound = workspace:WaitForChild("HardCoreSound")

local MULTI_MONSTER_SOUNDS = {
    M1 = HardCoreSound:WaitForChild("M1"),
    M2 = HardCoreSound:WaitForChild("M2"),
    M3 = HardCoreSound:WaitForChild("M3"),
    M4 = HardCoreSound:WaitForChild("M4")
}

for _, sound in pairs(MULTI_MONSTER_SOUNDS) do
    sound.Volume = MULTI_MONSTER_VOLUME
end

local GLITCH_CHARACTERS = {
    "#", "$", "%", "&",
    "0", "1", "3", "7",
    "/", "\\", "<", ">",
    "_", "-", "!", "?",
    "[", "]", "{", "}",
    "@", "*"
}

local function randomGlitchCharacter()
    return GLITCH_CHARACTERS[math.random(1, #GLITCH_CHARACTERS)]
end

local function corruptText(original, chance)
    local result = {}

    for i = 1, #original do
        local char = original:sub(i, i)

        if char ~= " " and math.random() < chance then
            result[#result + 1] = randomGlitchCharacter()
        else
            result[#result + 1] = char
        end
    end

    return table.concat(result)
end

local function createMultiMonsterUI()
    local player = Players.LocalPlayer

    if not player then
        return nil
    end

    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("MultiMonsterGlitchUI")

    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MultiMonsterGlitchUI"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.Parent = playerGui

    local text = Instance.new("TextLabel")
    text.Name = "GlitchText"
    text.AnchorPoint = Vector2.new(0.5, 1)
    text.Position = UDim2.new(0.5, 0, 0.88, 0)
    text.Size = UDim2.new(0.85, 0, 0, 85)
    text.BackgroundTransparency = 1
    text.Text = ""
    text.TextColor3 = Color3.fromRGB(255, 20, 20)
    text.TextStrokeColor3 = Color3.fromRGB(35, 0, 0)
    text.TextStrokeTransparency = 0.1
    text.TextSize = 32
    text.TextWrapped = true

    pcall(function()
        text.FontFace = Font.new("rbxassetid://11702779517")
    end)

    text.Parent = gui

    local timerText = Instance.new("TextLabel")
    timerText.Name = "TimerText"
    timerText.AnchorPoint = Vector2.new(0.5, 0.5)
    timerText.Position = UDim2.new(0.5, 0, -0.15, 0)
    timerText.Size = UDim2.new(0, 420, 0, 60)
    timerText.BackgroundTransparency = 1
    timerText.Text = "Time : 304"
    timerText.TextColor3 = Color3.fromRGB(255, 20, 20)
    timerText.TextStrokeColor3 = Color3.fromRGB(35, 0, 0)
    timerText.TextStrokeTransparency = 0.05
    timerText.TextSize = 30
    timerText.Visible = false

    pcall(function()
        timerText.FontFace = Font.new("rbxassetid://11702779517")
    end)

    timerText.Parent = gui

    local glitchLines = {}

    for i = 1, 7 do
        local line = Instance.new("Frame")
        line.Name = "GlitchLine_" .. i
        line.BorderSizePixel = 0
        line.BackgroundColor3 = Color3.fromRGB(math.random(180, 255), 0, 0)
        line.BackgroundTransparency = 0.55
        line.Size = UDim2.new(
            math.random(8, 35) / 100,
            0,
            0,
            math.random(1, 3)
        )
        line.Position = UDim2.new(
            math.random(5, 80) / 100,
            0,
            math.random(65, 92) / 100,
            0
        )
        line.Visible = false
        line.Parent = gui

        table.insert(glitchLines, line)
    end

    local timerLines = {}

    for i = 1, 4 do
        local line = Instance.new("Frame")
        line.Name = "TimerGlitchLine_" .. i
        line.BorderSizePixel = 0
        line.BackgroundColor3 = Color3.fromRGB(math.random(190, 255), 0, 0)
        line.BackgroundTransparency = 0.45
        line.Size = UDim2.new(0, math.random(50, 160), 0, math.random(1, 2))
        line.Position = UDim2.new(0.5, math.random(-170, 170), 0.08, math.random(-10, 10))
        line.Visible = false
        line.Parent = gui

        table.insert(timerLines, line)
    end

    return gui, text, glitchLines, timerText, timerLines
end

local function showGlitchSentence(label, lines, sentence, duration)
    if not label then
        return
    end

    local running = true
    local originalPosition = UDim2.new(0.5, 0, 0.88, 0)

    label.Text = sentence
    label.Visible = true
    label.TextTransparency = 0

    task.spawn(function()
        while running and label.Parent do
            label.Position = UDim2.new(
                0.5,
                math.random(-2, 2),
                0.88,
                math.random(-1, 1)
            )

            if math.random() < 0.26 then
                label.Text = corruptText(sentence, 0.08)
            else
                label.Text = sentence
            end

            if math.random() < 0.11 then
                label.TextTransparency = math.random(15, 50) / 100
            else
                label.TextTransparency = 0
            end

            for _, line in ipairs(lines) do
                line.Visible = math.random() < 0.11

                if line.Visible then
                    line.Position = UDim2.new(
                        math.random(8, 82) / 100,
                        0,
                        math.random(68, 92) / 100,
                        0
                    )

                    line.Size = UDim2.new(
                        math.random(8, 30) / 100,
                        0,
                        0,
                        math.random(1, 3)
                    )
                end
            end

            task.wait(math.random(4, 10) / 100)
        end
    end)

    task.wait(duration)

    running = false
    label.Text = sentence
    label.TextTransparency = 0
    label.Position = originalPosition

    for _, line in ipairs(lines) do
        line.Visible = false
    end
end

local function dropTimer(timerText)
    if not timerText then
        return
    end

    timerText.Visible = true
    timerText.Position = UDim2.new(0.38, 0, -0.18, 0)

    local points = {
        UDim2.new(0.42, 0, -0.05, 0),
        UDim2.new(0.57, 0, 0.015, 0),
        UDim2.new(0.46, 0, 0.055, 0),
        UDim2.new(0.52, 0, 0.075, 0),
        UDim2.new(0.5, 0, 0.08, 0)
    }

    local times = {
        0.12,
        0.14,
        0.12,
        0.1,
        0.1
    }

    for i, point in ipairs(points) do
        local tween = TweenService:Create(
            timerText,
            TweenInfo.new(
                times[i],
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            {
                Position = point
            }
        )

        tween:Play()
        tween.Completed:Wait()
    end

    timerText.Position = UDim2.new(0.5, 0, 0.08, 0)
end

local function startMultiMonsterTimer(timerText, timerLines)
    if not timerText then
        return
    end

    dropTimer(timerText)

    task.spawn(function()
        for timeLeft = 315, 0, -1 do
            if not timerText or not timerText.Parent then
                return
            end

            local normalText = "Time : " .. timeLeft
            local secondStart = os.clock()

            while os.clock() - secondStart < 1 do
                if not timerText.Parent then
                    return
                end

                timerText.Position = UDim2.new(
                    0.5,
                    math.random(-2, 2),
                    0.08,
                    math.random(-1, 1)
                )

                if math.random() < 0.3 then
                    timerText.Text = corruptText(normalText, 0.1)
                else
                    timerText.Text = normalText
                end

                if math.random() < 0.1 then
                    timerText.TextTransparency = math.random(10, 40) / 100
                else
                    timerText.TextTransparency = 0
                end

                if math.random() < 0.07 then
                    timerText.TextColor3 = Color3.fromRGB(255, 90, 90)
                else
                    timerText.TextColor3 = Color3.fromRGB(255, 20, 20)
                end

                for _, line in ipairs(timerLines or {}) do
                    line.Visible = math.random() < 0.12

                    if line.Visible then
                        line.Position = UDim2.new(
                            0.5,
                            math.random(-180, 180),
                            0.08,
                            math.random(-18, 18)
                        )

                        line.Size = UDim2.new(
                            0,
                            math.random(40, 170),
                            0,
                            math.random(1, 2)
                        )
                    end
                end

                task.wait(math.random(4, 9) / 100)
            end
        end

        if timerText and timerText.Parent then
            timerText.Text = "Time : 0"
            timerText.Position = UDim2.new(0.5, 0, 0.08, 0)
            timerText.TextTransparency = 0
            timerText.TextColor3 = Color3.fromRGB(255, 20, 20)
        end

        for _, line in ipairs(timerLines or {}) do
            line.Visible = false
        end
    end)
end

local function playSoundAndWait(sound)
    if not sound then
        return
    end

    sound:Stop()
    sound.TimePosition = 0
    sound:Play()
    sound.Ended:Wait()
end

function entityBehaviors.MultiMonster()
    local M1 = MULTI_MONSTER_SOUNDS.M1
    local M2 = MULTI_MONSTER_SOUNDS.M2
    local M3 = MULTI_MONSTER_SOUNDS.M3
    local M4 = MULTI_MONSTER_SOUNDS.M4

    if not M1 or not M2 or not M3 or not M4 then

        return
    end

    for _, sound in ipairs({M1, M2, M3, M4}) do
        pcall(function()
            sound:Stop()
            sound.TimePosition = 0
        end)
    end

    local gui, glitchText, glitchLines, timerText, timerLines = createMultiMonsterUI()

    M1:Play()

    task.spawn(function()
        local sentences = {
            "...",
            "这个地方真有趣.",
            "我喜欢这里?",
            "我会伤害到你吗?",
            "我讨厌这些。",
            "玩笑话总是让你开心。"
        }

        local timeout = 0

        while M1.TimeLength <= 0 and timeout < 5 do
            timeout += 0.05
            task.wait(0.05)
        end

        local totalTime = M1.TimeLength

        if totalTime <= 0 then
            totalTime = 18
        end

        local sentenceDuration = math.max(2, totalTime / #sentences)

        for _, sentence in ipairs(sentences) do
            if not M1.IsPlaying then
                break
            end

            showGlitchSentence(
                glitchText,
                glitchLines,
                sentence,
                sentenceDuration
            )
        end
    end)

    M1.Ended:Wait()

    if glitchText then
        glitchText.Text = ""
        glitchText.Visible = false
    end

    for _, line in ipairs(glitchLines or {}) do
        line.Visible = false
    end

    M2:Stop()
    M2.TimePosition = 0
    M2:Play()

    task.spawn(function()
        startMultiMonsterTimer(timerText, timerLines)
    end)

    M2.Ended:Wait()

    playSoundAndWait(M2)

    playSoundAndWait(M3)
    playSoundAndWait(M3)

    playSoundAndWait(M4)

    if gui then
        gui:Destroy()
    end
end
function entityBehaviors.CreakHard()
local RunService = game:GetService("RunService")

local MODEL_ID = "rbxassetid://122236943587712"
local GRAPH_ID = "rbxassetid://94509516923082"

local creak = workspace
	:WaitForChild("LiveEntities")
	:WaitForChild("Creak")

local objects = game:GetObjects(MODEL_ID)
local clone = objects[1]

if not clone then
	return
end

clone.Name = "CreakMimic"
clone.Parent = workspace

local destroyed = false

local function cleanup()
	if destroyed then
		return
	end

	destroyed = true

	if clone and clone.Parent then
		clone:Destroy()
	end
end

creak.Destroying:Connect(cleanup)

creak.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		cleanup()
	end
end)

local function hide(obj)
	if obj:IsA("MeshPart") then
		obj.Transparency = 1
	end
end

for _, obj in ipairs(creak:GetDescendants()) do
	hide(obj)
end

creak.DescendantAdded:Connect(hide)

for _, obj in ipairs(clone:GetDescendants()) do
	if obj:IsA("BasePart") then
		obj.CanCollide = false
		obj.CanTouch = false
		obj.CanQuery = false
		obj.Massless = true
	end
end

local cloneRoot =
	clone:FindFirstChild("HumanoidRootPart", true)
	or clone.PrimaryPart
	or clone:FindFirstChildWhichIsA("BasePart", true)

if not cloneRoot then
	cleanup()
	return
end

cloneRoot.Anchored = true
cloneRoot.Massless = false

if clone:IsA("Model") then
	clone.PrimaryPart = cloneRoot
end

local function findAnimator(model)
	local controller =
		model:FindFirstChild("AnimationController", true)

	if controller then
		local animator =
			controller:FindFirstChildWhichIsA(
				"Animator",
				true
			)

		if animator then
			return animator
		end
	end

	return model:FindFirstChildWhichIsA(
		"Animator",
		true
	)
end

local sourceAnimator = findAnimator(creak)
local targetAnimator = findAnimator(clone)

if not sourceAnimator or not targetAnimator then
	cleanup()
	return
end

local function isGraph(track)
	local animation = track.Animation

	if not animation then
		return false
	end

	return
		animation.AnimationId == GRAPH_ID
		or animation.Name == "CreakGraph"
end

local sourceTrack

for _, track in ipairs(
	sourceAnimator:GetPlayingAnimationTracks()
) do
	if isGraph(track) then
		sourceTrack = track
		break
	end
end

sourceAnimator.AnimationPlayed:Connect(function(track)
	if destroyed then
		return
	end

	if isGraph(track) then
		sourceTrack = track
	end
end)

while not sourceTrack and not destroyed do
	task.wait(0.05)

	if destroyed or not creak.Parent then
		cleanup()
		return
	end

	for _, track in ipairs(
		sourceAnimator:GetPlayingAnimationTracks()
	) do
		if isGraph(track) then
			sourceTrack = track
			break
		end
	end
end

if destroyed then
	return
end

for _, track in ipairs(
	targetAnimator:GetPlayingAnimationTracks()
) do
	track:Stop(0)
end

local graphAnimation = Instance.new("Animation")
graphAnimation.Name = "CreakGraph"
graphAnimation.AnimationId = GRAPH_ID

local targetTrack =
	targetAnimator:LoadAnimation(graphAnimation)

local parameterNames = {}

local function updateParameterList()
	table.clear(parameterNames)

	if not sourceTrack then
		return
	end

	local success, defaults = pcall(function()
		return sourceTrack:GetParameterDefaults()
	end)

	if not success or type(defaults) ~= "table" then
		return
	end

	for name in pairs(defaults) do
		table.insert(parameterNames, name)
	end
end

updateParameterList()

local function syncParameters()
	if destroyed then
		return
	end

	local src = sourceTrack
	local dst = targetTrack

	if not src or not dst then
		return
	end

	for i = 1, #parameterNames do
		local name = parameterNames[i]

		local success, value = pcall(
			src.GetParameter,
			src,
			name
		)

		if success and value ~= nil then
			pcall(
				dst.SetParameter,
				dst,
				name,
				value
			)
		end
	end
end

syncParameters()

targetTrack:Play(0, 1, 1)

local lastSourceTrack = sourceTrack

local preAnimationConnection
local renderConnection

preAnimationConnection = RunService.PreAnimation:Connect(function()
	if destroyed then
		preAnimationConnection:Disconnect()
		return
	end

	if sourceTrack ~= lastSourceTrack then
		lastSourceTrack = sourceTrack
		updateParameterList()
	end

	syncParameters()
end)

renderConnection = RunService.RenderStepped:Connect(function()
	if destroyed then
		renderConnection:Disconnect()
		return
	end

	if not creak.Parent then
		cleanup()
		renderConnection:Disconnect()
		return
	end

	if not clone.Parent then
		renderConnection:Disconnect()
		return
	end

	clone:PivotTo(
		creak:GetPivot()
	)
end)
end
function entityBehaviors.CreakWhite()
local RunService = game:GetService("RunService")
local MODEL_ID = "rbxassetid://107076625314099"
local GRAPH_ID = "rbxassetid://94509516923082"
local creak = workspace
	:WaitForChild("LiveEntities")
	:WaitForChild("Creak")

local objects = game:GetObjects(MODEL_ID)
local clone = objects[1]

if not clone then
	return
end

clone.Name = "CreakMimic"
clone.Parent = workspace

local destroyed = false

local function cleanup()
	if destroyed then
		return
	end

	destroyed = true

	if clone and clone.Parent then
		clone:Destroy()
	end
end

creak.Destroying:Connect(cleanup)

creak.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		cleanup()
	end
end)

local function hide(obj)
	if obj:IsA("MeshPart") then
		obj.Transparency = 1
	end
end

for _, obj in ipairs(creak:GetDescendants()) do
	hide(obj)
end

creak.DescendantAdded:Connect(hide)

for _, obj in ipairs(clone:GetDescendants()) do
	if obj:IsA("BasePart") then
		obj.CanCollide = false
		obj.CanTouch = false
		obj.CanQuery = false
		obj.Massless = true
	end
end

local cloneRoot =
	clone:FindFirstChild("HumanoidRootPart", true)
	or clone.PrimaryPart
	or clone:FindFirstChildWhichIsA("BasePart", true)

if not cloneRoot then
	cleanup()
	return
end

cloneRoot.Anchored = true
cloneRoot.Massless = false

if clone:IsA("Model") then
	clone.PrimaryPart = cloneRoot
end

local function findAnimator(model)
	local controller =
		model:FindFirstChild("AnimationController", true)

	if controller then
		local animator =
			controller:FindFirstChildWhichIsA(
				"Animator",
				true
			)

		if animator then
			return animator
		end
	end

	return model:FindFirstChildWhichIsA(
		"Animator",
		true
	)
end

local sourceAnimator = findAnimator(creak)
local targetAnimator = findAnimator(clone)

if not sourceAnimator or not targetAnimator then
	cleanup()
	return
end

local function isGraph(track)
	local animation = track.Animation

	if not animation then
		return false
	end

	return
		animation.AnimationId == GRAPH_ID
		or animation.Name == "CreakGraph"
end

local sourceTrack

for _, track in ipairs(
	sourceAnimator:GetPlayingAnimationTracks()
) do
	if isGraph(track) then
		sourceTrack = track
		break
	end
end

sourceAnimator.AnimationPlayed:Connect(function(track)
	if destroyed then
		return
	end

	if isGraph(track) then
		sourceTrack = track
	end
end)

while not sourceTrack and not destroyed do
	task.wait(0.05)

	if destroyed or not creak.Parent then
		cleanup()
		return
	end

	for _, track in ipairs(
		sourceAnimator:GetPlayingAnimationTracks()
	) do
		if isGraph(track) then
			sourceTrack = track
			break
		end
	end
end

if destroyed then
	return
end

for _, track in ipairs(
	targetAnimator:GetPlayingAnimationTracks()
) do
	track:Stop(0)
end

local graphAnimation = Instance.new("Animation")
graphAnimation.Name = "CreakGraph"
graphAnimation.AnimationId = GRAPH_ID

local targetTrack =
	targetAnimator:LoadAnimation(graphAnimation)

local parameterNames = {}

local function updateParameterList()
	table.clear(parameterNames)

	if not sourceTrack then
		return
	end

	local success, defaults = pcall(function()
		return sourceTrack:GetParameterDefaults()
	end)

	if not success or type(defaults) ~= "table" then
		return
	end

	for name in pairs(defaults) do
		table.insert(parameterNames, name)
	end
end

updateParameterList()

local function syncParameters()
	if destroyed then
		return
	end

	local src = sourceTrack
	local dst = targetTrack

	if not src or not dst then
		return
	end

	for i = 1, #parameterNames do
		local name = parameterNames[i]

		local success, value = pcall(
			src.GetParameter,
			src,
			name
		)

		if success and value ~= nil then
			pcall(
				dst.SetParameter,
				dst,
				name,
				value
			)
		end
	end
end

syncParameters()

targetTrack:Play(0, 1, 1)

local lastSourceTrack = sourceTrack

local preAnimationConnection
local renderConnection

preAnimationConnection = RunService.PreAnimation:Connect(function()
	if destroyed then
		preAnimationConnection:Disconnect()
		return
	end

	if sourceTrack ~= lastSourceTrack then
		lastSourceTrack = sourceTrack
		updateParameterList()
	end

	syncParameters()
end)

renderConnection = RunService.RenderStepped:Connect(function()
	if destroyed then
		renderConnection:Disconnect()
		return
	end

	if not creak.Parent then
		cleanup()
		renderConnection:Disconnect()
		return
	end

	if not clone.Parent then
		renderConnection:Disconnect()
		return
	end

	clone:PivotTo(
		creak:GetPivot() * CFrame.new(0, 2.8, 0)
	)
end)
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local NEAR_SOUND_DISTANCE = 115
local FAR_MAX_DISTANCE = 360
local FAR_MIN_VOLUME = 0.02
local MODEL_Y_OFFSET = -15
local SOUND_CONFIRM_TIME = 0.08

local HardCoreSound = workspace:WaitForChild("HardCoreSound")

local SilenceSound =
    HardCoreSound:WaitForChild("Silence")

local SilenceFarSound =
    HardCoreSound:WaitForChild("SilenceFar")

SilenceSound.Volume = 5
SilenceSound.Looped = false

SilenceFarSound.Volume = 1
SilenceFarSound.Looped = false

local player = Players.LocalPlayer

local function GetPlayerPosition1()
    local character = player.Character

    if character then
        local root = character:FindFirstChild("HumanoidRootPart")

        if root then
            return root.Position
        end
    end

    local camera = workspace.CurrentCamera

    if camera then
        return camera.CFrame.Position
    end

    return Vector3.zero
end

local function GetDistance1(position)
    return (GetPlayerPosition1() - position).Magnitude
end

local function ResetSound1(sound)
    sound:Stop()

    pcall(function()
        sound.TimePosition = 0
    end)
end

local function GetFarVolume1(distance)
    if distance <= NEAR_SOUND_DISTANCE then
        return 1
    end

    if distance >= FAR_MAX_DISTANCE then
        return FAR_MIN_VOLUME
    end

    local alpha =
        (distance - NEAR_SOUND_DISTANCE)
        / (FAR_MAX_DISTANCE - NEAR_SOUND_DISTANCE)

    local volume =
        (1 - alpha) ^ 1.25

    return math.clamp(
        volume,
        FAR_MIN_VOLUME,
        1
    )
end

local shakeID = 0
local currentShake = nil
local currentShakeOffset = CFrame.new()
local currentOriginalFOV = nil

local function StopShake1()
    local camera = workspace.CurrentCamera

    if currentShake then
        pcall(function()
            RunService:UnbindFromRenderStep(currentShake)
        end)
    end

    if camera then
        pcall(function()
            camera.CFrame =
                camera.CFrame
                * currentShakeOffset:Inverse()
        end)

        if currentOriginalFOV then
            camera.FieldOfView =
                currentOriginalFOV
        end
    end

    currentShake = nil
    currentShakeOffset = CFrame.new()
    currentOriginalFOV = nil
end

local function SilenceShake1(entityPosition)
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    StopShake1()

    shakeID += 1

    local bindName =
        "SilenceShake_" .. shakeID

    currentShake = bindName
    currentShakeOffset = CFrame.new()

    local distance =
        GetDistance1(entityPosition)

    local distancePower =
        math.clamp(
            1 - ((distance - 8) / 190),
            0.05,
            1
        )

    local shakeStrength =
        0.2
        + ((distancePower ^ 1.35) * 3.8)

    local originalFOV =
        camera.FieldOfView

    currentOriginalFOV =
        originalFOV

    local targetFOV =
        math.clamp(
            originalFOV
            + 72 * distancePower,
            originalFOV,
            120
        )

    local attackTime = 0.07
    local fadeTime = 2.1
    local totalTime =
        attackTime + fadeTime

    local started =
        os.clock()

    RunService:BindToRenderStep(
        bindName,
        Enum.RenderPriority.Camera.Value + 1,
        function()
            if currentShake ~= bindName then
                return
            end

            local elapsed =
                os.clock() - started

            if elapsed >= totalTime then
                camera.CFrame =
                    camera.CFrame
                    * currentShakeOffset:Inverse()

                currentShakeOffset =
                    CFrame.new()

                camera.FieldOfView =
                    originalFOV

                RunService:UnbindFromRenderStep(
                    bindName
                )

                if currentShake == bindName then
                    currentShake = nil
                    currentOriginalFOV = nil
                end

                return
            end

            local envelope
            local fov

            if elapsed <= attackTime then
                local alpha =
                    math.clamp(
                        elapsed / attackTime,
                        0,
                        1
                    )

                local impact =
                    1 - ((1 - alpha) ^ 5)

                envelope = impact

                fov =
                    originalFOV
                    + (
                        targetFOV
                        - originalFOV
                    )
                    * impact
            else
                local alpha =
                    math.clamp(
                        (elapsed - attackTime)
                        / fadeTime,
                        0,
                        1
                    )

                envelope =
                    (1 - alpha) ^ 1.3

                fov =
                    originalFOV
                    + (
                        targetFOV
                        - originalFOV
                    )
                    * envelope
            end

            camera.FieldOfView =
                fov

            local t =
                math.max(
                    elapsed - attackTime,
                    0
                )

            local wave1 =
                math.sin(
                    t * math.pi * 9.4
                )

            local wave2 =
                math.sin(
                    t * math.pi * 15.8
                    + 0.75
                )

            local wave3 =
                math.sin(
                    t * math.pi * 22.2
                    + 1.6
                )

            local verticalWave =
                math.sin(
                    t * math.pi * 12.6
                    + 1.15
                )

            local rollWave =
                math.sin(
                    t * math.pi * 10.1
                    + 0.35
                )

            local pitchWave =
                math.sin(
                    t * math.pi * 7.5
                    + 1.1
                )

            local x =
                (
                    wave1 * 0.22
                    + wave2 * 0.07
                    + wave3 * 0.025
                )
                * shakeStrength
                * envelope

            local y =
                verticalWave
                * 0.032
                * shakeStrength
                * envelope

            local yaw =
                (
                    wave1 * math.rad(0.6)
                    + wave2 * math.rad(0.18)
                )
                * shakeStrength
                * envelope

            local roll =
                rollWave
                * math.rad(0.88)
                * shakeStrength
                * envelope

            local pitch =
                pitchWave
                * math.rad(0.14)
                * shakeStrength
                * envelope

            local newOffset =
                CFrame.new(
                    x,
                    y,
                    0
                )
                * CFrame.Angles(
                    pitch,
                    yaw,
                    roll
                )

            camera.CFrame =
                camera.CFrame
                * currentShakeOffset:Inverse()
                * newOffset

            currentShakeOffset =
                newOffset
        end
    )
end

local jumpscareActive = false
local jumpscareFinished = false

local function TriggerJumpscare1()
    if jumpscareActive or jumpscareFinished then
        return
    end

    jumpscareActive = true

    ResetSound1(SilenceFarSound)
    ResetSound1(SilenceSound)

    SilenceSound.Volume = 5
    SilenceSound:Play()

    StopShake1()

    local character =
        player.Character

    if not character then
        jumpscareActive = false
        return
    end

    local humanoid =
        character:FindFirstChildOfClass(
            "Humanoid"
        )

    local playerGui =
        player:WaitForChild(
            "PlayerGui"
        )

    local oldGui =
        playerGui:FindFirstChild(
            "SilenceJumpscare"
        )

    if oldGui then
        oldGui:Destroy()
    end

    local gui =
        Instance.new("ScreenGui")

    gui.Name =
        "SilenceJumpscare"

    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000000

    gui.ZIndexBehavior =
        Enum.ZIndexBehavior.Sibling

    gui.Parent =
        playerGui

    local black =
        Instance.new("Frame")

    black.Size =
        UDim2.fromScale(1, 1)

    black.Position =
        UDim2.fromScale(0, 0)

    black.BackgroundColor3 =
        Color3.new(0, 0, 0)

    black.BorderSizePixel = 0
    black.ZIndex = 1
    black.Parent = gui

    local snow =
        Instance.new("ImageLabel")

    snow.AnchorPoint =
        Vector2.new(0.5, 0.5)

    snow.Position =
        UDim2.fromScale(0.5, 0.5)

    snow.Size =
        UDim2.fromScale(1.1, 1.1)

    snow.BackgroundTransparency = 1
    snow.ImageTransparency = 0

    snow.ScaleType =
        Enum.ScaleType.Stretch

    snow.ZIndex = 2
    snow.Parent = gui

    local jumpscare =
        Instance.new("ImageLabel")

    jumpscare.AnchorPoint =
        Vector2.new(0.5, 0.5)

    jumpscare.Position =
        UDim2.fromScale(0.5, 0.5)

    jumpscare.Size =
        UDim2.fromScale(1.02, 1.02)

    jumpscare.BackgroundTransparency = 1

    jumpscare.Image =
        "rbxassetid://14359776338"

    jumpscare.ImageTransparency = 0

    jumpscare.ScaleType =
        Enum.ScaleType.Stretch

    jumpscare.ZIndex = 3
    jumpscare.Parent = gui

    local snowImages = {
        "rbxassetid://117266253034518",
        "rbxassetid://8454012934",
        "rbxassetid://122347391038526"
    }

    snow.Image =
        snowImages[1]

    local camera =
        workspace.CurrentCamera

    local originalFOV =
        camera and camera.FieldOfView or 70

    local duration = 0.8
    local started = os.clock()
    local snowIndex = 1
    local lastSnow = 0

    while true do
        local elapsed =
            os.clock() - started

        local alpha =
            math.clamp(
                elapsed / duration,
                0,
                1
            )

        if elapsed - lastSnow >= 0.045 then
            lastSnow = elapsed

            snowIndex += 1

            if snowIndex > #snowImages then
                snowIndex = 1
            end

            snow.Image =
                snowImages[snowIndex]
        end

        local curve =
            1 - ((1 - alpha) ^ 3)

        local pulse =
            math.sin(
                alpha
                * math.pi
                * 9
            )

        local scale =
            1.02
            + curve * 0.12
            + pulse
            * 0.014
            * (1 - alpha)

        jumpscare.Size =
            UDim2.fromScale(
                scale,
                scale
            )

        jumpscare.Rotation =
            math.sin(
                alpha
                * math.pi
                * 11
            )
            * 0.75
            * (1 - alpha)

        local snowScale =
            1.1
            + math.sin(
                alpha
                * math.pi
                * 13
            )
            * 0.02

        snow.Size =
            UDim2.fromScale(
                snowScale,
                snowScale
            )

        if camera then
            camera.FieldOfView =
                originalFOV
                + 8 * curve
                + (
                    math.sin(
                        alpha
                        * math.pi
                        * 8
                    )
                    * 1.5
                    * (1 - alpha)
                )
        end

        if alpha >= 1 then
            break
        end

        RunService.RenderStepped:Wait()
    end

    if humanoid and humanoid.Parent then
        humanoid:TakeDamage(100)
    end

    local fadeDuration =
        0.45

    local fadeStarted =
        os.clock()

    while true do
        local alpha =
            math.clamp(
                (os.clock() - fadeStarted)
                / fadeDuration,
                0,
                1
            )

        local eased =
            1 - ((1 - alpha) ^ 3)

        jumpscare.ImageTransparency =
            eased

        snow.ImageTransparency =
            eased

        black.BackgroundTransparency =
            eased

        jumpscare.Size =
            UDim2.fromScale(
                1.14
                + eased * 0.04,
                1.14
                + eased * 0.04
            )

        if camera then
            camera.FieldOfView =
                originalFOV
                + 8
                * (1 - eased)
        end

        if alpha >= 1 then
            break
        end

        RunService.RenderStepped:Wait()
    end

    if camera then
        camera.FieldOfView =
            originalFOV
    end

    gui:Destroy()

    jumpscareFinished = true
    jumpscareActive = false
end

local soundWatchConnection = nil
local soundConnections = {}
local soundConfirmTokens = {}
local nearSilence = false

local function IsRealPlayingSound1(object)
    if not object then
        return false
    end

    if not object:IsA("Sound") then
        return false
    end

    local character =
        player.Character

    if not character then
        return false
    end

    if not object:IsDescendantOf(character) then
        return false
    end

    if object.SoundId == "" then
        return false
    end

    if object.Volume <= 0 then
        return false
    end

    if not object.Playing then
        return false
    end

    return true
end

local function CancelSoundConfirmation1(sound)
    soundConfirmTokens[sound] =
        (soundConfirmTokens[sound] or 0) + 1
end

local function ConfirmPlayingSound1(sound)
    if not nearSilence then
        return
    end

    if jumpscareActive or jumpscareFinished then
        return
    end

    if not IsRealPlayingSound1(sound) then
        return
    end

    soundConfirmTokens[sound] =
        (soundConfirmTokens[sound] or 0) + 1

    local token =
        soundConfirmTokens[sound]

    task.delay(
        SOUND_CONFIRM_TIME,
        function()
            if not nearSilence then
                return
            end

            if jumpscareActive or jumpscareFinished then
                return
            end

            if soundConfirmTokens[sound] ~= token then
                return
            end

            if not sound or not sound.Parent then
                return
            end

            if not IsRealPlayingSound1(sound) then
                return
            end

            task.spawn(
                TriggerJumpscare1
            )
        end
    )
end

local function DisconnectWatchedSound1(sound)
    local connections =
        soundConnections[sound]

    if connections then
        for _, connection in ipairs(
            connections
        ) do
            if connection then
                connection:Disconnect()
            end
        end
    end

    soundConnections[sound] = nil
    soundConfirmTokens[sound] = nil
end

local function WatchSound1(sound)
    if not sound:IsA("Sound") then
        return
    end

    DisconnectWatchedSound1(sound)

    soundConnections[sound] = {}

    table.insert(
        soundConnections[sound],
        sound:GetPropertyChangedSignal(
            "Playing"
        ):Connect(function()
            if sound.Playing then
                ConfirmPlayingSound1(sound)
            else
                CancelSoundConfirmation1(sound)
            end
        end)
    )

    table.insert(
        soundConnections[sound],
        sound.AncestryChanged:Connect(
            function()
                local character =
                    player.Character

                if
                    not character
                    or not sound:IsDescendantOf(character)
                then
                    CancelSoundConfirmation1(sound)
                    DisconnectWatchedSound1(sound)
                end
            end
        )
    )

    if sound.Playing then
        ConfirmPlayingSound1(sound)
    end
end

local function StopSoundWatcher1()
    nearSilence = false

    if soundWatchConnection then
        soundWatchConnection:Disconnect()
        soundWatchConnection = nil
    end

    local sounds = {}

    for sound in pairs(
        soundConnections
    ) do
        table.insert(
            sounds,
            sound
        )
    end

    for _, sound in ipairs(
        sounds
    ) do
        CancelSoundConfirmation1(sound)
        DisconnectWatchedSound1(sound)
    end

    table.clear(
        soundConfirmTokens
    )
end

local function StartSoundWatcher1()
    StopSoundWatcher1()

    local character =
        player.Character

    if not character then
        return
    end

    nearSilence = true

    for _, object in ipairs(
        character:GetDescendants()
    ) do
        if object:IsA("Sound") then
            WatchSound1(object)
        end
    end

    soundWatchConnection =
        character.DescendantAdded:Connect(
            function(object)
                if not nearSilence then
                    return
                end

                if object:IsA("Sound") then
                    WatchSound1(object)
                end
            end
        )
end

local audioToken = 0

local function StartRoomAudio1(
    entityPosition,
    totalDuration
)
    audioToken += 1

    local token =
        audioToken

    ResetSound1(SilenceSound)
    ResetSound1(SilenceFarSound)

    task.spawn(
        SilenceShake1,
        entityPosition
    )

    task.spawn(function()
        local started =
            os.clock()

        local currentMode =
            nil

        while
            audioToken == token
            and not jumpscareFinished
            and os.clock() - started < totalDuration
        do
            local distance =
                GetDistance1(
                    entityPosition
                )

            if distance <= NEAR_SOUND_DISTANCE then
                if currentMode ~= "near" then
                    ResetSound1(
                        SilenceFarSound
                    )

                    ResetSound1(
                        SilenceSound
                    )

                    SilenceSound.Volume =
                        5

                    SilenceSound:Play()

                    currentMode =
                        "near"
                end

                if not nearSilence then
                    StartSoundWatcher1()
                end
            else
                if nearSilence then
                    StopSoundWatcher1()
                end

                local farVolume =
                    GetFarVolume1(
                        distance
                    )

                if currentMode ~= "far" then
                    ResetSound1(
                        SilenceSound
                    )

                    ResetSound1(
                        SilenceFarSound
                    )

                    SilenceFarSound.Volume =
                        farVolume

                    SilenceFarSound:Play()

                    currentMode =
                        "far"
                else
                    SilenceFarSound.Volume =
                        farVolume
                end
            end

            RunService.Heartbeat:Wait()
        end

        if nearSilence then
            StopSoundWatcher1()
        end
    end)
end

function entityBehaviors.Silence()
    jumpscareActive = false
    jumpscareFinished = false

    StopSoundWatcher1()

    local CurrentRooms =
        workspace:WaitForChild(
            "CurrentRooms"
        )

    local rooms = {}

    for _, room in ipairs(
        CurrentRooms:GetChildren()
    ) do
        local number =
            tonumber(room.Name)

        if
            number
            and number >= 1
            
        then
            table.insert(
                rooms,
                {
                    Number = number,
                    Room = room
                }
            )
        end
    end

    table.sort(
        rooms,
        function(a, b)
            return
                a.Number
                < b.Number
        end
    )

    if #rooms == 0 then
        return
    end

    local loaded =
        game:GetObjects(
            "rbxassetid://131690436250513"
        )

    local Silence =
        loaded[1]

    if not Silence then
        return
    end

    if not Silence:IsA("Model") then
        local holder =
            Instance.new("Model")

        holder.Name =
            "Silence"

        Silence.Parent =
            holder

        Silence =
            holder
    end

    Silence.Name =
        "Silence"

    Silence.Parent =
        workspace

    for _, object in ipairs(
        Silence:GetDescendants()
    ) do
        if object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
        end
    end

    local modelRotation =
        Silence:GetPivot().Rotation

    Silence:PivotTo(
        CFrame.new(
            0,
            0,
            0
        )
        * modelRotation
    )

    local modelBoxCF,
        modelBoxSize =
        Silence:GetBoundingBox()

    local modelBottom =
        modelBoxCF.Position.Y
        - modelBoxSize.Y * 0.5

    local bottomOffset =
        -modelBottom

    local function GetRoomSize1(room)
        if room:IsA("Model") then
            local _, size =
                room:GetBoundingBox()

            return size
        end

        if room:IsA("BasePart") then
            return room.Size
        end

        return Vector3.new(
            30,
            20,
            30
        )
    end

    local function FindFloor1(room)
        local entrance =
            room:FindFirstChild(
                "RoomEntrance"
            )

        if not entrance then
            entrance =
                room:FindFirstChild(
                    "RoomEntrance",
                    true
                )
        end

        if
            entrance
            and entrance:IsA("BasePart")
        then
            local targetCF =
                entrance.CFrame
                * CFrame.new(
                    0,
                    0,
                    -15
                )

            local target =
                targetCF.Position

            local params =
                RaycastParams.new()

            params.FilterType =
                Enum.RaycastFilterType.Include

            params.FilterDescendantsInstances = {
                room
            }

            params.IgnoreWater =
                true

            local origin =
                target
                + Vector3.new(
                    0,
                    35,
                    0
                )

            local result =
                workspace:Raycast(
                    origin,
                    Vector3.new(
                        0,
                        -90,
                        0
                    ),
                    params
                )

            if result then
                return
                    result.Position,
                    GetRoomSize1(room)
            end

            return
                target,
                GetRoomSize1(room)
        end

        if room:IsA("Model") then
            local cf, size =
                room:GetBoundingBox()

            local params =
                RaycastParams.new()

            params.FilterType =
                Enum.RaycastFilterType.Include

            params.FilterDescendantsInstances = {
                room
            }

            params.IgnoreWater =
                true

            local origin =
                cf.Position
                + Vector3.new(
                    0,
                    size.Y * 0.5 + 10,
                    0
                )

            local result =
                workspace:Raycast(
                    origin,
                    Vector3.new(
                        0,
                        -(size.Y + 30),
                        0
                    ),
                    params
                )

            if result then
                return
                    result.Position,
                    size
            end

            return
                Vector3.new(
                    cf.Position.X,
                    cf.Position.Y
                    - size.Y * 0.5,
                    cf.Position.Z
                ),
                size
        end

        if room:IsA("BasePart") then
            return
                room.Position
                - Vector3.new(
                    0,
                    room.Size.Y * 0.5,
                    0
                ),
                room.Size
        end

        return
            Vector3.zero,
            Vector3.new(
                30,
                20,
                30
            )
    end

    local function PivotSilence1(position)
        Silence:PivotTo(
            CFrame.new(position)
            * modelRotation
        )
    end

    local function MoveVertical1(
        startPosition,
        endPosition,
        duration,
        descending
    )
        local started =
            os.clock()

        while true do
            if jumpscareFinished then
                return false
            end

            local alpha =
                math.clamp(
                    (os.clock() - started)
                    / duration,
                    0,
                    1
                )

            local eased

            if descending then
                eased =
                    1
                    - ((1 - alpha) ^ 4)
            else
                eased =
                    alpha ^ 4
            end

            PivotSilence1(
                startPosition:Lerp(
                    endPosition,
                    eased
                )
            )

            if alpha >= 1 then
                break
            end

            RunService.RenderStepped:Wait()
        end

        PivotSilence1(
            endPosition
        )

        return true
    end

    local MAX_SILENCE_ROOMS = 10

    local startRoomIndex = 1

    if #rooms > MAX_SILENCE_ROOMS then
        startRoomIndex = #rooms - 8
    end

    for roomIndex = startRoomIndex, #rooms do

        local data = rooms[roomIndex]
        if jumpscareFinished then
            break
        end

        local floorPosition,
            roomSize =
            FindFloor1(
                data.Room
            )

        local landingPosition =
            floorPosition
            + Vector3.new(
                0,
                bottomOffset
                + MODEL_Y_OFFSET,
                0
            )

        local spawnHeight =
            math.max(
                roomSize.Y + 35,
                45
            )

        local upperPosition =
            landingPosition
            + Vector3.new(
                0,
                spawnHeight,
                0
            )

        PivotSilence1(
            upperPosition
        )

        StartRoomAudio1(
            landingPosition,
            5.2
        )

        local moved =
            MoveVertical1(
                upperPosition,
                landingPosition,
                0.52,
                true
            )

        if not moved then
            break
        end

        local holdStarted =
            os.clock()

        while
            os.clock()
            - holdStarted
            < 4
        do
            if jumpscareFinished then
                break
            end

            RunService.Heartbeat:Wait()
        end

        if jumpscareFinished then
            break
        end

        moved =
            MoveVertical1(
                landingPosition,
                upperPosition,
                0.42,
                false
            )

        if not moved then
            break
        end
    end

    audioToken += 1

    StopSoundWatcher1()

    ResetSound1(
        SilenceFarSound
    )

    if Silence and Silence.Parent then
        Silence:Destroy()
    end
end

function entityBehaviors.DeerGod()
local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Debris = game:GetService("Debris")

    local entityModel = nil
    local chaseConnection = nil
    local lockedPlayer = nil

    local customSpeed = 20
    local lockRange = 250

    local teleportDistance = 80
    local teleportForwardOffset = 50
    local teleportStartDelay = 20

    local canTeleport = false

    local player = Players.LocalPlayer

    local glitchGui = nil
    local glitchConnection = nil


    local function CreateDeerGodGlitch()

        glitchGui = Instance.new("ScreenGui")
        glitchGui.Name = "DeerGodGlitch"
        glitchGui.IgnoreGuiInset = true
        glitchGui.ResetOnSpawn = false
        glitchGui.Parent = player:WaitForChild("PlayerGui")

        local noise = Instance.new("ImageLabel")
        noise.Parent = glitchGui
        noise.Size = UDim2.new(1,0,1,0)
        noise.BackgroundTransparency = 1
        noise.Image = "rbxassetid://8116159092"
        noise.ScaleType = Enum.ScaleType.Tile
        noise.TileSize = UDim2.new(0,180,0,180)
        noise.ImageTransparency = 0.92


        glitchConnection = RunService.RenderStepped:Connect(function()

            if not glitchGui or not glitchGui.Parent then
                return
            end

            noise.ImageTransparency = 0.86 + math.random()*0.1

            noise.Position = UDim2.new(
                0,
                math.random(-6,6),
                0,
                math.random(-6,6)
            )

            if math.random() < 0.08 then

                local bar = Instance.new("Frame")
                bar.Parent = glitchGui
                bar.Size = UDim2.new(
                    math.random(20,80)/100,
                    0,
                    0,
                    math.random(2,8)
                )

                bar.Position = UDim2.new(
                    math.random(),
                    0,
                    math.random(),
                    0
                )

                bar.BackgroundColor3 = Color3.new(
                    math.random(),
                    math.random(),
                    math.random()
                )

                bar.BackgroundTransparency = 0.8
                bar.BorderSizePixel = 0

                Debris:AddItem(bar,0.08)

            end

        end)

    end


    local entity = spawner.Create({

        Entity = {
            Name = "Deer god",
            Asset = "101210986101880",
            HeightOffset = -4
        },

        Lights = {
            Flicker = {
                Enabled = true,
                Duration = 50
            },
            Shatter = true,
            Repair = false
        },

        CameraShake = {
            Enabled = true,
            Range = 1500,
            Values = {0.5,5,0.1,1}
        },

        Movement = {
            Speed = 20,
            Delay = 2,
            Reversed = true
        },

        Damage = {
            Enabled = true,
            Range = 10,
            Amount = 200
        },

        Crucifixion = {
            Enabled = true,
            Range = 40,
            Resist = true,
            Break = true
        },
                Death = {
            Type = "Curious",
            Hints = {
                "看起来你真倒霉...",
                "你被所谓的鹿神击杀了",
                "不要理它过于遥远",
                "十字架不能保证你的安全"
            },
            Cause = "Deer God"
        }
    })

    local function FindTarget()

        local nearest = nil
        local shortest = math.huge

        local pos = entityModel.PrimaryPart.Position

        for _,p in ipairs(Players:GetPlayers()) do

            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if root and hum and hum.Health > 0 then

                local dist = (root.Position-pos).Magnitude

                if dist < shortest and dist <= lockRange then
                    shortest = dist
                    nearest = p
                end

            end
        end

        return nearest
    end


    entity:SetCallback("OnSpawned",function()

        entityModel = entity.Model

        if entityModel and not entityModel.PrimaryPart then
            entityModel.PrimaryPart =
                entityModel:FindFirstChild("Main")
                or entityModel:FindFirstChildWhichIsA("BasePart")
        end


        if not entityModel or not entityModel.PrimaryPart then
            return
        end


        CreateDeerGodGlitch()

        lockedPlayer = FindTarget()


        task.delay(teleportStartDelay,function()

            if entityModel and lockedPlayer then
                canTeleport = true
            end

        end)


        chaseConnection = RunService.Heartbeat:Connect(function(dt)

            if not entityModel or not entityModel.PrimaryPart then
                return
            end

            if not lockedPlayer then
                return
            end


            local char = lockedPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")


            if not root or not hum then
                return
            end


            if hum.Health <= 0 then

                if chaseConnection then
                    chaseConnection:Disconnect()
                end

                entityModel:Destroy()
                entityModel=nil
                lockedPlayer=nil

                return

            end


            local pos = entityModel.PrimaryPart.Position
            local target = root.Position

            local distance = (target-pos).Magnitude


            if canTeleport and distance >= teleportDistance then

                local forwardPosition =
                    root.Position +
                    root.CFrame.LookVector * teleportForwardOffset


                entityModel:SetPrimaryPartCFrame(
                    CFrame.lookAt(
                        forwardPosition,
                        forwardPosition-root.CFrame.LookVector
                    )
                )


                local sound = Instance.new("Sound")
                sound.SoundId = "rbxassetid://131811476310735"
                sound.Volume = 8
                sound.Parent = entityModel.PrimaryPart

                sound:Play()

                sound.Ended:Connect(function()
                    sound:Destroy()
                end)

                return
            end


            local direction = (target-pos).Unit
            local newPos = pos + direction*customSpeed*dt


            entityModel:SetPrimaryPartCFrame(
                CFrame.lookAt(
                    newPos,
                    newPos-direction
                )
            )

        end)


        task.delay(85,function()

            if chaseConnection then
                chaseConnection:Disconnect()
            end

            if entityModel then
                entityModel:Destroy()
            end

            local folder = workspace:FindFirstChild("HardCoreSound")

            if folder then
                local sound = folder:FindFirstChild("DeerGodMusic")
                if sound then
                    sound:Stop()
                end
            end

            if glitchConnection then
                glitchConnection:Disconnect()
            end

            if glitchGui then
                glitchGui:Destroy()
            end

        end)

    end)


    entity:Run()


    local folder = workspace:FindFirstChild("HardCoreSound")

    if folder then
        local music = folder:FindFirstChild("DeerGodMusic")
        if music then
            music:Play()
        end
    end
end
function entityBehaviors.FrostBite()
function GetRoom()
	local rooms = workspace:FindFirstChild("CurrentRooms")
	local gameData = game.ReplicatedStorage:FindFirstChild("GameData")
	local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")

	if not rooms or not latestRoom then
		return nil
	end

	return rooms:FindFirstChild(tostring(latestRoom.Value))
end

function LoadCustomInstance(source, parent)
	local model

	while task.wait() and not model do
		local success, result = pcall(function()
			return game:GetObjects("rbxassetid://" .. tostring(source))[1]
		end)

		if success and result then
			model = result
		end

		if model then
			model.Parent = parent or workspace

			for _, v in ipairs(model:GetDescendants()) do
				if v:IsA("Script") or v:IsA("LocalScript") then
					v:Destroy()
				end
			end
		end
	end

	return model
end

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local s = LoadCustomInstance("83840759413024", workspace)
if not s then
	return
end

local entity = s:FindFirstChildWhichIsA("BasePart")
if not entity then
	s:Destroy()
	return
end

local firstRoom = GetRoom()
if not firstRoom or not firstRoom:FindFirstChild("RoomEntrance") then
	s:Destroy()
	return
end

entity.CFrame = firstRoom.RoomEntrance.CFrame * CFrame.new(0, 5, -15)

local effectNames = {
	"face",
	"Heylois",
	"BlackTrai2l",
	"BlackTrai3l"
}

local function SetEntityEffectsEnabled(state)
	local attachment = entity:FindFirstChild("Attachment")
	if not attachment then
		return
	end

	for _, name in ipairs(effectNames) do
		local effect = attachment:FindFirstChild(name)
		if effect and effect:IsA("ParticleEmitter") or effect and effect:IsA("Trail") or effect and effect:IsA("Beam") then
			effect.Enabled = state
		elseif effect and effect:IsA("Light") then
			effect.Enabled = state
		end
	end
end

SetEntityEffectsEnabled(false)

local staticSounds = {}

for _, v in ipairs(s:GetDescendants()) do
	if v:IsA("Sound") and v.Name == "Static Effect" then
		v.Looped = true
		v:Play()
		table.insert(staticSounds, v)
	end
end

local hardcore = workspace:FindFirstChild("HardCoreSound")
local music

local function PlayMusic(name, looped, waitForLoad)
	if music then
		music:Stop()
		music:Destroy()
		music = nil
	end

	if not hardcore then
		return nil
	end

	local source = hardcore:FindFirstChild(name)
	if not source or not source:IsA("Sound") then
		return nil
	end

	music = source:Clone()
	music.Parent = workspace
	music.Looped = looped

	if waitForLoad and not music.IsLoaded then
		local started = os.clock()

		while music.Parent and not music.IsLoaded and os.clock() - started < 3 do
			task.wait()
		end
	end

	music:Play()
	return music
end

PlayMusic("F1", true)

local frost = Instance.new("ColorCorrectionEffect")
frost.Parent = game.Lighting

TweenService:Create(
	frost,
	TweenInfo.new(10),
	{
		TintColor = Color3.fromRGB(217, 250, 255),
		Saturation = -0.7,
		Contrast = 0.2
	}
):Play()

local light = Instance.new("PointLight")
light.Range = 60
light.Brightness = 99999
light.Parent = entity

TweenService:Create(
	light,
	TweenInfo.new(3),
	{
		Brightness = 0
	}
):Play()

local finished = false
local camShake
local cameraShakerModule = ReplicatedStorage:FindFirstChild("CameraShaker")

if cameraShakerModule then
	local success, shaker = pcall(require, cameraShakerModule)

	if success and shaker then
		camShake = shaker.new(
			Enum.RenderPriority.Camera.Value,
			function(cf)
				camera = workspace.CurrentCamera

				if camera then
					camera.CFrame = camera.CFrame * cf
				end
			end
		)

		camShake:Start()

		task.spawn(function()
			while entity.Parent and not finished do
				camera = workspace.CurrentCamera

				if camera then
					local distance = (camera.CFrame.Position - entity.Position).Magnitude
					local power = math.clamp(1 - distance / 120, 0, 1)

					if power > 0 then
						camShake:ShakeOnce(
							power * 8,
							40,
							0.05,
							0.35,
							Vector3.new(0.15, 0.15, 0.15),
							Vector3.new(1, 1, 1)
						)
					end
				end

				task.wait(0.15)
			end
		end)
	end
end

task.wait(5)

for _, v in ipairs(staticSounds) do
	v:Stop()
end

SetEntityEffectsEnabled(true)

pcall(function()
	entity.Ambience:Play()
	entity.AmbienceFar:Play()
end)

local function LerpNumberSequenceToOne(sequence, alpha)
	local keypoints = {}

	for _, keypoint in ipairs(sequence.Keypoints) do
		local value = keypoint.Value + (1 - keypoint.Value) * alpha
		local envelope = keypoint.Envelope * (1 - alpha)

		table.insert(
			keypoints,
			NumberSequenceKeypoint.new(
				keypoint.Time,
				value,
				envelope
			)
		)
	end

	return NumberSequence.new(keypoints)
end

local finalFadeStarted = false

local function StartFinalFade(duration)
	if finalFadeStarted then
		return
	end

	finalFadeStarted = true
	duration = math.max(tonumber(duration) or 5, 0.1)

	pcall(function()
		entity.Ambience:Stop()
		entity.AmbienceFar:Stop()
	end)

	SetEntityEffectsEnabled(false)

	local des = Instance.new("Sound")
	des.SoundId = "rbxassetid://111715441853991"
	des.Volume = 0.5
	des.Parent = workspace
	des:Play()
	Debris:AddItem(des, math.max(duration + 2, 10))

	local particleData = {}

	for _, v in ipairs(s:GetDescendants()) do
		if v:IsA("BasePart") then
			TweenService:Create(
				v,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{
					Transparency = 1
				}
			):Play()
		elseif v:IsA("Decal") or v:IsA("Texture") then
			TweenService:Create(
				v,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{
					Transparency = 1
				}
			):Play()
		elseif v:IsA("Light") then
			TweenService:Create(
				v,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{
					Brightness = 0
				}
			):Play()
		elseif v:IsA("ParticleEmitter") then
			table.insert(
				particleData,
				{
					Object = v,
					Transparency = v.Transparency
				}
			)
		end
	end

	local fadeValue = Instance.new("NumberValue")
	fadeValue.Value = 0

	local changedConnection
	changedConnection = fadeValue:GetPropertyChangedSignal("Value"):Connect(function()
		for _, data in ipairs(particleData) do
			if data.Object and data.Object.Parent then
				data.Object.Transparency = LerpNumberSequenceToOne(
					data.Transparency,
					fadeValue.Value
				)
			end
		end
	end)

	local particleTween = TweenService:Create(
		fadeValue,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{
			Value = 1
		}
	)

	particleTween:Play()

	particleTween.Completed:Connect(function()
		if changedConnection then
			changedConnection:Disconnect()
		end

		for _, data in ipairs(particleData) do
			if data.Object and data.Object.Parent then
				data.Object.Transparency = NumberSequence.new(1)
				data.Object.Enabled = false
			end
		end

		fadeValue:Destroy()
	end)

	if frost and frost.Parent then
		TweenService:Create(
			frost,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{
				TintColor = Color3.fromRGB(255, 255, 255),
				Saturation = 0,
				Contrast = 0
			}
		):Play()
	end
end

local roomCount = 0
local gameData = ReplicatedStorage:FindFirstChild("GameData")
local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")

if not latestRoom then
	finished = true
end

task.spawn(function()
	if not latestRoom then
		return
	end

	while roomCount < 5 and not finished do
		latestRoom.Changed:Wait()

		if finished then
			break
		end

		roomCount += 1

		local room = GetRoom()

		if room and room:FindFirstChild("RoomEntrance") and entity.Parent then
			local value = Instance.new("CFrameValue")
			value.Value = entity.CFrame

			local connection
			connection = value:GetPropertyChangedSignal("Value"):Connect(function()
				if entity.Parent then
					entity.CFrame = value.Value
				end
			end)

			local tween = TweenService:Create(
				value,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{
					Value = room.RoomEntrance.CFrame * CFrame.new(0, 5, -15)
				}
			)

			tween:Play()
			tween.Completed:Wait()

			if connection then
				connection:Disconnect()
			end

			value:Destroy()
		end

		if roomCount == 3 then
			PlayMusic("F2", true)
		elseif roomCount == 5 then
			local f3 = PlayMusic("F3", false, true)
			local fadeDuration = 5

			if f3 and f3.TimeLength > 0 then
				fadeDuration = f3.TimeLength
			end

			StartFinalFade(fadeDuration)

			if f3 then
				local ended = false
				local endedConnection

				endedConnection = f3.Ended:Connect(function()
					ended = true
				end)

				local started = os.clock()

				while f3.Parent and not ended and os.clock() - started < fadeDuration + 2 do
					task.wait()
				end

				if endedConnection then
					endedConnection:Disconnect()
				end
			else
				task.wait(fadeDuration)
			end

			finished = true
			break
		end
	end
end)

task.spawn(function()
	while not finished do
		task.wait(1)

		if finished then
			break
		end

		local safe = false
		local lighter = chr:FindFirstChild("Lighter")

		if lighter and lighter:FindFirstChild("Handle") then
			local holder = lighter.Handle:FindFirstChild("EffectsHolder")

			if holder and holder:FindFirstChild("AttachOn") then
				local main = holder.AttachOn:FindFirstChild("MainLight")

				if main and main:IsA("PointLight") then
					safe = main.Enabled
				end
			end
		end

		if not safe then
			pcall(function()
				local humanoid = chr:FindFirstChildOfClass("Humanoid")

				if humanoid and humanoid.Health > 0 then
					humanoid.Health -= 5
				end
			end)
		end
	end
end)

repeat
	task.wait()
until finished

dmg = false
roomChanged = true

if camShake then
	pcall(function()
		camShake:Stop()
	end)
end

pcall(function()
	entity.Ambience:Stop()
	entity.AmbienceFar:Stop()
end)

SetEntityEffectsEnabled(false)

if music then
	music:Stop()
	music:Destroy()
	music = nil
end

if s and s.Parent then
	s:Destroy()
end

if frost and frost.Parent then
	frost:Destroy()
end
end
function entityBehaviors.HATRED()
local HATRED_PREPARED_SOUND = nil

local function getHatredSound()
    local folder = game:GetService("Workspace"):FindFirstChild("HardCoreSound")
    if not folder then
        return nil
    end

    local sound = folder:FindFirstChild("HATRED")
    if sound and sound:IsA("Sound") then
        HATRED_PREPARED_SOUND = sound
        return sound
    end

    return nil
end

local function createPreparedHatredSound()
    return getHatredSound()
end

do
    createPreparedHatredSound()
end

_G.entityBehaviors = entityBehaviors
if type(getgenv) == "function" then
    getgenv().entityBehaviors = entityBehaviors
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
if not player then
    return
end

if type(_G.HatredBossController) == "table"
    and type(_G.HatredBossController.Stop) == "function" then
    pcall(_G.HatredBossController.Stop)
end

local CONFIG = {
    ModelId = 94520721608869,
    MusicVolume = 0.8,

    StartDistance = 120,
    StopDistance = 15,
    ApproachDuration = 20,
    HoverHeight = 3,
    HoverDuration = 260,

    FlickerDuration = 260,
    FlickerAmount = 30,
    ShakeDuration = 260,
    ShakeIntensity = 0.7,

    PhaseGoals = {10, 15, 20},
    PhaseTimes = {20, 30, 30},
    BluePenalty = 3,
    PhaseTransitionSoundId = 102844356541414,
    PhaseTransitionDelay = 2.2,

    FailureFadeDuration = 5,
    FailureStormDuration = 13,
    FailureVoidDuration = 2.5,
    FaceSwapDuration = 0.1,
    FaceSwapMinDelay = 1.4,
    FaceSwapMaxDelay = 3.2,
    FailureSoundId = 139866863795650,
    FailureSoundVolume = 4,
}

local COLORS = {
    Background = Color3.fromRGB(7, 8, 14),
    Panel = Color3.fromRGB(17, 19, 29),
    Panel2 = Color3.fromRGB(27, 29, 43),
    Text = Color3.fromRGB(242, 244, 255),
    Muted = Color3.fromRGB(151, 157, 183),
    Red = Color3.fromRGB(255, 54, 72),
    RedDark = Color3.fromRGB(138, 22, 42),
    Blue = Color3.fromRGB(48, 128, 255),
    Gold = Color3.fromRGB(255, 195, 77),
    Green = Color3.fromRGB(87, 232, 151),
}

local State = {
    running = false,
    ending = false,
    cleaned = false,
    token = 0,
    phase = 0,
    clicks = 0,
    deadline = 0,

    connections = {},
    tweens = {},
    targetTweens = {},
    instances = {},

    music = nil,
    phaseSound = nil,
    failureSound = nil,
    boss = nil,
    blur = nil,
    gui = nil,
    ui = nil,
    inventory = nil,
    bossConnection = nil,
    mouseConnection = nil,

    originalMouseBehavior = nil,
    originalMouseIconEnabled = nil,
    originalInventoryVisible = nil,
}

local Controller = {}
_G.HatredBossController = Controller

local function alive(token)
    return State.running and not State.cleaned and State.token == token
end

local function addConnection(connection)
    if connection then
        table.insert(State.connections, connection)
    end
    return connection
end

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function destroy(instance)
    if instance and instance.Parent then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function playTween(instance, info, goal)
    if not instance or not instance.Parent then
        return nil
    end
    local tween = TweenService:Create(instance, info, goal)
    table.insert(State.tweens, tween)
    tween:Play()
    return tween
end

local function waitCancelable(seconds, token)
    local finishAt = os.clock() + seconds
    while os.clock() < finishAt do
        if not alive(token) then
            return false
        end
        task.wait(math.max(0, math.min(0.1, finishAt - os.clock())))
    end
    return alive(token)
end

local function safeCaption(text)
    pcall(function()
        local mainUI = player:WaitForChild("PlayerGui", 3):FindFirstChild("MainUI")
        local initiator = mainUI and mainUI:FindFirstChild("Initiator")
        local mainGame = initiator and initiator:FindFirstChild("Main_Game")
        if mainGame then
            require(mainGame).caption(text, true)
        end
    end)
end

local function getCharacterParts(timeout)
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart", timeout or 5)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return character, root, humanoid
end

local function startRoomFlicker()
    task.spawn(function()
        pcall(function()
            local gameData = ReplicatedStorage:FindFirstChild("GameData")
            local latestRoomValue = gameData and gameData:FindFirstChild("LatestRoom")
            local rooms = Workspace:FindFirstChild("CurrentRooms")
            local room = latestRoomValue and rooms and rooms:FindFirstChild(tostring(latestRoomValue.Value))
            local modules = ReplicatedStorage:FindFirstChild("ModulesClient")
            local eventModule = modules and modules:FindFirstChild("Module_Events")
            if room and eventModule then
                require(eventModule).flicker(room, CONFIG.FlickerDuration, CONFIG.FlickerAmount)
            end
        end)
    end)
end

local SHAKE_BIND_NAME = "HatredBossCameraShake"

local function startCameraShake(token)
    pcall(function()
        RunService:UnbindFromRenderStep(SHAKE_BIND_NAME)
    end)

    local startedAt = os.clock()
    RunService:BindToRenderStep(SHAKE_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
        if not alive(token) then
            pcall(function()
                RunService:UnbindFromRenderStep(SHAKE_BIND_NAME)
            end)
            return
        end

        local elapsed = os.clock() - startedAt
        if elapsed >= CONFIG.ShakeDuration then
            pcall(function()
                RunService:UnbindFromRenderStep(SHAKE_BIND_NAME)
            end)
            return
        end

        local camera = Workspace.CurrentCamera
        if camera then
            local decay = math.max(0.12, 1 - elapsed / CONFIG.ShakeDuration)
            local power = CONFIG.ShakeIntensity * decay
            local x = math.noise(elapsed * 5.1, 0, 0) * power
            local y = math.noise(0, elapsed * 5.7, 0) * power
            local roll = math.noise(0, 0, elapsed * 4.6) * math.rad(power)
            camera.CFrame = camera.CFrame * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, roll)
        end
    end)
end

local function loadBossMusic()
    local sound = HATRED_PREPARED_SOUND or getHatredSound()
    if not sound then
        return nil
    end

    sound:Stop()
    sound.Volume = 0
    sound.Looped = true
    State.music = sound
    sound.TimePosition = 0
    sound:Play()
    playTween(sound, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {Volume = CONFIG.MusicVolume})
    return sound
end

local function fadeMusic(seconds)
    local sound = State.music
    State.music = nil
    if not sound then
        return
    end

    if sound.Parent then
        local tween = TweenService:Create(sound, TweenInfo.new(seconds or 1.2, Enum.EasingStyle.Quad), {Volume = 0})
        tween:Play()
        task.delay(seconds or 1.2, function()
            if sound and sound.Parent then
                pcall(function()
                    sound:Stop()
                end)
            end
        end)
    end
end

local function createGlowingModel()
    local model = Instance.new("Model")
    model.Name = "MovingModel"

    local mainPart = Instance.new("Part")
    mainPart.Name = "Core"
    mainPart.Size = Vector3.new(5, 5, 5)
    mainPart.Shape = Enum.PartType.Ball
    mainPart.Color = Color3.fromRGB(0, 200, 255)
    mainPart.Material = Enum.Material.Neon
    mainPart.Transparency = 0.2
    mainPart.CanCollide = false
    mainPart.Anchored = true
    mainPart.Parent = model

    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(100, 200, 255)
    pointLight.Range = 30
    pointLight.Brightness = 5
    pointLight.Parent = mainPart

    model.PrimaryPart = mainPart
    return model
end

local function loadBossModel()
    local success, result = pcall(function()
        local objects = game:GetObjects("rbxassetid://" .. tostring(CONFIG.ModelId))
        if objects and #objects > 0 then
            return objects[1]:Clone()
        end
        return nil
    end)

    if success and result then
        return result
    end

    return createGlowingModel()
end

local function startBossMovement(root, token)
    local model = loadBossModel()
    if not model then
        return false
    end

    model.Name = "HatRed"
    model.Parent = Workspace
    State.boss = model

    local primaryPart = model.PrimaryPart
    if not primaryPart then
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                model.PrimaryPart = part
                primaryPart = part
                break
            end
        end
    end

    if not primaryPart then
        model:Destroy()
        State.boss = nil
        return false
    end

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Anchored = true
        end
    end

    local playerPos = root.Position
    local playerLook = root.CFrame.LookVector
    local startPos = playerPos + (playerLook * CONFIG.StartDistance)
    startPos = startPos + Vector3.new(0, 10, 0)
    model:SetPrimaryPartCFrame(CFrame.new(startPos))

    local startTime = tick()
    local isMoving = true
    local isHovering = false
    local hoverStartTime = 0
    local connection

    connection = RunService.Heartbeat:Connect(function()
        if not alive(token) or not model or not model.Parent or not model:IsDescendantOf(Workspace) then
            if connection then
                connection:Disconnect()
            end
            return
        end

        if not root or not root.Parent then
            if connection then
                connection:Disconnect()
            end
            if model and model.Parent then
                model:Destroy()
            end
            return
        end

        local currentTime = tick()
        local currentPlayerPos = root.Position
        local playerLookDirection = root.CFrame.LookVector

        if isMoving then
            local elapsed = currentTime - startTime
            local progress = math.min(elapsed / CONFIG.ApproachDuration, 1)

            if progress >= 1 then
                isMoving = false
                isHovering = true
                hoverStartTime = currentTime
                return
            end

            local easedProgress = progress * progress
            local targetPos = currentPlayerPos + (playerLookDirection * CONFIG.StopDistance)
                + Vector3.new(0, CONFIG.HoverHeight, 0)
            local currentPos = startPos:Lerp(targetPos, easedProgress)
            model:SetPrimaryPartCFrame(CFrame.new(currentPos))

            local lookDirection = currentPlayerPos - currentPos
            if lookDirection.Magnitude > 0.1 then
                lookDirection = lookDirection.Unit
                model:SetPrimaryPartCFrame(CFrame.new(currentPos, currentPos + lookDirection))
            end
        elseif isHovering then
            local hoverTime = currentTime - hoverStartTime
            if hoverTime >= CONFIG.HoverDuration then
                if model and model.Parent then
                    model:Destroy()
                end
                if connection then
                    connection:Disconnect()
                end
                return
            end

            local targetPos = currentPlayerPos + (playerLookDirection * CONFIG.StopDistance)
                + Vector3.new(0, CONFIG.HoverHeight, 0)
            local currentPos = primaryPart.Position
            local smoothedPos = currentPos:Lerp(targetPos, 0.1)
            model:SetPrimaryPartCFrame(CFrame.new(smoothedPos))

            local lookDirection = currentPlayerPos - smoothedPos
            if lookDirection.Magnitude > 0.1 then
                lookDirection = lookDirection.Unit
                model:SetPrimaryPartCFrame(CFrame.new(smoothedPos, smoothedPos + lookDirection))
            end
        end
    end)

    State.bossConnection = connection
    addConnection(connection)
    return true
end

local FACE_NORMAL_ID = 92470122721520
local FACE_GLITCH_IDS = {
    130581413102559,
    94635282583639,
    16804066476,
    16595430194,
}

local function findReboundFace()
    local hatRed = State.boss
    if not hatRed or not hatRed.Parent then
        hatRed = Workspace:FindFirstChild("HatRed")
    end
    if not hatRed then
        return nil
    end

    local face = hatRed:FindFirstChild("FACE", true)
    local attachment = face and face:FindFirstChild("Attachment", true)
    return attachment and attachment:FindFirstChild("Rebound Face", true) or nil
end

local function setFaceTexture(faceObject, assetId)
    if not faceObject or not faceObject.Parent then
        return false
    end

    local asset = "rbxassetid://" .. tostring(assetId)
    local property
    if faceObject:IsA("ImageLabel") or faceObject:IsA("ImageButton") then
        property = "Image"
    elseif faceObject:IsA("MeshPart") then
        property = "TextureID"
    else
        property = "Texture"
    end

    return pcall(function()
        faceObject[property] = asset
    end)
end

local function startFaceChanging(token)
    task.spawn(function()
        while alive(token) and State.boss and State.boss.Parent do
            local delaySeconds = CONFIG.FaceSwapMinDelay
                + math.random() * (CONFIG.FaceSwapMaxDelay - CONFIG.FaceSwapMinDelay)
            if not waitCancelable(delaySeconds, token) then
                return
            end

            local faceObject = findReboundFace()
            if faceObject then
                local randomId = FACE_GLITCH_IDS[math.random(1, #FACE_GLITCH_IDS)]
                setFaceTexture(faceObject, randomId)
                if not waitCancelable(CONFIG.FaceSwapDuration, token) then
                    return
                end
                setFaceTexture(faceObject, FACE_NORMAL_ID)
            else
                task.wait(0.2)
            end
        end
    end)
end

local function hideInventory()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        return
    end

    local mainUI = playerGui:FindFirstChild("MainUI")
    local settings = mainUI and mainUI:FindFirstChild("Settings")
    local inventory = settings and settings:FindFirstChild("Inventory")
    if not inventory then
        for _, item in ipairs(playerGui:GetDescendants()) do
            if item:IsA("GuiObject") and item.Name:lower():find("inventory", 1, true) then
                inventory = item
                break
            end
        end
    end

    if inventory and inventory:IsA("GuiObject") then
        State.inventory = inventory
        State.originalInventoryVisible = inventory.Visible
        inventory.Visible = false
    end
end

local function startMouseOverride(token)
    State.originalMouseBehavior = UserInputService.MouseBehavior
    State.originalMouseIconEnabled = UserInputService.MouseIconEnabled

    State.mouseConnection = addConnection(RunService.RenderStepped:Connect(function()
        if alive(token) and State.phase > 0 then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
    end))
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

local function corner(parent, radius)
    local item = Instance.new("UICorner")
    item.CornerRadius = UDim.new(0, radius)
    item.Parent = parent
    return item
end

local function stroke(parent, color, thickness, transparency)
    local item = Instance.new("UIStroke")
    item.Color = color
    item.Thickness = thickness
    item.Transparency = transparency or 0
    item.Parent = parent
    return item
end

local function makeLabel(parent, name, text, size, position, font, color, textSize, alignment)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = position
    label.Font = font or Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = color or COLORS.Text
    label.TextSize = textSize or 18
    label.TextWrapped = true
    label.TextXAlignment = alignment or Enum.TextXAlignment.Center
    label.ZIndex = 15
    label.Parent = parent
    return label
end

local function makeTarget(parent, name, color, diameter)
    local button = Instance.new("TextButton")
    button.Name = name
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.Size = UDim2.fromOffset(diameter + 12, diameter + 12)
    button.Position = UDim2.fromScale(0.5, 0.5)
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = ""
    button.Active = true
    button.Selectable = true
    button.ZIndex = 20
    button.Parent = parent

    local orb = Instance.new("Frame")
    orb.Name = "Orb"
    orb.AnchorPoint = Vector2.new(0.5, 0.5)
    orb.Position = UDim2.fromScale(0.5, 0.5)
    orb.Size = UDim2.fromOffset(diameter, diameter)
    orb.BackgroundColor3 = color
    orb.BorderSizePixel = 0
    orb.ZIndex = 20
    orb.Parent = button
    corner(orb, 999)

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
    gradient.Rotation = 45
    gradient.Parent = orb
    stroke(orb, Color3.new(1, 1, 1), 2, 0.45)

    local scale = Instance.new("UIScale")
    scale.Name = "PopScale"
    scale.Scale = 1
    scale.Parent = button

    local shine = Instance.new("Frame")
    shine.Name = "Shine"
    shine.AnchorPoint = Vector2.new(0.5, 0.5)
    shine.Position = UDim2.fromScale(0.36, 0.34)
    shine.Size = UDim2.fromScale(0.26, 0.26)
    shine.BackgroundColor3 = Color3.new(1, 1, 1)
    shine.BackgroundTransparency = 0.25
    shine.BorderSizePixel = 0
    shine.ZIndex = 21
    shine.Parent = orb
    corner(shine, 999)

    return button
end

local function setTargetDiameter(target, diameter)
    if not target then
        return
    end
    target.Size = UDim2.fromOffset(diameter + 12, diameter + 12)
    local orb = target:FindFirstChild("Orb")
    if orb then
        orb.Size = UDim2.fromOffset(diameter, diameter)
    end
end

local function createUI()
    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("HatredBossUI")
    destroy(old)

    local gui = Instance.new("ScreenGui")
    gui.Name = "HatredBossUI"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.DisplayOrder = 10000
    gui.Parent = playerGui
    State.gui = gui

    local dim = Instance.new("Frame")
    dim.Name = "Dim"
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.new(0, 0, 0)
    dim.BackgroundTransparency = 1
    dim.BorderSizePixel = 0
    dim.ZIndex = 10
    dim.Parent = gui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromScale(0.72, 0.72)
    panel.BackgroundColor3 = COLORS.Panel
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.ZIndex = 11
    panel.Parent = gui
    corner(panel, 18)
    stroke(panel, Color3.fromRGB(107, 48, 68), 2, 0.25)

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(310, 340)
    sizeConstraint.MaxSize = Vector2.new(980, 700)
    sizeConstraint.Parent = panel

    local panelScale = Instance.new("UIScale")
    panelScale.Name = "EntranceScale"
    panelScale.Scale = 0.84
    panelScale.Parent = panel

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 5)
    accent.BackgroundColor3 = COLORS.Red
    accent.BorderSizePixel = 0
    accent.ZIndex = 12
    accent.Parent = panel
    local accentGradient = Instance.new("UIGradient")
    accentGradient.Color = ColorSequence.new(COLORS.RedDark, COLORS.Red, COLORS.RedDark)
    accentGradient.Parent = accent

    local title = makeLabel(panel, "Title", "H A T R E D", UDim2.new(0.55, 0, 0, 44), UDim2.new(0.04, 0, 0, 18), Enum.Font.GothamBlack, COLORS.Text, 23, Enum.TextXAlignment.Left)
    local phaseLabel = makeLabel(panel, "Phase", "PHASE 1 / 3", UDim2.new(0.35, 0, 0, 44), UDim2.new(0.61, 0, 0, 18), Enum.Font.GothamBold, COLORS.Gold, 16, Enum.TextXAlignment.Right)

    local instruction = makeLabel(panel, "Instruction", "点击红色目标", UDim2.new(0.92, 0, 0, 34), UDim2.new(0.04, 0, 0, 65), Enum.Font.GothamMedium, COLORS.Muted, 16)

    local statBar = Instance.new("Frame")
    statBar.Name = "StatBar"
    statBar.Size = UDim2.new(0.92, 0, 0, 46)
    statBar.Position = UDim2.new(0.04, 0, 0, 104)
    statBar.BackgroundColor3 = COLORS.Panel2
    statBar.BorderSizePixel = 0
    statBar.ZIndex = 12
    statBar.Parent = panel
    corner(statBar, 10)

    local counter = makeLabel(statBar, "Counter", "0 / 10", UDim2.new(0.28, 0, 1, 0), UDim2.new(0.03, 0, 0, 0), Enum.Font.GothamBold, COLORS.Text, 17, Enum.TextXAlignment.Left)
    local timer = makeLabel(statBar, "Timer", "20.0", UDim2.new(0.25, 0, 1, 0), UDim2.new(0.72, 0, 0, 0), Enum.Font.GothamBlack, COLORS.Text, 19, Enum.TextXAlignment.Right)

    local progressBack = Instance.new("Frame")
    progressBack.Name = "ProgressBack"
    progressBack.AnchorPoint = Vector2.new(0.5, 0.5)
    progressBack.Position = UDim2.fromScale(0.5, 0.5)
    progressBack.Size = UDim2.new(0.36, 0, 0, 7)
    progressBack.BackgroundColor3 = Color3.fromRGB(49, 52, 70)
    progressBack.BorderSizePixel = 0
    progressBack.ZIndex = 13
    progressBack.Parent = statBar
    corner(progressBack, 999)

    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.Size = UDim2.fromScale(0, 1)
    progress.BackgroundColor3 = COLORS.Red
    progress.BorderSizePixel = 0
    progress.ZIndex = 14
    progress.Parent = progressBack
    corner(progress, 999)

    local arena = Instance.new("Frame")
    arena.Name = "Arena"
    arena.Size = UDim2.new(0.92, 0, 1, -205)
    arena.Position = UDim2.new(0.04, 0, 0, 164)
    arena.BackgroundColor3 = COLORS.Background
    arena.BackgroundTransparency = 0.12
    arena.BorderSizePixel = 0
    arena.ClipsDescendants = true
    arena.ZIndex = 12
    arena.Parent = panel
    corner(arena, 14)
    stroke(arena, Color3.fromRGB(69, 72, 94), 1, 0.35)

    local arenaGradient = Instance.new("UIGradient")
    arenaGradient.Color = ColorSequence.new(Color3.fromRGB(13, 14, 23), Color3.fromRGB(25, 13, 21))
    arenaGradient.Rotation = 35
    arenaGradient.Parent = arena

    local redTarget = makeTarget(arena, "RedTarget", COLORS.Red, 66)
    local blueTarget1 = makeTarget(arena, "BlueTarget1", COLORS.Blue, 58)
    local blueTarget2 = makeTarget(arena, "BlueTarget2", COLORS.Blue, 58)
    blueTarget1.Visible = false
    blueTarget2.Visible = false

    local footer = makeLabel(panel, "Footer", "Blue -3s", UDim2.new(0.92, 0, 0, 26), UDim2.new(0.04, 0, 1, -34), Enum.Font.Gotham, COLORS.Muted, 12)

    local phaseSound = Instance.new("Sound")
    phaseSound.Name = "HatredPhaseTransition"
    phaseSound.SoundId = "rbxassetid://" .. tostring(CONFIG.PhaseTransitionSoundId)
    phaseSound.Volume = 0.9
    phaseSound.Parent = SoundService
    State.phaseSound = phaseSound

    State.blur = Instance.new("BlurEffect")
    State.blur.Name = "HatredBossBlur"
    State.blur.Size = 0
    State.blur.Parent = Lighting

    playTween(dim, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.36})
    playTween(State.blur, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {Size = 14})
    playTween(panelScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

    State.ui = {
        Dim = dim,
        Panel = panel,
        PanelScale = panelScale,
        Phase = phaseLabel,
        Instruction = instruction,
        Counter = counter,
        Timer = timer,
        Progress = progress,
        Arena = arena,
        Red = redTarget,
        Blue1 = blueTarget1,
        Blue2 = blueTarget2,
        Footer = footer,
    }
    return State.ui
end

local function moveTarget(target, speed)
    local ui = State.ui
    if not ui or not target or not target.Visible or not target.Parent then
        return
    end

    local arenaSize = ui.Arena.AbsoluteSize
    local targetSize = target.AbsoluteSize
    if arenaSize.X < 10 or arenaSize.Y < 10 then
        return
    end

    local halfX = targetSize.X * 0.5 + 8
    local halfY = targetSize.Y * 0.5 + 8
    local x = math.random(math.floor(halfX), math.max(math.floor(halfX), math.floor(arenaSize.X - halfX)))
    local y = math.random(math.floor(halfY), math.max(math.floor(halfY), math.floor(arenaSize.Y - halfY)))

    local oldTween = State.targetTweens[target]
    if oldTween then
        pcall(function()
            oldTween:Cancel()
        end)
    end
    local tween = TweenService:Create(target, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(x, y),
    })
    State.targetTweens[target] = tween
    tween:Play()
end

local function targetPulse(target, color)
    if not target or not target.Parent then
        return
    end
    local scale = target:FindFirstChild("PopScale")
    local orb = target:FindFirstChild("Orb")
    local outline = orb and orb:FindFirstChildOfClass("UIStroke")
    if scale then
        scale.Scale = 0.78
        playTween(scale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    end
    if outline then
        outline.Color = color
        outline.Transparency = 0
        playTween(outline, TweenInfo.new(0.35), {Transparency = 0.45})
    end
end

local function updateHUD()
    local ui = State.ui
    if not ui or not ui.Panel.Parent or State.phase < 1 then
        return
    end

    local goal = CONFIG.PhaseGoals[State.phase]
    ui.Phase.Text = string.format("PHASE %d / 3", State.phase)
    ui.Counter.Text = string.format("%d / %d", State.clicks, goal)
    local ratio = math.clamp(State.clicks / goal, 0, 1)
    playTween(ui.Progress, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(ratio, 1)})

    if State.phase == 1 then
        ui.Phase.TextColor3 = COLORS.Gold
        ui.Instruction.Text = "Click the red one!"
    elseif State.phase == 2 then
        ui.Phase.TextColor3 = Color3.fromRGB(217, 112, 255)
        ui.Instruction.Text = "Click the red one, Dodge the blue"
    else
        ui.Phase.TextColor3 = COLORS.Red
        ui.Instruction.Text = "END：Dodge the blue."
    end
end

local function flashMessage(text, color, seconds, token)
    local ui = State.ui
    if not ui or not ui.Instruction.Parent then
        return
    end
    local expectedPhase = State.phase
    ui.Instruction.Text = text
    ui.Instruction.TextColor3 = color
    task.delay(seconds or 0.8, function()
        if alive(token) and State.phase == expectedPhase then
            ui.Instruction.TextColor3 = COLORS.Muted
            updateHUD()
        end
    end)
end

local function beginPhase(phase, token)
    if not alive(token) then
        return
    end
    State.phase = phase
    State.clicks = 0
    State.deadline = os.clock() + CONFIG.PhaseTimes[phase]

    local ui = State.ui
    ui.Progress.Size = UDim2.fromScale(0, 1)
    ui.Red.Visible = true
    ui.Blue1.Visible = phase >= 2
    ui.Blue2.Visible = phase >= 3
    setTargetDiameter(ui.Red, phase == 1 and 66 or (phase == 2 and 58 or 52))
    setTargetDiameter(ui.Blue1, phase == 3 and 50 or 56)
    setTargetDiameter(ui.Blue2, 50)
    updateHUD()

    task.defer(function()
        RunService.Heartbeat:Wait()
        if alive(token) then
            moveTarget(ui.Red, 0)
            moveTarget(ui.Blue1, 0)
            moveTarget(ui.Blue2, 0)
        end
    end)
end

local function removeBoss()
    local model = State.boss
    State.boss = nil
    disconnect(State.bossConnection)
    State.bossConnection = nil
    destroy(model)
end

local function restoreLocalState()
    if State.inventory and State.inventory.Parent and State.originalInventoryVisible ~= nil then
        State.inventory.Visible = State.originalInventoryVisible
    end
    State.inventory = nil

    if State.originalMouseBehavior ~= nil then
        UserInputService.MouseBehavior = State.originalMouseBehavior
    end
    if State.originalMouseIconEnabled ~= nil then
        UserInputService.MouseIconEnabled = State.originalMouseIconEnabled
    end
end

local function cleanup(immediate)
    if State.cleaned then
        return
    end
    State.cleaned = true
    State.running = false
    State.phase = 0
    State.token = State.token + 1

    pcall(function()
        RunService:UnbindFromRenderStep(SHAKE_BIND_NAME)
    end)

    for _, connection in ipairs(State.connections) do
        disconnect(connection)
    end
    State.connections = {}

    for _, tween in ipairs(State.tweens) do
        pcall(function()
            tween:Cancel()
        end)
    end
    State.tweens = {}
    State.targetTweens = {}

    fadeMusic(immediate and 0.05 or 0.9)
    destroy(State.phaseSound)
    State.phaseSound = nil
    destroy(State.failureSound)
    State.failureSound = nil
    destroy(State.boss)
    State.boss = nil
    destroy(State.blur)
    State.blur = nil
    destroy(State.gui)
    State.gui = nil
    State.ui = nil
    restoreLocalState()
end

Controller.Stop = function()
    cleanup(false)
end

local function defeatPlayer()
    local character, _, humanoid = getCharacterParts(2)
    local signaled = false
    if type(replicatesignal) == "function" then
        signaled = pcall(function()
            replicatesignal(player.Kill)
        end)
    end
    if not signaled and humanoid and humanoid.Parent then
        humanoid.Health = 0
    elseif not signaled and character then
        character:BreakJoints()
    end
end

local FAILURE_TEXTURE_IDS = {
    88894221959954,
    12293713542,
    6214195404,
}

local function createFailureOverlay()
    local gui = State.gui
    if not gui or not gui.Parent then
        return nil
    end

    local old = gui:FindFirstChild("FailureOverlay")
    destroy(old)

    local overlay = Instance.new("Frame")
    overlay.Name = "FailureOverlay"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ClipsDescendants = true
    overlay.ZIndex = 500
    overlay.Parent = gui

    local textLayer = Instance.new("Frame")
    textLayer.Name = "LoserTextLayer"
    textLayer.Size = UDim2.fromScale(1, 1)
    textLayer.BackgroundTransparency = 1
    textLayer.BorderSizePixel = 0
    textLayer.ZIndex = 510
    textLayer.Parent = overlay

    local glitchBars = {}
    for index = 1, 18 do
        local bar = Instance.new("Frame")
        bar.Name = "EdgeError" .. index
        bar.BackgroundColor3 = COLORS.Red
        bar.BackgroundTransparency = 1
        bar.BorderSizePixel = 0
        bar.ZIndex = 505
        bar.Parent = overlay
        table.insert(glitchBars, bar)
    end

    local glitchImages = {}
    for index = 1, 12 do
        local image = Instance.new("ImageLabel")
        image.Name = "ErrorTexture" .. index
        image.AnchorPoint = Vector2.new(0.5, 0.5)
        image.BackgroundTransparency = 1
        image.BorderSizePixel = 0
        image.Image = "rbxassetid://" .. tostring(FAILURE_TEXTURE_IDS[((index - 1) % #FAILURE_TEXTURE_IDS) + 1])
        image.ImageTransparency = 1
        image.ScaleType = Enum.ScaleType.Stretch
        image.Visible = false
        image.ZIndex = 508 + (index % 3)
        image.Parent = overlay
        table.insert(glitchImages, image)
    end

    destroy(State.failureSound)
    local failureSound = Instance.new("Sound")
    failureSound.Name = "HatredLoserGlitch"
    failureSound.SoundId = "rbxassetid://" .. tostring(CONFIG.FailureSoundId)
    failureSound.Volume = CONFIG.FailureSoundVolume
    failureSound.Parent = SoundService
    State.failureSound = failureSound

    return overlay, textLayer, glitchBars, glitchImages
end

local function updateFailureGlitch(textLayer, glitchBars, glitchImages, intensity)
    if textLayer and textLayer.Parent then
        local jitter = math.floor(2 + intensity * 12)
        textLayer.Position = UDim2.fromOffset(math.random(-jitter, jitter), math.random(-jitter, jitter))
    end

    for index, bar in ipairs(glitchBars) do
        if not bar.Parent then
            continue
        end

        local side = ((index - 1) % 4) + 1
        local thickness = math.random(2, math.floor(5 + intensity * 25))
        local length = math.random(8, math.floor(20 + intensity * 70)) / 100
        if side == 1 then
            bar.Size = UDim2.new(length, 0, 0, thickness)
            bar.Position = UDim2.new(math.random(), 0, 0, math.random(0, 22))
        elseif side == 2 then
            bar.AnchorPoint = Vector2.new(0, 1)
            bar.Size = UDim2.new(length, 0, 0, thickness)
            bar.Position = UDim2.new(math.random(), 0, 1, -math.random(0, 22))
        elseif side == 3 then
            bar.Size = UDim2.new(0, thickness, length, 0)
            bar.Position = UDim2.new(0, math.random(0, 22), math.random(), 0)
        else
            bar.AnchorPoint = Vector2.new(1, 0)
            bar.Size = UDim2.new(0, thickness, length, 0)
            bar.Position = UDim2.new(1, -math.random(0, 22), math.random(), 0)
        end

        local colorRoll = math.random(1, 5)
        bar.BackgroundColor3 = colorRoll == 1 and Color3.new(1, 1, 1)
            or (colorRoll == 2 and Color3.fromRGB(30, 0, 0) or COLORS.Red)
        bar.BackgroundTransparency = math.random(5, math.floor(35 + (1 - intensity) * 50)) / 100
        bar.Visible = math.random() < (0.35 + intensity * 0.65)
    end

    for _, image in ipairs(glitchImages) do
        if image.Parent then
            local width = math.random(18, math.floor(35 + intensity * 55)) / 100
            local height = math.random(12, math.floor(25 + intensity * 50)) / 100
            image.Size = UDim2.fromScale(width, height)
            image.Position = UDim2.fromScale(math.random(), math.random())
            image.Rotation = math.random(-12, 12)
            image.Image = "rbxassetid://" .. tostring(FAILURE_TEXTURE_IDS[math.random(1, #FAILURE_TEXTURE_IDS)])
            image.ImageColor3 = math.random() < 0.25 and Color3.new(1, 1, 1)
                or Color3.fromRGB(255, math.random(15, 75), math.random(15, 75))
            image.ImageTransparency = math.random(8, math.floor(35 + (1 - intensity) * 45)) / 100
            image.Visible = math.random() < (0.2 + intensity * 0.72)
        end
    end
end

local function spawnLoserText(textLayer, intensity, isFirst)
    if not textLayer or not textLayer.Parent then
        return
    end

    local failureSound = State.failureSound
    if failureSound and failureSound.Parent then
        pcall(function()
            failureSound.TimePosition = 0
            failureSound:Play()
        end)
    end

    local label = Instance.new("TextLabel")
    label.Name = "YOUR_LOSER"
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Size = isFirst and UDim2.fromOffset(420, 100)
        or UDim2.fromOffset(math.random(150, 430), math.random(45, 115))
    label.Position = isFirst and UDim2.fromScale(0.5, 0.5)
        or UDim2.fromScale(math.random(), math.random())
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = math.random() < 0.35 and Enum.Font.Code or Enum.Font.GothamBlack
    label.Text = "YOUR LOSER"
    label.TextColor3 = math.random() < 0.18 and Color3.new(1, 1, 1) or COLORS.Red
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = math.max(0, 0.5 - intensity * 0.45)
    label.TextTransparency = isFirst and 0 or math.random(0, 25) / 100
    label.TextScaled = true
    label.Rotation = isFirst and 0 or math.random(-18, 18)
    label.ZIndex = 520 + math.random(0, 5)
    label.Parent = textLayer

    local scale = Instance.new("UIScale")
    scale.Scale = isFirst and 0.15 or math.random(35, 85) / 100
    scale.Parent = label
    playTween(
        scale,
        TweenInfo.new(isFirst and 0.55 or math.max(0.04, 0.18 - intensity * 0.12), Enum.EasingStyle.Back),
        {Scale = isFirst and 1 or math.random(90, 150) / 100}
    )
end

local function playFailureSequence(token)
    local overlay, textLayer, glitchBars, glitchImages = createFailureOverlay()
    if not overlay then
        return false
    end

    playTween(
        overlay,
        TweenInfo.new(CONFIG.FailureFadeDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
        {BackgroundTransparency = 0}
    )

    if not waitCancelable(1.4, token) then
        return false
    end

    spawnLoserText(textLayer, 0, true)
    if not waitCancelable(1.1, token) then
        return false
    end
    local stormStart = os.clock()
    local spawned = 1

    while alive(token) do
        local elapsed = os.clock() - stormStart
        local progress = math.clamp(elapsed / CONFIG.FailureStormDuration, 0, 1)
        if progress >= 1 then
            break
        end

        updateFailureGlitch(textLayer, glitchBars, glitchImages, progress)
        local burst = 1 + math.floor(progress * 4)
        for _ = 1, burst do
            if spawned >= 240 then
                break
            end
            spawnLoserText(textLayer, progress, false)
            spawned = spawned + 1
        end

        local interval = 0.92 * ((1 - progress) ^ 2) + 0.045
        if not waitCancelable(interval, token) then
            return false
        end
    end

    if textLayer and textLayer.Parent then
        textLayer:Destroy()
    end
    for _, bar in ipairs(glitchBars) do
        destroy(bar)
    end
    for _, image in ipairs(glitchImages) do
        destroy(image)
    end
    destroy(State.failureSound)
    State.failureSound = nil
    overlay.BackgroundTransparency = 0

    return waitCancelable(CONFIG.FailureVoidDuration, token)
end

local function finish(result, token)
    if State.ending or not alive(token) then
        return
    end
    State.ending = true

    local ui = State.ui
    if ui then
        ui.Red.Visible = false
        ui.Blue1.Visible = false
        ui.Blue2.Visible = false
        ui.Timer.Text = result == "victory" and "CLEAR" or "FAILED"
        ui.Timer.TextColor3 = result == "victory" and COLORS.Green or COLORS.Red
        ui.Instruction.Text = result == "victory" and "存活于憎恨" or "YOUR LOSER"
        ui.Instruction.TextColor3 = result == "victory" and COLORS.Green or COLORS.Red
    end

    if result == "victory" then
        removeBoss()
        fadeMusic(1.8)
        waitCancelable(1.1, token)
        safeCaption("It looks like you've made progress. Congratulations.")
        waitCancelable(1.3, token)
        cleanup(false)
    else
        fadeMusic(4)
        if playFailureSequence(token) and alive(token) then
            defeatPlayer()
        end
        cleanup(true)
    end
end

local function startMiniGame(token)
    local ui = createUI()
    hideInventory()
    beginPhase(1, token)
    startMouseOverride(token)

    local transitioning = false
    local nextRedMove = 0
    local nextBlue1Move = 0
    local nextBlue2Move = 0

    addConnection(ui.Red.Activated:Connect(function()
        if not alive(token) or State.ending or transitioning then
            return
        end
        State.clicks = State.clicks + 1
        targetPulse(ui.Red, Color3.new(1, 1, 1))
        updateHUD()

        if State.clicks >= CONFIG.PhaseGoals[State.phase] then
            if State.phase >= 3 then
                task.spawn(finish, "victory", token)
                return
            end

            transitioning = true
            local nextPhase = State.phase + 1
            State.deadline = math.huge
            ui.Red.Visible = false
            ui.Blue1.Visible = false
            ui.Blue2.Visible = false
            ui.Timer.Text = "READY"
            ui.Timer.TextColor3 = COLORS.Gold
            ui.Instruction.Text = nextPhase == 3
                and "存活第二阶段"
                or "存活第一阶段"
            ui.Instruction.TextColor3 = COLORS.Gold
            if State.phaseSound then
                State.phaseSound.TimePosition = 0
                State.phaseSound:Play()
            end
            task.delay(CONFIG.PhaseTransitionDelay, function()
                if alive(token) then
                    beginPhase(nextPhase, token)
                    transitioning = false
                end
            end)
        else
            moveTarget(ui.Red, State.phase == 3 and 0.12 or 0.18)
        end
    end))

    local function blueClicked(target)
        if not alive(token) or State.ending or transitioning or State.phase < 2 then
            return
        end
        State.deadline = State.deadline - CONFIG.BluePenalty
        targetPulse(target, COLORS.Red)
        flashMessage("-3s 躲避蓝色", COLORS.Red, 0.75, token)
        moveTarget(target, 0.16)
    end

    addConnection(ui.Blue1.Activated:Connect(function()
        blueClicked(ui.Blue1)
    end))
    addConnection(ui.Blue2.Activated:Connect(function()
        if State.phase >= 3 then
            blueClicked(ui.Blue2)
        end
    end))

    addConnection(RunService.Heartbeat:Connect(function()
        if not alive(token) or State.ending or State.phase < 1 then
            return
        end

        if transitioning then
            ui.Timer.Text = "READY"
            ui.Timer.TextColor3 = COLORS.Gold
            return
        end

        local now = os.clock()
        local remaining = math.max(0, State.deadline - now)
        ui.Timer.Text = string.format("%.1f", remaining)
        ui.Timer.TextColor3 = remaining <= 5 and COLORS.Red or COLORS.Text

        if not transitioning then
            local redInterval = State.phase == 1 and 0.82 or (State.phase == 2 and 0.66 or 0.5)
            if now >= nextRedMove then
                moveTarget(ui.Red, State.phase == 3 and 0.16 or 0.22)
                nextRedMove = now + redInterval
            end
            if State.phase >= 2 and now >= nextBlue1Move then
                moveTarget(ui.Blue1, 0.3)
                nextBlue1Move = now + (State.phase == 3 and 0.8 or 1.05)
            end
            if State.phase >= 3 and now >= nextBlue2Move then
                moveTarget(ui.Blue2, 0.3)
                nextBlue2Move = now + 0.9
            end
        end

        if remaining <= 0 then
            task.spawn(finish, "defeat", token)
        end
    end))
end

local function runEvent()
    if State.running then
        return
    end

    State.cleaned = false
    State.running = true
    State.ending = false
    State.phase = 0
    State.clicks = 0
    State.token = State.token + 1
    local token = State.token

    local ok, errorMessage = xpcall(function()
        local _, root = getCharacterParts(6)
        if not root then
            error("HumanoidRootPart was not found")
        end

        startRoomFlicker()
        startCameraShake(token)
        loadBossMusic()
        safeCaption("What is this?")
        if not waitCancelable(0.5, token) then
            return
        end
        if not startBossMovement(root, token) then
            error("Original boss model could not be loaded")
        end
        startFaceChanging(token)

        if not waitCancelable(CONFIG.ApproachDuration, token) then
            return
        end
        safeCaption("We meet again, little bug.")
        if not waitCancelable(3.2, token) then return end
        safeCaption("I hope you can learn a lesson this time.")
        if not waitCancelable(3.2, token) then return end
        safeCaption("Let's get started.")
        if not waitCancelable(1, token) then return end

        startMiniGame(token)
    end, debug.traceback)

    if not ok then
        cleanup(true)
    end
end

addConnection(player.CharacterRemoving:Connect(function()
    cleanup(true)
end))

Controller.Start = runEvent
task.spawn(runEvent)
end

function entityBehaviors.A500()
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local Workspace=game:GetService("Workspace")

local player=Players.LocalPlayer
local camera=Workspace.CurrentCamera

local CurrentRooms=Workspace:WaitForChild("CurrentRooms")
local LatestRoom=ReplicatedStorage.GameData.LatestRoom
local SoundFolder=Workspace:WaitForChild("HardCoreSound")

local A500One=SoundFolder.A500One
local A500Two=SoundFolder.A500Two
local A500Three=SoundFolder.A500Three
local A500Four=SoundFolder.A500Four

local roomChanges=0
local phase87=false
local gameEnded=false

local flameModel=nil
local flameRunning=false
local flameDamageCooldown=false


local function ReplaceTV()
	for _,v in ipairs(CurrentRooms:GetDescendants()) do
		if v:IsA("TextLabel") then
			if v.Name=="Number" then
				v.Text="??"
				v.TextColor3=Color3.fromRGB(151,60,255)
			elseif v.Name=="TextLabel" then
				v.Text="Y!o#u$ n%e&e%d t#o r!u$n f%a#s$t!e%r!"
				v.TextColor3=Color3.fromRGB(151,60,255)
			end
		end

		if v:IsA("SurfaceGui") or v:IsA("BillboardGui") then
			if v.Name=="TellerGui" then
				v.Enabled=true
			end
		end
	end
end


local function HideRoom(room)
	if not room then return end

	for _,v in ipairs(room:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Name=="Floor" or v.Name=="Ceiling" or v.Name=="Carpet" then
				v.Transparency=1
				v.LocalTransparencyModifier=1
			end
		end
	end
end


local hideConnection=CurrentRooms.ChildAdded:Connect(function(room)
	if gameEnded then return end

	if phase87 then
		task.wait(.1)
		HideRoom(room)
	else
		task.wait(.2)
		ReplaceTV()
	end
end)


LatestRoom.Changed:Connect(function()
	roomChanges+=1
end)


local function ErrorFlash()
	local gui=Instance.new("ScreenGui")
	gui.IgnoreGuiInset=true
	gui.ResetOnSpawn=false
	gui.Parent=player.PlayerGui

	local f=Instance.new("Frame")
	f.Size=UDim2.fromScale(1,1)
	f.BackgroundColor3=Color3.new(0,0,0)
	f.BackgroundTransparency=1
	f.Parent=gui

	for i=1,8 do
		f.BackgroundTransparency=0
		task.wait(.035)
		f.BackgroundTransparency=1
		task.wait(.035)
	end

	gui:Destroy()
end


local function Impact()
	local old=camera.FieldOfView
	local t=0

	while t<10 and not gameEnded do
		t+=RunService.RenderStepped:Wait()
		local p=(10-t)/10

		camera.FieldOfView=old+70*p

		camera.CFrame*=CFrame.new(
			math.sin(t*20)*.2*p,
			math.sin(t*12)*.05*p,
			0
		)
	end
end


local function ChangeSky()
	local sky=Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky",Lighting)

	sky.SkyboxBk="rbxassetid://15983968922"
	sky.SkyboxDn="rbxassetid://15983966825"
	sky.SkyboxFt="rbxassetid://15983965025"
	sky.SkyboxLf="rbxassetid://15983967420"
	sky.SkyboxRt="rbxassetid://15983966246"
	sky.SkyboxUp="rbxassetid://15983964246"
end


local function SpawnFlame()
	local objects=game:GetObjects("rbxassetid://88313881550159")
	local model=objects[1]

	if not model then return end

	flameModel=model
	flameModel.Name="Flame of Fury"
	flameModel.Parent=Workspace

	local root=flameModel.PrimaryPart or flameModel:FindFirstChildWhichIsA("BasePart")
	if not root then
		flameModel:Destroy()
		return
	end

	local char=player.Character or player.CharacterAdded:Wait()
	local hrp=char:WaitForChild("HumanoidRootPart")

	flameModel:PivotTo(hrp.CFrame*CFrame.new(0,0,100))
	flameRunning=true

	RunService:BindToRenderStep("FlameChase",301,function(dt)
		if not flameRunning or gameEnded or not flameModel.Parent then
			RunService:UnbindFromRenderStep("FlameChase")
			return
		end

		local target=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not target then return end

		local dir=target.Position-root.Position

		if dir.Magnitude>3 then
			root.CFrame=CFrame.lookAt(root.Position+dir.Unit*35*dt,target.Position)
		end

		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={flameModel}

		local hit=Workspace:Raycast(root.Position,dir.Unit*8,params)

		if hit and hit.Instance:IsDescendantOf(target.Parent) and not flameDamageCooldown then
			flameDamageCooldown=true

			local hum=target.Parent:FindFirstChildOfClass("Humanoid")
			if hum then hum:TakeDamage(90) end

			task.delay(5,function()
				flameDamageCooldown=false
			end)
		end
	end)
end


local function RemoveFlame()
	flameRunning=false

	pcall(function()
		RunService:UnbindFromRenderStep("FlameChase")
	end)

	if flameModel then
		flameModel:Destroy()
		flameModel=nil
	end
end


A500One.Looped=true
A500One:Play()
task.wait(.5)
ReplaceTV()


while roomChanges<3 do
	LatestRoom.Changed:Wait()
end


A500One:Stop()
A500Two:Play()


task.delay(5.2,function()
	ErrorFlash()
	task.wait(.15)
	Impact()
	SpawnFlame()
end)


task.delay(87,function()
	phase87=true

	ErrorFlash()
	task.wait(.15)

	Impact()
	ChangeSky()

	for _,r in ipairs(CurrentRooms:GetChildren()) do
		HideRoom(r)
	end
end)


A500Two.Ended:Wait()


if roomChanges<50 then
	A500Three.Looped=true
	A500Three:Play()

	while roomChanges<50 do
		task.wait(.1)
	end

	A500Three:Stop()
end


A500Four:Play()

gameEnded=true
phase87=false

RemoveFlame()

if hideConnection then
	hideConnection:Disconnect()
	hideConnection=nil
end

camera.FieldOfView=70
end

function entityBehaviors.Angler()
local entity = spawner.Create({
	Entity = {
		Name = "Angler",
		Asset = "137184736069143",
		HeightOffset = -0.6},Lights = {Flicker = {Enabled = true,Duration = 2},Shatter = true,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,Values = {1.5, 20, 0.1, 1}},
	Movement = {Speed = 110,Delay = 3,Reversed = false},Rebounding = {Enabled = false,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 100,
		Amount = 125},Crucifixion = {Enabled = true,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于Angler", "他和Rush一样", "看见闪灯时躲避", "这非常简单"},Cause = ""}})

entity:SetCallback("OnRebounding", function(startOfRebound)
	local entityModel = entity.Model
	local main = entityModel:WaitForChild("Main")
	local attachment = main:WaitForChild("Attachment")
	local AttachmentSwitch = main:WaitForChild("AttachmentSwitch")
	local sounds = {
		footsteps = main:WaitForChild("Footsteps"),
		playSound = main:WaitForChild("PlaySound"),
		switch = main:WaitForChild("Switch"),
		switchBack = main:WaitForChild("SwitchBack")
	}

	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end

	if startOfRebound == true then
		sounds.footsteps.PlaybackSpeed = 0.35
		sounds.playSound.PlaybackSpeed = 0.25
		sounds.switch:Play()
	else
		sounds.footsteps.PlaybackSpeed = 0.25
		sounds.playSound.PlaybackSpeed = 0.16
		sounds.switchBack:Play()
	end
end)
entity:Run()
end
function entityBehaviors.guidingjug()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local REPLACEMENT_CONFIG = {
    ["starjug"] = {assetId = 90395549970314}
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

local function hideStarJugParts(starJug)
    if not starJug or not starJug.Parent then return end
    
    local function hideRecursive(obj)
        if obj:IsA("MeshPart") or obj:IsA("BasePart") then
            if not trackedTargets[starJug] then
                trackedTargets[starJug] = {originalParts = {}}
            end
            trackedTargets[starJug].originalParts[obj] = {transparency = obj.Transparency}
            obj.Transparency = 1
        end
        
        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
            if not trackedTargets[starJug] then
                trackedTargets[starJug] = {originalParts = {}}
            end
            trackedTargets[starJug].originalParts[obj] = {enabled = obj.Enabled}
            obj.Enabled = false
        end
        
        if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SurfaceAppearance") then
            if not trackedTargets[starJug] then
                trackedTargets[starJug] = {originalParts = {}}
            end
            trackedTargets[starJug].originalParts[obj] = {transparency = obj.Transparency}
            obj.Transparency = 1
        end
        
        for _, child in ipairs(obj:GetChildren()) do
            hideRecursive(child)
        end
    end
    
    hideRecursive(starJug)
end

local function restoreStarJug(starJug)
    local data = trackedTargets[starJug]
    if not data or not data.originalParts then return end
    
    for part, partData in pairs(data.originalParts) do
        if part and part.Parent then
            if (part:IsA("MeshPart") or part:IsA("BasePart")) and partData.transparency then
                part.Transparency = partData.transparency
            elseif (part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail")) and partData.enabled ~= nil then
                part.Enabled = partData.enabled
            elseif (part:IsA("Texture") or part:IsA("Decal") or part:IsA("SurfaceAppearance")) and partData.transparency then
                part.Transparency = partData.transparency
            end
        end
    end
end

local function getItemConfig(itemName)
    local nameLower = itemName:lower()
    return REPLACEMENT_CONFIG[nameLower]
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
    if not effectModel then 
        return nil 
    end
    
    effectModel.Name = "StarJug_Follower"
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
    
    data.effect:PivotTo(targetCFrame)
    return true
end

local function startTrackingTarget(target, config)
    if trackedTargets[target] then 
        return trackedTargets[target] 
    end
    
    local effectModel = createFollowEffect(target, config.assetId)
    if not effectModel then 
        return nil 
    end
    
    hideStarJugParts(target)
    
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
        restoreStarJug(target)
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

local function findAllStarJugs()
    local targets = {}
    
    local function findStarJugsRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name:lower() == "starjug" then
                local config = getItemConfig(child.Name)
                if config then
                    table.insert(targets, {target = child, config = config})
                end
            end
            findStarJugsRecursive(child)
        end
    end
    
    findStarJugsRecursive(workspace)
    return targets
end

local function startDetection()
    local lastCheckTime = 0
    
    while true do
        local currentTime = tick()
        
        if currentTime - lastCheckTime >= CHECK_INTERVAL then
            lastCheckTime = currentTime
            
            cleanupDestroyedTargets()
            
            local allStarJugs = findAllStarJugs()
            
            for _, targetData in ipairs(allStarJugs) do
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
end
function entityBehaviors.A333()
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local random = Random.new()
local latestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")
local music = Workspace:WaitForChild("HardCoreSound"):WaitForChild("A333Music")

latestRoom.Changed:Wait()

local function getRoom()
    return Workspace:WaitForChild("CurrentRooms"):FindFirstChild(tostring(latestRoom.Value))
end

local model
local loaded = pcall(function()
    local room = getRoom()
    if not room then
        error("Current room not found")
    end

    local entrance = room:WaitForChild("RoomEntrance")
    local objects = game:GetObjects("rbxassetid://129270013455588")
    model = objects[1]
    if not model then
        error("Model failed to load")
    end

    model.Parent = Workspace
    local spawnCFrame = entrance.CFrame * CFrame.new(0, 2, -15)

    if model:IsA("Model") then
        model:PivotTo(spawnCFrame)
    elseif model:IsA("BasePart") then
        model.CFrame = spawnCFrame
        local innerPart = model:FindFirstChild("Part")
        if innerPart and innerPart:IsA("BasePart") then
            innerPart.CFrame = spawnCFrame
        end
    else
        local part = model:FindFirstChildWhichIsA("BasePart", true)
        if part then
            part.CFrame = spawnCFrame
        end
    end
end)

if not loaded then
    if model then
        model:Destroy()
    end
    return
end

local function fadeAndDestroyModel(target, duration)
    if not target or not target.Parent then
        return
    end

    local emitters = {}
    for _, descendant in ipairs(target:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") then
            table.insert(emitters, {
                emitter = descendant,
                keypoints = descendant.Transparency.Keypoints
            })
        end
    end

    local started = os.clock()
    while target.Parent do
        local alpha = math.clamp((os.clock() - started) / duration, 0, 1)

        for _, entry in ipairs(emitters) do
            if entry.emitter.Parent then
                local points = {}
                for _, keypoint in ipairs(entry.keypoints) do
                    table.insert(points, NumberSequenceKeypoint.new(
                        keypoint.Time,
                        keypoint.Value + (1 - keypoint.Value) * alpha,
                        keypoint.Envelope * (1 - alpha)
                    ))
                end
                entry.emitter.Transparency = NumberSequence.new(points)
            end
        end

        if alpha >= 1 then
            break
        end
        RunService.Heartbeat:Wait()
    end

    if target.Parent then
        target:Destroy()
    end
end

task.delay(4, function()
    fadeAndDestroyModel(model, 1.5)
end)

local running = true
local spectator = false
local screenGui
local currentImage
local camShake
local characterAddedConnection
local characterRemovingConnection
local diedConnection

local function removeEffects()
    if currentImage then
        currentImage:Destroy()
        currentImage = nil
    end
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
    if camShake then
        pcall(function()
            camShake:Stop()
        end)
        camShake = nil
    end
end

local function becomeSpectator()
    if spectator then
        return
    end
    spectator = true
    removeEffects()
end

local function hasDeathFlag(instance)
    if not instance then
        return false
    end
    return instance:GetAttribute("Dead") == true
        or instance:GetAttribute("IsDead") == true
        or instance:GetAttribute("Alive") == false
end

local function isPlayerActive()
    if spectator then
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    if humanoid.Health <= 0
        or humanoid:GetState() == Enum.HumanoidStateType.Dead
        or hasDeathFlag(character)
        or hasDeathFlag(player) then
        becomeSpectator()
        return false
    end

    return true
end

local function watchCharacter(character)
    if diedConnection then
        diedConnection:Disconnect()
        diedConnection = nil
    end

    task.spawn(function()
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
        if not running or spectator or player.Character ~= character or not humanoid then
            return
        end
        diedConnection = humanoid.Died:Connect(becomeSpectator)
        isPlayerActive()
    end)
end

characterAddedConnection = player.CharacterAdded:Connect(watchCharacter)
characterRemovingConnection = player.CharacterRemoving:Connect(function()
    becomeSpectator()
end)

if player.Character then
    watchCharacter(player.Character)
end

local function finishGame()
    if not running then
        return
    end
    running = false
    removeEffects()
    if diedConnection then
        diedConnection:Disconnect()
        diedConnection = nil
    end
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end
    if characterRemovingConnection then
        characterRemovingConnection:Disconnect()
        characterRemovingConnection = nil
    end
end

local endedConnection = music.Ended:Connect(finishGame)
local stoppedConnection = music.Stopped:Connect(finishGame)
local destroyingConnection = music.Destroying:Connect(finishGame)

local function isMusicRunning()
    return running and music.Parent ~= nil and music.IsPlaying
end

local function waitForMusicTime(seconds)
    while isMusicRunning() and music.TimePosition < seconds do
        if not spectator then
            isPlayerActive()
        end
        task.wait(0.03)
    end
    return isMusicRunning()
end

local function caption(message)
    if not isPlayerActive() or not isMusicRunning() then
        return
    end
    pcall(function()
        require(player.PlayerGui.MainUI.Initiator.Main_Game).caption(message, true)
    end)
end

local function shakeCamera()
    if not isPlayerActive() or not isMusicRunning() then
        return
    end

    if not camShake then
        local ok, shakerModule = pcall(function()
            return require(ReplicatedStorage:WaitForChild("CameraShaker"))
        end)
        if not ok then
            return
        end

        local created, instance = pcall(function()
            local shaker = shakerModule.new(Enum.RenderPriority.Camera.Value + 1, function(shakeCf)
                local camera = Workspace.CurrentCamera
                if camera and isPlayerActive() then
                    camera.CFrame = camera.CFrame * shakeCf
                end
            end)
            shaker:Start()
            return shaker
        end)
        if not created then
            return
        end
        camShake = instance
    end

    pcall(function()
        camShake:ShakeOnce(10, 3, 0.1, 6, 2, 0.5)
    end)
end

local function getScreenGui()
    if screenGui and screenGui.Parent then
        return screenGui
    end
    if not isPlayerActive() then
        return nil
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "A333JumpScareGui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000
    gui.Parent = player:WaitForChild("PlayerGui")
    screenGui = gui
    return gui
end

local function isHiding()
    local character = player.Character
    return character ~= nil and character:GetAttribute("Hiding") == true
end

local function showJumpScareAndCheck(shouldHide)
    if not isMusicRunning() or not isPlayerActive() then
        return
    end

    local gui = getScreenGui()
    if not gui then
        return
    end

    local image = Instance.new("ImageLabel")
    image.Name = "A333JumpScare"
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://122543847993550"
    image.ImageTransparency = 1
    image.AnchorPoint = Vector2.new(0.5, 0.5)
    image.Position = UDim2.fromScale(0.5, 0.5)
    local size = random:NextNumber(1.08, 1.22)
    image.Size = UDim2.fromScale(size, size)
    image.ScaleType = Enum.ScaleType.Crop
    image.ZIndex = 10
    image.Parent = gui
    currentImage = image

    local damaged = false
    local started = os.clock()

    while isMusicRunning() and isPlayerActive() and image.Parent do
        local elapsed = os.clock() - started
        if elapsed >= 0.4 then
            break
        end

        if elapsed < 0.1 then
            image.ImageTransparency = 1 - 0.5 * (elapsed / 0.1)
        elseif elapsed < 0.3 then
            image.ImageTransparency = 0.5
        else
            image.ImageTransparency = 0.5 + 0.5 * ((elapsed - 0.3) / 0.1)
        end

        image.Position = UDim2.new(0.5, random:NextInteger(-25, 25), 0.5, random:NextInteger(-25, 25))
        image.Rotation = random:NextInteger(-12, 12)

        if not damaged and isHiding() ~= shouldHide then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                damaged = true
                humanoid:TakeDamage(90)
                isPlayerActive()
            end
        end

        RunService.RenderStepped:Wait()
    end

    if currentImage == image then
        currentImage = nil
    end
    image:Destroy()
end

local function runChallenge(shouldHide)
    if not isMusicRunning() or not isPlayerActive() then
        return
    end

    caption(shouldHide and "躲藏" or "不躲藏")
    shakeCamera()

    local started = os.clock()
    while isMusicRunning() and isPlayerActive() and os.clock() - started < 0.8 do
        task.wait(0.02)
    end

    if isMusicRunning() and isPlayerActive() then
        showJumpScareAndCheck(shouldHide)
    end
end

music.Looped = false
music:Play()

if waitForMusicTime(10) and isPlayerActive() then
    caption("good luck")
end

local function isFinalTwentySeconds()
    return music.TimeLength > 0 and music.TimePosition >= math.max(0, music.TimeLength - 20)
end

if waitForMusicTime(14) then
    while isMusicRunning() do
        if spectator then
            break
        end

        if isPlayerActive() then
            local roundStart = music.TimePosition
            local shouldHide = random:NextInteger(1, 2) == 1
            runChallenge(shouldHide)

            local finalPhase = isFinalTwentySeconds()
            local nextRoundAt = roundStart + (finalPhase and random:NextNumber(3, 5) or random:NextNumber(5, 10))

            while isMusicRunning() and not spectator and music.TimePosition < nextRoundAt do
                isPlayerActive()
                if not finalPhase and isFinalTwentySeconds() then
                    finalPhase = true
                    nextRoundAt = music.TimePosition + random:NextNumber(3, 5)
                end
                task.wait(0.03)
            end
        else
            task.wait(0.1)
        end
    end
end

while isMusicRunning() do
    task.wait(0.1)
end

finishGame()
endedConnection:Disconnect()
stoppedConnection:Disconnect()
destroyingConnection:Disconnect()
end
function entityBehaviors.JeffTwo()
local RunService = game:GetService("RunService")
local V1 = game:GetObjects("rbxassetid://132473459444776")[1]
V1.Parent = workspace
local V2 = workspace:WaitForChild("JeffTheKiller")
local function HS()
    if not V2 then return end
    
    local function HP(obj)
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CanCollide = false
        end
        
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                child.Transparency = 1
            elseif child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") then
                child.Enabled = false
            end
            
            HP(child)
        end
    end
    local p1 = V2:FindFirstChild("Knife")
    local p2 = V2:FindFirstChild("Head")
    local p3 = V2:FindFirstChild("BoyAnimeHair_Black")
    if p1 then HP(p1) end
    if p2 then HP(p2) end
    if p3 then
        local handle = p3:FindFirstChild("Handle")
        if handle then HP(handle) end
    end
end
HS()
local connection
connection = V2.AncestryChanged:Connect(function(_, parent)
    if not parent then
        V1:Destroy()
        if connection then
            connection:Disconnect()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not V2 or not V2.Parent then 
        V1:Destroy()
        if connection then
            connection:Disconnect()
        end
        return 
    end
    local root = V2:FindFirstChild("HumanoidRootPart") or V2:FindFirstChild("Torso")
    if not root then return end
    if V1:IsA("Model") and V1.PrimaryPart then
        V1:SetPrimaryPartCFrame(root.CFrame)
    elseif V1:IsA("BasePart") then
        V1.CFrame = root.CFrame
    end
end)
end
function entityBehaviors.JEFFGUN()
local RunService = game:GetService("RunService")
local V1 = game:GetObjects("rbxassetid://81046861041760")[1]
V1.Parent = workspace
local V2 = workspace:WaitForChild("JeffTheKiller")

local xOffset = 0
local yOffset = 0
local zOffset = 0

if V1:IsA("Model") then
    local primary = V1:FindFirstChildWhichIsA("BasePart")
    if primary then
        V1.PrimaryPart = primary
    end
end

local function HS()
    if not V2 then return end
    
    local function HP(obj)
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CanCollide = false
        end
        
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                child.Transparency = 1
            elseif child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") then
                child.Enabled = false
            end
            
            HP(child)
        end
    end
    
    local p1 = V2:FindFirstChild("Knife")
    local p2 = V2:FindFirstChild("Head")
    local p3 = V2:FindFirstChild("BoyAnimeHair_Black")
    if p1 then HP(p1) end
    if p2 then HP(p2) end
    if p3 then
        local h = p3:Clone()
        h.Parent = V2
        HP(h)
    end
    
    local leftArm = V2:FindFirstChild("Left Arm")
    local rightArm = V2:FindFirstChild("Right Arm")
    if leftArm then HP(leftArm) end
    if rightArm then HP(rightArm) end
end

HS()

local connection
connection = V2.AncestryChanged:Connect(function(_, parent)
    if not parent then
        V1:Destroy()
        if connection then
            connection:Disconnect()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not V2 or not V2.Parent then 
        V1:Destroy()
        if connection then
            connection:Disconnect()
        end
        return 
    end

    local function findRootPart(model)
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        if root then 
            return root 
        end
        
        for _, child in pairs(model:GetDescendants()) do
            if (child.Name == "HumanoidRootPart" or child.Name == "Torso") and child:IsA("BasePart") then
                return child
            end
        end
        return nil
    end
    
    local root = findRootPart(V2)
    if not root then 
        V1:Destroy()
        if connection then
            connection:Disconnect()
        end
        return
    end
    if V1:IsA("Model") then
        if not V1.PrimaryPart then
            local part = V1:FindFirstChildWhichIsA("BasePart")
            if part then
                V1.PrimaryPart = part
            end
        end
        
        if V1.PrimaryPart then
            local newCFrame = CFrame.new(
                root.CFrame.Position.X + xOffset,
                root.CFrame.Position.Y + yOffset,
                root.CFrame.Position.Z + zOffset
            ) * root.CFrame.Rotation
            V1:SetPrimaryPartCFrame(newCFrame)
        end
    elseif V1:IsA("BasePart") then
        local newCFrame = CFrame.new(
            root.CFrame.Position.X + xOffset,
            root.CFrame.Position.Y + yOffset,
            root.CFrame.Position.Z + zOffset
        ) * root.CFrame.Rotation
        V1.CFrame = newCFrame
    end
end)
end
function entityBehaviors.JEFFGUNST()
local sound1 = Instance.new("Sound")
sound1.SoundId = "rbxassetid://3120031857"
sound1.Volume = 1
sound1.Parent = workspace
local sound2 = Instance.new("Sound")
sound2.SoundId = "rbxassetid://680140087"
sound2.Volume = 1
sound2.Parent = workspace
sound1:Play()
task.wait(1)
sound2:Play()
sound2.Ended:Wait()
sound1:Destroy()
sound2:Destroy()
end
function entityBehaviors.REBOUNDSW()
    local RunService = game:GetService("RunService")
    local ceaseHandledModels = setmetatable({}, { __mode = "k" })

    local testModelId = 129306212463084
    local reboundTemplate = nil
    local CameraShaker = require(game.ReplicatedStorage.CameraShaker)

    if _G.__ReboundMainCameraShake then
        pcall(function()
            _G.__ReboundMainCameraShake:Stop()
        end)
        _G.__ReboundMainCameraShake = nil
    end

    local reboundCameraShake = CameraShaker.new(
        Enum.RenderPriority.Camera.Value + 30,
        function(shakeCFrame)
            local activeCamera = workspace.CurrentCamera
            if activeCamera then
                activeCamera.CFrame = activeCamera.CFrame * shakeCFrame
            end
        end
    )
    reboundCameraShake:Start()
    _G.__ReboundMainCameraShake = reboundCameraShake

    local reboundCameraShakeStopped = false
    local function stopReboundCameraShake()
        if reboundCameraShakeStopped then
            return
        end
        reboundCameraShakeStopped = true
        pcall(function()
            reboundCameraShake:Stop()
        end)
        if _G.__ReboundMainCameraShake == reboundCameraShake then
            _G.__ReboundMainCameraShake = nil
        end
    end

    local function PlayPreloadedSound(soundName, volume)
        volume = volume or 1
        local soundFolder = workspace:FindFirstChild("HardCoreSound")
        if not soundFolder then
            return nil
        end

        local sound = soundFolder:FindFirstChild(soundName)
        if sound and sound:IsA("Sound") then
            sound.Volume = volume
            sound:Play()
            return sound
        end

        return nil
    end

    local function GetMaxExistingRoom()
        local rooms = workspace.CurrentRooms:GetChildren()
        local maxNum = 0
        for _, room in ipairs(rooms) do
            local num = tonumber(room.Name)
            if num and num > maxNum then
                maxNum = num
            end
        end
        return maxNum
    end

    local Players = game:GetService("Players")
    local reboundSealed = false
    local doorSignal = nil
    local movingSoundForWave = nil

    local function easeCrucifix(alpha)
        alpha = math.clamp(alpha, 0, 1)
        return alpha * alpha * (3 - 2 * alpha)
    end

    local function getCrucifixTool(character)
        if not character or not character:IsA("Model") then
            return nil
        end

        local directTool = character:FindFirstChild("Crucifix")
        if directTool and directTool:IsA("Tool") then
            return directTool
        end

        for _, descendant in ipairs(character:GetDescendants()) do
            if descendant.Name == "Crucifix" and descendant:IsA("Tool") then
                return descendant
            end
        end

        return nil
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

    local function getCrucifixVisualStates(root, shouldInclude, onlyRoot)
        local states = {}

        local function capture(object)
            if shouldInclude and not shouldInclude(object) then
                return
            end

            if object:IsA("BasePart") or object:IsA("Decal")
                or object:IsA("Texture") then
                table.insert(states, {
                    Object = object,
                    Kind = "Transparency",
                    Original = object.Transparency
                })
            elseif object:IsA("ParticleEmitter") or object:IsA("Beam")
                or object:IsA("Trail") then
                table.insert(states, {
                    Object = object,
                    Kind = "Sequence",
                    Original = object.Transparency
                })
            elseif object:IsA("Light") then
                table.insert(states, {
                    Object = object,
                    Kind = "Brightness",
                    Original = object.Brightness
                })
            elseif object:IsA("Highlight") then
                table.insert(states, {
                    Object = object,
                    Kind = "Highlight",
                    Fill = object.FillTransparency,
                    Outline = object.OutlineTransparency
                })
            elseif object:IsA("Smoke") then
                table.insert(states, {
                    Object = object,
                    Kind = "Smoke",
                    Original = object.Opacity
                })
            elseif object:IsA("Fire") then
                table.insert(states, {
                    Object = object,
                    Kind = "Fire",
                    Size = object.Size,
                    Heat = object.Heat
                })
            elseif object:IsA("Sound") then
                table.insert(states, {
                    Object = object,
                    Kind = "Sound",
                    Original = object.Volume
                })
            elseif object:IsA("GuiObject") then
                local state = {
                    Object = object,
                    Kind = "GuiObject",
                    Background = object.BackgroundTransparency
                }

                if object:IsA("ImageLabel") or object:IsA("ImageButton") then
                    state.Image = object.ImageTransparency
                end

                if object:IsA("TextLabel") or object:IsA("TextButton")
                    or object:IsA("TextBox") then
                    state.Text = object.TextTransparency
                end

                table.insert(states, state)
            end
        end

        capture(root)
        if not onlyRoot then
            for _, descendant in ipairs(root:GetDescendants()) do
                capture(descendant)
            end
        end

        return states
    end

    local function crucifixFadedSequence(original, factor)
        local keypoints = {}

        for _, keypoint in ipairs(original.Keypoints) do
            local nextTransparency = 1 - (1 - keypoint.Value) * factor
            table.insert(keypoints, NumberSequenceKeypoint.new(
                keypoint.Time,
                math.clamp(nextTransparency, 0, 1),
                keypoint.Envelope * factor
            ))
        end

        return NumberSequence.new(keypoints)
    end

    local function setCrucifixVisualFactor(states, factor)
        factor = math.clamp(factor, 0, 1)

        for _, state in ipairs(states) do
            local object = state.Object

            if object and object.Parent then
                if state.Kind == "Transparency" then
                    object.Transparency = 1 - (1 - state.Original) * factor
                elseif state.Kind == "Sequence" then
                    object.Transparency = crucifixFadedSequence(state.Original, factor)
                elseif state.Kind == "Brightness" then
                    object.Brightness = state.Original * factor
                elseif state.Kind == "Highlight" then
                    object.FillTransparency = 1 - (1 - state.Fill) * factor
                    object.OutlineTransparency = 1 - (1 - state.Outline) * factor
                elseif state.Kind == "Smoke" then
                    object.Opacity = state.Original * factor
                elseif state.Kind == "Fire" then
                    object.Size = state.Size * factor
                    object.Heat = state.Heat * factor
                elseif state.Kind == "Sound" then
                    object.Volume = state.Original * factor
                elseif state.Kind == "GuiObject" then
                    object.BackgroundTransparency = 1 - (1 - state.Background) * factor

                    if state.Image ~= nil then
                        object.ImageTransparency = 1 - (1 - state.Image) * factor
                    end

                    if state.Text ~= nil then
                        object.TextTransparency = 1 - (1 - state.Text) * factor
                    end
                end
            end
        end
    end

    local function fadeCrucifixVisuals(states, initialFactor, endFactor, duration)
        if duration <= 0 then
            setCrucifixVisualFactor(states, endFactor)
            return
        end

        local startTime = os.clock()

        while true do
            local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
            local eased = easeCrucifix(alpha)
            setCrucifixVisualFactor(
                states,
                initialFactor + (endFactor - initialFactor) * eased
            )

            if alpha >= 1 then
                break
            end

            RunService.Heartbeat:Wait()
        end
    end

    local function findCrucifixBeams(rushNew)
        local preferred = {}
        local fallback = {}

        for _, descendant in ipairs(rushNew:GetDescendants()) do
            if descendant:IsA("Beam") then
                table.insert(fallback, descendant)

                local ancestor = descendant.Parent
                while ancestor and ancestor ~= rushNew do
                    if string.lower(ancestor.Name) == "particlesin" then
                        table.insert(preferred, descendant)
                        break
                    end
                    ancestor = ancestor.Parent
                end

                if string.lower(descendant.Name) == "particlesin" then
                    local exists = false
                    for _, selected in ipairs(preferred) do
                        if selected == descendant then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        table.insert(preferred, descendant)
                    end
                end
            end
        end

        local beams = #preferred > 0 and preferred or fallback
        table.sort(beams, function(a, b)
            return a:GetFullName() < b:GetFullName()
        end)

        return beams
    end

    local function prepareCrucifixBeams(beams, rushNew, movingAttachment)
        for index, beam in ipairs(beams) do
            if beam.Parent then
                if not beam.Attachment0 then
                    beam.Attachment0 = movingAttachment
                end

                if not beam.Attachment1 or beam.Attachment1 == beam.Attachment0 then
                    local endpoint = Instance.new("Attachment")
                    endpoint.Name = "CrucifixBeamEndpoint" .. tostring(index)
                    local angle = (index - 1) * (math.pi / 2)
                    local offset = Vector3.new(
                        math.cos(angle) * 3,
                        2,
                        math.sin(angle) * 3
                    )
                    endpoint.Position = movingAttachment.Position
                        + rushNew.CFrame:VectorToObjectSpace(offset)
                    endpoint.Parent = rushNew
                    beam.Attachment1 = endpoint
                end

                if beam.Width0 <= 0 and beam.Width1 <= 0 then
                    beam.Width0 = 0.3
                    beam.Width1 = 0.3
                end

                beam.Enabled = true
                beam.Transparency = NumberSequence.new(1)
            end
        end
    end

    local crucifixBeamSoundIds = {
        "124444290902740",
        "100133789671771",
        "133850299035625",
        "120232105146350"
    }

    local function createCrucifixBeamFeedback()
        local beamCameraShaker = nil
        local shakeCleanupScheduled = false

        local function trigger(index)
            local soundId = crucifixBeamSoundIds[index]
            if not soundId then
                return
            end

            local sound = Instance.new("Sound")
            sound.Name = "CrucifixBeamSound" .. tostring(index)
            sound.SoundId = "rbxassetid://" .. soundId
            sound.Volume = 7
            sound.Looped = false
            sound.Parent = game:GetService("SoundService")
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
            sound:Play()

            if not beamCameraShaker then
                local module = game.ReplicatedStorage:FindFirstChild("CameraShaker")
                if module then
                    local loaded, CameraShaker = pcall(require, module)
                    if loaded and CameraShaker then
                        local created, shaker = pcall(function()
                            local currentShaker = CameraShaker.new(
                                Enum.RenderPriority.Camera.Value,
                                function(shakeCf)
                                    local camera = workspace.CurrentCamera
                                    if camera then
                                        camera.CFrame = camera.CFrame * shakeCf
                                    end
                                end
                            )
                            currentShaker:Start()
                            return currentShaker
                        end)
                        if created then
                            beamCameraShaker = shaker
                        end
                    end
                end
            end

            if beamCameraShaker then
                local started, shakeInstance = pcall(function()
                    return beamCameraShaker:StartShake(10, 28, 0.1, 0.25, 0.35)
                end)
                if started and shakeInstance then
                    task.delay(0.3, function()
                        pcall(function()
                            shakeInstance:StartFadeOut(3)
                        end)
                    end)
                else
                    pcall(function()
                        beamCameraShaker:ShakeOnce(10, 28, 0.1, 3, 0.25, 0.35)
                    end)
                end

                if not shakeCleanupScheduled then
                    shakeCleanupScheduled = true
                    task.delay(4.5, function()
                        if beamCameraShaker then
                            pcall(function()
                                beamCameraShaker:Stop()
                            end)
                        end
                    end)
                end
            end
        end

        return trigger
    end

    local function revealCrucifixBeams(beams, onBeamBegin)
        local startTime = os.clock()
        local perBeamDuration = 0.5
        local staggerDelay = 0.25
        local totalDuration = perBeamDuration + math.max(0, #beams - 1) * staggerDelay
        local begun = {}

        while true do
            local elapsed = os.clock() - startTime

            for index, beam in ipairs(beams) do
                if beam and beam.Parent then
                    local beamStartTime = (index - 1) * staggerDelay
                    if elapsed >= beamStartTime and not begun[index] then
                        begun[index] = true
                        if onBeamBegin then
                            onBeamBegin(index)
                        end
                    end

                    local beamAlpha = math.clamp(
                        (elapsed - beamStartTime) / perBeamDuration,
                        0,
                        1
                    )
                    beam.Enabled = true
                    beam.Transparency = NumberSequence.new(1 - easeCrucifix(beamAlpha))
                end
            end

            if elapsed >= totalDuration then
                break
            end
            RunService.Heartbeat:Wait()
        end

        for _, beam in ipairs(beams) do
            if beam and beam.Parent then
                beam.Enabled = true
                beam.Transparency = NumberSequence.new(0)
            end
        end
    end

    local function fadeCrucifixBeamsOut(beams, duration)
        local startTime = os.clock()

        while true do
            local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
            local transparency = easeCrucifix(alpha)

            for _, beam in ipairs(beams) do
                if beam and beam.Parent then
                    beam.Transparency = NumberSequence.new(transparency)
                end
            end

            if alpha >= 1 then
                break
            end
            RunService.Heartbeat:Wait()
        end

        for _, beam in ipairs(beams) do
            if beam and beam.Parent then
                beam.Transparency = NumberSequence.new(1)
                beam.Enabled = false
            end
        end
    end

    local function moveCrucifixAttachment(attachment, targetPosition, duration)
        local origin = attachment.Position
        local startTime = os.clock()

        while true do
            if not attachment.Parent then
                return false
            end

            local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
            local progress = easeCrucifix(alpha)
            attachment.Position = origin:Lerp(targetPosition, progress)

            if alpha >= 1 then
                attachment.Position = targetPosition
                return true
            end
            RunService.Heartbeat:Wait()
        end
    end

    local function fadeCrucifixDescendantsRecursively(root, duration)
        local found = {}
        local allStates = {}
        local stateCount = 0

        local function findChildren(object)
            if not object or found[object] then
                return
            end
            found[object] = true

            local states = getCrucifixVisualStates(object, nil, true)
            for _, state in ipairs(states) do
                table.insert(allStates, state)
                stateCount = stateCount + 1
            end

            for _, child in ipairs(object:GetChildren()) do
                findChildren(child)
            end
        end

        local startTime = os.clock()
        while true do
            if not root.Parent then
                return
            end

            findChildren(root)
            local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
            setCrucifixVisualFactor(allStates, 1 - easeCrucifix(alpha))

            if alpha >= 1 then
                break
            end

            for _, object in ipairs(root:GetDescendants()) do
                if not found[object] then
                    findChildren(object)
                end
            end
            RunService.Heartbeat:Wait()
        end
    end

    local function startCrucifixAmbientShake(replacement)
        local stepName = "ReboundCrucifixAmbient_"
            .. game:GetService("HttpService"):GenerateGUID(false)
        local startedAt = os.clock()
        local active = true
        local lastOffset = CFrame.new()
        local lastCamera = nil

        local function stop()
            if not active then
                return
            end
            active = false
            RunService:UnbindFromRenderStep(stepName)
        end

        RunService:BindToRenderStep(
            stepName,
            Enum.RenderPriority.Camera.Value + 3,
            function()
                if not replacement.Parent then
                    stop()
                    return
                end

                local camera = workspace.CurrentCamera
                if not camera then
                    return
                end

                if lastCamera ~= camera then
                    lastCamera = camera
                    lastOffset = CFrame.new()
                end

                local elapsed = os.clock() - startedAt
                local strength = easeCrucifix(math.clamp(elapsed / 0.5, 0, 1))
                local offset = CFrame.new(
                    math.sin(elapsed * 13) * 0.055 * strength,
                    math.sin(elapsed * 16 + 0.7) * 0.04 * strength,
                    0
                ) * CFrame.Angles(
                    math.sin(elapsed * 12) * math.rad(0.085) * strength,
                    math.sin(elapsed * 10 + 1.1) * math.rad(0.065) * strength,
                    0
                )

                camera.CFrame = camera.CFrame * lastOffset:Inverse() * offset
                lastOffset = offset
            end
        )

        return stop
    end

    local function runCrucifixReplacement(originalCFrame)

        local loadedSuccessfully, replacement = pcall(function()
            return game:GetObjects("rbxassetid://86848040233512")[1]
        end)

        if not loadedSuccessfully or not replacement then

            return
        end

        local targetCFrame = originalCFrame + Vector3.new(0, 0, 0)
        local bro = replacement.Name == "BRO" and replacement
            or replacement:FindFirstChild("BRO", true)

        local placed, placementError = pcall(function()
            if replacement:IsA("Model") then
                if bro and bro:IsA("Model") then
                    local pivotShift = targetCFrame * bro:GetPivot():Inverse()
                    replacement:PivotTo(pivotShift * replacement:GetPivot())
                else
                    replacement:PivotTo(targetCFrame)
                end
            elseif bro and bro:IsA("Model") then
                bro:PivotTo(targetCFrame)
            elseif replacement:IsA("BasePart") then
                replacement.CFrame = targetCFrame
            end

            for _, descendant in ipairs(replacement:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.Anchored = true
                    descendant.CanCollide = false
                    descendant.CanTouch = false
                end
            end

            if replacement:IsA("BasePart") then
                replacement.Anchored = true
                replacement.CanCollide = false
                replacement.CanTouch = false
            end

            replacement.Parent = workspace
        end)

        if not placed then

            replacement:Destroy()
            return
        end

        local stopAmbientShake = startCrucifixAmbientShake(replacement)
        task.delay(30, function()
            stopAmbientShake()
            if replacement and replacement.Parent then
                replacement:Destroy()
            end
        end)

        local animationOK, animationError = xpcall(function()
            local rushNew = (bro and bro:FindFirstChild("RushNew", true))
                or replacement:FindFirstChild("RushNew", true)
            if replacement.Name == "RushNew" and replacement:IsA("BasePart") then
                rushNew = replacement
            end
            local attachment = rushNew and rushNew:FindFirstChild("Attachment", true)
            if attachment and not attachment:IsA("Attachment") then
                attachment = nil
            end
            if not rushNew then

            elseif not attachment then

            else

            end

            task.wait(2.3)
            if not replacement.Parent then
                return
            end

            if rushNew and rushNew:IsA("BasePart") and attachment then
                local beams = findCrucifixBeams(rushNew)
                local introStates = getCrucifixVisualStates(attachment, function(object)
                    if not object:IsA("Beam") then
                        return true
                    end
                    for _, beam in ipairs(beams) do
                        if object == beam then
                            return false
                        end
                    end
                    return true
                end)

                setCrucifixVisualFactor(introStates, 0)
                prepareCrucifixBeams(beams, rushNew, attachment)

                local originalPosition = attachment.Position
                local upOffset = rushNew.CFrame:VectorToObjectSpace(Vector3.new(0, 3, 0))
                local downOffset = rushNew.CFrame:VectorToObjectSpace(Vector3.new(0, -20, 0))
                local upPosition = originalPosition + upOffset
                local downPosition = upPosition + downOffset

                task.spawn(function()
                    if attachment.Parent then
                        fadeCrucifixVisuals(introStates, 0, 1, 0.6)
                    end
                end)

                local beamsRevealFinished = #beams == 0
                if not beamsRevealFinished then
                    local playBeamFeedback = createCrucifixBeamFeedback()
                    task.spawn(function()
                        task.wait(0.8)
                        if replacement.Parent and attachment.Parent then
                            pcall(revealCrucifixBeams, beams, playBeamFeedback)
                        end
                        beamsRevealFinished = true
                    end)
                end

                if not moveCrucifixAttachment(attachment, upPosition, 1.8) then
                    return
                end

                while not beamsRevealFinished and replacement.Parent and attachment.Parent do
                    RunService.Heartbeat:Wait()
                end

                if not moveCrucifixAttachment(attachment, downPosition, 1.2) then
                    return
                end
                task.wait(2)
                fadeCrucifixBeamsOut(beams, 0.5)
            end
        end, function(err)
            return tostring(err) .. "\n" .. debug.traceback()
        end)

        if not animationOK then

        end
        local fadeOK, fadeError = pcall(function()
            fadeCrucifixDescendantsRecursively(replacement, 1)
        end)
        if not fadeOK then

        end
        if replacement.Parent then
            for _, descendant in ipairs(replacement:GetDescendants()) do
                if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam")
                    or descendant:IsA("Trail") or descendant:IsA("Sparkles")
                    or descendant:IsA("Smoke") or descendant:IsA("Fire") then
                    pcall(function()
                        descendant.Enabled = false
                    end)
                end
            end
        end
        task.wait(3)
        stopAmbientShake()
        if replacement then

            replacement:Destroy()
        end
    end


    function SpawnReboundEntity(startRoomType)
        if reboundSealed then
            return false
        end
        if not reboundTemplate then
            for attempt = 1, 6 do
                if reboundSealed then
                    return false
                end
                local success, loaded = pcall(function()
                    return game:GetObjects("rbxassetid://" .. testModelId)[1]
                end)
                if success and loaded then
                    reboundTemplate = loaded
                    break
                end
                if attempt < 6 then
                    task.wait(0.4)
                end
            end
        end

        if reboundSealed then
            return false
        end
        if not reboundTemplate then

            return false
        end

        local testEntity = reboundTemplate:Clone()
        if reboundSealed then
            if testEntity then
                testEntity:Destroy()
            end
            return false
        end
        if not testEntity then
            return false
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "Rebound" then
                pcall(function()
                    obj:Destroy()
                end)
            end
        end
        testEntity.Name = "Rebound"
        testEntity.Parent = workspace

        local primaryPart
        if testEntity:IsA("Model") then
            primaryPart = testEntity.PrimaryPart or testEntity:FindFirstChildWhichIsA("BasePart", true)
        elseif testEntity:IsA("BasePart") then
            primaryPart = testEntity
        end
        if not primaryPart then
            testEntity:Destroy()
            return false
        end

        primaryPart.Anchored = true
        primaryPart.CanCollide = false

        task.spawn(function()
            if reboundSealed or not primaryPart.Parent then
                return
            end
            local targetRoom
            if startRoomType == "start" then
                targetRoom = workspace.CurrentRooms:FindFirstChild("0")
            else
                local maxRoom = GetMaxExistingRoom()
                targetRoom = workspace.CurrentRooms:FindFirstChild(tostring(maxRoom))
            end

            if targetRoom then
                local targetPart
                if targetRoom:FindFirstChild("Nodes") then
                    targetPart = targetRoom:FindFirstChild("RoomEntrance")
                        or targetRoom:FindFirstChild("RoomExit")
                else
                    targetPart = targetRoom:FindFirstChild("RoomExit")
                        or targetRoom:FindFirstChild("RoomEntrance")
                end
                if not reboundSealed and primaryPart.Parent
                    and targetPart and targetPart:IsA("BasePart") then
                    primaryPart.CFrame = targetPart.CFrame + Vector3.new(0, 1, 0)
                end
            end

            task.wait(2)
            if not reboundSealed and primaryPart.Parent then
                StartEntityLogic(primaryPart, startRoomType)
            end
        end)
        return true
    end

    function StartEntityLogic(primaryPart, startRoomType)
        if reboundSealed or not primaryPart or not primaryPart.Parent then
            return
        end

        local lastProximityShake = 0
        task.spawn(function()
            local RunService = game:GetService("RunService")
            local player = game.Players.LocalPlayer

            while not reboundSealed and primaryPart and primaryPart.Parent do
                RunService.RenderStepped:Wait()
                if reboundSealed or not primaryPart or not primaryPart.Parent then
                    break
                end

                local character = player and player.Character
                local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                if humanoid and rootPart and humanoid.Health > 0 then
                    local distance = (primaryPart.Position - rootPart.Position).Magnitude

                    if distance <= 80 and os.clock() - lastProximityShake >= 0.12 then
                        local alpha = math.clamp(1 - distance / 80, 0, 1)
                        local amplitude = (0.3 + 8.2 * (alpha ^ 1.35)) * 3
                        local roughness = (45 + 35 * alpha) * 0.25
                        local positionInfluence = 0.35 + 0.4 * alpha
                        local rotationInfluence = 0.3 + 0.4 * alpha

                        reboundCameraShake:ShakeOnce(
                            amplitude,
                            roughness,
                            0.01,
                            0.16,
                            positionInfluence,
                            rotationInfluence
                        )

                        lastProximityShake = os.clock()
                    end
                end
            end

        end)

        local v305 = 1.4
        local v306 = 0.4
        local v307 = Vector3.new(0, 1, 0)
        local v310 = workspace.CurrentRooms

        local detectedPlayer = false
        local ceaseSpeedScale = 1
        local ceaseFreezeActive = false
        local ceaseFreezeToken = 0
        local ceaseStoredEffects = {}
        local ceaseDescendantConnection = nil
        local ceaseSoundConnection = nil
        local reboundMoving = false
        local activeMovementTween = nil
        local activeMovementTarget = nil
        local activeMovementOrigin = nil
        local ceaseStopMotionTween = nil
        local ceaseResumeMotionTween = nil
        local reboundMovementEnded = false
        local reboundModel = primaryPart:FindFirstAncestor("Rebound")
        if not reboundModel and primaryPart.Name == "Rebound" then
            reboundModel = primaryPart
        end

        local function easeCease(alpha)
            alpha = math.clamp(alpha, 0, 1)
            return alpha * alpha * (3 - 2 * alpha)
        end

        local function applyCeaseScale(scale)
            ceaseSpeedScale = math.clamp(scale, 0, 1)
            for obj, state in pairs(ceaseStoredEffects) do
                if obj.Parent then
                    if state.IsParticle then
                        pcall(function()
                            obj.TimeScale = state.TimeScale * ceaseSpeedScale
                        end)
                    else
                        pcall(function()
                            obj.PlaybackSpeed = state.PlaybackSpeed * ceaseSpeedScale
                        end)
                        pcall(function()
                            obj.Volume = state.Volume * ceaseSpeedScale
                        end)
                        if ceaseSpeedScale <= 0 then
                            if not state.PausedByCease and obj.IsPlaying then
                                pcall(function()
                                    obj:Pause()
                                    state.PausedByCease = true
                                end)
                            end
                        elseif state.PausedByCease then
                            pcall(function()
                                obj:Resume()
                                state.PausedByCease = false
                            end)
                        end
                    end
                end
            end
        end

        local function trackCeaseEffect(obj)
            if ceaseStoredEffects[obj] then
                return
            end
            if obj:IsA("ParticleEmitter") then
                ceaseStoredEffects[obj] = {
                    IsParticle = true,
                    TimeScale = obj.TimeScale
                }
            elseif obj:IsA("Sound") then
                ceaseStoredEffects[obj] = {
                    IsParticle = false,
                    PlaybackSpeed = obj.PlaybackSpeed,
                    Volume = obj.Volume,
                    PausedByCease = false
                }
            else
                return
            end

            if ceaseFreezeActive then
                local state = ceaseStoredEffects[obj]
                if state.IsParticle then
                    pcall(function()
                        obj.TimeScale = state.TimeScale * ceaseSpeedScale
                    end)
                else
                    pcall(function()
                        obj.PlaybackSpeed = state.PlaybackSpeed * ceaseSpeedScale
                    end)
                    pcall(function()
                        obj.Volume = state.Volume * ceaseSpeedScale
                    end)
                end
            end
        end

        local function restoreCeaseEffects(resumeMovement)
            ceaseFreezeToken = ceaseFreezeToken + 1
            if ceaseStopMotionTween then
                ceaseStopMotionTween:Cancel()
                ceaseStopMotionTween = nil
            end
            if ceaseResumeMotionTween then
                ceaseResumeMotionTween:Cancel()
                ceaseResumeMotionTween = nil
            end
            if ceaseDescendantConnection then
                ceaseDescendantConnection:Disconnect()
                ceaseDescendantConnection = nil
            end
            if ceaseSoundConnection then
                ceaseSoundConnection:Disconnect()
                ceaseSoundConnection = nil
            end
            for obj, state in pairs(ceaseStoredEffects) do
                if obj.Parent then
                    if state.IsParticle then
                        pcall(function()
                            obj.TimeScale = state.TimeScale
                        end)
                    else
                        pcall(function()
                            obj.PlaybackSpeed = state.PlaybackSpeed
                        end)
                        pcall(function()
                            obj.Volume = state.Volume
                        end)
                        if state.PausedByCease then
                            pcall(function()
                                obj:Resume()
                            end)
                        end
                    end
                end
            end
            ceaseStoredEffects = {}
            ceaseSpeedScale = 1
            ceaseFreezeActive = false
            if resumeMovement and not detectedPlayer and primaryPart.Parent and activeMovementTarget then
                local remainingDistance = (activeMovementTarget.Position - primaryPart.Position).Magnitude
                local originalDistance = activeMovementOrigin
                    and (activeMovementTarget.Position - activeMovementOrigin.Position).Magnitude or 0
                local originalSpeed = originalDistance > 0 and originalDistance / v305 or 0
                if remainingDistance > 0.01 then
                    local remainingDuration = originalSpeed > 0
                        and math.max(remainingDistance / originalSpeed, 0.01) or v305
                    activeMovementTween = game.TweenService:Create(
                        primaryPart,
                        TweenInfo.new(remainingDuration, Enum.EasingStyle.Linear),
                        { CFrame = activeMovementTarget }
                    )
                    activeMovementTween:Play()
                end
            end
        end

        local function trySealRebound(character)
            if reboundSealed or not primaryPart.Parent
                or not character or character:GetAttribute("Hiding") then

                return false
            end
            local tool = getCrucifixTool(character)
            if not tool then

                return false
            end


            local sealCFrame = primaryPart.CFrame
            reboundSealed = true
            detectedPlayer = true
            reboundMovementEnded = true
            reboundMoving = false
            stopReboundCameraShake()

            if activeMovementTween then
                activeMovementTween:Cancel()
                activeMovementTween = nil
            end
            if ceaseFreezeActive then
                restoreCeaseEffects(false)
            end
            if movingSoundForWave and movingSoundForWave.Parent then
                movingSoundForWave:Stop()
            end

            tool:Destroy()
            if reboundModel and reboundModel.Parent then
                reboundModel:Destroy()
            elseif primaryPart.Parent then
                primaryPart:Destroy()
            end

            if doorSignal then
                doorSignal:Fire()
            end
            task.spawn(runCrucifixReplacement, sealCFrame)
            return true
        end

        local function triggerCeaseFreeze(ceaseModel)
            if ceaseFreezeActive or not reboundMoving or reboundMovementEnded
                or not primaryPart.Parent or ceaseHandledModels[ceaseModel]
                or not activeMovementTween
                or activeMovementTween.PlaybackState ~= Enum.PlaybackState.Playing then
                return
            end

            ceaseHandledModels[ceaseModel] = true
            ceaseFreezeActive = true
            ceaseFreezeToken = ceaseFreezeToken + 1
            local token = ceaseFreezeToken

            activeMovementTween:Cancel()
            activeMovementTween = nil
            local startCFrame = primaryPart.CFrame
            local destination = activeMovementTarget
            local remainingDistance = (destination.Position - startCFrame.Position).Magnitude
            local originalDistance = activeMovementOrigin
                and (destination.Position - activeMovementOrigin.Position).Magnitude or remainingDistance
            local initialSpeed = originalDistance / v305
            local stopDistance = math.min(remainingDistance, initialSpeed * 2.25 / 5)
            local stopFraction = remainingDistance > 0.001 and stopDistance / remainingDistance or 0
            local stoppingCFrame = startCFrame:Lerp(destination, math.clamp(stopFraction, 0, 1))
            ceaseStopMotionTween = game.TweenService:Create(
                primaryPart,
                TweenInfo.new(2.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                { CFrame = stoppingCFrame }
            )
            ceaseStopMotionTween:Play()

            if reboundModel then
                trackCeaseEffect(reboundModel)
                for _, obj in ipairs(reboundModel:GetDescendants()) do
                    trackCeaseEffect(obj)
                end
                ceaseDescendantConnection = reboundModel.DescendantAdded:Connect(function(obj)
                    if ceaseFreezeToken == token and ceaseFreezeActive then
                        trackCeaseEffect(obj)
                    end
                end)
            end

            local soundFolder = workspace:FindFirstChild("HardCoreSound")
            if soundFolder then
                for _, obj in ipairs(soundFolder:GetDescendants()) do
                    if obj:IsA("Sound") and obj.Name:lower():find("rebound", 1, true) then
                        trackCeaseEffect(obj)
                    end
                end
                ceaseSoundConnection = soundFolder.DescendantAdded:Connect(function(obj)
                    if ceaseFreezeToken == token and ceaseFreezeActive
                        and obj:IsA("Sound") and obj.Name:lower():find("rebound", 1, true) then
                        trackCeaseEffect(obj)
                    end
                end)
            end

            task.spawn(function()
                local function isValid()
                    return ceaseFreezeToken == token
                        and primaryPart.Parent ~= nil
                        and not reboundMovementEnded
                end

                local function transition(fromScale, toScale, duration)
                    local startedAt = os.clock()
                    while true do
                        if not isValid() then
                            if ceaseFreezeToken == token then
                                restoreCeaseEffects()
                            end
                            return false
                        end
                        local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
                        applyCeaseScale(fromScale + (toScale - fromScale) * easeCease(alpha))
                        if alpha >= 1 then
                            return true
                        end
                        RunService.Heartbeat:Wait()
                    end
                end

                if not transition(1, 0, 2.25) then
                    return
                end
                if ceaseStopMotionTween then
                    ceaseStopMotionTween:Cancel()
                    ceaseStopMotionTween = nil
                end
                local holdStartedAt = os.clock()
                while os.clock() - holdStartedAt < 13 do
                    if not isValid() then
                        if ceaseFreezeToken == token then
                            restoreCeaseEffects()
                        end
                        return
                    end
                    task.wait(0.05)
                end
                local remainingDistance = (destination.Position - primaryPart.Position).Magnitude
                local recoverDistance = math.min(remainingDistance, initialSpeed * 2 / 5)
                local recoverFraction = remainingDistance > 0.001
                    and recoverDistance / remainingDistance or 0
                local recoveringCFrame = primaryPart.CFrame:Lerp(
                    destination, math.clamp(recoverFraction, 0, 1)
                )
                ceaseResumeMotionTween = game.TweenService:Create(
                    primaryPart,
                    TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                    { CFrame = recoveringCFrame }
                )
                ceaseResumeMotionTween:Play()
                if not transition(0, 1, 2) then
                    return
                end
                if ceaseFreezeToken == token then
                    restoreCeaseEffects(true)
                end
            end)
        end

        task.spawn(function()
            while primaryPart.Parent and not reboundMovementEnded and not reboundSealed do
                if reboundMoving and not ceaseFreezeActive then
                    local ceaseModel = workspace:FindFirstChild("Cease", true)
                    if ceaseModel and ceaseModel:IsA("Model")
                        and not ceaseHandledModels[ceaseModel] then
                        triggerCeaseFreeze(ceaseModel)
                    end
                end
                task.wait(0.1)
            end
            if ceaseFreezeActive then
                restoreCeaseEffects()
            end
        end)

        local function startReboundTween(targetCFrame)
            if reboundSealed or not primaryPart.Parent then
                return false
            end
            activeMovementOrigin = primaryPart.CFrame
            activeMovementTarget = targetCFrame
            activeMovementTween = game.TweenService:Create(
                primaryPart,
                TweenInfo.new(v305),
                { CFrame = targetCFrame }
            )
            reboundMoving = true
            activeMovementTween:Play()
            return true
        end

        local function waitReboundStep(duration)
            local elapsed = 0
            while not reboundSealed and elapsed < duration and primaryPart.Parent do
                local dt = RunService.Heartbeat:Wait()
                if not ceaseFreezeActive then
                    elapsed = elapsed + dt
                end
            end
            while not reboundSealed and ceaseFreezeActive and primaryPart.Parent do
                RunService.Heartbeat:Wait()
            end
            return not reboundSealed and primaryPart.Parent ~= nil
        end

        local function waitForReboundArrival()
            local destination = activeMovementTarget
            if not destination then
                return false
            end
            while not reboundSealed and primaryPart.Parent do
                if not ceaseFreezeActive then
                    local remaining = (destination.Position - primaryPart.Position).Magnitude
                    if remaining <= 0.05 then
                        return true
                    end
                    local state = activeMovementTween and activeMovementTween.PlaybackState
                    if not activeMovementTween
                        or state == Enum.PlaybackState.Cancelled
                        or state == Enum.PlaybackState.Completed then
                        local fullDistance = activeMovementOrigin
                            and (destination.Position - activeMovementOrigin.Position).Magnitude or remaining
                        local segmentSpeed = fullDistance > 0 and fullDistance / v305 or 0
                        local duration = segmentSpeed > 0
                            and math.max(remaining / segmentSpeed, 0.01) or v305
                        activeMovementTween = game.TweenService:Create(
                            primaryPart,
                            TweenInfo.new(duration, Enum.EasingStyle.Linear),
                            { CFrame = destination }
                        )
                        activeMovementTween:Play()
                    end
                end
                RunService.Heartbeat:Wait()
            end
            return false
        end

        local function CheckLineOfSight(entityPart, player, maxDistance)
            if not entityPart or not player or not player.Character then
                return false
            end
            if player.Character:GetAttribute("Hiding") then
                return false
            end
            
            local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
            if not hum or hum.Health <= 0 then
                return false
            end
            
            local origin = entityPart.Position
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            
            local targetPos = hrp.Position
            local distance = (targetPos - origin).Magnitude
            
            if distance <= 0.001 or distance > maxDistance then
                return false
            end
            local direction = (targetPos - origin).Unit * maxDistance
            local ray = Ray.new(origin, direction)
            local hitPart, _ = workspace:FindPartOnRay(ray, entityPart)
            
            return hitPart and hitPart:IsDescendantOf(player.Character)
        end

        local function CheckCrucifixRaycast(entityPart, player, maxDistance)
            if reboundSealed or not entityPart or not entityPart.Parent or not player then
                return nil
            end
            local character = player.Character
            if not character then

                return nil
            end
            if not character:IsDescendantOf(workspace) then

                return nil
            end
            if character:GetAttribute("Hiding") then

                return nil
            end

            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoid or humanoid.Health <= 0 then

                return nil
            end
            if not rootPart or not rootPart:IsA("BasePart") then

                return nil
            end

            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = { reboundModel or entityPart }

            local targets = { rootPart }
            for _, partName in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso" }) do
                local part = character:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    table.insert(targets, part)
                end
            end

            for _, part in ipairs(targets) do
                if reboundSealed or not entityPart.Parent then
                    return nil
                end
                local direction = part.Position - entityPart.Position
                local distance = direction.Magnitude
                if distance > 0.001 and distance <= maxDistance then
                    local result = workspace:Raycast(entityPart.Position, direction, raycastParams)
                    local hitPart = result and result.Instance
                    local hitCharacter = hitPart and getCharacterFromRaycastHit(hitPart) or nil

                    if not hitCharacter then
                        local partEntry = rayEntryDistanceToPart(
                            entityPart.Position, direction.Unit, part)
                        if partEntry and partEntry <= distance + 0.01 then
                            if not result or result.Distance > partEntry + 0.02 then
                                hitCharacter = character
                            end
                        end
                    end

                    if hitCharacter and not hitCharacter:GetAttribute("Hiding") then
                        local hitHumanoid = hitCharacter:FindFirstChildWhichIsA("Humanoid")
                        if hitHumanoid and hitHumanoid.Health > 0 then
                            local tool = getCrucifixTool(hitCharacter)
                            if tool then
                                return hitCharacter
                            end
                        end
                    end
                end
            end

            return nil
        end

        local function ExecutePlayer()
            if reboundSealed or detectedPlayer then return end
            detectedPlayer = true
            if ceaseFreezeActive then
                restoreCeaseEffects()
            end

            local vu321 = Instance.new("ScreenGui")
            local vu322 = Instance.new("ImageLabel")
            local v323 = Instance.new("ImageLabel")
            local v324 = Instance.new("ImageLabel")
            
            vu321.Name = "TestEntityJs"
            vu321.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            
            vu322.Name = "Static"
            vu322.Parent = vu321
            vu322.BackgroundColor3 = Color3.fromRGB(0, 63, 139)
            vu322.BackgroundTransparency = 1
            vu322.BorderSizePixel = 0
            vu322.Size = UDim2.new(1, 0, 1, 0)
            vu322.Image = "rbxassetid://236543215"
            vu322.ImageColor3 = Color3.fromRGB(0, 255, 255)
            vu322.ImageTransparency = 1
            
            v323.Name = "TestEntity"
            v323.Parent = vu321
            v323.BackgroundTransparency = 1
            v323.Position = UDim2.new(0.486631036, 0, 0.479363143, 0)
            v323.Size = UDim2.new(0.0267379656, 0, 0.0387096703, 0)
            v323.Image = "rbxassetid://97823818277141"
            
            v324.Name = "JSSIZE"
            v324.Parent = vu321
            v324.BackgroundTransparency = 1
            v324.Position = UDim2.new(-0.586452842, 0, -1.25140607, 0)
            v324.Size = UDim2.new(2.12834215, 0, 3.08128953, 0)
            v324.Visible = false
            v324.Image = "rbxassetid://10914800940"

            local function v326()
                local v325 = Instance.new("LocalScript", vu322)
                while v325.Parent and v325.Parent.Parent do
                    v325.Parent.Image = "rbxassetid://236543215"
                    task.wait(0.015)
                    v325.Parent.Rotation = 0
                    task.wait(0.015)
                    v325.Parent.Rotation = 180
                    task.wait(0.015)
                    v325.Parent.Image = "rbxassetid://236777652"
                    task.wait(0.015)
                    v325.Parent.Rotation = 0
                    task.wait(0.015)
                    v325.Parent.Rotation = 180
                    task.wait(0.015)
                end
            end
            coroutine.wrap(v326)()

            local v327 = Instance.new("LocalScript", vu321)
            local vu328 = game.ReplicatedStorage
            local vu329 = game.Players.LocalPlayer
            local vu330 = v327.Parent
            local vu331 = vu330.Static
            local vu332 = vu330.TestEntity
            
            local killSound = Instance.new("Sound")
            killSound.SoundId = "rbxassetid://94785993416953"
            killSound.Parent = workspace
            killSound.Volume = 2

            (function()
                game.TweenService:Create(vu331, TweenInfo.new(0.5), {
                    BackgroundTransparency = 0,
                    ImageTransparency = 0.8
                }):Play()
                
                game.TweenService:Create(vu332, TweenInfo.new(0.5), {
                    Size = v324.Size,
                    Position = v324.Position
                }):Play()
                
                killSound:Play()
                
                spawn(function()
                    wait(0.3)
                    if reboundSealed then
                        return
                    end
                    local char = vu329.Character
                    if char then
                        local hum = char:FindFirstChildWhichIsA("Humanoid")
                        if hum and hum.Health > 0 then
                            local damage = 100
                            local willDie = hum.Health <= damage
                            if willDie then
                                local playerStats = vu328.GameStats:FindFirstChild("Player_" .. vu329.Name)
                                local total = playerStats and playerStats:FindFirstChild("Total")
                                local deathCause = total and total:FindFirstChild("DeathCause")
                                if deathCause then
                                    deathCause.Value = "Rebound"
                                end
                            end
                            hum:TakeDamage(damage)
                        end
                    end
                end)
                
                wait(0.5)
                game.TweenService:Create(vu331, TweenInfo.new(1), {
                    BackgroundTransparency = 1,
                    ImageTransparency = 1
                }):Play()
                game.TweenService:Create(vu332, TweenInfo.new(0.3), {
                    ImageTransparency = 1
                }):Play()
                wait(1)
                killSound:Destroy()
                vu330:Destroy()
            end)()
        end

        spawn(function()
            local player = Players.LocalPlayer

            while not reboundSealed and primaryPart and primaryPart.Parent do
                task.wait(0.05)
                if reboundSealed or not primaryPart or not primaryPart.Parent then
                    break
                end
                if workspace:FindFirstChild("SeekMov") or workspace.CurrentRooms:FindFirstChild("50") then
                    break
                end

                for _, candidate in ipairs(Players:GetPlayers()) do
                    local hitCharacter = CheckCrucifixRaycast(primaryPart, candidate, 100)
                    if hitCharacter and getCrucifixTool(hitCharacter) then
                        if trySealRebound(hitCharacter) then
                            break
                        end
                    end
                end

                if reboundSealed then
                    break
                end
                if CheckLineOfSight(primaryPart, player, 100) then
                    ExecutePlayer()
                end
            end
        end)

        if startRoomType == "start" then
            local currentRoom = 0
            local maxRoom = game.ReplicatedStorage.GameData.LatestRoom.Value

            while currentRoom <= maxRoom and not reboundSealed and primaryPart.Parent do
                if workspace:FindFirstChild("SeekMovingNewClone") or workspace.CurrentRooms:FindFirstChild("9000") then
                    break
                end

                local targetRoom = v310:FindFirstChild(tostring(currentRoom))
                if targetRoom then
                    local targetCFrame
                    if targetRoom:FindFirstChild("Nodes") then
                        targetCFrame = (targetRoom:FindFirstChild("RoomEntrance") or targetRoom:FindFirstChild("RoomExit")).CFrame
                    else
                        targetCFrame = targetRoom.RoomExit.CFrame
                    end

                    if not startReboundTween(targetCFrame + v307) then
                        break
                    end

                    if not waitReboundStep(v306) then
                        break
                    end
                    if not waitForReboundArrival() then
                        break
                    end
                end

                maxRoom = game.ReplicatedStorage.GameData.LatestRoom.Value
                currentRoom = currentRoom + 1
            end
        else
            local currentRoom = GetMaxExistingRoom()
            local minRoom = math.max(0, currentRoom - 7)

            while currentRoom >= minRoom and not reboundSealed and primaryPart.Parent do
                if workspace:FindFirstChild("SeekMovingNewClone") or workspace.CurrentRooms:FindFirstChild("50") then
                    break
                end

                local targetRoom = v310:FindFirstChild(tostring(currentRoom))
                if targetRoom then
                    local targetCFrame
                    if targetRoom:FindFirstChild("Nodes") then
                        targetCFrame = (targetRoom:FindFirstChild("RoomEntrance") or targetRoom:FindFirstChild("RoomExit")).CFrame
                    else
                        targetCFrame = targetRoom.RoomExit.CFrame
                    end

                    if not startReboundTween(targetCFrame + v307) then
                        break
                    end

                    if not waitReboundStep(v306) then
                        break
                    end
                    if not waitForReboundArrival() then
                        break
                    end
                end

                currentRoom = currentRoom - 1
            end
        end

        while not reboundSealed and ceaseFreezeActive and primaryPart.Parent do
            RunService.Heartbeat:Wait()
        end
        reboundMovementEnded = true
        if ceaseFreezeActive then
            restoreCeaseEffects()
        end
        if primaryPart.Parent then
            primaryPart.Anchored = false
            primaryPart.CanCollide = false
        end
    end

    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "Rebound" or obj.Name == "Bound" or 
           (obj.Name:find("ReboundMovings") and not obj.Name:find("_Preloaded")) or 
           (obj.Name:find("ReboundSweep") and not obj.Name:find("_Preloaded")) then
            pcall(function() obj:Destroy() end)
        end
    end

    local sweepSound = PlayPreloadedSound("ReboundSweep", 2)
    
    local part = Instance.new("Part")
    part.Name = "Bound_" .. tick()
    part.Parent = workspace
    game.Lighting.MainColorCorrection.TintColor = Color3.fromRGB(61, 171, 98)
    game.Lighting.MainColorCorrection.Contrast = 0.2
    game.Lighting.MainColorCorrection.Saturation = -0.7

    local tween = game:GetService("TweenService")
    tween:Create(game.Lighting.MainColorCorrection, TweenInfo.new(5), {Contrast = 0}):Play()
    tween:Create(game.Lighting.MainColorCorrection, TweenInfo.new(5), {Saturation = 0}):Play()
    local TW = tween:Create(game.Lighting.MainColorCorrection, TweenInfo.new(5), {TintColor = Color3.fromRGB(255, 255, 255)})
    TW:Play()

    reboundCameraShake:ShakeOnce(10, 3, 0.1, 6, 2, 0.5)

    task.wait(3)

    local latestRoom = game.ReplicatedStorage.GameData.LatestRoom
    local doorGateOpen = false
    local acceptedDoorCount = 0
    doorSignal = Instance.new("BindableEvent")
    local doorConnection = latestRoom:GetPropertyChangedSignal("Value"):Connect(function()
        if doorGateOpen and not reboundSealed then
            acceptedDoorCount = acceptedDoorCount + 1
            doorSignal:Fire()
        end
    end)

    local function waitForSoundToFinish(sound)
        if not sound or not sound.Parent then
            return
        end
        local finished = false
        local connection = sound.Ended:Connect(function()
            finished = true
        end)
        local startedAt = os.clock()
        while not reboundSealed and sound.Parent and not finished do
            if os.clock() - startedAt >= 120 then
                break
            end
            if not sound.IsLoaded and os.clock() - startedAt >= 15 then
                break
            end
            task.wait(0.05)
        end
        connection:Disconnect()
    end

    local function waitForNextQualifiedDoor()
        if reboundSealed then
            return false
        end
        local previousAcceptedCount = acceptedDoorCount
        doorGateOpen = true
        while not reboundSealed and acceptedDoorCount == previousAcceptedCount do
            doorSignal.Event:Wait()
        end
        doorGateOpen = false
        return not reboundSealed
    end

    local directions = { "latest", "start", "latest", "start" }
    for waveIndex, startRoomType in ipairs(directions) do
        if reboundSealed then
            break
        end
        SpawnReboundEntity(startRoomType)
        if reboundSealed then
            break
        end
        movingSoundForWave = PlayPreloadedSound("ReboundMovings", 3)
        waitForSoundToFinish(movingSoundForWave)
        movingSoundForWave = nil
        if reboundSealed then
            break
        end
        if waveIndex < #directions then
            if not waitForNextQualifiedDoor() then
                break
            end
        end
    end
    doorGateOpen = false
    doorConnection:Disconnect()
    if doorSignal then
        doorSignal:Destroy()
        doorSignal = nil
    end
    stopReboundCameraShake()
    doorSignal = nil

end
function entityBehaviors.JEFFGUN2()
local RunService = game:GetService("RunService")
local V1 = game:GetObjects("rbxassetid://134258088105212")[1]
V1.Parent = workspace
local V2 = workspace:WaitForChild("JeffTheKiller")

local xOffset = 0
local yOffset = 0
local zOffset = 0

if V1:IsA("Model") then
    local primary = V1:FindFirstChildWhichIsA("BasePart")
    if primary then
        V1.PrimaryPart = primary
    end
end

local function HS()
    if not V2 then return end
    
    local function HP(obj)
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CanCollide = false
        end
        
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                child.Transparency = 1
            elseif child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") then
                child.Enabled = false
            end
            
            HP(child)
        end
    end
    
    local p1 = V2:FindFirstChild("Knife")
    local p2 = V2:FindFirstChild("Head")
    local p3 = V2:FindFirstChild("BoyAnimeHair_Black")
    if p1 then HP(p1) end
    if p2 then HP(p2) end
    if p3 then
        local h = p3:Clone()
        h.Parent = V2
        HP(h)
    end
    
    local leftArm = V2:FindFirstChild("Left Arm")
    local rightArm = V2:FindFirstChild("Right Arm")
    if leftArm then HP(leftArm) end
    if rightArm then HP(rightArm) end
end

HS()

local connection
connection = V2.AncestryChanged:Connect(function(_, parent)
    if not parent then
        V1:Destroy()
        if connection then
            connection:Disconnect()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not V2 or not V2.Parent then 
        V1:Destroy()
        if connection then
            connection:Disconnect()
        end
        return 
    end

    local function findRootPart(model)
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        if root then 
            return root 
        end
        
        for _, child in pairs(model:GetDescendants()) do
            if (child.Name == "HumanoidRootPart" or child.Name == "Torso") and child:IsA("BasePart") then
                return child
            end
        end
        return nil
    end
    
    local root = findRootPart(V2)
    if not root then 
        V1:Destroy()
        if connection then
            connection:Disconnect()
        end
        return
    end
    if V1:IsA("Model") then
        if not V1.PrimaryPart then
            local part = V1:FindFirstChildWhichIsA("BasePart")
            if part then
                V1.PrimaryPart = part
            end
        end
        
        if V1.PrimaryPart then
            local newCFrame = CFrame.new(
                root.CFrame.Position.X + xOffset,
                root.CFrame.Position.Y + yOffset,
                root.CFrame.Position.Z + zOffset
            ) * root.CFrame.Rotation
            V1:SetPrimaryPartCFrame(newCFrame)
        end
    elseif V1:IsA("BasePart") then
        local newCFrame = CFrame.new(
            root.CFrame.Position.X + xOffset,
            root.CFrame.Position.Y + yOffset,
            root.CFrame.Position.Z + zOffset
        ) * root.CFrame.Rotation
        V1.CFrame = newCFrame
    end
end)
end
function entityBehaviors.gunjeffkq()
local sound = Instance.new("Sound")
sound.Name = "Subspace"
sound.SoundId = "rbxassetid://89344175304287"
sound.Volume = 4
sound.Parent = workspace

sound.Ended:Connect(function()
    sound:Destroy()
end)
sound:Play()
end
function entityBehaviors.MONTNS()
local concrete = workspace.MonumentEntity.Top.Concrete
local decal = Instance.new("Decal")
decal.Texture = "rbxassetid://155213173"
decal.Parent = concrete
end
function entityBehaviors.MOSCJ()
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Red = Color3.fromRGB(255, 7, 11)
local function PlaySound(parent, soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.Parent = parent
	task.spawn(function()
		task.wait(0.1)
		sound:Play()
		sound.Ended:Wait()
		sound:Destroy()
	end)

end
local function GlitchText(TextLabel, Duration)

	if not TextLabel then
		return
	end

	local Original = TextLabel.Text

	local GlitchChars = {
		"▓",
		"█",
		"▒",
		"#",
		"%",
		"@",
		"0",
		"1",
		"7",
		"X",
		"?"
	}
	task.spawn(function()
		local Start = tick()
		while tick() - Start < Duration do
			if not TextLabel.Parent then
				return
			end
			local Result = ""
			for n = 1,#Original do
				local Char = Original:sub(n,n)
				if Char == " " or Char == "'" then

					Result = Result .. Char

				else
					if math.random() < 0.45 then
						Result =
							Result ..
							GlitchChars[
								math.random(
									1,
									#GlitchChars
								)
							]

					else

						Result =
							Result .. Char

					end

				end

			end

			TextLabel.Text = Result

			task.wait(0.08)

		end


		if TextLabel.Parent then
			TextLabel.Text = Original
		end

	end)

end



local function ApplyRedTheme(Achievement)

	for _,v in ipairs(Achievement:GetDescendants()) do

		if v:IsA("TextLabel") then
			v.TextColor3 = Red
		end


		if v:IsA("UIStroke") then
			v.Color = Red
		end


		if v:IsA("Frame") then
			v.BorderColor3 = Red
		end

	end

end



local function DoorsNotify(NotifyOptions)

	NotifyOptions = NotifyOptions or {}


	local PlayerGui =
		LocalPlayer:WaitForChild("PlayerGui")


	local UIContainer =
		PlayerGui:FindFirstChild("GlobalUI")
		or
		PlayerGui:FindFirstChild("MainUI")


	if not UIContainer then
		return
	end


	local AchievementsHolder =
		UIContainer:FindFirstChild("AchievementsHolder")


	if not AchievementsHolder then
		return
	end


	local Template =
		AchievementsHolder:FindFirstChild("Achievement")


	if not Template then
		return
	end


	local Achievement = Template:Clone()


	Achievement.Size =
		UDim2.new(0,0,0,0)


	Achievement.Frame.Position =
		UDim2.new(1.1,0,0,0)


	Achievement.Name =
		"LiveAchievement"


	Achievement.Visible = true



	Achievement.Frame.TextLabel.Text =
		NotifyOptions.Style
		or
		"NOTIFICATION"



	Achievement.Frame.Details.Title.Text =
		NotifyOptions.Title
		or
		"Sem Título"



	Achievement.Frame.Details.Desc.Text =
		NotifyOptions.Description
		or
		"Sem Descrição"



	Achievement.Frame.Details.Reason.Text =
		NotifyOptions.Reason
		or ""



	Achievement.Frame.ImageLabel.Image =
		(
			NotifyOptions.Image
			and
			NotifyOptions.Image ~= ""
		)
		and
		NotifyOptions.Image
		or
		"rbxassetid://0"



	ApplyRedTheme(Achievement)


	Achievement.Parent =
		AchievementsHolder



	PlaySound(
		AchievementsHolder,
		"rbxassetid://10469938989",
		1
	)



	task.spawn(function()

		task.wait(0.1)

		GlitchText(
			Achievement.Frame.Details.Title,
			NotifyOptions.Time or 5
		)

	end)



	task.spawn(function()


		Achievement:TweenSize(
			UDim2.new(1,0,0.2,0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Quad,
			0.8,
			true
		)


		task.wait(0.8)


		Achievement.Frame:TweenPosition(
			UDim2.new(0,0,0,0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.5,
			true
		)



		local Glow =
			Achievement.Frame:FindFirstChild("Glow")


		if Glow then

			TweenService:Create(
				Glow,
				TweenInfo.new(
					1,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In
				),
				{
					ImageTransparency = 1
				}
			):Play()

		end



		if typeof(NotifyOptions.Time) == "Instance" then

			NotifyOptions.Time.Destroying:Wait()

		else

			task.wait(
				NotifyOptions.Time or 5
			)

		end



		if not Achievement.Parent then
			return
		end



		Achievement.Frame:TweenPosition(
			UDim2.new(1.1,0,0,0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Quad,
			0.5,
			true
		)



		task.wait(0.5)



		Achievement:TweenSize(
			UDim2.new(1,0,-0.1,0),
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Quad,
			0.5,
			true
		)



		task.wait(0.5)


		Achievement:Destroy()

	end)

end



DoorsNotify({
	Style = "Done!",
	Title = "Someone Else's Turn",
	Description = "Survive The MultiMonsters",
	Reason = "No matter where you are, there's always a buzzing sound following you...",
	Image = "rbxassetid://100946605902758",
	Time = 6
})
end
function entityBehaviors.A500F()
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local flipActive = true
local flipStart = os.clock()
local flipDuration = 5
local flipDirection = 2
RunService:BindToRenderStep("ScreenFlipOnce", Enum.RenderPriority.Camera.Value + 1, function()
local now = os.clock()
local progress = (now - flipStart) / flipDuration
if progress >= 1 then
RunService:UnbindFromRenderStep("ScreenFlipOnce")
return
end
local curve = math.sin(progress * math.pi) ^ 0.4
local flipAngle = math.rad(360) * curve * flipDirection
camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, flipAngle)
end)
end
function entityBehaviors.A4()
 local hardCoreSound = workspace:FindFirstChild("HardCoreSound")
    local A4 = hardCoreSound and hardCoreSound:FindFirstChild("A4")
    if A4 and A4:IsA("Sound") then
        A4:Stop()
        A4.TimePosition = 0
        A4:Play()
    end
end
function entityBehaviors.A5()
 local hardCoreSound = workspace:FindFirstChild("HardCoreSound")
    local A5 = hardCoreSound and hardCoreSound:FindFirstChild("A5")
    if A5 and A5:IsA("Sound") then
        A5:Stop()
        A5.TimePosition = 0
        A5:Play()
    end
end
function entityBehaviors.A6()
 local hardCoreSound = workspace:FindFirstChild("HardCoreSound")
    local A6 = hardCoreSound and hardCoreSound:FindFirstChild("A6")
    if A6 and A6:IsA("Sound") then
        A6:Stop()
        A6.TimePosition = 0
        A6:Play()
    end
end
function entityBehaviors.A7()
 local hardCoreSound = workspace:FindFirstChild("HardCoreSound")
    local A7 = hardCoreSound and hardCoreSound:FindFirstChild("A7")
    if A7 and A7:IsA("Sound") then
        A7:Stop()
        A7.TimePosition = 0
        A7:Play()
    end
end
function entityBehaviors.Silence2()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local InsertService = game:GetService("InsertService")

local SILENCE_ASSET_ID = 131179838362680
local CRUCIFIX_ASSET_ID = 128235155752478
local JUMPSCARE_SOUND_ID = "rbxassetid://1592934514"
local JUMPSCARE_IMAGE_ID = "rbxassetid://139425974297545"
local JUMPSCARE_IMAGE_ALT_ID = "rbxassetid://71258076152603"
local SILENCE_SPEED = 20
local DETECTION_DISTANCE = 200
local HEIGHT_OFFSET = Vector3.new(0, 0, 0)
local JUMPSCARE_DAMAGE = 180

local silence = nil
local isJumpScaring = false
local hasJumpScared = false
local isSilenceDespawning = false
local crucifixActivated = false
local silenceIsMoving = false
local silenceMoveCancelled = false
local ceaseFreezeActive = false
local ceaseSpeedScale = 1
local ceaseFreezeSerial = 0
local ceaseSavedEffects = {}
local ceaseDescendantConnection = nil
local ceaseHandledModels = setmetatable({}, { __mode = "k" })

local function ease(alpha)
    alpha = math.clamp(alpha, 0, 1)
    return alpha * alpha * (3 - 2 * alpha)
end

local function loadModel(assetId, fallbackName)
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)

    if success and type(objects) == "table" then
        for _, object in ipairs(objects) do
            if object:IsA("Model") then
                return object
            end
        end
    end

    local template = ReplicatedStorage:FindFirstChild(fallbackName, true)
    if template and template:IsA("Model") then
        return template:Clone()
    end

    local loaded, asset = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)

    if loaded and asset and asset:IsA("Model") then
        return asset
    end

    return nil
end

local function prepareModel(model, queryable)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = queryable
        end
    end
end

local function getSilencePosition()
    if silence and silence.Parent then
        return silence:GetPivot().Position
    end
    return nil
end

local function isActive()
    return silence ~= nil
        and silence.Parent ~= nil
        and not crucifixActivated
        and not isSilenceDespawning
        and not silenceMoveCancelled
end

local function applyCeaseSpeed(scale)
    ceaseSpeedScale = math.clamp(scale, 0, 1)

    for object, saved in pairs(ceaseSavedEffects) do
        if object.Parent then
            if saved.Type == "Particle" then
                pcall(function()
                    object.TimeScale = saved.TimeScale * ceaseSpeedScale
                end)
            else
                pcall(function()
                    object.PlaybackSpeed = saved.PlaybackSpeed * ceaseSpeedScale
                    object.Volume = saved.Volume * ceaseSpeedScale
                end)
            end
        end
    end
end

local function trackCeaseEffect(object)
    if ceaseSavedEffects[object] then
        return
    end

    if object:IsA("ParticleEmitter") then
        ceaseSavedEffects[object] = {
            Type = "Particle",
            TimeScale = object.TimeScale
        }
    elseif object:IsA("Sound") then
        ceaseSavedEffects[object] = {
            Type = "Sound",
            PlaybackSpeed = object.PlaybackSpeed,
            Volume = object.Volume
        }
    else
        return
    end

    if ceaseFreezeActive then
        local saved = ceaseSavedEffects[object]
        if saved.Type == "Particle" then
            pcall(function()
                object.TimeScale = saved.TimeScale * ceaseSpeedScale
            end)
        else
            pcall(function()
                object.PlaybackSpeed = saved.PlaybackSpeed * ceaseSpeedScale
                object.Volume = saved.Volume * ceaseSpeedScale
            end)
        end
    end
end

local function cancelCeaseFreeze()
    ceaseFreezeSerial = ceaseFreezeSerial + 1

    if ceaseDescendantConnection then
        ceaseDescendantConnection:Disconnect()
        ceaseDescendantConnection = nil
    end

    for object, saved in pairs(ceaseSavedEffects) do
        if object.Parent then
            if saved.Type == "Particle" then
                pcall(function()
                    object.TimeScale = saved.TimeScale
                end)
            else
                pcall(function()
                    object.PlaybackSpeed = saved.PlaybackSpeed
                    object.Volume = saved.Volume
                end)
            end
        end
    end

    ceaseSavedEffects = {}
    ceaseSpeedScale = 1
    ceaseFreezeActive = false
end

local function startCeaseFreeze(ceaseModel)
    if ceaseFreezeActive or not silenceIsMoving or not isActive()
        or isJumpScaring or ceaseHandledModels[ceaseModel] then
        return
    end

    ceaseHandledModels[ceaseModel] = true
    ceaseFreezeActive = true
    ceaseFreezeSerial = ceaseFreezeSerial + 1
    local freezeSerial = ceaseFreezeSerial
    local currentSilence = silence

    for _, descendant in ipairs(currentSilence:GetDescendants()) do
        trackCeaseEffect(descendant)
    end

    ceaseDescendantConnection = currentSilence.DescendantAdded:Connect(function(descendant)
        if ceaseFreezeActive and ceaseFreezeSerial == freezeSerial then
            trackCeaseEffect(descendant)
        end
    end)

    task.spawn(function()
        local function stillValid()
            return ceaseFreezeSerial == freezeSerial
                and silence == currentSilence
                and currentSilence.Parent ~= nil
                and not isJumpScaring
                and not crucifixActivated
                and not isSilenceDespawning
        end

        local function transition(fromScale, toScale, duration)
            local startedAt = os.clock()
            while true do
                if not stillValid() then
                    if ceaseFreezeSerial == freezeSerial then
                        cancelCeaseFreeze()
                    end
                    return false
                end

                local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
                applyCeaseSpeed(fromScale + (toScale - fromScale) * ease(alpha))
                if alpha >= 1 then
                    return true
                end
                RunService.Heartbeat:Wait()
            end
        end

        if not transition(1, 0, 2.25) then
            return
        end

        local holdStartedAt = os.clock()
        while os.clock() - holdStartedAt < 13 do
            if not stillValid() then
                if ceaseFreezeSerial == freezeSerial then
                    cancelCeaseFreeze()
                end
                return
            end
            task.wait(0.05)
        end

        if not transition(0, 1, 2) then
            return
        end

        if ceaseFreezeSerial == freezeSerial then
            cancelCeaseFreeze()
        end
    end)
end

local function stopSilenceMovement()
    silenceMoveCancelled = true
    silenceIsMoving = false
    cancelCeaseFreeze()
end

local function destroySilence()
    stopSilenceMovement()
    isSilenceDespawning = true
    local previousSilence = silence
    silence = nil
    if previousSilence then
        previousSilence:Destroy()
    end
end

local function getCrucifixTool(character)
    if not character or not character:IsA("Model") then
        return nil
    end

    local direct = character:FindFirstChild("Crucifix")
    if direct and direct:IsA("Tool") then
        return direct
    end

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant.Name == "Crucifix" and descendant:IsA("Tool") then
            return descendant
        end
    end

    return nil
end

local function getCharacterFromHit(hitInstance)
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
    local entry, exitDistance = 0, math.huge

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
            exitDistance = math.min(exitDistance, far)
            if exitDistance < entry then
                return nil
            end
        end
    end

    return entry
end

local easeCease = ease

local function getCrucifixVisualStates(root, shouldInclude, onlyRoot)
    local states = {}

    local function capture(object)
        if shouldInclude and not shouldInclude(object) then
            return
        end

        if object:IsA("BasePart") or object:IsA("Decal")
            or object:IsA("Texture") then
            table.insert(states, {
                Object = object,
                Kind = "Transparency",
                Original = object.Transparency
            })
        elseif object:IsA("ParticleEmitter") or object:IsA("Beam")
            or object:IsA("Trail") then
            table.insert(states, {
                Object = object,
                Kind = "Sequence",
                Original = object.Transparency
            })
        elseif object:IsA("Light") then
            table.insert(states, {
                Object = object,
                Kind = "Brightness",
                Original = object.Brightness
            })
        elseif object:IsA("Highlight") then
            table.insert(states, {
                Object = object,
                Kind = "Highlight",
                Fill = object.FillTransparency,
                Outline = object.OutlineTransparency
            })
        elseif object:IsA("Smoke") then
            table.insert(states, {
                Object = object,
                Kind = "Smoke",
                Original = object.Opacity
            })
        elseif object:IsA("Fire") then
            table.insert(states, {
                Object = object,
                Kind = "Fire",
                Size = object.Size,
                Heat = object.Heat
            })
        elseif object:IsA("Sound") then
            table.insert(states, {
                Object = object,
                Kind = "Sound",
                Original = object.Volume
            })
        elseif object:IsA("GuiObject") then
            local state = {
                Object = object,
                Kind = "GuiObject",
                Background = object.BackgroundTransparency
            }

            if object:IsA("ImageLabel") or object:IsA("ImageButton") then
                state.Image = object.ImageTransparency
            end

            if object:IsA("TextLabel") or object:IsA("TextButton")
                or object:IsA("TextBox") then
                state.Text = object.TextTransparency
            end

            table.insert(states, state)
        end
    end

    capture(root)
    if not onlyRoot then
        for _, descendant in ipairs(root:GetDescendants()) do
            capture(descendant)
        end
    end

    return states
end

local function crucifixFadedSequence(original, factor)
    local keypoints = {}

    for _, keypoint in ipairs(original.Keypoints) do
        local nextTransparency = 1 - (1 - keypoint.Value) * factor
        table.insert(keypoints, NumberSequenceKeypoint.new(
            keypoint.Time,
            math.clamp(nextTransparency, 0, 1),
            keypoint.Envelope * factor
        ))
    end

    return NumberSequence.new(keypoints)
end

local function setCrucifixVisualFactor(states, factor)
    factor = math.clamp(factor, 0, 1)

    for _, state in ipairs(states) do
        local object = state.Object

        if object and object.Parent then
            if state.Kind == "Transparency" then
                object.Transparency = 1 - (1 - state.Original) * factor
            elseif state.Kind == "Sequence" then
                object.Transparency = crucifixFadedSequence(state.Original, factor)
            elseif state.Kind == "Brightness" then
                object.Brightness = state.Original * factor
            elseif state.Kind == "Highlight" then
                object.FillTransparency = 1 - (1 - state.Fill) * factor
                object.OutlineTransparency = 1 - (1 - state.Outline) * factor
            elseif state.Kind == "Smoke" then
                object.Opacity = state.Original * factor
            elseif state.Kind == "Fire" then
                object.Size = state.Size * factor
                object.Heat = state.Heat * factor
            elseif state.Kind == "Sound" then
                object.Volume = state.Original * factor
            elseif state.Kind == "GuiObject" then
                object.BackgroundTransparency = 1 - (1 - state.Background) * factor

                if state.Image ~= nil then
                    object.ImageTransparency = 1 - (1 - state.Image) * factor
                end

                if state.Text ~= nil then
                    object.TextTransparency = 1 - (1 - state.Text) * factor
                end
            end
        end
    end
end

local function fadeCrucifixVisuals(states, initialFactor, endFactor, duration)
    if duration <= 0 then
        setCrucifixVisualFactor(states, endFactor)
        return
    end

    local startTime = os.clock()

    while true do
        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        local eased = easeCease(alpha)
        setCrucifixVisualFactor(
            states,
            initialFactor + (endFactor - initialFactor) * eased
        )

        if alpha >= 1 then
            break
        end

        RunService.Heartbeat:Wait()
    end
end

local function findCrucifixBeams(rushNew)
    local preferred = {}
    local fallback = {}

    for _, descendant in ipairs(rushNew:GetDescendants()) do
        if descendant:IsA("Beam") then
            table.insert(fallback, descendant)

            local ancestor = descendant.Parent
            while ancestor and ancestor ~= rushNew do
                if string.lower(ancestor.Name) == "particlesin" then
                    table.insert(preferred, descendant)
                    break
                end
                ancestor = ancestor.Parent
            end

            if string.lower(descendant.Name) == "particlesin" then
                local exists = false
                for _, selected in ipairs(preferred) do
                    if selected == descendant then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(preferred, descendant)
                end
            end
        end
    end

    local beams = #preferred > 0 and preferred or fallback
    table.sort(beams, function(a, b)
        return a:GetFullName() < b:GetFullName()
    end)

    return beams
end

local function prepareCrucifixBeams(beams, rushNew, movingAttachment)
    for index, beam in ipairs(beams) do
        if beam.Parent then
            if not beam.Attachment0 then
                beam.Attachment0 = movingAttachment
            end

            if not beam.Attachment1 or beam.Attachment1 == beam.Attachment0 then
                local endpoint = Instance.new("Attachment")
                endpoint.Name = "CrucifixBeamEndpoint" .. tostring(index)
                local angle = (index - 1) * (math.pi / 2)
                local offset = Vector3.new(
                    math.cos(angle) * 3,
                    2,
                    math.sin(angle) * 3
                )
                endpoint.Position = movingAttachment.Position
                    + rushNew.CFrame:VectorToObjectSpace(offset)
                endpoint.Parent = rushNew
                beam.Attachment1 = endpoint
            end

            if beam.Width0 <= 0 and beam.Width1 <= 0 then
                beam.Width0 = 0.3
                beam.Width1 = 0.3
            end

            beam.Enabled = true
            beam.Transparency = NumberSequence.new(1)
        end
    end
end

local crucifixBeamSoundIds = {
    "124444290902740",
    "100133789671771",
    "133850299035625",
    "120232105146350"
}

local function createCrucifixBeamFeedback()
    local beamCameraShaker = nil
    local shakeCleanupScheduled = false

    local function trigger(index)
        local soundId = crucifixBeamSoundIds[index]
        if not soundId then
            return
        end

        local sound = Instance.new("Sound")
        sound.Name = "CrucifixBeamSound" .. tostring(index)
        sound.SoundId = "rbxassetid://" .. soundId
        sound.Volume = 7
        sound.Looped = false
        sound.Parent = game:GetService("SoundService")
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
        sound:Play()

        if not beamCameraShaker then
            local module = game.ReplicatedStorage:FindFirstChild("CameraShaker")
            if module then
                local loaded, CameraShaker = pcall(require, module)
                if loaded and CameraShaker then
                    local created, shaker = pcall(function()
                        local currentShaker = CameraShaker.new(
                            Enum.RenderPriority.Camera.Value,
                            function(shakeCf)
                                local camera = workspace.CurrentCamera
                                if camera then
                                    camera.CFrame = camera.CFrame * shakeCf
                                end
                            end
                        )
                        currentShaker:Start()
                        return currentShaker
                    end)
                    if created then
                        beamCameraShaker = shaker
                    end
                end
            end
        end

        if beamCameraShaker then
            local started, shakeInstance = pcall(function()
                return beamCameraShaker:StartShake(10, 28, 0.1, 0.25, 0.35)
            end)
            if started and shakeInstance then
                task.delay(0.3, function()
                    pcall(function()
                        shakeInstance:StartFadeOut(3)
                    end)
                end)
            else
                pcall(function()
                    beamCameraShaker:ShakeOnce(10, 28, 0.1, 3, 0.25, 0.35)
                end)
            end

            if not shakeCleanupScheduled then
                shakeCleanupScheduled = true
                task.delay(4.5, function()
                    if beamCameraShaker then
                        pcall(function()
                            beamCameraShaker:Stop()
                        end)
                    end
                end)
            end
        end
    end

    return trigger
end

local function revealCrucifixBeams(beams, onBeamBegin)
    local startTime = os.clock()
    local perBeamDuration = 0.5
    local staggerDelay = 0.25
    local totalDuration = perBeamDuration + math.max(0, #beams - 1) * staggerDelay
    local begun = {}

    while true do
        local elapsed = os.clock() - startTime

        for index, beam in ipairs(beams) do
            if beam and beam.Parent then
                local beamStartTime = (index - 1) * staggerDelay
                if elapsed >= beamStartTime and not begun[index] then
                    begun[index] = true
                    if onBeamBegin then
                        onBeamBegin(index)
                    end
                end

                local beamAlpha = math.clamp(
                    (elapsed - beamStartTime) / perBeamDuration,
                    0,
                    1
                )
                beam.Enabled = true
                beam.Transparency = NumberSequence.new(1 - easeCease(beamAlpha))
            end
        end

        if elapsed >= totalDuration then
            break
        end
        RunService.Heartbeat:Wait()
    end

    for _, beam in ipairs(beams) do
        if beam and beam.Parent then
            beam.Enabled = true
            beam.Transparency = NumberSequence.new(0)
        end
    end
end

local function fadeCrucifixBeamsOut(beams, duration)
    local startTime = os.clock()

    while true do
        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        local transparency = easeCease(alpha)

        for _, beam in ipairs(beams) do
            if beam and beam.Parent then
                beam.Transparency = NumberSequence.new(transparency)
            end
        end

        if alpha >= 1 then
            break
        end
        RunService.Heartbeat:Wait()
    end

    for _, beam in ipairs(beams) do
        if beam and beam.Parent then
            beam.Transparency = NumberSequence.new(1)
            beam.Enabled = false
        end
    end
end

local function moveCrucifixAttachment(attachment, targetPosition, duration)
    local origin = attachment.Position
    local startTime = os.clock()

    while true do
        if not attachment.Parent then
            return false
        end

        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        local progress = easeCease(alpha)
        attachment.Position = origin:Lerp(targetPosition, progress)

        if alpha >= 1 then
            attachment.Position = targetPosition
            return true
        end
        RunService.Heartbeat:Wait()
    end
end

local function fadeCrucifixDescendantsRecursively(root, duration)
    local found = {}
    local allStates = {}
    local stateCount = 0

    local function findChildren(object)
        if not object or found[object] then
            return
        end
        found[object] = true

        local states = getCrucifixVisualStates(object, nil, true)
        for _, state in ipairs(states) do
            table.insert(allStates, state)
            stateCount = stateCount + 1
        end

        for _, child in ipairs(object:GetChildren()) do
            findChildren(child)
        end
    end

    local startTime = os.clock()
    while true do
        if not root.Parent then
            return
        end

        findChildren(root)
        local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
        setCrucifixVisualFactor(allStates, 1 - easeCease(alpha))

        if alpha >= 1 then
            break
        end

        for _, object in ipairs(root:GetDescendants()) do
            if not found[object] then
                findChildren(object)
            end
        end
        RunService.Heartbeat:Wait()
    end
end

local function startCrucifixAmbientShake(replacement)
    local stepName = "SilenceCrucifixAmbient_"
        .. game:GetService("HttpService"):GenerateGUID(false)
    local startedAt = os.clock()
    local active = true
    local lastOffset = CFrame.new()
    local lastCamera = nil

    local function stop()
        if not active then
            return
        end
        active = false
        RunService:UnbindFromRenderStep(stepName)
    end

    RunService:BindToRenderStep(
        stepName,
        Enum.RenderPriority.Camera.Value + 3,
        function()
            if not replacement.Parent then
                stop()
                return
            end

            local camera = workspace.CurrentCamera
            if not camera then
                return
            end

            if lastCamera ~= camera then
                lastCamera = camera
                lastOffset = CFrame.new()
            end

            local elapsed = os.clock() - startedAt
            local strength = easeCease(math.clamp(elapsed / 0.5, 0, 1))
            local offset = CFrame.new(
                math.sin(elapsed * 13) * 0.055 * strength,
                math.sin(elapsed * 16 + 0.7) * 0.04 * strength,
                0
            ) * CFrame.Angles(
                math.sin(elapsed * 12) * math.rad(0.085) * strength,
                math.sin(elapsed * 10 + 1.1) * math.rad(0.065) * strength,
                0
            )

            camera.CFrame = camera.CFrame * lastOffset:Inverse() * offset
            lastOffset = offset
        end
    )

    return stop
end

local function runCrucifixReplacement(originalCFrame)

    local loadedSuccessfully, replacement = pcall(function()
        return game:GetObjects("rbxassetid://128235155752478")[1]
    end)

    if not loadedSuccessfully or not replacement then

        return
    end

    local targetCFrame = originalCFrame + Vector3.new(0, 1, 0)
    local bro = replacement.Name == "BRO" and replacement
        or replacement:FindFirstChild("BRO", true)

    local placed, placementError = pcall(function()
        if replacement:IsA("Model") then
            if bro and bro:IsA("Model") then
                local pivotShift = targetCFrame * bro:GetPivot():Inverse()
                replacement:PivotTo(pivotShift * replacement:GetPivot())
            else
                replacement:PivotTo(targetCFrame)
            end
        elseif bro and bro:IsA("Model") then
            bro:PivotTo(targetCFrame)
        elseif replacement:IsA("BasePart") then
            replacement.CFrame = targetCFrame
        end

        for _, descendant in ipairs(replacement:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.Anchored = true
                descendant.CanCollide = false
                descendant.CanTouch = false
            end
        end

        if replacement:IsA("BasePart") then
            replacement.Anchored = true
            replacement.CanCollide = false
            replacement.CanTouch = false
        end

        replacement.Parent = workspace
    end)

    if not placed then

        replacement:Destroy()
        return
    end

    local stopAmbientShake = startCrucifixAmbientShake(replacement)
    task.delay(30, function()
        stopAmbientShake()
        if replacement and replacement.Parent then
            replacement:Destroy()
        end
    end)

    local animationOK, animationError = xpcall(function()
        local rushNew = bro and bro:FindFirstChild("RushNew", true)
        local attachment = rushNew and rushNew:FindFirstChild("Attachment", true)
        if attachment and not attachment:IsA("Attachment") then
            attachment = nil
        end
        if not rushNew then

        elseif not attachment then

        else

        end

        task.wait(2.3)
        if not replacement.Parent then
            return
        end

        if rushNew and rushNew:IsA("BasePart") and attachment then
            local beams = findCrucifixBeams(rushNew)
            local introStates = getCrucifixVisualStates(attachment, function(object)
                if not object:IsA("Beam") then
                    return true
                end
                for _, beam in ipairs(beams) do
                    if object == beam then
                        return false
                    end
                end
                return true
            end)

            setCrucifixVisualFactor(introStates, 0)
            prepareCrucifixBeams(beams, rushNew, attachment)

            local originalPosition = attachment.Position
            local upOffset = rushNew.CFrame:VectorToObjectSpace(Vector3.new(0, 3, 0))
            local downOffset = rushNew.CFrame:VectorToObjectSpace(Vector3.new(0, -20, 0))
            local upPosition = originalPosition + upOffset
            local downPosition = upPosition + downOffset

            task.spawn(function()
                if attachment.Parent then
                    fadeCrucifixVisuals(introStates, 0, 1, 0.6)
                end
            end)

            local beamsRevealFinished = #beams == 0
            if not beamsRevealFinished then
                local playBeamFeedback = createCrucifixBeamFeedback()
                task.spawn(function()
                    task.wait(0.8)
                    if replacement.Parent and attachment.Parent then
                        pcall(revealCrucifixBeams, beams, playBeamFeedback)
                    end
                    beamsRevealFinished = true
                end)
            end

            if not moveCrucifixAttachment(attachment, upPosition, 1.8) then
                error("Attachment 上升中被删除")
            end

            while not beamsRevealFinished and replacement.Parent and attachment.Parent do
                RunService.Heartbeat:Wait()
            end

            if not moveCrucifixAttachment(attachment, downPosition, 1.2) then
                error("Attachment 下降中被删除")
            end
            task.wait(2)
            fadeCrucifixBeamsOut(beams, 0.5)
        end
    end, function(err)
        return tostring(err) .. "\n" .. debug.traceback()
    end)

    if not animationOK then

    end
    local fadeOK, fadeError = pcall(function()
        fadeCrucifixDescendantsRecursively(replacement, 1)
    end)
    if not fadeOK then

    end
    if replacement.Parent then
        for _, descendant in ipairs(replacement:GetDescendants()) do
            if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam")
                or descendant:IsA("Trail") or descendant:IsA("Sparkles")
                or descendant:IsA("Smoke") or descendant:IsA("Fire") then
                pcall(function()
                    descendant.Enabled = false
                end)
            end
        end
    end
    task.wait(3)
    stopAmbientShake()
    if replacement then

        replacement:Destroy()
    end
end

local function tryUseCrucifix(character)
    if crucifixActivated or isJumpScaring or not isActive()
        or not character or character:GetAttribute("Hiding") then
        return false
    end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local tool = getCrucifixTool(character)
    if not tool then
        return false
    end

    crucifixActivated = true
    local lastCFrame = silence:GetPivot()
    tool:Destroy()
    destroySilence()
    task.spawn(runCrucifixReplacement, lastCFrame)
    return true
end

local function scanPlayerCrucifixRaycasts()
    if not isActive() or isJumpScaring then
        return false
    end

    local currentSilence = silence
    local origin = getSilencePosition()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { currentSilence }

    for _, candidatePlayer in ipairs(Players:GetPlayers()) do
        if not isActive() or currentSilence ~= silence then
            return crucifixActivated
        end

        local character = candidatePlayer.Character
        if character and character:IsDescendantOf(workspace)
            and not character:GetAttribute("Hiding") then
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0
                and rootPart and rootPart:IsA("BasePart")
                and getCrucifixTool(character) then
                local targets = { rootPart }
                for _, name in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso" }) do
                    local part = character:FindFirstChild(name)
                    if part and part:IsA("BasePart") then
                        table.insert(targets, part)
                    end
                end

                for _, targetPart in ipairs(targets) do
                    local direction = targetPart.Position - origin
                    local distance = direction.Magnitude
                    if distance > 0.001 and distance <= DETECTION_DISTANCE then
                        local result = workspace:Raycast(origin, direction, raycastParams)
                        local hitCharacter = result and getCharacterFromHit(result.Instance)

                        if not hitCharacter then
                            local entryDistance = rayEntryDistanceToPart(origin, direction.Unit, targetPart)
                            if entryDistance and entryDistance <= distance + 0.01
                                and (not result or result.Distance > entryDistance + 0.02) then
                                hitCharacter = character
                            end
                        end

                        if hitCharacter and not hitCharacter:GetAttribute("Hiding") then
                            if tryUseCrucifix(hitCharacter) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

local function setDeathCause(player)
    local gameStats = ReplicatedStorage:FindFirstChild("GameStats")
    if not gameStats then
        return
    end

    local playerStat = gameStats:FindFirstChild("Player_" .. player.Name)
    if not playerStat then
        return
    end

    local total = playerStat:FindFirstChild("Total")
    if not total then
        return
    end

    local deathCause = total:FindFirstChild("DeathCause")
    if deathCause then
        deathCause.Value = "Silence"
    end
end

local function playJumpscareSound()
    local sound = Instance.new("Sound")
    sound.Name = "SilenceJumpscareSound"
    sound.SoundId = JUMPSCARE_SOUND_ID
    sound.Volume = 3
    sound.Looped = false
    sound.Parent = SoundService

    local cleaned = false
    local function cleanup()
        if cleaned then
            return
        end
        cleaned = true
        if sound.Parent then
            sound:Destroy()
        end
    end

    sound.Ended:Once(cleanup)
    task.delay(30, cleanup)
    sound:Play()
end

local function triggerSilenceJumpScare(character)
    if not isActive() or isJumpScaring or hasJumpScared or crucifixActivated then
        return
    end

    if tryUseCrucifix(character) then
        return
    end

    local player = Players:GetPlayerFromCharacter(character)
    if not player or player ~= Players.LocalPlayer then
        return
    end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 or character:GetAttribute("Hiding") then
        return
    end

    isJumpScaring = true
    playJumpscareSound()
    cancelCeaseFreeze()

    local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
    if not playerGui then
        isJumpScaring = false
        return
    end
    hasJumpScared = true

    local existing = playerGui:FindFirstChild("SilenceJumpscare")
    if existing then
        existing:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SilenceJumpscare"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 10000
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BorderSizePixel = 0
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.ZIndex = 1
    background.Parent = screenGui

    task.wait(0.8)
    if not screenGui.Parent then
        isJumpScaring = false
        return
    end

    local image = Instance.new("ImageLabel")
    image.Name = "SilenceImage"
    image.AnchorPoint = Vector2.new(0.5, 0.5)
    image.Position = UDim2.fromScale(0.5, 0.5)
    image.Size = UDim2.fromScale(0.08, 0.08)
    image.BackgroundTransparency = 1
    image.Image = JUMPSCARE_IMAGE_ID
    image.ScaleType = Enum.ScaleType.Fit
    image.ZIndex = 2
    image.Parent = screenGui

    local flashActive = true
    task.spawn(function()
        local isWhite = false
        while flashActive and background.Parent do
            task.wait(0.065)
            if not flashActive or not background.Parent then
                break
            end
            isWhite = not isWhite
            background.BackgroundColor3 = isWhite and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
        end
    end)

    task.spawn(function()
        local useAlternate = false
        while flashActive and image.Parent do
            task.wait(0.043)
            if not flashActive or not image.Parent then
                break
            end
            useAlternate = not useAlternate
            image.Image = useAlternate and JUMPSCARE_IMAGE_ALT_ID or JUMPSCARE_IMAGE_ID
        end
    end)

    local growTween = TweenService:Create(image, TweenInfo.new(
        0.2,
        Enum.EasingStyle.Exponential,
        Enum.EasingDirection.Out
    ), {
        Size = UDim2.fromScale(1.65, 1.65)
    })
    growTween:Play()
    growTween.Completed:Wait()
    flashActive = false

    if humanoid.Parent and humanoid.Health > 0 then
        if humanoid.Health <= JUMPSCARE_DAMAGE then
            setDeathCause(player)
        end
        humanoid:TakeDamage(JUMPSCARE_DAMAGE)
    end

    task.wait(0.12)
    if screenGui.Parent then
        screenGui:Destroy()
    end
    isJumpScaring = false
end

local function getOrderedRooms()
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    local orderedRooms = {}
    if not currentRooms then
        return orderedRooms
    end

    for _, room in ipairs(currentRooms:GetChildren()) do
        if room:IsA("Model") then
            local number = tonumber(room.Name)
            if number then
                table.insert(orderedRooms, { Number = number, Room = room })
            end
        end
    end

    table.sort(orderedRooms, function(a, b)
        return a.Number < b.Number
    end)
    return orderedRooms
end

local function getOrderedNodes(pathfindNodes)
    local orderedNodes = {}
    for _, node in ipairs(pathfindNodes:GetChildren()) do
        if node:IsA("BasePart") then
            table.insert(orderedNodes, node)
        end
    end

    table.sort(orderedNodes, function(a, b)
        local aNumber = tonumber(a.Name)
        local bNumber = tonumber(b.Name)
        if aNumber and bNumber then
            return aNumber < bNumber
        elseif aNumber then
            return true
        elseif bNumber then
            return false
        end
        return a.Name < b.Name
    end)
    return orderedNodes
end

local function moveSilenceTo(targetGetter)
    if not isActive() then
        return false
    end

    local movingSilence = silence
    silenceIsMoving = true

    while isActive() and silence == movingSilence do
        local deltaTime = RunService.Heartbeat:Wait()
        if not isActive() or silence ~= movingSilence then
            break
        end

        if not isJumpScaring then
            local targetCFrame = targetGetter()
            if not targetCFrame then
                silenceIsMoving = false
                return "refresh"
            end

            local currentCFrame = movingSilence:GetPivot()
            local distance = (targetCFrame.Position - currentCFrame.Position).Magnitude

            if distance <= 0.05 then
                if not ceaseFreezeActive then
                    movingSilence:PivotTo(targetCFrame)
                    silenceIsMoving = false
                    return true
                end
            else
                local step = SILENCE_SPEED * ceaseSpeedScale * math.min(deltaTime, 0.1)
                if step > 0 then
                    movingSilence:PivotTo(currentCFrame:Lerp(targetCFrame, math.min(step / distance, 1)))
                end
            end
        end
    end

    silenceIsMoving = false
    return false
end

local function startPlayerDetection()
    task.spawn(function()
        while isActive() do
            if scanPlayerCrucifixRaycasts() then
                return
            end
            task.wait(0.05)
        end
    end)

    task.spawn(function()
        while isActive() do
            if silenceIsMoving and not ceaseFreezeActive and not isJumpScaring then
                local ceaseModel = workspace:FindFirstChild("Cease", true)
                if ceaseModel and ceaseModel:IsA("Model")
                    and not ceaseHandledModels[ceaseModel] then
                    startCeaseFreeze(ceaseModel)
                end
            end
            task.wait(0.1)
        end
    end)

    task.spawn(function()
        local localPlayer = Players.LocalPlayer
        while isActive() and not hasJumpScared do
            RunService.Heartbeat:Wait()
            if not isActive() then
                return
            end

            local character = localPlayer and localPlayer.Character
            if character and character:IsDescendantOf(workspace)
                and not character:GetAttribute("Hiding") then
                local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                local currentSilence = silence

                if humanoid and humanoid.Health > 0
                    and currentSilence and currentSilence.Parent then
                    local entityPosition = currentSilence:GetPivot().Position
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                    raycastParams.FilterDescendantsInstances = { currentSilence }

                    local targetParts = {}
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if rootPart and rootPart:IsA("BasePart") then
                        table.insert(targetParts, rootPart)
                    end

                    for _, partName in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso" }) do
                        local targetPart = character:FindFirstChild(partName)
                        if targetPart and targetPart:IsA("BasePart") then
                            table.insert(targetParts, targetPart)
                        end
                    end

                    for _, targetPart in ipairs(targetParts) do
                        if not isActive() or currentSilence ~= silence then
                            return
                        end

                        local direction = targetPart.Position - entityPosition
                        local distance = direction.Magnitude

                        if distance > 0.001 and distance <= DETECTION_DISTANCE then
                            local result = workspace:Raycast(
                                entityPosition,
                                direction,
                                raycastParams
                            )
                            local hitCharacter = result and getCharacterFromHit(result.Instance)
                            local reachedCharacter = hitCharacter == character

                            if not reachedCharacter then
                                local entryDistance = rayEntryDistanceToPart(
                                    entityPosition,
                                    direction.Unit,
                                    targetPart
                                )

                                if entryDistance and entryDistance <= distance + 0.01
                                    and (not result or result.Distance > entryDistance + 0.02) then
                                    reachedCharacter = true
                                end
                            end

                            if reachedCharacter then
                                if tryUseCrucifix(character) then
                                    return
                                end
                                triggerSilenceJumpScare(character)
                                return
                            elseif hitCharacter and hitCharacter ~= character then
                                if tryUseCrucifix(hitCharacter) then
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function executeSilencePathfinding()
    local loadedSilence = loadModel(SILENCE_ASSET_ID, "SilenceModel")
    if not loadedSilence then
        return
    end

    local initialRooms = getOrderedRooms()
    if #initialRooms == 0 then
        loadedSilence:Destroy()
        return
    end

    local MAX_SILENCE_ROOMS = 8
    local startRoomIndex = math.max(1, #initialRooms - MAX_SILENCE_ROOMS)

    local startRoom = initialRooms[startRoomIndex].Room
    local pathfindNodes = startRoom:FindFirstChild("PathfindNodes")
    local startNode = nil
    if pathfindNodes then
        local orderedNodes = getOrderedNodes(pathfindNodes)
        startNode = orderedNodes[1]
    end
    if not startNode then
        startNode = startRoom:FindFirstChild("RoomExit")
    end
    if not startNode or not startNode:IsA("BasePart") then
        loadedSilence:Destroy()
        return
    end

    silence = loadedSilence
    prepareModel(silence, true)
    silence:PivotTo(startNode.CFrame + HEIGHT_OFFSET)
    silence.Parent = workspace
    isSilenceDespawning = false
    silenceMoveCancelled = false
    hasJumpScared = false
    startPlayerDetection()

    local startRoomNumber = initialRooms[startRoomIndex].Number
    local completedRoomNumber = -math.huge
    local completedRoomCount = 0
    local states = {}
    local missingSince = nil

    while isActive() and completedRoomCount < MAX_SILENCE_ROOMS do
        if isJumpScaring then
            task.wait(0.05)
        else
            local rooms = getOrderedRooms()
            if #rooms == 0 then
                if not missingSince then
                    missingSince = os.clock()
                elseif os.clock() - missingSince >= 2 then
                    break
                end
                task.wait(0.1)
            else
                local targetRoomNumber = rooms[math.max(1, #rooms - 1)].Number
                local currentRoom = nil

                for _, data in ipairs(rooms) do
                    if data.Number >= startRoomNumber
                        and data.Number > completedRoomNumber
                        and data.Number <= targetRoomNumber then
                        currentRoom = data
                        break
                    end
                end

                if not currentRoom then
                    local latest = getOrderedRooms()
                    local latestTarget = latest[math.max(1, #latest - 1)]
                    if latestTarget and completedRoomNumber >= latestTarget.Number then
                        break
                    end
                    if not missingSince then
                        missingSince = os.clock()
                    elseif os.clock() - missingSince >= 2 then
                        break
                    end
                    task.wait(0.1)
                else
                    missingSince = nil
                    local number = currentRoom.Number
                    local room = currentRoom.Room
                    local state = states[number]
                    if not state or state.Model ~= room then
                        state = { Model = room, Visited = {}, UsedExit = false, EmptySince = nil }
                        states[number] = state
                    end

                    local nodesFolder = room:FindFirstChild("PathfindNodes")
                    local nextNode = nil
                    if nodesFolder then
                        for _, node in ipairs(getOrderedNodes(nodesFolder)) do
                            if not state.Visited[node.Name] then
                                nextNode = node
                                break
                            end
                        end
                    end

                    if nextNode then
                        local moved = moveSilenceTo(function()
                            if not room.Parent or not nextNode:IsDescendantOf(room) then
                                return nil
                            end
                            return nextNode.CFrame + HEIGHT_OFFSET
                        end)

                        if moved == true then
                            state.Visited[nextNode.Name] = true
                        elseif moved == false then
                            break
                        else
                            task.wait(0.05)
                        end
                    else
                        local orderedNodes = nodesFolder and getOrderedNodes(nodesFolder) or {}
                        local exit = room:FindFirstChild("RoomExit")
                        if #orderedNodes == 0 and not state.UsedExit
                            and exit and exit:IsA("BasePart") then
                            local moved = moveSilenceTo(function()
                                if not room.Parent or not exit:IsDescendantOf(room) then
                                    return nil
                                end
                                return exit.CFrame + HEIGHT_OFFSET
                            end)
                            if moved == true then
                                state.UsedExit = true
                            elseif moved == false then
                                break
                            end
                        elseif #orderedNodes > 0 or state.UsedExit then
                            completedRoomNumber = number
                            completedRoomCount = completedRoomCount + 1
                        else
                            if not state.EmptySince then
                                state.EmptySince = os.clock()
                            elseif os.clock() - state.EmptySince >= 2 then
                                break
                            end
                            task.wait(0.1)
                        end
                    end
                end
            end
        end
    end

    if silence and silence.Parent and not isJumpScaring and not crucifixActivated then
        destroySilence()
    end
end

task.spawn(executeSilencePathfinding)
end

local entityConfig = {
    ["rbxassetid://1"] = entityBehaviors.ATCHRipper,
    ["rbxassetid://3"] = entityBehaviors.AMIN60,
    ["rbxassetid://4"] = entityBehaviors.Black60,
    ["rbxassetid://5"] = entityBehaviors.INGODONE,
    ["rbxassetid://6"] = entityBehaviors.Subspace,
    ["rbxassetid://7"] = entityBehaviors.DELALL,
    ["rbxassetid://8"] = entityBehaviors.ChainSmoker,
    ["rbxassetid://9"] = entityBehaviors.LightSpeed,
    ["rbxassetid://10"] = entityBehaviors.A200Jump,
    ["rbxassetid://11"] = entityBehaviors.Cease, 
    ["rbxassetid://12"] = entityBehaviors.Shok,
    ["rbxassetid://13"] = entityBehaviors.LightOSs,
    ["rbxassetid://14"] = entityBehaviors.SuperDread,
    ["rbxassetid://16"] = entityBehaviors.MultiMonster,
    ["rbxassetid://17"] = entityBehaviors.CreakHard,
    ["rbxassetid://18"] = entityBehaviors.CreakWhite,
    ["rbxassetid://19"] = entityBehaviors.Silence,
    ["rbxassetid://195"] = entityBehaviors.Silence2,
    ["rbxassetid://20"] = entityBehaviors.DeerGod,
    ["rbxassetid://21"] = entityBehaviors.FrostBite,
    ["rbxassetid://22"] = entityBehaviors.HATRED,
    ["rbxassetid://23"] = entityBehaviors.A500,
    ["rbxassetid://24"] = entityBehaviors.Angler,
    ["rbxassetid://25"] = entityBehaviors.guidingjug,
    ["rbxassetid://26"] = entityBehaviors.A333,
    ["rbxassetid://27"] = entityBehaviors.JeffTwo,
    ["rbxassetid://28"] = entityBehaviors.JEFFGUNST,
    ["rbxassetid://29"] = entityBehaviors.JEFFGUN,
    ["rbxassetid://30"] = entityBehaviors.REBOUNDSW,
    ["rbxassetid://31"] = entityBehaviors.JEFFGUN2,
    ["rbxassetid://31"] = entityBehaviors.gunjeffkq,
    ["rbxassetid://32"] = entityBehaviors.MONTNS,
    ["rbxassetid://33"] = entityBehaviors.MOSCJ,
    ["rbxassetid://34"] = entityBehaviors.A500F,
    ["rbxassetid://35"] = entityBehaviors.Smiler,
    ["rbxassetid://62"] = entityBehaviors.A4,
    ["rbxassetid://63"] = entityBehaviors.A5,
    ["rbxassetid://64"] = entityBehaviors.A6,
    ["rbxassetid://65"] = entityBehaviors.A7,
    ["rbxassetid://2"] = entityBehaviors.A200
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
hint.Text = "Loading... Doors HardCore V10.6.5 By HeavenNow :)"
game.Debris:AddItem(hint, 3)
