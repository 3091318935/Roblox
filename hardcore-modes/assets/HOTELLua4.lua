if workspace:FindFirstChild("HardcoreFour") then
    return
end
local marker = Instance.new("BoolValue")
marker.Name = "HardcoreFour"
marker.Value = true
marker.Parent = workspace
local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()
local entityBehaviors = {}

function entityBehaviors.WHATTHIS()
loadstring(game:HttpGet("https://github.com/Zero0Star/RipperNewSound/blob/master/AINEW.lua?raw=true"))()
end

function entityBehaviors.TheBoiledOne()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local latestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")

local MODEL_ID = 114369907629692
local AMBIENT_ID = 137177653817621
local RANDOM_IDS = {119223589229162, 121719103873398, 87808103166511}
local HIT_ID = 87290118952161
local EXIT_ID = 73193010308245
local SPAWN_DISTANCE = 10
local HEIGHT_OFFSET = 2
local WAIT_BEFORE_MOVING = 3
local MOVE_DISTANCE = 45
local MOVE_DURATION = 0.8
local ATTACK_RANGE = 5
local LOOK_THRESHOLD = 0.75
local ROOM_CHANGES_TO_EXIT = 5
local FACE_YAW_OFFSET = math.rad(-90)

local function LoadCustomInstance(source)
    local success, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(source))[1]
    end)

    if not success or not result then
        return nil
    end

    for _, object in ipairs(result:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") then
            object:Destroy()
        end
    end

    result.Parent = workspace
    return result
end

local entity = LoadCustomInstance(MODEL_ID)

if not entity then
    return
end

local primary
if entity:IsA("Model") then
    primary = entity:FindFirstChild("RootPart", true)
    if not (primary and primary:IsA("BasePart")) then
        primary = entity.PrimaryPart or entity:FindFirstChildWhichIsA("BasePart", true)
    end
    if primary then
        entity.PrimaryPart = primary
    end
elseif entity:IsA("BasePart") then
    primary = entity
end

if not primary then
    entity:Destroy()
    return
end

for _, object in ipairs(entity:GetDescendants()) do
    if object:IsA("BasePart") then
        object.Anchored = true
        object.CanCollide = false
    end
end

if entity:IsA("BasePart") then
    entity.Anchored = true
    entity.CanCollide = false
end

local function GetPlayerRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart") or nil
end

local function GetLivingHumanoid()
    if player:GetAttribute("Alive") == false then
        return nil
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return humanoid
    end
    return nil
end

local function FacePlayerAt(position, targetPosition)
    local lookPosition = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
    if (lookPosition - position).Magnitude > 0.01 then
        entity:PivotTo(CFrame.lookAt(position, lookPosition) * CFrame.Angles(0, FACE_YAW_OFFSET, 0))
    else
        entity:PivotTo(CFrame.new(position) * entity:GetPivot().Rotation)
    end
end

local root = GetPlayerRoot()
local startBasis = root and root.CFrame or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame) or CFrame.new()
local spawnPosition = (startBasis * CFrame.new(0, HEIGHT_OFFSET, SPAWN_DISTANCE)).Position
FacePlayerAt(spawnPosition, root and root.Position or startBasis.Position)

local savedFogStart = Lighting.FogStart
local savedFogEnd = Lighting.FogEnd
local savedFogColor = Lighting.FogColor
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local createdAtmosphere = false
local originalAtmosphere

if atmosphere then
    originalAtmosphere = {
        Density = atmosphere.Density,
        Haze = atmosphere.Haze,
        Color = atmosphere.Color,
        Decay = atmosphere.Decay,
        Glare = atmosphere.Glare,
        Offset = atmosphere.Offset
    }
else
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "ShadowEntityFog"
    atmosphere.Parent = Lighting
    createdAtmosphere = true
end

Lighting.FogStart = 0
Lighting.FogEnd = 5
Lighting.FogColor = Color3.fromRGB(55, 58, 64)
atmosphere.Density = 1
atmosphere.Haze = 10
atmosphere.Glare = 0
atmosphere.Offset = 0
atmosphere.Color = Color3.fromRGB(72, 76, 83)
atmosphere.Decay = Color3.fromRGB(25, 27, 31)

local fogBlur = Instance.new("DepthOfFieldEffect")
fogBlur.Name = "ShadowEntityDenseFog"
fogBlur.FocusDistance = 2
fogBlur.InFocusRadius = 1
fogBlur.NearIntensity = 0
fogBlur.FarIntensity = 1
fogBlur.Parent = Lighting

local fogRestored = false
local function RestoreFog()
    if fogRestored then
        return
    end

    fogRestored = true
    Lighting.FogStart = savedFogStart
    Lighting.FogEnd = savedFogEnd
    Lighting.FogColor = savedFogColor

    if fogBlur and fogBlur.Parent then
        fogBlur:Destroy()
    end

    if atmosphere then
        if createdAtmosphere then
            atmosphere:Destroy()
        elseif atmosphere.Parent and originalAtmosphere then
            for property, value in pairs(originalAtmosphere) do
                atmosphere[property] = value
            end
        end
    end
end

local active = true
local completed = false
local roomChanges = 0
local roomConnection
local heartbeatConnection
local activeSounds = {}

local function MakeSound(id, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = parent or SoundService
    activeSounds[sound] = true
    return sound
end

local function InterruptibleWait(seconds)
    local elapsed = 0
    while active and elapsed < seconds do
        elapsed = elapsed + task.wait(math.min(0.1, seconds - elapsed))
    end
    return active
end

local function WaitUntilPlaybackEnds(sound, limit, shouldStop)
    local loadingStart = os.clock()
    while sound.Parent and not sound.IsLoaded and os.clock() - loadingStart < 6 do
        if shouldStop and not active then
            return
        end
        task.wait(0.1)
    end

    local startTime = os.clock()
    local duration = sound.TimeLength > 0 and sound.TimeLength + 1 or 8
    duration = math.min(duration, limit or 20)

    while sound.Parent and sound.IsPlaying and os.clock() - startTime < duration do
        if shouldStop and not active then
            return
        end
        task.wait(0.1)
    end
end

local function StopAllSounds()
    for sound in pairs(activeSounds) do
        activeSounds[sound] = nil
        if sound.Parent then
            sound:Stop()
            sound:Destroy()
        end
    end
end

local function PlayFinalSound(id)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = SoundService
    sound:Play()
    WaitUntilPlaybackEnds(sound, 20, false)
    sound:Stop()
    sound:Destroy()
end

local function Finish(id)
    if completed then
        return
    end

    completed = true
    active = false

    if roomConnection then
        roomConnection:Disconnect()
        roomConnection = nil
    end

    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end

    StopAllSounds()
    RestoreFog()

    task.spawn(function()
        PlayFinalSound(id)
        if entity and entity.Parent then
            entity:Destroy()
        end
    end)
end

roomConnection = latestRoom.Changed:Connect(function()
    if not active then
        return
    end

    roomChanges = roomChanges + 1
    if roomChanges >= ROOM_CHANGES_TO_EXIT then
        Finish(EXIT_ID)
    end
end)

task.spawn(function()
    local ambient = MakeSound(AMBIENT_ID, SoundService)

    while active do
        ambient:Play()
        WaitUntilPlaybackEnds(ambient, 30, true)
        if not active then
            break
        end
        ambient:Stop()
        if not InterruptibleWait(1) then
            break
        end
    end

    activeSounds[ambient] = nil
    if ambient.Parent then
        ambient:Destroy()
    end
end)

task.spawn(function()
    local previousIndex

    while active do
        local index = math.random(1, #RANDOM_IDS)
        if index == previousIndex and #RANDOM_IDS > 1 then
            index = (index % #RANDOM_IDS) + 1
        end
        previousIndex = index

        local sound = MakeSound(RANDOM_IDS[index], SoundService)
        sound:Play()
        WaitUntilPlaybackEnds(sound, 30, true)
        activeSounds[sound] = nil
        if sound.Parent then
            sound:Stop()
            sound:Destroy()
        end

        if not InterruptibleWait(5) then
            break
        end
    end
end)

local function IsLookingAtEntity()
    local camera = workspace.CurrentCamera
    if not camera or not primary.Parent then
        return false
    end

    local from = camera.CFrame.Position
    local toEntity = primary.Position - from

    if toEntity.Magnitude <= 0.01 then
        return true
    end

    if camera.CFrame.LookVector:Dot(toEntity.Unit) < LOOK_THRESHOLD then
        return false
    end

    local _, visible = camera:WorldToViewportPoint(primary.Position)
    if not visible then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local character = player.Character
    params.FilterDescendantsInstances = character and {character} or {}

    local result = workspace:Raycast(from, toEntity, params)
    return not result or result.Instance:IsDescendantOf(entity)
end

local function CanHitPlayer()
    local character = player.Character
    local targetRoot = GetPlayerRoot()
    local humanoid = GetLivingHumanoid()
    if not character or not targetRoot or not humanoid then
        return nil
    end

    local origin = primary.Position
    local difference = targetRoot.Position - origin
    local distance = difference.Magnitude

    if distance > ATTACK_RANGE or distance < 0.01 then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {entity}
    params.IgnoreWater = true

    local hit = workspace:Raycast(origin, difference.Unit * ATTACK_RANGE, params)
    if hit and hit.Instance:IsDescendantOf(character) then
        return humanoid
    end
    return nil
end

local unnoticedTime = 0
local movement

heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
    if not active or not entity.Parent or not primary.Parent then
        return
    end

    local humanoid = GetLivingHumanoid()
    local targetRoot = GetPlayerRoot()

    if not humanoid or not targetRoot then
        unnoticedTime = 0
        movement = nil
        return
    end

    if IsLookingAtEntity() then
        unnoticedTime = 0
        movement = nil
    else
        if movement then
            movement.elapsed = movement.elapsed + dt
            local alpha = math.clamp(movement.elapsed / MOVE_DURATION, 0, 1)
            local eased = alpha * alpha * (3 - 2 * alpha)
            local position = movement.start:Lerp(movement.goal, eased)
            FacePlayerAt(position, targetRoot.Position)

            if alpha >= 1 then
                movement = nil
                unnoticedTime = 0
            end
        else
            unnoticedTime = unnoticedTime + dt
            if unnoticedTime >= WAIT_BEFORE_MOVING then
                unnoticedTime = 0
                local current = entity:GetPivot().Position
                local target = Vector3.new(targetRoot.Position.X, targetRoot.Position.Y + HEIGHT_OFFSET, targetRoot.Position.Z)
                local flatOffset = Vector3.new(target.X - current.X, 0, target.Z - current.Z)
                local travel = math.min(MOVE_DISTANCE, math.max(flatOffset.Magnitude - 1.5, 0))

                if travel > 0.01 then
                    local goal = current + flatOffset.Unit * travel
                    goal = Vector3.new(goal.X, target.Y, goal.Z)
                    movement = {start = current, goal = goal, elapsed = 0}
                    FacePlayerAt(current, targetRoot.Position)
                end
            end
        end
    end

    local hitHumanoid = CanHitPlayer()
    if hitHumanoid then
        hitHumanoid:TakeDamage(100)
        if hitHumanoid.Health <= 0 then
            player:SetAttribute("Alive", false)
        end
        Finish(HIT_ID)
    end
end)
end
function entityBehaviors.Baldi()
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

while not player do
	task.wait()
	player = Players.LocalPlayer
end

local LatestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")

local function GetLargestRoom()
	local rooms = workspace:FindFirstChild("CurrentRooms")
	if not rooms then return nil end

	local largest
	local max = -1

	for _, room in pairs(rooms:GetChildren()) do
		local id = tonumber(room.Name)
		if id and id > max then
			max = id
			largest = room
		end
	end

	return largest
end

local function GetDoorCFrame(room)
	local door = room and room:FindFirstChild("Door") and room.Door:FindFirstChild("Door")
	if door and door:IsA("BasePart") then
		return door.CFrame
	end
end

local function LoadBaldi()
	local success, model = pcall(function()
		return game:GetObjects("rbxassetid://84406407528761")[1]
	end)

	if not success or not model then
		return nil
	end

	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") then
			v:Destroy()
		end
	end

	return model
end

local room = GetLargestRoom()
if not room then return end

local cf = GetDoorCFrame(room)
if not cf then return end

local baldi = LoadBaldi()
if not baldi then return end

baldi:PivotTo(cf)
baldi.Parent = workspace

local destroyed = false
local canStart = false
local triggered = false

local protectDelete = false
local megaSound = nil
local stopMathGame = nil

local function DestroyBaldi()
	if destroyed then return end
	destroyed = true

	if megaSound then
		megaSound:Stop()
		megaSound = nil
	end

	if stopMathGame then
		stopMathGame()
	end

	if baldi and baldi.Parent then
		baldi:Destroy()
	end
end

local roomChanges = 0

LatestRoom.Changed:Connect(function()
	roomChanges += 1

	if roomChanges == 1 then
		local s1 = Instance.new("Sound")
		s1.SoundId = "rbxassetid://17556446241"
		s1.Volume = 1
		s1.Parent = workspace
		s1:Play()

		s1.Ended:Connect(function()
			s1:Destroy()

			local s2 = Instance.new("Sound")
			s2.SoundId = "rbxassetid://100704961414689"
			s2.Volume = 1
			s2.Parent = workspace
			s2:Play()

			s2.Ended:Connect(function()
				s2:Destroy()
				canStart = true
			end)
		end)
	end

	if roomChanges >= 3 then
		if not protectDelete then
			DestroyBaldi()
		end
	end
end)

local function StartMathGame()
	local Main_Game = require(player.PlayerGui.MainUI.Initiator.Main_Game)

	math.randomseed(tick())

	local questionIndex = 1
	local answer = nil
	local currentQuestion = ""

	local active = false
	local gameFinished = false
	local wrongCount = 0

	local chatConnection

	stopMathGame = function()
		gameFinished = true
		active = false
		answer = nil
		currentQuestion = ""

		if chatConnection then
			chatConnection:Disconnect()
			chatConnection = nil
		end
	end

	local function createQuestion(level)

		local a,b,c,x,result

		if level == 1 then

			a = math.random(1,5)
			b = math.random(1,10)
			x = math.random(1,10)

			answer = a*x+b

			return "Given f(x)="..a.."x+"..b..", find f("..x..")"

		elseif level == 2 then

			a = math.random(2,8)
			b = math.random(1,10)
			x = math.random(1,10)

			result = a*x+b
			answer = x

			return "Given f(x)="..a.."x+"..b..", if f(x)="..result..", find x"

		elseif level == 3 then

			a = math.random(2,8)
			b = math.random(-10,10)
			x = math.random(1,10)

			local textB

			if b >= 0 then
				textB = "+"..b
			else
				textB = b
			end

			answer = a*x+b

			return "Given f(x)="..a.."x"..textB..", find f("..x..")"

		elseif level == 4 then

			a = math.random(1,5)
			b = math.random(-5,5)
			c = math.random(-10,10)
			x = math.random(1,8)

			answer = a*x*x+b*x+c

			return "Given f(x)="..a.."x²+"..b.."x+"..c..", find f("..x..")"

		elseif level == 5 then

			a = math.random(1,5)
			b = math.random(-5,5)
			c = math.random(-10,10)
			x = math.random(1,8)

			result = a*x*x+b*x+c
			answer = x

			return "Given f(x)="..a.."x²+"..b.."x+"..c..", if f(x)="..result..", find x"

		end

	end

	local function repeatQuestion()

		task.spawn(function()

			while active and not gameFinished do

				Main_Game.caption(
					"Question "..questionIndex..": "..currentQuestion,
					true
				)

				task.wait(5)

			end

		end)

	end

	local function nextQuestion()

		if questionIndex > 5 then

			gameFinished = true
			active = false
			answer = nil
			currentQuestion = ""

			Main_Game.caption(
				"Game Finished!",
				true
			)

			if chatConnection then
				chatConnection:Disconnect()
				chatConnection = nil
			end

			DestroyBaldi()

			return

		end

		currentQuestion = createQuestion(questionIndex)

		active = true

		Main_Game.caption(
			"Question "..questionIndex..": "..currentQuestion,
			true
		)

		repeatQuestion()

	end

	chatConnection = player.Chatted:Connect(function(message)

		if gameFinished then
			return
		end

		local num = tonumber(message)

		if not num then
			return
		end

		if num == answer then

			active = false

			Main_Game.caption(
				"Correct!",
				true
			)

			task.wait(1)

			questionIndex += 1

			nextQuestion()

		else

			wrongCount += 1

			Main_Game.caption(
				"Wrong!",
				true
			)

			if wrongCount >= 2 then

				gameFinished = true
				active = false
				answer = nil
				currentQuestion = ""

				Main_Game.caption(
					"Game Failed!",
					true
				)

				if chatConnection then
					chatConnection:Disconnect()
					chatConnection = nil
				end

				if megaSound then
					megaSound:Stop()
				end

				protectDelete = true

			end

		end

	end)

	nextQuestion()

end

RunService.Heartbeat:Connect(function()

	if destroyed or triggered or not canStart then
		return
	end

	if not baldi.Parent then
		return
	end


	local target =
		baldi.PrimaryPart
		or baldi:FindFirstChildWhichIsA("BasePart")


	if not target then
		return
	end


	for _,plr in ipairs(Players:GetPlayers()) do


		local character = plr.Character

		local humanoid =
			character and character:FindFirstChildOfClass("Humanoid")


		local root =
			character and character:FindFirstChild("HumanoidRootPart")
		if humanoid
		and humanoid.Health > 0
		and root then


			local distance =
				(root.Position - target.Position).Magnitude


			if distance <= 15 then


				triggered = true
				megaSound =
					baldi:FindFirstChild(
						"Baldi Mega Mix",
						true
					)


				if megaSound then
					megaSound:Play()
				end

				StartMathGame()


				break

			end

		end

	end

end)
end

function entityBehaviors.Baldi2()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local LatestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")

local function StopMathGameAndMusic()

	for _,v in ipairs(workspace:GetDescendants()) do
		if v:IsA("Sound") then
			v:Stop()
		end
	end

	local gui = player:FindFirstChild("PlayerGui")
	if gui then
		local mainUI = gui:FindFirstChild("MainUI")
		if mainUI then
			local caption = mainUI:FindFirstChild("Caption", true)
			if caption and caption:IsA("TextLabel") then
				caption.Text = ""
			end
		end
	end

	pcall(function()
		for _,connection in ipairs(getconnections(player.Chatted)) do
			connection:Disable()
		end
	end)
end

StopMathGameAndMusic()

local baldi

for _,v in ipairs(workspace:GetDescendants()) do
	if v:IsA("Model") and v.Name == "Baldi" then
		baldi = v
		break
	end
end

if not baldi then
	return
end

local destroyed = false
local damageDone = false
local targetPlayer

local function DestroyBaldi()
	if destroyed then return end
	destroyed = true

	if baldi and baldi.Parent then
		baldi:Destroy()
	end
end

local baldiPart = baldi:FindFirstChild("baldi", true)
if not baldiPart then
	return
end

local attachment1 = baldiPart:FindFirstChild("Attachment1")
local attachment2 = baldiPart:FindFirstChild("Attachment2")

local baldi2Particle

if attachment1 then
	local old = attachment1:FindFirstChild("baldi")
	if old and old:IsA("ParticleEmitter") then
		old:Destroy()
	end
end

if attachment2 then
	baldi2Particle = attachment2:FindFirstChild("baldi2")
	if baldi2Particle and baldi2Particle:IsA("ParticleEmitter") then
		baldi2Particle.Enabled = true
	end
end

task.wait(5)

local root = baldi.PrimaryPart or baldi:FindFirstChildWhichIsA("BasePart")
if not root then return end

local nearest = math.huge

for _,plr in ipairs(Players:GetPlayers()) do
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if hrp then
		local d = (root.Position - hrp.Position).Magnitude
		if d < nearest then
			nearest = d
			targetPlayer = plr
		end
	end
end

if not targetPlayer then return end

local function PlayMoveSound()

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://1841427728"
	sound.Volume = 1
	sound.Parent = baldi
	sound:Play()

	if baldi2Particle then
		baldi2Particle.Texture = "rbxassetid://15951405914"

		task.delay(0.15,function()
			if baldi2Particle then
				baldi2Particle.Texture = "rbxassetid://15953172586"
			end
		end)
	end

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function Damage()

	if damageDone then return end
	damageDone = true

	local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:TakeDamage(100)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://98207961689599"
		sound.Parent = workspace
		sound:Play()

		sound.Ended:Connect(function()
			sound:Destroy()
			DestroyBaldi()
		end)
	end
end

local function RayCheck()

	if damageDone then return end

	local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	local root = baldi.PrimaryPart or baldi:FindFirstChildWhichIsA("BasePart")

	if not hrp or not root then return end

	local direction = hrp.Position - root.Position

	if direction.Magnitude <= 15 then
		Damage()
	end
end

local function WatchDeath(character)

	local hum = character:WaitForChild("Humanoid")

	hum.Died:Connect(function()
		DestroyBaldi()
	end)
end

if targetPlayer.Character then
	WatchDeath(targetPlayer.Character)
end

targetPlayer.CharacterAdded:Connect(function(character)
	if not destroyed then
		WatchDeath(character)
	end
end)

task.spawn(function()

	while not destroyed do

		task.wait(3)

		local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		local root = baldi.PrimaryPart or baldi:FindFirstChildWhichIsA("BasePart")

		if hrp and root then

			local direction = Vector3.new(
				hrp.Position.X-root.Position.X,
				0,
				hrp.Position.Z-root.Position.Z
			)

			if direction.Magnitude > 0 then

				local pos = root.Position + direction.Unit * 20

				baldi:PivotTo(
					CFrame.new(pos.X,pos.Y-2,pos.Z)
				)

				PlayMoveSound()

			end
		end
	end
end)

local connection
connection = RunService.Heartbeat:Connect(function()

	if destroyed then
		connection:Disconnect()
		return
	end

	RayCheck()
end)

local roomCount = 0

LatestRoom.Changed:Connect(function()

	roomCount += 1

	if roomCount >= 20 then

		if connection then
			connection:Disconnect()
		end

		DestroyBaldi()

	end
end)

end


function entityBehaviors.SA90()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainUI = PlayerGui:WaitForChild("MainUI")
local Jumpscare = MainUI:WaitForChild("Jumpscare")
local A90Gui = Jumpscare:WaitForChild("Jumpscare_A90")
local MainGameFolder = MainUI.Initiator.Main_Game
local A90Module = MainGameFolder.RemoteListener.Modules.A90
local MainGame = require(MainGameFolder)
local CameraShaker = require(ReplicatedStorage:WaitForChild("CameraShaker"))
local RNG = Random.new()
if A90Gui:GetAttribute("CustomA90Running") then
	return
end
A90Gui:SetAttribute("CustomA90Running", true)
local Running = true
local StaticRunning = false
local Cleaned = false
local Moved = false
local Intensity = 0
local StartLookVector = MainGame.cam.CFrame.LookVector
local CameraShake = CameraShaker.new(
	Enum.RenderPriority.Camera.Value,
	function(shakeCFrame)
		if Camera then
			Camera.CFrame = Camera.CFrame * shakeCFrame
		end
	end
)
CameraShake:Start()
local function setDeathCause(cause)
	local gameStats = ReplicatedStorage:FindFirstChild("GameStats")

	if not gameStats then
		return
	end

	local playerStats = gameStats:FindFirstChild("Player_" .. Player.Name)

	if not playerStats then
		return
	end

	local total = playerStats:FindFirstChild("Total")

	if not total then
		return
	end

	local deathCause = total:FindFirstChild("DeathCause")

	if deathCause then
		deathCause.Value = cause
	end
end

local function cleanup()
	if Cleaned then
		return
	end

	Cleaned = true
	Running = false
	StaticRunning = false

	pcall(function()
		A90Module.Spawn:Stop()
	end)

	pcall(function()
		CameraShake:Stop()
	end)

	A90Gui:SetAttribute("CustomA90Running", false)
end

SoundService.Main.Volume = 0

A90Gui.Face.Image = "http://www.roblox.com/asset/?id=12635832722"
A90Gui.FaceAngry.Image = "http://www.roblox.com/asset/?id=12635955412"

pcall(function()
	A90Module.Spawn.SoundGroup = nil
	A90Module.Hit.SoundGroup = nil
end)

A90Module.Spawn:Play()

A90Gui.BackgroundTransparency = 1
A90Gui.Face.Visible = true
A90Gui.FaceAngry.Visible = false
A90Gui.Static.Visible = true
A90Gui.Static2.Visible = true
A90Gui.Static.ImageTransparency = 1
A90Gui.Static2.ImageTransparency = 1
A90Gui.Face.ImageColor3 = Color3.new(0, 0, 0)
A90Gui.Face.Rotation = RNG:NextNumber(-5, 5)

A90Gui.Face.Position = UDim2.new(
	RNG:NextNumber(10, 90) / 100,
	0,
	RNG:NextNumber(10, 90) / 100,
	0
)

A90Gui.Visible = true

task.wait(0.03)

A90Gui.Face.ImageColor3 = Color3.new(1, 1, 1)

task.wait(0.28)

A90Gui.BackgroundTransparency = 0
A90Gui.Face.Rotation = 0
A90Gui.Face.Position = UDim2.new(0.5, 0, 0.49, 0)

task.wait(0.03)

A90Gui.StopIcon.Visible = true
A90Gui.BackgroundColor3 = Color3.new(0, 0, 0)
A90Gui.BackgroundTransparency = 1
A90Gui.Static.ImageTransparency = 0.8
A90Gui.Static2.ImageTransparency = 0.8

task.delay(0.2, function()
	A90Gui.StopIcon.Visible = false

	while Running do
		task.wait(0.03)

		if not Running then
			break
		end

		Intensity += 15

		local effectIntensity = 100 + Intensity * 0.5
		local randomColor = math.random(0, 1)

		A90Gui.Static.Position = UDim2.new(
			math.random(0, 100) / 100,
			0,
			math.random(0, 100) / 100,
			0
		)

		A90Gui.Static.Rotation = math.random(0, 1) * 180

		A90Gui.Static2.Position = UDim2.new(
			math.random(0, 100) / 100,
			0,
			math.random(0, 100) / 100,
			0
		)

		A90Gui.Static2.Rotation = math.random(0, 1) * 180

		A90Gui.Face.Position = UDim2.new(
			0.5,
			0,
			0.49,
			math.random(-1, 1)
		)

		A90Gui.FaceAngry.Position = UDim2.new(
			0.5 + RNG:NextNumber(-effectIntensity, effectIntensity) / 50000,
			0,
			0.49 + RNG:NextNumber(-effectIntensity, effectIntensity) / 30000,
			math.random(-1, 1)
		)

		A90Gui.FaceAngry.Rotation =
			RNG:NextNumber(-1, 1) * (Intensity * 0.0015)

		A90Gui.FaceAngry.ImageColor3 =
			Color3.new(1, randomColor, randomColor)

		if not Moved then
			local currentCamera = MainGame.cam
			local humanoid = MainGame.hum

			if currentCamera and humanoid then
				local currentLookVector = currentCamera.CFrame.LookVector

				local cameraMoved =
					(StartLookVector - currentLookVector).Magnitude > 0.4

				local playerMoved =
					humanoid.MoveDirection.Magnitude > 0.4

				if cameraMoved or playerMoved then
					Moved = true
				end
			end
		end
	end
end)

task.wait(0.3)

A90Gui.BackgroundColor3 = Color3.new(0, 0, 0)
A90Gui.BackgroundTransparency = 0
A90Gui.Static.ImageTransparency = 0
A90Gui.Static2.ImageTransparency = 0.5

task.wait(0.03)

A90Gui.Face.ImageColor3 = Color3.new(1, 0, 0)

task.wait(0.03)

A90Gui.Visible = false

task.wait(0.08)

if Moved then
	A90Gui.Visible = true
	A90Module.Hit:Play()

	task.wait(0.03)

	A90Gui.Face.ImageColor3 = Color3.new(1, 1, 1)

	task.wait(0.03)

	A90Gui.BackgroundTransparency = 0
	A90Gui.Static.ImageTransparency = 0
	A90Gui.Static2.ImageTransparency = 0.5

	task.wait(0.067)

	A90Gui.FaceAngry.Size = UDim2.new(0.8, 0, 0.8, 0)
	A90Gui.FaceAngry.Rotation = 0
	A90Gui.FaceAngry.ImageTransparency = 0
	A90Gui.FaceAngry.ImageColor3 = Color3.new(1, 0, 0)
	A90Gui.FaceAngry.Visible = true

	task.wait(0.067)

	A90Gui.FaceAngry.ImageColor3 = Color3.new(1, 1, 1)
	A90Gui.Face.Visible = false

	task.wait(0.75)

	Running = false

	task.wait()

	local Character = Player.Character
	local Humanoid =
		Character
		and Character:FindFirstChildOfClass("Humanoid")

	if Humanoid and Humanoid.Health > 0 then
		local Damage = 70
		local WillDie = Humanoid.Health <= Damage

		if WillDie then
			setDeathCause("A-90")
		end

		Humanoid:TakeDamage(Damage)
	end

	task.wait(0.1)

	A90Gui.FaceAngry.Visible = false
	A90Gui.BackgroundColor3 = Color3.new(1, 1, 1)
	A90Gui.Static.ImageTransparency = 1
	A90Gui.Static2.ImageTransparency = 1

	task.wait(0.067)

	A90Gui.BackgroundColor3 = Color3.new(1, 0, 0)

	task.wait(0.067)

	A90Gui.BackgroundColor3 = Color3.new(0, 0, 0)

	task.wait(0.067)

	CameraShake:ShakeOnce(25, 8, 0, 4)

	task.wait(0.03)

	A90Module.Spawn:Stop()

	A90Gui.BackgroundTransparency = 1
	A90Gui.Static.ImageTransparency = 0.5
	A90Gui.Static2.ImageTransparency = 0.5

	TweenService:Create(
		A90Gui.Static,
		TweenInfo.new(
			20,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			ImageTransparency = 1
		}
	):Play()

	TweenService:Create(
		A90Gui.Static2,
		TweenInfo.new(
			5,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			ImageTransparency = 1
		}
	):Play()

	local FaceSize = RNG:NextNumber(2, 3)

	A90Gui.FaceAngry.Rotation = RNG:NextNumber(-3, 3)
	A90Gui.FaceAngry.Visible = true
	A90Gui.FaceAngry.ImageColor3 = Color3.new(1, 0, 0)
	A90Gui.FaceAngry.Size = UDim2.new(FaceSize, 0, FaceSize, 0)

	TweenService:Create(
		A90Gui.FaceAngry,
		TweenInfo.new(
			5,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			ImageTransparency = 1
		}
	):Play()

	SoundService.Main.Volume = 0

	local Equalizer =
		SoundService.Main:FindFirstChild("EqualizerSoundEffect")

	if Equalizer then
		Equalizer.Enabled = true
		Equalizer.HighGain = -50
		Equalizer.LowGain = 10
		Equalizer.MidGain = -50

		TweenService:Create(
			Equalizer,
			TweenInfo.new(
				15,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.InOut
			),
			{
				LowGain = 0,
				HighGain = 0,
				MidGain = 0
			}
		):Play()
	end

	TweenService:Create(
		SoundService.Main,
		TweenInfo.new(
			5,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		{
			Volume = 1
		}
	):Play()

	StaticRunning = true

	task.spawn(function()
		while StaticRunning do
			task.wait()

			if not StaticRunning then
				break
			end

			local MaxPosition = 100.1

			A90Gui.Static.Position = UDim2.new(
				RNG:NextNumber(0, MaxPosition) / 100,
				0,
				RNG:NextNumber(0, MaxPosition) / 100,
				0
			)

			A90Gui.Static.Rotation = math.random(0, 1) * 180

			A90Gui.Static2.Position = UDim2.new(
				RNG:NextNumber(0, MaxPosition) / 100,
				0,
				RNG:NextNumber(0, MaxPosition) / 100,
				0
			)

			A90Gui.Static2.Rotation = math.random(0, 1) * 180
		end
	end)

	task.wait(20)

	StaticRunning = false
	A90Gui.Visible = false
	A90Gui.BackgroundTransparency = 0
	A90Gui.Static.ImageTransparency = 1
	A90Gui.Static2.ImageTransparency = 1

	cleanup()
else
	Running = false
	A90Module.Spawn:Stop()
	A90Gui.BackgroundTransparency = 1
	A90Gui.Visible = false
	CameraShake:ShakeOnce(5, 10, 0.1, 1)
	SoundService.Main.Volume = 1
	task.wait(1.2)
	cleanup()
end
end

function entityBehaviors.WH1T3()
local entity = spawner.Create({Entity = {Name = "WH1T3",
Asset = "91653443213214",HeightOffset = 5},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = false,Range = 200,Values = {1.5, 20, 0.1, 1}},
Movement = {Speed = 800,Delay = 5,Reversed = false},Rebounding = {Enabled = true,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 100,Amount = 125},Crucifixion = {
Enabled = true,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于WH1T3", "听取周围的声音", "观察它的规律", "反复进柜子躲避它"},Cause = "WH1T3"}})
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

function entityBehaviors.TUMA()
local function Damage(Amount)
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local DamageAmount = (Amount / 100) * Humanoid.MaxHealth
    local NewHealth = Humanoid.Health - DamageAmount
    if NewHealth <= 0 then
        Player:SetAttribute("Alive", false)
        replicatesignal(Player.Kill)
    else
        Humanoid.Health = NewHealth
    end
end

local function LoadCustomInstance(source)
    local model
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    return model
end

local function MainExecution()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
    end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end
    local chasingEntity = LoadCustomInstance(86163085571492)
    if not chasingEntity then
        return
    end
    task.spawn(function()
        wait(30)
        if chasingEntity and chasingEntity.Parent then
            chasingEntity:Destroy()
        end
    end)
    local entityPart
    if chasingEntity:IsA("Model") then
        if chasingEntity.PrimaryPart then
            entityPart = chasingEntity.PrimaryPart
        else
            entityPart = chasingEntity:FindFirstChildWhichIsA("BasePart")
        end
    else
        entityPart = chasingEntity:FindFirstChildWhichIsA("BasePart")
    end
    if not entityPart then
        chasingEntity:Destroy()
        return
    end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    entityPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, 40)
    local function ColorEnvironment()
        local player = game.Players.LocalPlayer
        local character = player.Character
        local function IsMonsterPart(part)
            if part:IsA("Model") and (part:GetAttribute("Monster") or part.Name:find("Monster") or part.Name:find("Entity")) then
                return true
            end
            local ancestor = part.Parent
            while ancestor do
                if ancestor:IsA("Model") and (ancestor:GetAttribute("Monster") or ancestor.Name:find("Monster") or ancestor.Name:find("Entity")) then
                    return true
                end
                ancestor = ancestor.Parent
            end
            return false
        end
        for transparency = 0, 0.8, 0.1 do
            for _, part in pairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    local isPlayerPart = character and (part:IsDescendantOf(character) or part.Name == "HumanoidRootPart")
                    local isMonster = IsMonsterPart(part)
                    local isSpawnLocation = part:IsA("SpawnLocation") or (part.Parent and part.Parent:IsA("SpawnLocation"))
                    local isChasingEntity = part:IsDescendantOf(chasingEntity)
                    if not isPlayerPart and not isMonster and not isChasingEntity and not part:IsA("Terrain") and not isSpawnLocation then
                        task.spawn(function()
                            local originalColor = part.Color
                            local originalMaterial = part.Material
                            for i = 0, 1, 0.1 do
                                if part and part.Parent then
                                    part.Color = originalColor:Lerp(Color3.fromRGB(255, 105, 180), i)
                                    part.Material = Enum.Material.Neon
                                    part.Transparency = transparency
                                    wait(0.05)
                                end
                            end
                        end)
                    end
                end
            end
            wait(0.5)
        end
    end
    local function TriggerSimpleJumpscare()
        local jumpscareGui = Instance.new("ScreenGui")
        jumpscareGui.Name = "SimpleJumpscare"
        jumpscareGui.Parent = player:WaitForChild("PlayerGui")
        jumpscareGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local jumpscareImage = Instance.new("ImageLabel")
        jumpscareImage.Name = "JumpscareImage"
        jumpscareImage.Parent = jumpscareGui
        jumpscareImage.BackgroundTransparency = 1
        jumpscareImage.Position = UDim2.new(0.5, 0, 0.5, 0)
        jumpscareImage.AnchorPoint = Vector2.new(0.5, 0.5)
        jumpscareImage.Size = UDim2.new(0.01, 0, 0.01, 0)
        jumpscareImage.Image = "rbxassetid://2142657118"
        jumpscareImage.ImageColor3 = Color3.fromRGB(203, 73, 208)
        jumpscareImage.ImageTransparency = 1
        local killSound = Instance.new("Sound")
        killSound.SoundId = "rbxassetid://139300381946118"
        killSound.Volume = 3
        killSound.Parent = workspace
        local tweenService = game:GetService("TweenService")
        local function ExecuteJumpscareSequence()
            tweenService:Create(jumpscareImage, TweenInfo.new(0.5), {
                ImageTransparency = 0
            }):Play()
            tweenService:Create(jumpscareImage, TweenInfo.new(0.5), {
                Size = UDim2.new(0.8, 0, 0.8, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }):Play()
            killSound:Play()
            spawn(function()
                wait(0.3)
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    if hum then
                        hum:TakeDamage(100)
                        if game.ReplicatedStorage.GameStats["Player_" .. player.Name] then
                            game.ReplicatedStorage.GameStats["Player_" .. player.Name].Total.DeathCause.Value = "Threat"
                        end
                        firesignal(game.ReplicatedStorage.RemotesFolder.DeathHint.OnClientEvent, {
                            "你死于Threat...",
                            "威胁如影随形...",
                            "在它看见你之前躲起来..."
                        }, "Blue")
                    end
                end
            end)
            wait(0.5)
            tweenService:Create(jumpscareImage, TweenInfo.new(1), {
                ImageTransparency = 1
            }):Play()
            wait(1)
            killSound:Destroy()
            jumpscareGui:Destroy()
        end
        ExecuteJumpscareSequence()
    end
    local function StartRaycastDamage()
        while true do
            local char = player.Character
            if char then
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    local rayOrigin = Vector3.new(
                        math.random(-50, 50),
                        math.random(5, 20),
                        math.random(-50, 50)
                    )
                    local rayDirection = (char.HumanoidRootPart.Position - rayOrigin).Unit * 10
                    local raycastResult = workspace:Raycast(rayOrigin, rayDirection)
                    if raycastResult and raycastResult.Instance:IsDescendantOf(char) then
                        Damage(100)
                        TriggerSimpleJumpscare()
                        if chasingEntity and chasingEntity.Parent then
                            chasingEntity:Destroy()
                        end
                        break
                    end
                end
            end
            wait(0.5)
        end
    end
    local function SetupCollisionDetection()
        if entityPart then
            entityPart.Touched:Connect(function(hit)
                local hitCharacter = hit:FindFirstAncestorWhichIsA("Model")
                if hitCharacter and hitCharacter == character then
                    if not character:GetAttribute("Hiding") then
                        Damage(100)
                        TriggerSimpleJumpscare()
                        if chasingEntity and chasingEntity.Parent then
                            chasingEntity:Destroy()
                        end
                    end
                end
            end)
        end
    end
    local function StartChasing()
        local RunService = game:GetService("RunService")
        local chasingSpeed = 11
        local isChasing = true
        local detectionInterval = 0.5
        local lastDetectionTime = 0
        local chaseConnection
        chaseConnection = RunService.RenderStepped:Connect(function(deltaTime)
            if not isChasing or not chasingEntity or not chasingEntity.Parent then
                if chaseConnection then
                    chaseConnection:Disconnect()
                end
                return
            end
            local currentCharacter = player.Character
            if not currentCharacter then
                if chasingEntity and chasingEntity.Parent then
                    chasingEntity:Destroy()
                end
                isChasing = false
                if chaseConnection then
                    chaseConnection:Disconnect()
                end
                return
            end
            local currentHumanoid = currentCharacter:FindFirstChildWhichIsA("Humanoid")
            if not currentHumanoid or currentHumanoid.Health <= 0 then
                if chasingEntity and chasingEntity.Parent then
                    chasingEntity:Destroy()
                end
                isChasing = false
                if chaseConnection then
                    chaseConnection:Disconnect()
                end
                return
            end
            local target = currentCharacter.HumanoidRootPart
            if not target then
                return
            end
            local direction = (target.Position - entityPart.Position).Unit
            local moveVector = direction * chasingSpeed * deltaTime
            entityPart.Position = entityPart.Position + moveVector
            entityPart.CFrame = CFrame.lookAt(entityPart.Position, target.Position)
            local currentTime = tick()
            if currentTime - lastDetectionTime >= detectionInterval then
                lastDetectionTime = currentTime
                local rayOrigin = entityPart.Position
                local rayDirection = (target.Position - rayOrigin).Unit * 10
                local ray = Ray.new(rayOrigin, rayDirection)
                local hit = workspace:FindPartOnRay(ray, chasingEntity)
                if hit and hit:IsDescendantOf(currentCharacter) and not currentCharacter:GetAttribute("Hiding") then
                    isChasing = false
                    Damage(100)
                    TriggerSimpleJumpscare()
                    if chasingEntity and chasingEntity.Parent then
                        chasingEntity:Destroy()
                    end
                    if chaseConnection then
                        chaseConnection:Disconnect()
                    end
                end
            end
            local distance = (entityPart.Position - target.Position).Magnitude
            if distance < 2 then
                isChasing = false
                Damage(100)
                TriggerSimpleJumpscare()
                if chasingEntity and chasingEntity.Parent then
                    chasingEntity:Destroy()
                end
                if chaseConnection then
                    chaseConnection:Disconnect()
                end
            end
        end)
        return chaseConnection
    end
    local function Cleanup()
        if chasingEntity and chasingEntity.Parent then
            chasingEntity:Destroy()
        end
    end
    game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            Cleanup()
        end
    end)
    humanoid.Died:Connect(function()
        Cleanup()
    end)
    SetupCollisionDetection()
    StartChasing()
    task.spawn(StartRaycastDamage)
    task.spawn(function()
        ColorEnvironment()
    end)
end
MainExecution()
end
function entityBehaviors.OSAB()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local function isPlayerLookingAtEntity(entity)
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return false end

    local head = character:FindFirstChild("Head")
    if not head then return false end

    local entityPosition
    if entity:IsA("Model") then
        local primary = entity.PrimaryPart or entity:FindFirstChildWhichIsA("BasePart")
        if not primary then return false end
        entityPosition = primary.Position
    else
        entityPosition = entity.Position
    end

    local cameraDirection = Camera.CFrame.LookVector
    local toEntity = (entityPosition - head.Position).Unit

    local dot = cameraDirection:Dot(toEntity)
    return dot > 0.7
end

local damageConnection

local function setParticleTransparency(model, value)
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            obj.Transparency = NumberSequence.new(value)
        end
    end
end

local function fadeParticles(model, fromValue, toValue, duration)
    local emitters = {}

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            table.insert(emitters, obj)
            obj.Transparency = NumberSequence.new(fromValue)
        end
    end

    local startTime = tick()

    while tick() - startTime < duration do
        local alpha = (tick() - startTime) / duration
        local value = fromValue + (toValue - fromValue) * alpha

        for _, emitter in ipairs(emitters) do
            emitter.Transparency = NumberSequence.new(value)
        end

        RunService.Heartbeat:Wait()
    end

    for _, emitter in ipairs(emitters) do
        emitter.Transparency = NumberSequence.new(toValue)
    end
end

local function startDamageLoop(entity)
    if damageConnection then
        damageConnection:Disconnect()
    end

    local lastDamageTime = 0

    damageConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not entity or not entity.Parent then
            damageConnection:Disconnect()
            return
        end

        if not isPlayerLookingAtEntity(entity) then
            lastDamageTime = lastDamageTime + deltaTime

            if lastDamageTime >= 0.5 then
                lastDamageTime = 0

                local Player = Players.LocalPlayer
                local Character = Player.Character or Player.CharacterAdded:Wait()
                local Humanoid = Character:WaitForChild("Humanoid")

                local NewHealth = Humanoid.Health - 10
                Humanoid.Health = NewHealth

                if NewHealth <= 0 then
                    Player:SetAttribute("Alive", false)

                    if game.ReplicatedStorage:FindFirstChild("Kill") then
                        game.ReplicatedStorage.Kill:FireServer(Player)
                    end
                end
            end
        end
    end)
end

function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model

    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)

        if success and result then
            model = result
        end
    end

    if model then
        model.Parent = workspace

        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end

    return model
end

local function fadeOutAndDestroy(model)
    fadeParticles(model, 0, 1, 1)

    if model then
        model:Destroy()
    end
end

local s = LoadCustomInstance(124110962492998)

if not s then
    return
end

if s:IsA("Model") then
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(5, 0.8, -15))
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")

        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(5, 0.8, -15))
        end
    end
else
    local entity = s:FindFirstChildWhichIsA("BasePart")

    if entity then
        entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(5, 0.8, -15)

        if entity:FindFirstChild("Part") then
            entity.Part.CFrame = entity.CFrame
        end
    end
end

local Obsession = s:FindFirstChild("Obsession")

if not Obsession and s.Name == "Obsession" then
    Obsession = s
end

setParticleTransparency(s, 1)

fadeParticles(s, 1, 0, 1)

startDamageLoop(s)

game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()

if damageConnection then
    damageConnection:Disconnect()
end

fadeOutAndDestroy(s)
end
function entityBehaviors.Hunger()
function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model
    
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    
    return model
end

local s = LoadCustomInstance(138426557790457)
if not s then
    return
end

if s:IsA("Model") then
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0.8, -25))
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")
        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0.8, -25))
        end
    end
else
    local entity = s:FindFirstChildWhichIsA("BasePart")
    if entity then
        entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0.8, -25)
        if entity:FindFirstChild("Part") then
            entity.Part.CFrame = entity.CFrame
        end
    end
end
local hunger = s:FindFirstChild("Hunger")
if not hunger and s.Name == "Hunger" then
    hunger = s
end

if hunger then
    local rushNew = hunger:FindFirstChild("RushNew")
    if rushNew then
        local attachment = rushNew:FindFirstChild("Attachment")
        if attachment then
            local particle = attachment:FindFirstChild("ParticleEmitter")
            if particle and particle:IsA("ParticleEmitter") then
                particle.Transparency = NumberSequence.new(1)
                wait(12)
                local startTime = tick()
                local fadeDuration = 5
                while tick() - startTime < fadeDuration do
                    local elapsed = tick() - startTime
                    local transparency = math.clamp(1 - (elapsed / fadeDuration), 0, 1)
                    particle.Transparency = NumberSequence.new(transparency)
                    game:GetService("RunService").Heartbeat:Wait()
                end
                particle.Transparency = NumberSequence.new(0)
                require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("I have no strength to run.. I am very hungry", true)
                game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
                s:Destroy()
            end
        end
    end
end
end

function entityBehaviors.kITTY()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model
    
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    
    return model
end

local function isPlayerLookingAtModel(model)
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return false end
    
    local head = character:FindFirstChild("Head")
    if not head then return false end
    
    local camera = Workspace.CurrentCamera
    if not camera then return false end
    
    local modelPosition
    if model:IsA("Model") then
        if model.PrimaryPart then
            modelPosition = model.PrimaryPart.Position
        else
            local primary = model:FindFirstChildWhichIsA("BasePart")
            if primary then
                modelPosition = primary.Position
            else
                return false
            end
        end
    else
        modelPosition = model.Position
    end
    
    local cameraCFrame = camera.CFrame
    local cameraDirection = cameraCFrame.LookVector
    local toModel = (modelPosition - cameraCFrame.Position).Unit
    
    local dot = cameraDirection:Dot(toModel)
    return dot > 0.9
end

local function raycastToPlayer(model, maxDistance)
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local modelPosition
    if model:IsA("Model") then
        if model.PrimaryPart then
            modelPosition = model.PrimaryPart.Position
        else
            local primary = model:FindFirstChildWhichIsA("BasePart")
            if primary then
                modelPosition = primary.Position
            else
                return false
            end
        end
    else
        modelPosition = model.Position
    end
    
    local direction = (humanoidRootPart.Position - modelPosition)
    local distance = direction.Magnitude
    
    if distance <= maxDistance then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {model}
        raycastParams.IgnoreWater = true
        
        local raycastResult = Workspace:Raycast(
            modelPosition,
            direction.Unit * maxDistance,
            raycastParams
        )
        
        if raycastResult then
            local hitPart = raycastResult.Instance
            if hitPart and hitPart:IsDescendantOf(character) then
                return true
            end
        end
    end
    
    return false
end

local function updateParticleVisibility(model, isVisible)
    if not model then return end
    
    local ObsessionNew = model:FindFirstChild("ObsessionNew")
    if not ObsessionNew then
        ObsessionNew = model:FindFirstChild("Obsession")
    end
    
    if ObsessionNew then
        local attachment = ObsessionNew:FindFirstChildOfClass("Attachment")
        if attachment then
            local particleEmitter = attachment:FindFirstChildOfClass("ParticleEmitter")
            if particleEmitter then
                particleEmitter.Transparency = NumberSequence.new(isVisible and 1 or 0)
            end
        end
    end
end

local currentRoom = GetRoom()
if not currentRoom then
    return
end

local assetsFolder = currentRoom:FindFirstChild("Assets")
if not assetsFolder then
    return
end

local pillars = {}
for _, child in ipairs(assetsFolder:GetChildren()) do
    if child.Name == "Pillar" and child:IsA("Model") then
        table.insert(pillars, child)
    end
end

if #pillars == 0 then
    return
end

local randomPillar = pillars[math.random(1, #pillars)]

local s = LoadCustomInstance(88484943740859)
if not s then
    return
end

local Kitty = s:FindFirstChild("Kitty")
if not Kitty and s.Name == "Kitty" then
    Kitty = s
end

if randomPillar.PrimaryPart then
    if s:IsA("Model") then
        if s.PrimaryPart then
            s:SetPrimaryPartCFrame(randomPillar.PrimaryPart.CFrame + Vector3.new(5, 0, 0))
        else
            local primary = s:FindFirstChildWhichIsA("BasePart")
            if primary then
                s.PrimaryPart = primary
                s:SetPrimaryPartCFrame(randomPillar.PrimaryPart.CFrame + Vector3.new(5, 0, 0))
            end
        end
    else
        local entity = s:FindFirstChildWhichIsA("BasePart")
        if entity then
            entity.CFrame = randomPillar.PrimaryPart.CFrame + Vector3.new(5, 0, 0)
            if entity:FindFirstChild("Part") then
                entity.Part.CFrame = entity.CFrame
            end
        end
    end
else
    local pillarBasePart = randomPillar:FindFirstChildWhichIsA("BasePart")
    if pillarBasePart then
        if s:IsA("Model") then
            if s.PrimaryPart then
                s:SetPrimaryPartCFrame(pillarBasePart.CFrame + Vector3.new(2, 0, 0))
            else
                local primary = s:FindFirstChildWhichIsA("BasePart")
                if primary then
                    s.PrimaryPart = primary
                    s:SetPrimaryPartCFrame(pillarBasePart.CFrame + Vector3.new(2, 0, 0))
                end
            end
        else
            local entity = s:FindFirstChildWhichIsA("BasePart")
            if entity then
                entity.CFrame = pillarBasePart.CFrame + Vector3.new(2, 0, 0)
                if entity:FindFirstChild("Part") then
                    entity.Part.CFrame = entity.CFrame
                end
            end
        end
    end
end

local canHide = false
local hasHidden = false
local spawnTime = tick()

local raycastConnection
raycastConnection = RunService.Heartbeat:Connect(function()
    if not s or not s.Parent then
        raycastConnection:Disconnect()
        return
    end
    
    if not canHide then
        if tick() - spawnTime >= 5 then
            canHide = true
        else
            return
        end
    end
    
    if hasHidden then
        return
    end
    
    local inRange = raycastToPlayer(s, 12)
    local isLooking = isPlayerLookingAtModel(s)
    
    if inRange or isLooking then
        updateParticleVisibility(s, true)
        hasHidden = true
    end
end)

game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
if raycastConnection then
    raycastConnection:Disconnect()
end
s:Destroy()
end

function entityBehaviors.Hunger()
function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model
    
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    
    return model
end

local s = LoadCustomInstance(138426557790457)
if not s then
    return
end

if s:IsA("Model") then
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0.8, -25))
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")
        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0.8, -25))
        end
    end
else
    local entity = s:FindFirstChildWhichIsA("BasePart")
    if entity then
        entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0.8, -25)
        if entity:FindFirstChild("Part") then
            entity.Part.CFrame = entity.CFrame
        end
    end
end
local hunger = s:FindFirstChild("Hunger")
if not hunger and s.Name == "Hunger" then
    hunger = s
end

if hunger then
    local rushNew = hunger:FindFirstChild("RushNew")
    if rushNew then
        local attachment = rushNew:FindFirstChild("Attachment")
        if attachment then
            local particle = attachment:FindFirstChild("ParticleEmitter")
            if particle and particle:IsA("ParticleEmitter") then
                particle.Transparency = NumberSequence.new(1)
                wait(12)
                local startTime = tick()
                local fadeDuration = 5
                while tick() - startTime < fadeDuration do
                    local elapsed = tick() - startTime
                    local transparency = math.clamp(1 - (elapsed / fadeDuration), 0, 1)
                    particle.Transparency = NumberSequence.new(transparency)
                    game:GetService("RunService").Heartbeat:Wait()
                end
                particle.Transparency = NumberSequence.new(0)
                require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("I have no strength to run.. I am very hungry", true)
                game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
                s:Destroy()
            end
        end
    end
end
end

function entityBehaviors.HIMS()
local entity = spawner.Create({Entity = {Name = "Him",
Asset = "86311109309225",HeightOffset = 0},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = false,Range = 200,Values = {1.5, 20, 0.1, 1}},
Movement = {Speed = 300,Delay = 5,Reversed = false},Rebounding = {Enabled = true,Type = "ambush",Min = 4,Max = 4,Delay = math.random(5, 30) / 10},Damage = {Enabled = true,Range = 100,Amount = 125},Crucifixion = {
Enabled = true,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于Him", "竭力的嘶吼声预告着它要到来", "观察它的规律", "反复进柜子躲避它"},Cause = "Him"}})
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

function entityBehaviors.bkeyes()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera

local function isPlayerLookingAtEntity(entity)
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return false end

    local head = character:FindFirstChild("Head")
    if not head then return false end

    local entityPosition

    if entity:IsA("Model") then
        local primary = entity.PrimaryPart or entity:FindFirstChildWhichIsA("BasePart")
        if not primary then return false end
        entityPosition = primary.Position
    else
        entityPosition = entity.Position
    end

    local cameraDirection = Camera.CFrame.LookVector
    local toEntity = (entityPosition - head.Position).Unit

    local dot = cameraDirection:Dot(toEntity)
    return dot > 0.7
end

local function setParticleTransparency(model, value)
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            obj.Transparency = NumberSequence.new(value)
        end
    end
end

local function fadeParticles(model, fromValue, toValue, duration)
    local emitters = {}

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            table.insert(emitters, obj)
        end
    end

    local startTime = tick()

    while tick() - startTime < duration do
        local alpha = (tick() - startTime) / duration
        local value = fromValue + (toValue - fromValue) * alpha

        for _, emitter in ipairs(emitters) do
            emitter.Transparency = NumberSequence.new(value)
        end

        RunService.Heartbeat:Wait()
    end

    for _, emitter in ipairs(emitters) do
        emitter.Transparency = NumberSequence.new(toValue)
    end
end

local damageConnection

local function startDamageLoop(entity)
    if damageConnection then
        damageConnection:Disconnect()
    end

    local lastDamageTime = 0

    damageConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not entity or not entity.Parent then
            damageConnection:Disconnect()
            return
        end

        if isPlayerLookingAtEntity(entity) then
            lastDamageTime = lastDamageTime + deltaTime

            if lastDamageTime >= 0.05 then
                lastDamageTime = 0

                local Player = Players.LocalPlayer
                local Character = Player.Character or Player.CharacterAdded:Wait()
                local Humanoid = Character:WaitForChild("Humanoid")

                if Humanoid.Health > 0 then
                    local NewHealth = Humanoid.Health - 5

                    if NewHealth <= 0 then
                        Humanoid.Health = 0
                        Player:SetAttribute("Alive", false)

                        if game.ReplicatedStorage:FindFirstChild("Kill") then
                            game.ReplicatedStorage.Kill:FireServer(Player)
                        end
                    else
                        Humanoid.Health = NewHealth
                    end
                end
            end
        end
    end)
end

function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model

    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)

        if success and result then
            model = result
        end
    end

    if model then
        model.Parent = workspace

        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end

    return model
end

local s = LoadCustomInstance(130034778193642)

if not s then
    return
end

local targetPart
local currentRoom = GetRoom()

if currentRoom then
    local doorModel = currentRoom:FindFirstChild("Door")

    if doorModel then
        targetPart = doorModel:FindFirstChild("Door")
    end
end

local targetCFrame

if targetPart and targetPart:IsA("BasePart") then
    targetCFrame = targetPart.CFrame
else
    targetCFrame = GetRoom():WaitForChild("RoomEntrance").CFrame
end

if s:IsA("Model") then
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(targetCFrame * CFrame.new(0, 0, 5))
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")

        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(targetCFrame * CFrame.new(0, 0, 5))
        end
    end
else
    local entity = s:FindFirstChildWhichIsA("BasePart")

    if entity then
        entity.CFrame = targetCFrame * CFrame.new(0, 0, 5)

        if entity:FindFirstChild("Part") then
            entity.Part.CFrame = entity.CFrame
        end
    end
end

local Brokeneyes = s:FindFirstChild("Broken eyes")

if not Brokeneyes and s.Name == "Broken eyes" then
    Brokeneyes = s
end

setParticleTransparency(s, 1)

fadeParticles(s, 1, 0, 2)

startDamageLoop(s)

game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()

if damageConnection then
    damageConnection:Disconnect()
end

fadeParticles(s, 0, 1, 2)

s:Destroy()
end

function entityBehaviors.dread()
function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(tostring(game.ReplicatedStorage.GameData.LatestRoom.Value))
end

local function LoadCustomInstance(source)
    local model
    
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    
    return model
end

local function Damage(Amount)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local Player = Players.LocalPlayer
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

    if not Humanoid or Humanoid.Health <= 0 or Character:GetAttribute("Hiding") then
        return false
    end

    local DamageAmount = (Amount / 100) * Humanoid.MaxHealth
    local OldHealth = Humanoid.Health

    if OldHealth <= DamageAmount then
        local GameStats = ReplicatedStorage:FindFirstChild("GameStats")
        local PlayerStats = GameStats and GameStats:FindFirstChild("Player_" .. Player.Name)
        local Total = PlayerStats and PlayerStats:FindFirstChild("Total")
        local DeathCause = Total and Total:FindFirstChild("DeathCause")

        if DeathCause then
            DeathCause.Value = "ClockDread"
        end
    end

    Humanoid.Health = math.max(0, OldHealth - DamageAmount)
    return true
end

local s = LoadCustomInstance(128969616828176)
if not s then
    return
end

if s:IsA("Model") then
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, -3.6, -25))
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")
        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, -3.6, -25))
        end
    end
else
    local entity = s:FindFirstChildWhichIsA("BasePart")
    if entity then
        entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, -3.6, -25)
        if entity:FindFirstChild("Part") then
            entity.Part.CFrame = entity.CFrame
        end
    end
end

local sound1 = Instance.new("Sound")
sound1.SoundId = "rbxassetid://139804031181000"
sound1.Parent = workspace
sound1.Looped = false
sound1.Volume = 1
local soundCount = math.random(3, 10)

for i = 1, soundCount do
    sound1:Play()
    sound1.Ended:Wait()
end
sound1:Destroy()

local sound2 = Instance.new("Sound")
sound2.SoundId = "rbxassetid://137004686137325"
sound2.Parent = workspace
sound2.Looped = false
sound2.Volume = 1
sound2.PlaybackSpeed = 0.8
sound2:Play()

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")
local image = Instance.new("ImageLabel")
image.Image = "rbxassetid://100734201255797"
image.BackgroundTransparency = 1
image.Size = UDim2.new(1, 0, 1, 0)
image.Position = UDim2.new(0.5, 0, 0.5, 0)
image.AnchorPoint = Vector2.new(0.5, 0.5)
image.Parent = gui
image.ZIndex = 999
image.ScaleType = Enum.ScaleType.Fit
image.BackgroundTransparency = 1
image.ImageTransparency = 1
image.ImageColor3 = Color3.fromRGB(255, 255, 255)

local blur = Instance.new("BlurEffect")
blur.Size = 2
blur.Parent = game:GetService("Lighting")

for i = 0, 1, 0.05 do
    image.ImageTransparency = 1 - (i * 0.1)
    local offsetX = (math.random() - 0.5) * 2
    local offsetY = (math.random() - 0.5) * 2
    image.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
    wait(0.05)
end

image.ImageTransparency = 0.9
image.Position = UDim2.new(0.5, 0, 0.5, 0)
local hasTriggered = false
local startStay = tick()
while tick() - startStay < 2 do
    local offsetX = (math.random() - 0.5) * 2
    local offsetY = (math.random() - 0.5) * 2
    image.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if humanoid and humanoid.Health > 0 then
            local isHiding = character:GetAttribute("Hiding")
            if not isHiding and not hasTriggered then
                hasTriggered = Damage(100)
            end
        end
    end

    wait(0.05)
end

for i = 1, 0, -0.05 do
    image.ImageTransparency = 0.9 + (1 - i) * 0.1

    local offsetX = (math.random() - 1) * 2
    local offsetY = (math.random() - 1) * 2
    image.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)

    wait(0.05)
end

image:Destroy()
gui:Destroy()
blur:Destroy()

sound2:Destroy()

task.wait(20)

if s and s.Parent then
    s:Destroy()
end

end

function entityBehaviors.DEPTH1()
local TweenService = game:GetService("TweenService")
local targetColor = Color3.fromRGB(21, 0, 255)
local fadeDuration = 1

local fadeInfo = TweenInfo.new(
    fadeDuration,
    Enum.EasingStyle.Linear,
    Enum.EasingDirection.Out
)

local function createFadeTween(object)
    if object:IsA("BasePart") or object:IsA("Light") then
        local tween = TweenService:Create(object, fadeInfo, {Color = targetColor})
        tween:Play()
        return tween
    end
    return nil
end

local function modifyObjectsWithTween()
    local allTweens = {}
    for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
        if room:IsA("Model") then
            local assets = room:FindFirstChild("Assets")
            if assets then
                for _, chandelier in pairs(assets:GetChildren()) do
                    if chandelier:IsA("Model") and chandelier.Name == "Chandelier" then
                        local lightFixture = chandelier:FindFirstChild("LightFixture")
                        if lightFixture then
                            local pointLight = lightFixture:FindFirstChild("PointLight")
                            if pointLight and pointLight:IsA("PointLight") then
                                table.insert(allTweens, createFadeTween(pointLight))
                            end
                            
                            local spotLight = lightFixture:FindFirstChild("SpotLight")
                            if spotLight and spotLight:IsA("SpotLight") then
                                table.insert(allTweens, createFadeTween(spotLight))
                            end
                            
                            local neon = lightFixture:FindFirstChild("Neon")
                            if neon and neon:IsA("BasePart") then
                                table.insert(allTweens, createFadeTween(neon))
                            end
                        end
                    end
                end
                local lightFixtures = assets:FindFirstChild("Light_Fixtures")
                if lightFixtures then
                    for _, lightStand in pairs(lightFixtures:GetChildren()) do
                        if lightStand:IsA("Model") and lightStand.Name == "LightStand" then
                            local lightFixture = lightStand:FindFirstChild("LightFixture")
                            if lightFixture then
                                local pointLight = lightFixture:FindFirstChild("PointLight")
                                if pointLight and pointLight:IsA("PointLight") then
                                    table.insert(allTweens, createFadeTween(pointLight))
                                end
                                
                                local neon = lightFixture:FindFirstChild("Neon")
                                if neon and neon:IsA("BasePart") then
                                    table.insert(allTweens, createFadeTween(neon))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
coroutine.wrap(function()
    modifyObjectsWithTween()
end)()
local entity = spawner.Create({Entity = {Name = "Depth",Asset = "93356386746722",HeightOffset = 1},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,
Range = 100,Values = {10, 30, 0.1, 1}},Movement = {Speed = 180,Delay = 2,Reversed = false},Rebounding = {Enabled = true,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},
Damage = {Enabled = true,Range = 99,Amount = 125},Crucifixion = {Enabled = true,Range = 100,Resist = false,Break = true},Death = {
Type = "Guiding",Hints = {"你死于Depth", "当灯光变蓝时他会出现", "他会上锁当前房间的门", "所以务必尽快离开!"},Cause = "Depth"}})
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

function entityBehaviors.coomon()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local OldEntity = workspace:FindFirstChild("Common Sence")

if OldEntity then
	pcall(function()
		OldEntity:Destroy()
	end)
end

local function setDeathCause(cause)
	local gameStats = ReplicatedStorage:FindFirstChild("GameStats")

	if not gameStats then
		return
	end

	local playerStats = gameStats:FindFirstChild("Player_" .. Player.Name)

	if not playerStats then
		return
	end

	local total = playerStats:FindFirstChild("Total")

	if not total then
		return
	end

	local deathCause = total:FindFirstChild("DeathCause")

	if deathCause then
		deathCause.Value = cause
	end
end

local success, models = pcall(function()
	return game:GetObjects(
		"rbxassetid://112572076699068"
	)
end)

if not success
	or not models
	or not models[1]
then
	return
end

local figureModel = models[1]

figureModel.Name = "Common Sence"
figureModel.Parent = workspace

local EntityRunning = true
local IsAttacking = false

local function destroyEntity()
	if not EntityRunning then
		return
	end

	EntityRunning = false

	if figureModel then
		pcall(function()
			figureModel:Destroy()
		end)
	end
end

local CurrentRooms =
	workspace:FindFirstChild("CurrentRooms")

if not CurrentRooms then
	destroyEntity()
	return
end

local room50 =
	CurrentRooms:FindFirstChild("50")

if not room50 then
	destroyEntity()
	return
end

local startModel =
	room50:FindFirstChild(
		"Door",
		true
	)

if not startModel then
	destroyEntity()
	return
end

local startPart =
	startModel:FindFirstChild("Hidden")

if not startPart
	or not startPart:IsA("BasePart")
then
	destroyEntity()
	return
end

local FigureSetup =
	room50:FindFirstChild("FigureSetup")

if not FigureSetup then
	destroyEntity()
	return
end

local FigureNodesFolder =
	FigureSetup:FindFirstChild("FigureNodes")

if not FigureNodesFolder then
	destroyEntity()
	return
end

local allWaypoints = {}

for _, waypoint in ipairs(
	FigureNodesFolder:GetChildren()
) do
	if waypoint:IsA("BasePart") then
		table.insert(
			allWaypoints,
			waypoint
		)
	end
end

if #allWaypoints == 0 then
	destroyEntity()
	return
end

if not figureModel.PrimaryPart then
	for _, object in ipairs(
		figureModel:GetDescendants()
	) do
		if object:IsA("BasePart") then
			figureModel.PrimaryPart = object
			break
		end
	end
end

if not figureModel.PrimaryPart then
	destroyEntity()
	return
end

local HEIGHT_OFFSET = 3

local startPosition =
	Vector3.new(
		startPart.Position.X,
		startPart.Position.Y + HEIGHT_OFFSET,
		startPart.Position.Z
	)

figureModel:PivotTo(
	CFrame.new(startPosition)
)

local LatestRoom =
	ReplicatedStorage
		:WaitForChild("GameData")
		:WaitForChild("LatestRoom")

local StartingRoomValue =
	LatestRoom.Value

task.spawn(function()
	while EntityRunning do
		LatestRoom.Changed:Wait()

		if not EntityRunning then
			break
		end

		if LatestRoom.Value ~= StartingRoomValue then
			destroyEntity()
			break
		end
	end
end)

local function entityAlive()
	return
		EntityRunning
		and figureModel
		and figureModel.Parent
		and figureModel.PrimaryPart
end

local function moveToPosition(
	targetPosition,
	speed
)
	if not entityAlive() then
		return false
	end

	local currentPivot =
		figureModel:GetPivot()

	local startPos =
		currentPivot.Position

	local endPos =
		Vector3.new(
			targetPosition.X,
			targetPosition.Y + HEIGHT_OFFSET,
			targetPosition.Z
		)

	local distance =
		(endPos - startPos).Magnitude

	if distance <= 0.01 then
		figureModel:PivotTo(
			CFrame.new(endPos)
		)

		return true
	end

	local duration =
		distance / speed

	local elapsed = 0
	local updateAccumulator = 0

	while elapsed < duration do
		if not entityAlive() then
			return false
		end

		local deltaTime =
			RunService.Heartbeat:Wait()

		elapsed += deltaTime
		updateAccumulator += deltaTime

		if updateAccumulator >= 1 / 30
			or elapsed >= duration
		then
			updateAccumulator = 0

			local progress =
				math.clamp(
					elapsed / duration,
					0,
					1
				)

			local currentPos =
				startPos:Lerp(
					endPos,
					progress
				)

			figureModel:PivotTo(
				CFrame.new(currentPos)
			)
		end
	end

	if entityAlive() then
		figureModel:PivotTo(
			CFrame.new(endPos)
		)

		return true
	end

	return false
end

local function getNearestWaypoint(
	currentPos,
	remainingWaypoints
)
	local nearest = nil
	local nearestDistance = math.huge

	for _, waypoint in ipairs(
		remainingWaypoints
	) do
		if waypoint
			and waypoint.Parent
		then
			local waypointPosition =
				Vector3.new(
					waypoint.Position.X,
					waypoint.Position.Y + HEIGHT_OFFSET,
					waypoint.Position.Z
				)

			local distance =
				(
					waypointPosition
					- currentPos
				).Magnitude

			if distance < nearestDistance then
				nearestDistance = distance
				nearest = waypoint
			end
		end
	end

	return nearest
end

local function setupAttackDetection()
	local ATTACK_RANGE = 10
	local ATTACK_COOLDOWN = 0.5
	local DAMAGE = 70

	task.spawn(function()
		while entityAlive() do
			task.wait(
				ATTACK_COOLDOWN
			)

			if not entityAlive() then
				break
			end

			local Character =
				Player.Character

			if not Character then
				continue
			end

			local Humanoid =
				Character
					:FindFirstChildOfClass(
						"Humanoid"
					)

			local RootPart =
				Character
					:FindFirstChild(
						"HumanoidRootPart"
					)

			if not Humanoid
				or not RootPart
				or Humanoid.Health <= 0
			then
				continue
			end

			if IsAttacking then
				continue
			end

			local EntityRoot =
				figureModel.PrimaryPart

			if not EntityRoot then
				break
			end

			local entityPosition =
				EntityRoot.Position

			local playerPosition =
				RootPart.Position

			local offset =
				playerPosition
				- entityPosition

			local distance =
				offset.Magnitude

			if distance > ATTACK_RANGE then
				continue
			end

			if distance <= 0.05 then
				IsAttacking = true

				local WillDie =
					Humanoid.Health <= DAMAGE

				if WillDie then
					setDeathCause(
						"Common Sence"
					)
				end

				Humanoid:TakeDamage(DAMAGE)

				task.wait(1)

				IsAttacking = false

				continue
			end

			local raycastParams =
				RaycastParams.new()

			raycastParams.FilterType =
				Enum.RaycastFilterType.Exclude

			raycastParams.FilterDescendantsInstances =
				{
					figureModel
				}

			raycastParams.IgnoreWater = true

			local result =
				workspace:Raycast(
					entityPosition,
					offset,
					raycastParams
				)

			if result
				and result.Instance
				and result.Instance:IsDescendantOf(
					Character
				)
			then
				IsAttacking = true

				local WillDie =
					Humanoid.Health <= DAMAGE

				if WillDie then
					setDeathCause(
						"Common Sence"
					)
				end

				Humanoid:TakeDamage(
					DAMAGE
				)

				task.wait(1)

				IsAttacking = false
			end
		end
	end)
end

local function moveThroughWaypoints()
	if not entityAlive() then
		return
	end

	local remainingWaypoints = {}

	for _, waypoint in ipairs(
		allWaypoints
	) do
		table.insert(
			remainingWaypoints,
			waypoint
		)
	end

	local visitedWaypoints = {}

	local currentPos =
		figureModel.PrimaryPart.Position

	while #remainingWaypoints > 0
		and entityAlive()
	do
		local nearest =
			getNearestWaypoint(
				currentPos,
				remainingWaypoints
			)

		if not nearest then
			break
		end

		local moved =
			moveToPosition(
				nearest.Position,
				14
			)

		if not moved
			or not entityAlive()
		then
			break
		end

		currentPos =
			figureModel.PrimaryPart.Position

		table.insert(
			visitedWaypoints,
			nearest
		)

		for index, waypoint in ipairs(
			remainingWaypoints
		) do
			if waypoint == nearest then
				table.remove(
					remainingWaypoints,
					index
				)

				break
			end
		end
	end

	for index =
		#visitedWaypoints - 1,
		1,
		-1
	do
		if not entityAlive() then
			break
		end

		local waypoint =
			visitedWaypoints[index]

		local moved =
			moveToPosition(
				waypoint.Position,
				14
			)

		if not moved then
			break
		end
	end

	for index =
		2,
		#visitedWaypoints
	do
		if not entityAlive() then
			break
		end

		local waypoint =
			visitedWaypoints[index]

		local moved =
			moveToPosition(
				waypoint.Position,
				14
			)

		if not moved then
			break
		end
	end
end

setupAttackDetection()
moveThroughWaypoints()
end

function entityBehaviors.MOVERS()
local MainUI = game:GetObjects("rbxassetid://95819908379371")[1]
MainUI.Parent = game.Players.LocalPlayer.PlayerGui
local plr = game.Players.LocalPlayer
local arg1 = game.Workspace.CurrentCamera
local Jumpscare_Mover = MainUI.Jumpscare.Jumpscare_A90
Jumpscare_Mover.BackgroundTransparency = 1
Jumpscare_Mover.Face.Visible = true
Jumpscare_Mover.FaceAngry.Visible = false
Jumpscare_Mover.Static.Visible = true
Jumpscare_Mover.Static2.Visible = true
Jumpscare_Mover.Static.ImageTransparency = 1
Jumpscare_Mover.Static2.ImageTransparency = 1
Jumpscare_Mover.Face.Image = "rbxassetid://119177305867863"
Jumpscare_Mover.FaceAngry.Image = "rbxassetid://77341058717266"

Jumpscare_Mover.Face.ImageColor3 = Color3.new(0, 0, 0)
Jumpscare_Mover.Face.Position = UDim2.new(0.5, 0, 0.5, 0)
Jumpscare_Mover.Visible = true

Jumpscare_Mover.BackgroundColor3 = Color3.new(0, 0, 0)
Jumpscare_Mover.Static.ImageColor3 = Color3.new(0, 0, 0)
Jumpscare_Mover.Static2.ImageColor3 = Color3.new(0, 0, 0)

local spawnSound = Instance.new("Sound")
spawnSound.SoundId = "rbxassetid://138085276131551"
spawnSound.Volume = 8
spawnSound.Parent = Jumpscare_Mover
spawnSound:Play()

local jumpscareSound = Instance.new("Sound")
jumpscareSound.SoundId = "rbxassetid://139300381946118"
jumpscareSound.Volume = 8
jumpscareSound.Parent = Jumpscare_Mover

local fadeTime = 5
local fadeSteps = 50
local fadeInterval = fadeTime / fadeSteps

for i = 0, 1, 1/fadeSteps do
    Jumpscare_Mover.Face.ImageTransparency = 1 - i
    Jumpscare_Mover.Static.ImageTransparency = 1 - i
    Jumpscare_Mover.Static2.ImageTransparency = 1 - i
    Jumpscare_Mover.BackgroundTransparency = 1 - i
    task.wait(fadeInterval)
end

Jumpscare_Mover.Face.ImageTransparency = 0
Jumpscare_Mover.Static.ImageTransparency = 0.8
Jumpscare_Mover.Static2.ImageTransparency = 0.8
Jumpscare_Mover.BackgroundTransparency = 0
Jumpscare_Mover.Face.ImageColor3 = Color3.new(1, 1, 1)

local isMoving = false
local wasMoving = false
local LookVector = arg1.CFrame.LookVector
local isActive = true
local stopCheckTime = 0
local lastMoveTime = 0
local damageApplied = false

local function setDeathCause(deathCause)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local gameStats = replicatedStorage:FindFirstChild("GameStats")
    local playerStats = gameStats and gameStats:FindFirstChild("Player_" .. plr.Name)
    local total = playerStats and playerStats:FindFirstChild("Total")
    local value = total and total:FindFirstChild("DeathCause")
    if value then
        value.Value = deathCause
    end
end

local function applyDamage()
    if damageApplied then return end
    damageApplied = true

    local character = plr.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    local damage = 99
    if humanoid.Health <= damage then
        setDeathCause("Mover")
    end

    humanoid:TakeDamage(damage)
end

task.delay(0.2, function()
    while isActive do
        task.wait(0.03333333333333333)

        if not isActive or not Jumpscare_Mover.Parent then
            break
        end

        local character = plr.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            isActive = false
            break
        end

        Jumpscare_Mover.Static.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0)
        Jumpscare_Mover.Static.Rotation = math.random(0, 1) * 180
        Jumpscare_Mover.Static2.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0)
        Jumpscare_Mover.Static2.Rotation = math.random(0, 1) * 180
        Jumpscare_Mover.Face.Position = UDim2.new(0.5, 0, 0.49, math.random(-1, 1))
        Jumpscare_Mover.FaceAngry.Position = UDim2.new(0.5 + math.random(-100, 100) / 50000, 0, 0.49 + math.random(-100, 100) / 30000, math.random(-1, 1))
        local randint = math.random(0, 1)
        Jumpscare_Mover.FaceAngry.ImageColor3 = Color3.new(1, randint, randint)

        local currentMoving = false
        if 0.4 < (LookVector - arg1.CFrame.LookVector).Magnitude then
            currentMoving = true
        end
        if 0.4 < humanoid.MoveDirection.Magnitude then
            currentMoving = true
        end

        if currentMoving then
            isMoving = true
            wasMoving = true
            lastMoveTime = tick()
        else
            if wasMoving then
                isActive = false
                Jumpscare_Mover.Face.Image = "rbxassetid://77341058717266"
                jumpscareSound:Play()

                task.wait(0.03333333333333333)
                Jumpscare_Mover.Face.ImageColor3 = Color3.new(1, 0, 0)
                Jumpscare_Mover.Static.ImageTransparency = 0
                Jumpscare_Mover.Static2.ImageTransparency = 0.5

                task.wait(0.06666666666666667)
                Jumpscare_Mover.FaceAngry.ImageColor3 = Color3.new(1, 0, 0)
                Jumpscare_Mover.FaceAngry.Visible = true

                task.wait(0.06666666666666667)
                Jumpscare_Mover.FaceAngry.ImageColor3 = Color3.new(1, 1, 1)
                Jumpscare_Mover.Face.Visible = false
                Jumpscare_Mover.FaceAngry.Size = UDim2.new(0.8, 0, 0.8, 0)

                task.wait(0.75)
                applyDamage()

                task.wait(0.1)
                Jumpscare_Mover.FaceAngry.Visible = false
                Jumpscare_Mover.BackgroundColor3 = Color3.new(1, 1, 1)
                Jumpscare_Mover.Static.ImageTransparency = 1
                Jumpscare_Mover.Static2.ImageTransparency = 1

                task.wait(0.06666666666666667)
                Jumpscare_Mover.BackgroundColor3 = Color3.new(1, 0, 0)

                task.wait(0.06666666666666667)
                Jumpscare_Mover.BackgroundColor3 = Color3.new(0, 0, 0)

                task.wait(0.06666666666666667)
                break
            end
        end

        LookVector = arg1.CFrame.LookVector
    end
end)

task.wait(5)

if isActive then
    if not wasMoving then
        Jumpscare_Mover.Face.Image = "rbxassetid://77341058717266"
        jumpscareSound:Play()

        task.wait(0.03333333333333333)
        Jumpscare_Mover.Face.ImageColor3 = Color3.new(1, 0, 0)
        Jumpscare_Mover.Static.ImageTransparency = 0
        Jumpscare_Mover.Static2.ImageTransparency = 0.5

        task.wait(0.06666666666666667)
        Jumpscare_Mover.FaceAngry.ImageColor3 = Color3.new(1, 0, 0)
        Jumpscare_Mover.FaceAngry.Visible = true

        task.wait(0.06666666666666667)
        Jumpscare_Mover.FaceAngry.ImageColor3 = Color3.new(1, 1, 1)
        Jumpscare_Mover.Face.Visible = false
        Jumpscare_Mover.FaceAngry.Size = UDim2.new(0.8, 0, 0.8, 0)

        task.wait(0.75)
        applyDamage()

        task.wait(0.1)
        Jumpscare_Mover.FaceAngry.Visible = false
        Jumpscare_Mover.BackgroundColor3 = Color3.new(1, 1, 1)
        Jumpscare_Mover.Static.ImageTransparency = 1
        Jumpscare_Mover.Static2.ImageTransparency = 1

        task.wait(0.06666666666666667)
        Jumpscare_Mover.BackgroundColor3 = Color3.new(1, 0, 0)

        task.wait(0.06666666666666667)
        Jumpscare_Mover.BackgroundColor3 = Color3.new(0, 0, 0)

        task.wait(0.06666666666666667)
    else
        spawnSound:Stop()
        Jumpscare_Mover.BackgroundTransparency = 1
        Jumpscare_Mover.Face.ImageTransparency = 1
        Jumpscare_Mover.Static.ImageTransparency = 1
        Jumpscare_Mover.Static2.ImageTransparency = 1
    end
end

isActive = false
Jumpscare_Mover.Visible = false
task.wait(2)
MainUI:Destroy()

end
function entityBehaviors.SMILEWH()
function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model
    
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    
    return model
end

local function Damage(Amount)
    local Players = game:GetService("Players")

    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    
    local DamageAmount = (Amount / 100) * Humanoid.MaxHealth
    local NewHealth = Humanoid.Health - DamageAmount
    
    if NewHealth <= 0 then
        Player:SetAttribute("Alive", false)
        replicatesignal(Player.Kill)
    else
        Humanoid.Health = NewHealth
    end
end

local s = LoadCustomInstance(139610986522701)
if not s then
    return
end

local targetCFrame
local isModel = s:IsA("Model")
local entityPart

if isModel then
    local room = GetRoom()
    if not room then
        return
    end
    
    local roomEntrance = room:WaitForChild("RoomEntrance")
    targetCFrame = roomEntrance.CFrame * CFrame.new(0, 0, -25)
    local roomBaseY = roomEntrance.Position.Y
    
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(targetCFrame + Vector3.new(0, 15, 0))
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")
        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(targetCFrame + Vector3.new(0, 15, 0))
        end
    end
    entityPart = s.PrimaryPart
else
    entityPart = s:FindFirstChildWhichIsA("BasePart")
    if entityPart then
        local room = GetRoom()
        if not room then
            return
        end
        
        local roomEntrance = room:WaitForChild("RoomEntrance")
        targetCFrame = roomEntrance.CFrame * CFrame.new(0, 0, -25)
        local roomBaseY = roomEntrance.Position.Y
        
        entityPart.CFrame = targetCFrame + Vector3.new(0, 15, 0)
        if entityPart:FindFirstChild("Part") then
            entityPart.Part.CFrame = entityPart.CFrame
        end
    end
end

if not targetCFrame or not entityPart then
    return
end

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://139637448871564"
sound.Volume = 1
sound.Parent = workspace
sound:Play()

local countdownEnded = false
local roomChanged = false
local startY = targetCFrame.Y + 15
local targetY = targetCFrame.Y + 3
local dropDuration = 3
local dropStartTime = tick()

spawn(function()
    while not roomChanged do
        local elapsedTime = tick() - dropStartTime
        local progress = math.min(elapsedTime / dropDuration, 1)
        local currentY = startY + (targetY - startY) * (progress * progress * (3 - 2 * progress))
        
        if isModel and s.PrimaryPart then
            local pos = targetCFrame.Position
            s:SetPrimaryPartCFrame(CFrame.new(pos.X, currentY, pos.Z))
        elseif entityPart then
            local pos = targetCFrame.Position
            entityPart.CFrame = CFrame.new(pos.X, currentY, pos.Z)
        end
        
        if progress >= 1 then
            break
        end
        
        game:GetService("RunService").Heartbeat:Wait()
    end
end)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CountdownGui"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 0.1, 0)
textLabel.Position = UDim2.new(0, 0, 0.1, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
textLabel.TextStrokeTransparency = 0
textLabel.TextScaled = true
textLabel.Text = "20"
textLabel.Parent = screenGui

local fontSuccess, customFont = pcall(function()
    return Font.fromId(12187372382)
end)

if fontSuccess and customFont then
    textLabel.FontFace = customFont
else
    textLabel.Font = Enum.Font.GothamBlack
end

local countdownTask
countdownTask = spawn(function()
    for i = 20, 1, -1 do
        if roomChanged then
            break
        end
        textLabel.Text = tostring(i)
        local progress = (20 - i) / 20
        textLabel.TextColor3 = Color3.new(1, 1 - progress * 0.8, 1 - progress * 0.8)
        wait(1)
    end
    if not roomChanged then
        countdownEnded = true
        textLabel.Text = "0"
        textLabel.TextColor3 = Color3.new(1, 0, 0)
        wait(0.5)
    end
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
end)

local roomChangeCount = 0
local connection
connection = game.ReplicatedStorage.GameData.LatestRoom.Changed:Connect(function()
    roomChangeCount = roomChangeCount + 1
    if roomChangeCount == 3 then
        roomChanged = true
        if connection then 
            connection:Disconnect() 
        end
        if s and s.Parent then
            s:Destroy()
        end
        if sound then
            sound:Stop()
            sound:Destroy()
        end
        if countdownTask then
            coroutine.close(countdownTask)
        end
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end
end)

spawn(function()
    wait(20.5)
    if not roomChanged and countdownEnded then
        replicatesignal(player.Kill)
    end
end)
end

function entityBehaviors.SMILEWH2()
function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model
    
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    
    return model
end

local function Damage(Amount)
    local Players = game:GetService("Players")

    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    
    local DamageAmount = (Amount / 100) * Humanoid.MaxHealth
    local NewHealth = Humanoid.Health - DamageAmount
    
    if NewHealth <= 0 then
        Player:SetAttribute("Alive", false)
        replicatesignal(Player.Kill)
    else
        Humanoid.Health = NewHealth
    end
end

local s = LoadCustomInstance(139610986522701)
if not s then
    return
end

local targetCFrame
local isModel = s:IsA("Model")
local entityPart

if isModel then
    local room = GetRoom()
    if not room then
        return
    end
    
    local roomEntrance = room:WaitForChild("RoomEntrance")
    targetCFrame = roomEntrance.CFrame * CFrame.new(0, 0, -25)
    local roomBaseY = roomEntrance.Position.Y
    
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(targetCFrame + Vector3.new(0, 15, 0))
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")
        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(targetCFrame + Vector3.new(0, 15, 0))
        end
    end
    entityPart = s.PrimaryPart
else
    entityPart = s:FindFirstChildWhichIsA("BasePart")
    if entityPart then
        local room = GetRoom()
        if not room then
            return
        end
        
        local roomEntrance = room:WaitForChild("RoomEntrance")
        targetCFrame = roomEntrance.CFrame * CFrame.new(0, 0, -25)
        local roomBaseY = roomEntrance.Position.Y
        
        entityPart.CFrame = targetCFrame + Vector3.new(0, 15, 0)
        if entityPart:FindFirstChild("Part") then
            entityPart.Part.CFrame = entityPart.CFrame
        end
    end
end

if not targetCFrame or not entityPart then
    return
end

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://139637448871564"
sound.Volume = 1
sound.Parent = workspace
sound:Play()

local countdownEnded = false
local roomChanged = false
local startY = targetCFrame.Y + 15
local targetY = targetCFrame.Y + 3
local dropDuration = 3
local dropStartTime = tick()

spawn(function()
    while not roomChanged do
        local elapsedTime = tick() - dropStartTime
        local progress = math.min(elapsedTime / dropDuration, 1)
        local currentY = startY + (targetY - startY) * (progress * progress * (3 - 2 * progress))
        
        if isModel and s.PrimaryPart then
            local pos = targetCFrame.Position
            s:SetPrimaryPartCFrame(CFrame.new(pos.X, currentY, pos.Z))
        elseif entityPart then
            local pos = targetCFrame.Position
            entityPart.CFrame = CFrame.new(pos.X, currentY, pos.Z)
        end
        
        if progress >= 1 then
            break
        end
        
        game:GetService("RunService").Heartbeat:Wait()
    end
end)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CountdownGui"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 0.1, 0)
textLabel.Position = UDim2.new(0, 0, 0.1, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
textLabel.TextStrokeTransparency = 0
textLabel.TextScaled = true
textLabel.Text = "20"
textLabel.Parent = screenGui

local fontSuccess, customFont = pcall(function()
    return Font.fromId(12187372382)
end)

if fontSuccess and customFont then
    textLabel.FontFace = customFont
else
    textLabel.Font = Enum.Font.GothamBlack
end

local countdownTask
countdownTask = spawn(function()
    for i = 20, 1, -1 do
        if roomChanged then
            break
        end
        textLabel.Text = tostring(i)
        local progress = (20 - i) / 20
        textLabel.TextColor3 = Color3.new(1, 1 - progress * 0.8, 1 - progress * 0.8)
        wait(1)
    end
    if not roomChanged then
        countdownEnded = true
        textLabel.Text = "0"
        textLabel.TextColor3 = Color3.new(1, 0, 0)
        wait(0.5)
    end
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
end)

local roomChangeCount = 0
local connection
connection = game.ReplicatedStorage.GameData.LatestRoom.Changed:Connect(function()
    roomChangeCount = roomChangeCount + 1
    if roomChangeCount == 1 then
        roomChanged = true
        if connection then 
            connection:Disconnect() 
        end
        if s and s.Parent then
            s:Destroy()
        end
        if sound then
            sound:Stop()
            sound:Destroy()
        end
        if countdownTask then
            coroutine.close(countdownTask)
        end
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end
end)
end

spawn(function()
    wait(20.5)
    if not roomChanged and countdownEnded then
        replicatesignal(player.Kill)
    end
end)

function entityBehaviors.munci1()
local entity = spawner.Create({Entity = {Name = "Angry Munci",Asset = "74683697319835",HeightOffset = 1},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,
Range = 100,Values = {10, 30, 0.1, 1}},Movement = {Speed = 1000,Delay = 5,Reversed = false},Rebounding = {Enabled = false,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},
Damage = {Enabled = true,Range = 99,Amount = 125},Crucifixion = {Enabled = true,Range = 100,Resist = false,Break = true},Death = {
Type = "Guiding",Hints = {"你死于angry munci", "在细小的环境内听到他说话的声音...", "他的速度非常快", "注意仔细辨别!"},Cause = "Angry Munci"}})
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

function entityBehaviors.FLU()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function Damage(Amount)
    local Player = Players.LocalPlayer
    local Character = Player.Character
    if not Character then
        return
    end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then
        return
    end
    
    local NewHealth = Humanoid.Health - Amount
    
    if NewHealth <= 0 then
        Player:SetAttribute("Alive", false)
        if game.ReplicatedStorage:FindFirstChild("Kill") then
            game.ReplicatedStorage.Kill:FireServer(Player)
        end
    else
        Humanoid.Health = NewHealth
    end
end

local function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model
    
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    
    return model
end

local currentRoom = GetRoom()
if not currentRoom then
    return
end

local s = LoadCustomInstance(138743339338089)
if not s then
    return
end

local modelPosition
if s:IsA("Model") then
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(currentRoom:WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0, -40))
        modelPosition = s.PrimaryPart.Position
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")
        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(currentRoom:WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0, -40))
            modelPosition = primary.Position
        end
    end
else
    s.CFrame = currentRoom:WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 0, -40)
    modelPosition = s.Position
end

local lastCheckTime = 0
local damageLoop = RunService.Heartbeat:Connect(function(deltaTime)
    if not s or not s.Parent then
        damageLoop:Disconnect()
        return
    end
    
    lastCheckTime = lastCheckTime + deltaTime
    if lastCheckTime < 1 then
        return
    end
    lastCheckTime = 0
    
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    
    local distance = (humanoidRootPart.Position - modelPosition).Magnitude
    if distance > 18 then
        return
    end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {s}
    raycastParams.IgnoreWater = true
    
    local raycastResult = workspace:Raycast(
        modelPosition,
        (humanoidRootPart.Position - modelPosition).Unit * 18,
        raycastParams
    )
    
    if raycastResult then
        local hitPart = raycastResult.Instance
        if hitPart and hitPart:IsDescendantOf(character) then
            local Humanoid = character:FindFirstChild("Humanoid")
            if not Humanoid or Humanoid.Health <= 0 then
                return
            end
            
            local NewHealth = Humanoid.Health - 15
            Humanoid.Health = NewHealth
            
            if NewHealth <= 0 then
                player:SetAttribute("Alive", false)
                if game.ReplicatedStorage:FindFirstChild("Kill") then
                    game.ReplicatedStorage.Kill:FireServer(player)
                end
            end
        end
    end
end)

game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
damageLoop:Disconnect()
s:Destroy()
end

function entityBehaviors.CLCR()
local modelID = 79114665134948
local targetName = "Repentance_Skinned"
local loadedModel = nil
local targetModel = nil
local anchorPart = nil
local connections = {}
local isFollowing = false
local fadeStartTime = nil
local isFading = false
local isProcessing = false
local processedModels = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cachedModel
local function preloadModel()
    if cachedModel and cachedModel.Parent then
        cachedModel:Destroy()
        cachedModel = nil
    end
    
    local success, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(modelID))
    end)
    
    if not success or not result or not result[1] then
        return nil
    end
    
    cachedModel = result[1]
    cachedModel.Name = "Preloaded_VFX_Model"
    cachedModel.Parent = ReplicatedStorage
    
    for _, part in ipairs(cachedModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Massless = true
        end
    end
    
    return cachedModel
end

local function getModelFromCache()
    if not cachedModel or not cachedModel.Parent then
        return nil
    end
    
    local modelClone = cachedModel:Clone()
    modelClone.Parent = workspace
    modelClone.Name = "Follow_Model"
    
    return modelClone
end

local function createAnchorAtEntity()
    if not targetModel or not targetModel.Parent then 
        return nil 
    end
    
    local entity = targetModel:FindFirstChild("Entity")
    if not entity then
        return nil
    end
    
    local anchor = Instance.new("Part")
    anchor.Name = "Entity_Anchor"
    anchor.Size = Vector3.new(0.001, 0.001, 0.001)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Massless = true
    anchor.CFrame = entity.CFrame + Vector3.new(0, 1.4, 0)
    anchor.Parent = workspace
    
    return anchor
end

local function deleteTargetParts()
    if not targetModel or not targetModel.Parent then return end
    
    local crucifix = targetModel:FindFirstChild("Crucifix")
    if crucifix then
        crucifix:Destroy()
    end
end

local function playAudioOnce()
    if not cachedModel or not cachedModel.Parent then
        return
    end
    
    local sciFiSound
    local crucifixSound
    
    for _, descendant in ipairs(cachedModel:GetDescendants()) do
        if descendant:IsA("Sound") then
            if descendant.Name == "Hello Neighbor Scifi Sound Effect" then
                sciFiSound = descendant
            elseif descendant.Name == "doors crucifix" then
                crucifixSound = descendant
            end
        end
    end
    
    if sciFiSound then
        local sound1 = sciFiSound:Clone()
        sound1.Parent = workspace
        sound1:Play()
        
        sound1.Ended:Connect(function()
            if sound1 and sound1.Parent then
                sound1:Destroy()
            end
        end)
    end
    
    if crucifixSound then
        local sound2 = crucifixSound:Clone()
        sound2.Parent = workspace
        sound2:Play()
        
        sound2.Ended:Connect(function()
            if sound2 and sound2.Parent then
                sound2:Destroy()
            end
        end)
    end
end

local function loadModel()
    if loadedModel and loadedModel.Parent then
        loadedModel:Destroy()
        loadedModel = nil
    end
    
    local model = getModelFromCache()
    
    if model then
        playAudioOnce()
    end
    
    return model
end

local function fadeOutModel()
    if not loadedModel or not loadedModel.Parent then return end
    
    isFading = true
    local fadeDuration = 2
    local startTime = tick()
    
    while loadedModel and loadedModel.Parent and tick() - startTime < fadeDuration do
        local progress = (tick() - startTime) / fadeDuration
        
        for _, part in ipairs(loadedModel:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = progress
            elseif part:IsA("ParticleEmitter") then
                part.Rate = part.Rate * (1 - progress)
            elseif part:IsA("Beam") then
                part.Transparency = NumberSequence.new(progress)
            end
        end
        
        RunService.Heartbeat:Wait()
    end
    
    if loadedModel and loadedModel.Parent then
        loadedModel:Destroy()
        loadedModel = nil
    end
    
    isFading = false
    isProcessing = false
    
    if anchorPart and anchorPart.Parent then
        anchorPart:Destroy()
        anchorPart = nil
    end
    
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    
    delay(0.5, function()
        if cachedModel and cachedModel.Parent then
            cachedModel:Destroy()
            cachedModel = nil
        end
    end)
end

local function followTarget()
    if not anchorPart or not anchorPart.Parent or not loadedModel or not loadedModel.Parent then
        isFollowing = false
        return
    end
    
    isFollowing = true
    loadedModel:PivotTo(anchorPart.CFrame)
    fadeStartTime = tick()
    
    while isFollowing and anchorPart and anchorPart.Parent and loadedModel and loadedModel.Parent do
        RunService.Heartbeat:Wait()
        
        loadedModel:PivotTo(anchorPart.CFrame)
        
        if not isFading and tick() - fadeStartTime >= 8 then
            fadeOutModel()
        end
    end
end

local function processTarget()
    if isProcessing or processedModels[targetModel] then
        return
    end
    
    local entity = targetModel:FindFirstChild("Entity")
    if not entity then
        return
    end
    
    processedModels[targetModel] = true
    isProcessing = true
    isFollowing = false
    isFading = false
    fadeStartTime = nil
    
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    
    if loadedModel and loadedModel.Parent then
        loadedModel:Destroy()
        loadedModel = nil
    end
    
    if anchorPart and anchorPart.Parent then
        anchorPart:Destroy()
        anchorPart = nil
    end
    
    if not targetModel or not targetModel.Parent or not targetModel:IsA("Model") then
        processedModels[targetModel] = nil
        isProcessing = false
        return
    end
    deleteTargetParts()
    anchorPart = createAnchorAtEntity()
    if not anchorPart then
        processedModels[targetModel] = nil
        isProcessing = false
        return
    end
    loadedModel = loadModel()
    if not loadedModel then
        anchorPart:Destroy()
        anchorPart = nil
        processedModels[targetModel] = nil
        isProcessing = false
        return
    end
    local conn1 = targetModel.AncestryChanged:Connect(function(_, parent)
        if not parent then
            isFollowing = false
            if loadedModel and loadedModel.Parent then
                loadedModel:Destroy()
                loadedModel = nil
            end
            if anchorPart and anchorPart.Parent then
                anchorPart:Destroy()
                anchorPart = nil
            end
        end
    end)
    local conn2 = loadedModel.AncestryChanged:Connect(function(_, parent)
        if not parent then
            isFollowing = false
            loadedModel = nil
        end
    end)
    local conn3 = anchorPart.AncestryChanged:Connect(function(_, parent)
        if not parent then
            isFollowing = false
            anchorPart = nil
        end
    end)
    table.insert(connections, conn1)
    table.insert(connections, conn2)
    table.insert(connections, conn3)
    coroutine.wrap(followTarget)()
end
workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "Entity" then
        local model = descendant.Parent
        if model and model.Name == targetName and model:IsA("Model") and not processedModels[model] and not isProcessing then
            wait(0.1)
            targetModel = model
            processTarget()
        end
    end
    if descendant.Name == targetName and descendant:IsA("Model") and not processedModels[descendant] and not isProcessing then
        wait(0.2)
        local entity = descendant:FindFirstChild("Entity")
        if entity then
            targetModel = descendant
            processTarget()
        end
    end
end)
local preloadSuccess = pcall(preloadModel)
if not preloadSuccess or not cachedModel then
    return
end
wait(2)
end

function entityBehaviors.Muffler1()
function GetRoom()
    return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
end

local function LoadCustomInstance(source)
    local model
    
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    
    return model
end

local s = LoadCustomInstance(113018476110287)
if not s then
    return
end

local targetCFrame
local isModel = s:IsA("Model")
local entityPart

if isModel then
    local room = GetRoom()
    if not room then
        return
    end
    
    local roomEntrance = room:WaitForChild("RoomEntrance")
    targetCFrame = roomEntrance.CFrame * CFrame.new(0, -13, -25)
    local roomBaseY = roomEntrance.Position.Y
    
    if s.PrimaryPart then
        s:SetPrimaryPartCFrame(targetCFrame + Vector3.new(0, 15, 0))
    else
        local primary = s:FindFirstChildWhichIsA("BasePart")
        if primary then
            s.PrimaryPart = primary
            s:SetPrimaryPartCFrame(targetCFrame + Vector3.new(0, 15, 0))
        end
    end
    entityPart = s.PrimaryPart
else
    entityPart = s:FindFirstChildWhichIsA("BasePart")
    if entityPart then
        local room = GetRoom()
        if not room then
            return
        end
        
        local roomEntrance = room:WaitForChild("RoomEntrance")
        targetCFrame = roomEntrance.CFrame * CFrame.new(0, -13, -25)
        local roomBaseY = roomEntrance.Position.Y
        
        entityPart.CFrame = targetCFrame + Vector3.new(0, 15, 0)
        if entityPart:FindFirstChild("Part") then
            entityPart.Part.CFrame = entityPart.CFrame
        end
    end
end

if not targetCFrame or not entityPart then
    return
end

local countdownEnded = false
local roomChanged = false
local startY = targetCFrame.Y + 15
local targetY = targetCFrame.Y + 3
local dropDuration = 3
local dropStartTime = tick()

spawn(function()
    while not roomChanged do
        local elapsedTime = tick() - dropStartTime
        local progress = math.min(elapsedTime / dropDuration, 1)
        local currentY = startY + (targetY - startY) * (progress * progress * (3 - 2 * progress))
        
        if isModel and s.PrimaryPart then
            local pos = targetCFrame.Position
            s:SetPrimaryPartCFrame(CFrame.new(pos.X, currentY, pos.Z))
        elseif entityPart then
            local pos = targetCFrame.Position
            entityPart.CFrame = CFrame.new(pos.X, currentY, pos.Z)
        end
        
        if progress >= 1 then
            break
        end
        
        game:GetService("RunService").Heartbeat:Wait()
    end
end)

end
function entityBehaviors.HUNGERCUR()
local Hunger = workspace:FindFirstChild("Hunger")
if Hunger and Hunger:IsA("Model") then
    local HungerPos = Hunger.PrimaryPart and Hunger.PrimaryPart.Position or Hunger:GetPivot().Position
    Hunger:Destroy()
    
    local model
    pcall(function()
        model = game:GetObjects("rbxassetid://75267288948071")[1]
    end)
    
    if model and model:IsA("Model") then
        model.Parent = workspace
        model:PivotTo(CFrame.new(HungerPos + Vector3.new(0, 6, 0)))
        
        local explosionCameraShaker = require(game.ReplicatedStorage.CameraShaker)
        local explosionCam = workspace.CurrentCamera
        local explosionCamShake = explosionCameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
            explosionCam.CFrame = explosionCam.CFrame * shakeCf
        end)
        explosionCamShake:Start()
        explosionCamShake:ShakeOnce(10, 100, 0.1, 8, 10, 1)
        
        task.wait(6)
        require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("一个杂碎已经被我清除",true)
        local beams = {}
        local emitters = {}
        local meshes = {}
        
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Beam") then
                table.insert(beams, obj)
            elseif obj:IsA("ParticleEmitter") then
                table.insert(emitters, obj)
            elseif obj:IsA("MeshPart") then
                table.insert(meshes, obj)
            end
        end
        
        local startTime = tick()
        local duration = 1
        
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local alpha = elapsed / duration
            
            for _, beam in ipairs(beams) do
                beam.Transparency = NumberSequence.new(alpha)
            end
            
            for _, emitter in ipairs(emitters) do
                emitter.Transparency = NumberSequence.new(alpha)
            end
            
            for _, mesh in ipairs(meshes) do
                mesh.Transparency = alpha
            end
            
            task.wait()
        end
        
        for _, beam in ipairs(beams) do
            beam.Transparency = NumberSequence.new(1)
        end
        
        for _, emitter in ipairs(emitters) do
            emitter.Transparency = NumberSequence.new(1)
        end
        
        for _, mesh in ipairs(meshes) do
            mesh.Transparency = 1
        end
        
        task.wait(0.5)
        model:Destroy()
    end
end
end

function entityBehaviors.RIPPCUR()
local rushNew = workspace:FindFirstChild("RushNew")
if rushNew and rushNew:IsA("BasePart") then
    local rushNewPos = rushNew.Position
    rushNew:Destroy()
    
    local model
    pcall(function()
        model = game:GetObjects("rbxassetid://70558624002937")[1]
    end)
    
    if model and model:IsA("Model") then
        model.Parent = workspace
        model:PivotTo(CFrame.new(rushNewPos + Vector3.new(0, 8, 0)))
        
        local explosionCameraShaker = require(game.ReplicatedStorage.CameraShaker)
        local explosionCam = workspace.CurrentCamera
        local explosionCamShake = explosionCameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
            explosionCam.CFrame = explosionCam.CFrame * shakeCf
        end)
        explosionCamShake:Start()
        explosionCamShake:ShakeOnce(10, 100, 0.1, 8, 10, 1)
        
        task.wait(8)
        
        local beams = {}
        local emitters = {}
        local meshes = {}
        
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Beam") then
                table.insert(beams, obj)
            elseif obj:IsA("ParticleEmitter") then
                table.insert(emitters, obj)
            elseif obj:IsA("MeshPart") then
                table.insert(meshes, obj)
            end
        end
        
        local startTime = tick()
        local duration = 1
        
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local alpha = elapsed / duration
            
            for _, beam in ipairs(beams) do
                beam.Transparency = NumberSequence.new(alpha)
            end
            
            for _, emitter in ipairs(emitters) do
                emitter.Transparency = NumberSequence.new(alpha)
            end
            
            for _, mesh in ipairs(meshes) do
                mesh.Transparency = alpha
            end
            
            task.wait()
        end
        
        for _, beam in ipairs(beams) do
            beam.Transparency = NumberSequence.new(1)
        end
        
        for _, emitter in ipairs(emitters) do
            emitter.Transparency = NumberSequence.new(1)
        end
        
        for _, mesh in ipairs(meshes) do
            mesh.Transparency = 1
        end
        
        task.wait(0.5)
        model:Destroy()
    end
end
end

function entityBehaviors.DEERCUR()
local DeerGod = workspace:FindFirstChild("DeerGod")
if DeerGod and DeerGod:IsA("Model") then
    local DeerGodPos = DeerGod.PrimaryPart and DeerGod.PrimaryPart.Position or DeerGod:GetPivot().Position
    DeerGod:Destroy()
    
    local model
    pcall(function()
        model = game:GetObjects("rbxassetid://95232410623518")[1]
    end)
    
    if model and model:IsA("Model") then
        model.Parent = workspace
        model:PivotTo(CFrame.new(DeerGodPos + Vector3.new(0, 7, 0)))
        
        local explosionCameraShaker = require(game.ReplicatedStorage.CameraShaker)
        local explosionCam = workspace.CurrentCamera
        local explosionCamShake = explosionCameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
            explosionCam.CFrame = explosionCam.CFrame * shakeCf
        end)
        explosionCamShake:Start()
        explosionCamShake:ShakeOnce(10, 100, 0.1, 8, 10, 1)
        
        task.wait(7)
        require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("你不该呆在这里",true)
        local beams = {}
        local emitters = {}
        local meshes = {}
        
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Beam") then
                table.insert(beams, obj)
            elseif obj:IsA("ParticleEmitter") then
                table.insert(emitters, obj)
            elseif obj:IsA("MeshPart") then
                table.insert(meshes, obj)
            end
        end
        
        local startTime = tick()
        local duration = 1
        
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local alpha = elapsed / duration
            
            for _, beam in ipairs(beams) do
                beam.Transparency = NumberSequence.new(alpha)
            end
            
            for _, emitter in ipairs(emitters) do
                emitter.Transparency = NumberSequence.new(alpha)
            end
            
            for _, mesh in ipairs(meshes) do
                mesh.Transparency = alpha
            end
            
            task.wait()
        end
        
        for _, beam in ipairs(beams) do
            beam.Transparency = NumberSequence.new(1)
        end
        
        for _, emitter in ipairs(emitters) do
            emitter.Transparency = NumberSequence.new(1)
        end
        
        for _, mesh in ipairs(meshes) do
            mesh.Transparency = 1
        end
        
        task.wait(0.5)
        model:Destroy()
    end
end
end
function entityBehaviors.REBOUCUR()
local Rebound = workspace:FindFirstChild("Rebound")
if Rebound and Rebound:IsA("Model") then
    local ReboundPos

    local primaryPart = Rebound.PrimaryPart
    if not primaryPart then
        primaryPart = Rebound:FindFirstChildWhichIsA("BasePart")
    end
    
    if primaryPart then
        ReboundPos = primaryPart.Position
    else
        ReboundPos = Rebound:GetPivot().Position
    end
    
    Rebound:Destroy()
    
    local model
    pcall(function()
        model = game:GetObjects("rbxassetid://79375225577662")[1]
    end)
    
    if model and model:IsA("Model") then
        model.Parent = workspace

        local newPrimaryPart = model.PrimaryPart
        if not newPrimaryPart then
            newPrimaryPart = model:FindFirstChildWhichIsA("BasePart")
        end
        
        if newPrimaryPart then
            newPrimaryPart.Anchored = true
            newPrimaryPart.CanCollide = false
            newPrimaryPart.CFrame = CFrame.new(ReboundPos + Vector3.new(0, 6, 0))
        else
            model:PivotTo(CFrame.new(ReboundPos + Vector3.new(0, 5.7, 0)))
        end
        
        local explosionCameraShaker = require(game.ReplicatedStorage.CameraShaker)
        local explosionCam = workspace.CurrentCamera
        local explosionCamShake = explosionCameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
            explosionCam.CFrame = explosionCam.CFrame * shakeCf
        end)
        explosionCamShake:Start()
        explosionCamShake:ShakeOnce(10, 100, 0.1, 8, 10, 1)
        
        task.wait(7)
        require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("一个杂碎已经被我清除",true)
        
        local beams = {}
        local emitters = {}
        
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Beam") then
                table.insert(beams, obj)
            elseif obj:IsA("ParticleEmitter") then
                table.insert(emitters, obj)
            end
        end
        
        local startTime = tick()
        local duration = 1
        
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local alpha = elapsed / duration
            
            for _, beam in ipairs(beams) do
                beam.Transparency = NumberSequence.new(alpha)
            end
            
            for _, emitter in ipairs(emitters) do
                emitter.Transparency = NumberSequence.new(alpha)
            end
            
            task.wait()
        end
        
        for _, beam in ipairs(beams) do
            beam.Transparency = NumberSequence.new(1)
        end
        
        for _, emitter in ipairs(emitters) do
            emitter.Transparency = NumberSequence.new(1)
        end
        
        task.wait(0.5)
        model:Destroy()
    end
end
end
local function PreloadDeerGodSounds()
    if workspace:FindFirstChild("DeerGod_Preloaded") then
        return
    end
    
    local function DownloadAndStoreSound(url, soundName)
        local fullFileName = soundName .. ".mp3"
        local success, audioData = pcall(function()
            return game:HttpGet(url)
        end)
        
        if not success then
            return nil
        end

        local writeSuccess = pcall(function()
            writefile(fullFileName, audioData)
        end)
        
        if not writeSuccess then
            return nil
        end

        local assetPath
        if getsynasset then
            assetPath = getsynasset(fullFileName)
        elseif getcustomasset then
            assetPath = getcustomasset(fullFileName)
        end
        
        if not assetPath then
            return nil
        end

        local sound = Instance.new("Sound")
        sound.SoundId = assetPath
        sound.Name = soundName .. "_Preloaded"
        sound.Parent = workspace
        sound.Volume = 0
        sound:Play()
        sound:Stop()
        
        return sound
    end

    if dgmusic then
        DownloadAndStoreSound(dgmusic, "DeerGod")
    end
end

PreloadDeerGodSounds()

local function PlayPreloadedDeerGodSound(volume)
    volume = volume or 4
    local sound = workspace:FindFirstChild("DeerGod_Preloaded")
    
    if sound then
        sound.Volume = volume
        sound:Play()
        return sound
    end
    return nil
end

function entityBehaviors.SHOOPFY()
local Following_ENEMY = workspace:FindFirstChild("Following_ENEMY")
if Following_ENEMY and Following_ENEMY:IsA("Model") then
    local Following_ENEMYPos = Following_ENEMY.PrimaryPart and Following_ENEMY.PrimaryPart.Position or Following_ENEMY:GetPivot().Position
    Following_ENEMY:Destroy()
    
    local model
    pcall(function()
        model = game:GetObjects("rbxassetid://102643619785276")[1]
    end)
    
    if model and model:IsA("Model") then
        model.Parent = workspace
        model:PivotTo(CFrame.new(Following_ENEMYPos + Vector3.new(0, 4.3, 0)))
        
        local explosionCameraShaker = require(game.ReplicatedStorage.CameraShaker)
        local explosionCam = workspace.CurrentCamera
        local explosionCamShake = explosionCameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
            explosionCam.CFrame = explosionCam.CFrame * shakeCf
        end)
        explosionCamShake:Start()
        explosionCamShake:ShakeOnce(10, 100, 0.1, 8, 10, 1)
        
        task.wait(7)
        require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("你不该呆在这里",true)
        local beams = {}
        local emitters = {}
        local meshes = {}
        
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Beam") then
                table.insert(beams, obj)
            elseif obj:IsA("ParticleEmitter") then
                table.insert(emitters, obj)
            elseif obj:IsA("MeshPart") then
                table.insert(meshes, obj)
            end
        end
        
        local startTime = tick()
        local duration = 1
        
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local alpha = elapsed / duration
            
            for _, beam in ipairs(beams) do
                beam.Transparency = NumberSequence.new(alpha)
            end
            
            for _, emitter in ipairs(emitters) do
                emitter.Transparency = NumberSequence.new(alpha)
            end
            
            for _, mesh in ipairs(meshes) do
                mesh.Transparency = alpha
            end
            
            task.wait()
        end
        
        for _, beam in ipairs(beams) do
            beam.Transparency = NumberSequence.new(1)
        end
        
        for _, emitter in ipairs(emitters) do
            emitter.Transparency = NumberSequence.new(1)
        end
        
        for _, mesh in ipairs(meshes) do
            mesh.Transparency = 1
        end
        
        task.wait(0.5)
        model:Destroy()
    end
end
end
function entityBehaviors.JEFFXZ()
local workspace = game:GetService("Workspace")
local jeff = workspace:FindFirstChild("JeffTheKiller")
if not jeff then
    return
end
local jeffPart
if jeff:IsA("Model") and jeff.PrimaryPart then
    jeffPart = jeff.PrimaryPart
elseif jeff:IsA("BasePart") then
    jeffPart = jeff
else

    for _, descendant in ipairs(jeff:GetDescendants()) do
        if descendant:IsA("BasePart") then
            jeffPart = descendant
            break
        end
    end
end

if not jeffPart then

    return
end
jeffPart.Anchored = true
jeffPart.CanCollide = false
local rotationSpeed = 20 
local rotationAxis = Vector3.new(1, 1, 0)  
local RunService = game:GetService("RunService")

local function rotateJeff()
    local rotationPerFrame = rotationSpeed * math.pi / 180

    local rotationCFrame = CFrame.Angles(0, rotationPerFrame, 0)
    jeffPart.CFrame = jeffPart.CFrame * rotationCFrame
end
local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
    rotateJeff()
end)
local function stopRotation()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end
end


function entityBehaviors.JEFFZR()
local workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local jeff = workspace:FindFirstChild("JeffTheKiller")
if not jeff then
    return
end
local jeffPart
if jeff:IsA("Model") and jeff.PrimaryPart then
    jeffPart = jeff.PrimaryPart
elseif jeff:IsA("BasePart") then
    jeffPart = jeff
else
    for _, descendant in ipairs(jeff:GetDescendants()) do
        if descendant:IsA("BasePart") then
            jeffPart = descendant
            break
        end
    end
end
if not jeffPart then

    return
end
jeffPart.Anchored = false
jeffPart.CanCollide = true
local chaseSpeed = 25
local detectionRange = 200 
local stoppingDistance = 3  
local chaseUpdateInterval = 0.1
local currentTarget = nil
local lastChaseTime = 0
local function findNearestPlayer()
    local nearestPlayer = nil
    local nearestDistance = detectionRange
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local distance = (character.HumanoidRootPart.Position - jeffPart.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end
    
    return nearestPlayer, nearestDistance
end
local function moveToTarget(targetPosition)
    local direction = (targetPosition - jeffPart.Position).Unit
    local newPosition = jeffPart.Position + (direction * chaseSpeed * chaseUpdateInterval)

    jeffPart.CFrame = CFrame.new(newPosition) * jeffPart.CFrame.Rotation

    local lookAtCFrame = CFrame.new(jeffPart.Position, Vector3.new(targetPosition.X, jeffPart.Position.Y, targetPosition.Z))
    jeffPart.CFrame = CFrame.new(jeffPart.Position) * lookAtCFrame.Rotation
end
local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
    lastChaseTime = lastChaseTime + deltaTime
    
    if lastChaseTime >= chaseUpdateInterval then
        lastChaseTime = 0

        local targetPlayer, distance = findNearestPlayer()
        
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            currentTarget = targetPlayer
            local targetPosition = targetPlayer.Character.HumanoidRootPart.Position

            if distance > stoppingDistance then

                moveToTarget(targetPosition)
            else

            end
        else
            currentTarget = nil
        end
    end
end)
local function onPlayerDied(player)
    if currentTarget == player then
        currentTarget = nil
    end
end
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.Died:Connect(function()
                onPlayerDied(player)
            end)
        end
    end)
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                onPlayerDied(player)
            end)
        end
    end
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.Died:Connect(function()
                onPlayerDied(player)
            end)
        end
    end)
end)
local function stopChase()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    currentTarget = nil
    jeffPart.Anchored = true
end
local chaseController = {
    stop = stopChase,
    setSpeed = function(newSpeed)
        chaseSpeed = newSpeed
    end,
    setRange = function(newRange)
        detectionRange = newRange
    end,
    getStatus = function()
        return {
            isChasing = currentTarget ~= nil,
            target = currentTarget and currentTarget.Name or "无",
            speed = chaseSpeed,
            range = detectionRange
        }
    end
}
end

function entityBehaviors.TOUSHI()
    local Workspace = game:GetService("Workspace")
    local CurrentRooms = Workspace:WaitForChild("CurrentRooms")

    if not _G.KeyDoorHighlightState then
        _G.KeyDoorHighlightState = {
            isEnabled = false,
            highlights = {},
            connections = {},
            currentRoomCount = 0
        }
    end
    
    local state = _G.KeyDoorHighlightState

    local function findKeyParts(model)
        if not model or not model:IsA("Model") then
            return {}
        end
        
        local keyParts = {}
        
        for _, child in pairs(model:GetDescendants()) do
            if child:IsA("BasePart") and child.Transparency < 1 then
                table.insert(keyParts, child)
            end
        end
        
        return keyParts
    end

    local function findDoorPart(door)
        if not door then return nil end
        
        if door:IsA("BasePart") then
            return door
        end
        
        if door:IsA("Model") then
            if door.PrimaryPart and door.PrimaryPart:IsA("BasePart") then
                return door.PrimaryPart
            end
            
            for _, child in pairs(door:GetDescendants()) do
                if child:IsA("BasePart") and child.Transparency < 1 then
                    return child
                end
            end
        end
        
        return nil
    end

    local function createHighlight(target, name)
        if not target or not target:IsA("BasePart") then
            return nil
        end

        if target:FindFirstChild(name .. "Highlight") then
            return target:FindFirstChild(name .. "Highlight")
        end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = name .. "Highlight"
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.3
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = target
        highlight.Parent = target
        
        state.highlights[highlight] = true
        return highlight
    end

    local function scanAndHighlightAll()
        for _, room in pairs(CurrentRooms:GetChildren()) do
            if room:IsA("Model") then

                local assets = room:FindFirstChild("Assets")
                if assets then
                    local keyObtain = assets:FindFirstChild("KeyObtain")
                    if keyObtain then
                        local keyParts = findKeyParts(keyObtain)
                        for _, part in ipairs(keyParts) do
                            createHighlight(part, "Key")
                        end
                    end
                end

                local door = room:FindFirstChild("Door")
                if door then
                    local doorPart = findDoorPart(door)
                    if doorPart then
                        createHighlight(doorPart, "Door")
                    end
                end
            end
        end
    end

    local function startMonitoring()

        local roomAddedConnection = CurrentRooms.ChildAdded:Connect(function(room)
            if state.isEnabled and room:IsA("Model") then
                task.wait(0.3)

                local assets = room:FindFirstChild("Assets")
                if assets then
                    local keyObtain = assets:FindFirstChild("KeyObtain")
                    if keyObtain then
                        local keyParts = findKeyParts(keyObtain)
                        for _, part in ipairs(keyParts) do
                            createHighlight(part, "Key")
                        end
                    end
                end

                local door = room:FindFirstChild("Door")
                if door then
                    local doorPart = findDoorPart(door)
                    if doorPart then
                        createHighlight(doorPart, "Door")
                    end
                end
            end
        end)
        
        table.insert(state.connections, roomAddedConnection)

        for _, room in pairs(CurrentRooms:GetChildren()) do
            if room:IsA("Model") then

                local assetsConnection
                assetsConnection = room:GetPropertyChangedSignal("Assets"):Connect(function()
                    if state.isEnabled and room:FindFirstChild("Assets") then
                        local assets = room.Assets
                        task.wait(0.1)
                        
                        local keyObtain = assets:FindFirstChild("KeyObtain")
                        if keyObtain then
                            task.wait(0.1)
                            local keyParts = findKeyParts(keyObtain)
                            for _, part in ipairs(keyParts) do
                                createHighlight(part, "Key")
                            end
                        end
                    end
                end)
                
                table.insert(state.connections, assetsConnection)

                local doorConnection
                doorConnection = room:GetPropertyChangedSignal("Door"):Connect(function()
                    if state.isEnabled and room:FindFirstChild("Door") then
                        local door = room.Door
                        local doorPart = findDoorPart(door)
                        if doorPart then
                            createHighlight(doorPart, "Door")
                        end
                    end
                end)
                
                table.insert(state.connections, doorConnection)
            end
        end
    end

    local function cleanupAll()
        for highlight, _ in pairs(state.highlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        state.highlights = {}

        for _, connection in ipairs(state.connections) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
        state.connections = {}
        
        state.isEnabled = false
        state.currentRoomCount = 0
    end

    if state.isEnabled then
        cleanupAll()
    else
        state.isEnabled = true
        scanAndHighlightAll()
        startMonitoring()
    end
end

function entityBehaviors.MR()
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
    local function createBeamFadeTween(beam)
    if not beam or not beam:IsA("Beam") then
        return
    end

    local colorValue = Instance.new("Color3Value")
    colorValue.Value = beam.Color.Keypoints[1].Value

    local connection
    connection = colorValue.Changed:Connect(function(value)
        if beam and beam.Parent then
            beam.Color = ColorSequence.new(value)
        elseif connection then
            connection:Disconnect()
        end
    end)

    local tween = TweenService:Create(
        colorValue,
        fadeInfo,
        {
            Value = targetColor
        }
    )

    tween.Completed:Connect(function()
        if connection then
            connection:Disconnect()
        end

        if beam and beam.Parent then
            beam.Color = ColorSequence.new(targetColor)
        end

        colorValue:Destroy()
    end)

    tween:Play()
end

    local function modifyObjectsWithTween()
        local currentRooms = workspace:FindFirstChild("CurrentRooms")

        if not currentRooms then
            return
        end

        for _, room in ipairs(currentRooms:GetChildren()) do
            if room:IsA("Model") then
                local assets = room:FindFirstChild("Assets")

                if assets then
                    for _, chandelier in ipairs(assets:GetChildren()) do
                        if chandelier:IsA("Model")
                            and chandelier.Name == "Chandelier"
                        then
                            local lightFixture =
                                chandelier:FindFirstChild("LightFixture")

                            if lightFixture then
                                local pointLight =
                                    lightFixture:FindFirstChild("PointLight")

                                local spotLight =
                                    lightFixture:FindFirstChild("SpotLight")

                                local neon =
                                    lightFixture:FindFirstChild("Neon")

                                if pointLight
                                    and pointLight:IsA("PointLight")
                                then
                                    createFadeTween(pointLight)
                                end

                                if spotLight
                                    and spotLight:IsA("SpotLight")
                                then
                                    createFadeTween(spotLight)
                                end

                                if neon and neon:IsA("BasePart") then
                                    createFadeTween(neon)
                                end
                            end
                        end
                    end
                    local lightFixturesNew = assets:FindFirstChild("Light_Fixtures")

if lightFixturesNew then
    for _, lightStand in ipairs(lightFixturesNew:GetChildren()) do
        if lightStand:IsA("Model") and lightStand.Name == "LightStand" then
            for _, lightFixture in ipairs(lightStand:GetChildren()) do
                if lightFixture.Name == "LightFixture" then
                    for _, loadedLight in ipairs(lightFixture:GetChildren()) do
                        if loadedLight.Name == "LoadedLight_New" then
                            for _, atachm in ipairs(loadedLight:GetDescendants()) do
                                if atachm.Name == "atachm" then
                                    for _, newLight in ipairs(atachm:GetChildren()) do
                                        if newLight.Name == "Ok you cannot tell me this isnt good" then
                                            if newLight:IsA("BasePart") or newLight:IsA("Light") then
                                                createFadeTween(newLight)
                                            elseif newLight:IsA("Beam") then
                                                createBeamFadeTween(newLight)
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
    end
end

for _, loadedChandelier in ipairs(assets:GetChildren()) do
    if loadedChandelier.Name == "LoadedChandelier_New" then
        for _, lightFixture in ipairs(loadedChandelier:GetChildren()) do
            if lightFixture.Name == "LightFixture" then
                for _, neon in ipairs(lightFixture:GetChildren()) do
                    if neon.Name == "Neon" then
                        for _, attachment in ipairs(neon:GetChildren()) do
                            if attachment.Name == "Attachment" then
                                for _, beam in ipairs(attachment:GetChildren()) do
                                    if beam.Name == "Beam" and beam:IsA("Beam") then
                                        createBeamFadeTween(beam)
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

                    local lightFixtures =
                        assets:FindFirstChild("Light_Fixtures")

                    if lightFixtures then
                        for _, lightStand in ipairs(
                            lightFixtures:GetChildren()
                        ) do
                            if lightStand:IsA("Model")
                                and lightStand.Name == "LightStand"
                            then
                                local lightFixture =
                                    lightStand:FindFirstChild(
                                        "LightFixture"
                                    )

                                if lightFixture then
                                    local pointLight =
                                        lightFixture:FindFirstChild(
                                            "PointLight"
                                        )

                                    local neon =
                                        lightFixture:FindFirstChild("Neon")

                                    if pointLight
                                        and pointLight:IsA("PointLight")
                                    then
                                        createFadeTween(pointLight)
                                    end

                                    if neon and neon:IsA("BasePart") then
                                        createFadeTween(neon)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    task.spawn(modifyObjectsWithTween)

    local ripper = nil
    local ripperAsset = nil
    local isRipperDespawning = false
    local hasAttackedPlayer = false
    local ripperIsMoving = false
    local ripperMoveCancelled = false

    local function StopRipperMovement()
        ripperMoveCancelled = true
        ripperIsMoving = false
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


    local function DamageRipperPlayer(playerChar)
        if hasAttackedPlayer or not playerChar then
            return
        end

        local player = Players:GetPlayerFromCharacter(playerChar)
        local humanoid = playerChar:FindFirstChildWhichIsA("Humanoid")
        if not player or not humanoid or humanoid.Health <= 0 then
            return
        end

        hasAttackedPlayer = true
        StopRipperMovement()

        local damage = 125
        if humanoid.Health <= damage then
            local gameStats = game.ReplicatedStorage:FindFirstChild("GameStats")

            if gameStats then
                local playerStat = gameStats:FindFirstChild("Player_" .. player.Name)

                if playerStat then
                    local total = playerStat:FindFirstChild("Total")

                    if total then
                        local deathCause = total:FindFirstChild("DeathCause")

                        if deathCause then
                            deathCause.Value = "Ripper"
                        end
                    end
                end
            end
        end

        humanoid:TakeDamage(damage)

        if ripper and ripper.Parent then
            ripper:Destroy()
        end

        if ripperAsset then
            ripperAsset:Destroy()
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

    local function moveRipperTo(targetCFrame, speedFactor)
        if hasAttackedPlayer or isRipperDespawning
            or not ripper or not ripper.Parent then
            return false
        end

        local movingRipper = ripper
        ripperMoveCancelled = false
        ripperIsMoving = true

        local startCFrame = movingRipper.CFrame
        local totalDistance = (startCFrame.Position - targetCFrame.Position).Magnitude
        local travelled = 0

        while not ripperMoveCancelled and not hasAttackedPlayer
             and not isRipperDespawning
            and ripper == movingRipper and movingRipper.Parent do
            local deltaTime = RunService.Heartbeat:Wait()

            if ripperMoveCancelled or hasAttackedPlayer
                or isRipperDespawning or ripper ~= movingRipper
                or not movingRipper.Parent then
                break
            end

            if totalDistance > 0.001 and travelled < totalDistance then
                travelled = math.min(
                    travelled + math.max(speedFactor, 0) * math.min(deltaTime, 0.1),
                    totalDistance
                )
                movingRipper.CFrame = startCFrame:Lerp(targetCFrame, travelled / totalDistance)
            else
                movingRipper.CFrame = targetCFrame
                travelled = totalDistance
            end

            if travelled >= totalDistance then
                ripperIsMoving = false
                return true
            end
        end

        ripperIsMoving = false
        return false
    end

    local function ExecuteRipperPathfinding()
        isRipperDespawning = false
        local RIPPER_MODEL_ID = "96664504057582"

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

        local heightOffset = Vector3.new(0, 1.3, 0)
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

                local shakerRipper = ripper
                task.spawn(function()
                    while shakerRipper and shakerRipper.Parent do
                        task.wait(0.25)
                    end

                    if cameraShaker then
                        pcall(function()
                            cameraShaker:Stop()
                        end)
                    end
                end)
            end
        end

        local lastProximityShake = 0

        task.spawn(function()
            while ripper
                and ripper.Parent

                and not hasAttackedPlayer
                and not isRipperDespawning
            do
                RunService.RenderStepped:Wait()

                if hasAttackedPlayer or isRipperDespawning
                    or not ripper or not ripper.Parent then
                    return
                end

                local visibleRipper = ripper
                local player = Players.LocalPlayer

                if player and player.Character then
                    local character = player.Character
                    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                    local rootPart = character:FindFirstChild("HumanoidRootPart")

                    if humanoid and rootPart and humanoid.Health > 0 then
                        local distance = (visibleRipper.Position - rootPart.Position).Magnitude

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

                        if distance <= 50 and not character:GetAttribute("Hiding") then
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                            raycastParams.FilterDescendantsInstances = { visibleRipper }

                            local targets = { rootPart }
                            for _, name in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso" }) do
                                local bodyPart = character:FindFirstChild(name)
                                if bodyPart and bodyPart:IsA("BasePart") then
                                    table.insert(targets, bodyPart)
                                end
                            end

                            for _, targetPart in ipairs(targets) do
                                local direction = targetPart.Position - visibleRipper.Position
                                local rayDistance = direction.Magnitude

                                if rayDistance > 0.001 and rayDistance <= 50 then
                                    local raycastResult = workspace:Raycast(
                                        visibleRipper.Position,
                                        direction,
                                        raycastParams
                                    )
                                    local hitCharacter = raycastResult
                                        and getCharacterFromRaycastHit(raycastResult.Instance)

                                    local hitsPlayer = hitCharacter == character

                                    if not hitsPlayer then
                                        local entryDistance = rayEntryDistanceToPart(
                                            visibleRipper.Position,
                                            direction.Unit,
                                            targetPart
                                        )
                                        if entryDistance
                                            and entryDistance <= rayDistance + 0.01
                                            and (not raycastResult
                                                or raycastResult.Distance > entryDistance + 0.02)
                                        then
                                            hitsPlayer = true
                                        end
                                    end

                                    if hitsPlayer then
                                        DamageRipperPlayer(character)
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)

        local targetRoomIndex =
            math.max(1, #orderedRooms - 1)

        local reachedFinalRoom = false
        local completedRoomIndex = 0

        for roomIndex = startRoomIndex, targetRoomIndex do
            if hasAttackedPlayer

                or isRipperDespawning
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
                    or hasAttackedPlayer

                    or isRipperDespawning
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
                        if hasAttackedPlayer

                            or isRipperDespawning
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


        if hasAttackedPlayer

            or not ripper
            or not ripper.Parent
        then
            ripper = nil
            ripperAsset = nil
            return
        end

        if hasAttackedPlayer then
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

        if hasAttackedPlayer or not ripper or not ripper.Parent then
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
                DamageRipperPlayer(character)
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

function entityBehaviors.MO()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local latestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")

local MODEL_ID = 120103250808971
local AMBIENT_ID = 137177653817621
local RANDOM_IDS = {119223589229162, 121719103873398, 87808103166511}
local HIT_ID = 87290118952161
local EXIT_ID = 73193010308245
local SPAWN_DISTANCE = 10
local HEIGHT_OFFSET = 2
local WAIT_BEFORE_MOVING = 3
local MOVE_DISTANCE = 45
local MOVE_DURATION = 0.8
local ATTACK_RANGE = 5
local LOOK_THRESHOLD = 0.75
local ROOM_CHANGES_TO_EXIT = 5
local FACE_YAW_OFFSET = math.rad(-90)

local function LoadCustomInstance(source)
    local success, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(source))[1]
    end)

    if not success or not result then
        return nil
    end

    for _, object in ipairs(result:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") then
            object:Destroy()
        end
    end

    result.Parent = workspace
    return result
end

local entity = LoadCustomInstance(MODEL_ID)

if not entity then
    return
end

local primary
if entity:IsA("Model") then
    primary = entity:FindFirstChild("RootPart", true)
    if not (primary and primary:IsA("BasePart")) then
        primary = entity.PrimaryPart or entity:FindFirstChildWhichIsA("BasePart", true)
    end
    if primary then
        entity.PrimaryPart = primary
    end
elseif entity:IsA("BasePart") then
    primary = entity
end

if not primary then
    entity:Destroy()
    return
end

for _, object in ipairs(entity:GetDescendants()) do
    if object:IsA("BasePart") then
        object.Anchored = true
        object.CanCollide = false
    end
end

if entity:IsA("BasePart") then
    entity.Anchored = true
    entity.CanCollide = false
end

local function GetPlayerRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart") or nil
end

local function GetLivingHumanoid()
    if player:GetAttribute("Alive") == false then
        return nil
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return humanoid
    end
    return nil
end

local function FacePlayerAt(position, targetPosition)
    local lookPosition = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
    if (lookPosition - position).Magnitude > 0.01 then
        entity:PivotTo(CFrame.lookAt(position, lookPosition) * CFrame.Angles(0, FACE_YAW_OFFSET, 0))
    else
        entity:PivotTo(CFrame.new(position) * entity:GetPivot().Rotation)
    end
end

local root = GetPlayerRoot()
local startBasis = root and root.CFrame or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame) or CFrame.new()
local spawnPosition = (startBasis * CFrame.new(0, HEIGHT_OFFSET, SPAWN_DISTANCE)).Position
FacePlayerAt(spawnPosition, root and root.Position or startBasis.Position)

local savedFogStart = Lighting.FogStart
local savedFogEnd = Lighting.FogEnd
local savedFogColor = Lighting.FogColor
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local createdAtmosphere = false
local originalAtmosphere

if atmosphere then
    originalAtmosphere = {
        Density = atmosphere.Density,
        Haze = atmosphere.Haze,
        Color = atmosphere.Color,
        Decay = atmosphere.Decay,
        Glare = atmosphere.Glare,
        Offset = atmosphere.Offset
    }
else
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "ShadowEntityFog"
    atmosphere.Parent = Lighting
    createdAtmosphere = true
end

Lighting.FogStart = 0
Lighting.FogEnd = 5
Lighting.FogColor = Color3.fromRGB(55, 58, 64)
atmosphere.Density = 1
atmosphere.Haze = 10
atmosphere.Glare = 0
atmosphere.Offset = 0
atmosphere.Color = Color3.fromRGB(72, 76, 83)
atmosphere.Decay = Color3.fromRGB(25, 27, 31)

local fogBlur = Instance.new("DepthOfFieldEffect")
fogBlur.Name = "ShadowEntityDenseFog"
fogBlur.FocusDistance = 2
fogBlur.InFocusRadius = 1
fogBlur.NearIntensity = 0
fogBlur.FarIntensity = 1
fogBlur.Parent = Lighting

local fogRestored = false
local function RestoreFog()
    if fogRestored then
        return
    end

    fogRestored = true
    Lighting.FogStart = savedFogStart
    Lighting.FogEnd = savedFogEnd
    Lighting.FogColor = savedFogColor

    if fogBlur and fogBlur.Parent then
        fogBlur:Destroy()
    end

    if atmosphere then
        if createdAtmosphere then
            atmosphere:Destroy()
        elseif atmosphere.Parent and originalAtmosphere then
            for property, value in pairs(originalAtmosphere) do
                atmosphere[property] = value
            end
        end
    end
end

local active = true
local completed = false
local roomChanges = 0
local roomConnection
local heartbeatConnection
local activeSounds = {}

local function MakeSound(id, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = parent or SoundService
    activeSounds[sound] = true
    return sound
end

local function InterruptibleWait(seconds)
    local elapsed = 0
    while active and elapsed < seconds do
        elapsed = elapsed + task.wait(math.min(0.1, seconds - elapsed))
    end
    return active
end

local function WaitUntilPlaybackEnds(sound, limit, shouldStop)
    local loadingStart = os.clock()
    while sound.Parent and not sound.IsLoaded and os.clock() - loadingStart < 6 do
        if shouldStop and not active then
            return
        end
        task.wait(0.1)
    end

    local startTime = os.clock()
    local duration = sound.TimeLength > 0 and sound.TimeLength + 1 or 8
    duration = math.min(duration, limit or 20)

    while sound.Parent and sound.IsPlaying and os.clock() - startTime < duration do
        if shouldStop and not active then
            return
        end
        task.wait(0.1)
    end
end

local function StopAllSounds()
    for sound in pairs(activeSounds) do
        activeSounds[sound] = nil
        if sound.Parent then
            sound:Stop()
            sound:Destroy()
        end
    end
end

local function PlayFinalSound(id)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(id)
    sound.Volume = 1
    sound.Looped = false
    sound.Parent = SoundService
    sound:Play()
    WaitUntilPlaybackEnds(sound, 20, false)
    sound:Stop()
    sound:Destroy()
end

local function Finish(id)
    if completed then
        return
    end

    completed = true
    active = false

    if roomConnection then
        roomConnection:Disconnect()
        roomConnection = nil
    end

    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end

    StopAllSounds()
    RestoreFog()

    task.spawn(function()
        PlayFinalSound(id)
        if entity and entity.Parent then
            entity:Destroy()
        end
    end)
end

roomConnection = latestRoom.Changed:Connect(function()
    if not active then
        return
    end

    roomChanges = roomChanges + 1
    if roomChanges >= ROOM_CHANGES_TO_EXIT then
        Finish(EXIT_ID)
    end
end)

task.spawn(function()
    local ambient = MakeSound(AMBIENT_ID, SoundService)

    while active do
        ambient:Play()
        WaitUntilPlaybackEnds(ambient, 30, true)
        if not active then
            break
        end
        ambient:Stop()
        if not InterruptibleWait(1) then
            break
        end
    end

    activeSounds[ambient] = nil
    if ambient.Parent then
        ambient:Destroy()
    end
end)

task.spawn(function()
    local previousIndex

    while active do
        local index = math.random(1, #RANDOM_IDS)
        if index == previousIndex and #RANDOM_IDS > 1 then
            index = (index % #RANDOM_IDS) + 1
        end
        previousIndex = index

        local sound = MakeSound(RANDOM_IDS[index], SoundService)
        sound:Play()
        WaitUntilPlaybackEnds(sound, 30, true)
        activeSounds[sound] = nil
        if sound.Parent then
            sound:Stop()
            sound:Destroy()
        end

        if not InterruptibleWait(5) then
            break
        end
    end
end)

local function IsLookingAtEntity()
    local camera = workspace.CurrentCamera
    if not camera or not primary.Parent then
        return false
    end

    local from = camera.CFrame.Position
    local toEntity = primary.Position - from

    if toEntity.Magnitude <= 0.01 then
        return true
    end

    if camera.CFrame.LookVector:Dot(toEntity.Unit) < LOOK_THRESHOLD then
        return false
    end

    local _, visible = camera:WorldToViewportPoint(primary.Position)
    if not visible then
        return false
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local character = player.Character
    params.FilterDescendantsInstances = character and {character} or {}

    local result = workspace:Raycast(from, toEntity, params)
    return not result or result.Instance:IsDescendantOf(entity)
end

local function CanHitPlayer()
    local character = player.Character
    local targetRoot = GetPlayerRoot()
    local humanoid = GetLivingHumanoid()
    if not character or not targetRoot or not humanoid then
        return nil
    end

    local origin = primary.Position
    local difference = targetRoot.Position - origin
    local distance = difference.Magnitude

    if distance > ATTACK_RANGE or distance < 0.01 then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {entity}
    params.IgnoreWater = true

    local hit = workspace:Raycast(origin, difference.Unit * ATTACK_RANGE, params)
    if hit and hit.Instance:IsDescendantOf(character) then
        return humanoid
    end
    return nil
end

local unnoticedTime = 0
local movement

heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
    if not active or not entity.Parent or not primary.Parent then
        return
    end

    local humanoid = GetLivingHumanoid()
    local targetRoot = GetPlayerRoot()

    if not humanoid or not targetRoot then
        unnoticedTime = 0
        movement = nil
        return
    end

    if IsLookingAtEntity() then
        unnoticedTime = 0
        movement = nil
    else
        if movement then
            movement.elapsed = movement.elapsed + dt
            local alpha = math.clamp(movement.elapsed / MOVE_DURATION, 0, 1)
            local eased = alpha * alpha * (3 - 2 * alpha)
            local position = movement.start:Lerp(movement.goal, eased)
            FacePlayerAt(position, targetRoot.Position)

            if alpha >= 1 then
                movement = nil
                unnoticedTime = 0
            end
        else
            unnoticedTime = unnoticedTime + dt
            if unnoticedTime >= WAIT_BEFORE_MOVING then
                unnoticedTime = 0
                local current = entity:GetPivot().Position
                local target = Vector3.new(targetRoot.Position.X, targetRoot.Position.Y + HEIGHT_OFFSET, targetRoot.Position.Z)
                local flatOffset = Vector3.new(target.X - current.X, 0, target.Z - current.Z)
                local travel = math.min(MOVE_DISTANCE, math.max(flatOffset.Magnitude - 1.5, 0))

                if travel > 0.01 then
                    local goal = current + flatOffset.Unit * travel
                    goal = Vector3.new(goal.X, target.Y, goal.Z)
                    movement = {start = current, goal = goal, elapsed = 0}
                    FacePlayerAt(current, targetRoot.Position)
                end
            end
        end
    end

    local hitHumanoid = CanHitPlayer()
    if hitHumanoid then
        hitHumanoid:TakeDamage(100)
        if hitHumanoid.Health <= 0 then
            player:SetAttribute("Alive", false)
        end
        Finish(HIT_ID)
    end
end)
end


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local NEAR_SOUND_DISTANCE = 115
local FAR_MAX_DISTANCE = 360
local FAR_MIN_VOLUME = 0.02
local MODEL_Y_OFFSET = -12
local SOUND_CONFIRM_TIME = 0.08

local hardCoreSound = workspace:WaitForChild("HardCoreSound")
local SilenceSound = hardCoreSound:WaitForChild("Silence")
SilenceSound.Volume = 5
SilenceSound.Looped = false

local SilenceFarSound = hardCoreSound:WaitForChild("SilenceFar")
SilenceFarSound.Volume = 1
SilenceFarSound.Looped = false

local player = Players.LocalPlayer

local function GetPlayerPosition()
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

local function GetDistance(position)
    return (GetPlayerPosition() - position).Magnitude
end

local function ResetSound(sound)
    sound:Stop()

    pcall(function()
        sound.TimePosition = 0
    end)
end

local function GetFarVolume(distance)
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

local function StopShake()
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

local function SilenceShake(entityPosition)
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    StopShake()

    shakeID += 1

    local bindName =
        "SilenceShake_" .. shakeID

    currentShake = bindName
    currentShakeOffset = CFrame.new()

    local distance =
        GetDistance(entityPosition)

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

local function TriggerJumpscare()
    if jumpscareActive or jumpscareFinished then
        return
    end

    jumpscareActive = true

    ResetSound(SilenceFarSound)
    ResetSound(SilenceSound)

    SilenceSound.Volume = 5
    SilenceSound:Play()

    StopShake()

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

local function IsRealPlayingSound(object)
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

local function CancelSoundConfirmation(sound)
    soundConfirmTokens[sound] =
        (soundConfirmTokens[sound] or 0) + 1
end

local function ConfirmPlayingSound(sound)
    if not nearSilence then
        return
    end

    if jumpscareActive or jumpscareFinished then
        return
    end

    if not IsRealPlayingSound(sound) then
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

            if not IsRealPlayingSound(sound) then
                return
            end

            task.spawn(
                TriggerJumpscare
            )
        end
    )
end

local function DisconnectWatchedSound(sound)
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

local function WatchSound(sound)
    if not sound:IsA("Sound") then
        return
    end

    DisconnectWatchedSound(sound)

    soundConnections[sound] = {}

    table.insert(
        soundConnections[sound],
        sound:GetPropertyChangedSignal(
            "Playing"
        ):Connect(function()
            if sound.Playing then
                ConfirmPlayingSound(sound)
            else
                CancelSoundConfirmation(sound)
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
                    CancelSoundConfirmation(sound)
                    DisconnectWatchedSound(sound)
                end
            end
        )
    )

    if sound.Playing then
        ConfirmPlayingSound(sound)
    end
end

local function StopSoundWatcher()
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
        CancelSoundConfirmation(sound)
        DisconnectWatchedSound(sound)
    end

    table.clear(
        soundConfirmTokens
    )
end

local function StartSoundWatcher()
    StopSoundWatcher()

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
            WatchSound(object)
        end
    end

    soundWatchConnection =
        character.DescendantAdded:Connect(
            function(object)
                if not nearSilence then
                    return
                end

                if object:IsA("Sound") then
                    WatchSound(object)
                end
            end
        )
end

local audioToken = 0

local function StartRoomAudio(
    entityPosition,
    totalDuration
)
    audioToken += 1

    local token =
        audioToken

    ResetSound(SilenceSound)
    ResetSound(SilenceFarSound)

    task.spawn(
        SilenceShake,
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
                GetDistance(
                    entityPosition
                )

            if distance <= NEAR_SOUND_DISTANCE then
                if currentMode ~= "near" then
                    ResetSound(
                        SilenceFarSound
                    )

                    ResetSound(
                        SilenceSound
                    )

                    SilenceSound.Volume =
                        5

                    SilenceSound:Play()

                    currentMode =
                        "near"
                end

                if not nearSilence then
                    StartSoundWatcher()
                end
            else
                if nearSilence then
                    StopSoundWatcher()
                end

                local farVolume =
                    GetFarVolume(
                        distance
                    )

                if currentMode ~= "far" then
                    ResetSound(
                        SilenceSound
                    )

                    ResetSound(
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
            StopSoundWatcher()
        end
    end)
end

function entityBehaviors.MS()
    jumpscareActive = false
    jumpscareFinished = false

    StopSoundWatcher()

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
            and number <= 100
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
            "rbxassetid://94655489412905"
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

    local function GetRoomSize(room)
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

    local function FindFloor(room)
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
                    GetRoomSize(room)
            end

            return
                target,
                GetRoomSize(room)
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

    local function PivotSilence(position)
        Silence:PivotTo(
            CFrame.new(position)
            * modelRotation
        )
    end

    local function MoveVertical(
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

            PivotSilence(
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

        PivotSilence(
            endPosition
        )

        return true
    end

    for _, data in ipairs(
        rooms
    ) do
        if jumpscareFinished then
            break
        end

        local floorPosition,
            roomSize =
            FindFloor(
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

        PivotSilence(
            upperPosition
        )

        StartRoomAudio(
            landingPosition,
            5.2
        )

        local moved =
            MoveVertical(
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
            MoveVertical(
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

    StopSoundWatcher()

    ResetSound(
        SilenceFarSound
    )

    if Silence and Silence.Parent then
        Silence:Destroy()
    end
end

function entityBehaviors.MM()
local entity = spawner.Create({Entity = {Name = "MultiMonster",Asset = "114092014360320",HeightOffset = 1},Lights = {Flicker = {Enabled = true,Duration = 0.1},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 40,Values = {50, 20, 0.5, 0.5}},Movement = {Speed = 400,Delay = 1,Reversed = false},Rebounding = {Enabled = true,Type = "Ambush",Min = 1,Max = 1},Damage = {Enabled = true,Range = 50,Amount = 125},Crucifixion = {Enabled = false,Range = 50,Resist = false,Break = true},Cause = "MultiMonster"})
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

function entityBehaviors.MC()
 
 local entity = spawner.Create({Entity = {Name = "Cease",Asset = "120103250808971",HeightOffset = 1},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 100,Delay = 5,Reversed = false},Rebounding = {Enabled = false,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},Damage = {Enabled = false,Range = 100,Amount = 125},Crucifixion = {Enabled = false,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"CEASE", "...", "...", "..."},Cause = "Cease"}}) 
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

entity:SetCallback("OnSpawned", function()
    task.spawn(function()
        local TweenService = game:GetService("TweenService")
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local SoundService = game:GetService("SoundService")
        local Debris = game:GetService("Debris")
        local blue = Color3.fromRGB(91, 113, 255)
        local fadeInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        local originals = {}

        local function fadeSequence(object, originalSequence, restoring)
            local progress = Instance.new("NumberValue")
            local connection = progress:GetPropertyChangedSignal("Value"):Connect(function()
                if not object.Parent then
                    return
                end
                local keypoints = {}
                for _, keypoint in ipairs(originalSequence.Keypoints) do
                    local color = restoring
                        and blue:Lerp(keypoint.Value, progress.Value)
                        or keypoint.Value:Lerp(blue, progress.Value)
                    table.insert(keypoints, ColorSequenceKeypoint.new(keypoint.Time, color))
                end
                object.Color = ColorSequence.new(keypoints)
            end)
            local tween = TweenService:Create(progress, fadeInfo, {Value = 1})
            tween.Completed:Connect(function()
                connection:Disconnect()
                if object.Parent then
                    object.Color = restoring and originalSequence or ColorSequence.new(blue)
                end
                progress:Destroy()
            end)
            tween:Play()
        end

        local function tint(object)
            if not object or originals[object] ~= nil then
                return
            end
            if object:IsA("BasePart") or object:IsA("Light") then
                originals[object] = object.Color
                TweenService:Create(object, fadeInfo, {Color = blue}):Play()
            elseif object:IsA("ParticleEmitter") or object:IsA("Beam") then
                originals[object] = object.Color
                fadeSequence(object, object.Color, false)
            end
        end

        local function tintFixture(fixture)
            if not fixture then
                return
            end
            tint(fixture:FindFirstChild("PointLight", true))
            tint(fixture:FindFirstChild("SpotLight", true))
            local neon = fixture:FindFirstChild("Neon", true)
            tint(neon)
            if not neon then
                return
            end
            local bright = neon:FindFirstChild("Bright sh idfk")
            local atachm = neon:FindFirstChild("atachm")
            local glow = neon:FindFirstChild("Glow")
            tint(bright and bright:FindFirstChild("ParticleEmitter"))
            tint(atachm and atachm:FindFirstChild("Ok you cannot tell me this isnt good"))
            tint(glow and glow:FindFirstChild("Beam"))
        end

        local rooms = workspace:FindFirstChild("CurrentRooms")
        if rooms then
            for _, room in ipairs(rooms:GetChildren()) do
                if room:IsA("Model") then
                    local assets = room:FindFirstChild("Assets")
                    if assets then
                        for _, item in ipairs(assets:GetChildren()) do
                            if item:IsA("Model") and item.Name == "Chandelier" then
                                tintFixture(item:FindFirstChild("LightFixture", true))
                            end
                        end
                        local lightFixtures = assets:FindFirstChild("Light_Fixtures")
                        if lightFixtures then
                            for _, item in ipairs(lightFixtures:GetChildren()) do
                                if item:IsA("Model") and item.Name == "LightStand" then
                                    tintFixture(item:FindFirstChild("LightFixture", true))
                                end
                            end
                        end
                    end
                end
            end
        end

        task.wait(5)

        for object, originalColor in pairs(originals) do
            if object.Parent then
                if typeof(originalColor) == "Color3" then
                    TweenService:Create(object, fadeInfo, {Color = originalColor}):Play()
                else
                    fadeSequence(object, originalColor, true)
                end
            end
        end

        local deadline = os.clock() + 9
        local damaged = false
        while os.clock() < deadline and not damaged do
            RunService.Heartbeat:Wait()
            local player = Players.LocalPlayer
            local character = player and player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and humanoid.MoveDirection.Magnitude > 0.05 then
                damaged = true
                local sound = Instance.new("Sound")
                sound.SoundId = "rbxassetid://115478216144558"
                sound.Volume = 2
                sound.Looped = false
                sound.Parent = SoundService
                sound.Ended:Connect(function()
                    sound:Destroy()
                end)
                Debris:AddItem(sound, 20)
                sound:Play()
                humanoid:TakeDamage(100)
            end
        end
    end)
end)

entity:Run()
end

function entityBehaviors.MT()
local damageCooldown = false

local function Damage1(Amount)
    if damageCooldown then
        return
    end

    damageCooldown = true

    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local DamageAmount = (Amount / 100) * Humanoid.MaxHealth
    local NewHealth = Humanoid.Health - DamageAmount
    if NewHealth <= 0 then
        local gameStats = game.ReplicatedStorage:FindFirstChild("GameStats")
        local playerStats = gameStats and gameStats:FindFirstChild("Player_" .. Player.Name)
        local total = playerStats and playerStats:FindFirstChild("Total")
        local deathCause = total and total:FindFirstChild("DeathCause")
        if deathCause then
            deathCause.Value = "MultiMonster"
        end
        Player:SetAttribute("Alive", false)
        replicatesignal(Player.Kill)
    else
        Humanoid.Health = NewHealth
    end

    task.delay(2, function()
        damageCooldown = false
    end)
end

local function LoadCustomInstance1(source)
    local model
    if tonumber(source) then
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(source))[1]
        end)
        if success and result then
            model = result
        end
    end
    if model then
        model.Parent = workspace
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
    end
    return model
end

local function MainExecution1()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
    end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end
    local chasingEntity = LoadCustomInstance1(90750780922717)
    if not chasingEntity then
        return
    end
    task.spawn(function()
        wait(30)
        if chasingEntity and chasingEntity.Parent then
            chasingEntity:Destroy()
        end
    end)
    local entityPart
    if chasingEntity:IsA("Model") then
        if chasingEntity.PrimaryPart then
            entityPart = chasingEntity.PrimaryPart
        else
            entityPart = chasingEntity:FindFirstChildWhichIsA("BasePart")
        end
    else
        entityPart = chasingEntity:FindFirstChildWhichIsA("BasePart")
    end
    if not entityPart then
        chasingEntity:Destroy()
        return
    end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    entityPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, 40)
    local function StartRaycastDamage1()
        while true do
            local char = player.Character
            if char then
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    local rayOrigin = Vector3.new(
                        math.random(-50, 50),
                        math.random(5, 20),
                        math.random(-50, 50)
                    )
                    local rayDirection = (char.HumanoidRootPart.Position - rayOrigin).Unit * 10
                    local raycastResult = workspace:Raycast(rayOrigin, rayDirection)
                    if raycastResult and raycastResult.Instance:IsDescendantOf(char) then
                        Damage1(90)
                        if chasingEntity and chasingEntity.Parent then
                            chasingEntity:Destroy()
                        end
                        break
                    end
                end
            end
            wait(0.5)
        end
    end
    local function SetupCollisionDetection1()
        if entityPart then
            entityPart.Touched:Connect(function(hit)
                local hitCharacter = hit:FindFirstAncestorWhichIsA("Model")
                if hitCharacter and hitCharacter == character then
                    if not character:GetAttribute("Hiding") then
                        Damage1(90)
                        if chasingEntity and chasingEntity.Parent then
                            chasingEntity:Destroy()
                        end
                    end
                end
            end)
        end
    end
    local function StartChasing1()
        local RunService = game:GetService("RunService")
        local chasingSpeed = 11
        local isChasing = true
        local detectionInterval = 0.5
        local lastDetectionTime = 0
        local chaseConnection
        chaseConnection = RunService.RenderStepped:Connect(function(deltaTime)
            if not isChasing or not chasingEntity or not chasingEntity.Parent then
                if chaseConnection then
                    chaseConnection:Disconnect()
                end
                return
            end
            local currentCharacter = player.Character
            if not currentCharacter then
                if chasingEntity and chasingEntity.Parent then
                    chasingEntity:Destroy()
                end
                isChasing = false
                if chaseConnection then
                    chaseConnection:Disconnect()
                end
                return
            end
            local currentHumanoid = currentCharacter:FindFirstChildWhichIsA("Humanoid")
            if not currentHumanoid or currentHumanoid.Health <= 0 then
                if chasingEntity and chasingEntity.Parent then
                    chasingEntity:Destroy()
                end
                isChasing = false
                if chaseConnection then
                    chaseConnection:Disconnect()
                end
                return
            end
            local target = currentCharacter.HumanoidRootPart
            if not target then
                return
            end
            local direction = (target.Position - entityPart.Position).Unit
            local moveVector = direction * chasingSpeed * deltaTime
            entityPart.Position = entityPart.Position + moveVector
            entityPart.CFrame = CFrame.lookAt(entityPart.Position, target.Position)
            local currentTime = tick()
            if currentTime - lastDetectionTime >= detectionInterval then
                lastDetectionTime = currentTime
                local rayOrigin = entityPart.Position
                local rayDirection = (target.Position - rayOrigin).Unit * 10
                local ray = Ray.new(rayOrigin, rayDirection)
                local hit = workspace:FindPartOnRay(ray, chasingEntity)
                if hit and hit:IsDescendantOf(currentCharacter) and not currentCharacter:GetAttribute("Hiding") then
                    isChasing = false
                    Damage1(90)
                    if chasingEntity and chasingEntity.Parent then
                        chasingEntity:Destroy()
                    end
                    if chaseConnection then
                        chaseConnection:Disconnect()
                    end
                end
            end
            local distance = (entityPart.Position - target.Position).Magnitude
            if distance < 2 then
                isChasing = false
                Damage1(90)
                if chasingEntity and chasingEntity.Parent then
                    chasingEntity:Destroy()
                end
                if chaseConnection then
                    chaseConnection:Disconnect()
                end
            end
        end)
        return chaseConnection
    end
    local function Cleanup1()
        if chasingEntity and chasingEntity.Parent then
            chasingEntity:Destroy()
        end
    end
    game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            Cleanup1()
        end
    end)
    humanoid.Died:Connect(function()
        Cleanup1()
    end)
    SetupCollisionDetection1()
    StartChasing1()
    task.spawn(StartRaycastDamage1)
end
MainExecution1()
end

function entityBehaviors.MD()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

if not RunService:IsClient() then
    return
end

if not player then
    return
end

local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
    return
end

local ENTITY_ASSET_ID = 96664504057582
local SPEED = 12
local CHASE_RANGE = 75
local HIT_RANGE = 10
local MAX_ROOMS = 15
local HEIGHT_OFFSET = Vector3.new(0, 2.4, 0)
local CAMERA_SHAKE_INTERVAL = 0.8
local CAMERA_SHAKE_MAX_DISTANCE = 300
local CAMERA_SHAKE_MIN_MAGNITUDE = 0.5
local CAMERA_SHAKE_MAX_MAGNITUDE = 5
local START_SEARCH_TIMEOUT = 25
local WAYPOINT_PASS_RADIUS = 3

local function loadModel(assetId, fallbackName)
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)
    if ok and type(objects) == "table" then
        for _, object in ipairs(objects) do
            if object:IsA("Model") then
                local children = object:GetChildren()
                if #children == 1 and children[1]:IsA("Model")
                    and not object:FindFirstChildWhichIsA("BasePart", true) then
                    local nested = children[1]
                    nested.Parent = nil
                    object:Destroy()
                    return nested
                end
                return object
            end
        end
    end

    local template = ReplicatedStorage:FindFirstChild(fallbackName, true)
    if template and template:IsA("Model") then
        return template:Clone()
    end

    local loaded, container = pcall(function()
        return InsertService:LoadAsset(assetId)
    end)
    if loaded and container and container:IsA("Model") then
        local children = container:GetChildren()
        if #children == 1 and children[1]:IsA("Model") then
            local nested = children[1]
            nested.Parent = nil
            container:Destroy()
            return nested
        end
        if container:FindFirstChildWhichIsA("BasePart", true) then
            return container
        end
        container:Destroy()
    end
    return nil
end

local function prepareModel(model)
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
        elseif object:IsA("Script") or object:IsA("LocalScript") then
            object.Disabled = true
        end
    end
    if not model.PrimaryPart then
        local primary = model:FindFirstChild("Main", true)
            or model:FindFirstChild("HumanoidRootPart", true)
            or model:FindFirstChildWhichIsA("BasePart", true)
        if primary and primary:IsA("BasePart") then
            model.PrimaryPart = primary
        end
    end
end

local function getRooms()
    local folder = Workspace:FindFirstChild("CurrentRooms")
    local result = {}
    if folder then
        for _, room in ipairs(folder:GetChildren()) do
            if room:IsA("Model") then
                local number = tonumber(room.Name)
                if number then
                    result[#result + 1] = { Number = number, Room = room }
                end
            end
        end
    end
    table.sort(result, function(a, b)
        return a.Number < b.Number
    end)
    return result
end

local function getNodes(room)
    local result = {}
    local folder = room:FindFirstChild("PathfindNodes")

    if folder then
        for _, object in ipairs(folder:GetChildren()) do
            if object:IsA("BasePart") then
                result[#result + 1] = object
            end
        end
    end

    table.sort(result, function(a, b)
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

    return result
end

local function getRoomExit(room)
    local roomExit = room:FindFirstChild("RoomExit")
    if roomExit and roomExit:IsA("BasePart") then
        return roomExit
    end
    return nil
end

local function getAliveCharacter(targetPlayer)
    if not targetPlayer or targetPlayer.Parent ~= Players then
        return nil, nil, nil
    end
    local character = targetPlayer.Character
    if not character or not character:IsDescendantOf(Workspace) then
        return nil, nil, nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
        return nil, nil, nil
    end
    return character, root, humanoid
end

local function approach(model, targetPosition, dt)
    local pivot = model:GetPivot()
    local position = pivot.Position
    local difference = targetPosition - position
    local distance = difference.Magnitude
    if distance <= 0.05 then
        return true
    end
    local step = math.min(distance, SPEED * math.min(dt, 0.1))
    local nextPosition = position + difference.Unit * step
    local forward = Vector3.new(difference.X, 0, difference.Z)
    local rotation = pivot.Rotation
    if forward.Magnitude > 0.001 then
        rotation = CFrame.lookAt(Vector3.zero, forward.Unit).Rotation
    end
    model:PivotTo(CFrame.new(nextPosition) * rotation)
    return distance - step <= 0.05
end

local pathMovement = nil

local function moveAlongOriginalRipperPath(model, node, deltaTime)
    if not pathMovement or pathMovement.Node ~= node then
        local startCFrame = model:GetPivot()
        local targetCFrame = node.CFrame + HEIGHT_OFFSET
        pathMovement = {
            Node = node,
            StartCFrame = startCFrame,
            TargetCFrame = targetCFrame,
            TotalDistance = (targetCFrame.Position - startCFrame.Position).Magnitude,
            Travelled = 0
        }
    end

    local state = pathMovement
    if state.TotalDistance <= 0.001 then
        model:PivotTo(state.TargetCFrame)
        pathMovement = nil
        return true
    end

    state.Travelled = math.min(
        state.Travelled + SPEED * math.min(deltaTime, 0.1),
        state.TotalDistance
    )

    model:PivotTo(
        state.StartCFrame:Lerp(
            state.TargetCFrame,
            state.Travelled / state.TotalDistance
        )
    )

    if state.Travelled >= state.TotalDistance then
        pathMovement = nil
        return true
    end

    return false
end

local function rayCanHit(model, character)
    local origin = model.PrimaryPart and model.PrimaryPart.Position or model:GetPivot().Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    for _, name in ipairs({ "HumanoidRootPart", "Head", "UpperTorso", "Torso", "LowerTorso" }) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            local direction = part.Position - origin
            if direction.Magnitude <= HIT_RANGE and direction.Magnitude > 0.001 then
                local exclusions = { model }
                for _ = 1, 10 do
                    params.FilterDescendantsInstances = exclusions
                    local result = Workspace:Raycast(origin, direction, params)
                    if not result or result.Instance:IsDescendantOf(character) then
                        return true
                    end

                    local obstacle = result.Instance
                    local nodeFolder = obstacle:FindFirstAncestor("PathfindNodes")
                    if nodeFolder or (obstacle:IsA("BasePart")
                        and obstacle.Transparency >= 0.98 and not obstacle.CanCollide) then
                        exclusions[#exclusions + 1] = obstacle
                    else
                        break
                    end
                end
            end
        end
    end

    return false
end

local entity = loadModel(ENTITY_ASSET_ID, "DeerGodModel")
if not entity then
    return
end

local rooms = {}
local startIndex = nil
local startRoom = nil
local startNode = nil
local startNodes = nil
local initialSearchStarted = os.clock()
while not startNode and os.clock() - initialSearchStarted < START_SEARCH_TIMEOUT do
    rooms = getRooms()
    local candidateStartIndex = 1
    if #rooms > 10 then
        candidateStartIndex = #rooms - 8
    end

    for index = candidateStartIndex, #rooms do
        local data = rooms[index]
        local nodes = getNodes(data.Room)
        local candidateNode = nodes[1] or getRoomExit(data.Room)

        if candidateNode and candidateNode:IsA("BasePart") then
            startIndex = index
            startRoom = data.Room
            startNodes = nodes
            startNode = candidateNode
            break
        end
    end

    if not startNode then
        task.wait(0.5)
    end
end

if not startNode or not startNode.Parent then
    entity:Destroy()
    return
end

entity.Name = "Deer God"
entity:PivotTo(startNode.CFrame + HEIGHT_OFFSET)
entity.Parent = Workspace

local saySounds = {}
for index = 1, 5 do
    local saySound = entity:FindFirstChild("Say" .. index, true)
    if saySound and saySound:IsA("Sound") then
        saySound.Looped = false
        saySounds[#saySounds + 1] = saySound
    end
end

local ambientSounds = {}
local soundNames = { PlaySound = true, Footsteps = true }
for _, descendant in ipairs(entity:GetDescendants()) do
    if descendant:IsA("Sound") and soundNames[descendant.Name] then
        descendant.Looped = true
        descendant.TimePosition = 0
        descendant:Play()
        ambientSounds[#ambientSounds + 1] = descendant
    end
end

local running = true
local errorParticlesGui = nil
local errorParticlesConnection = nil
local lockedPlayer = nil
local lockedCharacter = nil
local hitCharacters = setmetatable({}, { __mode = "k" })
local currentGoal = nil
local currentRoomNumber = rooms[startIndex].Number
local roomsEntered = 1
local visited = setmetatable({}, { __mode = "k" })
local routeProgressByRoom = {}
local completedNodeKeys = {}
local completedRoomExits = {}
local finished = false

local function getStableNodeKey(roomNumber, node)
    local position = node.Position
    return tostring(roomNumber) .. ":" .. node.Name .. ":" .. string.format(
        "%.1f:%.1f:%.1f", position.X, position.Y, position.Z
    )
end

local function completeNode(roomNumber, node, nodeIndex, isExit)
    visited[node] = true
    if isExit then
        completedRoomExits[roomNumber] = true
    else
        local previous = routeProgressByRoom[roomNumber] or 0
        if nodeIndex > previous then
            routeProgressByRoom[roomNumber] = nodeIndex
        end
        completedNodeKeys[getStableNodeKey(roomNumber, node)] = true
    end
end

local function nodeAlreadyCompleted(roomNumber, node, nodeIndex, isExit)
    if visited[node] then
        return true
    end
    if isExit then
        return completedRoomExits[roomNumber] == true
    end
    return nodeIndex <= (routeProgressByRoom[roomNumber] or 0)
        or completedNodeKeys[getStableNodeKey(roomNumber, node)] == true
end

if #startNodes > 0 then
    for index, node in ipairs(startNodes) do
        if node == startNode then
            completeNode(currentRoomNumber, node, index, false)
            break
        end
    end
else
    completeNode(currentRoomNumber, startNode, 0, true)
end

local ERROR_PARTICLE_TEXTURES = {
    "rbxassetid://6214195404",
    "rbxassetid://12293713542",
    "rbxassetid://7144894845"
}

local function stopErrorParticles()
    if errorParticlesConnection then
        errorParticlesConnection:Disconnect()
        errorParticlesConnection = nil
    end
    if errorParticlesGui then
        errorParticlesGui:Destroy()
        errorParticlesGui = nil
    end
end

local function startErrorParticles()
    stopErrorParticles()

    local old = playerGui:FindFirstChild("DeerGodErrorParticles")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "DeerGodErrorParticles"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 75
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    errorParticlesGui = gui

    local sprites = {}
    local expiration = {}
    for index = 1, 30 do
        local sprite = Instance.new("ImageLabel")
        sprite.Name = "ErrorParticle" .. index
        sprite.BorderSizePixel = 0
        sprite.BackgroundTransparency = 1
        sprite.Image = ERROR_PARTICLE_TEXTURES[math.random(1, #ERROR_PARTICLE_TEXTURES)]
        sprite.ImageTransparency = 1
        sprite.ScaleType = Enum.ScaleType.Crop
        sprite.Visible = false
        sprite.ZIndex = 2
        sprite.Parent = gui
        sprites[index] = sprite
        expiration[index] = 0
    end

    local strips = {}
    local stripExpiration = {}
    for index = 1, 5 do
        local strip = Instance.new("Frame")
        strip.Name = "ErrorScanline" .. index
        strip.BackgroundColor3 = Color3.fromRGB(200, 40, 70)
        strip.BackgroundTransparency = 0.6
        strip.BorderSizePixel = 0
        strip.Visible = false
        strip.ZIndex = 1
        strip.Parent = gui
        strips[index] = strip
        stripExpiration[index] = 0
    end

    local startedAt = os.clock()
    local nextBurst = startedAt
    local nextStrip = startedAt
    local spriteIndex = 0
    local stripIndex = 0

    errorParticlesConnection = RunService.RenderStepped:Connect(function()
        if not running or not gui.Parent or os.clock() - startedAt >= 60 then
            stopErrorParticles()
            return
        end

        local now = os.clock()

        if now >= nextBurst then
            nextBurst = now + 0.055 + math.random() * 0.055
            for _ = 1, math.random(3, 7) do
                spriteIndex = spriteIndex % #sprites + 1
                local sprite = sprites[spriteIndex]
                sprite.Image = ERROR_PARTICLE_TEXTURES[math.random(1, #ERROR_PARTICLE_TEXTURES)]
                sprite.ImageColor3 = math.random() < 0.55
                    and Color3.fromRGB(math.random(190, 255), math.random(70, 150), math.random(90, 170))
                    or Color3.fromRGB(math.random(150, 230), math.random(200, 255), 255)
                sprite.ImageTransparency = math.random(25, 70) / 100
                sprite.Position = UDim2.fromScale(math.random(), math.random())
                sprite.Size = UDim2.fromOffset(math.random(6, 90), math.random(3, 36))
                sprite.Rotation = math.random(-14, 14)
                sprite.Visible = true
                expiration[spriteIndex] = now + math.random(7, 22) / 100
            end
        end

        if now >= nextStrip then
            nextStrip = now + 0.10 + math.random() * 0.17
            stripIndex = stripIndex % #strips + 1
            local strip = strips[stripIndex]
            strip.BackgroundColor3 = math.random() < 0.6
                and Color3.fromRGB(210, 35, 65)
                or Color3.fromRGB(105, 210, 230)
            strip.BackgroundTransparency = math.random(40, 80) / 100
            strip.Position = UDim2.fromScale(math.random() * 0.6, math.random())
            strip.Size = UDim2.new(math.random(20, 90) / 100, 0, 0, math.random(2, 7))
            strip.Visible = true
            stripExpiration[stripIndex] = now + math.random(5, 14) / 100
        end

        for index, sprite in ipairs(sprites) do
            if sprite.Visible and now >= expiration[index] then
                sprite.Visible = false
            end
        end
        for index, strip in ipairs(strips) do
            if strip.Visible and now >= stripExpiration[index] then
                strip.Visible = false
            end
        end
    end)
end

local function setDeathCause(targetPlayer)
    local gameStats = ReplicatedStorage:FindFirstChild("GameStats")
    local playerStats = gameStats and gameStats:FindFirstChild("Player_" .. targetPlayer.Name)
    local total = playerStats and playerStats:FindFirstChild("Total")
    local deathCause = total and total:FindFirstChild("DeathCause")
    if deathCause and deathCause:IsA("StringValue") then
        deathCause.Value = "MultiMonster"
    end
end

local function killTargetLocally(targetPlayer, targetCharacter)
    setDeathCause(targetPlayer)
    if targetPlayer == player and typeof(replicatesignal) == "function" then
        pcall(function()
            replicatesignal(player.Kill)
        end)
    end
    local character = targetPlayer.Character
    if character == targetCharacter then
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid.Health = 0
        end
    end
end

local shakeLoopSerial = 0

local function startDistanceShake()
    shakeLoopSerial = shakeLoopSerial + 1
    local serial = shakeLoopSerial
    local cameraShaker = nil
    local shakerModule = ReplicatedStorage:FindFirstChild("CameraShaker")

    if shakerModule then
        local loaded, CameraShaker = pcall(require, shakerModule)
        if loaded and CameraShaker then
            local created, shaker = pcall(function()
                local instance = CameraShaker.new(
                    Enum.RenderPriority.Camera.Value + 1,
                    function(shakeCFrame)
                        local camera = Workspace.CurrentCamera
                        if camera then
                            camera.CFrame = camera.CFrame * shakeCFrame
                        end
                    end
                )
                instance:Start()
                return instance
            end)
            if created then
                cameraShaker = shaker
            end
        end
    end

    task.spawn(function()
        while running and entity and entity.Parent and serial == shakeLoopSerial do
            local _, root, humanoid = getAliveCharacter(player)
            local distance = math.huge
            if root then
                distance = (root.Position - entity:GetPivot().Position).Magnitude
            end

            local proximity = math.clamp(
                1 - distance / CAMERA_SHAKE_MAX_DISTANCE,
                0,
                1
            )
            local magnitude = CAMERA_SHAKE_MIN_MAGNITUDE
                + (CAMERA_SHAKE_MAX_MAGNITUDE - CAMERA_SHAKE_MIN_MAGNITUDE) * proximity

            if cameraShaker then
                pcall(function()
                    cameraShaker:ShakeOnce(magnitude, 10, 0.05, 0.4)
                end)
            elseif humanoid then
                local originalOffset = humanoid.CameraOffset
                local offset = Vector3.new(
                    math.random(-100, 100) / 100,
                    math.random(-100, 100) / 100,
                    math.random(-50, 50) / 100
                ) * magnitude

                local inTween = TweenService:Create(
                    humanoid,
                    TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { CameraOffset = originalOffset + offset }
                )
                local outTween = TweenService:Create(
                    humanoid,
                    TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { CameraOffset = originalOffset }
                )

                inTween:Play()
                task.delay(0.09, function()
                    if humanoid and humanoid.Parent then
                        outTween:Play()
                    end
                end)
            end

            task.wait(CAMERA_SHAKE_INTERVAL)
        end

        if cameraShaker then
            pcall(function()
                cameraShaker:Stop()
            end)
        end
    end)
end

local function getNearestPlayer(position)
    local nearest = nil
    local nearestDistance = CHASE_RANGE
    for _, candidate in ipairs(Players:GetPlayers()) do
        local character, root = getAliveCharacter(candidate)
        if character and root and not hitCharacters[character] then
            local distance = (root.Position - position).Magnitude
            if distance <= nearestDistance then
                nearestDistance = distance
                nearest = candidate
            end
        end
    end
    return nearest
end

local function findRouteGoal()
    if currentGoal then
        local room = currentGoal.Room
        local node = currentGoal.Node
        if room and room.Parent and node and node:IsDescendantOf(room)
            and not nodeAlreadyCompleted(
                currentGoal.RoomNumber, node, currentGoal.Index, currentGoal.IsExit
            ) then
            return currentGoal
        end
        currentGoal = nil
        pathMovement = nil
    end

    local orderedRooms = getRooms()
    if #orderedRooms == 0 then
        return "finished"
    end

    local roomIndex = nil
    for index, data in ipairs(orderedRooms) do
        if data.Number >= currentRoomNumber then
            roomIndex = index
            break
        end
    end
    if not roomIndex then
        return "finished"
    end

    local targetRoomIndex = math.max(1, #orderedRooms - 1)

    for index = roomIndex, targetRoomIndex do
        local roomData = orderedRooms[index]
        local room = roomData.Room
        local nodes = getNodes(room)
        local nextNode = nil
        local nextIndex = 0
        local isExit = false

        if #nodes > 0 then
            for nodeIndex, node in ipairs(nodes) do
                if not nodeAlreadyCompleted(roomData.Number, node, nodeIndex, false) then
                    nextNode = node
                    nextIndex = nodeIndex
                    break
                end
            end
        else
            local roomExit = getRoomExit(room)
            if roomExit and not nodeAlreadyCompleted(roomData.Number, roomExit, 0, true) then
                nextNode = roomExit
                isExit = true
            end
        end

        if nextNode then
            if roomData.Number > currentRoomNumber then
                if roomsEntered >= MAX_ROOMS then
                    return "finished"
                end
                currentRoomNumber = roomData.Number
                roomsEntered = roomsEntered + 1
            end

            currentGoal = {
                Room = room,
                RoomNumber = roomData.Number,
                Node = nextNode,
                Index = nextIndex,
                IsExit = isExit
            }
            return currentGoal
        end

        if roomsEntered >= MAX_ROOMS then
            return "finished"
        end
    end

    return "finished"
end

local lastChasePosition = nil
local lastChaseProgressCheck = 0

local function markWaypointsPassedDuringChase(fromPosition, toPosition)
    local travel = toPosition - fromPosition
    local distanceSquared = travel:Dot(travel)
    if distanceSquared <= 0.0001 then
        return
    end

    local orderedRooms = getRooms()
    local targetRoomIndex = math.max(1, #orderedRooms - 1)
    local laterRoomsToEnter = MAX_ROOMS - roomsEntered

    for roomIndex = 1, targetRoomIndex do
        local roomData = orderedRooms[roomIndex]
        if roomData.Number >= currentRoomNumber then
            if roomData.Number > currentRoomNumber then
                if laterRoomsToEnter <= 0 then
                    break
                end
                laterRoomsToEnter = laterRoomsToEnter - 1
            end

            local nodes = getNodes(roomData.Room)
            if #nodes > 0 then
                for index, node in ipairs(nodes) do
                    if not nodeAlreadyCompleted(roomData.Number, node, index, false) then
                        local waypointPosition = node.Position + HEIGHT_OFFSET
                        local fraction = math.clamp(
                            (waypointPosition - fromPosition):Dot(travel) / distanceSquared,
                            0,
                            1
                        )
                        local nearestPosition = fromPosition + travel * fraction
                        if (nearestPosition - waypointPosition).Magnitude <= WAYPOINT_PASS_RADIUS then
                            completeNode(roomData.Number, node, index, false)
                        end
                    end
                end
            else
                local roomExit = getRoomExit(roomData.Room)
                if roomExit and not nodeAlreadyCompleted(roomData.Number, roomExit, 0, true) then
                    local waypointPosition = roomExit.Position + HEIGHT_OFFSET
                    local fraction = math.clamp(
                        (waypointPosition - fromPosition):Dot(travel) / distanceSquared,
                        0,
                        1
                    )
                    local nearestPosition = fromPosition + travel * fraction
                    if (nearestPosition - waypointPosition).Magnitude <= WAYPOINT_PASS_RADIUS then
                        completeNode(roomData.Number, roomExit, 0, true)
                    end
                end
            end
        end
    end

    if currentGoal and nodeAlreadyCompleted(
        currentGoal.RoomNumber, currentGoal.Node, currentGoal.Index, currentGoal.IsExit
    ) then
        currentGoal = nil
        pathMovement = nil
    end
end

local function finish()
    if finished then
        return
    end
    finished = true
    running = false
    shakeLoopSerial = shakeLoopSerial + 1
    stopErrorParticles()
    for _, sound in ipairs(ambientSounds) do
        if sound.Parent then
            sound:Stop()
        end
    end
    for _, sound in ipairs(saySounds) do
        if sound.Parent then
            sound:Stop()
        end
    end
    if entity and entity.Parent then
        entity:Destroy()
    end
end

startDistanceShake()
startErrorParticles()

task.spawn(function()
    while running and entity and entity.Parent do
        task.wait(math.random(5, 10))
        if not running or not entity or not entity.Parent then
            break
        end

        local availableSounds = {}
        for _, sound in ipairs(saySounds) do
            if sound and sound.Parent and sound:IsDescendantOf(entity) then
                availableSounds[#availableSounds + 1] = sound
            end
        end

        if #availableSounds > 0 then
            for _, sound in ipairs(availableSounds) do
                if sound.IsPlaying then
                    sound:Stop()
                end
            end

            local selectedSound = availableSounds[math.random(1, #availableSounds)]
            selectedSound.TimePosition = 0
            selectedSound:Play()
        end
    end

    for _, sound in ipairs(saySounds) do
        if sound and sound.Parent and sound.IsPlaying then
            sound:Stop()
        end
    end
end)

while running and entity.Parent do
    local deltaTime = RunService.Heartbeat:Wait()

    if lockedPlayer then
        local character = getAliveCharacter(lockedPlayer)
        if character ~= lockedCharacter then
            lockedPlayer = nil
            lockedCharacter = nil
        end
    end

    if not lockedPlayer then
        lockedPlayer = getNearestPlayer(entity:GetPivot().Position)
        lockedCharacter = lockedPlayer and lockedPlayer.Character or nil
    end

    if lockedPlayer then
        pathMovement = nil
        local character, root, humanoid = getAliveCharacter(lockedPlayer)
        if character and root and humanoid and character == lockedCharacter then
            if not lastChasePosition then
                lastChasePosition = entity:GetPivot().Position
            end
            local previousPosition = lastChasePosition
            approach(entity, root.Position, deltaTime)
            local currentPosition = entity:GetPivot().Position
            if os.clock() - lastChaseProgressCheck >= 0.1 then
                markWaypointsPassedDuringChase(previousPosition, currentPosition)
                lastChasePosition = currentPosition
                lastChaseProgressCheck = os.clock()
            end
        else
            lockedPlayer = nil
            lockedCharacter = nil
            if lastChasePosition then
                markWaypointsPassedDuringChase(lastChasePosition, entity:GetPivot().Position)
            end
            lastChasePosition = nil
            lastChaseProgressCheck = 0
        end
    else
        if lastChasePosition then
            markWaypointsPassedDuringChase(lastChasePosition, entity:GetPivot().Position)
        end
        lastChasePosition = nil
        lastChaseProgressCheck = 0
        local goal = findRouteGoal()
        if goal == "finished" then
            break
        elseif goal then
            local room = goal.Room
            local node = goal.Node
            if room.Parent and node:IsDescendantOf(room) then
                if moveAlongOriginalRipperPath(entity, node, deltaTime) then
                    completeNode(goal.RoomNumber, node, goal.Index, goal.IsExit)
                    currentGoal = nil
                end
            else
                currentGoal = nil
                pathMovement = nil
            end
        else
            break
        end
    end

    local myCharacter, myRoot, myHumanoid = getAliveCharacter(player)
    if myCharacter and myRoot and myHumanoid
        and not hitCharacters[myCharacter]
        and rayCanHit(entity, myCharacter) then
        hitCharacters[myCharacter] = true
        killTargetLocally(player, myCharacter)
    end
end

finish()
end

function entityBehaviors.MRB()
   local RunService = game:GetService("RunService")
    local testModelId = 96664504057582
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

    local doorSignal = nil
    local movingSoundForWave = nil

    function SpawnReboundEntity(startRoomType)
        if not reboundTemplate then
            for attempt = 1, 6 do
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

        if not reboundTemplate then

            return false
        end

        local testEntity = reboundTemplate:Clone()
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
            if not primaryPart.Parent then
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
                if primaryPart.Parent and targetPart and targetPart:IsA("BasePart") then
                    primaryPart.CFrame = targetPart.CFrame + Vector3.new(0, 1, 0)
                end
            end

            task.wait(2)
            if primaryPart.Parent then
                StartEntityLogic(primaryPart, startRoomType)
            end
        end)
        return true
    end

    function StartEntityLogic(primaryPart, startRoomType)
        if not primaryPart or not primaryPart.Parent then
            return
        end

        local lastProximityShake = 0
        task.spawn(function()
            local RunService = game:GetService("RunService")
            local player = game.Players.LocalPlayer

            while primaryPart and primaryPart.Parent do
                RunService.RenderStepped:Wait()
                if not primaryPart or not primaryPart.Parent then
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

        local activeMovementTween = nil
        local activeMovementTarget = nil
        local activeMovementOrigin = nil

        local function startReboundTween(targetCFrame)
            if not primaryPart.Parent then
                return false
            end
            activeMovementOrigin = primaryPart.CFrame
            activeMovementTarget = targetCFrame
            activeMovementTween = game.TweenService:Create(
                primaryPart,
                TweenInfo.new(v305),
                { CFrame = targetCFrame }
            )
            activeMovementTween:Play()
            return true
        end

        local function waitReboundStep(duration)
            local elapsed = 0
            while elapsed < duration and primaryPart.Parent do
                local dt = RunService.Heartbeat:Wait()
                elapsed = elapsed + dt
            end
            return primaryPart.Parent ~= nil
        end

        local function waitForReboundArrival()
            local destination = activeMovementTarget
            if not destination then
                return false
            end
            while primaryPart.Parent do
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
                RunService.Heartbeat:Wait()
            end
            return false
        end

        local detectedPlayer = false

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
            if not hrp then
                return false
            end

            local targetPos = hrp.Position
            local distance = (targetPos - origin).Magnitude
            if distance <= 0.001 or distance > maxDistance then
                return false
            end

            local direction = (targetPos - origin).Unit * maxDistance
            local ray = Ray.new(origin, direction)
            local hitPart = workspace:FindPartOnRay(ray, entityPart)
            return hitPart and hitPart:IsDescendantOf(player.Character)
        end

        local function ExecutePlayer()
            if detectedPlayer then
                return
            end
            detectedPlayer = true

            task.spawn(function()
                task.wait(0.3)
                local player = game.Players.LocalPlayer
                local char = player and player.Character
                if char then
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    if hum and hum.Health > 0 then
                        local damage = 100
                        local willDie = hum.Health <= damage
                        if willDie then
                            local playerStats = game.ReplicatedStorage.GameStats:FindFirstChild("Player_" .. player.Name)
                            local total = playerStats and playerStats:FindFirstChild("Total")
                            local deathCause = total and total:FindFirstChild("DeathCause")
                            if deathCause then
                                deathCause.Value = "MultiMonster"
                            end
                        end
                        hum:TakeDamage(damage)
                    end
                end
            end)
        end

        task.spawn(function()
            local player = game.Players.LocalPlayer
            while primaryPart and primaryPart.Parent do
                task.wait(0.05)
                if not primaryPart or not primaryPart.Parent then
                    break
                end
                if workspace:FindFirstChild("SeekMov") or workspace.CurrentRooms:FindFirstChild("50") then
                    break
                end
                if not detectedPlayer and CheckLineOfSight(primaryPart, player, 100) then
                    ExecutePlayer()
                end
            end
        end)

        if startRoomType == "start" then
            local currentRoom = 0
            local maxRoom = game.ReplicatedStorage.GameData.LatestRoom.Value

            while currentRoom <= maxRoom and primaryPart.Parent do
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

                maxRoom = game.ReplicatedStorage.GameData.LatestRoom.Value
                currentRoom = currentRoom + 1
            end
        else
            local currentRoom = GetMaxExistingRoom()
            local minRoom = math.max(0, currentRoom - 7)

            while currentRoom >= minRoom and primaryPart.Parent do
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

    local sweepSound = PlayPreloadedSound("MultiMonsterRebound", 2)
    
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
        if doorGateOpen then
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
        while sound.Parent and not finished do
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
        local previousAcceptedCount = acceptedDoorCount
        doorGateOpen = true
        while acceptedDoorCount == previousAcceptedCount do
            doorSignal.Event:Wait()
        end
        doorGateOpen = false
        return true
    end

    local directions = { "latest", "start", "latest", "start" }
    for waveIndex, startRoomType in ipairs(directions) do
        SpawnReboundEntity(startRoomType)
        movingSoundForWave = PlayPreloadedSound("ReboundMovings", 3)
        waitForSoundToFinish(movingSoundForWave)
        movingSoundForWave = nil
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



function entityBehaviors.MF()
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

local s = LoadCustomInstance("130785314054121", workspace)
if not s then
    return
end

local entity = s:FindFirstChildWhichIsA("BasePart")
entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0, 5, -15)
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
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.ToolEventPrompt.Enabled = false
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.Log.SparkParticles.Enabled = false
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.Log.SmokeParticles.Enabled = false
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.Log.FireParticles.Enabled = false
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.Log.FireLight.Enabled = false
end)


local pointLight = Instance.new("PointLight")
pointLight.Color = Color3.new(255, 255, 255)
pointLight.Range = 60
pointLight.Brightness = 99999
pointLight.Parent = entity

tweenservice:Create(pointLight, TweenInfo.new(3), {
    Brightness = 0
}):Play()

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://137044859218769"
sound.Looped = false
sound.Volume = 5
sound.Parent = s
sound:Play()

local frost = Instance.new("ColorCorrectionEffect")
frost.Parent = game.Lighting
tweenservice:Create(frost, TweenInfo.new(10), {
    TintColor = Color3.fromRGB(217, 250, 255),
    Saturation = -0.7,
    Contrast = 0.2
}):Play()

for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
    if entity:FindFirstChild("Attachment") and entity.Attachment:FindFirstChild(v) then
        entity.Attachment[v].Enabled = false
    end
end
wait(8)
local roomChanged = false
local roomChangedConnection
roomChangedConnection = game.ReplicatedStorage.GameData.LatestRoom.Changed:Connect(function()
    roomChanged = true
    if roomChangedConnection then
        roomChangedConnection:Disconnect()
    end
end)
for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
    if entity:FindFirstChild("Attachment") and entity.Attachment:FindFirstChild(v) then
        entity.Attachment[v].Enabled = true
    end
end
wait(2)

if roomChanged then
    for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
        if entity:FindFirstChild("Attachment") and entity.Attachment:FindFirstChild(v) then
            entity.Attachment[v].Enabled = false
        end
    end
    
    pcall(function() entity.Ambience:Stop() end)
    pcall(function() entity.AmbienceFar:Stop() end)
    
    local des = Instance.new("Sound")
    des.SoundId = "rbxassetid://109891187801924"
    des.Looped = false
    des.Volume = 2.5
    des.Parent = s
    des:Play()
    
    wait(5)
    s:Destroy()
    
    tweenservice:Create(frost, TweenInfo.new(5), {
        TintColor = Color3.fromRGB(255, 255, 255),
        Saturation = 0,
        Contrast = 0
    }):Play()
    wait(5)
    frost:Destroy()
    return
end
pcall(function() entity.Ambience:Play() end)
pcall(function() entity.AmbienceFar:Play() end)

local dmg = true
task.spawn(function()
    while dmg and not roomChanged do
        wait(1)
        local lighter = chr:FindFirstChild("Lighter")
        local safe = false
        if lighter then
            local handle = lighter:FindFirstChild("Handle")
            if handle then
                local holder = handle:FindFirstChild("EffectsHolder")
                if holder then
                    local attach = holder:FindFirstChild("AttachOn")
                    if attach then
                        local main = attach:FindFirstChild("MainLight")
                        if main and main:IsA("PointLight") then
                            safe = main.Enabled
                        end
                    end
                end
            end
        end
        if not safe and not roomChanged then
            pcall(function()
                chr.Humanoid.Health -= 5
                game.ReplicatedStorage.GameStats["Player_" .. plr.Name].Total.DeathCause.Value = "Frostbite"
                
                firesignal(game.ReplicatedStorage.RemotesFolder.DeathHint.OnClientEvent, {
                        "It's a bit cold here, isn't it?",
                        "You froze to death by something.",
                        "Maybe you need some cold prevention measures. I heard that humans are very sensitive to the cold..",
                        "Try using your lighter to keep warm.",
                        "This may be a bit tricky and noisy.",
                        "You should try again.",
                        "By the way, the name of the thing that killed you is Frostbite."
                    }, "Yellow")
            end)
        end
    end
    dmg = false
end)

game.ReplicatedStorage.GameData.LatestRoom.Changed:Wait()

dmg = false
roomChanged = true

if roomChangedConnection then
    roomChangedConnection:Disconnect()
end

for _, v in ipairs({"face", "Heylois", "BlackTrai2l", "BlackTrai3l"}) do
    if entity:FindFirstChild("Attachment") and entity.Attachment:FindFirstChild(v) then
        entity.Attachment[v].Enabled = false
    end
end

pcall(function() entity.Ambience:Stop() end)
pcall(function() entity.AmbienceFar:Stop() end)

local des = Instance.new("Sound")
des.SoundId = "rbxassetid://111715441853991"
des.Looped = false
des.Volume = 2.5
des.Parent = s
des:Play()

wait(5)
s:Destroy()

tweenservice:Create(frost, TweenInfo.new(5), {
    TintColor = Color3.fromRGB(255, 255, 255),
    Saturation = 0,
    Contrast = 0
}):Play()
wait(5)
frost:Destroy()
end

function entityBehaviors.DeerGodTWO()
local Players = game:GetService("Players") 
local RunService = game:GetService("RunService") 
local player = Players.LocalPlayer 
local ids = {"rbxassetid://8116159092","rbxassetid://435812828","rbxassetid://860440643"} 
 
local gui = Instance.new("ScreenGui",player:WaitForChild("PlayerGui")) 
gui.Name = "SnowGlitchEnhanced" 
gui.IgnoreGuiInset = true 
 
local mainImg = Instance.new("ImageLabel",gui) 
mainImg.Size = UDim2.new(1,0,1,0) 
mainImg.BackgroundTransparency = 1 
mainImg.ImageTransparency = 0.88 
mainImg.Image = ids[math.random(#ids)] 
mainImg.ScaleType = Enum.ScaleType.Tile 
mainImg.TileSize = UDim2.new(0,64,0,64) 
 
local flashFrame = Instance.new("Frame",gui) 
flashFrame.Size = UDim2.new(1,0,1,0) 
flashFrame.BackgroundColor3 = Color3.new(1,1,1) 
flashFrame.BackgroundTransparency = 1 
flashFrame.BorderSizePixel = 0 
 
local start = tick() 
local lastFlash = tick() 
local flashInterval = 0.15 
local flashDuration = 0.05 
 
local conn = RunService.RenderStepped:Connect(function() 
    local elapsed = tick() - start 
    if elapsed >= 60 then 
        conn:Disconnect() 
        gui:Destroy() 
        return 
    end 
     
    mainImg.Image = ids[math.random(#ids)] 
    mainImg.ImageTransparency = 0.78 + math.random()*0.18 
    local sz = 48 + math.random(0,32) 
    mainImg.TileSize = UDim2.new(0,sz,0,sz) 
    local r = math.random(80,120)/100 
    local g = math.random(70,110)/100 
    local b = math.random(90,130)/100 
    mainImg.ImageColor3 = Color3.new(r,g,b) 
     
    if tick() - lastFlash >= flashInterval then 
        flashFrame.BackgroundTransparency = 0.65 + math.random()*0.25 
        lastFlash = tick() 
    else 
        flashFrame.BackgroundTransparency = 1 
    end 
     
    if math.random() < 0.03 then 
        local x = math.random(0,800) 
        local y = math.random(0,600) 
        local w = math.random(20,80) 
        local h = math.random(10,40) 
        local highlight = Instance.new("Frame",gui) 
        highlight.Size = UDim2.new(0,w,0,h) 
        highlight.Position = UDim2.new(0,x,0,y) 
        highlight.BackgroundColor3 = Color3.new(1,1,1) 
        highlight.BackgroundTransparency = 0.5 + math.random()*0.3 
        highlight.BorderSizePixel = 0 
        game:GetService("Debris"):AddItem(highlight,0.06) 
    end 
end) 
    local entity = spawner.Create({ 
        Entity = { 
            Name = "DeerGod", 
            Asset = "92755817727288", 
            HeightOffset = -0.8 
        }, 
        Lights = { 
            Flicker = { 
                Enabled = true, 
                Duration = 50 
            }, 
            Shatter = true, 
            Repair = false 
        }, 
        Earthquake = { 
            Enabled = false 
        }, 
        CameraShake = { 
            Enabled = true, 
            Range = 1500, 
            Values = {0.5, 5, 0.1, 1} 
        }, 
        Movement = { 
            Speed = 25, 
            Delay = 0, 
            Reversed = false 
        }, 
        Rebounding = { 
            Enabled = false, 
            Type = "Blitz", 
            Min = 1, 
            Max = math.random(1, 2), 
            Delay = math.random(10, 30) / 10 
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
                "It seems you are so unfortunate...",  
                "You died by the Deer God",  
                "That powerful force will drag you into the abyss.", 
                "The cross cannot guarantee your safety.", 
                "See you next time." 
            }, 
            Cause = "Deer God" 
        } 
    }) 
 
    entity:SetCallback("OnSpawned", function() 
        entityModel = entity.Model 
        if entityModel then 
            if not entityModel.PrimaryPart then 
                local primaryPart = entityModel:FindFirstChild("Main") or entityModel:FindFirstChildWhichIsA("BasePart") 
                if primaryPart then 
                    entityModel.PrimaryPart = primaryPart 
                end 
            end 
        end 
     
        startChaseSystem() 
    end) 
     
    entity:SetCallback("OnDespawning", function() 
        if chaseConnection then 
            chaseConnection:Disconnect() 
            chaseConnection = nil 
        end 
    end) 
 
    entity:SetCallback("OnDamagePlayer", function(newHealth) 
        if newHealth == 0 then 
            if chaseConnection then 
                chaseConnection:Disconnect() 
                chaseConnection = nil 
            end 
     
            if entityModel and entityModel.PrimaryPart then 
                local currentPos = entityModel.PrimaryPart.Position 
                local forwardDir = entityModel.PrimaryPart.CFrame.LookVector 
                local targetPos = currentPos + forwardDir * 10 
                 
                entityModel:SetPrimaryPartCFrame(CFrame.new(currentPos, targetPos)) 
            end 
        end 
    end) 
     
    entity:SetCallback("OnRebounding", function(startOfRebound) 
        if not entityModel then return end 
         
        local main = entityModel:FindFirstChild("Main") 
        if not main then return end 
         
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
 
    local musicInstance = workspace:WaitForChild("HardCoreSound"):WaitForChild("DeerGodMusic")
    musicInstance.Volume = 4
    musicInstance:Play()
end
function entityBehaviors.FireMeld()
local meldView = workspace:FindFirstChild("MeldView")

local function addFire(obj)
	if obj:IsA("BasePart") and not obj:FindFirstChildOfClass("Fire") then
		local fire = Instance.new("Fire")
		fire.Size = 10
		fire.Heat = 10
		fire.Parent = obj
	end
end

if meldView then
	for _, obj in ipairs(meldView:GetDescendants()) do
		addFire(obj)
	end

	meldView.DescendantAdded:Connect(function(obj)
		addFire(obj)
	end)
end

task.wait(10)

if meldView and meldView.Parent then
	meldView:Destroy()
end

local currentRooms = workspace:FindFirstChild("CurrentRooms")

if currentRooms then
	for _, model in ipairs(currentRooms:GetDescendants()) do
		if model:IsA("Model") then
			local meldData = model:FindFirstChild("MeldData")
			local meldPads = model:FindFirstChild("MeldPads")
			local meldViewInside = model:FindFirstChild("MeldView")

			if meldData then
				meldData:Destroy()
			end

			if meldPads then
				meldPads:Destroy()
			end

			if meldViewInside then
				meldViewInside:Destroy()
			end
		end
	end
end
end
function entityBehaviors.JEFFDEATH()
for _, model in ipairs(workspace:GetChildren()) do
    if model.Name == "JeffTheKiller" then
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://102588764079889"
        sound.Volume = 1
        sound.Parent = workspace
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end
end
function entityBehaviors.HATRED2()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
    return
end

if type(_G.HatredPhaseTwoController) == "table" and type(_G.HatredPhaseTwoController.Stop) == "function" then
    pcall(_G.HatredPhaseTwoController.Stop)
end

local PendingAudio = _G.HatredPhaseTwoPendingAudio
if type(PendingAudio) ~= "table" then
    PendingAudio = {}
    _G.HatredPhaseTwoPendingAudio = PendingAudio
end

local CONFIG = {
    HatredModelId = "132062308462518",
    BlackHoleModelId = "133134959825646",
    ReplacementHatredModelId = "94520721608869",
    ReplacementViewDistance = 15,
    ReplacementHoverHeight = 8,
    HatredFacingOffsetDegrees = 90,
    ScaleSoundId = "18870782376",
    ScaleSoundVolume = 0.8,
    BlackHoleAppearanceSoundId = "119750858019376",
    BlackHoleAppearanceSoundVolume = 1,
    BlackHoleExpandedSoundId = "5813077875",
    BlackHoleExpandedSoundVolume = 2,
    EndingSoundId = "101395573137763",
    EndingSoundVolume = 1,
    EndingTextFadeDuration = 1,
    EndingTextHoldDuration = 3,
    HatredMusicVolume = 0.8,
    HatredMusicStart = 30,
    HatredMusicFadeIn = 2,
    CameraFlightDuration = 5,
    HeadLift = 3,
    HeadRotationDegrees = 140,
    HeadMoveDuration = 2.5,
    BlackLift = 50,
    BlackLiftDuration = 3.5,
    HatsBlackCameraDistance = 4,
    ModelFadeDuration = 1.5,
    InitialZoomDuration = 5,
    BlackoutAt = 5,
    ScaleAt = 6.4,
    HatredMusicLoadTimeout = 15,
    Hat2LoadTimeout = 15,
    BlackHoleScale = 50,
    BlackHoleWideFov = 115,
    SuctionWideFov = 120,
    PlayerLockFov = 120,
    BlackHolePullbackMultiplier = 1.55,
    ScaleDuration = 0.2,
    BlackHoleImpactShake = 0.55,
    BlackHoleShakeStrength = 2.6,
    BlackHoleModelShakePosition = 1.4,
    BlackHoleModelShakeRotation = 2.8,
    SuctionDuration = 0.85,
    SuctionDistanceFactor = 0.45,
    SuctionStreakSpeed = 4.8,
    KeyboardDuration = 70,
    DecoyIntervalMin = 8,
    DecoyIntervalMax = 18,
    DecoyChance = 0.2,
    DecoyDuration = 0.8,
    PromptStartWindow = 3.1,
    PromptEndWindow = 0.7,
    PromptDifficultyCurve = 1.5,
    PromptGap = 0.12,
    ScreenFadeDuration = 5,
    MusicFadeDuration = 8,
}

local State = {
    running = false,
    ending = false,
    token = 0,
    connections = {},
    tweens = {},
    roomTransparency = {},
    sharedSounds = {},
    ownedSounds = {},
    musicFadeInSound = nil,
    musicFadeInTween = nil,
    gui = nil,
    hatred = nil,
    preloadedHatred = nil,
    blackHole = nil,
    effectSound = nil,
    appearanceSound = nil,
    expandedSound = nil,
    endingSound = nil,
    blur = nil,
    camera = nil,
    cameraSnapshot = nil,
    cameraFrame = nil,
    cameraFocus = nil,
    cameraMode = "manual",
    followObject = nil,
    followOffset = nil,
    fixedCameraPosition = nil,
    playerCameraOffset = nil,
    root = nil,
    humanoid = nil,
    movementLock = nil,
    shakePower = 0,
    shakeUntil = 0,
    shakeDuration = 0,
    baseShake = 0,
    introBrand = nil,
    introGradient = nil,
    challenge = nil,
    suctionOverlay = nil,
    chromaticOverlay = nil,
}

local Controller = {}
_G.HatredPhaseTwoController = Controller
if type(getgenv) == "function" then
    getgenv().HatredPhaseTwoController = Controller
end

local CAMERA_BIND_NAME = "HatredPhaseTwoCamera"

local function alive(token)
    return State.running and State.token == token
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
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function playTween(instance, duration, goal, style, direction)
    if not instance or not instance.Parent then
        return nil
    end
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style or Enum.EasingStyle.Sine, direction or Enum.EasingDirection.Out), goal)
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
        task.wait(math.max(0, math.min(0.05, finishAt - os.clock())))
    end
    return alive(token)
end

local function animate(token, duration, update)
    local startedAt = os.clock()
    duration = math.max(duration, 0.001)
    while alive(token) do
        local progress = math.clamp((os.clock() - startedAt) / duration, 0, 1)
        local eased = progress * progress * (3 - 2 * progress)
        update(eased, progress)
        if progress >= 1 then
            return true
        end
        task.wait(0.03)
    end
    return false
end

local function getWorldFrame(object)
    if not object then
        return nil
    end
    if object:IsA("Model") then
        return object:GetPivot()
    elseif object:IsA("BasePart") then
        return object.CFrame
    elseif object:IsA("Attachment") then
        return object.WorldCFrame
    end
    local part = object:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame or nil
end

local function setWorldFrame(object, cf)
    if not object or not object.Parent then
        return false
    end
    if object:IsA("Model") then
        object:PivotTo(cf)
        return true
    elseif object:IsA("BasePart") then
        object.CFrame = cf
        return true
    elseif object:IsA("Attachment") then
        object.WorldCFrame = cf
        return true
    end
    local part = object:FindFirstChildWhichIsA("BasePart", true)
    if part then
        local delta = cf * part.CFrame:Inverse()
        for _, child in ipairs(object:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CFrame = delta * child.CFrame
            end
        end
        return true
    end
    return false
end

local function findRoomEntrance(token)
    local timeoutAt = os.clock() + 10
    while alive(token) and os.clock() < timeoutAt do
        local rooms = Workspace:FindFirstChild("CurrentRooms")
        local gameData = ReplicatedStorage:FindFirstChild("GameData")
        local latest = gameData and gameData:FindFirstChild("LatestRoom")
        local room = rooms and latest and rooms:FindFirstChild(tostring(latest.Value))
        local entrance = room and room:FindFirstChild("RoomEntrance", true)
        if entrance and entrance:IsA("BasePart") then
            return rooms, room, entrance
        end
        task.wait(0.1)
    end
    if not alive(token) then
        return nil, nil, nil
    end
    error("CurrentRooms, LatestRoom, or a BasePart named RoomEntrance was not found")
end

local function loadModel(assetId, fallbackName)
    local result
    local success, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. assetId)
    end)
    if success and objects and objects[1] then
        result = objects[1]
    end
    if not result then
        local stored = ReplicatedStorage:FindFirstChild(fallbackName, true)
        if stored then
            local cloned, copy = pcall(function()
                return stored:Clone()
            end)
            if cloned then
                result = copy
            end
        end
    end
    if not result then
        error("Unable to load asset " .. assetId .. "; place a model named " .. fallbackName .. " in ReplicatedStorage if needed")
    end

    if not result:IsA("Model") then
        local wrapper = Instance.new("Model")
        result.Parent = wrapper
        result = wrapper
    end
    if not result:FindFirstChildWhichIsA("BasePart", true) then
        destroy(result)
        error("Asset " .. assetId .. " does not contain a BasePart")
    end
    for _, item in ipairs(result:GetDescendants()) do
        if item:IsA("Script") or item:IsA("LocalScript") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
        end
    end
    return result
end

local function isTransparencyObject(object)
    return object:IsA("BasePart") or object:IsA("Beam") or object:IsA("ParticleEmitter")
end

local function sequenceToward(sequence, target, alpha)
    local keypoints = {}
    for _, keypoint in ipairs(sequence.Keypoints) do
        local value = keypoint.Value + (target - keypoint.Value) * alpha
        table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, value, keypoint.Envelope * (1 - alpha)))
    end
    return NumberSequence.new(keypoints)
end

local function transparencyObjects(model)
    local objects = model:GetDescendants()
    if isTransparencyObject(model) then
        table.insert(objects, model)
    end
    return objects
end

local function hideModelForReveal(model)
    for _, item in ipairs(transparencyObjects(model)) do
        if item:IsA("Beam") or item:IsA("ParticleEmitter") then
            pcall(function()
                item.Transparency = NumberSequence.new(1)
            end)
        end
    end
end

local function fadeModelIn(model, token)
    local entries = {}
    for _, item in ipairs(transparencyObjects(model)) do
        if isTransparencyObject(item) then
            local ok, transparency = pcall(function()
                return item.Transparency
            end)
            if ok then
                table.insert(entries, {object = item, original = transparency, numeric = item:IsA("BasePart")})
            end
        end
    end
    return animate(token, CONFIG.ModelFadeDuration, function(alpha)
        for _, entry in ipairs(entries) do
            local item = entry.object
            if item.Parent then
                pcall(function()
                    if entry.numeric then
                        item.Transparency = entry.original * (1 - alpha)
                    elseif alpha >= 1 then
                        item.Transparency = NumberSequence.new(0)
                    else
                        item.Transparency = sequenceToward(entry.original, 0, alpha)
                    end
                end)
            end
        end
    end)
end

local function hideRooms(rooms)
    for _, item in ipairs(rooms:GetDescendants()) do
        if isTransparencyObject(item) then
            local ok, original = pcall(function()
                return item.Transparency
            end)
            if ok then
                table.insert(State.roomTransparency, {object = item, original = original})
                pcall(function()
                    item.Transparency = item:IsA("BasePart") and 1 or NumberSequence.new(1)
                end)
            end
        end
    end
end

local function restoreRooms()
    local saved = State.roomTransparency
    State.roomTransparency = {}
    for _, entry in ipairs(saved) do
        if entry.object and entry.object.Parent then
            pcall(function()
                entry.object.Transparency = entry.original
            end)
        end
    end
end

local function lockPlayer(root, humanoid)
    local jumpEnabled = true
    pcall(function()
        jumpEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
    end)
    State.root = root
    State.humanoid = humanoid
    State.movementLock = {
        anchored = root.Anchored,
        walkSpeed = humanoid.WalkSpeed,
        jumpEnabled = jumpEnabled,
    }
    root.Anchored = true
    humanoid.WalkSpeed = 0
    humanoid.Jump = false
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end)
    addConnection(RunService.Heartbeat:Connect(function()
        if not State.running or not root.Parent or not humanoid.Parent then
            return
        end
        if not root.Anchored then
            root.Anchored = true
        end
        if humanoid.WalkSpeed ~= 0 then
            State.movementLock.walkSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
        end
        humanoid.Jump = false
    end))
end

local function restorePlayer()
    local saved = State.movementLock
    State.movementLock = nil
    if not saved then
        return
    end
    if State.root and State.root.Parent then
        pcall(function()
            State.root.Anchored = saved.anchored
        end)
    end
    if State.humanoid and State.humanoid.Parent then
        pcall(function()
            State.humanoid.WalkSpeed = saved.walkSpeed
            State.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, saved.jumpEnabled)
        end)
    end
end

local function shakeFor(power, duration)
    State.shakePower = power
    State.shakeDuration = duration
    State.shakeUntil = os.clock() + duration
end

local function faceHatredAtPlayer()
    local model = State.hatred
    if not model or not model.Parent or not State.root or not State.root.Parent then
        return
    end
    local targetPosition
    if State.cameraMode == "normal" and State.camera and State.camera.Parent then
        targetPosition = State.camera.CFrame.Position
    elseif State.playerCameraOffset then
        targetPosition = (State.root.CFrame * State.playerCameraOffset).Position
    else
        targetPosition = State.root.Position
    end
    local current = model:GetPivot()
    local origin = current.Position
    local target = Vector3.new(targetPosition.X, origin.Y, targetPosition.Z)
    if (target - origin).Magnitude < 0.01 then
        return
    end
    local desired = CFrame.lookAt(origin, target) * CFrame.Angles(0, math.rad(CONFIG.HatredFacingOffsetDegrees), 0)
    if (current.LookVector - desired.LookVector).Magnitude > 0.001 then
        model:PivotTo(desired)
    end
end

local function setupCamera(root)
    local camera = Workspace.CurrentCamera
    if not camera then
        error("Workspace.CurrentCamera was not found")
    end
    State.camera = camera
    State.cameraSnapshot = {
        cameraType = camera.CameraType,
        cameraSubject = camera.CameraSubject,
        cframe = camera.CFrame,
        focus = camera.Focus,
        fieldOfView = camera.FieldOfView,
        fieldOfViewMode = camera.FieldOfViewMode,
    }
    State.playerCameraOffset = root.CFrame:ToObjectSpace(camera.CFrame)
    State.cameraFrame = camera.CFrame
    State.cameraMode = "manual"
    camera.CameraType = Enum.CameraType.Scriptable
    State.baseShake = 0.012
    State.shakePower = 0
    State.shakeUntil = 0
    State.shakeDuration = 0
    RunService:BindToRenderStep(CAMERA_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
        if not State.running or not State.camera or not State.camera.Parent then
            return
        end
        faceHatredAtPlayer()
        local frame = State.cameraFrame
        local focus = State.cameraFocus
        if State.cameraMode == "look_fixed" and State.followObject and State.fixedCameraPosition then
            local targetFrame = getWorldFrame(State.followObject)
            if targetFrame then
                focus = targetFrame.Position
                local position = State.fixedCameraPosition
                if (position - focus).Magnitude < 0.01 then
                    position = position + Vector3.new(0, 0, 1)
                end
                frame = CFrame.lookAt(position, focus)
                State.cameraFrame = frame
            end
        elseif State.cameraMode == "follow" and State.followObject then
            local targetFrame = getWorldFrame(State.followObject)
            if targetFrame then
                focus = targetFrame.Position
                local position = focus + State.followOffset
                if (position - focus).Magnitude < 0.01 then
                    position = focus + Vector3.new(0, 0, 1)
                end
                frame = CFrame.lookAt(position, focus)
                State.cameraFrame = frame
            end
        elseif State.cameraMode == "player" and State.root and State.root.Parent then
            if State.camera.FieldOfViewMode ~= Enum.FieldOfViewMode.Vertical then
                State.camera.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
            end
            if math.abs(State.camera.FieldOfView - CONFIG.PlayerLockFov) > 0.001 then
                State.camera.FieldOfView = CONFIG.PlayerLockFov
            end
            local holeFrame = getWorldFrame(State.blackHole)
            if holeFrame then
                focus = holeFrame.Position
                local position = (State.root.CFrame * State.playerCameraOffset).Position
                if (position - focus).Magnitude < 0.01 then
                    position = focus + Vector3.new(0, 0, 1)
                end
                frame = CFrame.lookAt(position, focus)
                State.cameraFrame = frame
            end
        end
        if not frame then
            return
        end
        local now = os.clock()
        local pulse = 0
        if now < State.shakeUntil and State.shakeDuration > 0 then
            pulse = State.shakePower * ((State.shakeUntil - now) / State.shakeDuration)
        end
        local amount = State.baseShake + pulse
        local x = math.noise(now * 11, 0, 0) * amount
        local y = math.noise(0, now * 13, 0) * amount
        local z = math.noise(0, 0, now * 9) * amount * 0.5
        if State.cameraMode == "look_fixed" then
            State.camera.CFrame = frame
        else
            State.camera.CFrame = frame * CFrame.new(x, y, z) * CFrame.Angles(y * 0.012, x * 0.012, z * 0.025)
        end
        if focus then
            State.camera.Focus = CFrame.new(focus)
        end
        if State.introBrand and State.introBrand.Parent then
            State.introBrand.Rotation = math.noise(now * 5, 10, 0) * 0.8
        end
        if State.introGradient and State.introGradient.Parent then
            State.introGradient.Offset = Vector2.new(math.sin(now * 2) * 0.65, 0)
        end
    end)
end

local function restoreCamera()
    pcall(function()
        RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)
    end)
    local camera = State.camera
    local saved = State.cameraSnapshot
    State.cameraSnapshot = nil
    if camera and saved then
        pcall(function()
            if saved.fieldOfViewMode then
                camera.FieldOfViewMode = saved.fieldOfViewMode
            end
            camera.FieldOfView = saved.fieldOfView
            camera.CameraSubject = saved.cameraSubject
            if saved.cameraType == Enum.CameraType.Scriptable then
                camera.CFrame = saved.cframe
                camera.Focus = saved.focus
            end
            camera.CameraType = saved.cameraType
        end)
    end
end

local function moveCamera(token, target, duration, targetFov)
    if not alive(token) then
        return false
    end
    State.cameraMode = "manual"
    local initial = State.cameraFrame
    local initialFov = State.camera.FieldOfView
    return animate(token, duration, function(alpha)
        State.cameraFrame = initial:Lerp(target, alpha)
        if targetFov then
            State.camera.FieldOfView = initialFov + (targetFov - initialFov) * alpha
        end
    end)
end

local function startInitialZoom(token, target, duration, targetFov)
    local initial = State.cameraFrame
    local initialFov = State.camera.FieldOfView
    State.cameraMode = "zoom"
    task.spawn(function()
        local ok, err = pcall(function()
            animate(token, duration, function(alpha)
                if State.cameraMode == "zoom" then
                    State.cameraFrame = initial:Lerp(target, alpha)
                    State.camera.FieldOfView = initialFov + (targetFov - initialFov) * alpha
                end
            end)
        end)
        if not ok and alive(token) then
            warn("Hatred phase 2 camera zoom stopped: " .. tostring(err))
            Controller.Stop()
        end
    end)
end

local function returnPlayerCamera(token, holePosition)
    if not alive(token) then
        return false
    end
    local playerFrame = State.root.CFrame * State.playerCameraOffset
    State.cameraMode = "manual"
    State.cameraFrame = playerFrame
    State.cameraFocus = playerFrame.Position + playerFrame.LookVector * 10
    State.camera.CFrame = playerFrame
    State.camera.Focus = CFrame.new(State.cameraFocus)
    State.camera.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
    State.camera.FieldOfView = CONFIG.PlayerLockFov
    RunService.RenderStepped:Wait()
    if not alive(token) then
        return false
    end
    local cameraPosition = playerFrame.Position
    if (holePosition - cameraPosition).Magnitude < 0.01 then
        cameraPosition = cameraPosition + Vector3.new(0, 0, 1)
    end
    local facingHole = CFrame.lookAt(cameraPosition, holePosition)
    State.cameraFocus = holePosition
    State.cameraFrame = facingHole
    State.camera.CFrame = facingHole
    State.camera.Focus = CFrame.new(holePosition)
    State.camera.CameraSubject = State.cameraSnapshot.cameraSubject or State.humanoid
    State.camera.CameraType = Enum.CameraType.Scriptable
    State.cameraMode = "player"
    return true
end

local function viewToward(origin, target, distance)
    local delta = origin - target
    local direction = delta.Magnitude > 0.01 and delta.Unit or Vector3.new(0, 0, 1)
    return CFrame.lookAt(target + direction * distance, target)
end

local function moveObject(token, object, target, duration)
    local initial = getWorldFrame(object)
    if not initial then
        error("Unable to move " .. object.Name)
    end
    return animate(token, duration, function(alpha)
        if not setWorldFrame(object, initial:Lerp(target, alpha)) then
            error("The moving object was removed during the scene")
        end
    end)
end

local function moveHatsBlackWithCamera(token, object)
    local initial = getWorldFrame(object)
    if not initial then
        error("HATSBLACK was not found during the ascent")
    end
    local target = initial + Vector3.new(0, CONFIG.BlackLift, 0)
    local fixedPosition = State.fixedCameraPosition
    local switched = false
    return animate(token, CONFIG.BlackLiftDuration, function(alpha)
        if not setWorldFrame(object, initial:Lerp(target, alpha)) then
            error("HATSBLACK was removed during the ascent")
        end
        if not switched and alpha >= 0.5 then
            switched = true
            local current = getWorldFrame(object).Position
            local delta = fixedPosition - current
            local direction = delta.Magnitude > 0.01 and delta.Unit or Vector3.new(0, 0, 1)
            State.followOffset = direction * CONFIG.HatsBlackCameraDistance
            State.cameraFrame = CFrame.lookAt(current + State.followOffset, current)
            State.cameraMode = "follow"
        end
    end)
end

local function replacementFrame(holePosition)
    local playerView = State.root.CFrame * State.playerCameraOffset
    local towardHole = holePosition - playerView.Position
    local horizontal = Vector3.new(towardHole.X, 0, towardHole.Z)
    if horizontal.Magnitude < 0.01 then
        local look = playerView.LookVector
        horizontal = Vector3.new(look.X, 0, look.Z)
    end
    if horizontal.Magnitude < 0.01 then
        local look = State.root.CFrame.LookVector
        horizontal = Vector3.new(look.X, 0, look.Z)
    end
    local direction = horizontal.Magnitude > 0.01 and horizontal.Unit or Vector3.new(0, 0, -1)
    local playerPosition = State.root.Position
    local position = Vector3.new(
        playerPosition.X + direction.X * CONFIG.ReplacementViewDistance,
        playerPosition.Y + CONFIG.ReplacementHoverHeight,
        playerPosition.Z + direction.Z * CONFIG.ReplacementViewDistance
    )
    return CFrame.new(position)
end

local function make(className, parent, properties)
    local object = Instance.new(className)
    if properties then
        for key, value in pairs(properties) do
            object[key] = value
        end
    end
    object.Parent = parent
    return object
end

local function rounded(object, radius)
    return make("UICorner", object, {CornerRadius = UDim.new(0, radius)})
end

local function outline(object, color, transparency, thickness)
    return make("UIStroke", object, {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    })
end

local function makeScreen()
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = make("ScreenGui", playerGui, {
        Name = "HatredPhaseTwoUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = 16000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    State.gui = gui
    local scene = make("CanvasGroup", gui, {
        Name = "Scene",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
    })
    local topBar = make("Frame", scene, {
        Name = "TopBar",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 0.075),
        Position = UDim2.fromScale(0, -0.075),
        ZIndex = 10,
    })
    local bottomBar = make("Frame", scene, {
        Name = "BottomBar",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 0.075),
        Position = UDim2.fromScale(0, 1),
        ZIndex = 10,
    })
    local blackout = make("Frame", scene, {
        Name = "Blackout",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 90,
    })
    local whiteFlash = make("Frame", scene, {
        Name = "WhiteFlash",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 100,
    })
    local win = make("TextLabel", gui, {
        Name = "WinText",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.7, 0.15),
        BackgroundTransparency = 1,
        Text = "You won",
        TextColor3 = Color3.fromRGB(255, 244, 242),
        TextStrokeColor3 = Color3.fromRGB(93, 0, 0),
        TextStrokeTransparency = 1,
        TextTransparency = 1,
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        ZIndex = 110,
    })
    make("UITextSizeConstraint", win, {MaxTextSize = 58, MinTextSize = 18})
    State.blur = make("BlurEffect", Lighting, {Name = "HatredPhaseTwoBlur", Size = 0})
    playTween(topBar, 1.25, {Position = UDim2.fromScale(0, 0)})
    playTween(bottomBar, 1.25, {Position = UDim2.fromScale(0, 0.925)})
    playTween(State.blur, 2, {Size = 2})
    return {gui = gui, scene = scene, blackout = blackout, whiteFlash = whiteFlash, win = win}
end

local function findSound(name)
    local folder = Workspace:FindFirstChild("HardCoreSound", true) or ReplicatedStorage:FindFirstChild("HardCoreSound", true) or SoundService:FindFirstChild("HardCoreSound", true)
    if not folder then
        return nil
    end
    local exact = folder:FindFirstChild(name, true)
    local result
    if exact and exact:IsA("Sound") then
        result = exact
    end
    if not result then
        for _, object in ipairs(folder:GetDescendants()) do
            if object:IsA("Sound") and string.lower(object.Name) == string.lower(name) then
                result = object
                break
            end
        end
    end
    if result and result:IsDescendantOf(ReplicatedStorage) then
        result = result:Clone()
        result.Parent = SoundService
        table.insert(State.ownedSounds, result)
    end
    return result
end

local function rememberSound(sound)
    if sound and not State.sharedSounds[sound] then
        local pending = PendingAudio[sound]
        if pending then
            PendingAudio[sound] = nil
            for _, connection in ipairs(pending.connections) do
                disconnect(connection)
            end
            if pending.fadeInTween then
                pcall(function()
                    pending.fadeInTween:Cancel()
                end)
            end
            if pending.saved and not pending.owned then
                pcall(function()
                    sound.Volume = pending.saved.volume
                    sound.Looped = pending.saved.looped
                end)
            end
        end
        State.sharedSounds[sound] = {volume = sound.Volume, looped = sound.Looped}
    end
end

local function startHatredMusic(token)
    local sound = findSound("HATRED")
    if not sound then
        warn("Hatred phase 2: HardCoreSound.HATRED was not found; the scene will continue without it")
        return
    end
    rememberSound(sound)
    sound:Stop()
    local timeoutAt = os.clock() + CONFIG.HatredMusicLoadTimeout
    while alive(token) and sound.Parent and not sound.IsLoaded and os.clock() < timeoutAt do
        task.wait(0.05)
    end
    if not alive(token) then
        return
    end
    if not sound.Parent or not sound.IsLoaded then
        warn("Hatred phase 2: HATRED music could not be loaded; the scene will continue without it")
        return
    end
    if sound.TimeLength > 0 and sound.TimeLength <= CONFIG.HatredMusicStart then
        warn("Hatred phase 2: HATRED must be longer than " .. CONFIG.HatredMusicStart .. " seconds")
        return
    end
    sound.Volume = 0
    sound.Looped = true
    sound:Play()
    sound.TimePosition = CONFIG.HatredMusicStart
    State.musicFadeInSound = sound
    State.musicFadeInTween = playTween(sound, CONFIG.HatredMusicFadeIn, {Volume = CONFIG.HatredMusicVolume})
end

local function startHat2(token)
    local sound = findSound("HAT2")
    if not sound then
        error("HardCoreSound.HAT2 was not found; it is required for the scene timing")
    end
    rememberSound(sound)
    sound:Stop()
    local timeoutAt = os.clock() + CONFIG.Hat2LoadTimeout
    while alive(token) and sound.Parent and not sound.IsLoaded and os.clock() < timeoutAt do
        task.wait(0.05)
    end
    if not alive(token) then
        return nil
    end
    if not sound.Parent or not sound.IsLoaded then
        error("HardCoreSound.HAT2 could not be loaded; check the asset and its permissions")
    end
    if sound.TimeLength > 0 and sound.TimeLength <= CONFIG.ScaleAt then
        error("HardCoreSound.HAT2 must be longer than " .. CONFIG.ScaleAt .. " seconds")
    end
    sound:Play()
    return sound
end

local function waitForSoundPosition(token, sound, targetPosition)
    local lastPosition = sound.TimePosition
    local lastProgressAt = os.clock()
    while alive(token) do
        if not sound.Parent then
            error("HardCoreSound.HAT2 was removed during the scene")
        end
        if sound.TimePosition >= targetPosition then
            return true
        end
        if not sound.Playing then
            error("HardCoreSound.HAT2 stopped before " .. targetPosition .. " seconds")
        end
        if sound.TimePosition > lastPosition + 0.001 then
            lastPosition = sound.TimePosition
            lastProgressAt = os.clock()
        elseif os.clock() - lastProgressAt > CONFIG.Hat2LoadTimeout then
            error("HardCoreSound.HAT2 stopped advancing; check the asset and playback")
        end
        task.wait(0.01)
    end
    return false
end

local function prepareCueSounds(token)
    local scaleSound = make("Sound", SoundService, {
        Name = "HatredPhaseTwoScaleLoop",
        SoundId = "rbxassetid://" .. CONFIG.ScaleSoundId,
        Volume = CONFIG.ScaleSoundVolume,
        Looped = true,
    })
    local appearanceSound = make("Sound", SoundService, {
        Name = "HatredPhaseTwoBlackHoleAppearance",
        SoundId = "rbxassetid://" .. CONFIG.BlackHoleAppearanceSoundId,
        Volume = CONFIG.BlackHoleAppearanceSoundVolume,
        Looped = false,
    })
    local expandedSound = make("Sound", SoundService, {
        Name = "HatredPhaseTwoExpandedLoop",
        SoundId = "rbxassetid://" .. CONFIG.BlackHoleExpandedSoundId,
        Volume = CONFIG.BlackHoleExpandedSoundVolume,
        Looped = true,
    })
    local endingSound = make("Sound", SoundService, {
        Name = "HatredPhaseTwoEnding",
        SoundId = "rbxassetid://" .. CONFIG.EndingSoundId,
        Volume = CONFIG.EndingSoundVolume,
        Looped = false,
    })
    State.effectSound = scaleSound
    State.appearanceSound = appearanceSound
    State.expandedSound = expandedSound
    State.endingSound = endingSound
    addConnection(appearanceSound.Ended:Connect(function()
        if State.appearanceSound == appearanceSound then
            State.appearanceSound = nil
        end
        destroy(appearanceSound)
    end))
    addConnection(endingSound.Ended:Connect(function()
        if State.endingSound == endingSound then
            State.endingSound = nil
        end
        destroy(endingSound)
    end))
    task.spawn(function()
        local ok, err = pcall(function()
            ContentProvider:PreloadAsync({scaleSound, appearanceSound, expandedSound, endingSound})
        end)
        if not ok and alive(token) then
            warn("Hatred phase 2: audio preload failed: " .. tostring(err))
        end
    end)
end

local function playCueSound(sound, label)
    if not sound or not sound.Parent then
        error("Hatred phase 2: " .. label .. " sound was removed before its cue")
    end
    if not sound.IsLoaded then
        warn("Hatred phase 2: " .. label .. " sound is not loaded yet")
    end
    sound:Play()
end

local function startScaleSound()
    playCueSound(State.effectSound, "scale")
end

local function startAppearanceSound()
    playCueSound(State.appearanceSound, "appearance")
end

local function startExpandedSound()
    playCueSound(State.expandedSound, "expanded")
end

local function startEnding(screen, token)
    playCueSound(State.endingSound, "ending")
    local caption = make("CanvasGroup", screen.gui, {
        Name = "HatredAfterGameMessage",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 0.88),
        Size = UDim2.new(0.8, 0, 0, 64),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ZIndex = 120,
    })
    local text = make("TextLabel", caption, {
        Name = "Message",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "None of this feels real...",
        TextColor3 = Color3.fromRGB(255, 245, 242),
        TextStrokeColor3 = Color3.new(0, 0, 0),
        TextStrokeTransparency = 0.25,
        TextScaled = true,
        Font = Enum.Font.GothamMedium,
        ZIndex = 121,
    })
    make("UITextSizeConstraint", text, {MaxTextSize = 30, MinTextSize = 14})
    playTween(caption, CONFIG.EndingTextFadeDuration, {GroupTransparency = 0})
    task.spawn(function()
        if not waitCancelable(CONFIG.EndingTextFadeDuration + CONFIG.EndingTextHoldDuration, token) then
            return
        end
        playTween(caption, CONFIG.EndingTextFadeDuration, {GroupTransparency = 1})
        if not waitCancelable(CONFIG.EndingTextFadeDuration, token) then
            return
        end
        destroy(caption)
    end)
end

local function fadeSounds()
    for sound in pairs(State.sharedSounds) do
        if sound.Parent then
            playTween(sound, CONFIG.MusicFadeDuration, {Volume = 0})
        end
    end
    if State.effectSound and State.effectSound.Parent then
        playTween(State.effectSound, CONFIG.MusicFadeDuration, {Volume = 0})
    end
    if State.appearanceSound and State.appearanceSound.Parent then
        playTween(State.appearanceSound, CONFIG.MusicFadeDuration, {Volume = 0})
    end
    if State.expandedSound and State.expandedSound.Parent then
        playTween(State.expandedSound, CONFIG.MusicFadeDuration, {Volume = 0})
    end
end

local function finishSoundNaturally(sound, record)
    if not sound or not sound.Parent then
        if record.fadeInTween then
            pcall(function()
                record.fadeInTween:Cancel()
            end)
        end
        if record.owned then
            destroy(sound)
        end
        return
    end
    local entry = {connections = {}, saved = record.saved, owned = record.owned, fadeInTween = record.fadeInTween}
    PendingAudio[sound] = entry
    local function finish()
        if PendingAudio[sound] ~= entry then
            return
        end
        PendingAudio[sound] = nil
        for _, connection in ipairs(entry.connections) do
            disconnect(connection)
        end
        if entry.fadeInTween then
            pcall(function()
                entry.fadeInTween:Cancel()
            end)
        end
        pcall(function()
            sound:Pause()
        end)
        if entry.saved and not entry.owned then
            pcall(function()
                sound.Volume = entry.saved.volume
                sound.Looped = entry.saved.looped
            end)
        end
        if entry.owned then
            destroy(sound)
        end
    end
    local function connect(signal, callback)
        local ok, connection = pcall(function()
            return signal:Connect(callback)
        end)
        if ok and connection then
            table.insert(entry.connections, connection)
        end
    end
    connect(sound.Ended, finish)
    connect(sound.Stopped, finish)
    connect(sound.Paused, finish)
    pcall(function()
        connect(sound:GetPropertyChangedSignal("Playing"), function()
            if not sound.Playing then
                finish()
            end
        end)
        connect(sound:GetPropertyChangedSignal("Looped"), function()
            if PendingAudio[sound] == entry and sound.Looped then
                sound.Looped = false
            end
        end)
    end)
    pcall(function()
        sound.Looped = false
    end)
    if not sound.Playing then
        finish()
        return
    end
    task.spawn(function()
        local waitStarted = os.clock()
        while PendingAudio[sound] == entry do
            if not sound.Parent or not sound.Playing then
                finish()
                return
            end
            if not sound.IsLoaded and os.clock() - waitStarted > CONFIG.Hat2LoadTimeout then
                warn("Hatred phase 2: a sound could not be loaded")
                finish()
                return
            end
            task.wait(0.25)
        end
    end)
end

local function stopSounds(finishAfterDeath, finishEndingSound)
    local records = {}
    for sound, saved in pairs(State.sharedSounds) do
        records[sound] = {saved = saved, owned = false}
    end
    local function addOwned(sound)
        if sound then
            records[sound] = records[sound] or {}
            records[sound].owned = true
        end
    end
    for _, sound in ipairs(State.ownedSounds) do
        addOwned(sound)
    end
    addOwned(State.effectSound)
    addOwned(State.appearanceSound)
    addOwned(State.expandedSound)
    addOwned(State.endingSound)
    if finishEndingSound and State.endingSound and records[State.endingSound] then
        records[State.endingSound].finishNaturally = true
    end
    if finishAfterDeath and State.musicFadeInSound and records[State.musicFadeInSound] then
        records[State.musicFadeInSound].fadeInTween = State.musicFadeInTween
    end
    State.sharedSounds = {}
    State.ownedSounds = {}
    State.musicFadeInSound = nil
    State.musicFadeInTween = nil
    State.effectSound = nil
    State.appearanceSound = nil
    State.expandedSound = nil
    State.endingSound = nil
    for sound, record in pairs(records) do
        if finishAfterDeath or record.finishNaturally then
            finishSoundNaturally(sound, record)
        else
            pcall(function()
                sound:Stop()
                if record.saved and not record.owned then
                    sound.Volume = record.saved.volume
                    sound.Looped = record.saved.looped
                end
            end)
            if record.owned then
                destroy(sound)
            end
        end
    end
end

local function showWarning(scene, token)
    local prompt = make("CanvasGroup", scene, {
        Name = "EscapeWarning",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.38),
        Size = UDim2.new(0.86, 0, 0, 88),
        BackgroundTransparency = 1,
        GroupTransparency = 1,
        ZIndex = 35,
    })
    make("UISizeConstraint", prompt, {MaxSize = Vector2.new(930, 88)})
    local function label(text, x, width, color)
        local result = make("TextLabel", prompt, {
            Position = UDim2.fromScale(x, 0),
            Size = UDim2.fromScale(width, 1),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = color,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 0.15,
            TextScaled = true,
            Font = Enum.Font.GothamBlack,
            ZIndex = 36,
        })
        make("UITextSizeConstraint", result, {MaxTextSize = 43, MinTextSize = 8})
        return result
    end
    label("Get out of ", 0, 0.38, Color3.fromRGB(255, 246, 242))
    local brand = label("HatRed", 0.38, 0.23, Color3.new(1, 1, 1))
    label(" control!!!", 0.61, 0.39, Color3.fromRGB(255, 246, 242))
    local gradient = make("UIGradient", brand, {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 28, 12)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 145, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 35, 18)),
        }),
    })
    State.introBrand = brand
    State.introGradient = gradient
    playTween(prompt, 0.5, {GroupTransparency = 0})
    if not waitCancelable(3.3, token) then
        return false
    end
    playTween(prompt, 0.5, {GroupTransparency = 1})
    if not waitCancelable(0.55, token) then
        return false
    end
    State.introBrand = nil
    State.introGradient = nil
    destroy(prompt)
    return true
end

local function makeChallenge(scene)
    local group = make("CanvasGroup", scene, {
        Name = "EscapeChallenge",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.52),
        Size = UDim2.fromScale(0.88, 0.72),
        BackgroundColor3 = Color3.fromRGB(9, 4, 8),
        BackgroundTransparency = 0.09,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 20,
    })
    make("UISizeConstraint", group, {MaxSize = Vector2.new(640, 590)})
    rounded(group, 15)
    outline(group, Color3.fromRGB(186, 46, 35), 0.22, 2)
    local background = make("ImageLabel", group, {
        Name = "BackgroundTexture",
        BackgroundTransparency = 1,
        Image = "rbxassetid://108241048414941",
        ImageTransparency = 0.87,
        ScaleType = Enum.ScaleType.Crop,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 21,
    })
    rounded(background, 15)
    local function text(name, content, position, size, textSize, color, zIndex)
        return make("TextLabel", group, {
            Name = name,
            BackgroundTransparency = 1,
            Position = position,
            Size = size,
            Text = content,
            Font = Enum.Font.GothamBold,
            TextColor3 = color,
            TextSize = textSize,
            TextScaled = false,
            TextWrapped = true,
            ZIndex = zIndex or 23,
        })
    end
    local heading = text("Heading", "BREAK THE CONTROL", UDim2.fromScale(0.05, 0.035), UDim2.fromScale(0.9, 0.075), 20, Color3.fromRGB(255, 225, 214))
    heading.TextScaled = true
    make("UITextSizeConstraint", heading, {MaxTextSize = 22, MinTextSize = 12})
    local subheading = text("Subheading", "PRESS THE LETTER BEFORE TIME RUNS OUT", UDim2.fromScale(0.05, 0.12), UDim2.fromScale(0.9, 0.055), 13, Color3.fromRGB(185, 147, 142))
    subheading.TextScaled = true
    make("UITextSizeConstraint", subheading, {MaxTextSize = 13, MinTextSize = 8})
    local timer = text("Timer", "01:00", UDim2.fromScale(0.05, 0.2), UDim2.fromScale(0.9, 0.075), 25, Color3.fromRGB(255, 168, 128))
    timer.TextScaled = true
    make("UITextSizeConstraint", timer, {MaxTextSize = 28, MinTextSize = 12})
    local letter = text("Letter", "?", UDim2.fromScale(0.1, 0.275), UDim2.fromScale(0.8, 0.23), 80, Color3.fromRGB(255, 244, 238))
    letter.Font = Enum.Font.GothamBlack
    letter.TextScaled = true
    make("UITextSizeConstraint", letter, {MaxTextSize = 100, MinTextSize = 28})
    local letterGradient = make("UIGradient", letter, {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 94, 56)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 205, 167)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 69, 37)),
        }),
    })
    local track = make("Frame", group, {
        Name = "TimeTrack",
        BackgroundColor3 = Color3.fromRGB(52, 22, 23),
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.12, 0.515),
        Size = UDim2.fromScale(0.76, 0.016),
        ZIndex = 23,
    })
    rounded(track, 8)
    local fill = make("Frame", track, {
        Name = "Fill",
        BackgroundColor3 = Color3.fromRGB(255, 92, 49),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 24,
    })
    rounded(fill, 8)
    local feedback = text("Feedback", "STAY FOCUSED", UDim2.fromScale(0.05, 0.55), UDim2.fromScale(0.9, 0.07), 14, Color3.fromRGB(232, 176, 157))
    feedback.TextScaled = true
    make("UITextSizeConstraint", feedback, {MaxTextSize = 16, MinTextSize = 9})
    local keyboard = make("Frame", group, {
        Name = "Keyboard",
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.07, 0.64),
        Size = UDim2.fromScale(0.86, 0.31),
        ZIndex = 24,
    })
    make("UIGridLayout", keyboard, {
        CellSize = UDim2.new(1 / 7, -4, 1 / 4, -4),
        CellPadding = UDim2.fromOffset(4, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local buttons = {}
    for index = 1, 26 do
        local char = string.char(64 + index)
        local button = make("TextButton", keyboard, {
            Name = "Key" .. char,
            LayoutOrder = index,
            BackgroundColor3 = Color3.fromRGB(48, 24, 25),
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            AutoButtonColor = true,
            Text = char,
            TextColor3 = Color3.fromRGB(251, 225, 218),
            Font = Enum.Font.GothamBold,
            TextScaled = true,
            ZIndex = 25,
        })
        rounded(button, 5)
        make("UITextSizeConstraint", button, {MaxTextSize = 22, MinTextSize = 8})
        buttons[char] = button
    end
    return {group = group, heading = heading, subheading = subheading, timer = timer, letter = letter, gradient = letterGradient, track = track, fill = fill, feedback = feedback, keyboard = keyboard, buttons = buttons}
end

local function touchControlsPreferred()
    if UserInputService.TouchEnabled ~= true then
        return false
    end
    if UserInputService.KeyboardEnabled ~= true then
        return true
    end
    local ok, preferred = pcall(function()
        return UserInputService.PreferredInput
    end)
    if ok and preferred then
        return preferred == Enum.PreferredInput.Touch
    end
    return false
end

local function layoutChallenge(ui, touch)
    ui.keyboard.Visible = touch
    if touch then
        ui.group.Size = UDim2.fromScale(0.88, 0.72)
        ui.heading.Position, ui.heading.Size = UDim2.fromScale(0.05, 0.035), UDim2.fromScale(0.9, 0.075)
        ui.subheading.Position, ui.subheading.Size = UDim2.fromScale(0.05, 0.12), UDim2.fromScale(0.9, 0.055)
        ui.timer.Position, ui.timer.Size = UDim2.fromScale(0.05, 0.2), UDim2.fromScale(0.9, 0.075)
        ui.letter.Position, ui.letter.Size = UDim2.fromScale(0.1, 0.275), UDim2.fromScale(0.8, 0.23)
        ui.track.Position, ui.track.Size = UDim2.fromScale(0.12, 0.515), UDim2.fromScale(0.76, 0.016)
        ui.feedback.Position, ui.feedback.Size = UDim2.fromScale(0.05, 0.55), UDim2.fromScale(0.9, 0.07)
    else
        ui.group.Size = UDim2.fromScale(0.72, 0.51)
        ui.heading.Position, ui.heading.Size = UDim2.fromScale(0.05, 0.045), UDim2.fromScale(0.9, 0.12)
        ui.subheading.Position, ui.subheading.Size = UDim2.fromScale(0.05, 0.16), UDim2.fromScale(0.9, 0.08)
        ui.timer.Position, ui.timer.Size = UDim2.fromScale(0.05, 0.27), UDim2.fromScale(0.9, 0.1)
        ui.letter.Position, ui.letter.Size = UDim2.fromScale(0.1, 0.37), UDim2.fromScale(0.8, 0.32)
        ui.track.Position, ui.track.Size = UDim2.fromScale(0.12, 0.72), UDim2.fromScale(0.76, 0.018)
        ui.feedback.Position, ui.feedback.Size = UDim2.fromScale(0.05, 0.78), UDim2.fromScale(0.9, 0.1)
    end
end

local function startSuction(scene, token)
    local overlay = make("Frame", scene, {
        Name = "SuctionEffect",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 15,
    })
    State.suctionOverlay = overlay
    local streaks = {}
    for index = 1, 26 do
        local angle = (index / 26) * math.pi * 2
        local streak = make("Frame", overlay, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = index % 3 == 0 and Color3.fromRGB(255, 109, 69) or Color3.fromRGB(255, 238, 229),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Rotation = math.deg(angle),
            ZIndex = 16,
        })
        rounded(streak, 4)
        table.insert(streaks, {frame = streak, angle = angle, offset = (index % 7) / 7})
    end
    local startedAt = os.clock()
    addConnection(RunService.RenderStepped:Connect(function()
        if not alive(token) or not overlay.Parent then
            return
        end
        local elapsed = os.clock() - startedAt
        local subtle = State.cameraMode == "player"
        for _, item in ipairs(streaks) do
            local progress = (elapsed * CONFIG.SuctionStreakSpeed + item.offset) % 1
            local radius = 0.72 * (1 - progress)
            item.frame.Position = UDim2.fromScale(0.5 + math.cos(item.angle) * radius, 0.5 + math.sin(item.angle) * radius)
            item.frame.Size = UDim2.new(0.03 + 0.12 * (1 - progress), 0, 0, 2 + 5 * (1 - progress))
            item.frame.BackgroundTransparency = math.clamp((subtle and 0.45 or 0.2) + 0.45 * progress, 0, 1)
        end
    end))
end

local function startChromaticRadial(scene, token)
    local overlay = make("Frame", scene, {
        Name = "ChromaticRadial",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 17,
    })
    State.chromaticOverlay = overlay
    local colors = {
        Color3.fromRGB(255, 45, 45),
        Color3.fromRGB(55, 255, 105),
        Color3.fromRGB(55, 110, 255),
    }
    local edgeToCenter = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.48),
        NumberSequenceKeypoint.new(0.5, 0.82),
        NumberSequenceKeypoint.new(1, 1),
    })
    local centerToEdge = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.82),
        NumberSequenceKeypoint.new(1, 0.48),
    })
    local edges = {
        {name = "LeftEdge", position = UDim2.fromScale(0, 0), size = UDim2.fromScale(0.3, 1), color = colors[1], rotation = 0, fade = edgeToCenter},
        {name = "RightEdge", position = UDim2.fromScale(0.7, 0), size = UDim2.fromScale(0.3, 1), color = colors[3], rotation = 0, fade = centerToEdge},
        {name = "TopEdge", position = UDim2.fromScale(0, 0), size = UDim2.fromScale(1, 0.3), color = colors[3], rotation = 90, fade = edgeToCenter},
        {name = "BottomEdge", position = UDim2.fromScale(0, 0.7), size = UDim2.fromScale(1, 0.3), color = colors[2], rotation = 90, fade = centerToEdge},
    }
    for _, edge in ipairs(edges) do
        local frame = make("Frame", overlay, {
            Name = edge.name,
            Position = edge.position,
            Size = edge.size,
            BackgroundColor3 = edge.color,
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            ZIndex = 17,
        })
        make("UIGradient", frame, {Rotation = edge.rotation, Transparency = edge.fade})
    end
    local rays = {}
    local transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.22, 1),
        NumberSequenceKeypoint.new(0.55, 0.88),
        NumberSequenceKeypoint.new(0.84, 0.56),
        NumberSequenceKeypoint.new(1, 0.78),
    })
    for index = 1, 16 do
        local baseAngle = (index - 1) * math.pi * 2 / 16
        for channel, color in ipairs(colors) do
            for layer = 1, 2 do
                local ray = make("Frame", overlay, {
                    Name = "Ray" .. index .. "_" .. channel .. "_" .. layer,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = color,
                    BackgroundTransparency = layer == 1 and 0.68 or 0.42,
                    BorderSizePixel = 0,
                    ZIndex = 18,
                })
                make("UIGradient", ray, {Transparency = transparency})
                table.insert(rays, {
                    frame = ray,
                    angle = baseAngle + (channel - 2) * 0.014,
                    width = layer == 1 and 28 or 5,
                    index = index,
                })
            end
        end
    end
    local startedAt = os.clock()
    local lastUpdate = -1
    addConnection(RunService.RenderStepped:Connect(function()
        if not alive(token) or not overlay.Parent then
            return
        end
        local elapsed = os.clock() - startedAt
        if lastUpdate >= 0 and elapsed - lastUpdate < 0.06 then
            return
        end
        lastUpdate = elapsed
        local viewport = State.camera and State.camera.ViewportSize
        local width = viewport and viewport.X > 1 and viewport.X or 1280
        local height = viewport and viewport.Y > 1 and viewport.Y or 720
        local length = math.sqrt(width * width + height * height) * 0.78
        for _, ray in ipairs(rays) do
            local angle = ray.angle + math.sin(elapsed * 2.1 + ray.index) * 0.009
            ray.frame.Position = UDim2.new(0.5, math.cos(angle) * length * 0.5, 0.5, math.sin(angle) * length * 0.5)
            ray.frame.Size = UDim2.fromOffset(length, ray.width)
            ray.frame.Rotation = math.deg(angle)
        end
    end))
end

local function startBlackHoleJitter(token)
    local hole = State.blackHole
    if not hole or not hole.Parent then
        return
    end
    local startedAt = os.clock()
    local lastUpdate = -math.huge
    local lastOffset = CFrame.new()
    addConnection(RunService.Heartbeat:Connect(function()
        if not alive(token) or not hole.Parent then
            return
        end
        local now = os.clock()
        if now - lastUpdate < 1 / 30 then
            return
        end
        lastUpdate = now
        local elapsed = now - startedAt
        local positionStrength = CONFIG.BlackHoleModelShakePosition
        local rotationStrength = CONFIG.BlackHoleModelShakeRotation
        local offset = CFrame.new(
            math.noise(elapsed * 13, 10, 0) * positionStrength,
            math.noise(0, elapsed * 15, 7) * positionStrength * 0.75,
            math.noise(5, 0, elapsed * 11) * positionStrength * 0.55
        ) * CFrame.Angles(
            math.rad(math.noise(elapsed * 12, 2, 0) * rotationStrength),
            math.rad(math.noise(3, elapsed * 14, 0) * rotationStrength),
            math.rad(math.noise(0, 4, elapsed * 10) * rotationStrength * 0.65)
        )
        hole:PivotTo(hole:GetPivot() * lastOffset:Inverse() * offset)
        lastOffset = offset
    end))
end

local function suctionImpact(token)
    local initial = State.cameraFrame
    local holeFrame = getWorldFrame(State.blackHole)
    local focus = holeFrame and holeFrame.Position
    local target = initial
    if focus then
        local distance = (initial.Position - focus).Magnitude
        target = viewToward(initial.Position, focus, math.max(1, distance * CONFIG.SuctionDistanceFactor))
    end
    local startingFov = State.camera.FieldOfView
    return animate(token, CONFIG.SuctionDuration, function(alpha)
        State.cameraFrame = initial:Lerp(target, alpha)
        State.camera.FieldOfView = startingFov + (CONFIG.SuctionWideFov - startingFov) * alpha
    end)
end

local function killForWrongInput(challenge)
    if not challenge.active then
        return
    end
    challenge.active = false
    challenge.failed = true
    local humanoid = State.humanoid
    local fired, err = pcall(function()
        if type(replicatesignal) ~= "function" then
            error("replicatesignal is unavailable")
        end
        replicatesignal(player.Kill)
    end)
    if not fired then
        warn("Hatred phase 2: player.Kill signal failed: " .. tostring(err))
        pcall(function()
            if humanoid and humanoid.Parent then
                humanoid.Health = 0
            end
        end)
    end
    Controller.Stop("death")
end

local function runChallenge(scene, token)
    local ui = makeChallenge(scene)
    local challenge = {
        active = true,
        target = nil,
        correct = 0,
        wrong = 0,
        missed = 0,
        deadline = 0,
        window = 0,
        readyAt = 0,
        lastTarget = nil,
        isFake = false,
        fakeKey = nil,
        fakeUntil = 0,
        fakeShownAt = 0,
        revealedAt = 0,
    }
    State.challenge = challenge
    layoutChallenge(ui, touchControlsPreferred())
    local layoutOk, layoutConnection = pcall(function()
        return UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
            if alive(token) and challenge.active then
                layoutChallenge(ui, touchControlsPreferred())
            end
        end)
    end)
    if layoutOk then
        addConnection(layoutConnection)
    end
    State.mouseSnapshot = {
        behavior = UserInputService.MouseBehavior,
        icon = UserInputService.MouseIconEnabled,
    }
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
    playTween(ui.group, 0.5, {GroupTransparency = 0})
    local startedAt = os.clock()
    local finishedAt = startedAt + CONFIG.KeyboardDuration
    local promptsSinceDecoy = 0

    local function submit(char)
        if not alive(token) or not challenge.active or not challenge.target or os.clock() >= challenge.deadline then
            return
        end
        if challenge.isFake then
            challenge.wrong = challenge.wrong + 1
            killForWrongInput(challenge)
            return
        end
        if char == challenge.target then
            challenge.correct = challenge.correct + 1
            challenge.lastTarget = challenge.target
            challenge.target = nil
            challenge.readyAt = os.clock() + CONFIG.PromptGap
            ui.feedback.Text = "CORRECT"
            ui.feedback.TextColor3 = Color3.fromRGB(255, 208, 160)
        else
            challenge.wrong = challenge.wrong + 1
            killForWrongInput(challenge)
        end
    end

    for char, button in pairs(ui.buttons) do
        local key = char
        addConnection(button.Activated:Connect(function()
            submit(key)
        end))
    end
    local digitKeys = {
        Zero = true, One = true, Two = true, Three = true, Four = true,
        Five = true, Six = true, Seven = true, Eight = true, Nine = true,
        KeypadZero = true, KeypadOne = true, KeypadTwo = true, KeypadThree = true, KeypadFour = true,
        KeypadFive = true, KeypadSix = true, KeypadSeven = true, KeypadEight = true, KeypadNine = true,
    }
    addConnection(UserInputService.InputBegan:Connect(function(input)
        if not challenge.active or UserInputService:GetFocusedTextBox() then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            if type(keyName) == "string" and keyName:match("^[A-Z]$") then
                submit(keyName)
            elseif digitKeys[keyName] then
                submit(keyName)
            end
        end
    end))

    while alive(token) and os.clock() < finishedAt do
        local now = os.clock()
        local elapsed = now - startedAt
        local remaining = math.max(0, finishedAt - now)
        local secondsShown = math.ceil(remaining)
        ui.timer.Text = string.format("%02d:%02d", math.floor(secondsShown / 60), secondsShown % 60)
        ui.gradient.Offset = Vector2.new(math.sin(now * 2.4) * 0.65, 0)
        if challenge.target and challenge.isFake and now >= challenge.fakeUntil then
            challenge.isFake = false
            challenge.fakeKey = nil
            challenge.revealedAt = now
            challenge.deadline = math.min(finishedAt, now + challenge.window)
            ui.letter.Text = challenge.target
        end
        if challenge.target and not challenge.isFake and now >= challenge.deadline then
            challenge.missed = challenge.missed + 1
            challenge.lastTarget = challenge.target
            challenge.target = nil
            challenge.readyAt = now + CONFIG.PromptGap
            ui.feedback.Text = "TOO SLOW"
            ui.feedback.TextColor3 = Color3.fromRGB(255, 87, 67)
        end
        if not challenge.target and now >= challenge.readyAt then
            local available = "ABCDEFGHIKLNOPQRSTUVWXYZ"
            local index = math.random(1, #available)
            local nextKey = available:sub(index, index)
            if nextKey == challenge.lastTarget then
                index = ((index - 1 + math.random(1, #available - 1)) % #available) + 1
                nextKey = available:sub(index, index)
            end
            challenge.target = nextKey
            local progress = math.clamp(elapsed / CONFIG.KeyboardDuration, 0, 1)
            local difficulty = progress ^ CONFIG.PromptDifficultyCurve
            challenge.window = CONFIG.PromptStartWindow + (CONFIG.PromptEndWindow - CONFIG.PromptStartWindow) * difficulty
            promptsSinceDecoy = promptsSinceDecoy + 1
            challenge.isFake = remaining > CONFIG.DecoyDuration + 0.05 and (
                promptsSinceDecoy >= CONFIG.DecoyIntervalMax
                or (promptsSinceDecoy >= CONFIG.DecoyIntervalMin and math.random() < CONFIG.DecoyChance)
            )
            if challenge.isFake then
                promptsSinceDecoy = 0
                local fakeIndex = math.random(1, #available)
                if fakeIndex == index then
                    fakeIndex = ((fakeIndex - 1 + math.random(1, #available - 1)) % #available) + 1
                end
                challenge.fakeKey = available:sub(fakeIndex, fakeIndex)
                challenge.fakeShownAt = now
                challenge.fakeUntil = now + CONFIG.DecoyDuration
                challenge.deadline = finishedAt
                ui.letter.Text = challenge.fakeKey
            else
                challenge.fakeKey = nil
                challenge.revealedAt = now
                challenge.deadline = math.min(finishedAt, now + challenge.window)
                ui.letter.Text = nextKey
            end
            ui.feedback.Text = "PRESS THE MATCHING LETTER"
            ui.feedback.TextColor3 = Color3.fromRGB(232, 176, 157)
        end
        if challenge.target and challenge.isFake then
            ui.fill.Size = UDim2.fromScale(1, 1)
        elseif challenge.target then
            local fraction = math.clamp((challenge.deadline - now) / challenge.window, 0, 1)
            ui.fill.Size = UDim2.fromScale(fraction, 1)
        else
            ui.fill.Size = UDim2.fromScale(0, 1)
        end
        task.wait(0.04)
    end
    challenge.active = false
    if not alive(token) then
        return nil
    end
    if challenge.target and not challenge.isFake and os.clock() >= challenge.deadline then
        challenge.missed = challenge.missed + 1
        challenge.target = nil
    end
    ui.keyboard.Visible = false
    ui.fill.Size = UDim2.fromScale(0, 1)
    return ui
end

local function cleanup(finishAfterDeath)
    State.running = false
    if State.challenge then
        State.challenge.active = false
    end
    for _, connection in ipairs(State.connections) do
        disconnect(connection)
    end
    State.connections = {}
    local fadeInToPreserve = finishAfterDeath and State.musicFadeInTween or nil
    for _, tween in ipairs(State.tweens) do
        if tween ~= fadeInToPreserve then
            pcall(function()
                tween:Cancel()
            end)
        end
    end
    State.tweens = {}
    stopSounds(finishAfterDeath, State.ending and not finishAfterDeath)
    restoreRooms()
    restoreCamera()
    restorePlayer()
    if State.mouseSnapshot then
        pcall(function()
            UserInputService.MouseBehavior = State.mouseSnapshot.behavior
            UserInputService.MouseIconEnabled = State.mouseSnapshot.icon
        end)
        State.mouseSnapshot = nil
    end
    destroy(State.hatred)
    destroy(State.preloadedHatred)
    destroy(State.blackHole)
    destroy(State.blur)
    destroy(State.gui)
    State.hatred = nil
    State.preloadedHatred = nil
    State.blackHole = nil
    State.blur = nil
    State.gui = nil
    State.challenge = nil
    State.suctionOverlay = nil
    State.chromaticOverlay = nil
    State.fixedCameraPosition = nil
    State.introBrand = nil
    State.introGradient = nil
    State.ending = false
end

function Controller.Stop(reason)
    if State.running then
        State.token = State.token + 1
        cleanup(reason == "death")
    end
end

local function runEvent()
    if State.running then
        warn("Hatred phase 2 is already running")
        return
    end
    State.running = true
    State.ending = false
    State.token = State.token + 1
    local token = State.token
    local ok, err = xpcall(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local root = character:WaitForChild("HumanoidRootPart", 10)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not root or not root:IsA("BasePart") or not humanoid or not humanoid:IsA("Humanoid") then
            error("The player's HumanoidRootPart or Humanoid was not found")
        end
        local rooms, _, entrance = findRoomEntrance(token)
        if not alive(token) then
            return
        end
        local hatred = loadModel(CONFIG.HatredModelId, "HatredPhaseTwoModel")
        State.hatred = hatred
        hatred.Name = "HatredPhaseTwoEntity"
        local head = hatred:FindFirstChild("Head1", true)
        local hatsBlack = head and head:FindFirstChild("HATSBLACK", true)
        if not head or not getWorldFrame(head) or not hatsBlack or not getWorldFrame(hatsBlack) then
            error("The HATRED model must contain Head1 with a HATSBLACK descendant")
        end
        hideModelForReveal(head)
        local spawnPosition = (entrance.CFrame * CFrame.new(0, 5, -15)).Position
        local playerPosition = Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position or root.Position
        local facing = Vector3.new(playerPosition.X, spawnPosition.Y, playerPosition.Z)
        if (facing - spawnPosition).Magnitude < 0.01 then
            facing = spawnPosition + Vector3.new(0, 0, -1)
        end
        hatred.Parent = Workspace
        hatred:PivotTo(CFrame.lookAt(spawnPosition, facing) * CFrame.Angles(0, math.rad(CONFIG.HatredFacingOffsetDegrees), 0))
        lockPlayer(root, humanoid)
        setupCamera(root)
        local screen = makeScreen()
        prepareCueSounds(token)
        addConnection(humanoid.Died:Connect(function()
            Controller.Stop("death")
        end))
        addConnection(player.CharacterRemoving:Connect(function(oldCharacter)
            if oldCharacter == character then
                Controller.Stop(humanoid.Health <= 0 and "death" or nil)
            end
        end))

        local hatredPosition = hatred:GetPivot().Position
        State.cameraFocus = hatredPosition
        local closeToHatred = viewToward(State.cameraFrame.Position, hatredPosition, 6)
        if not moveCamera(token, closeToHatred, CONFIG.CameraFlightDuration, 62) then
            return
        end
        startHatredMusic(token)
        if not waitCancelable(CONFIG.HatredMusicFadeIn, token) then
            return
        end

        local headFrame = getWorldFrame(head)
        local liftedHead = (headFrame + Vector3.new(0, CONFIG.HeadLift, 0)) * CFrame.Angles(0, math.rad(CONFIG.HeadRotationDegrees), 0)
        if not moveObject(token, head, liftedHead, CONFIG.HeadMoveDuration) then
            return
        end
        local blackFrame = getWorldFrame(hatsBlack)
        if not blackFrame then
            error("HATSBLACK disappeared during the scene")
        end
        State.cameraFocus = blackFrame.Position
        State.followObject = hatsBlack
        State.fixedCameraPosition = State.cameraFrame.Position
        State.cameraMode = "look_fixed"
        if not fadeModelIn(head, token) then
            return
        end
        hideRooms(rooms)

        if not moveHatsBlackWithCamera(token, hatsBlack) then
            return
        end
        shakeFor(0.09, 0.55)
        screen.whiteFlash.BackgroundTransparency = 0
        playTween(screen.whiteFlash, 0.22, {BackgroundTransparency = 1})

        local hole = loadModel(CONFIG.BlackHoleModelId, "HatredBlackHoleModel")
        State.blackHole = hole
        hole.Name = "HatredPhaseTwoBlackHole"
        hole.Parent = Workspace
        blackFrame = getWorldFrame(hatsBlack)
        hole:PivotTo(blackFrame)
        startAppearanceSound()
        local originalScale = hole:GetScale()
        local originalSize = hole:GetExtentsSize().Magnitude
        local replacement = loadModel(CONFIG.ReplacementHatredModelId, "HatredPhaseTwoReplacementModel")
        State.preloadedHatred = replacement
        replacement.Name = "HatredPhaseTwoReplacement"
        State.cameraMode = "manual"
        local holePosition = hole:GetPivot().Position
        State.cameraFocus = holePosition
        local hat2 = startHat2(token)
        if not hat2 or not alive(token) then
            return
        end
        startInitialZoom(token, viewToward(State.cameraFrame.Position, holePosition, 3.5), CONFIG.InitialZoomDuration, 38)
        if not waitForSoundPosition(token, hat2, CONFIG.BlackoutAt) then
            return
        end
        State.cameraMode = "manual"
        screen.blackout.BackgroundTransparency = 0
        holePosition = hole:GetPivot().Position
        replacement.Parent = Workspace
        replacement:PivotTo(replacementFrame(holePosition))
        destroy(State.hatred)
        State.hatred = replacement
        State.preloadedHatred = nil
        faceHatredAtPlayer()
        if not waitForSoundPosition(token, hat2, CONFIG.ScaleAt) then
            return
        end
        if CONFIG.ScaleAt <= CONFIG.BlackoutAt then
            RunService.RenderStepped:Wait()
            if not alive(token) then
                return
            end
        end

        holePosition = hole:GetPivot().Position
        local pulledBackDistance = math.clamp(originalSize * CONFIG.BlackHoleScale * CONFIG.BlackHolePullbackMultiplier, 60, 2000)
        State.cameraFrame = viewToward(State.cameraFrame.Position, holePosition, pulledBackDistance)
        State.cameraFocus = holePosition
        State.camera.FieldOfView = CONFIG.BlackHoleWideFov
        startScaleSound()
        startSuction(screen.scene, token)
        State.baseShake = CONFIG.BlackHoleImpactShake
        shakeFor(1.8, 1.2)
        playTween(screen.blackout, 0.28, {BackgroundTransparency = 1})
        if not animate(token, CONFIG.ScaleDuration, function(alpha)
            hole:ScaleTo(originalScale * (1 + (CONFIG.BlackHoleScale - 1) * alpha))
        end) then
            return
        end
        startExpandedSound()
        startBlackHoleJitter(token)
        State.baseShake = CONFIG.BlackHoleShakeStrength
        shakeFor(3, 1.6)
        screen.whiteFlash.BackgroundTransparency = 0.15
        playTween(screen.whiteFlash, 0.3, {BackgroundTransparency = 1})
        playTween(State.blur, 0.35, {Size = 0})
        startChromaticRadial(screen.scene, token)
        if not suctionImpact(token) then
            return
        end
        if not returnPlayerCamera(token, hole:GetPivot().Position) then
            return
        end
        if not showWarning(screen.scene, token) then
            return
        end
        local challengeUI = runChallenge(screen.scene, token)
        if not challengeUI or not alive(token) then
            return
        end
        Controller.LastResult = {
            correct = State.challenge.correct,
            wrong = State.challenge.wrong,
            missed = State.challenge.missed,
        }
        State.ending = true
        playTween(screen.blackout, 0.3, {BackgroundTransparency = 0})
        if not waitCancelable(0.35, token) then
            return
        end
        restoreRooms()
        destroy(State.hatred)
        destroy(State.blackHole)
        State.hatred = nil
        State.blackHole = nil
        challengeUI.group.Visible = false
        restoreCamera()
        startEnding(screen, token)
        screen.win.TextTransparency = 1
        screen.win.TextStrokeTransparency = 1
        playTween(screen.win, 0.75, {TextTransparency = 0, TextStrokeTransparency = 0.2})
        playTween(screen.scene, CONFIG.ScreenFadeDuration, {GroupTransparency = 1})
        playTween(State.blur, CONFIG.ScreenFadeDuration, {Size = 0})
        fadeSounds()
        if not waitCancelable(2, token) then
            return
        end
        playTween(screen.win, math.max(1, CONFIG.ScreenFadeDuration - 2), {TextTransparency = 1, TextStrokeTransparency = 1})
        if not waitCancelable(math.max(CONFIG.ScreenFadeDuration, CONFIG.MusicFadeDuration) - 2 + 0.1, token) then
            return
        end
    end, debug.traceback)
    if State.token ~= token then
        return
    end
    if not ok then
        warn("Hatred phase 2 stopped: " .. tostring(err))
    end
    cleanup()
end

Controller.Start = runEvent
task.spawn(runEvent)
end

function entityBehaviors.Claim()
local currentLoadedRoom=workspace.CurrentRooms[game:GetService("ReplicatedStorage").GameData.LatestRoom.Value]
local eyes=game:GetObjects("rbxassetid://117078342673507")[1]
 
local num=0

if currentLoadedRoom:FindFirstChild("Nodes") then
   num = math.floor(#currentLoadedRoom.Nodes:GetChildren()/2)
end

eyes.RushNew.CFrame=(
	num==0 and currentLoadedRoom[currentLoadedRoom.Name] or currentLoadedRoom.Nodes[num]
).CFrame+Vector3.new(0,5,0)

eyes.Parent=workspace
				local function canSeeTarget(target,size)
					if killed == true then
						return
					end
					local origin = eyes.RushNew.Position
					local direction = (target.HumanoidRootPart.Position - eyes.RushNew.Position).unit * size
					local ray = Ray.new(origin, direction)

					local hit, pos = workspace:FindPartOnRay(ray, eyes.RushNew)


					if hit then
						if hit:IsDescendantOf(target) then
							killed = true
							return true
						end
					else
						return false
					end
				end
local particle = eyes.RushNew.Attachment
particle.ParticleEmitter.Enabled = false
particle.Spark.Enabled = false
    local death = Instance.new("Sound")
    death.Parent = workspace
    death.Name = "die"
    death.SoundId = "rbxassetid://5867708670"
    death.Volume = 0.7
    death.Pitch = 1
    local distort = Instance.new("DistortionSoundEffect")
    distort.Level = 0.9
    distort.Parent = death
    local cue = Instance.new("Sound")
    cue.Parent = workspace
    cue.Name = "Bubbles"
    cue.SoundId = "rbxassetid://9113601215"
    cue.Volume = 1
    cue.Pitch = 0.6
    local distort = Instance.new("DistortionSoundEffect")
    distort.Level = 0.7
    distort.Parent = cue
    cue.TimePosition = 1.25
wait(0.5)
particle.Spark.Enabled = true
cue:Play()
    wait(2)

				spawn(function()
					while eyes ~= nil do wait(0.2)
						local v = game.Players.LocalPlayer
						local parent = script.Parent
						if v.Character ~= nil and not v.Character:GetAttribute("Hiding") then
							if canSeeTarget(v.Character,50) then
								v.Character:FindFirstChildWhichIsA("Humanoid"):TakeDamage(100)
				game:GetService("ReplicatedStorage").GameStats["Player_".. game.Players.LocalPlayer.Name].Total.DeathCause.Value = "Claim"
				death:Play()
				local speaker = game.Players.LocalPlayer.Character
		for i,v in pairs(speaker:GetChildren()) do
			if v:IsA("BasePart") and
				v.Name == "Head" or
				v.Name == "RightUpperLeg" or
				v.Name == "LeftUpperLeg" or
				v.Name == "RightUpperArm" or
				v.Name == "LeftUpperArm" or
				v.Name == "RightLowerLeg" or
				v.Name == "LeftLowerLeg" or
				v.Name == "RightLowerArm" or
				v.Name == "LeftLowerArm" or
				v.Name == "RightFoot" or
				v.Name == "LeftFoot" or
				v.Name == "RightHand" or
				v.Name == "LeftHand" or
				v.Name == "UpperTorso" or
				v.Name == "LowerTorso" then
				v:Destroy()
			end
		end
		        wait(1.8)
		        loadstring(game:HttpGet("https://raw.githubusercontent.com/check78/GuidingLight/main/ClaimDie.txt"))()
							end
						end
					end
				end)
    particle.ParticleEmitter.Enabled = true
    local TweenService = game:GetService("TweenService")
    local cue2 = Instance.new("Sound")
    cue2.Parent = eyes.RushNew
    cue2.Name = "Idle"
    cue2.SoundId = "rbxassetid://8256091246"
    cue2.Volume = 1
    cue2.Pitch = 4
    local distort = Instance.new("DistortionSoundEffect")
    distort.Level = 0.9
    distort.Parent = cue2
local fl = Instance.new("FlangeSoundEffect")
fl.Depth = 0.06
fl.Mix = 0.85
fl.Rate = 5
fl.Parent = cue2
	cue2.RollOffMaxDistance = 90
	cue2.RollOffMinDistance = 5
	cue2.RollOffMode = Enum.RollOffMode.LinearSquare
    local TW = TweenService:Create(cue2, TweenInfo.new(1.5),{Pitch = 0})
    local TW2 = TweenService:Create(cue2, TweenInfo.new(1.5),{Volume = 0})
    local TW3 = TweenService:Create(cue2, TweenInfo.new(1.5),{Volume = 1})
    cue2:Play()
    TW3:Play()
    wait(7)
	eyes.RushNew.Anchored = false
	eyes.RushNew.CanCollide = false
    TW:Play()
    TW2:Play()
    wait(2)
    eyes:Destroy()
    death:Destroy()
    cue:Destroy()
end
function entityBehaviors.Honcho()
local CurrentRooms = workspace:FindFirstChild("CurrentRooms")
if not CurrentRooms then
	return
end

if workspace:FindFirstChild("SeekMovingNewClone") then
	return
end

local DEFAULTS = {
	Speed        = 70,
	Delay        = 3,
	Size         = 1.2,
	KillRange    = 40,
	Rebounds     = 0,
	Jumpscare    = true,
	Papers       = 400,
	Sync         = false,
	Debug        = false,
}

local SETTINGS = {}
for key, default in pairs(DEFAULTS) do
	local value = _G[key]
	_G[key] = nil
	if value ~= nil and type(value) ~= type(default) then
		value = nil
	end
	SETTINGS[key] = if value == nil then default else value
end

local MODEL_ID = 83984800533456

local ANIMATION_IDS = {
	Idle   = 101907348895136,
	Walk   = 100466662502744,
	Attack = 91194170893496,
}

local SOUND_IDS = {
	Scream     = 82613796053949,
}

local RITUAL_URL       = "https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/CrucifixRitual"

local RUSH_SPEED       = 65
local MORPH_WALK_SPEED = 45
local TURN_SPEED       = 10
local CRUCIFIX_RANGE   = 40
local ENCOUNTER_RANGE  = 80
local SHAKE_RANGE      = 60
local REBOUND_DELAY    = 2
local JUMPSCARE_TIME   = 1.3
local JUMPSCARE_GAP    = 3.2
local LUNGE_TIME       = 0.18
local MAX_PAPERS       = 1500
local FAIL_GRACE       = 1.5

local DEATH = { Cause = "Honcho" }

SETTINGS.Speed     = math.max(SETTINGS.Speed, 1)
SETTINGS.Size      = math.max(SETTINGS.Size, 0.2)
SETTINGS.Delay     = math.max(SETTINGS.Delay, 0)
SETTINGS.KillRange = math.max(SETTINGS.KillRange, 0)
SETTINGS.Rebounds  = math.max(math.floor(SETTINGS.Rebounds), 0)
SETTINGS.Papers    = math.clamp(math.floor(SETTINGS.Papers), 0, MAX_PAPERS)

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService      = game:GetService("TweenService")
local ContentProvider   = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer

local function log(format, ...)
	if SETTINGS.Debug then
		print("[Honcho] " .. string.format(format, ...))
	end
end

local function problem(...)
end

local function spawnSafe(label, fn, ...)
	task.spawn(function(...)
		local ok, err = xpcall(fn, debug.traceback, ...)
		if not ok then
			problem("errore in %s: %s", label, tostring(err))
		end
	end, ...)
end

log("impostazioni: Speed %s, Delay %s, Size %s, KillRange %s, Rebounds %s, Jumpscare %s, Papers %s, Sync %s",
	tostring(SETTINGS.Speed), tostring(SETTINGS.Delay), tostring(SETTINGS.Size), tostring(SETTINGS.KillRange),
	tostring(SETTINGS.Rebounds), tostring(SETTINGS.Jumpscare), tostring(SETTINGS.Papers), tostring(SETTINGS.Sync))

if _G.HonchoCleanup then
	pcall(_G.HonchoCleanup)
end

local state = {
	model       = nil,
	position    = Vector3.zero,
	rotation    = CFrame.identity,
	speed       = RUSH_SPEED * SETTINGS.Speed / 100,
	pivotHeight = 0,
	headHeight  = 0,
	boxSize     = Vector3.one,
	running     = false,
	paused      = false,
	watching    = false,
	finished    = false,
}
local body: { [string]: any } = {}
local connections = {}
local cleanupTasks = {}

local function playerAlive()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function flatUnit(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.05 then
		return nil
	end
	return flat.Unit
end

local function randomUnit()
	local vector = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
	if vector.Magnitude < 0.01 then
		return Vector3.yAxis
	end
	return vector.Unit
end

local function newPart(name, size, cframe, colour, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = colour
	part.Material = material
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function tween(instance, duration, goals, style, direction)
	local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local playing = TweenService:Create(instance, info, goals)
	playing:Play()
	return playing
end

local function flashScreen(colour, startTransparency, duration)
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "HonchoFlash"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = colour
	frame.BackgroundTransparency = startTransparency
	frame.Parent = gui

	gui.Parent = playerGui
	tween(frame, duration, { BackgroundTransparency = 1 })
	task.delay(duration + 0.1, function()
		gui:Destroy()
	end)
end

local function shake(magnitude, roughness, fadeIn, fadeOut)
	pcall(function()
		local mainGame = require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game)
		mainGame.camShaker:ShakeOnce(magnitude, roughness, fadeIn, fadeOut)
	end)
end

local function latestRoomValue()
	local gameData = ReplicatedStorage:FindFirstChild("GameData")
	return gameData and gameData:FindFirstChild("LatestRoom")
end

local function killPlayer(humanoid)
	pcall(function()
		ReplicatedStorage.GameStats["Player_" .. LocalPlayer.Name].Total.DeathCause.Value = DEATH.Cause
	end)
	humanoid.Health = 0
	log("ti ha ucciso")
end

local function prepareModel()
	local ok, model = pcall(function()
		return game:GetObjects("rbxassetid://" .. MODEL_ID)[1]
	end)
	if not ok or typeof(model) ~= "Instance" or not model:IsA("Model") then
		return nil
	end

	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		humanoid:Destroy()
	end

	local root = model:FindFirstChild("HumanoidRootPart", true)
		or model:FindFirstChild("RootPart", true)
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	model.PrimaryPart = root
	model.Name = "Honcho"

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = part == root
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end

	model:ScaleTo(SETTINGS.Size)

	local pivot = model:GetPivot().Position
	local boxCFrame, boxSize = model:GetBoundingBox()
	state.pivotHeight = pivot.Y - (boxCFrame.Position.Y - boxSize.Y / 2)
	state.boxSize = boxSize

	local head = model:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		state.headHeight = head.Position.Y - pivot.Y
	else
		state.headHeight = (boxCFrame.Position.Y + boxSize.Y / 2 - pivot.Y) * 0.9
	end

	return model
end

local RitualModule = nil
local ritualLoading = false

local function ritualModule()
	while ritualLoading do
		task.wait(0.1)
	end
	if RitualModule then return RitualModule end

	ritualLoading = true
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(RITUAL_URL))()
	end)
	ritualLoading = false

	if ok and type(result) == "table" then
		RitualModule = result
		if SETTINGS.Debug then
			result.Debug = true
		end
	else
		problem("CrucifixRitual non si è caricato, niente rituale: %s", tostring(result))
	end
	return RitualModule
end

local function preloadRitual()
	local ritual = ritualModule()
	if ritual then
		ritual.Preload()
	end
	pcall(function()
		ContentProvider:PreloadAsync({ "rbxassetid://" .. SOUND_IDS.Scream })
	end)
	log("rituale precaricato")
end

local function loadTrack(animator, name, looped, priority)
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. ANIMATION_IDS[name]
	local track = animator:LoadAnimation(animation)
	track.Looped = looped
	track.Priority = priority
	return track
end

local function setupBody()
	local model = state.model
	local controller = model:FindFirstChildWhichIsA("AnimationController")
		or model:FindFirstChildWhichIsA("AnimationController", true)
	if not controller then
		controller = Instance.new("AnimationController")
		controller.Parent = model
	end

	local animator = controller:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end

	body.idle   = loadTrack(animator, "Idle", true, Enum.AnimationPriority.Idle)
	body.walk   = loadTrack(animator, "Walk", true, Enum.AnimationPriority.Movement)
	body.attack = loadTrack(animator, "Attack", false, Enum.AnimationPriority.Action)

	body.walkRate = math.clamp(state.speed / (MORPH_WALK_SPEED * SETTINGS.Size), 0.5, 3)
	body.stepRate = math.pi * state.speed / (7 * SETTINGS.Size)

	local footsteps = model:FindFirstChild("Footsteps", true)
	if footsteps and footsteps:IsA("Sound") then
		footsteps.Looped = true
		body.footsteps = footsteps
	end

	local scream = Instance.new("Sound")
	scream.Name = "HonchoScream"
	scream.SoundId = "rbxassetid://" .. SOUND_IDS.Scream
	scream.Volume = 2
	scream.RollOffMinDistance = 20
	scream.Parent = model.PrimaryPart
	body.scream = scream

	task.delay(4, function()
		if state.finished then return end
		for name, track in pairs({ Idle = body.idle, Walk = body.walk, Attack = body.attack }) do
			if track.Length == 0 then
				problem("l'animazione %s non si è caricata", name)
			end
		end
		if not scream.IsLoaded then
			problem("il suono di Honcho non si è caricato")
		end
		body.walkBroken = body.walk.Length == 0
	end)
end

local function setMoving(moving)
	if not body.walk or body.moving == moving then return end

	if moving and state.paused then return end
	body.moving = moving

	if moving then
		body.idle:Stop(0.25)
		body.walk:Play(0.25, 1, body.walkRate)
		if body.footsteps then body.footsteps:Play() end
	else
		body.walk:Stop(0.25)
		body.idle:Play(0.25)
		if body.footsteps then body.footsteps:Stop() end
	end
end

local function render(offset)
	local cframe = CFrame.new(state.position) * state.rotation
	if offset then
		cframe *= offset
	end
	state.model:PivotTo(cframe)
end

local function walkBob()
	if not body.walkBroken or not body.moving then
		return nil
	end
	local phase = os.clock() * body.stepRate
	return CFrame.new(0, math.abs(math.sin(phase)) * 0.35 * SETTINGS.Size, 0)
		* CFrame.Angles(0, 0, math.sin(phase) * math.rad(4))
end

local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude
floorParams.RespectCanCollide = true

local function characters()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	return list
end

local function floorAt(point, fallbackY)
	floorParams.FilterDescendantsInstances = characters()
	local hit = workspace:Raycast(point + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), floorParams)
	return if hit then hit.Position.Y else fallbackY
end

local function sortedNodePositions(folder)
	local nodes = {}
	for _, node in ipairs(folder:GetChildren()) do
		if node:IsA("BasePart") and tonumber(node.Name) then
			table.insert(nodes, node)
		end
	end
	table.sort(nodes, function(a, b)
		return (tonumber(a.Name) :: number) < (tonumber(b.Name) :: number)
	end)

	local positions = {}
	for index, node in ipairs(nodes) do
		positions[index] = node.Position
	end
	return positions
end

local nodeCache = _G.HonchoNodeCache or setmetatable({}, { __mode = "k" })
_G.HonchoNodeCache = nodeCache
if not _G.HonchoNodeWatcher then
	_G.HonchoNodeWatcher = CurrentRooms.DescendantRemoving:Connect(function(instance)
		local room = instance.Parent
		if instance.Name == "PathfindNodes" and room and room.Parent == CurrentRooms then
			nodeCache[room] = sortedNodePositions(instance)
		end
	end)
end

local function buildPath()
	local rooms = {}
	for _, room in ipairs(CurrentRooms:GetChildren()) do
		if tonumber(room.Name) then
			table.insert(rooms, room)
		end
	end
	table.sort(rooms, function(a, b)
		return (tonumber(a.Name) :: number) < (tonumber(b.Name) :: number)
	end)

	local path = {}
	local function add(room, position, fallbackY)
		local floorY = floorAt(position, fallbackY)
		table.insert(path, { room = room, position = Vector3.new(position.X, floorY, position.Z) })
	end

	for _, room in ipairs(rooms) do

		local entrance = room:FindFirstChild("RoomEntrance")
		if entrance and entrance:IsA("BasePart") then
			add(room, entrance.Position, entrance.Position.Y - 3)
		end

		local folder = room:FindFirstChild("PathfindNodes")
		local nodes = (folder and sortedNodePositions(folder)) or nodeCache[room] or {}
		for _, position in ipairs(nodes) do
			add(room, position, position.Y)
		end

		local exit = room:FindFirstChild("RoomExit")
		if exit and exit:IsA("BasePart") then
			add(room, exit.Position, exit.Position.Y - 3)
		end
	end
	return path
end

local function reversed(list)
	local copy = {}
	for index = #list, 1, -1 do
		table.insert(copy, list[index])
	end
	return copy
end

local PAPER_COLOURS = {
	Color3.fromRGB(246, 243, 235),
	Color3.fromRGB(236, 229, 212),
	Color3.fromRGB(226, 226, 226),
	Color3.fromRGB(242, 232, 204),
}
local PAPER_GRAVITY = 14
local PAPER_DRAG    = 2.2

local papers = { list = {}, folder = nil, connection = nil }

local movingParts, movingCFrames = {}, {}

local function updatePapers(deltaTime)
	table.clear(movingParts)
	table.clear(movingCFrames)
	local list = papers.list

	for index = #list, 1, -1 do
		local paper = list[index]
		paper.age += deltaTime

		if paper.age >= paper.life then
			paper.part:Destroy()
			list[index] = list[#list]
			list[#list] = nil
		else
			if not paper.landed then
				paper.velocity += Vector3.new(0, -PAPER_GRAVITY * deltaTime, 0)
				paper.velocity *= math.max(0, 1 - PAPER_DRAG * deltaTime)
				local sway = paper.swayDirection * (math.sin(paper.age * paper.swaySpeed + paper.swayPhase) * 2.5)
				paper.position += (paper.velocity + sway) * deltaTime
				paper.angle += paper.spin * deltaTime

				if paper.position.Y <= paper.floorY then

					paper.landed = true
					paper.position = Vector3.new(paper.position.X, paper.floorY, paper.position.Z)
					paper.part.CFrame = CFrame.new(paper.position) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
				else
					table.insert(movingParts, paper.part)
					table.insert(movingCFrames, CFrame.new(paper.position) * CFrame.fromAxisAngle(paper.axis, paper.angle))
				end
			end

			local remaining = paper.life - paper.age
			if remaining < 1 then
				paper.part.Transparency = 1 - remaining
			end
		end
	end

	if #movingParts > 0 then
		workspace:BulkMoveTo(movingParts, movingCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end

	if #list == 0 and papers.connection then
		papers.connection:Disconnect()
		papers.connection = nil
		papers.folder:Destroy()
		papers.folder = nil
	end
end

local function spawnPaper(position, floorY, velocity, life)
	if not papers.folder then
		papers.folder = Instance.new("Folder")
		papers.folder.Name = "HonchoPapers"
		papers.folder.Parent = workspace
	end

	local length = 0.7 + math.random() * 0.5
	local colour = PAPER_COLOURS[math.random(#PAPER_COLOURS)]
	local part = newPart("Paper", Vector3.new(length * 0.78, 0.02, length), CFrame.new(position), colour, Enum.Material.SmoothPlastic, 0)
	part.Parent = papers.folder

	table.insert(papers.list, {
		part          = part,
		position      = position,
		velocity      = velocity,
		axis          = randomUnit(),
		angle         = math.random() * math.pi * 2,
		spin          = (math.random() * 2 - 1) * 7,
		swayDirection = flatUnit(randomUnit()) or Vector3.xAxis,
		swaySpeed     = 3 + math.random() * 3,
		swayPhase     = math.random() * math.pi * 2,
		age           = 0,
		life          = life or (5 + math.random() * 3),
		floorY        = floorY + 0.03,
		landed        = false,
	})

	if not papers.connection then
		papers.connection = RunService.Heartbeat:Connect(updatePapers)
	end
end

local function burstFromBody(count, floorY)
	local model = state.model
	if count <= 0 or not model or not model.Parent then return end

	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottom = math.max(boxCFrame.Position.Y - boxSize.Y / 2, floorY + 0.3)
	local top = math.max(boxCFrame.Position.Y + boxSize.Y / 2, bottom + 0.5)
	for _ = 1, count do
		local offset = Vector3.new((math.random() - 0.5) * boxSize.X, 0, (math.random() - 0.5) * boxSize.Z) * 0.8
		local point = boxCFrame:PointToWorldSpace(offset)
		point = Vector3.new(point.X, bottom + math.random() * (top - bottom), point.Z)
		local direction = (randomUnit() + Vector3.new(0, 0.9, 0)).Unit
		spawnPaper(point, floorY, direction * (8 + math.random() * 16))
	end
end

local function geyser(count, center, radius, floorY)
	for _ = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * radius * 0.5
		local origin = center + Vector3.new(math.cos(angle) * distance, 0.5, math.sin(angle) * distance)
		local direction = (Vector3.new(math.cos(angle) * 0.5, 1, math.sin(angle) * 0.5) + randomUnit() * 0.35).Unit
		spawnPaper(origin, floorY, direction * (16 + math.random() * 22))
	end
end

local dismiss

local function finish(reason)
	if state.finished then return end
	state.finished = true
	state.running = false
	state.watching = false
	log("fine: %s", reason)

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)

	for _, cleanup in ipairs(cleanupTasks) do
		pcall(cleanup)
	end
	table.clear(cleanupTasks)

	if state.model then
		state.model:Destroy()
	end
	if _G.HonchoCleanup == dismiss then
		_G.HonchoCleanup = nil
	end
end

dismiss = function()
	finish("tolto da una nuova esecuzione")
end

local function jumpscare(humanoid)
	log("ti ha preso")

	if not SETTINGS.Jumpscare then
		killPlayer(humanoid)
		finish("ti ha preso")
		return
	end

	local model = state.model

	local headOffset = Vector3.new(0, state.headHeight, 0)
	local head = model:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		headOffset = model:GetPivot():PointToObjectSpace(head.Position)
	end

	pcall(function()
		body.walk:Stop(0.05)
		if body.footsteps then body.footsteps:Stop() end

		if not body.idle.IsPlaying then body.idle:Play(0.05) end
		body.attack:Play(0.05)
		body.scream:Play()
	end)
	shake(10, 12, 0.05, 1.5)

	local startedAt = os.clock()
	local far = JUMPSCARE_GAP * 2.5
	local flashed = false
	local stepName = "HonchoJumpscare" .. tostring(startedAt)

	RunService:BindToRenderStep(stepName, Enum.RenderPriority.Camera.Value + 1, function()
		local view = workspace.CurrentCamera.CFrame
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local forward = flatUnit(view.LookVector)
			or (root and flatUnit(root.CFrame.LookVector))
			or Vector3.new(0, 0, -1)

		local progress = math.clamp((os.clock() - startedAt) / LUNGE_TIME, 0, 1)
		local gap = far + (JUMPSCARE_GAP - far) * (1 - (1 - progress) ^ 3)
		local rotation = CFrame.lookAt(Vector3.zero, -forward)
		local facePosition = view.Position + forward * gap
		model:PivotTo(CFrame.new(facePosition - rotation:VectorToWorldSpace(headOffset)) * rotation)

		if progress >= 1 and not flashed then
			flashed = true
			flashScreen(Color3.fromRGB(150, 0, 0), 0.35, 0.5)
		end
	end)
	table.insert(cleanupTasks, function()
		RunService:UnbindFromRenderStep(stepName)
	end)

	task.wait(JUMPSCARE_TIME)
	if humanoid.Parent and humanoid.Health > 0 then
		killPlayer(humanoid)
	end

	task.wait(1)
	finish("jumpscare")
end

local LIMB_SEGMENTS = { "Shoulder", "UpperArm", "UpperWrist", "LowerWrist", "Hand", "UpperLeg", "MiddleLeg", "LowerLeg", "Ankle", "Foot" }
local TIE_SEGMENTS  = { "TieTop", "TieUpper", "TieMiddle", "TieLower", "TieBottom" }

local POSE_SPECS = {

	Whiplash = {
		Pelvis      = { -8, 0, 0, 0, 0, 0.5 },
		LowerTorso  = { 10, 0, 0 },
		MiddleTorso = { 14, 0, -4 },
		UpperTorso  = { 18, -6, -6 },
		Neck        = { 16, 0, 0 },
		Head        = { 38, 10, -12 },
		R = {
			Shoulder   = { 0, -30, 10 },
			UpperArm   = { 0, -10, 5 },
			UpperWrist = { 0, 45, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 20 },
			UpperLeg   = { -25, 0, 6 },
			MiddleLeg  = { -20, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -20, 0, 0 },
		},
		L = {
			Shoulder   = { 0, -50, -55 },
			UpperArm   = { 0, -10, -10 },
			UpperWrist = { 0, 15, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 0, 0, -10 },
			UpperLeg   = { 10, 0, 8 },
			MiddleLeg  = { -8, 0, 0 },
			LowerLeg   = { -8, 0, 0 },
			Ankle      = { 10, 0, 0 },
		},
	},

	Cower = {
		Pelvis      = { 0, -10, 0, 0, -0.9, 0.35 },
		LowerTorso  = { -6, -6, 0 },
		MiddleTorso = { -10, -8, 4 },
		UpperTorso  = { -14, -14, 6 },
		Neck        = { -10, -10, 4 },
		Head        = { -24, -30, 12 },
		R = {
			Shoulder   = { 0, 50, 60 },
			UpperArm   = { 0, 45, 30 },
			UpperWrist = { 0, 30, 0 },
			LowerWrist = { 0, 15, 0 },
			Hand       = { 0, 10, -25 },
			UpperLeg   = { 45, 0, 10 },
			MiddleLeg  = { -35, 0, 0 },
			LowerLeg   = { -40, 0, 0 },
			Ankle      = { 30, 0, 0 },
		},
		L = {
			Shoulder   = { 0, -35, -45 },
			UpperArm   = { 0, -10, -15 },
			UpperWrist = { 0, 35, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 20 },
			UpperLeg   = { 20, 0, 12 },
			MiddleLeg  = { -25, 0, 0 },
			LowerLeg   = { -30, 0, 0 },
			Ankle      = { 35, 0, 0 },
		},
	},

	Cower2 = {
		Pelvis      = { 0, -16, 0, 0, -0.8, 0.45 },
		LowerTorso  = { -4, -10, 2 },
		MiddleTorso = { -8, -14, 8 },
		UpperTorso  = { -8, -24, 12 },
		Neck        = { -6, -14, 8 },
		Head        = { -10, -42, 20 },
		R = {
			Shoulder   = { 0, 48, 64 },
			UpperArm   = { 0, 45, 30 },
			UpperWrist = { 0, 38, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 0, 15, -30 },
			UpperLeg   = { 40, 0, 12 },
			MiddleLeg  = { -30, 0, 0 },
			LowerLeg   = { -36, 0, 0 },
			Ankle      = { 26, 0, 0 },
		},
		L = {
			Shoulder   = { 0, -55, -35 },
			UpperArm   = { 0, -15, -10 },
			UpperWrist = { 0, 25, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 30 },
			UpperLeg   = { 24, 0, 14 },
			MiddleLeg  = { -28, 0, 0 },
			LowerLeg   = { -32, 0, 0 },
			Ankle      = { 36, 0, 0 },
		},
	},

	Limp = {
		LowerTorso  = { -6, 0, 0 },
		MiddleTorso = { -8, 0, 2 },
		UpperTorso  = { -10, 4, 4 },
		Neck        = { -15, 0, 0 },
		Head        = { -40, 6, 12 },
		R = {
			Shoulder   = { 10, 0, -82 },
			UpperArm   = { 0, 0, -4 },
			UpperWrist = { 0, 15, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 0, 0, -10 },
			UpperLeg   = { 8, 0, 3 },
			MiddleLeg  = { -10, 0, 0 },
			LowerLeg   = { -15, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
		L = {
			Shoulder   = { 16, 0, -80 },
			UpperArm   = { 0, 0, -4 },
			UpperWrist = { 0, 20, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 0, 0, -10 },
			UpperLeg   = { 3, 0, 2 },
			MiddleLeg  = { -6, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	Jerk = {
		Pelvis      = { 0, 6, -4 },
		LowerTorso  = { 4, 4, -4 },
		MiddleTorso = { 8, 6, -6 },
		UpperTorso  = { 12, 10, -8 },
		Neck        = { 12, -8, 6 },
		Head        = { 35, -14, 12 },
		R = {
			Shoulder   = { 0, 30, 40 },
			UpperArm   = { 0, 10, 10 },
			UpperWrist = { 0, 40, 0 },
			LowerWrist = { 0, 15, 0 },
			Hand       = { 0, 0, 20 },
			UpperLeg   = { 50, 0, 10 },
			MiddleLeg  = { -45, 0, 0 },
			LowerLeg   = { -50, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
		L = {
			Shoulder   = { 0, -20, -30 },
			UpperArm   = { 0, -5, -10 },
			UpperWrist = { 0, 30, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 25 },
			UpperLeg   = { -10, 0, 6 },
			MiddleLeg  = { -12, 0, 0 },
			LowerLeg   = { -14, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
	},

	Seized = {
		LowerTorso  = { -10, 0, 0 },
		MiddleTorso = { 14, 0, 0 },
		UpperTorso  = { 20, 0, 0 },
		Neck        = { 18, 0, 0 },
		Head        = { 45, 0, 0 },
		R = {
			Shoulder   = { -50, 0, -78 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 45, 0, -15 },
			UpperLeg   = { -12, 0, 6 },
			MiddleLeg  = { -18, 0, 0 },
			LowerLeg   = { -20, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	Scream = {
		LowerTorso  = { -10, 4, -4 },
		MiddleTorso = { 16, 6, -6 },
		UpperTorso  = { 22, 8, -10 },
		Neck        = { 20, 8, -10 },
		Head        = { 50, 15, -20 },
		R = {
			Shoulder   = { -55, 0, -70 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 15, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 50, 0, -20 },
			UpperLeg   = { 35, 0, 8 },
			MiddleLeg  = { -40, 0, 0 },
			LowerLeg   = { -45, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
		L = {
			Shoulder   = { -45, 0, -82 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 40, 0, -10 },
			UpperLeg   = { -14, 0, 5 },
			MiddleLeg  = { -16, 0, 0 },
			LowerLeg   = { -18, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	StruggleA = {
		Pelvis      = { 0, 14, -10 },
		LowerTorso  = { -6, 10, -10 },
		MiddleTorso = { 8, 16, -16 },
		UpperTorso  = { 14, 20, -22 },
		Neck        = { 10, -20, 18 },
		Head        = { 18, -42, 34 },
		R = {
			Shoulder   = { -20, 0, -45 },
			UpperArm   = { -10, 0, -5 },
			UpperWrist = { 0, 55, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 60, 0, -30 },
			UpperLeg   = { 70, 0, 12 },
			MiddleLeg  = { -55, 0, 0 },
			LowerLeg   = { -60, 0, 0 },
			Ankle      = { -20, 0, 0 },
		},
		L = {
			Shoulder   = { -50, 0, -84 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 8, 0 },
			LowerWrist = { 0, 4, 0 },
			Hand       = { 30, 0, 0 },
			UpperLeg   = { -15, 0, 5 },
			MiddleLeg  = { -6, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
	},

	StruggleC = {
		Pelvis      = { -6, -6, 6 },
		LowerTorso  = { -8, -4, 6 },
		MiddleTorso = { -12, -6, 10 },
		UpperTorso  = { -18, -10, 14 },
		Neck        = { -12, 14, 10 },
		Head        = { -30, 25, 20 },
		R = {
			Shoulder   = { -10, 0, -55 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 40, 0 },
			LowerWrist = { 0, 15, 0 },
			Hand       = { 40, 0, -20 },
			UpperLeg   = { 55, 0, 10 },
			MiddleLeg  = { -50, 0, 0 },
			LowerLeg   = { -55, 0, 0 },
			Ankle      = { -25, 0, 0 },
		},
		L = {
			Shoulder   = { -15, 0, -60 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 35, 0 },
			LowerWrist = { 0, 15, 0 },
			Hand       = { 40, 0, -20 },
			UpperLeg   = { 40, 0, 8 },
			MiddleLeg  = { -45, 0, 0 },
			LowerLeg   = { -50, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
	},

	Spasm = {
		Pelvis      = { 6, -6, 4 },
		LowerTorso  = { -8, -4, 4 },
		MiddleTorso = { 18, -6, 6 },
		UpperTorso  = { 26, -8, 8 },
		Neck        = { 22, 10, -8 },
		Head        = { 55, -10, 10 },
		R = {
			Shoulder   = { -58, 0, -76 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 50, 0, -20 },
			UpperLeg   = { -30, 0, 6 },
			MiddleLeg  = { -30, 0, 0 },
			LowerLeg   = { -20, 0, 0 },
			Ankle      = { -40, 0, 0 },
		},
		L = {
			Shoulder   = { -52, 0, -80 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 50, 0, -20 },
			UpperLeg   = { -24, 0, 6 },
			MiddleLeg  = { -34, 0, 0 },
			LowerLeg   = { -24, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
	},

	Strain = {
		Pelvis      = { 4, 8, 0 },
		LowerTorso  = { 4, 4, -2 },
		MiddleTorso = { 8, 6, -4 },
		UpperTorso  = { 12, 8, -6, 0, 0.15, 0 },
		Neck        = { 12, -6, 6 },
		Head        = { 40, -12, 15 },
		R = {
			Shoulder   = { -12, 0, -40 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 60, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 50, 0, -30 },
			UpperLeg   = { -10, 0, 4 },
			MiddleLeg  = { -35, 0, 0 },
			LowerLeg   = { -30, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
		L = {
			Shoulder   = { -18, 0, -44 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 55, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 50, 0, -30 },
			UpperLeg   = { -6, 0, 4 },
			MiddleLeg  = { -30, 0, 0 },
			LowerLeg   = { -34, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	Yank = {
		Pelvis      = { -10, 0, 0, 0, 0.3, 0 },
		LowerTorso  = { -14, 0, 0 },
		MiddleTorso = { -18, 0, 0 },
		UpperTorso  = { -22, 0, 0 },
		Neck        = { -15, 0, 0 },
		Head        = { -40, 0, 0 },
		R = {
			Shoulder   = { -20, 0, -88 },
			UpperArm   = { -6, 0, -4 },
			UpperWrist = { 0, 6, 0 },
			LowerWrist = { 0, 4, 0 },
			Hand       = { 30, 0, 0 },
			UpperLeg   = { 45, 0, 4 },
			MiddleLeg  = { -40, 0, 0 },
			LowerLeg   = { -45, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
	},

	Fight = {
		Pelvis      = { 0, -8, 6 },
		LowerTorso  = { 2, -8, 6 },
		MiddleTorso = { 10, -10, 8 },
		UpperTorso  = { 16, -14, 12 },
		Neck        = { 14, 12, -10 },
		Head        = { 35, 20, -18 },
		R = {
			Shoulder   = { -15, 0, -48 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 50, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 55, 0, -25 },
			UpperLeg   = { 30, 0, 6 },
			MiddleLeg  = { -32, 0, 0 },
			LowerLeg   = { -36, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
		L = {
			Shoulder   = { -40, 0, -80 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 12, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 40, 0, -10 },
			UpperLeg   = { -8, 0, 4 },
			MiddleLeg  = { -8, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	Wrench = {
		Pelvis      = { 0, -10, 6 },
		LowerTorso  = { 2, -10, 8 },
		MiddleTorso = { 6, -14, 10 },
		UpperTorso  = { 10, -20, 15 },
		Neck        = { 10, -14, 6 },
		Head        = { 30, -30, 10 },
		R = {
			Shoulder   = { 0, 25, 60 },
			UpperArm   = { 0, 10, 10 },
			UpperWrist = { 0, 30, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 20 },
			UpperLeg   = { 20, 0, 4 },
			MiddleLeg  = { -20, 0, 0 },
			LowerLeg   = { -24, 0, 0 },
			Ankle      = { -40, 0, 0 },
		},
		L = {
			Shoulder   = { -45, 0, -82 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 40, 0, -10 },
			UpperLeg   = { -6, 0, 4 },
			MiddleLeg  = { -8, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	Grab = {
		Pelvis      = { 0, -10, -4 },
		LowerTorso  = { -2, -8, -4 },
		MiddleTorso = { -3, -12, -6 },
		UpperTorso  = { -5, -20, -6 },
		Neck        = { 4, -8, -6 },
		Head        = { 20, -15, -10 },
		R = {
			Shoulder   = { 0, 58, 62 },
			UpperArm   = { 0, 8, 4 },
			UpperWrist = { 0, 45, -15 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, -45 },
			UpperLeg   = { 10, 0, 2 },
			MiddleLeg  = { -10, 0, 0 },
			LowerLeg   = { -12, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
		L = {
			Shoulder   = { -45, 0, -80 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 40, 0, -10 },
			UpperLeg   = { -6, 0, 4 },
			MiddleLeg  = { -8, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	Pull = {
		Pelvis      = { 0, -10, -4 },
		LowerTorso  = { -3, -8, -4 },
		MiddleTorso = { -4.5, -12, -6 },
		UpperTorso  = { -7.5, -20, -6 },
		Neck        = { 10, -10, -8 },
		Head        = { 32, -18, -12 },
		R = {
			Shoulder   = { 0, 50, 68 },
			UpperArm   = { 0, 8, 4 },
			UpperWrist = { 0, 60, -10 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, -45 },
			UpperLeg   = { 20, 0, 4 },
			MiddleLeg  = { -18, 0, 0 },
			LowerLeg   = { -20, 0, 0 },
			Ankle      = { -40, 0, 0 },
		},
		L = {
			Shoulder   = { -40, 0, -76 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 20, 0 },
			LowerWrist = { 0, 8, 0 },
			Hand       = { 50, 0, -15 },
			UpperLeg   = { -4, 0, 4 },
			MiddleLeg  = { -6, 0, 0 },
			LowerLeg   = { -8, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	Taken = {
		Pelvis      = { 0, 0, 4 },
		LowerTorso  = { 4, 0, 4 },
		MiddleTorso = { 8, -4, 8 },
		UpperTorso  = { 12, -6, 12 },
		Neck        = { 16, 6, -6 },
		Head        = { 45, 10, -12 },
		R = {
			Shoulder   = { 0, 10, 80 },
			UpperArm   = { 0, 5, 5 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 0, 0, 10 },
			UpperLeg   = { -6, 0, 2 },
			MiddleLeg  = { -4, 0, 0 },
			LowerLeg   = { -6, 0, 0 },
			Ankle      = { -55, 0, 0 },
		},
		L = {
			Shoulder   = { -40, 0, -84 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 8, 0 },
			LowerWrist = { 0, 4, 0 },
			Hand       = { 35, 0, -5 },
			UpperLeg   = { -6, 0, 2 },
			MiddleLeg  = { -4, 0, 0 },
			LowerLeg   = { -6, 0, 0 },
			Ankle      = { -55, 0, 0 },
		},
	},
}

POSE_SPECS.Resist = {
	Pelvis      = { 6, 0, 0, 0, 0.1, 0 },
	LowerTorso  = { 6, 0, 0 },
	MiddleTorso = { 4, 0, 0 },
	UpperTorso  = { 2, 0, 0, 0, 0.1, 0 },
	Neck        = { -8, 0, 0 },
	Head        = { -18, 0, 0 },
	R = {
		Shoulder   = { -30, 0, -58 },
		UpperArm   = { -8, 0, -5 },
		UpperWrist = { 0, 75, 0 },
		LowerWrist = { 0, 25, 0 },
		Hand       = { 60, 0, -35 },
		UpperLeg   = { 12, 0, 12 },
		MiddleLeg  = { -22, 0, 0 },
		LowerLeg   = { -18, 0, 0 },
		Ankle      = { -30, 0, 0 },
	},
}

POSE_SPECS.Tear = {
	Pelvis      = { 0, 12, -6 },
	LowerTorso  = { 4, 10, -6 },
	MiddleTorso = { 10, 14, -10 },
	UpperTorso  = { 16, 18, -14, 0, 0.1, 0 },
	Neck        = { 10, 12, -8 },
	Head        = { 30, 20, -14 },
	R = {
		Shoulder   = { 10, 20, 72 },
		UpperArm   = { 0, 10, 10 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 0, 0, 30 },
		UpperLeg   = { 30, 0, 10 },
		MiddleLeg  = { -30, 0, 0 },
		LowerLeg   = { -34, 0, 0 },
		Ankle      = { -30, 0, 0 },
	},
	L = {
		Shoulder   = { -40, 0, -70 },
		UpperArm   = { -10, 0, -6 },
		UpperWrist = { 0, 60, 0 },
		LowerWrist = { 0, 20, 0 },
		Hand       = { 55, 0, -30 },
		UpperLeg   = { -10, 0, 8 },
		MiddleLeg  = { -14, 0, 0 },
		LowerLeg   = { -16, 0, 0 },
		Ankle      = { -45, 0, 0 },
	},
}

POSE_SPECS.Roar = {
	Pelvis      = { -4, 0, 0, 0, 0.2, 0 },
	LowerTorso  = { 8, 0, 0 },
	MiddleTorso = { 16, 0, 0 },
	UpperTorso  = { 24, 0, 0, 0, 0.15, 0 },
	Neck        = { 18, 0, 0 },
	Head        = { 42, 0, 0 },
	R = {
		Shoulder   = { 5, -15, 45 },
		UpperArm   = { 0, -10, 10 },
		UpperWrist = { 0, 25, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 0, 0, 35 },
		UpperLeg   = { -8, 0, 22 },
		MiddleLeg  = { -12, 0, 0 },
		LowerLeg   = { -10, 0, 0 },
		Ankle      = { -30, 0, 0 },
	},
}

POSE_SPECS.Drop = {
	Pelvis      = { -6, 0, 0 },
	LowerTorso  = { -6, 0, 0 },
	MiddleTorso = { -4, 0, 0 },
	UpperTorso  = { 0, 0, 0 },
	Neck        = { 4, 0, 0 },
	Head        = { 10, 0, 0 },
	R = {
		Shoulder   = { 0, -10, 20 },
		UpperArm   = { 0, -5, 5 },
		UpperWrist = { 0, 30, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 0, 0, 20 },
		UpperLeg   = { 55, 0, 10 },
		MiddleLeg  = { -55, 0, 0 },
		LowerLeg   = { -40, 0, 0 },
		Ankle      = { -10, 0, 0 },
	},
}

POSE_SPECS.Land = {
	Pelvis      = { -10, 0, 0, 0, -0.9, 0.2 },
	LowerTorso  = { -14, 0, 0 },
	MiddleTorso = { -14, 0, 0 },
	UpperTorso  = { -12, 0, 0 },
	Neck        = { 14, 0, 0 },
	Head        = { 26, 0, 0 },
	R = {
		Shoulder   = { -25, 0, -50 },
		UpperArm   = { -10, 0, -6 },
		UpperWrist = { 0, 35, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 40, 0, -20 },
		UpperLeg   = { 60, 0, 14 },
		MiddleLeg  = { -65, 0, 0 },
		LowerLeg   = { -35, 0, 0 },
		Ankle      = { 20, 0, 0 },
	},
	L = {
		Shoulder   = { 10, 0, -70 },
		UpperArm   = { -6, 0, -4 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 8, 0 },
		Hand       = { 20, 0, -10 },
		UpperLeg   = { 45, 0, 14 },
		MiddleLeg  = { -55, 0, 0 },
		LowerLeg   = { -30, 0, 0 },
		Ankle      = { 15, 0, 0 },
	},
}

POSE_SPECS.Loom = {
	Pelvis      = { 0, 0, 0 },
	LowerTorso  = { -2, 0, 0 },
	MiddleTorso = { -4, 0, 0 },
	UpperTorso  = { -6, 0, 0, 0, 0.1, 0 },
	Neck        = { -4, 0, 0 },
	Head        = { -8, 0, 0 },
	R = {
		Shoulder   = { 0, 0, -68 },
		UpperArm   = { 0, 0, -4 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 8, 0 },
		Hand       = { 10, 0, -10 },
		UpperLeg   = { 2, 0, 8 },
		MiddleLeg  = { -4, 0, 0 },
		LowerLeg   = { -4, 0, 0 },
		Ankle      = { -2, 0, 0 },
	},
}

local function mirrorSpec(spec)
	local mirrored = { R = spec.L or spec.R, L = spec.R }
	for key, value in pairs(spec) do
		if key ~= "R" and key ~= "L" then
			mirrored[key] = { value[1], -value[2], -value[3], -(value[4] or 0), value[5], value[6] }
		end
	end
	return mirrored
end
POSE_SPECS.StruggleB = mirrorSpec(POSE_SPECS.StruggleA)
POSE_SPECS.FightB = mirrorSpec(POSE_SPECS.Fight)
POSE_SPECS.TearB = mirrorSpec(POSE_SPECS.Tear)

local function compilePose(spec)
	local pose = {}
	local function put(name, value, mirror)
		local y, z, x = value[2], value[3], value[4] or 0
		if mirror then
			y, z, x = -y, -z, -x
		end
		pose[name] = CFrame.new(Vector3.new(x, value[5] or 0, value[6] or 0) * SETTINGS.Size)
			* CFrame.Angles(math.rad(value[1]), math.rad(y), math.rad(z))
	end
	for key, value in pairs(spec) do
		if key ~= "R" and key ~= "L" then
			put(key, value, false)
		end
	end
	local left = spec.L or spec.R
	for _, segment in ipairs(LIMB_SEGMENTS) do
		if spec.R and spec.R[segment] then put("Right" .. segment, spec.R[segment], false) end
		if left and left[segment] then put("Left" .. segment, left[segment], true) end
	end
	return pose
end

local BANISH_KEYS = {
	{ 0.00, "Start" },
	{ 0.06, "Whiplash", "Out" },
	{ 0.22, "Cower", "Out" },
	{ 0.40, "Cower2", "InOut" },
	{ 0.55, "Cower", "InOut" },
	{ 0.80, "Limp", "InOut" },
	{ 0.97, "Jerk", "Out" },
	{ 1.10, "Seized", "Out" },
	{ 1.28, "Scream", "InOut" },
	{ 1.45, "StruggleA", "InOut" },
	{ 1.60, "StruggleB", "InOut" },
	{ 1.76, "StruggleC", "InOut" },
	{ 1.90, "Spasm", "Out" },
	{ 2.06, "StruggleA", "InOut" },
	{ 2.22, "StruggleB", "InOut" },
	{ 2.40, "Strain", "InOut" },
	{ 2.50, "Strain" },
	{ 2.56, "Yank", "Out" },
	{ 2.80, "Fight", "InOut" },
	{ 2.98, "StruggleC", "InOut" },
	{ 3.14, "FightB", "InOut" },
	{ 3.30, "FightB" },
	{ 3.36, "Yank", "Out" },
	{ 3.58, "FightB", "InOut" },
	{ 3.74, "StruggleA", "InOut" },
	{ 3.90, "Fight", "InOut" },
	{ 4.05, "Fight" },
	{ 4.11, "Yank", "Out" },
	{ 4.32, "Fight", "InOut" },
	{ 4.50, "StruggleB", "InOut" },
	{ 4.66, "Strain", "InOut" },
	{ 4.75, "Strain" },
	{ 4.81, "Wrench", "Out" },
	{ 4.95, "Grab", "Out" },
	{ 5.20, "Pull", "InOut" },
	{ 5.35, "Pull" },
	{ 5.55, "Taken", "Out" },
	{ 5.80, "Taken" },
}

local FAIL_KEYS = {
	{ 0.00, "Start" },
	{ 0.06, "Whiplash", "Out" },
	{ 0.22, "Cower", "Out" },
	{ 0.40, "Cower2", "InOut" },
	{ 0.55, "Cower", "InOut" },
	{ 0.80, "Limp", "InOut" },
	{ 0.97, "Jerk", "Out" },
	{ 1.10, "Seized", "Out" },
	{ 1.28, "Scream", "InOut" },
	{ 1.45, "StruggleA", "InOut" },
	{ 1.60, "StruggleB", "InOut" },
	{ 1.76, "StruggleC", "InOut" },
	{ 1.90, "Spasm", "Out" },
	{ 2.06, "StruggleA", "InOut" },
	{ 2.22, "StruggleB", "InOut" },
	{ 2.40, "Strain", "InOut" },
	{ 2.50, "Strain" },
	{ 2.56, "Yank", "Out" },
	{ 2.80, "Fight", "InOut" },
	{ 3.14, "FightB", "InOut" },
	{ 3.30, "FightB" },
	{ 3.36, "Yank", "Out" },
	{ 3.62, "Resist", "Out" },
	{ 3.88, "Resist", "InOut" },
	{ 3.95, "Tear", "Out" },
	{ 4.12, "Resist", "InOut" },
	{ 4.22, "TearB", "Out" },
	{ 4.40, "Strain", "InOut" },
	{ 4.48, "Tear", "Out" },
	{ 4.72, "Strain", "InOut" },
	{ 4.90, "Roar", "Out" },
	{ 5.25, "Roar", "InOut" },
	{ 5.45, "Drop", "InOut" },
	{ 5.62, "Land", "Out" },
	{ 6.10, "Land", "InOut" },
	{ 6.70, "Loom", "InOut" },
	{ 7.20, "Loom" },
}

local JOINT_LAG = {
	Pelvis = 0, LowerTorso = 0.01, MiddleTorso = 0.02, UpperTorso = 0.03, Neck = 0.05, Head = 0.07,
	Shoulder = 0.03, UpperArm = 0.04, UpperWrist = 0.06, LowerWrist = 0.08, Hand = 0.1,
	UpperLeg = 0.02, MiddleLeg = 0.04, LowerLeg = 0.06, Ankle = 0.08, Foot = 0.09,
	TieTop = 0.05, TieUpper = 0.07, TieMiddle = 0.09, TieLower = 0.11, TieBottom = 0.13,
}

local function jointLag(name)
	local segment = string.gsub(string.gsub(name, "^Right", ""), "^Left", "")
	return JOINT_LAG[name] or JOINT_LAG[segment] or 0.04
end

local function trembleAt(elapsed, fail)
	if fail and elapsed >= 3.36 then
		if elapsed < 4.9 then return 1.7 end
		if elapsed < 5.62 then return 2.1 end
		if elapsed < 6.3 then return 0.6 end
		return 0.15
	end
	if elapsed < 0.55 then return 0.7 end
	if elapsed < 0.97 then return 0.35 end
	if elapsed < 2.5 then return 1.1 end
	if elapsed < 4.75 then return 1.4 end
	return 1.9
end

local TREMBLE_DEGREES = {
	Head = 7, Neck = 4, UpperTorso = 3, MiddleTorso = 2, LowerTorso = 1.5, Pelvis = 1,
	RightShoulder = 3, LeftShoulder = 3, RightUpperArm = 2, LeftUpperArm = 2,
}

local GRIPPING_ARM = { RightShoulder = true, RightUpperArm = true, RightUpperWrist = true, RightLowerWrist = true, RightHand = true }

local EASING = {
	Out   = function(x) return 1 - (1 - x) ^ 3 end,
	InOut = function(x) return (1 - math.cos(x * math.pi)) / 2 end,
}

local function keyAt(keys, time)
	if time <= keys[1][1] then
		return keys[1], keys[1], 1
	end
	for index = 2, #keys do
		local key = keys[index]
		if time < key[1] then
			local previous = keys[index - 1]
			local alpha = math.clamp((time - previous[1]) / (key[1] - previous[1]), 0, 1)
			return previous, key, EASING[key[3] or "InOut"](alpha)
		end
	end
	local last = keys[#keys]
	return last, last, 1
end

local cachedFrom, cachedTo, cachedAlpha = {}, {}, {}

local function sampleBanish(poses, jointNames, lags, elapsed, into, fail)
	local keys = if fail then FAIL_KEYS else BANISH_KEYS
	local intensity = trembleAt(elapsed, fail)
	table.clear(cachedFrom)
	for index, name in ipairs(jointNames) do
		local lag = lags[name] or 0
		if not cachedFrom[lag] then
			cachedFrom[lag], cachedTo[lag], cachedAlpha[lag] = keyAt(keys, elapsed - lag)
		end
		local from, to, alpha = cachedFrom[lag], cachedTo[lag], cachedAlpha[lag]
		local cframe = (poses[from[2]][name] or CFrame.identity):Lerp(poses[to[2]][name] or CFrame.identity, alpha)
		local amount = math.rad((TREMBLE_DEGREES[name] or 2.5) * intensity)
		if not fail and GRIPPING_ARM[name] and elapsed > 4.9 and elapsed < 5.4 then
			amount *= 0.25
		end
		cframe *= CFrame.Angles(
			math.noise(index * 1.37, elapsed * 12) * 2 * amount,
			math.noise(index * 2.11, elapsed * 12 + 40) * 2 * amount,
			math.noise(index * 3.73, elapsed * 12 + 80) * 2 * amount
		)
		into[name] = cframe
	end

	local lift = if fail
		then math.clamp((elapsed - 2.5) / 1, 0, 1) * 20 * (1 - math.clamp((elapsed - 5.3) / 0.6, 0, 1))
		else math.clamp((elapsed - 2.5) / 3, 0, 1) * 30
	for index, name in ipairs(TIE_SEGMENTS) do
		if into[name] then
			local wave = math.sin(elapsed * 16 - index * 0.9) * (8 + 7 * intensity)
			into[name] *= CFrame.Angles(math.rad(lift * (if index == 1 then 1.4 else 0.5) + wave), math.rad(math.sin(elapsed * 9 + index) * 8), 0)
		end
	end
	return into
end

local function collectJoints(model)
	local joints, names, lags = {}, {}, {}
	for _, motor in ipairs(model:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Part1 then
			local name = motor.Part1.Name
			local rotation = motor.C0.Rotation
			table.insert(joints, { name = name, motor = motor, rotation = rotation, inverse = rotation:Inverse() })
			table.insert(names, name)
			lags[name] = jointLag(name)
		end
	end
	return joints, names, lags
end

local function currentPose(joints)
	local pose = {}
	for _, joint in ipairs(joints) do
		pose[joint.name] = joint.rotation * joint.motor.Transform * joint.inverse
	end
	return pose
end

local function applyPose(joints, pose)
	for _, joint in ipairs(joints) do
		joint.motor.Transform = joint.inverse * (pose[joint.name] or CFrame.identity) * joint.rotation
	end
end

local function stopTracks()
	for _, track in ipairs({ body.idle, body.walk, body.attack }) do
		pcall(function()
			track:Stop(0)
		end)
	end
	body.moving = false
	if body.footsteps then
		body.footsteps:Stop()
	end
end

local function findPart(model, name)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant.Name == name and descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

local BODY_EMITTERS = { Triangles = true, ZoomParticle = true, YellowParticle = true }

local function bodyEffects(model)
	local lights, emitters, saved = {}, {}, {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("PointLight") then
			saved[descendant] = {
				Color = descendant.Color, Brightness = descendant.Brightness,
				Range = descendant.Range, Enabled = descendant.Enabled,
			}
			descendant.Brightness = 0
			descendant.Range = 16 * SETTINGS.Size
			descendant.Enabled = true
			table.insert(lights, descendant)
		elseif descendant:IsA("ParticleEmitter") and BODY_EMITTERS[descendant.Name] then
			saved[descendant] = {
				Color = descendant.Color, LightEmission = descendant.LightEmission,
				LightInfluence = descendant.LightInfluence, Enabled = descendant.Enabled,
			}
			descendant.LightEmission = 1
			descendant.LightInfluence = 0
			table.insert(emitters, descendant)
		end
	end
	return lights, emitters, saved
end

local CHAIN_TARGETS = {
	{ part = "RightHand",       angle = 35,   reach = 0.85, at = 0.95 },
	{ part = "LeftHand",        angle = 145,  reach = 0.85, at = 1.00 },
	{ part = "RightFoot",       angle = -60,  reach = 0.45, at = 1.12 },
	{ part = "LeftFoot",        angle = -120, reach = 0.45, at = 1.18 },
	{ part = "UpperTorso",      angle = -20,  reach = 0.9,  at = 1.28, offset = Vector3.new(0.9, 0.2, 0) },
	{ part = "UpperTorso",      angle = -160, reach = 0.9,  at = 1.34, offset = Vector3.new(-0.9, 0.2, 0) },
	{ part = "RightUpperWrist", angle = 5,    reach = 0.95, at = 1.44 },
	{ part = "LeftUpperWrist",  angle = 175,  reach = 0.95, at = 1.50 },
}

local function honchoBody(fail, failTimes)
	local model = state.model

	setMoving(false)
	local character = LocalPlayer.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if playerRoot then
		local toPlayer = flatUnit(playerRoot.Position - state.position)
		if toPlayer then
			state.rotation = CFrame.lookAt(Vector3.zero, toPlayer)
		end
	end
	render()

	local joints, jointNames, lags = collectJoints(model)
	local poses = { Start = currentPose(joints) }
	for name, spec in pairs(POSE_SPECS) do
		poses[name] = compilePose(spec)
	end
	stopTracks()

	local basePosition = state.position
	local floorY = floorAt(state.position, state.position.Y - state.pivotHeight)
	local center = Vector3.new(state.position.X, floorY, state.position.Z)
	local radius = math.clamp(math.max(state.boxSize.X, state.boxSize.Z) / 2 + 4, 6, 16)
	local lights, emitters, saved = bodyEffects(model)

	local total = SETTINGS.Papers
	local streamBudget = math.floor(total * 0.4)
	local geyserBudget = math.floor(total * 0.35)
	local rainBudget = total - streamBudget - geyserBudget
	local joltBurst = math.floor(total * 0.025)
	local streamEnd = if fail then failTimes.Break else 5.8
	local streamLeft = streamBudget
	local streamRate = math.max(streamBudget - joltBurst * 4, 0) / (streamEnd - 1)
	local streamCarry = 0
	local lastStream = 0
	local frame = {}

	local honcho = {
		Scale      = SETTINGS.Size,
		Anchor     = center,
		Radius     = radius,

		Depth      = state.pivotHeight + state.headHeight + (5 + 2.2) * SETTINGS.Size,
		Lights     = lights,
		Emitters   = emitters,

		SnapFirst  = "RightHand",
		SnapGroups = { { "RightHand", "RightUpperWrist" }, { "LeftHand", "LeftUpperWrist" }, { "UpperTorso" } },
	}

	function honcho.Chains()
		local chains = {}
		for _, spec in ipairs(CHAIN_TARGETS) do
			local part = findPart(model, spec.part)
			if part then
				table.insert(chains, {
					part   = part,
					name   = spec.part,
					offset = (spec.offset or Vector3.zero) * SETTINGS.Size,
					angle  = spec.angle,
					reach  = spec.reach,
					at     = spec.at,
				})
			end
		end
		return chains
	end

	function honcho.Place(yOffset, offset)
		state.position = basePosition + Vector3.new(0, yOffset, 0)
		render(offset)
	end

	function honcho.Pose(elapsed, isFail)
		applyPose(joints, sampleBanish(poses, jointNames, lags, elapsed, frame, isFail))
	end

	function honcho.Step(_, elapsed, deltaTime)
		if elapsed < 1 or elapsed > streamEnd or streamLeft <= 0 then return end
		streamCarry += streamRate * deltaTime
		if elapsed - lastStream < 0.1 then return end
		lastStream = elapsed

		local count = math.min(math.floor(streamCarry), streamLeft)
		if count > 0 then
			streamCarry -= count
			streamLeft -= count
			burstFromBody(count, floorY)
		end
	end

	function honcho.Jolt()
		local burst = math.min(streamLeft, joltBurst)
		streamLeft -= burst
		burstFromBody(burst, floorY)
	end

	function honcho.Scream(_, kind)
		pcall(function()
			body.scream.PlaybackSpeed = if kind == "roar" then 0.7 else 0.85
			body.scream.Volume = if kind == "roar" then 3 else 2
			body.scream:Play()
		end)
	end

	function honcho.Vanish()
		if model.Parent then
			model:Destroy()
		end
		geyser(geyserBudget + streamLeft, center, radius, floorY)
		streamLeft = 0
	end

	function honcho.After()
		task.spawn(function()
			local area = radius * 2.4
			local rainStart = os.clock()
			local rained = 0
			while rained < rainBudget and not state.finished do
				RunService.Heartbeat:Wait()
				local due = math.floor(rainBudget * math.clamp((os.clock() - rainStart) / 2.5, 0, 1))
				for _ = rained + 1, due do
					local angle = math.random() * math.pi * 2
					local distance = math.sqrt(math.random()) * area
					local origin = center + Vector3.new(math.cos(angle) * distance, 10 + math.random() * 4, math.sin(angle) * distance)
					spawnPaper(origin, floorY, Vector3.new((math.random() - 0.5) * 2, -1 - math.random() * 2, (math.random() - 0.5) * 2), 6 + math.random() * 2)
				end
				rained = math.max(rained, due)
			end
		end)
	end

	function honcho.BreakFree()
		burstFromBody(streamLeft + math.floor(geyserBudget * 0.5), floorY)
		streamLeft = 0
	end

	function honcho.Recover()
		for instance, properties in pairs(saved) do
			if instance.Parent then
				for property, value in pairs(properties) do
					pcall(function()
						instance[property] = value
					end)
				end
			end
		end
		pcall(function()
			body.scream.PlaybackSpeed = 1
			body.scream.Volume = 2
		end)
		applyPose(joints, {})
		state.position = basePosition
		render()
	end

	return honcho
end

local function ritual(tool, removeToolAfter)
	log("rituale del crocifisso")

	local Ritual = ritualModule()
	if not Ritual then
		state.noRitual = true
		state.paused = false
		state.watching = true
		return
	end

	local ok, result = pcall(function()
		local _, fail = Ritual.Outcome(tool, false)
		return Ritual.Run({
			Model = state.model,
			Tool  = tool,
			Body  = honchoBody(fail, Ritual.FailTimes),
			Alive = function()
				return not state.finished
			end,
		})
	end)

	if removeToolAfter and tool and tool.Parent then
		pcall(function()
			tool:Destroy()
		end)
	end

	if not ok then
		error(result)
	end

	if result == "Banished" then
		finish("esorcizzato")
	elseif result == "Failed" then
		log("il crocifisso si è spezzato: riparte")
		state.paused = false
		if state.running then
			setMoving(true)
		end
		task.delay(FAIL_GRACE, function()
			if not state.finished then
				state.watching = true
			end
		end)
	end
end

local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
sightParams.RespectCanCollide = true

local hidingSpots = CollectionService:GetTagged("HidingSpot")
local function refreshHidingSpots()
	hidingSpots = CollectionService:GetTagged("HidingSpot")
end
table.insert(connections, CollectionService:GetInstanceAddedSignal("HidingSpot"):Connect(refreshHidingSpots))
table.insert(connections, CollectionService:GetInstanceRemovedSignal("HidingSpot"):Connect(refreshHidingSpots))

local sightIgnore = {}

local function canSee(origin, target, character)

	table.clear(sightIgnore)
	table.move(hidingSpots, 1, #hidingSpots, 1, sightIgnore)
	table.insert(sightIgnore, character)
	table.insert(sightIgnore, state.model)
	sightParams.FilterDescendantsInstances = sightIgnore
	return workspace:Raycast(origin, target - origin, sightParams) == nil
end

local function heldCrucifix(character)
	if not character then return nil end

	local directTool = character:FindFirstChild("Crucifix")
	if directTool and directTool:IsA("Tool") then
		return directTool
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Tool")
			and (descendant.Name == "Crucifix" or CollectionService:HasTag(descendant, "Crucifix")) then
			return descendant
		end
	end

	return nil
end

local otherCrucifixRayParams = RaycastParams.new()
otherCrucifixRayParams.FilterType = Enum.RaycastFilterType.Exclude
otherCrucifixRayParams.RespectCanCollide = false

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

local function scanOtherPlayerCrucifix()
	if state.noRitual or state.finished or not state.model or not state.model.Parent then
		return false
	end

	otherCrucifixRayParams.FilterDescendantsInstances = { state.model }

	for _, candidatePlayer in ipairs(Players:GetPlayers()) do
		if candidatePlayer ~= LocalPlayer then
			local character = candidatePlayer.Character
			if character and character:IsDescendantOf(workspace) and not character:GetAttribute("Hiding") then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local rootPart = character:FindFirstChild("HumanoidRootPart")

				if humanoid and humanoid.Health > 0 and rootPart and rootPart:IsA("BasePart")
					and (rootPart.Position - state.position).Magnitude <= CRUCIFIX_RANGE + 4 then
					local tool = heldCrucifix(character)
					if tool then
						local targets = { rootPart }
						for _, partName in ipairs({ "Head", "UpperTorso", "Torso", "LowerTorso" }) do
							local targetPart = character:FindFirstChild(partName)
							if targetPart and targetPart:IsA("BasePart") then
								table.insert(targets, targetPart)
							end
						end

						for _, targetPart in ipairs(targets) do
							if state.finished or state.paused or not state.model.Parent then
								return false
							end

							local direction = targetPart.Position - state.position
							local distance = direction.Magnitude
							if distance > 0.001 and distance <= CRUCIFIX_RANGE then
								local result = workspace:Raycast(state.position, direction, otherCrucifixRayParams)
								local hitCharacter = result and getCharacterFromRaycastHit(result.Instance) or nil

								if hitCharacter ~= character then
									local partEntry = rayEntryDistanceToPart(state.position, direction.Unit, targetPart)
									if partEntry and partEntry <= distance + 0.01
									and (not result or result.Distance > partEntry + 0.02) then
										hitCharacter = character
									end
								end

								if hitCharacter == character then
									state.paused = true
									state.watching = false
									spawnSafe("rituale altro giocatore", ritual, tool, true)
									return true
								end
							end
						end
					end
				end
			end
		end
	end

	return false
end

local lastShake = 0

local function watchPlayer()
	if not state.watching or state.paused then return end
	if scanOtherPlayerCrucifix() then return end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then return end

	local head = character:FindFirstChild("Head")
	local target = (head or root).Position
	local distance = (target - state.position).Magnitude
	if distance > ENCOUNTER_RANGE then return end

	if distance <= SHAKE_RANGE and os.clock() - lastShake > 0.1 then
		lastShake = os.clock()
		local closeness = 1 - distance / SHAKE_RANGE
		shake(1.5 * closeness, 20 * closeness, 0.1, 1)
	end

	if not canSee(state.position, target, character) then return end

	local crucifix = not state.noRitual and heldCrucifix(character)
	if crucifix and distance <= CRUCIFIX_RANGE then
		state.paused = true
		state.watching = false
		spawnSafe("rituale", ritual, crucifix)
		return
	end

	if distance <= SETTINGS.KillRange and not character:GetAttribute("Hiding") then
		state.paused = true
		state.watching = false
			spawnSafe("jumpscare", jumpscare, humanoid)
	end
end

local function moveTo(target)
	while state.running do
		local deltaTime = RunService.Heartbeat:Wait()
		if not state.running then return end

		if not state.paused then
			local offset = target - state.position
			local distance = offset.Magnitude
			if distance < 0.1 then return end

			state.position += offset.Unit * math.min(state.speed * deltaTime, distance)
			local direction = flatUnit(offset)
			if direction then
				local facing = CFrame.lookAt(Vector3.zero, direction)
				state.rotation = state.rotation:Lerp(facing, 1 - math.exp(-TURN_SPEED * deltaTime))
			end
			render(walkBob())
		end
	end
end

local function walk(points)
	local lift = Vector3.new(0, state.pivotHeight, 0)
	for _, point in ipairs(points) do
		if not state.running then return end
		moveTo(point.position + lift)
	end
end

local function waitWhileRunning(seconds)
	local deadline = os.clock() + seconds
	while state.running and os.clock() < deadline do
		RunService.Heartbeat:Wait()
	end
end

local function sinkAway()
	setMoving(false)
	local start = state.position
	local startedAt = os.clock()
	while state.running do
		local progress = (os.clock() - startedAt) / 0.9
		if progress >= 1 then break end
		state.position = start - Vector3.new(0, 20 * progress ^ 2, 0)
		render()
		RunService.Heartbeat:Wait()
	end
end

local function waitForSync()
	local latest = latestRoomValue()
	if not latest then
		problem("non trovo GameData.LatestRoom, parto subito senza sincronizzarmi")
		return
	end
	log("sincronizzato: parto alla prossima porta (ora %s)", tostring(latest.Value))
	latest.Changed:Wait()

	task.wait(0.5)
end

local function main()
	if SETTINGS.Sync then
		waitForSync()
		if state.finished then return end
	end

	local path = buildPath()
	log("percorso: %d punti", #path)
	if #path < 2 then
		problem("non trovo i nodi delle stanze in workspace.CurrentRooms")
		finish("nessun nodo")
		return
	end

	state.position = path[1].position + Vector3.new(0, state.pivotHeight, 0)
	local firstStep = flatUnit(path[2].position - path[1].position)
	if firstStep then
		state.rotation = CFrame.lookAt(Vector3.zero, firstStep)
	end
	render()
	state.model.Parent = workspace
	state.running = true

	setupBody()
	setMoving(false)

	waitWhileRunning(SETTINGS.Delay)
	if not state.running then return end

	state.watching = true
	setMoving(true)
	walk(path)

	for _ = 1, SETTINGS.Rebounds do
		if not state.running then return end
		setMoving(false)
		waitWhileRunning(REBOUND_DELAY)
		setMoving(true)
		walk(reversed(path))

		if not state.running then return end
		setMoving(false)
		waitWhileRunning(REBOUND_DELAY)

		path = buildPath()
		setMoving(true)
		walk(path)
	end
	if not state.running then return end

	state.watching = false
	sinkAway()
	finish("percorso finito")
end

local model = prepareModel()
if not model then
	problem("non riesco a caricare il modello %d", MODEL_ID)
	return
end
state.model = model
log("modello pronto: pivot %.1f stud sopra i piedi, testa %.1f sopra il pivot", state.pivotHeight, state.headHeight)

_G.HonchoCleanup = dismiss

local reportedWatchError = false
table.insert(connections, RunService.Heartbeat:Connect(function()
	local ok, err = pcall(watchPlayer)
	if not ok and not reportedWatchError then
		reportedWatchError = true
		problem("errore nel controllo del giocatore: %s", tostring(err))
	end
end))

spawnSafe("precaricamento", preloadRitual)
spawnSafe("percorso", main)
end

local entityConfig = {
    ["rbxassetid://1"]  = entityBehaviors.SA90,
    ["rbxassetid://2"]  = entityBehaviors.WH1T3,
    ["rbxassetid://3"]  = entityBehaviors.TUMA,
    ["rbxassetid://4"]  = entityBehaviors.OSAB,
    ["rbxassetid://5"]  = entityBehaviors.kITTY,
    ["rbxassetid://6"]  = entityBehaviors.Hunger,
    ["rbxassetid://7"]  = entityBehaviors.HIMS,
    ["rbxassetid://8"]  = entityBehaviors.bkeyes,
    ["rbxassetid://9"]  = entityBehaviors.dread,
    ["rbxassetid://10"]  = entityBehaviors.DEPTH1,
    ["rbxassetid://11"]  = entityBehaviors.coomon,
    ["rbxassetid://13"]  = entityBehaviors.CLCR,
    ["rbxassetid://14"]  = entityBehaviors.FLU,
    ["rbxassetid://15"]  = entityBehaviors.MOVERS,
    ["rbxassetid://16"]  = entityBehaviors.SMILEWH,
    ["rbxassetid://17"]  = entityBehaviors.SMILEWH2,
    ["rbxassetid://22"]  = entityBehaviors.Muffler1,
    ["rbxassetid://31"]  = entityBehaviors.DeerGodTWO,
    ["rbxassetid://32"]  = entityBehaviors.SILENCECUR,
    ["rbxassetid://33"]  = entityBehaviors.HUNGERCUR,
    ["rbxassetid://34"]  = entityBehaviors.DEERCUR,
    ["rbxassetid://35"]  = entityBehaviors.RIPPCUR,
    ["rbxassetid://36"]  = entityBehaviors.REBOUCUR,
    ["rbxassetid://37"]  = entityBehaviors.JEFFXZ,
    ["rbxassetid://38"]  = entityBehaviors.JEFFZR,
    ["rbxassetid://99"]  = entityBehaviors.TOUSHI,
    ["rbxassetid://888"]  = entityBehaviors.WHATTHIS,
    ["rbxassetid://580"]  = entityBehaviors.SHOOPFY,
    ["rbxassetid://085"]  = entityBehaviors.MR,
    ["rbxassetid://086"]  = entityBehaviors.MRB,
    ["rbxassetid://087"]  = entityBehaviors.MC,
    ["rbxassetid://088"]  = entityBehaviors.MT,
    ["rbxassetid://089"]  = entityBehaviors.MD,
    ["rbxassetid://080"]  = entityBehaviors.MO,
    ["rbxassetid://081"]  = entityBehaviors.MM,
    ["rbxassetid://082"]  = entityBehaviors.MS,
    ["rbxassetid://083"]  = entityBehaviors.MF,
    ["rbxassetid://0854"]  = entityBehaviors.TheBoiledOne,
    ["rbxassetid://0855"]  = entityBehaviors.Baldi,
    ["rbxassetid://0856"]  = entityBehaviors.Baldi2,
    ["rbxassetid://0857"]  = entityBehaviors.FireMeld,
    ["rbxassetid://08588"]  = entityBehaviors.JEFFDEATH,
    ["rbxassetid://09666"]  = entityBehaviors.HATRED2,
    ["rbxassetid://8324537"]  = entityBehaviors.Claim,
    ["rbxassetid://623868"]  = entityBehaviors.Honcho,
    ["rbxassetid://12"]  = entityBehaviors.munci1
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
hint.Text = "LoadingFour... Doors HardCore V10.7.0 By Mr.key & HeavenNow & Number303 :)"
game.Debris:AddItem(hint, 2)