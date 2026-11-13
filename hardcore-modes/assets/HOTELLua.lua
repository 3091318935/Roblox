if workspace:FindFirstChild("HardcoreOne") then
    return
end
local marker = Instance.new("BoolValue")
marker.Name = "HardcoreOne"
marker.Value = true
marker.Parent = workspace
local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()
local entityBehaviors = {}

function entityBehaviors.ForstBite2()
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

function entityBehaviors.HATREDJN()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local targetPlayerName = "QWQ75321"
local modelId = 81410369891419

local targetPlayer = Players:WaitForChild(targetPlayerName)

local objects = game:GetObjects("rbxassetid://" .. modelId)
local halo = objects[1]

if not halo then
	return
end

halo.Parent = workspace

local parts = {}

if halo:IsA("BasePart") then
	table.insert(parts, halo)
else
	for _,v in ipairs(halo:GetDescendants()) do
		if v:IsA("BasePart") then
			table.insert(parts, v)
		end
	end
end

if #parts == 0 then
	halo:Destroy()
	return
end

for _,v in ipairs(parts) do
	v.Anchored = true
	v.CanCollide = false
	v.CanTouch = false
	v.CanQuery = false
end

local mainPart = parts[1]

local smoothCF = mainPart.CFrame
local angle = 0
local rotateSpeed = math.rad(120)

local offset = CFrame.new(0,0,4)

RunService.RenderStepped:Connect(function(dt)

	local character = targetPlayer.Character
	local head = character and character:FindFirstChild("Head")

	if not head then
		return
	end

	angle += rotateSpeed * dt

	local headCF = head.CFrame

	local targetCF =
		headCF
		* offset
		* CFrame.Angles(0, angle, 0)

	smoothCF = smoothCF:Lerp(targetCF, math.clamp(dt * 8,0,1))

	local moveCF = smoothCF * mainPart.CFrame:Inverse()

	for _,v in ipairs(parts) do
		v.CFrame = moveCF * v.CFrame
	end
end)
end

function entityBehaviors.CURXT()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local FollowPlayerName = "SparkleAtom"
local ModelID = "rbxassetid://82956537226998"
local AnimationID = "rbxassetid://122746752555782"
local RightOffset = 4
local BackOffset = 6
local HeightOffset = 1
local Smooth = 0.12
local player =
	Players:FindFirstChild(FollowPlayerName)


if not player then
	
	player =
		Players.PlayerAdded:Wait()
	
end
local objects

local success,err =
pcall(function()
	
	objects =
		game:GetObjects(ModelID)
	
end)

if not success or not objects[1] then
	return
end
local pet = objects[1]
pet.Name = "PetFollower"
pet.Parent = workspace
local humanoid =
	pet:FindFirstChildOfClass("Humanoid")
if not humanoid then
	return
	
end
local animator =
	humanoid:FindFirstChildOfClass("Animator")


if not animator then
	
	animator =
		Instance.new("Animator")
	
	animator.Parent = humanoid
	
end
local animation =
	Instance.new("Animation")


animation.AnimationId =
	AnimationID
local track


local ok,err =
pcall(function()
	
	track =
		animator:LoadAnimation(animation)
	
end)

if ok and track then
	
	track.Looped = true
	
	track.Priority =
		Enum.AnimationPriority.Action
	
	track:Play(0.2)
else
end
local root =
	pet:FindFirstChild("HumanoidRootPart")
	or pet.PrimaryPart
	or pet:FindFirstChildWhichIsA("BasePart")



if not root then
	return
	
end
pet.PrimaryPart = root

for _,part in ipairs(pet:GetDescendants()) do
	
	if part:IsA("BasePart") then
		
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		
	end
	
end
root.Anchored = true

local function GetTarget()


	local character =
		player.Character


	if not character then
		return nil
	end
	local hrp =
		character:FindFirstChild("HumanoidRootPart")


	if not hrp then
		return nil
	end

	return
		hrp.CFrame
		*
		CFrame.new(
			RightOffset,
			HeightOffset,
			BackOffset
		)
end
local first =
	GetTarget()
if first then
	
	root.CFrame = first
	
end
RunService.RenderStepped:Connect(function(dt)


	local target =
		GetTarget()


	if not target then
		return
	end

	local current =
		root.CFrame

	local new =
		current:Lerp(
			target,
			Smooth
		)
	root.CFrame = new
end)
end
function entityBehaviors.FigureXF()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local function findHeadPart()
    for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
        local figureRig = room:FindFirstChild("FigureRig")
        if figureRig and figureRig:IsA("Model") then
            local head = figureRig:FindFirstChild("Head")
            if head and head:IsA("MeshPart") then
                return head
            end
        end
    end
    return nil
end

local function attractToHead()
    local headPart = findHeadPart()
    if not headPart then return end

    local nearestPlayer
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (hrp.Position - headPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = player
            end
        end
    end
    
    if not nearestPlayer then

        return
    end
    local hrp = nearestPlayer.Character.HumanoidRootPart
    local moveSpeed = 0.5
    local stopDistance = 1
    while (hrp.Position - headPart.Position).Magnitude > stopDistance do
        local direction = (headPart.Position - hrp.Position).Unit
        hrp.CFrame = CFrame.new(hrp.Position + direction * moveSpeed)
        
        RunService.Heartbeat:Wait()
    end

end

attractToHead()
end

function entityBehaviors.FigureSpawn()

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FIGURE_ASSET_ID = "rbxassetid://96598945864381"
local TEMPLATE_NAME = "Figure1Template"
local MAIN_GRAPH_ID = "18570699250"
local SPECIAL_ANIMATIONS = {
	["18540813605"] = "idle",
	["18570706208"] = "run",
	["18583455040"] = "crucifix",
	["18542418459"] = "new_anim",
}

-- Higher means less visual lag. Teleports bypass smoothing altogether.
local FOLLOW_SMOOTHNESS = 35
local TELEPORT_DISTANCE = 18
local MOVEMENT_SAMPLE_INTERVAL = 0.1
local GRAPH_PROBE_INTERVAL = 0.25
local MAX_TIME_DRIFT = 0.20
local TIME_DRIFT_DEADZONE = 0.015
local MAX_SPEED_CORRECTION = 0.12
local SPEED_CORRECTION_GAIN = 0.8
local WEIGHT_TOLERANCE = 0.02

local dead = false
local currentRooms
local originalFigure
local figure1
local sourceAnimator
local targetAnimator
local sourceRoot
local targetRoot
local targetPivotFromRoot
local smoothedRoot
local soundController
local lastPosition
local movementSpeed = 0
local movementSampleTimer = 0

local graphSourceTrack
local graphTargetTrack
local graphStoppedConnection
local graphParameters = {}
local graphDefaults = {}
local graphLastValues = {}
local nextGraphParameterProbe = 0
local specialTracks = {}
local figureConnections = {}
local globalConnections = {}
local bindFigure

local function connectTo(list, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(list, connection)
	return connection
end

local function disconnectList(list)
	for _, connection in ipairs(list) do
		connection:Disconnect()
	end
	table.clear(list)
end

local function getAnimationId(track)
	local animation = track and track.Animation
	local id = animation and animation.AnimationId
	return id and id:match("%d+") or nil
end

local function findAnimator(model)
	if not model then
		return nil
	end
	local figurenoid = model:FindFirstChild("Figurenoid", true)
	if figurenoid then
		local animator = figurenoid:FindFirstChildWhichIsA("Animator", true)
		if animator then
			return animator
		end
	end
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		local animator = humanoid:FindFirstChildWhichIsA("Animator", true)
		if animator then
			return animator
		end
	end
	return model:FindFirstChildWhichIsA("Animator", true)
end

local function getTargetAnimator(model)
	local animator = findAnimator(model)
	if animator then
		return animator
	end
	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	local parent = humanoid or model:FindFirstChildWhichIsA("AnimationController", true)
	if not parent then
		parent = Instance.new("AnimationController")
		parent.Name = "AnimationController"
		parent.Parent = model
	end
	animator = Instance.new("Animator")
	animator.Parent = parent
	return animator
end

local function findRootPart(model)
	if not model then
		return nil
	end
	if model:IsA("BasePart") then
		return model
	end
	if model:IsA("Model") and model.PrimaryPart then
		return model.PrimaryPart
	end
	for _, name in ipairs({"HumanoidRootPart", "RootPart", "Root", "LowerTorso", "Torso"}) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function setupFollow(sourceModel, targetModel)
	sourceRoot = findRootPart(sourceModel)
	targetRoot = findRootPart(targetModel)
	if not sourceRoot or not targetRoot then
		return false
	end

	-- Keep the original offset between the model pivot and its chosen root.
	local rootFromPivot = targetModel:GetPivot():ToObjectSpace(targetRoot.CFrame)
	targetPivotFromRoot = rootFromPivot:Inverse()
	local parts = targetModel:GetDescendants()
	if targetModel:IsA("BasePart") then
		table.insert(parts, targetModel)
	end
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			part.Anchored = part == targetRoot
			part.CanCollide = false
			part.CanTouch = false
			part.Massless = part ~= targetRoot
		end
	end

	smoothedRoot = sourceRoot.CFrame
	targetModel:PivotTo(smoothedRoot * targetPivotFromRoot)
	return true
end

local function stepFollow(dt)
	if not figure1 or not figure1.Parent or not sourceRoot or not sourceRoot.Parent then
		return
	end
	local goal = sourceRoot.CFrame
	local distance = (goal.Position - smoothedRoot.Position).Magnitude
	if distance >= TELEPORT_DISTANCE or dt > 0.25 then
		smoothedRoot = goal
	else
		local alpha = 1 - math.exp(-FOLLOW_SMOOTHNESS * math.max(dt, 0))
		smoothedRoot = smoothedRoot:Lerp(goal, alpha)
	end
	figure1:PivotTo(smoothedRoot * targetPivotFromRoot)
end

local function hideObject(object)
	if object:IsA("BasePart") or object:IsA("Decal") or object:IsA("Texture") then
		object.Transparency = 1
	end
end

local function hideOriginal(model)
	for _, object in ipairs(model:GetDescendants()) do
		hideObject(object)
	end
	connectTo(figureConnections, model.DescendantAdded, hideObject)
end

local function isFootSound(sound, model)
	local current = sound.Parent
	while current and current ~= model do
		if current.Name == "RightFoot" or current.Name == "LeftFoot" then
			return true
		end
		current = current.Parent
	end
	return false
end

local function muteOriginal(model)
	local function mute(object)
		if object:IsA("Sound") and not isFootSound(object, model) then
			object.Volume = 0
		end
	end
	for _, object in ipairs(model:GetDescendants()) do
		mute(object)
	end
	connectTo(figureConnections, model.DescendantAdded, mute)
end

local SoundController = {}
SoundController.__index = SoundController

function SoundController.new(model)
	return setmetatable({
		model = model,
		mode = nil,
		walkTimer = 0,
		walkDelay = math.random(5, 10),
		currentClick = nil,
		clickConnection = nil,
	}, SoundController)
end

function SoundController:StopClick()
	if self.clickConnection then
		self.clickConnection:Disconnect()
		self.clickConnection = nil
	end
	if self.currentClick then
		pcall(function()
			self.currentClick:Stop()
			self.currentClick.TimePosition = 0
		end)
	end
	self.currentClick = nil
end

function SoundController:PlayClick()
	if self.currentClick or not self.model then
		return
	end
	local head = self.model:FindFirstChild("Head", true)
	if not head then
		return
	end
	local sounds = {}
	for _, name in ipairs({"Click", "ClickLow"}) do
		local sound = head:FindFirstChild(name, true)
		if sound and sound:IsA("Sound") then
			table.insert(sounds, sound)
		end
	end
	if #sounds == 0 then
		return
	end
	local sound = sounds[math.random(1, #sounds)]
	self.currentClick = sound
	self.clickConnection = sound.Ended:Connect(function()
		if self.currentClick == sound then
			self.currentClick = nil
		end
		if self.clickConnection then
			self.clickConnection:Disconnect()
			self.clickConnection = nil
		end
	end)
	local ok = pcall(function()
		sound.TimePosition = 0
		sound:Play()
	end)
	if not ok then
		self:StopClick()
	end
end

function SoundController:PlayGrowl()
	local head = self.model and self.model:FindFirstChild("Head", true)
	local growl = head and head:FindFirstChild("Growl", true)
	if growl and growl:IsA("Sound") then
		pcall(function()
			growl.TimePosition = 0
			growl.PlaybackSpeed = 1
			growl.Volume = 1
			growl:Play()
		end)
	end
end

function SoundController:SetMode(mode)
	if self.mode == mode then
		return
	end
	self:StopClick()
	self.mode = mode
	if mode == "walk" then
		self.walkTimer = 0
		self.walkDelay = math.random(5, 10)
		self:PlayClick()
	elseif mode == "run" then
		self:PlayGrowl()
	end
end

function SoundController:Step(dt)
	if self.mode ~= "walk" then
		return
	end
	self.walkTimer = self.walkTimer + dt
	if self.walkTimer >= self.walkDelay then
		self.walkTimer = 0
		self.walkDelay = math.random(5, 10)
		self:PlayClick()
	end
end

function SoundController:Destroy()
	self:StopClick()
	if self.model then
		for _, object in ipairs(self.model:GetDescendants()) do
			if object:IsA("Sound") then
				pcall(function()
					object:Stop()
				end)
			end
		end
	end
	self.model = nil
end

local function getTrackWeight(track)
	local ok, weight = pcall(function()
		return track.WeightCurrent
	end)
	return ok and weight or 0
end

local function hasActiveSpecial()
	for sourceTrack in pairs(specialTracks) do
		-- Weight can remain visible after Stopped while a track fades out.
		if getTrackWeight(sourceTrack) > 0.01 then
			return true
		end
	end
	return false
end

local function updateGraphBlend()
	local target = graphTargetTrack
	if not target then
		return
	end
	local weight = hasActiveSpecial() and 0 or 1
	pcall(function()
		if not target.IsPlaying then
			if graphSourceTrack then
				target:Play(0.08, weight, graphSourceTrack.Speed)
			end
		elseif math.abs(target.WeightTarget - weight) > 0.001 then
			target:AdjustWeight(weight, 0.08)
		end
	end)
end

local function getGraphDefaults(track)
	if not track or getAnimationId(track) ~= MAIN_GRAPH_ID then
		return {}
	end
	local ok, defaults = pcall(function()
		return track:GetParameterDefaults()
	end)
	return ok and type(defaults) == "table" and defaults or {}
end

local function refreshGraphParameters()
	if not graphSourceTrack or os.clock() < nextGraphParameterProbe then
		return
	end
	nextGraphParameterProbe = os.clock() + GRAPH_PROBE_INTERVAL
	for name, defaultValue in pairs(getGraphDefaults(graphSourceTrack)) do
		if graphDefaults[name] == nil then
			graphDefaults[name] = defaultValue
			table.insert(graphParameters, name)
		end
	end
end

-- Small drift is corrected by a gentle speed change. Only large drift causes a
-- time jump. Loop boundaries use the shortest wrapped time difference.
local function syncTrackPlayback(source, target)
	local speed = source.Speed
	if source.Looped ~= target.Looped then
		target.Looped = source.Looped
	end
	if source.IsPlaying and target.IsPlaying and source.Length > 0 and target.Length > 0 then
		local delta = source.TimePosition - target.TimePosition
		if source.Looped and target.Looped and math.abs(source.Length - target.Length) < 0.05 then
			local length = target.Length
			delta = (delta + length / 2) % length - length / 2
		end
		if math.abs(delta) > MAX_TIME_DRIFT or (math.abs(speed) < 0.001 and math.abs(delta) > TIME_DRIFT_DEADZONE) then
			local newTime = source.TimePosition
			if target.Looped then
				newTime = newTime % target.Length
			else
				newTime = math.clamp(newTime, 0, target.Length)
			end
			target.TimePosition = newTime
		elseif math.abs(speed) >= 0.001 and math.abs(delta) > TIME_DRIFT_DEADZONE then
			-- Never reverse a slowly playing source while correcting its phase.
			local limit = math.min(MAX_SPEED_CORRECTION, math.abs(speed) * 0.25)
			local correction = math.clamp(delta * SPEED_CORRECTION_GAIN, -limit, limit)
			speed = speed + correction
		end
	end
	if math.abs(target.Speed - speed) > 0.01 then
		target:AdjustSpeed(speed)
	end
end

local function syncGraph()
	local source = graphSourceTrack
	local target = graphTargetTrack
	if not source or not target then
		return
	end
	refreshGraphParameters()
	for _, name in ipairs(graphParameters) do
		local ok, value = pcall(source.GetParameter, source, name)
		if ok and value ~= nil and graphLastValues[name] ~= value then
			local setOk = pcall(target.SetParameter, target, name, value)
			if setOk then
				graphLastValues[name] = value
			end
		end
	end
	pcall(syncTrackPlayback, source, target)
end

local function stopGraph()
	if graphStoppedConnection then
		graphStoppedConnection:Disconnect()
		graphStoppedConnection = nil
	end
	if graphTargetTrack then
		pcall(function()
			graphTargetTrack:Stop(0)
			graphTargetTrack:Destroy()
		end)
	end
	graphSourceTrack = nil
	graphTargetTrack = nil
	table.clear(graphParameters)
	table.clear(graphDefaults)
	table.clear(graphLastValues)
	nextGraphParameterProbe = 0
end

local function loadTrack(id, name)
	local animation = Instance.new("Animation")
	animation.Name = name
	animation.AnimationId = "rbxassetid://" .. id
	local ok, track = pcall(function()
		return targetAnimator:LoadAnimation(animation)
	end)
	animation:Destroy()
	if not ok or not track then
		warn("[Figure1] 动画加载失败:", name, id)
		return nil
	end
	return track
end

local function bindGraph(sourceTrack)
	if dead or getAnimationId(sourceTrack) ~= MAIN_GRAPH_ID then
		return
	end
	if graphSourceTrack == sourceTrack and graphTargetTrack then
		return
	end
	stopGraph()
	local targetTrack = loadTrack(MAIN_GRAPH_ID, sourceTrack.Animation.Name)
	if not targetTrack then
		return
	end
	graphSourceTrack = sourceTrack
	graphTargetTrack = targetTrack
	graphDefaults = getGraphDefaults(sourceTrack)
	for name in pairs(graphDefaults) do
		table.insert(graphParameters, name)
	end
	pcall(function()
		targetTrack.Priority = sourceTrack.Priority
		targetTrack.Looped = sourceTrack.Looped
	end)
	for _, name in ipairs(graphParameters) do
		local ok, value = pcall(sourceTrack.GetParameter, sourceTrack, name)
		if not ok or value == nil then
			value = graphDefaults[name]
		end
		if value ~= nil and pcall(targetTrack.SetParameter, targetTrack, name, value) then
			graphLastValues[name] = value
		end
	end
	targetTrack:Play(0, hasActiveSpecial() and 0 or 1, sourceTrack.Speed)
	pcall(function()
		if targetTrack.Length > 0 then
			targetTrack.TimePosition = sourceTrack.TimePosition % targetTrack.Length
		end
	end)
	graphStoppedConnection = sourceTrack.Stopped:Connect(function()
		if graphSourceTrack ~= sourceTrack then
			return
		end
		graphSourceTrack = nil
		table.clear(graphParameters)
		table.clear(graphDefaults)
		table.clear(graphLastValues)
		pcall(function()
			targetTrack:AdjustSpeed(0)
		end)
		updateGraphBlend()
	end)
	syncGraph()
	updateGraphBlend()
end

local function removeSpecialTrack(sourceTrack)
	local info = specialTracks[sourceTrack]
	if not info then
		return
	end
	specialTracks[sourceTrack] = nil
	if info.endedConnection then
		info.endedConnection:Disconnect()
	end
	pcall(function()
		info.targetTrack:Stop(0)
		info.targetTrack:Destroy()
	end)
end

local function bindSpecialTrack(sourceTrack)
	if dead or specialTracks[sourceTrack] then
		return
	end
	local id = getAnimationId(sourceTrack)
	local name = id and SPECIAL_ANIMATIONS[id]
	if not name then
		return
	end
	local targetTrack = loadTrack(id, "Figure1_" .. name)
	if not targetTrack then
		return
	end
	pcall(function()
		targetTrack.Priority = sourceTrack.Priority
		targetTrack.Looped = sourceTrack.Looped
	end)
	targetTrack:Play(0.03, math.max(getTrackWeight(sourceTrack), 0.001), sourceTrack.Speed)
	pcall(function()
		targetTrack.TimePosition = sourceTrack.TimePosition
	end)
	local info = {name = name, targetTrack = targetTrack}
	specialTracks[sourceTrack] = info
	info.endedConnection = sourceTrack.Ended:Connect(function()
		removeSpecialTrack(sourceTrack)
		updateGraphBlend()
	end)
	updateGraphBlend()
end

local function syncSpecialTracks()
	local removeList = {}
	for sourceTrack, info in pairs(specialTracks) do
		local ok, playing = pcall(function()
			return sourceTrack.IsPlaying
		end)
		local weight = getTrackWeight(sourceTrack)
		if not ok or (not playing and weight <= 0.001) then
			table.insert(removeList, sourceTrack)
		else
			pcall(function()
				local target = info.targetTrack
				if target.IsPlaying then
					syncTrackPlayback(sourceTrack, target)
					if math.abs(target.WeightTarget - weight) > WEIGHT_TOLERANCE then
						target:AdjustWeight(weight, 0.04)
					end
				end
			end)
		end
	end
	for _, sourceTrack in ipairs(removeList) do
		removeSpecialTrack(sourceTrack)
	end
	updateGraphBlend()
end

local function inspectTrack(track)
	if dead or not track or not track.Animation then
		return
	end
	local id = getAnimationId(track)
	if id == MAIN_GRAPH_ID then
		bindGraph(track)
	elseif id and SPECIAL_ANIMATIONS[id] then
		bindSpecialTrack(track)
	end
end

local function getActiveSpecial()
	for _, wantedName in ipairs({"crucifix", "new_anim", "run"}) do
		for sourceTrack, info in pairs(specialTracks) do
			if info.name == wantedName and getTrackWeight(sourceTrack) > 0.01 then
				return wantedName
			end
		end
	end
	return nil
end

local function updateSoundMode()
	if not soundController then
		return
	end
	local special = getActiveSpecial()
	if special == "run" then
		soundController:SetMode("run")
	elseif special then
		soundController:SetMode(nil)
	elseif movementSpeed > 0.5 then
		soundController:SetMode("walk")
	else
		soundController:SetMode(nil)
	end
end

local function shutdown()
	if dead then
		return
	end
	dead = true
	disconnectList(figureConnections)
	disconnectList(globalConnections)
	local tracks = {}
	for sourceTrack in pairs(specialTracks) do
		table.insert(tracks, sourceTrack)
	end
	for _, sourceTrack in ipairs(tracks) do
		removeSpecialTrack(sourceTrack)
	end
	stopGraph()
	if soundController then
		soundController:Destroy()
		soundController = nil
	end
	if figure1 then
		figure1:Destroy()
		figure1 = nil
	end
	originalFigure = nil
	sourceAnimator = nil
	targetAnimator = nil
	sourceRoot = nil
	targetRoot = nil
	smoothedRoot = nil
end

local function loadReplacement()
	local template = ReplicatedStorage:FindFirstChild(TEMPLATE_NAME)
	if template and (template:IsA("Model") or template:IsA("BasePart")) then
		local ok, result = pcall(function()
			return template:Clone()
		end)
		if ok and result then
			return result
		end
		warn("[Figure1] Figure1Template 无法克隆，请检查 Archivable。")
	end
	local ok, objects = pcall(function()
		return game:GetObjects(FIGURE_ASSET_ID)
	end)
	if not ok or not objects or not objects[1] then
		warn("[Figure1] 替身加载失败。普通脚本请在 ReplicatedStorage 放入 Figure1Template 模型。")
		return nil
	end
	local model = objects[1]
	for i = 2, #objects do
		objects[i]:Destroy()
	end
	if not model:IsA("Model") and not model:IsA("BasePart") then
		model:Destroy()
		warn("[Figure1] 替身资源必须是 Model 或 BasePart。")
		return nil
	end
	return model
end

bindFigure = function(figureRig)
	if dead or originalFigure then
		return
	end
	originalFigure = figureRig
	sourceAnimator = findAnimator(figureRig)
	if not sourceAnimator then
		warn("[Figure1] 原 Figure 缺少 Animator。")
		shutdown()
		return
	end
	figure1 = loadReplacement()
	if not figure1 then
		shutdown()
		return
	end
	figure1.Name = "Figure1"
	figure1.Parent = workspace
	targetAnimator = getTargetAnimator(figure1)
	if not setupFollow(figureRig, figure1) then
		warn("[Figure1] 无法找到原 Figure 或替身的根部 BasePart。")
		shutdown()
		return
	end
	hideOriginal(figureRig)
	muteOriginal(figureRig)
	disconnectList(globalConnections)
	lastPosition = sourceRoot.Position
	soundController = SoundController.new(figure1)

	for _, track in ipairs(targetAnimator:GetPlayingAnimationTracks()) do
		pcall(function()
			track:Stop(0)
		end)
	end
	connectTo(figureConnections, sourceAnimator.AnimationPlayed, inspectTrack)
	local ok, tracks = pcall(function()
		return sourceAnimator:GetPlayingAnimationTracks()
	end)
	if ok then
		for _, track in ipairs(tracks) do
			inspectTrack(track)
		end
	end

	connectTo(figureConnections, figureRig.Destroying, shutdown)
	connectTo(figureConnections, figureRig.AncestryChanged, function()
		if not figureRig:IsDescendantOf(workspace) then
			shutdown()
		end
	end)
	connectTo(figureConnections, RunService.PreAnimation, function()
		if not dead then
			syncGraph()
			syncSpecialTracks()
		end
	end)
	-- PreRender is client-only. On a server, use Heartbeat as a fallback.
	local followEvent = RunService:IsClient() and RunService.PreRender or RunService.Heartbeat
	connectTo(figureConnections, followEvent, function(dt)
		if not dead then
			stepFollow(dt)
		end
	end)
	connectTo(figureConnections, RunService.Heartbeat, function(dt)
		if dead then
			return
		end
		if not originalFigure or not originalFigure.Parent or not figure1 or not figure1.Parent
			or not sourceRoot or not sourceRoot.Parent or not targetRoot or not targetRoot.Parent then
			shutdown()
			return
		end
		movementSampleTimer = movementSampleTimer + dt
		if movementSampleTimer >= MOVEMENT_SAMPLE_INTERVAL then
			local position = sourceRoot.Position
			if lastPosition then
				movementSpeed = (position - lastPosition).Magnitude / movementSampleTimer
			end
			lastPosition = position
			movementSampleTimer = 0
		end
		updateSoundMode()
		soundController:Step(dt)
	end)
end

currentRooms = workspace:WaitForChild("CurrentRooms")
connectTo(globalConnections, currentRooms.DescendantAdded, function(object)
	if not dead and not originalFigure and object.Name == "FigureRig"
		and (object:IsA("Model") or object:IsA("Folder")) then
		bindFigure(object)
	end
end)

for _, object in ipairs(currentRooms:GetDescendants()) do
	if object.Name == "FigureRig" and (object:IsA("Model") or object:IsA("Folder")) then
		bindFigure(object)
		break
	end
end
end

function entityBehaviors.Z367Game()
local Z367_MUSIC_VOLUME = 4.4
local Z367_PRELOADED_MUSIC = workspace:WaitForChild("HardCoreSound"):WaitForChild("Z367")

if Z367_PRELOADED_MUSIC:IsA("Sound") then
    Z367_PRELOADED_MUSIC.Volume = Z367_MUSIC_VOLUME
    Z367_PRELOADED_MUSIC.Looped = false
    pcall(function()
        Z367_PRELOADED_MUSIC:Stop()
        Z367_PRELOADED_MUSIC.TimePosition = 0
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local CONFIG = {
    Duration = 42,
    MaxPressure = 5,

    MouseSensitivity = 0.00205,
    Friction = 0.875,
    MaxSpeed = 0.027,
    CenterRadius = 0.105,
    OuterLimit = 0.445,
    Spring = 0.00082,

    RecoveryRate = 1.45,
    BaseDrainRate = 0.48,
    DistanceDrain = 1.55,

    Phase = {
        [1] = {
            MinEventDelay = 4.0,
            MaxEventDelay = 6.2,
            ImpactForce = 0.105,
            ShakeMagnitude = 18,
            ShakeRoughness = 120,
            ShakeFadeIn = 0.06,
            ShakeFadeOut = 0.28,
            ShakePosInfluence = 1.45,
            ShakeRotInfluence = 0.32,
            DrainMultiplier = 1.00,
            InputMultiplier = 1.00,
        },
        [2] = {
            MinEventDelay = 3.1,
            MaxEventDelay = 5.0,
            ImpactForce = 0.135,
            ShakeMagnitude = 22,
            ShakeRoughness = 145,
            ShakeFadeIn = 0.06,
            ShakeFadeOut = 0.30,
            ShakePosInfluence = 1.70,
            ShakeRotInfluence = 0.40,
            DrainMultiplier = 1.06,
            InputMultiplier = 0.98,
        },
        [3] = {
            MinEventDelay = 2.35,
            MaxEventDelay = 4.0,
            ImpactForce = 0.165,
            ShakeMagnitude = 26,
            ShakeRoughness = 170,
            ShakeFadeIn = 0.07,
            ShakeFadeOut = 0.34,
            ShakePosInfluence = 1.90,
            ShakeRotInfluence = 0.48,
            DrainMultiplier = 1.12,
            InputMultiplier = 0.96,
        },

        [4] = {
            MinEventDelay = 2.75,
            MaxEventDelay = 4.45,
            ImpactForce = 0.150,
            ShakeMagnitude = 30,
            ShakeRoughness = 200,
            ShakeFadeIn = 0.10,
            ShakeFadeOut = 0.22,
            ShakePosInfluence = 2.00,
            ShakeRotInfluence = 0.50,
            DrainMultiplier = 1.07,
            InputMultiplier = 0.95,
        },
    },

    ImpactSoundId = "",
    WarningSoundId = "",
    HeartbeatSoundId = "",
}

local state = {
    active = false,
    dead = false,
    ending = false,
    pressure = CONFIG.MaxPressure,
    remaining = CONFIG.Duration,
    progress = 0,
    phase = 1,
    ballPos = Vector2.new(0.5, 0.5),
    ballVelocity = Vector2.zero,
    inverted = false,
    blackout = false,
    distortion = 0,
    nextEventAt = 0,
    connections = {},
    tweens = {},
    music = nil,
    heartbeat = nil,
    oldMouseBehavior = UserInputService.MouseBehavior,
    oldMouseIcon = UserInputService.MouseIconEnabled,
}

local function clamp01(x)
    return math.clamp(x, 0, 1)
end

local function randomUnit2()
    local a = math.random() * math.pi * 2
    return Vector2.new(math.cos(a), math.sin(a))
end

local function tween(obj, info, props)
    if not obj or not obj.Parent then return nil end
    local t = TweenService:Create(obj, info, props)
    table.insert(state.tweens, t)
    t:Play()
    return t
end

local function safeDestroy(x)
    if x and x.Parent then
        x:Destroy()
    end
end

local function new(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", {
        Color = color or Color3.fromRGB(255,255,255),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

local function playOneShot(soundId, volume, speed)
    if not soundId or soundId == "" then return end
    local s = new("Sound", {
        SoundId = soundId,
        Volume = volume or 1,
        PlaybackSpeed = speed or 1,
    }, workspace)
    s:Play()
    Debris:AddItem(s, 5)
end

local function runCameraShake(magnitude, roughness, fadeIn, fadeOut, posInfluence, rotInfluence)
    local cameraShakerModule = ReplicatedStorage:FindFirstChild("CameraShaker")
    if not cameraShakerModule then
        return false
    end

    local ok = pcall(function()
        local CameraShaker = require(cameraShakerModule)
        local currentCamera = workspace.CurrentCamera

        local camShake = CameraShaker.new(
            Enum.RenderPriority.Camera.Value,
            function(shakeCf)
                currentCamera = workspace.CurrentCamera
                if currentCamera then
                    currentCamera.CFrame = currentCamera.CFrame * shakeCf
                end
            end
        )

        camShake:Start()
        camShake:ShakeOnce(
            magnitude or 30,
            roughness or 200,
            fadeIn or 0.1,
            fadeOut or 0.2,
            posInfluence or 2,
            rotInfluence or 0.5
        )

        task.delay((fadeIn or 0.1) + (fadeOut or 0.2) + 0.35, function()
            pcall(function()
                camShake:Stop()
            end)
        end)
    end)

    return ok
end

local function runFinalCameraShake()
    return runCameraShake(30, 200, 0.1, 0.2, 2, 0.5)
end

local fallbackShake = {
    power = 0,
    endAt = 0,
}

local function requestFallbackShake(power, duration)
    fallbackShake.power = math.max(fallbackShake.power, power or 0)
    fallbackShake.endAt = math.max(fallbackShake.endAt, os.clock() + (duration or 0.25))
end

local gameCameraShaker = nil

local function stopGameCameraShake()
    if gameCameraShaker then
        pcall(function()
            gameCameraShaker:Stop()
        end)
        gameCameraShaker = nil
    end
end

local function runGameCameraShake()
    stopGameCameraShake()

    local cameraShakerModule = ReplicatedStorage:FindFirstChild("CameraShaker")
    if not cameraShakerModule then

        requestFallbackShake(0.004, CONFIG.Duration)
        return false
    end

    local ok = pcall(function()
        local CameraShaker = require(cameraShakerModule)

        gameCameraShaker = CameraShaker.new(
            Enum.RenderPriority.Camera.Value,
            function(shakeCf)
                local currentCamera = workspace.CurrentCamera
                if currentCamera and state.active then
                    currentCamera.CFrame = currentCamera.CFrame * shakeCf
                end
            end
        )

        gameCameraShaker:Start()

        gameCameraShaker:ShakeOnce(
            10,
            10,
            0.1,
            CONFIG.Duration,
            2,
            0.5
        )
    end)

    if not ok then
        gameCameraShaker = nil
        requestFallbackShake(0.004, CONFIG.Duration)
        return false
    end

    return true
end

local function shakeForPhase(multiplier)
    if _G.Z367PlayModelBang then
        pcall(_G.Z367PlayModelBang)
    end
    local p = CONFIG.Phase[state.phase]
    multiplier = multiplier or 1

    local worked = runCameraShake(
        p.ShakeMagnitude * multiplier,
        p.ShakeRoughness,
        p.ShakeFadeIn,
        p.ShakeFadeOut,
        p.ShakePosInfluence,
        p.ShakeRotInfluence
    )

    if not worked then
        requestFallbackShake(0.010 * p.ShakeMagnitude / 18 * multiplier, p.ShakeFadeOut + 0.15)
    end
end

local function buildUI()
    local old = playerGui:FindFirstChild("Z367_V31")
    if old then old:Destroy() end

    local gui = new("ScreenGui", {
        Name = "Z367_V31",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = 999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    local root = new("Frame", {
        Name = "Root",
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.fromRGB(5,5,7),
        BackgroundTransparency = 0.46,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, gui)

    local introFade = new("Frame", {
        Name = "GameFade",
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        Active = false,
        ZIndex = 1000,
    }, gui)

    local flash = new("Frame", {
        Name = "ImpactFlash",
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.fromRGB(255,245,245),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 800,
    }, gui)

    local redPulse = new("Frame", {
        Name = "DangerPulse",
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.fromRGB(170,0,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 20,
    }, gui)

    local vignetteTop = new("Frame", {
        Size = UDim2.new(1,0,0.24,0),
        BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, gui)
    local gt = new("UIGradient", {Rotation = 90}, vignetteTop)
    gt.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0),
        NumberSequenceKeypoint.new(1,1),
    })

    local vignetteBottom = vignetteTop:Clone()
    vignetteBottom.Position = UDim2.new(0,0,0.76,0)
    vignetteBottom.Parent = gui
    vignetteBottom.UIGradient.Rotation = -90

    local vignetteLeft = new("Frame", {
        Size = UDim2.new(0.18,0,1,0),
        BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, gui)
    local gl = new("UIGradient", {Rotation = 0}, vignetteLeft)
    gl.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0),
        NumberSequenceKeypoint.new(1,1),
    })

    local vignetteRight = vignetteLeft:Clone()
    vignetteRight.Position = UDim2.new(0.82,0,0,0)
    vignetteRight.Parent = gui
    vignetteRight.UIGradient.Rotation = 180

    local scanHolder = new("Frame", {
        Name = "Scanlines",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, gui)

    for y = 0, 1, 0.018 do
        new("Frame", {
            Size = UDim2.new(1,0,0,1),
            Position = UDim2.new(0,0,y,0),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            BackgroundTransparency = 0.965,
            BorderSizePixel = 0,
            ZIndex = 15,
        }, scanHolder)
    end

    local title = new("TextLabel", {
        Name = "Title",
        AnchorPoint = Vector2.new(0.5,0),
        Position = UDim2.new(0.5,0,0.055,0),
        Size = UDim2.new(0.7,0,0,34),
        BackgroundTransparency = 1,
        Text = "Z-367 // CONTAINMENT INTERFACE",
        TextColor3 = Color3.fromRGB(218,218,218),
        TextTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 21,
        TextStrokeTransparency = 0.7,
        ZIndex = 30,
    }, gui)

    local subtitle = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5,0),
        Position = UDim2.new(0.5,0,0.095,0),
        Size = UDim2.new(0.7,0,0,24),
        BackgroundTransparency = 1,
        Text = "MAINTAIN SIGNAL STABILITY",
        TextColor3 = Color3.fromRGB(145,145,150),
        TextTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 14,
        ZIndex = 30,
    }, gui)

    local arena = new("Frame", {
        Name = "Arena",
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.52),
        Size = UDim2.fromOffset(410,410),
        BackgroundColor3 = Color3.fromRGB(12,12,15),
        BackgroundTransparency = 0.36,
        BorderSizePixel = 0,
        ZIndex = 30,
    }, gui)
    corner(arena, 205)
    local arenaStroke = stroke(arena, Color3.fromRGB(115,115,125), 2, 0.34)

    local ring2 = new("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(270,270),
        BackgroundTransparency = 1,
        ZIndex = 31,
    }, arena)
    corner(ring2, 135)
    stroke(ring2, Color3.fromRGB(80,80,90), 1, 0.48)

    local safeZone = new("Frame", {
        Name = "SafeZone",
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(88,88),
        BackgroundColor3 = Color3.fromRGB(185,185,190),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 33,
    }, arena)
    corner(safeZone, 44)
    local safeStroke = stroke(safeZone, Color3.fromRGB(200,200,205), 2, 0.18)

    local centerDot = new("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(6,6),
        BackgroundColor3 = Color3.fromRGB(235,235,240),
        BorderSizePixel = 0,
        ZIndex = 36,
    }, arena)
    corner(centerDot, 6)

    local ballGlow = new("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(42,42),
        BackgroundColor3 = Color3.fromRGB(220,220,230),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 34,
    }, arena)
    corner(ballGlow, 21)

    local ball = new("Frame", {
        Name = "ControlBall",
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(19,19),
        BackgroundColor3 = Color3.fromRGB(225,225,232),
        BorderSizePixel = 0,
        ZIndex = 35,
    }, arena)
    corner(ball, 10)
    stroke(ball, Color3.fromRGB(255,255,255), 1, 0.4)

    local pressurePanel = new("Frame", {
        AnchorPoint = Vector2.new(0.5,1),
        Position = UDim2.new(0.5,0,0.92,0),
        Size = UDim2.fromOffset(520,62),
        BackgroundColor3 = Color3.fromRGB(8,8,10),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 30,
    }, gui)
    corner(pressurePanel, 6)
    stroke(pressurePanel, Color3.fromRGB(75,75,82), 1, 0.3)

    local pressureLabel = new("TextLabel", {
        Position = UDim2.fromOffset(12,6),
        Size = UDim2.new(1,-24,0,18),
        BackgroundTransparency = 1,
        Text = "SIGNAL PRESSURE",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(170,170,175),
        Font = Enum.Font.Code,
        TextSize = 13,
        ZIndex = 32,
    }, pressurePanel)

    local pressureBack = new("Frame", {
        Position = UDim2.fromOffset(12,31),
        Size = UDim2.new(1,-24,0,17),
        BackgroundColor3 = Color3.fromRGB(30,30,34),
        BorderSizePixel = 0,
        ZIndex = 32,
    }, pressurePanel)
    corner(pressureBack, 3)

    local pressureFill = new("Frame", {
        Name = "PressureFill",
        Size = UDim2.fromScale(1,1),
        BackgroundColor3 = Color3.fromRGB(195,195,200),
        BorderSizePixel = 0,
        ZIndex = 33,
    }, pressureBack)
    corner(pressureFill, 3)

    local timer = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5,0),
        Position = UDim2.new(0.5,0,0.135,0),
        Size = UDim2.fromOffset(180,48),
        BackgroundTransparency = 1,
        Text = "01:01",
        TextColor3 = Color3.fromRGB(225,225,230),
        TextTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 34,
        TextStrokeTransparency = 0.72,
        ZIndex = 30,
    }, gui)

    local phaseText = new("TextLabel", {
        AnchorPoint = Vector2.new(0,0),
        Position = UDim2.new(0.025,0,0.04,0),
        Size = UDim2.fromOffset(240,30),
        BackgroundTransparency = 1,
        Text = "PHASE // 01",
        TextColor3 = Color3.fromRGB(135,135,145),
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Code,
        TextSize = 15,
        ZIndex = 30,
    }, gui)

    local warning = new("TextLabel", {
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.29),
        Size = UDim2.new(0.8,0,0,52),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(255,75,75),
        TextTransparency = 1,
        TextStrokeTransparency = 0.35,
        Font = Enum.Font.Code,
        TextSize = 25,
        ZIndex = 120,
    }, gui)

    local glitchHolder = new("Frame", {
        Name = "GlitchHolder",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 150,
    }, gui)

    local blur = Lighting:FindFirstChild("Z367_V31_Blur")
    if blur then blur:Destroy() end
    blur = new("BlurEffect", {Name="Z367_V31_Blur", Size=0}, Lighting)

    local color = Lighting:FindFirstChild("Z367_V31_Color")
    if color then color:Destroy() end
    color = new("ColorCorrectionEffect", {
        Name = "Z367_V31_Color",
        Brightness = -0.02,
        Contrast = 0.05,
        Saturation = -0.08,
        TintColor = Color3.fromRGB(240,240,246),
    }, Lighting)

    return {
        Gui = gui,
        Root = root,
        IntroFade = introFade,
        Flash = flash,
        RedPulse = redPulse,
        Title = title,
        Subtitle = subtitle,
        Arena = arena,
        ArenaStroke = arenaStroke,
        SafeZone = safeZone,
        SafeStroke = safeStroke,
        Ball = ball,
        BallGlow = ballGlow,
        PressureFill = pressureFill,
        PressureLabel = pressureLabel,
        Timer = timer,
        PhaseText = phaseText,
        Warning = warning,
        GlitchHolder = glitchHolder,
        Blur = blur,
        Color = color,
    }
end

local ui = nil

local function runGameFadeIn()

    ui.IntroFade.Visible = true
    ui.IntroFade.Active = false
    ui.IntroFade.BackgroundTransparency = 0
    ui.Title.TextTransparency = 1
    ui.Subtitle.TextTransparency = 1
    ui.Timer.TextTransparency = 1
    ui.PhaseText.TextTransparency = 1

    task.wait(0.35)

    tween(
        ui.IntroFade,
        TweenInfo.new(1.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )

    task.delay(0.22, function()
        tween(ui.Title, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {TextTransparency = 0})
        tween(ui.Timer, TweenInfo.new(0.75, Enum.EasingStyle.Quad), {TextTransparency = 0})
    end)

    task.delay(0.46, function()
        tween(ui.Subtitle, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {TextTransparency = 0})
        tween(ui.PhaseText, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {TextTransparency = 0})
    end)

    task.delay(1.8, function()
        if ui.IntroFade and ui.IntroFade.Parent then
            ui.IntroFade.BackgroundTransparency = 1
            ui.IntroFade.Visible = false
            ui.IntroFade.Active = false
        end
    end)
end

local function setWarning(text, duration, strong)
    if not state.active or state.ending then return end
    ui.Warning.Text = text
    ui.Warning.TextTransparency = 1
    ui.Warning.Position = UDim2.fromScale(0.5,0.29)

    tween(ui.Warning, TweenInfo.new(0.10, Enum.EasingStyle.Linear), {
        TextTransparency = 0,
        Position = UDim2.fromScale(0.5,0.285),
    })

    if strong then
        ui.Warning.TextSize = 29
    else
        ui.Warning.TextSize = 24
    end

    task.delay(duration or 0.65, function()
        if ui.Warning and ui.Warning.Parent then
            tween(ui.Warning, TweenInfo.new(0.24), {TextTransparency = 1})
        end
    end)
end

local function flashScreen(color, peakTransparency, inTime, outTime)
    ui.Flash.BackgroundColor3 = color or Color3.new(1,1,1)
    ui.Flash.BackgroundTransparency = 1

    tween(ui.Flash, TweenInfo.new(inTime or 0.035), {
        BackgroundTransparency = peakTransparency or 0.18
    })

    task.delay(inTime or 0.035, function()
        tween(ui.Flash, TweenInfo.new(outTime or 0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
    end)
end

local function pulseDanger(amount)
    amount = clamp01(amount or 0.5)
    ui.RedPulse.BackgroundTransparency = 1
    tween(ui.RedPulse, TweenInfo.new(0.07), {
        BackgroundTransparency = 0.92 - amount * 0.34
    })
    task.delay(0.08, function()
        tween(ui.RedPulse, TweenInfo.new(0.45), {BackgroundTransparency = 1})
    end)
end

local function impactBlur(size)
    ui.Blur.Size = 0
    tween(ui.Blur, TweenInfo.new(0.055), {Size = size or 17})
    task.delay(0.07, function()
        tween(ui.Blur, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = 0})
    end)
end

local function spawnGlitchSlice(intensity)
    if not ui.GlitchHolder or not ui.GlitchHolder.Parent then return end
    intensity = intensity or 1

    local h = math.random(2, math.max(3, math.floor(12 * intensity)))
    local y = math.random(5,95) / 100
    local offset = math.random(-22,22) * intensity

    local slice = new("Frame", {
        Position = UDim2.new(0,offset,y,0),
        Size = UDim2.new(1,0,0,h),
        BackgroundColor3 = (math.random() > 0.5)
            and Color3.fromRGB(220,225,235)
            or Color3.fromRGB(140,0,20),
        BackgroundTransparency = 0.70 + math.random() * 0.20,
        BorderSizePixel = 0,
        ZIndex = 151,
    }, ui.GlitchHolder)

    Debris:AddItem(slice, math.random(3,10)/100)
end

local function glitchBurst(intensity, duration)
    intensity = intensity or 1
    duration = duration or 0.3

    task.spawn(function()
        local finish = os.clock() + duration
        while state.active and os.clock() < finish do
            for _ = 1, math.max(1, math.floor(2 * intensity)) do
                spawnGlitchSlice(intensity)
            end

            local x = math.random(-5,5) * intensity
            local y = math.random(-3,3) * intensity
            ui.Arena.Position = UDim2.new(0.5,x,0.52,y)
            ui.Title.Position = UDim2.new(0.5,-x,0.055,0)

            task.wait(math.random(2,6)/100)
        end

        if ui.Arena and ui.Arena.Parent then
            ui.Arena.Position = UDim2.fromScale(0.5,0.52)
        end
        if ui.Title and ui.Title.Parent then
            ui.Title.Position = UDim2.new(0.5,0,0.055,0)
        end
    end)
end

local function addForce(force, multiplier)
    state.ballVelocity += force * (multiplier or 1)
end

local function doImpact(strengthMultiplier, warningText)
    if not state.active or state.ending then return end

    local p = CONFIG.Phase[state.phase]
    strengthMultiplier = strengthMultiplier or 1

    setWarning(warningText or ">> IMPACT DETECTED <<", 0.45, true)
    playOneShot(CONFIG.WarningSoundId, 1.2, 1)

    task.wait(math.max(0.10, 0.22 - state.phase * 0.025))

    local direction = randomUnit2()
    addForce(direction * p.ImpactForce * strengthMultiplier)

    shakeForPhase(strengthMultiplier)

    flashScreen(Color3.fromRGB(255,245,245), 0.12, 0.025, 0.32)
    pulseDanger(0.55 + state.phase * 0.08)
    impactBlur(13 + state.phase * 3)
    glitchBurst(0.65 + state.phase * 0.12, 0.18 + state.phase * 0.035)
    playOneShot(CONFIG.ImpactSoundId, 1.8, 0.92 + math.random() * 0.12)
end

local function doDoubleImpact()
    if not state.active then return end
    setWarning("MULTIPLE CONTACTS", 0.55, true)
    doImpact(0.82, "CONTACT // 01")
    task.wait(0.22)
    if state.active then
        doImpact(0.78, "CONTACT // 02")
    end
end

local function doDistortion()
    if not state.active or state.ending then return end
    setWarning("SIGNAL INVERSION", 0.9, true)

    state.inverted = true
    state.distortion = math.max(state.distortion, 0.85)

    shakeForPhase(0.58)
    glitchBurst(1.65, 0.8)
    impactBlur(19)
    pulseDanger(0.45)

    local oldTint = ui.Color.TintColor
    ui.Color.TintColor = Color3.fromRGB(205,225,255)
    ui.Color.Contrast = 0.18

    task.delay(state.phase == 4 and 1.45 or 1.7, function()
        state.inverted = false
        if ui.Color and ui.Color.Parent then
            ui.Color.TintColor = oldTint
            ui.Color.Contrast = 0.05
        end
    end)
end

local function doPressureSurge()
    if not state.active or state.ending then return end
    setWarning("PRESSURE SURGE", 0.75, true)

    shakeForPhase(0.72)
    flashScreen(Color3.fromRGB(255,70,70), 0.56, 0.05, 0.50)
    pulseDanger(0.8)
    impactBlur(15)
    glitchBurst(1.1, 0.42)

    local drain = ({0.20,0.28,0.36,0.36})[state.phase]
    state.pressure = math.max(0, state.pressure - drain)

    addForce(randomUnit2() * CONFIG.Phase[state.phase].ImpactForce * 0.62)
end

local function doBlackout()
    if not state.active or state.ending then return end
    setWarning("VISUAL FEED LOST", 0.5, true)

    shakeForPhase(0.62)
    glitchBurst(1.35, 0.32)

    state.blackout = true
    tween(ui.Root, TweenInfo.new(0.10), {BackgroundTransparency = 0.02})
    tween(ui.Arena, TweenInfo.new(0.10), {BackgroundTransparency = 0.94})
    tween(ui.Ball, TweenInfo.new(0.10), {BackgroundTransparency = 0.82})
    tween(ui.SafeZone, TweenInfo.new(0.10), {BackgroundTransparency = 1})

    local duration = ({0.62,0.78,0.92,0.88})[state.phase]

    task.delay(duration, function()
        if not state.active then return end
        state.blackout = false

        shakeForPhase(0.32)
        flashScreen(Color3.fromRGB(225,235,255), 0.34, 0.03, 0.28)
        tween(ui.Root, TweenInfo.new(0.22), {BackgroundTransparency = 0.46})
        tween(ui.Arena, TweenInfo.new(0.22), {BackgroundTransparency = 0.36})
        tween(ui.Ball, TweenInfo.new(0.22), {BackgroundTransparency = 0})
        tween(ui.SafeZone, TweenInfo.new(0.22), {BackgroundTransparency = 0.94})
    end)
end

local function doSignalCorruption()
    if not state.active or state.ending then return end
    setWarning("CORRUPTED INPUT", 0.8, false)
    glitchBurst(1.8, 0.65)
    shakeForPhase(0.45)
    impactBlur(11)

    state.distortion = 1
    addForce(randomUnit2() * CONFIG.Phase[state.phase].ImpactForce * 0.48)
end

local EVENT_FUNCTIONS = {
    Impact = function() doImpact(1.00) end,
    HeavyImpact = function() doImpact(1.22, ">> HEAVY IMPACT <<") end,
    DoubleImpact = doDoubleImpact,
    Distortion = doDistortion,
    Surge = doPressureSurge,
    Blackout = doBlackout,
    Corruption = doSignalCorruption,
}

local function chooseEvent()
    local phase = state.phase
    local pool

    if phase == 1 then
        pool = {"Impact","Impact","HeavyImpact","Corruption"}
    elseif phase == 2 then
        pool = {"Impact","HeavyImpact","HeavyImpact","Surge","Corruption","Blackout"}
    elseif phase == 3 then
        pool = {"HeavyImpact","HeavyImpact","DoubleImpact","Surge","Distortion","Blackout","Corruption"}
    else

        pool = {
            "HeavyImpact","HeavyImpact","HeavyImpact",
            "Impact",
            "Surge","Surge",
            "Distortion",
            "Blackout",
            "Corruption",
            "DoubleImpact"
        }
    end

    return pool[math.random(1,#pool)]
end

local function scheduleNextEvent(now)
    local p = CONFIG.Phase[state.phase]
    state.nextEventAt = now + p.MinEventDelay + math.random() * (p.MaxEventDelay - p.MinEventDelay)
end

local function calculatePhase(progress)
    if progress < 0.25 then return 1 end
    if progress < 0.50 then return 2 end
    if progress < 0.75 then return 3 end
    return 4
end

local function enterPhase(newPhase)
    if newPhase == state.phase then return end
    state.phase = newPhase
    ui.PhaseText.Text = string.format("PHASE // %02d", newPhase)

    setWarning("PHASE " .. tostring(newPhase) .. " // ESCALATION", 0.9, true)

    shakeForPhase(0.55 + newPhase * 0.08)
    flashScreen(Color3.fromRGB(235,235,245), 0.52, 0.04, 0.42)
    glitchBurst(0.8 + newPhase * 0.18, 0.42)
end

local function lockMouse()
    state.oldMouseBehavior = UserInputService.MouseBehavior
    state.oldMouseIcon = UserInputService.MouseIconEnabled
    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function restoreMouse()
    UserInputService.MouseBehavior = state.oldMouseBehavior
    UserInputService.MouseIconEnabled = state.oldMouseIcon
end

local function connectInput()
    table.insert(state.connections, UserInputService.InputChanged:Connect(function(input)
        if not state.active or state.ending then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

        local delta = input.Delta
        local sign = state.inverted and -1 or 1
        local p = CONFIG.Phase[state.phase]

        local d = Vector2.new(delta.X, delta.Y)
        local distortionScale = 1

        if state.distortion > 0 then
            local wobble = Vector2.new(
                math.sin(os.clock()*17),
                math.cos(os.clock()*13)
            ) * state.distortion * 0.18
            d += d * wobble
            distortionScale = 1 - state.distortion * 0.10
        end

        state.ballVelocity += d
            * CONFIG.MouseSensitivity
            * p.InputMultiplier
            * distortionScale
            * sign
    end))
end

local function disconnectAll()
    for _, c in ipairs(state.connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(state.connections)
end

local function cleanup()
    state.active = false

    stopGameCameraShake()

    if ui and ui.IntroFade and ui.IntroFade.Parent then
        ui.IntroFade.BackgroundTransparency = 1
        ui.IntroFade.Visible = false
        ui.IntroFade.Active = false
    end

    disconnectAll()
    restoreMouse()

    for _, t in ipairs(state.tweens) do
        pcall(function() t:Cancel() end)
    end
    table.clear(state.tweens)

    if state.heartbeat then
        pcall(function()
            state.heartbeat:Stop()
            state.heartbeat:Destroy()
        end)
        state.heartbeat = nil
    end

    task.delay(0.2, function()
        safeDestroy(ui.Blur)
        safeDestroy(ui.Color)
    end)
end

local showSurviveEffect

local function surviveSequence()
    if state.ending then return end
    state.ending = true

    setWarning("SIGNAL STABILIZED", 1.3, true)
    runFinalCameraShake()
    flashScreen(Color3.fromRGB(235,245,255), 0.10, 0.06, 0.70)

    tween(ui.Blur, TweenInfo.new(0.7), {Size = 0})
    tween(ui.Root, TweenInfo.new(1.0), {BackgroundTransparency = 0.72})

    task.wait(1.15)

    ui.IntroFade.Visible = true
    ui.IntroFade.BackgroundTransparency = 1
    tween(ui.IntroFade, TweenInfo.new(0.85, Enum.EasingStyle.Quad), {BackgroundTransparency = 0})

    task.wait(0.9)
    cleanup()
    safeDestroy(ui.Gui)

    showSurviveEffect()

    if _G.Z367IntegratedResult then
        pcall(_G.Z367IntegratedResult, "win")
    end
end

local killEffectPlayed = false
local isPlayerDead = false

local function showKillEffect()
    if killEffectPlayed then
        return
    end

    killEffectPlayed = true
    isPlayerDead = true

    local playerGui = player:WaitForChild("PlayerGui")
    local oldKillGui = playerGui:FindFirstChild("KillEffect")
    if oldKillGui then
        oldKillGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KillEffect"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 10000
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    for _, child in ipairs(screenGui:GetChildren()) do
        child:Destroy()
    end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://112123002526111"
    sound.Volume = 4
    sound.Parent = workspace
    sound:Play()
    Debris:AddItem(sound, math.max(sound.TimeLength + 1, 3))

    local image = Instance.new("ImageLabel")
    image.Image = "rbxassetid://99207315574595"
    image.Size = UDim2.new(0, 10, 0, 10)
    image.Position = UDim2.new(0.5, 0, 0.5, 0)
    image.AnchorPoint = Vector2.new(0.5, 0.5)
    image.BackgroundTransparency = 1
    image.ScaleType = Enum.ScaleType.Fit
    image.SizeConstraint = Enum.SizeConstraint.RelativeXY
    image.ZIndex = 2
    image.Parent = screenGui

    TweenService:Create(
        image,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(1.5, 0, 1.5, 0)}
    ):Play()

    task.wait(0.3)

    local time = 0
    local duration = 0.8

    while time < duration and image.Parent do
        local dt = task.wait()
        time += dt

        local shakeX = math.sin(time * 30) * 0.002
        local shakeY = math.cos(time * 28) * 0.002

        image.Position = UDim2.new(0.5 + shakeX, 0, 0.5 + shakeY, 0)
    end

    local signalWorked = pcall(function()
        if type(replicatesignal) ~= "function" then
            error("replicatesignal unavailable")
        end
        replicatesignal(game.Players.LocalPlayer.Kill)
    end)

    if not signalWorked then
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            pcall(function()
                humanoid.Health = 0
            end)
        end
    end

    TweenService:Create(
        image,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {ImageTransparency = 1}
    ):Play()

    task.wait(0.2)

    if image.Parent then
        image:Destroy()
    end

    task.wait(0.5)

    if screenGui.Parent then
        screenGui:Destroy()
    end
end

showSurviveEffect = function()
    if workspace:FindFirstChild("Z-367") then
        workspace["Z-367"]:Destroy()
    end
end

local function deathSequence()
    if state.ending then return end
    state.ending = true
    state.dead = true

    if ui and ui.Warning then
        ui.Warning.Text = "SIGNAL LOST"
        ui.Warning.TextColor3 = Color3.fromRGB(255,45,45)
        ui.Warning.TextTransparency = 0
    end

    runFinalCameraShake()
    requestFallbackShake(0.035,0.5)
    flashScreen(Color3.fromRGB(255,20,20), 0.08, 0.025, 0.30)
    glitchBurst(2.4, 0.42)
    impactBlur(28)

    task.wait(0.08)

    showKillEffect()

    cleanup()
    safeDestroy(ui and ui.Gui)

    if _G.Z367IntegratedResult then
        pcall(_G.Z367IntegratedResult, "lose")
    end
end

local function updatePressureVisual(percent, inCenter)
    percent = clamp01(percent)
    ui.PressureFill.Size = UDim2.new(percent,0,1,0)

    local r, g, b
    if percent > 0.55 then
        local t = (percent - 0.55) / 0.45
        r = 225
        g = math.floor(145 + 80*t)
        b = math.floor(110 + 110*t)
    else
        local t = percent / 0.55
        r = 235
        g = math.floor(45 + 100*t)
        b = math.floor(50 + 60*t)
    end

    ui.PressureFill.BackgroundColor3 = Color3.fromRGB(r,g,b)

    if percent < 0.38 then
        local pulse = (math.sin(os.clock()*8)+1)/2
        ui.RedPulse.BackgroundTransparency = 0.91 + pulse*0.07
        ui.PressureLabel.Text = "SIGNAL PRESSURE // CRITICAL"
        ui.PressureLabel.TextColor3 = Color3.fromRGB(255,85,85)
    elseif percent < 0.62 then
        ui.RedPulse.BackgroundTransparency = 1
        ui.PressureLabel.Text = "SIGNAL PRESSURE // UNSTABLE"
        ui.PressureLabel.TextColor3 = Color3.fromRGB(220,165,120)
    else
        ui.RedPulse.BackgroundTransparency = 1
        ui.PressureLabel.Text = "SIGNAL PRESSURE"
        ui.PressureLabel.TextColor3 = Color3.fromRGB(170,170,175)
    end

    ui.SafeStroke.Color = inCenter
        and Color3.fromRGB(215,225,220)
        or Color3.fromRGB(145,80,80)
end

local function updateTimer()
    local seconds = math.max(0, math.ceil(state.remaining))
    local mins = math.floor(seconds/60)
    local secs = seconds%60
    ui.Timer.Text = string.format("%02d:%02d", mins, secs)
end

local Z367MusicStartedAt = nil

local function startGame()
    if state.active or state.ending then return end

    if not ui or not ui.Gui or not ui.Gui.Parent then
        ui = buildUI()
    end

    ui.Gui.Enabled = true
    if ui.Blur then ui.Blur.Enabled = true end
    if ui.Color then ui.Color.Enabled = true end

    killEffectPlayed = false
    isPlayerDead = false

    state.active = true
    state.dead = false
    state.ending = false
    state.pressure = CONFIG.MaxPressure
    state.remaining = CONFIG.Duration
    state.progress = 0
    state.phase = 1
    state.ballPos = Vector2.new(0.5,0.5)
    state.ballVelocity = Vector2.zero
    state.inverted = false
    state.blackout = false
    state.distortion = 0

    lockMouse()
    connectInput()

    state.music = Z367_PRELOADED_MUSIC

    runGameFadeIn()

    local gameStartedAt = Z367MusicStartedAt or os.clock()
    local warmupBurstPlayed = false

    scheduleNextEvent(gameStartedAt + 2.0)

    local last = gameStartedAt

    table.insert(state.connections, RunService.RenderStepped:Connect(function(dt)
        if not state.active or state.ending then return end

        local now = os.clock()
        dt = math.min(dt, 1/20)

        camera = workspace.CurrentCamera

        if fallbackShake.endAt > now and camera then
            local p = fallbackShake.power
            local rx = math.rad((math.random()-0.5) * p * 90)
            local ry = math.rad((math.random()-0.5) * p * 90)
            local rz = math.rad((math.random()-0.5) * p * 50)
            local tx = (math.random()-0.5) * p
            local ty = (math.random()-0.5) * p
            camera.CFrame = camera.CFrame * CFrame.new(tx,ty,0) * CFrame.Angles(rx,ry,rz)
        elseif fallbackShake.endAt <= now then
            fallbackShake.power = 0
        end

        state.remaining -= dt
        state.progress = clamp01(1 - state.remaining / CONFIG.Duration)

        local elapsed = now - gameStartedAt
        local warmup = elapsed < 6

        if not warmupBurstPlayed and elapsed >= 6 then
            warmupBurstPlayed = true

            runCameraShake(
                34,
                220,
                0.05,
                0.62,
                2.2,
                0.55
            )

            flashScreen(Color3.fromRGB(245,245,255), 0.34, 0.025, 0.32)
            glitchBurst(0.75, 0.20)
        end

        local phase = calculatePhase(state.progress)
        if phase ~= state.phase then
            enterPhase(phase)
            scheduleNextEvent(now + 0.35)
        end

        local phaseCfg = CONFIG.Phase[state.phase]

        local driftStrength
        local randomStrength

        if warmup then
            driftStrength = 0.000035 + state.phase * 0.000008
            randomStrength = 0.000035
        else
            driftStrength = 0.000125 + state.phase * 0.000034
            randomStrength = 0.000110
        end

        state.ballVelocity += Vector2.new(
            math.sin(now*2.7 + state.phase) * driftStrength,
            math.cos(now*2.2 + state.phase*0.7) * driftStrength
        )

        state.ballVelocity += Vector2.new(
            (math.random()-0.5) * randomStrength,
            (math.random()-0.5) * randomStrength
        )

        local center = Vector2.new(0.5,0.5)
        local towardCenter = center - state.ballPos
        state.ballVelocity += towardCenter * CONFIG.Spring

        state.ballVelocity *= math.pow(CONFIG.Friction, dt*60)

        local maxSpeed = CONFIG.MaxSpeed

        if warmup then
            maxSpeed *= 0.58
        else

            maxSpeed *= 0.92
        end

        if state.phase == 4 then

            maxSpeed *= 0.94
        end

        if state.ballVelocity.Magnitude > maxSpeed then
            state.ballVelocity = state.ballVelocity.Unit * maxSpeed
        end

        state.ballPos += state.ballVelocity

        local offset = state.ballPos - center
        local dist = offset.Magnitude
        if dist > CONFIG.OuterLimit then
            state.ballPos = center + offset.Unit * CONFIG.OuterLimit
            state.ballVelocity = -state.ballVelocity * 0.46

            shakeForPhase(0.22)
            pulseDanger(0.35)
            glitchBurst(0.38,0.10)
        end

        ui.Ball.Position = UDim2.fromScale(state.ballPos.X,state.ballPos.Y)
        ui.BallGlow.Position = ui.Ball.Position

        local safeDistance = (state.ballPos-center).Magnitude
        local inCenter = safeDistance <= CONFIG.CenterRadius

        if inCenter then
            state.pressure = math.min(
                CONFIG.MaxPressure,
                state.pressure + CONFIG.RecoveryRate * dt
            )
        else
            local outside = math.max(0, safeDistance-CONFIG.CenterRadius)
            local distancePenalty = outside * CONFIG.DistanceDrain

            local drain = (
                CONFIG.BaseDrainRate + distancePenalty
            ) * phaseCfg.DrainMultiplier

            if state.phase == 4 then
                drain *= 0.92
            end

            state.pressure -= drain * dt
        end

        state.pressure = math.clamp(state.pressure,0,CONFIG.MaxPressure)
        updatePressureVisual(state.pressure/CONFIG.MaxPressure,inCenter)
        updateTimer()

        state.distortion = math.max(0,state.distortion-dt*0.65)

        if not warmup and now >= state.nextEventAt then
            local eventName = chooseEvent()
            local fn = EVENT_FUNCTIONS[eventName]
            if fn then
                task.spawn(fn)
            end
            scheduleNextEvent(now)
        end

        if state.pressure <= 0 then
            task.spawn(deathSequence)
            return
        end

        if state.remaining <= 0 then
            task.spawn(surviveSequence)
            return
        end

        last = now
    end))
end

table.insert(state.connections, player.CharacterRemoving:Connect(function()
    if state.active then
        cleanup()
        safeDestroy(ui.Gui)
    end
end))

_G.Z367StartSelectedMinigame = startGame

local Z367LockedPlayer = nil
local Z367EncounterStarted = false

local function isPlayerAlive(player)
    local char = player and player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if hum and hum.Health > 0 and root then
        return true, root
    end

    return false, nil
end

local function getNearestAlivePlayer(position)
    local nearest = nil
    local nearestRoot = nil
    local shortest = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        local alive, root = isPlayerAlive(plr)

        if alive and root then
            local distance = (root.Position - position).Magnitude

            if distance < shortest then
                shortest = distance
                nearest = plr
                nearestRoot = root
            end
        end
    end

    return nearest, nearestRoot, shortest
end

local function isThisPlayerLocked()
    return Z367LockedPlayer == player
end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ENTITY_SPEED = 70
local ACQUIRE_RANGE = 70
local GAME_TRIGGER_DISTANCE = 3
local HOLD_DISTANCE = 3
local TARGET_LOCKED = false
local SELECTED_PLAYER = nil
local SELECTED_USER_ID = nil
local entityModel = nil
local chaseConnection = nil
local encounterHoldConnection = nil
local selectedPlayerDeathConnection = nil
local departureConnection = nil
local lockedDepartureDirection = nil
local soundManagerConnection = nil
local soundSystemActive = false
local isShakingCamera = false
local chaseStartTime = 0
local BANG_VOLUME = 3.25
local DEPART_SPEED = 90
local DEPART_DISTANCE = 135
local bangSounds = {}
local attackSound = nil
local pandemoniumEyesBeam = nil
local resolved = false

local encounterSerial = 0

local ambientCameraShaker = nil
local CachedCameraShaker = nil

local removeZ367
local releaseBackToSpawnerPath

local function aliveCharacter(plr)
    if not plr then return nil, nil, nil end
    local char = plr.Character
    if not char then return nil,nil,nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not root then return nil,nil,nil end
    return char, hum, root
end

local function nearestAlivePlayer(origin)
    local best, bestRoot, bestDistance
    for _, plr in ipairs(Players:GetPlayers()) do
        local _, hum, root = aliveCharacter(plr)
        if hum and root then
            local d = (root.Position-origin).Magnitude
            if (not bestDistance) or d < bestDistance then
                best, bestRoot, bestDistance = plr, root, d
            end
        end
    end
    return best, bestRoot, bestDistance
end

local function setEyes(enabled)
    if pandemoniumEyesBeam and pandemoniumEyesBeam:IsA("Beam") then
        pandemoniumEyesBeam.Enabled = enabled
    end
end

local function findEntityAudio()
    table.clear(bangSounds)
    local zModel = entityModel or Workspace:FindFirstChild("Z-367")
    if not zModel then return false end
    local pandemoniumPart = zModel:FindFirstChild("Pandemonium")
    if not pandemoniumPart then return false end

    pandemoniumEyesBeam = pandemoniumPart:FindFirstChild("PandemoniumEyes")
    setEyes(false)
    attackSound = pandemoniumPart:FindFirstChild("Attack")

    for i=1,4 do
        local snd = pandemoniumPart:FindFirstChild("Bang"..i)
        if snd and snd:IsA("Sound") then
            snd.Volume = BANG_VOLUME
            table.insert(bangSounds,snd)
        end
    end

    local preloadList = {}
    if attackSound and attackSound:IsA("Sound") then
        table.insert(preloadList, attackSound)
    end
    for _, snd in ipairs(bangSounds) do
        table.insert(preloadList, snd)
    end

    if #preloadList > 0 then
        pcall(function()
            game:GetService("ContentProvider"):PreloadAsync(preloadList)
        end)
    end

    return true
end

local function playRandomBang()
    if #bangSounds == 0 then return end
    local snd = bangSounds[math.random(1,#bangSounds)]
    if snd then
        pcall(function()
            snd.Volume = BANG_VOLUME
            snd.TimePosition = 0
            snd:Play()
        end)
    end
end

_G.Z367PlayModelBang = playRandomBang

local function getCachedCameraShaker()
    if CachedCameraShaker then
        return CachedCameraShaker
    end

    local module = ReplicatedStorage:FindFirstChild("CameraShaker")
    if not module then
        return nil
    end

    local ok, result = pcall(require, module)
    if ok then
        CachedCameraShaker = result
        return result
    end

    return nil
end

local function stopAmbientMicroShake()
    if ambientCameraShaker then
        pcall(function()
            ambientCameraShaker:Stop()
        end)
        ambientCameraShaker = nil
    end
end

local function startAmbientMicroShake()
    stopAmbientMicroShake()

    local CameraShaker = getCachedCameraShaker()
    if not CameraShaker then
        return
    end

    pcall(function()
        ambientCameraShaker = CameraShaker.new(
            Enum.RenderPriority.Camera.Value,
            function(cf)
                if not soundSystemActive then
                    return
                end

                local cam = Workspace.CurrentCamera
                if cam then
                    cam.CFrame = cam.CFrame * cf
                end
            end
        )

        ambientCameraShaker:Start()

        ambientCameraShaker:ShakeOnce(
            10,
            10,
            0.1,
            CONFIG.Duration,
            2,
            0.5
        )
    end)
end

local function spectatorCameraShake()
    local CameraShaker = getCachedCameraShaker()
    if not CameraShaker then return end

    pcall(function()
        local shaker = CameraShaker.new(
            Enum.RenderPriority.Camera.Value,
            function(cf)
                local cam = Workspace.CurrentCamera
                if cam then
                    cam.CFrame = cam.CFrame * cf
                end
            end
        )

        shaker:Start()
        shaker:ShakeOnce(12,80,0.08,0.32,1.1,0.25)
        task.delay(.7,function()
            pcall(function() shaker:Stop() end)
        end)
    end)
end

local function spectatorClimaxShake()
    local CameraShaker = getCachedCameraShaker()
    if not CameraShaker then return end

    pcall(function()
        local shaker = CameraShaker.new(
            Enum.RenderPriority.Camera.Value,
            function(cf)
                local cam = Workspace.CurrentCamera
                if cam then
                    cam.CFrame = cam.CFrame * cf
                end
            end
        )

        shaker:Start()
        shaker:ShakeOnce(
            34,
            220,
            0.05,
            0.62,
            2.2,
            0.55
        )

        task.delay(1.0,function()
            pcall(function() shaker:Stop() end)
        end)
    end)
end

local function startSoundManager()
    if soundManagerConnection then
        soundManagerConnection:Disconnect()
    end

    local bangTimer = 0
    local nextBangInterval = math.random(2,6)
    local climaxStarted = false

    soundManagerConnection = RunService.Heartbeat:Connect(function(dt)
        if not soundSystemActive then return end

        local elapsed = os.clock() - chaseStartTime

        if not climaxStarted and elapsed >= 6 then
            climaxStarted = true
            bangTimer = 0
            nextBangInterval = math.random(2,6)

            playRandomBang()
        end

        if climaxStarted and elapsed < (CONFIG.Duration + 6) then
            bangTimer += dt

            if bangTimer >= nextBangInterval then
                playRandomBang()
                spectatorCameraShake()

                bangTimer = 0
                nextBangInterval = math.random(2,6)
            end
        end
    end)
end

local function startAmbientForEveryone()
    if soundSystemActive then return end

    soundSystemActive = true
    chaseStartTime = os.clock()
    Z367MusicStartedAt = chaseStartTime

    encounterSerial += 1

    if Z367_PRELOADED_MUSIC and Z367_PRELOADED_MUSIC.Parent then
        pcall(function()
            Z367_PRELOADED_MUSIC.Volume = Z367_MUSIC_VOLUME
            Z367_PRELOADED_MUSIC.TimePosition = 0
            Z367_PRELOADED_MUSIC:Play()
        end)
    end

    startAmbientMicroShake()
    startSoundManager()
end

local function stopAmbient()
    soundSystemActive=false
    isShakingCamera=false

    encounterSerial += 1

    stopAmbientMicroShake()

    if soundManagerConnection then
        soundManagerConnection:Disconnect()
        soundManagerConnection=nil
    end

    if attackSound then
        pcall(function() attackSound:Stop() end)
        attackSound.Volume=1
    end

    for _,snd in ipairs(bangSounds) do
        pcall(function() snd:Stop() end)
    end

    if Z367_PRELOADED_MUSIC and Z367_PRELOADED_MUSIC.Parent then
        pcall(function()
            Z367_PRELOADED_MUSIC:Stop()
            Z367_PRELOADED_MUSIC.TimePosition = 0
            Z367_PRELOADED_MUSIC.Volume = Z367_MUSIC_VOLUME
        end)
    end

    Z367MusicStartedAt = nil
end

local function stopZ367MusicOnly()
    if Z367_PRELOADED_MUSIC and Z367_PRELOADED_MUSIC.Parent then
        pcall(function()
            Z367_PRELOADED_MUSIC:Stop()
            Z367_PRELOADED_MUSIC.TimePosition = 0
            Z367_PRELOADED_MUSIC.Volume = Z367_MUSIC_VOLUME
        end)
    end

    Z367MusicStartedAt = nil
end

local function disconnectSelectedPlayerDeathWatcher()
    if selectedPlayerDeathConnection then
        selectedPlayerDeathConnection:Disconnect()
        selectedPlayerDeathConnection = nil
    end
end

local function watchSelectedPlayerDeath(plr)
    disconnectSelectedPlayerDeathWatcher()

    if not plr then
        return
    end

    local character = plr.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    selectedPlayerDeathConnection = humanoid.Died:Connect(function()
        if SELECTED_PLAYER == plr or Z367LockedPlayer == plr then

            stopZ367MusicOnly()

            if releaseBackToSpawnerPath then
                releaseBackToSpawnerPath()
            end
        end
    end)
end

local function disableCustomChase()
    if chaseConnection then
        chaseConnection:Disconnect()
        chaseConnection=nil
    end
end

local function disableEncounterHold()
    if encounterHoldConnection then
        encounterHoldConnection:Disconnect()
        encounterHoldConnection=nil
    end
end

local function startEncounterHold()
    disableEncounterHold()

    encounterHoldConnection = RunService.Heartbeat:Connect(function()
        if not TARGET_LOCKED or resolved then return end
        if not entityModel or not entityModel.Parent or not entityModel.PrimaryPart then return end
        if not SELECTED_PLAYER then return end

        local char = SELECTED_PLAYER.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then

            return
        end

        local frontPos = root.Position + root.CFrame.LookVector * HOLD_DISTANCE
        entityModel:SetPrimaryPartCFrame(CFrame.lookAt(frontPos, root.Position))

        lockedDepartureDirection = root.CFrame.LookVector
    end)
end

local function disableDeparture()
    if departureConnection then
        departureConnection:Disconnect()
        departureConnection=nil
    end
end

local function startDeparture(direction)
    disableDeparture()

    if not entityModel or not entityModel.Parent or not entityModel.PrimaryPart then
        return
    end

    local dir = direction
    if not dir or dir.Magnitude < 0.001 then
        dir = entityModel.PrimaryPart.CFrame.LookVector
    else
        dir = dir.Unit
    end

    local travelled = 0

    departureConnection = RunService.Heartbeat:Connect(function(dt)
        if not entityModel or not entityModel.Parent or not entityModel.PrimaryPart then
            disableDeparture()
            return
        end

        local step = DEPART_SPEED * math.min(dt, 1/20)
        travelled += step

        local pos = entityModel.PrimaryPart.Position + dir * step
        entityModel:SetPrimaryPartCFrame(CFrame.lookAt(pos, pos + dir))

        if travelled >= DEPART_DISTANCE then
            disableDeparture()
            setEyes(false)
        end
    end)
end

removeZ367 = function()
    disableCustomChase()
    disableEncounterHold()
    disconnectSelectedPlayerDeathWatcher()
    disableDeparture()
    stopAmbient()
    setEyes(false)
    if entityModel and entityModel.Parent then
        entityModel:Destroy()
    else
        local z=Workspace:FindFirstChild("Z-367")
        if z then z:Destroy() end
    end
end

releaseBackToSpawnerPath = function()

    TARGET_LOCKED = true
    resolved = true

    disableCustomChase()
    disableEncounterHold()
    disableDeparture()
    disconnectSelectedPlayerDeathWatcher()
    stopAmbient()
    setEyes(false)

    SELECTED_PLAYER = nil
    SELECTED_USER_ID = nil
    Z367LockedPlayer = nil
    lockedDepartureDirection = nil

end

_G.Z367IntegratedResult=function(result)
    if resolved then return end
    resolved=true
    if result=="win" then
        removeZ367()
    else
        releaseBackToSpawnerPath()
    end
end

local function beginSelectedPlayerEncounter()
    if not SELECTED_PLAYER or resolved then return end

    TARGET_LOCKED=true
    Z367LockedPlayer = SELECTED_PLAYER

    setEyes(true)

    startAmbientForEveryone()

    if not Z367EncounterStarted then
        local starter = _G.Z367StartSelectedMinigame
        if type(starter) == "function" then
            Z367EncounterStarted = true
            task.spawn(function()
                local ok = pcall(starter)
                if not ok then
                    Z367EncounterStarted = false

                    if ui and ui.IntroFade and ui.IntroFade.Parent then
                        ui.IntroFade.BackgroundTransparency = 1
                        ui.IntroFade.Visible = false
                        ui.IntroFade.Active = false
                    end
                end
            end)
        end
    end
end

local function playAttackOnTargetLock()
    if not attackSound or not attackSound:IsA("Sound") then
        return
    end

    pcall(function()
        attackSound:Stop()
        attackSound.TimePosition = 0
        attackSound.Volume = 1
        attackSound:Play()
    end)
end

local function fadeAttackForEncounter()
    if not attackSound or not attackSound:IsA("Sound") then
        return
    end

    pcall(function()
        TweenService:Create(
            attackSound,
            TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Volume = 0.1}
        ):Play()
    end)
end

local function startNearestPlayerChase()
    if not entityModel or not entityModel.PrimaryPart then return end
    disableCustomChase()

    chaseConnection=RunService.Heartbeat:Connect(function(dt)
        if resolved or not entityModel or not entityModel.Parent or not entityModel.PrimaryPart then return end

        if not SELECTED_PLAYER then
            local plr,root,d=getNearestAlivePlayer(entityModel.PrimaryPart.Position)

            if plr and d and d <= ACQUIRE_RANGE then
                SELECTED_PLAYER=plr
                SELECTED_USER_ID=plr.UserId
                Z367LockedPlayer=plr

                watchSelectedPlayerDeath(plr)

                playAttackOnTargetLock()
            else
                setEyes(false)
                return
            end
        end

        local _,hum,targetRoot=aliveCharacter(SELECTED_PLAYER)
        if not hum or not targetRoot then

            releaseBackToSpawnerPath()
            return
        end

        local pos=entityModel.PrimaryPart.Position
        local target=targetRoot.Position
        local delta=target-pos
        local distance=delta.Magnitude

        if distance <= GAME_TRIGGER_DISTANCE then

            lockedDepartureDirection = targetRoot.CFrame.LookVector

            disableCustomChase()

            fadeAttackForEncounter()
            beginSelectedPlayerEncounter()
            startEncounterHold()
            return
        end

        setEyes(true)
        local dir=delta.Unit
        local travel=math.min(ENTITY_SPEED*dt, math.max(0,distance-GAME_TRIGGER_DISTANCE))
        local newPos=pos+dir*travel
        entityModel:SetPrimaryPartCFrame(CFrame.new(newPos,target))
    end)
end

local entity = spawner.Create({
	Entity = {
		Name = "Z-367",
		Asset = "100118518576966",
HeightOffset = -3},Lights = {Flicker = {Enabled = true,Duration = 1.5},Shatter = false,Repair = false},
Earthquake = {Enabled = false},CameraShake = {Enabled = false,Range = 20,Values = {1.5, 20, 0.1, 1}},
Movement = {Speed = 50,Delay = 2,Reversed = false},Rebounding = {Enabled = false,Type = "Blitz",
Min = 1,Max = math.random(1, 2),Delay = math.random(10, 30) / 10},Damage = {Enabled = false,Range = 20,Amount = 0},
Crucifixion = {Enabled = true,Range = 70,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你被 Z-367 击败了...", "你该多练练准星!", "请仔细辨别环境中的声音", "他随时都可能出现"},Cause = ""}
})

entity:SetCallback("OnSpawned",function()
    disconnectSelectedPlayerDeathWatcher()
    stopAmbientMicroShake()
    encounterSerial += 1

    resolved = false
    TARGET_LOCKED = false
    Z367EncounterStarted = false
    SELECTED_PLAYER = nil
    SELECTED_USER_ID = nil
    Z367LockedPlayer = nil
    lockedDepartureDirection = nil
    Z367MusicStartedAt = nil

    if Z367_PRELOADED_MUSIC and Z367_PRELOADED_MUSIC.Parent then
        pcall(function()
            Z367_PRELOADED_MUSIC:Stop()
            Z367_PRELOADED_MUSIC.TimePosition = 0
            Z367_PRELOADED_MUSIC.Volume = Z367_MUSIC_VOLUME
        end)
    end

    entityModel=entity.Model
    if entityModel and not entityModel.PrimaryPart then
        entityModel.PrimaryPart=entityModel:FindFirstChild("Main")
            or entityModel:FindFirstChildWhichIsA("BasePart")
    end
    findEntityAudio()
    startNearestPlayerChase()
end)

entity:SetCallback("OnDespawning",function()
    disableCustomChase()
    disableEncounterHold()
    disconnectSelectedPlayerDeathWatcher()
    disableDeparture()

    stopAmbient()
    setEyes(false)
end)

entity:SetCallback("OnDamagePlayer",function(newHealth)
    if newHealth==0 then
        releaseBackToSpawnerPath()
    end
end)

entity:SetCallback("OnRebounding",function(startOfRebound)
    if not entityModel then return end
    local main=entityModel:FindFirstChild("Main")
    if not main then return end
    local attachment=main:FindFirstChild("Attachment")
    local attachmentSwitch=main:FindFirstChild("AttachmentSwitch")
    if not attachment or not attachmentSwitch then return end

    local footsteps=main:FindFirstChild("Footsteps")
    local playSound=main:FindFirstChild("PlaySound")
    local switch=main:FindFirstChild("Switch")
    local switchBack=main:FindFirstChild("SwitchBack")

    for _,c in ipairs(attachment:GetChildren()) do
        pcall(function() c.Enabled=not startOfRebound end)
    end
    for _,c in ipairs(attachmentSwitch:GetChildren()) do
        pcall(function() c.Enabled=startOfRebound end)
    end

    if startOfRebound then
        if footsteps then footsteps.PlaybackSpeed=.35 end
        if playSound then playSound.PlaybackSpeed=.25 end
        if switch then switch:Play() end
    else
        if footsteps then footsteps.PlaybackSpeed=.25 end
        if playSound then playSound.PlaybackSpeed=.16 end
        if switchBack then switchBack:Play() end
    end
end)

entity:Run()
end

function entityBehaviors.A60Ps1()
local entity = spawner.Create({
	Entity = {
		Name = "A60",
		Asset = "117633452506607",
		HeightOffset = 0
	},
	Lights = {
		Flicker = {
			Enabled = false,
			Duration = 10
		},
		Shatter = false,
		Repair = false
	},
	Earthquake = {
		Enabled = false
	},
	CameraShake = {
		Enabled = true,
		Range = 200,
		Values = {1.5, 20, 0.1, 1}
	},
	Movement = {
		Speed = 350,
		Delay = 3,
		Reversed = false
	},
	Rebounding = {
		Enabled = true,
		Type = "ambush",
		Min = 5,
		Max = 5,
		Delay = math.random(10, 30) / 10
	},
	Damage = {
		Enabled = true,
		Range = 100,
		Amount = 125
	},
	Crucifixion = {
		Enabled = true,
		Range = 100,
		Resist = false,
		Break = true
	},
	Death = {
		Type = "Guiding",
		Hints = {"你死于A60", "...", "你会从Ambush那学会点什么", "他随时可能出现!"},
		Cause = ""
	}
})
entity:SetCallback("OnRebounding", function(startOfRebound)
	-- Variables for the entity
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

	-- Toggle particle emitters and lights within the entityModel
	-- To switch between green & red state
	for _, c in attachment:GetChildren() do
		c.Enabled = (not startOfRebound)
	end
	for _, c in AttachmentSwitch:GetChildren() do
		c.Enabled = startOfRebound
	end

	-- Play sounds
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

local face = workspace:WaitForChild("A60"):WaitForChild("RushNew"):WaitForChild("Main"):WaitForChild("Face")
if face and face:IsA("ParticleEmitter") then
    while true do
        face.Texture = "rbxassetid://12145534911"
        wait(0.1)
        face.Texture = "rbxassetid://12145554242"
        wait(0.1)
        face.Texture = "rbxassetid://12145599498"
        wait(0.1)
        face.Texture = "rbxassetid://12145599275"
        wait(0.1)
        face.Texture = "rbxassetid://12155335619"
        wait(0.1)
        face.Texture = "rbxassetid://12145598814"
        wait(0.1)
        face.Texture = "rbxassetid://12146135062"
        wait(0.1)
        face.Texture = "rbxassetid://11378285585"
        wait(0.1)
    end
else
end
end

function entityBehaviors.A60PS2()
function DEATHMESSAGE(messages, deathCause)
    local player = game.Players.LocalPlayer
    local character = player.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

    if not humanoid or humanoid.Health > 100 then
        return
    end

    local gameStats = game:GetService("ReplicatedStorage"):FindFirstChild("GameStats")
    local playerStats = gameStats and gameStats:FindFirstChild("Player_" .. player.Name)
    local total = playerStats and playerStats:FindFirstChild("Total")
    local deathCauseValue = total and total:FindFirstChild("DeathCause")

    if deathCauseValue then
        deathCauseValue.Value = deathCause
    end
end

local originalDEATHMESSAGE = DEATHMESSAGE

local jumpscareActive = false
local entityTimerActive = false
local attackDetectionActive = true
local loopActive = false

DEATHMESSAGE = function(messages, deathCause)
    originalDEATHMESSAGE(messages, deathCause)
    
    if deathCause == "A-60" and not jumpscareActive then
        jumpscareActive = true

        spawn(function()
            local jumpSound = Instance.new("Sound")
            jumpSound.Parent = workspace
            jumpSound.Volume = 10
            jumpSound.SoundId = "rbxassetid://103879029437685"
            jumpSound:Play()

            wait(jumpSound.TimeLength)
            jumpSound:Destroy()
        end)
        
        local function PlayA60Jumpscare()
            local JumpscareGUI = Instance.new("ScreenGui")
            JumpscareGUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            JumpscareGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            
            local JumpscareEnd = Instance.new("ImageLabel")
            JumpscareEnd.Name = "JumpscareEnd"
            JumpscareEnd.Parent = JumpscareGUI
            JumpscareEnd.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            JumpscareEnd.BackgroundTransparency = 1
            JumpscareEnd.Position = UDim2.new(0.468, 0, 0.455, 0)
            JumpscareEnd.Size = UDim2.new(0.064, 0, 0.088, 0)
            JumpscareEnd.Image = "rbxassetid://0"
            JumpscareEnd.ImageColor3 = Color3.fromRGB(255, 0, 4)
            JumpscareEnd.ZIndex = 10
            
            local FullScreen = Instance.new("ImageLabel")
            FullScreen.Name = "Full"
            FullScreen.Parent = JumpscareGUI
            FullScreen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            FullScreen.BackgroundTransparency = 1
            FullScreen.Position = UDim2.new(-0.061, 0, -0.224, 0)
            FullScreen.Size = UDim2.new(1.122, 0, 1.447, 0)
            FullScreen.Image = "rbxassetid://11151804223"
            FullScreen.ImageTransparency = 1
            FullScreen.ZIndex = 5
            
            local A60 = workspace:FindFirstChild("A-60")
            if not A60 then
                JumpscareGUI:Destroy()
                return
            end
            
            local RushModel = A60:FindFirstChild("RushNew")
            if not RushModel then
                JumpscareGUI:Destroy()
                return
            end
            
            local Player = game.Players.LocalPlayer
            local Character = Player.Character
            if not Character then
                JumpscareGUI:Destroy()
                return
            end
            
            local Camera = workspace.CurrentCamera
            
            local CameraShaker
            local success, shakerModule = pcall(function()
                return require(game:GetService("ReplicatedStorage"):FindFirstChild("CameraShaker") or 
                       game:GetService("ReplicatedStorage"):WaitForChild("CameraShaker"))
            end)
            
            if success and shakerModule then
                CameraShaker = shakerModule.new(Enum.RenderPriority.Camera.Value, function(cameraShake)
                    Camera.CFrame = Camera.CFrame * cameraShake
                end)
                CameraShaker:Start()
            end
            
            local A60Clone = RushModel:Clone()
            A60Clone.Parent = Camera
            A60Clone.Name = "A-60_SCARE"
            
            for _, descendant in pairs(A60Clone:GetDescendants()) do
                if descendant:IsA("Sound") then
                    descendant:Destroy()
                end
            end
            
            local faceImages = A60Clone:FindFirstChild("IMAGEIDS")
            if faceImages then
                task.spawn(function()
                    while A60Clone.Parent do
                        local images = faceImages:GetChildren()
                        if #images > 0 then
                            local randomImage = images[math.random(1, #images)]
                            local mainFace = A60Clone:FindFirstChild("Main")
                            if mainFace and mainFace:FindFirstChild("Face") then
                                mainFace.Face.Texture = randomImage.Image
                            end
                        end
                        task.wait(math.random(0, 20) / 1000)
                    end
                end)
            end
            
            if CameraShaker then
                CameraShaker:ShakeOnce(25, 25, 0, 4, 90, 60)
            end
            
            local colorEffect = Instance.new("ColorCorrectionEffect")
            colorEffect.Parent = game:GetService("Lighting")
            
            game:GetService("TweenService"):Create(colorEffect, TweenInfo.new(0.5), {
                Brightness = 0.2,
                Contrast = 0.2,
                Saturation = -0.2,
                TintColor = Color3.fromRGB(255, 0, 4)
            }):Play()
            
            local targetOffset = Vector3.new(0, -1.2, -5)
            local lerpSpeed = 0.8
            
            task.spawn(function()
                local startTime = tick()
                while tick() - startTime < 0.5 and A60Clone.Parent do
                    local alpha = (tick() - startTime) / 0.5
                    A60Clone.CFrame = A60Clone.CFrame:Lerp(Camera.CFrame * CFrame.new(targetOffset), lerpSpeed)
                    task.wait()
                end
                
                local mainFace = A60Clone:FindFirstChild("Main")
                if mainFace and mainFace:FindFirstChild("Face") then
                    JumpscareEnd.Image = mainFace.Face.Texture
                end
                
                game:GetService("TweenService"):Create(JumpscareEnd, TweenInfo.new(0.5), {
                    Size = FullScreen.Size,
                    Position = FullScreen.Position,
                    Rotation = math.random(-20, 20)
                }):Play()
                
                game:GetService("TweenService"):Create(colorEffect, TweenInfo.new(10), {
                    Brightness = 0,
                    Contrast = 0,
                    Saturation = 0,
                    TintColor = Color3.fromRGB(255, 255, 255)
                }):Play()
                
                game:GetService("TweenService"):Create(A60Clone, TweenInfo.new(1), {
                    CFrame = Camera.CFrame * CFrame.new(Vector3.new(0, -1.2, 45))
                }):Play()
                
                task.wait(0.5)
                
                game:GetService("TweenService"):Create(JumpscareEnd, TweenInfo.new(0.5), {
                    ImageTransparency = 1
                }):Play()
                
                task.wait(0.5)
                
                A60Clone:Destroy()
                task.wait(2)
                colorEffect:Destroy()
                task.wait(1)
                JumpscareGUI:Destroy()
                if CameraShaker then
                    pcall(function()
                        CameraShaker:Stop()
                    end)
                end
                jumpscareActive = false
            end)
        end
        
        PlayA60Jumpscare()
    end
end

local models = game:GetObjects("rbxassetid://117633452506607")
local figureModel = models[1]
figureModel.Parent = workspace
figureModel.Name = "A-60"

local room50 = workspace.CurrentRooms["50"]
local startModel = room50:FindFirstChild("Door", true)

if not startModel then
    return
end

local startPart = startModel:FindFirstChild("Hidden")
if not startPart then
    return
end

local figureNodesFolder = workspace.CurrentRooms["50"].FigureSetup.FigureNodes
local allWaypoints = {}

for _, waypoint in pairs(figureNodesFolder:GetChildren()) do
    if waypoint:IsA("BasePart") then
        table.insert(allWaypoints, waypoint)
    end
end

if #allWaypoints == 0 then
    return
end

if not figureModel.PrimaryPart then
    for _, part in pairs(figureModel:GetDescendants()) do
        if part:IsA("BasePart") then
            figureModel.PrimaryPart = part
            break
        end
    end
end

if not figureModel.PrimaryPart then
    return
end

local startHeightOffset = 3
local startPos = Vector3.new(
    startPart.Position.X,
    startPart.Position.Y + startHeightOffset,
    startPart.Position.Z
)

if figureModel and figureModel.PrimaryPart then
    figureModel:SetPrimaryPartCFrame(CFrame.new(startPos))
end

local function moveToPosition(targetPosition, speed)
    if not figureModel or not figureModel.PrimaryPart then
        return
    end
    
    local startPos = figureModel.PrimaryPart.Position
    local endPos = Vector3.new(
        targetPosition.X,
        targetPosition.Y + startHeightOffset,
        targetPosition.Z
    )
    
    local distance = (endPos - startPos).Magnitude
    if distance == 0 then
        return
    end
    
    local duration = distance / speed
    local startTime = tick()
    
    local RunService = game:GetService("RunService")
    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not figureModel or not figureModel.PrimaryPart then
            if connection then
                connection:Disconnect()
            end
            return
        end
        
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        local currentPos = Vector3.new(
            startPos.X + (endPos.X - startPos.X) * progress,
            startPos.Y + (endPos.Y - startPos.Y) * progress,
            startPos.Z + (endPos.Z - startPos.Z) * progress
        )
        
        figureModel:SetPrimaryPartCFrame(CFrame.new(currentPos))
        
        if progress >= 1 and connection then
            connection:Disconnect()
        end
    end)
    
    while tick() - startTime < duration do
        wait()
    end
    
    if figureModel and figureModel.PrimaryPart then
        figureModel:SetPrimaryPartCFrame(CFrame.new(endPos))
    end
end

local function getNearestWaypoint(currentPos, remainingWaypoints)
    local nearest = nil
    local nearestDistance = math.huge
    
    for _, waypoint in pairs(remainingWaypoints) do
        local waypointWithOffset = Vector3.new(
            waypoint.Position.X,
            waypoint.Position.Y + startHeightOffset,
            waypoint.Position.Z
        )
        local distance = (waypointWithOffset - currentPos).Magnitude
        if distance < nearestDistance then
            nearestDistance = distance
            nearest = waypoint
        end
    end
    
    return nearest
end

local function setupAttackDetection()
    local isAttacking = false
    local attackRange = 70
    local attackCooldown = 0.5
    local deathMessages = {
        "你被A-60击败了...",
        "巨大的嘈杂声中能感知到你的存在",
        "保持距离，寻找安全的位置"
    }
    
    spawn(function()
        while figureModel and figureModel.Parent and attackDetectionActive do
            wait(attackCooldown)
            
            local player = game.Players.LocalPlayer
            if player and player.Character and player.Character:FindFirstChild("Humanoid") then
                local character = player.Character
                local humanoid = character:FindFirstChild("Humanoid")
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and humanoidRootPart and humanoid.Health > 0 then
                    if not figureModel or not figureModel.PrimaryPart then
                        break
                    end
                    
                    local entityPosition = figureModel.PrimaryPart.Position
                    local playerPosition = humanoidRootPart.Position
                    local distance = (playerPosition - entityPosition).Magnitude
                    
                    if distance > 0.001 and distance <= attackRange then
                        local rayDirection = (playerPosition - entityPosition).Unit
                        local ray = Ray.new(entityPosition, rayDirection * attackRange)
                        
                        local ignoreList = {figureModel}
                        local hitPart, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
                        
                        if hitPart and hitPart:IsDescendantOf(character) and not character:GetAttribute("Hiding") then
                            if not isAttacking then
                                isAttacking = true
                                
                                DEATHMESSAGE(deathMessages, "A-60")
                                
                                humanoid:TakeDamage(100)
                                
                                wait(1)
                                isAttacking = false
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function moveThroughWaypoints()
    if not figureModel or not figureModel.PrimaryPart then
        return
    end
    
    local remainingWaypoints = {}
    for _, wp in pairs(allWaypoints) do
        table.insert(remainingWaypoints, wp)
    end
    
    local visitedWaypoints = {}
    local currentPos = figureModel.PrimaryPart.Position
    
    while #remainingWaypoints > 0 do
        if not figureModel or not figureModel.PrimaryPart then
            break
        end
        
        local nearest = getNearestWaypoint(currentPos, remainingWaypoints)
        if nearest then
            moveToPosition(nearest.Position, 140)
            
            if not figureModel or not figureModel.PrimaryPart then
                break
            end
            
            currentPos = figureModel.PrimaryPart.Position
            table.insert(visitedWaypoints, nearest)
            
            for i, wp in pairs(remainingWaypoints) do
                if wp == nearest then
                    table.remove(remainingWaypoints, i)
                    break
                end
            end
        else
            break
        end
    end
    
    for i = #visitedWaypoints - 1, 1, -1 do
        if not figureModel or not figureModel.PrimaryPart then
            break
        end
        
        local waypoint = visitedWaypoints[i]
        moveToPosition(waypoint.Position, 140)
        
        if not figureModel or not figureModel.PrimaryPart then
            break
        end
        
        currentPos = figureModel.PrimaryPart.Position
    end
    
    for i = 2, #visitedWaypoints do
        if not figureModel or not figureModel.PrimaryPart then
            break
        end
        
        local waypoint = visitedWaypoints[i]
        moveToPosition(waypoint.Position, 140)
        
        if not figureModel or not figureModel.PrimaryPart then
            break
        end
        
        currentPos = figureModel.PrimaryPart.Position
    end
end

if not entityTimerActive then
    entityTimerActive = true
    loopActive = true
    
    setupAttackDetection()
    
    spawn(function()
        while loopActive and figureModel and figureModel.Parent do
            moveThroughWaypoints()
            wait(0.1)
        end
    end)
    
    spawn(function()
        wait(60)
        
        loopActive = false
        attackDetectionActive = false
        
        if figureModel and figureModel.Parent then
            figureModel:Destroy()
        end
        
        figureModel = nil
        entityTimerActive = false
    end)
end

spawn(function()
    wait(0.5)
    local face = workspace:WaitForChild("A-60"):WaitForChild("RushNew"):WaitForChild("Main"):WaitForChild("Face")
    if face and face:IsA("ParticleEmitter") then
        while face and face.Parent and figureModel and figureModel.Parent do
            face.Texture = "rbxassetid://12145534911"
            wait(0.1)
            face.Texture = "rbxassetid://12145554242"
            wait(0.1)
            face.Texture = "rbxassetid://12145599498"
            wait(0.1)
            face.Texture = "rbxassetid://12145599275"
            wait(0.1)
            face.Texture = "rbxassetid://12155335619"
            wait(0.1)
            face.Texture = "rbxassetid://12145598814"
            wait(0.1)
            face.Texture = "rbxassetid://12146135062"
            wait(0.1)
            face.Texture = "rbxassetid://11378285585"
            wait(0.1)
        end
    end
end)

end

function entityBehaviors.XBramble()
local targetModel = workspace:WaitForChild("LiveEntityBramble", 5)
if not targetModel then
    return
end

local ModelID = 87341133560380

local success, modelData = pcall(function()
    return game:GetObjects("rbxassetid://" .. ModelID)
end)

if not success or #modelData == 0 then
    return
end

local NewModel = modelData[1]:Clone()
NewModel.Parent = workspace
NewModel.Name = "LiveEntityBramble1"

for _, part in ipairs(NewModel:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
        part.Transparency = 0
        part.CanCollide = true
    end
end

local partsToCopy = {
    "RightArm",
    "LeftArm", 
    "Head"
}

local copiedParts = {}

for _, partName in ipairs(partsToCopy) do
    
    local sourcePart = NewModel:FindFirstChild(partName, true)
    
    if sourcePart then

        if sourcePart:IsA("Model") then
            for _, child in ipairs(sourcePart:GetDescendants()) do
                if child:IsA("BasePart") or child:IsA("MeshPart") then
                end
            end
        end

        local clonedPart = sourcePart:Clone()
        clonedPart.Parent = targetModel

        local existingPart = targetModel:FindFirstChild(partName)
        if existingPart then
            clonedPart.Name = partName .. "_New"
        else
            clonedPart.Name = partName
        end

        if clonedPart:IsA("BasePart") or clonedPart:IsA("MeshPart") then
            clonedPart.Transparency = 0
            clonedPart.CanCollide = true
        end
        
        table.insert(copiedParts, clonedPart)

    else
        for _, child in ipairs(NewModel:GetChildren()) do

        end
    end
end

local originalHead = targetModel:FindFirstChild("Head")
if originalHead then
    if originalHead:IsA("BasePart") or originalHead:IsA("MeshPart") then
        originalHead.Transparency = 1
        originalHead.CanCollide = false

    elseif originalHead:IsA("Model") then
        for _, part in ipairs(originalHead:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("MeshPart") then
                part.Transparency = 1
                part.CanCollide = false
            end
        end

    end
else

end

local RunService = game:GetService("RunService")
local followConnection
followConnection = RunService.Heartbeat:Connect(function()
    if not targetModel or not targetModel.Parent or not NewModel or not NewModel.Parent then
        if followConnection then
            followConnection:Disconnect()
        end
        return
    end

    local mainPartTarget = targetModel.PrimaryPart or targetModel:FindFirstChild("HumanoidRootPart") or 
                           targetModel:FindFirstChild("Torso") or targetModel:FindFirstChildWhichIsA("BasePart")
    
    local mainPartNew = NewModel.PrimaryPart or NewModel:FindFirstChild("HumanoidRootPart") or 
                       NewModel:FindFirstChild("Torso") or NewModel:FindFirstChildWhichIsA("BasePart")
    
    if mainPartTarget and mainPartNew then

        mainPartNew.CFrame = mainPartTarget.CFrame
    end
end)

task.wait(1)

for _, part in ipairs(NewModel:GetDescendants()) do
    if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
        part.Transparency = 1
        part.CanCollide = false
    end
end

local model = workspace.LiveEntityBramble
local rightArm = model:FindFirstChild("RightArm", true)
local darkGrayColor = Color3.fromRGB(36, 36, 36) 

if rightArm then
    for _, part in ipairs(rightArm:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Color = darkGrayColor
        end
    end
end
wait(1)
local model = workspace.LiveEntityBramble
local LeftLeg = model:FindFirstChild("LeftLeg", true)
local darkGrayColor = Color3.fromRGB(36, 36, 36) 

if LeftLeg then
    for _, part in ipairs(LeftLeg:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Color = darkGrayColor
        end
    end
end
wait(1)
local model = workspace.LiveEntityBramble
local RightLeg = model:FindFirstChild("RightLeg", true)
local darkGrayColor = Color3.fromRGB(14, 14, 14) 

if RightLeg then
    for _, part in ipairs(RightLeg:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Color = darkGrayColor
        end
    end
end
wait(0.5)
local model = workspace.LiveEntityBramble
local Torso = model:FindFirstChild("Torso", true)
local darkGrayColor = Color3.fromRGB(14, 14, 14) 

if Torso then
    for _, part in ipairs(Torso:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Color = darkGrayColor
        end
    end
end
wait(0.5)
local model = workspace.LiveEntityBramble
local LeftArm = model:FindFirstChild("LeftArm", true)
local darkGrayColor = Color3.fromRGB(14, 14, 14) 

if LeftArm then
    for _, part in ipairs(LeftArm:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Color = darkGrayColor
        end
    end
end

local targetModel = workspace:WaitForChild("LiveEntityBramble", 5)
if not targetModel then
    return
end

local targetColor = Color3.fromRGB(160, 0, 0)

local pointLights = {}
local changedLights = 0

for _, light in ipairs(targetModel:GetDescendants()) do
    if light:IsA("PointLight") then
        table.insert(pointLights, {
            instance = light,
            originalColor = light.Color, 
            originalBrightness = light.Brightness,
            originalRange = light.Range
        })
    end
end

if #pointLights == 0 then

    local lightTypes = {}
    for _, child in ipairs(targetModel:GetDescendants()) do
        if child:IsA("Light") then
            local typeName = child.ClassName
            if not lightTypes[typeName] then
                lightTypes[typeName] = true
                print("  - " .. typeName)
            end
        end
    end
    return
end

for _, data in ipairs(pointLights) do
    local light = data.instance

    light.Color = targetColor

    light.Brightness = 5
    light.Range = 10      
    changedLights = changedLights + 1

    local newR = math.floor(light.Color.R * 255)
    local newG = math.floor(light.Color.G * 255)
    local newB = math.floor(light.Color.B * 255)
    
    local oldR = math.floor(data.originalColor.R * 255)
    local oldG = math.floor(data.originalColor.G * 255)
    local oldB = math.floor(data.originalColor.B * 255)
    
end

task.wait(0.5)

local correctCount = 0
local incorrectCount = 0

for _, data in ipairs(pointLights) do
    local light = data.instance
    local r = math.floor(light.Color.R * 255)
    local g = math.floor(light.Color.G * 255)
    local b = math.floor(light.Color.B * 255)
    
    if r == 160 and g == 0 and b == 0 then
        correctCount = correctCount + 1
    else
        incorrectCount = incorrectCount + 1
    end
end
local targetModel = workspace:WaitForChild("LiveEntityBramble", 5)
if not targetModel then

    return
end
local targetColor = Color3.fromRGB(255, 0, 0)

local particlePaths = {
    "Head.LanternNeon.Attachment.CenterAttach.CenterAttach",
    "Head.UpperHead.Glass.FliesParticles"
}

local changedParticles = 0

for _, path in ipairs(particlePaths) do

    local parts = {}
    for part in path:gmatch("([^.]+)") do
        table.insert(parts, part)
    end

    local current = targetModel
    local found = true
    
    for i, partName in ipairs(parts) do
        current = current:FindFirstChild(partName)
        if not current then
   
            found = false
            break
        end
    end
    
    if found and current:IsA("ParticleEmitter") then

        local originalColor = nil
        if current.Color and current.Color.Keypoints and #current.Color.Keypoints > 0 then
            originalColor = current.Color.Keypoints[1].Value
        end

        local redColorSequence = ColorSequence.new(targetColor)
        current.Color = redColorSequence

        current.Lifetime = NumberRange.new(1, 2)
        current.Rate = 50
        current.Speed = NumberRange.new(5, 10)

        current.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0)
        })

        current.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.1),
            NumberSequenceKeypoint.new(1, 1)
        })
        
        changedParticles = changedParticles + 1

        if originalColor then
            local oldR = math.floor(originalColor.R * 255)
            local oldG = math.floor(originalColor.G * 255)
            local oldB = math.floor(originalColor.B * 255)
        end
        
    elseif found then

        for _, particle in ipairs(current:GetDescendants()) do
            if particle:IsA("ParticleEmitter") then

                particle.Color = ColorSequence.new(targetColor)
                particle.Rate = 50
                
                changedParticles = changedParticles + 1

            end
        end
    end
end

local model = workspace:WaitForChild("LiveEntityBramble")
local targetColor = Color3.fromRGB(255, 0, 0)

local function findAndModifyParticle(path)
    local parts = path:split("-")
    local current = model
    
    for _, partName in ipairs(parts) do
        current = current:FindFirstChild(partName)
        if not current then return false end
    end
    
    if current and current:IsA("ParticleEmitter") then
        current.Color = ColorSequence.new(targetColor)
        return true
    end
    
    return false
end

findAndModifyParticle("Head-LanternNeon-Attachment-CenterAttach-LightCenterParticle")

local model = workspace:WaitForChild("LiveEntityBramble")
local lowerHead = model:FindFirstChild("LowerHead", true)
if lowerHead then
    if lowerHead:IsA("BasePart") or lowerHead:IsA("MeshPart") then
        lowerHead.Transparency = 1
    end
    for _, part in ipairs(lowerHead:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Transparency = 1
        end
    end
end

local model = workspace:WaitForChild("LiveEntityBramble")
local head = model:FindFirstChild("Head", true)

if head then

    local tongue = head:FindFirstChild("Tongue", true)
    if tongue then
        if tongue:IsA("BasePart") or tongue:IsA("MeshPart") then
            tongue.Color = Color3.fromRGB(0, 0, 0)
        elseif tongue:IsA("Model") then
            for _, part in ipairs(tongue:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.Color = Color3.fromRGB(0, 0, 0)
                end
            end
        end
    end

    local lanternNeon = head:FindFirstChild("LanternNeon", true)
    if lanternNeon then
        if lanternNeon:IsA("BasePart") or lanternNeon:IsA("MeshPart") then
            lanternNeon.Color = Color3.fromRGB(168, 0, 0)
        elseif lanternNeon:IsA("Model") then
            for _, part in ipairs(lanternNeon:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.Color = Color3.fromRGB(168, 0, 0)
                end
            end
        end
    end
end

local model = workspace:WaitForChild("LiveEntityBramble")
local head = model:FindFirstChild("Head", true)
local lowerHead = head and head:FindFirstChild("LowerHead", true)

if lowerHead then
    local newModel = game:GetObjects("rbxassetid://77857688443174")[1]:Clone()
    newModel.Parent = lowerHead
    newModel.Name = "PART"
end
wait(1)
local PART = workspace.LiveEntityBramble.Head.LowerHead.PART
local target = workspace.LiveEntityBramble:FindFirstChild("Head", true):FindFirstChild("LowerHead", true)
local RunService = game:GetService("RunService")

if PART and target then
    local targetPart = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart")
    RunService.Heartbeat:Connect(function()
        PART.CFrame = targetPart.CFrame
    end)
end
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

function entityBehaviors.Silence()
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

    local startRoomIndex = 1
    if #initialRooms > 10 then
        startRoomIndex = #initialRooms - 8
    end

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
    local states = {}
    local missingSince = nil

    while isActive() do
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

function entityBehaviors.ForstBite()
local vu5 = game:GetObjects("rbxassetid://85104600103168")[1]
        spawn(function()
            getgenv().death = false
            local function vu529()
                while true do
                    function DEATHMESSAGE(pu506, pu507)
                        local replicatedStorage = game:GetService("ReplicatedStorage")
                        local player = game.Players.LocalPlayer
                        local gameStats = replicatedStorage:FindFirstChild("GameStats")
                        local playerStats = gameStats and gameStats:FindFirstChild("Player_" .. player.Name)
                        local total = playerStats and playerStats:FindFirstChild("Total")
                        local deathCause = total and total:FindFirstChild("DeathCause")
                        if deathCause then
                            deathCause.Value = pu507
                        end
                    end
                    if workspace:FindFirstChild("SeekMovingNewClone") or workspace.CurrentRooms:FindFirstChild("50") then
                        break
                    end
                    wait(0.01)
                    local v508 = game.Players.LocalPlayer
                    local vu509 = workspace.CurrentCamera
                    local vu510 = v508.Character
                    game:GetService("ReplicatedStorage")
                    local frostbiteFreezeActive = false
                    local v512 = require(game.ReplicatedStorage:WaitForChild("CameraShaker")).new(Enum.RenderPriority.Camera.Value, function(p511)
                        if not frostbiteFreezeActive then
                            vu509.CFrame = vu509.CFrame * p511
                        end
                    end)
                    v512:Start()
                    local v513 = Instance.new("Model", game:GetService("Lighting"))
                    local v514 = vu5:Clone()
                    local v515 = v514.FrostyNew
                    local v516 = v515.Attachment
                    v514.Parent = workspace
                    v513:Destroy()
                    local v517 = workspace.CurrentRooms[game:GetService("ReplicatedStorage").GameData.LatestRoom.Value]
                    local nodeFolder = v517:FindFirstChild("Nodes") or v517:FindFirstChild("PathfindNodes")
                    local spawnPart
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
                        local v518 = math.max(1, math.floor(#nodes / 2))
                        spawnPart = nodes[v518]
                    end
                    if not spawnPart then
                        for _, candidateName in ipairs({v517.Name, "RoomEntrance", "RoomExit"}) do
                            local candidate = v517:FindFirstChild(candidateName)
                            if candidate and candidate:IsA("BasePart") then
                                spawnPart = candidate
                                break
                            end
                        end
                        if not spawnPart then
                            spawnPart = v517.PrimaryPart
                        end
                    end
                    if not spawnPart then
                        pcall(function()
                            v512:Stop()
                        end)
                        v514:Destroy()
                        return
                    end
                    v515.CFrame = spawnPart.CFrame + Vector3.new(0, 11, 0)
                    local v519 = Instance.new("ColorCorrectionEffect")
                    v519.Parent = game:GetService("Lighting")
                    v519.TintColor = Color3.new(1, 1, 1)
                    v519.Enabled = false
                    local v520 = v512:StartShake(3.6, 55, 5)
                    local frostbiteLighterStates = setmetatable({}, {__mode = "k"})
                    local frostbiteLighterConnections = {}
                    local frostbiteLighterDebug = false
                    local frostbiteEventActive = true
                    local frostbiteFreezeBusy = false
                    local frostbiteFreezeFactor = 1
                    local frostbiteEffects = {}
                    local frostbiteSeenCease = setmetatable({}, {__mode = "k"})
                    local frostbiteStaticTween = nil
                    local frostbiteShakerStopped = false

                    local function registerFrostbiteEffect(object)
                        if frostbiteEffects[object] then
                            return
                        end
                        if object:IsA("ParticleEmitter") then
                            frostbiteEffects[object] = {"particle", object.TimeScale}
                        elseif object:IsA("Sound") then
                            frostbiteEffects[object] = {"sound", object.PlaybackSpeed, object.Volume}
                        else
                            return
                        end
                        local state = frostbiteEffects[object]
                        if frostbiteFreezeBusy then
                            pcall(function()
                                if state[1] == "particle" then
                                    object.TimeScale = state[2] * frostbiteFreezeFactor
                                else
                                    object.PlaybackSpeed = state[2] * frostbiteFreezeFactor
                                    object.Volume = state[3] * frostbiteFreezeFactor
                                end
                            end)
                        end
                    end

                    local function applyFrostbiteFreeze(factor)
                        frostbiteFreezeFactor = factor
                        for object, state in pairs(frostbiteEffects) do
                            if object.Parent then
                                pcall(function()
                                    if state[1] == "particle" then
                                        object.TimeScale = state[2] * factor
                                    else
                                        object.PlaybackSpeed = state[2] * factor
                                        object.Volume = state[3] * factor
                                    end
                                end)
                            else
                                frostbiteEffects[object] = nil
                            end
                        end
                    end

                    local function restoreFrostbiteEffects()
                        for object, state in pairs(frostbiteEffects) do
                            if object.Parent then
                                pcall(function()
                                    if state[1] == "particle" then
                                        object.TimeScale = state[2]
                                    else
                                        object.PlaybackSpeed = state[2]
                                        object.Volume = state[3]
                                    end
                                end)
                            end
                            frostbiteEffects[object] = nil
                        end
                        frostbiteFreezeFactor = 1
                    end

                    local function restoreFrostbiteShake()
                        if frostbiteShakerStopped then
                            frostbiteShakerStopped = false
                            pcall(function()
                                v512:Start()
                            end)
                        end
                    end

                    local function applyFrostbiteFreezeTween(startFactor, endFactor, duration)
                        local started = os.clock()
                        while frostbiteEventActive do
                            local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
                            local eased = alpha * alpha * (3 - 2 * alpha)
                            applyFrostbiteFreeze(startFactor + (endFactor - startFactor) * eased)
                            if alpha >= 1 then
                                return true
                            end
                            game:GetService("RunService").Heartbeat:Wait()
                        end
                        return false
                    end

                    local function startFrostbiteCease(cease)
                        if not frostbiteEventActive or frostbiteFreezeBusy or frostbiteSeenCease[cease] then
                            return
                        end
                        frostbiteSeenCease[cease] = true
                        frostbiteFreezeBusy = true
                        frostbiteFreezeActive = true
                        frostbiteShakerStopped = true
                        pcall(function()
                            v512:Stop()
                        end)
                        if frostbiteStaticTween and frostbiteStaticTween.PlaybackState == Enum.PlaybackState.Playing then
                            frostbiteStaticTween:Pause()
                        end
                        for _, object in ipairs(v514:GetDescendants()) do
                            registerFrostbiteEffect(object)
                        end
                        task.spawn(function()
                            if not applyFrostbiteFreezeTween(frostbiteFreezeFactor, 0, 2.25) then
                                return
                            end
                            local holdStarted = os.clock()
                            while frostbiteEventActive and os.clock() - holdStarted < 13 do
                                applyFrostbiteFreeze(0)
                                game:GetService("RunService").Heartbeat:Wait()
                            end
                            if not frostbiteEventActive then
                                return
                            end
                            if not applyFrostbiteFreezeTween(0, 1, 2) then
                                return
                            end
                            restoreFrostbiteEffects()
                            if frostbiteStaticTween and frostbiteStaticTween.PlaybackState == Enum.PlaybackState.Paused then
                                frostbiteStaticTween:Play()
                            end
                            frostbiteFreezeBusy = false
                            frostbiteFreezeActive = false
                            restoreFrostbiteShake()
                        end)
                    end

                    local frostbiteDescendantConnection = v514.DescendantAdded:Connect(function(object)
                        if frostbiteFreezeBusy then
                            registerFrostbiteEffect(object)
                        end
                    end)

                    task.spawn(function()
                        while frostbiteEventActive and v514.Parent do
                            local cease = workspace:FindFirstChild("Cease")
                            if cease and cease:IsA("Model") then
                                startFrostbiteCease(cease)
                            end
                            task.wait(0.1)
                        end
                    end)

                    local function endFrostbiteCease()
                        for _, connection in ipairs(frostbiteLighterConnections) do
                            connection:Disconnect()
                        end
                        table.clear(frostbiteLighterConnections)
                        frostbiteEventActive = false
                        frostbiteFreezeActive = false
                        frostbiteFreezeBusy = false
                        if frostbiteDescendantConnection then
                            frostbiteDescendantConnection:Disconnect()
                        end
                        restoreFrostbiteEffects()
                        if frostbiteStaticTween and frostbiteStaticTween.PlaybackState == Enum.PlaybackState.Paused then
                            frostbiteStaticTween:Play()
                        end
                        restoreFrostbiteShake()
                    end
                    v516.face.Enabled = false
                    v516.BlackTrail.Enabled = false
                    v516.Heylois.Enabled = false
                    v516.smoke.Enabled = true
                    v516.BlackTrai3l.Enabled = true
                    v516.BlackTrai2l.Enabled = true
                    v515.Part.ParticleEmitter.Enabled = false
                    v515["Static Effect"]:Play()
                    wait(5)
                    v515["Static Effect"]:Play()
                    frostbiteStaticTween = game.TweenService:Create(v515["Static Effect"], TweenInfo.new(2), {
                        Pitch = 0
                    })
                    frostbiteStaticTween:Play()
                    if frostbiteFreezeActive then
                        frostbiteStaticTween:Pause()
                    end
                    v520:StartFadeOut(2.5)
                    wait(2)
                    local v521 = v512:StartShake(2, 55, 25, nil, Vector3.new(5, 5, 5))
                    local frostbiteBlueTween = game.TweenService:Create(v519, TweenInfo.new(7), {
                        TintColor = Color3.new(0.00784314, 0.188235, 1)
                    })
                    frostbiteBlueTween:Play()
                    local vu522 = true

                    local function findFrostbiteLighter(character)
                        if not character then
                            return nil
                        end
                        local exact = character:FindFirstChild("Lighter")
                        if exact then
                            return exact
                        end
                        for _, child in ipairs(character:GetChildren()) do
                            local name = string.lower(child.Name)
                            if string.find(name, "lighter", 1, true) then
                                return child
                            end
                        end
                        return nil
                    end

                    local function getFrostbiteEnabledEffect(instance)
                        if instance:IsA("ParticleEmitter") or instance:IsA("Fire")
                            or instance:IsA("PointLight") or instance:IsA("SpotLight")
                            or instance:IsA("SurfaceLight") or instance:IsA("Beam")
                            or instance:IsA("Trail") or instance:IsA("Smoke")
                            or instance:IsA("Sparkles") then
                            return instance.Enabled
                        end
                        return nil
                    end

                    local function getFrostbiteVisualState(attachOn)
                        if not attachOn then
                            return nil
                        end
                        local hasEffect = false
                        local anyEnabled = false
                        local function checkEffect(object)
                            local enabled = getFrostbiteEnabledEffect(object)
                            if enabled ~= nil then
                                hasEffect = true
                                if enabled then
                                    anyEnabled = true
                                end
                            end
                        end
                        checkEffect(attachOn)
                        for _, object in ipairs(attachOn:GetDescendants()) do
                            checkEffect(object)
                        end
                        if hasEffect then
                            return anyEnabled
                        end
                        return nil
                    end

                    local function getFrostbiteBooleanState(lighter, effectsHolder, attachOn)
                        local stateNames = {
                            "IsLit", "Lit", "IsOn", "On", "Ignited",
                            "IsIgnited", "LightOn", "IsActivated", "Using", "IsUsing"
                        }
                        for _, container in ipairs({lighter, effectsHolder or lighter, attachOn or lighter}) do
                            for _, name in ipairs(stateNames) do
                                local attribute = container:GetAttribute(name)
                                if typeof(attribute) == "boolean" then
                                    return attribute
                                end
                                local value = container:FindFirstChild(name)
                                if value and value:IsA("BoolValue") then
                                    return value.Value
                                end
                            end
                        end
                        return nil
                    end

                    local function watchFrostbiteLighter(lighter)
                        if not lighter:IsA("Tool") or frostbiteLighterStates[lighter] then
                            return
                        end
                        local state = {active = false, activated = false}
                        frostbiteLighterStates[lighter] = state
                        table.insert(frostbiteLighterConnections, lighter.Activated:Connect(function()
                            state.active = not state.active
                            state.activated = true
                        end))
                        table.insert(frostbiteLighterConnections, lighter.Unequipped:Connect(function()
                            state.active = false
                            state.activated = false
                        end))
                    end

                    local function isFrostbiteLighterLit(character)
                        local lighter = findFrostbiteLighter(character)
                        if not lighter then
                            return false
                        end
                        watchFrostbiteLighter(lighter)
                        local effectsHolder = lighter:FindFirstChild("EffectsHolder", true)
                        local attachOn = effectsHolder and effectsHolder:FindFirstChild("AttachOn", true)
                        if not attachOn then
                            attachOn = lighter:FindFirstChild("AttachOn", true)
                        end
                        if not attachOn then
                            local characterHolder = character:FindFirstChild("EffectsHolder", true)
                            if characterHolder then
                                effectsHolder = characterHolder
                                attachOn = characterHolder:FindFirstChild("AttachOn", true)
                            end
                        end
                        local visualState = getFrostbiteVisualState(attachOn)
                        if visualState == true then
                            return true
                        end
                        local booleanState = getFrostbiteBooleanState(lighter, effectsHolder, attachOn)
                        if booleanState == true then
                            return true
                        end
                        local state = frostbiteLighterStates[lighter]
                        if state and state.activated then
                            return state.active
                        end
                        if booleanState ~= nil then
                            return booleanState
                        end
                        if visualState ~= nil then
                            return visualState
                        end
                        if frostbiteLighterDebug then
                            warn("Frostbite lighter: no usable on/off effect", lighter:GetFullName(),
                                "holder:", effectsHolder and effectsHolder:GetFullName() or "none",
                                "AttachOn:", attachOn and attachOn:GetFullName() or "none")
                        end
                        return state ~= nil and state.activated and state.active or false
                    end

                    spawn(function()
                        while wait(1) and vu522 do
                            if not frostbiteFreezeActive then
                                local activeCharacter = v508.Character
                                local v523 = activeCharacter and activeCharacter:FindFirstChildOfClass("Humanoid")
                                if v523 and v523.Health > 0 then
                                    local lighterLit = isFrostbiteLighterLit(activeCharacter)
                                    if not lighterLit then
                                        if frostbiteLighterDebug then
                                            warn("Frostbite damage: Lighter not detected as active")
                                        end
                                        if v523.Health <= 5 then
                                            DEATHMESSAGE({
                                                "You died to who you call Frostbite...",
                                                "He will spawn in the middle and start freezing the room.",
                                                "Find something that has heat to keep you warm!"
                                            }, "FrostBite")
                                        end
                                        v523:TakeDamage(5)
                                    elseif frostbiteLighterDebug then
                                        print("Frostbite damage blocked: Lighter active")
                                    end
                                end
                            end
                        end
                    end)
                    v519.Enabled = true
                    v516.face.Enabled = true
                    v516.BlackTrail.Enabled = true
                    v516.Heylois.Enabled = true
                    v516.smoke.Enabled = true
                    v516.BlackTrai3l.Enabled = true
                    v516.BlackTrai2l.Enabled = true
                    v515.Part.ParticleEmitter.Enabled = true
                    v515.Ambience:Play()
                    v515.AmbienceFar:Play()
                    game:GetService("ReplicatedStorage").GameData.LatestRoom:GetPropertyChangedSignal("Value"):Wait()
                    frostbiteBlueTween:Cancel()
                    local frostbiteReturnTween = game.TweenService:Create(v519, TweenInfo.new(7), {
                        TintColor = Color3.new(1, 1, 1)
                    })
                    frostbiteReturnTween.Completed:Once(function(playbackState)
                        if playbackState == Enum.PlaybackState.Completed and v519.Parent then
                            v519:Destroy()
                        end
                    end)
                    frostbiteReturnTween:Play()
                    endFrostbiteCease()
                    vu522 = false
                    v521:StartFadeOut(15)
                    v520:StartFadeOut(1)
                    v515["Static Effect"]:Stop()
                    v515.Ambience:Stop()
                    v515.AmbienceFar:Stop()
                    local v526 = Instance.new("Sound", v515)
                    local v527 = Instance.new("FlangeSoundEffect")
                    local v528 = Instance.new("DistortionSoundEffect")
                    FlangeSoundEffect3 = Instance.new("FlangeSoundEffect")
                    v526.Name = "ahhhhhh"
                    v526.MaxDistance = 500
                    v526.Pitch = 0.23999999463558197
                    v526.PlaybackSpeed = 0.23999999463558197
                    v526.RollOffMode = Enum.RollOffMode.InverseTapered
                    v526.SoundId = "rbxassetid://6305809364"
                    v527.Parent = v526
                    v527.Rate = 0.75
                    v527.Depth = 1
                    v527.Mix = 0.7300000190734863
                    v528.Parent = v526
                    v528.Level = 0.9800000190734863
                    FlangeSoundEffect3.Parent = v526
                    FlangeSoundEffect3.Rate = 0.25
                    FlangeSoundEffect3.Depth = 1
                    FlangeSoundEffect3.Mix = 1
                    v526:Play()
                    v516.face.Enabled = false
                    v516.BlackTrail.Enabled = false
                    v516.Heylois.Enabled = false
                    v516.smoke.Enabled = true
                    v516.BlackTrai3l.Enabled = true
                    v516.BlackTrai2l.Enabled = true
                    v515.Part.ParticleEmitter.Enabled = false
                    v526.Ended:Wait()
                    v516.BlackTrai3l.Enabled = false
                    v516.BlackTrai2l.Enabled = false
                    v516.smoke.Enabled = false
                    wait(2)
                    pcall(function()
                        v512:Stop()
                    end)
                    v514:Destroy()
                    break
                end
            end
            vu529()
        end)
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
local Workspace = game:GetService("Workspace")
local function RandomUnanchor(count)
    count = count or 1800
    local parts = {}
      for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Anchored and not string.find(part.Name:lower(), "floor") then
            table.insert(parts, part)
        end
    end
    if #parts == 0 then
        return
    end
    local targetCount = math.min(count, #parts)
    local indices = {}

    for i = 1, #parts do
        indices[i] = i
    end
    for i = #indices, 2, -1 do
        local j = math.random(1, i)
        indices[i], indices[j] = indices[j], indices[i]
    end
    local unanchored = 0
    for i = 1, targetCount do
        local part = parts[indices[i]]
        if part and part.Anchored then
            part.Anchored = false
            unanchored = unanchored + 1

            if i % 100 == 0 then
            
            end
        end
    end
    return unanchored
end
RandomUnanchor(1800)
end

function entityBehaviors.INGODTWO()
 local entity = spawner.Create({
        Entity = {Name = "@&%^#*$Indescribable God!@$*&^!Q(*", Asset = "85650922684960", HeightOffset = -0.8},
        Lights = {Flicker = {Enabled = true, Duration = 50}, Shatter = true, Repair = true},
        Earthquake = {Enabled = false},
        CameraShake = {Enabled = true, Range = 1500, Values = {0.5, 20, 0.1, 1}},
        Movement = {Speed = 15, Delay = 2, Reversed = false},
        Rebounding = {Enabled = false, Type = "Blitz", Min = 1, Max = math.random(1, 2), Delay = math.random(10, 30) / 10},
        Damage = {Enabled = true, Range = 40, Amount = 200},
        Crucifixion = {Enabled = true, Range = 40, Resist = true, Break = true},
        Death = {
            Type = "Curious", 
            Hints = {
                "看来你遭遇了糟糕的事情。", 
                "你死于 %@&*$^%@&*!^$%(*&!^@$((!@&*$%", 
                "或许有时旁观并不会带给你友好的收益。", 
                "急速奔跑是你本能的求生欲。", 
                "下次见。"}, Cause = ""}})
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

function entityBehaviors.DELALL()
 local Event = game:GetService("ReplicatedStorage").RemotesFolder.AdminPanelRunCommand
Event:FireServer(
    "DELETE ALL",
    {}
)
local function deleteDirectChildModelsAndParts()
    local workspace = game:GetService("Workspace")
    local names = { "A-200", "A60", "Amin-60", "Black-A60", "Deer god","Black Hole Particle effect","Deer God",
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
local entity = spawner.Create({Entity = {Name = "smiler",Asset = "108450814500304",HeightOffset = 0},Lights = {Flicker = {Enabled = true,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 450,Delay = 11,Reversed = false},Rebounding = {Enabled = true,Type = "ambush",Min = 8,Max = 8,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 200,Amount = 125},Crucifixion = {Enabled = true,Range = 200,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于Smiler", "或许你需要在Ambush那学会点东西", "在闪灯数秒后他会出现", "加油,我相信你可以做到"},Cause = ""}})
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
function entityBehaviors.WhoopDaShoop()
local RunService = game:GetService("RunService")
local modelId = 86112457302745
local loadedModel
local success, result = pcall(function()
    return game:GetObjects("rbxassetid://" .. modelId)[1]
end)
if success and result and result:IsA("Model") then
    loadedModel = result
    loadedModel.Parent = workspace
else
    return
end

if not loadedModel.PrimaryPart then
    local rootPart = loadedModel:FindFirstChild("HumanoidRootPart") or loadedModel:FindFirstChildWhichIsA("BasePart")
    if rootPart then
        loadedModel.PrimaryPart = rootPart
    else
        return
    end
end

local function findGroundskeeper()
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return nil end

    for _, room in ipairs(currentRooms:GetChildren()) do
        if room:IsA("Model") then
            local target = room:FindFirstChild("Groundskeeper", true)
            if target and target:IsA("Model") then
                return target
            end
        end
    end
    return nil
end

local targetModel = findGroundskeeper()
if not targetModel then
    return
end

if not targetModel.PrimaryPart then
    local rootPart = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
    if rootPart then
        targetModel.PrimaryPart = rootPart
    else
        return
    end
end

local function processHideModel(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
            descendant.Transparency = 1
            if descendant:IsA("MeshPart") then
                descendant.RenderFidelity = Enum.RenderFidelity.Performance
            end
        end
        if descendant:IsA("Decal") or descendant:IsA("Texture") then
            descendant.Transparency = 1
        end
        if descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
            descendant.Enabled = false
        end
        if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
            descendant:Destroy()
        end
        if descendant:IsA("ParticleEmitter") then
            descendant.Enabled = false
        end
        if descendant:IsA("Fire") or descendant:IsA("Smoke") then
            descendant.Enabled = false
        end
    end
end

local function hideGroundskeeper()
    local foundAny = false
    local function searchAndHide(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "Groundskeeper" and child:IsA("Model") then
                processHideModel(child)
                foundAny = true
            end
            searchAndHide(child)
        end
    end
    searchAndHide(workspace)
    return foundAny
end

hideGroundskeeper()

local function setupHideMonitor()
    local connections = {}
    local function monitorChildAdded(parent)
        local connection = parent.ChildAdded:Connect(function(child)
            if child.Name == "Groundskeeper" and child:IsA("Model") then
                task.wait(0.1)
                processHideModel(child)
            end
            monitorChildAdded(child)
        end)
        table.insert(connections, connection)
    end
    monitorChildAdded(workspace)
    return function()
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
    end
end

local hideMonitor = setupHideMonitor()

local function processDeleteSounds(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("Sound") then
            descendant:Destroy()
        end
    end
end

local function deleteGroundskeeperSounds()
    local foundAny = false
    local function searchAndDelete(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "Groundskeeper" and child:IsA("Model") then
                processDeleteSounds(child)
            end
            searchAndDelete(child)
        end
    end
    searchAndDelete(workspace)
    return foundAny
end

deleteGroundskeeperSounds()

local function setupSoundDeletionMonitor()
    local connections = {}
    local function processNewSound(sound)
        if not sound:IsA("Sound") then return end
        local current = sound
        while current and current ~= game do
            if current.Name == "Groundskeeper" and current:IsA("Model") then
                sound:Destroy()
                break
            end
            current = current.Parent
        end
    end
    local function monitorDescendantAdded(parent)
        local connection = parent.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("Sound") then
                processNewSound(descendant)
            end
        end)
        table.insert(connections, connection)
    end
    monitorDescendantAdded(workspace)
    local groundskeeperConnection
    groundskeeperConnection = workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "Groundskeeper" and descendant:IsA("Model") then
            task.wait(0.1)
            processDeleteSounds(descendant)
        end
    end)
    table.insert(connections, groundskeeperConnection)
    return function()
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
    end
end

local soundMonitor = setupSoundDeletionMonitor()

local followConnection
followConnection = RunService.Heartbeat:Connect(function()
    if not targetModel or not targetModel.PrimaryPart or not loadedModel or not loadedModel.PrimaryPart or not targetModel.PrimaryPart.Parent or not loadedModel.Parent then
        if followConnection then
            followConnection:Disconnect()
        end
        return
    end
    local targetCFrame = targetModel.PrimaryPart.CFrame
    loadedModel:PivotTo(targetCFrame)
end)

return function()
    if followConnection then
        followConnection:Disconnect()
    end
    if hideMonitor then
        hideMonitor()
    end
    if soundMonitor then
        soundMonitor()
    end
    if loadedModel and loadedModel.Parent then
        loadedModel:Destroy()
    end
end
end

function entityBehaviors.WhoopDaShoopTwo()
 local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://138148333"
sound.Name = "WHOOP"
sound.Parent = workspace
sound:Play()

local targetModel = workspace:FindFirstChild("Following_ENEMY")
if not targetModel then return end

if not targetModel.PrimaryPart then
    local rootPart = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
    if rootPart then targetModel.PrimaryPart = rootPart else return end
end

local currentRooms = Workspace:FindFirstChild("CurrentRooms")
local groundskeeperModel
if currentRooms then
    for _, room in ipairs(currentRooms:GetChildren()) do
        if room:IsA("Folder") or room:IsA("Model") then
            local groundskeeper = room:FindFirstChild("Groundskeeper")
            if groundskeeper and groundskeeper:IsA("Model") then
                groundskeeperModel = groundskeeper
                break
            end
        end
    end
end
if not groundskeeperModel then return end

if not groundskeeperModel.PrimaryPart then
    local rootPart = groundskeeperModel:FindFirstChild("HumanoidRootPart") or groundskeeperModel:FindFirstChildWhichIsA("BasePart")
    if rootPart then groundskeeperModel.PrimaryPart = rootPart else return end
end

task.wait(1.8)

local laser1Id = 75823189898619
local laser1Model
local laser1Success, laser1Result = pcall(function()
    return game:GetObjects("rbxassetid://" .. laser1Id)[1]
end)
if laser1Success and laser1Result and laser1Result:IsA("Model") then
    laser1Model = laser1Result
    laser1Model.Name = "Laser1"
    laser1Model.Parent = workspace
    if not laser1Model.PrimaryPart then
        local rootPart = laser1Model:FindFirstChild("HumanoidRootPart") or laser1Model:FindFirstChildWhichIsA("BasePart")
        if rootPart then laser1Model.PrimaryPart = rootPart end
    end
else
    return
end

local function hideModel(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
            descendant.Transparency = 1
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            descendant.Transparency = 1
        elseif descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
            descendant.Enabled = false
        end
    end
end

local function restoreModelExceptRootPart(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant.Name ~= "HumanoidRootPart" then
            if descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
                descendant.Transparency = 0
            elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
                descendant.Transparency = 0
            elseif descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
                descendant.Enabled = true
            end
        end
    end
end

local laser1FollowConnection
if groundskeeperModel and groundskeeperModel.PrimaryPart and laser1Model and laser1Model.PrimaryPart then
    laser1Model:PivotTo(groundskeeperModel.PrimaryPart.CFrame)
    hideModel(targetModel)
    laser1FollowConnection = RunService.Heartbeat:Connect(function()
        if not groundskeeperModel or not groundskeeperModel.PrimaryPart or not laser1Model or not laser1Model.PrimaryPart or 
           not groundskeeperModel.PrimaryPart.Parent or not laser1Model.Parent then
            if laser1FollowConnection then laser1FollowConnection:Disconnect() end
            return
        end
        laser1Model:PivotTo(groundskeeperModel.PrimaryPart.CFrame)
    end)
else
    return
end

task.wait(1.3)

local laser2Id = 74088823220607
local laser2Model
local laser2Success, laser2Result = pcall(function()
    return game:GetObjects("rbxassetid://" .. laser2Id)[1]
end)
if laser2Success and laser2Result and laser2Result:IsA("Model") then
    laser2Model = laser2Result
    laser2Model.Name = "Laser2"
    laser2Model.Parent = workspace
    if not laser2Model.PrimaryPart then
        local rootPart = laser2Model:FindFirstChild("HumanoidRootPart") or laser2Model:FindFirstChildWhichIsA("BasePart")
        if rootPart then laser2Model.PrimaryPart = rootPart end
    end
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local SHAKE_INTENSITY = 2
    local SHAKE_DURATION = 10
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
            if connection then connection:Disconnect() end
        end
    end)
else
    return
end

local laser2FollowConnection
if groundskeeperModel and groundskeeperModel.PrimaryPart and laser2Model and laser2Model.PrimaryPart then
    laser2Model:PivotTo(groundskeeperModel.PrimaryPart.CFrame)
    hideModel(laser1Model)
    laser2FollowConnection = RunService.Heartbeat:Connect(function()
        if not groundskeeperModel or not groundskeeperModel.PrimaryPart or not laser2Model or not laser2Model.PrimaryPart or 
           not groundskeeperModel.PrimaryPart.Parent or not laser2Model.Parent then
            if laser2FollowConnection then laser2FollowConnection:Disconnect() end
            return
        end
        laser2Model:PivotTo(groundskeeperModel.PrimaryPart.CFrame)
    end)
else
    return
end

local soundFinished = false
local soundConnection
soundConnection = sound.Ended:Connect(function()
    soundFinished = true
    if soundConnection then soundConnection:Disconnect() end
end)
while not soundFinished do task.wait(0.1) end
if targetModel then restoreModelExceptRootPart(targetModel) end
if laser1FollowConnection then laser1FollowConnection:Disconnect() end
if laser2FollowConnection then laser2FollowConnection:Disconnect() end
if laser1Model and laser1Model.Parent then laser1Model:Destroy() end
if laser2Model and laser2Model.Parent then laser2Model:Destroy() end
if sound and sound.Parent then sound:Destroy() end
end

function entityBehaviors.ChainSmoker()
local entity = spawner.Create({Entity = {Name = "Chainsmoker",Asset = "91743718986054",HeightOffset = 1},Lights = {Flicker = {Enabled = true,Duration = 1},Shatter = true,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 10,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 30,Delay = 1,Reversed = false},Rebounding = {Enabled = false,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},Damage = {Enabled = true,Range = 5,Amount = 125},Crucifixion = {Enabled = true,Range = 20,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"你死于Chainsmoker", "......", "或许我不能告诉你他的信息", "总而言之，当心闪灯"},Cause = ""}})
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

function entityBehaviors.Deergod()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
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

local ENTITY_ASSET_ID = 104577643723831
local DEATH_ASSET_ID = 83935353406484
local VICTIM_ANIMATION_ID = "rbxassetid://131382303107033"
local SPEED = 12
local CHASE_RANGE = 75
local HIT_RANGE = 10
local MAX_ROOMS = 15
local HEIGHT_OFFSET = Vector3.new(0, 2.4, 0)
local DEATH_POSITION = Vector3.new(244, -304, -6)
local DEATH_SECONDS = 15
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

local deathTemplate = loadModel(DEATH_ASSET_ID, "DeerGodDeathModel")
prepareModel(entity)
if deathTemplate then
    prepareModel(deathTemplate)
    pcall(function()
        ContentProvider:PreloadAsync({ deathTemplate })
    end)
end

local animation = Instance.new("Animation")
animation.Name = "DeerGodVictimAnimation"
animation.AnimationId = VICTIM_ANIMATION_ID
pcall(function()
    ContentProvider:PreloadAsync({ animation })
end)

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
    if deathTemplate then
        deathTemplate:Destroy()
    end
    animation:Destroy()
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
local soundNames = { PlaySound = true, Footsteps = true, Music = true }
for _, descendant in ipairs(entity:GetDescendants()) do
    if descendant:IsA("Sound") and soundNames[descendant.Name] then
        descendant.Looped = true
        descendant.TimePosition = 0
        descendant:Play()
        ambientSounds[#ambientSounds + 1] = descendant
    end
end

local hardCoreMusicFolder = Workspace:FindFirstChild("HardCoreSound")
if hardCoreMusicFolder then
    for _, name in ipairs({ "DeerGodMusic", "DeerMusic", "DeerGodBackgroundSound", "DeerBackgroundSound" }) do
        local music = hardCoreMusicFolder:FindFirstChild(name)
        if music and music:IsA("Sound") then
            music:Stop()
            music.TimePosition = 0
            music.Looped = true
            music:Play()
            ambientSounds[#ambientSounds + 1] = music
            break
        end
    end
end

local running = true
local errorParticlesGui = nil
local errorParticlesConnection = nil
local cutsceneActive = false
local cutsceneSerial = 0
local cutsceneConnection = nil
local cutsceneState = nil
local lockedPlayer = nil
local lockedCharacter = nil
local victimSpeedConnection = nil
local victimSpeedHumanoid = nil
local victimOriginalWalkSpeed = nil
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
        deathCause.Value = "Deer God"
    end
end

local function playVictimAnimation(humanoid)
    local animator = humanoid:FindFirstChildWhichIsA("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    if ok and track then
        track.Looped = true
        track.Priority = Enum.AnimationPriority.Action4
        track:Play(0.1)
        return track
    end
    return nil
end

local function pauseAmbientSounds()
    for _, sound in ipairs(ambientSounds) do
        if sound and sound.Parent and sound.IsPlaying then
            sound:Pause()
        end
    end

    local hardCoreFolder = Workspace:FindFirstChild("HardCoreSound")
    if hardCoreFolder then
        for _, object in ipairs(hardCoreFolder:GetDescendants()) do
            if object:IsA("Sound") and object.Name ~= "DeerDeath" and object.IsPlaying then
                object:Pause()
            end
        end
    end
end

local function restoreCutscene()
    if cutsceneConnection then
        cutsceneConnection:Disconnect()
        cutsceneConnection = nil
    end
    if not cutsceneState then
        return
    end
    local state = cutsceneState
    cutsceneState = nil
    local camera = state.Camera
    if camera and camera.Parent then
        camera.CameraType = state.CameraType
        local character = player.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        elseif state.CameraSubject and state.CameraSubject.Parent then
            camera.CameraSubject = state.CameraSubject
        end
    end
    Lighting.FogColor = state.FogColor
    Lighting.FogStart = state.FogStart
    Lighting.FogEnd = state.FogEnd
    if state.ColorEffect then
        state.ColorEffect:Destroy()
    end
    if state.RedGui then
        state.RedGui:Destroy()
    end
    if state.DeerDeathSound then
        state.DeerDeathSound:Stop()
        state.DeerDeathSound:Destroy()
    end
end

local function startCutscene(deathModel)
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    restoreCutscene()
    local state = {
        Camera = camera,
        CameraType = camera.CameraType,
        CameraSubject = camera.CameraSubject,
        FogColor = Lighting.FogColor,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd
    }
    cutsceneState = state

    local redGui = Instance.new("ScreenGui")
    redGui.Name = "DeerGodRedHaze"
    redGui.IgnoreGuiInset = true
    redGui.ResetOnSpawn = false
    redGui.DisplayOrder = 90
    redGui.Parent = playerGui
    local veil = Instance.new("Frame")
    veil.Size = UDim2.fromScale(1, 1)
    veil.BackgroundColor3 = Color3.fromRGB(130, 20, 25)
    veil.BackgroundTransparency = 0.94
    veil.BorderSizePixel = 0
    veil.Parent = redGui
    state.RedGui = redGui

    local effect = Instance.new("ColorCorrectionEffect")
    effect.Name = "DeerGodDeathColor"
    effect.TintColor = Color3.fromRGB(255, 190, 190)
    effect.Saturation = -0.15
    effect.Contrast = 0.1
    effect.Parent = Lighting
    state.ColorEffect = effect

    Lighting.FogColor = Color3.fromRGB(100, 35, 40)
    Lighting.FogStart = 5
    Lighting.FogEnd = 50

    local end1 = deathModel and deathModel:FindFirstChild("END1", true)
    local end2 = deathModel and deathModel:FindFirstChild("END2", true)

    if end1 and end1:IsA("BasePart") and end2 and end2:IsA("BasePart") then
        local fromPosition = end1.Position
        local toPosition = end2.Position
        local difference = toPosition - fromPosition
        local forward = difference.Magnitude > 0.001
            and difference.Unit or end1.CFrame.LookVector
        local cameraStartedAt = os.clock()
        local startingCameraCFrame = CFrame.lookAt(fromPosition, fromPosition + forward)

        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = startingCameraCFrame
        camera.Focus = CFrame.new(toPosition)

        cutsceneConnection = RunService.RenderStepped:Connect(function()
            local currentCamera = Workspace.CurrentCamera
            if cutsceneActive and currentCamera then
                local alpha = math.clamp(
                    (os.clock() - cameraStartedAt) / DEATH_SECONDS,
                    0,
                    1
                )
                local eased = alpha * alpha * (3 - 2 * alpha)
                local position = fromPosition:Lerp(toPosition, eased)
                currentCamera.CameraType = Enum.CameraType.Scriptable
                currentCamera.CFrame = CFrame.lookAt(position, position + forward)
                currentCamera.Focus = CFrame.new(toPosition)
            end
        end)
    end

    local hardCoreSound = Workspace:FindFirstChild("HardCoreSound")
    local original = hardCoreSound and hardCoreSound:FindFirstChild("DeerDeath")
    if original and original:IsA("Sound") then
        local sound = original:Clone()
        sound.Looped = false
        sound.TimePosition = 0
        sound.Parent = SoundService
        sound:Play()
        state.DeerDeathSound = sound
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

local function restoreVictimWalkSpeed()
    if victimSpeedConnection then
        victimSpeedConnection:Disconnect()
        victimSpeedConnection = nil
    end

    if victimSpeedHumanoid and victimSpeedHumanoid.Parent and victimOriginalWalkSpeed ~= nil then
        victimSpeedHumanoid.WalkSpeed = victimOriginalWalkSpeed
    end

    victimSpeedHumanoid = nil
    victimOriginalWalkSpeed = nil
end

local function lockVictimWalkSpeed(humanoid)
    restoreVictimWalkSpeed()

    if not humanoid or not humanoid.Parent then
        return
    end

    victimSpeedHumanoid = humanoid
    victimOriginalWalkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = -20

    victimSpeedConnection = RunService.Heartbeat:Connect(function()
        if not cutsceneActive or not victimSpeedHumanoid or not victimSpeedHumanoid.Parent then
            restoreVictimWalkSpeed()
            return
        end

        if victimSpeedHumanoid.WalkSpeed ~= -20 then
            victimSpeedHumanoid.WalkSpeed = -20
        end
    end)
end

local function playDeathScene(targetPlayer, targetCharacter, targetHumanoid)
    if targetPlayer ~= player or cutsceneActive or not running then
        return
    end
    cutsceneActive = true
    lockVictimWalkSpeed(targetHumanoid)
    pauseAmbientSounds()
    cutsceneSerial = cutsceneSerial + 1
    local serial = cutsceneSerial
    hitCharacters[targetCharacter] = true

    local track = playVictimAnimation(targetHumanoid)
    local deathModel = nil
    if deathTemplate then
        deathModel = deathTemplate:Clone()
        deathModel.Name = "DeerGodDeathScene"
        deathModel:PivotTo(CFrame.new(DEATH_POSITION))
        deathModel.Parent = Workspace
    end

    if targetPlayer == player then
        startCutscene(deathModel)
    end

    task.delay(DEATH_SECONDS, function()
        if serial ~= cutsceneSerial then
            restoreVictimWalkSpeed()
            if track then
                track:Stop(0)
                track:Destroy()
            end
            if deathModel then
                deathModel:Destroy()
            end
            return
        end

        local camera = Workspace.CurrentCamera
        if targetPlayer == player and camera and cutsceneState and cutsceneState.Camera == camera then
            local end1 = deathModel and deathModel:FindFirstChild("END1", true)
            local end2 = deathModel and deathModel:FindFirstChild("END2", true)
            if end1 and end1:IsA("BasePart") and end2 and end2:IsA("BasePart") then
                local direction = end2.Position - end1.Position
                local forward = direction.Magnitude > 0.001 and direction.Unit or end1.CFrame.LookVector
                camera.CameraType = Enum.CameraType.Scriptable
                camera.CFrame = CFrame.lookAt(end2.Position, end2.Position + forward)
                camera.Focus = CFrame.new(end2.Position + forward * 10)
            end
        end

        killTargetLocally(targetPlayer, targetCharacter)

        task.delay(0.8, function()
            if serial ~= cutsceneSerial then
                restoreVictimWalkSpeed()
                if track then
                    track:Stop(0)
                    track:Destroy()
                end
                if deathModel then
                    deathModel:Destroy()
                end
                return
            end

            restoreVictimWalkSpeed()
            if track then
                track:Stop(0)
                track:Destroy()
            end
            if deathModel then
                deathModel:Destroy()
            end
            if targetPlayer == player then
                restoreCutscene()
            end
            if lockedPlayer == targetPlayer and lockedCharacter == targetCharacter then
                lockedPlayer = nil
                lockedCharacter = nil
            end
            cutsceneActive = false
        end)
    end)
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
                        if camera and not cutsceneActive then
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
            if not cutsceneActive then
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
    cutsceneSerial = cutsceneSerial + 1
    restoreVictimWalkSpeed()
    restoreCutscene()
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
    if deathTemplate then
        deathTemplate:Destroy()
        deathTemplate = nil
    end
    animation:Destroy()
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

    if not cutsceneActive then
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
            playDeathScene(player, myCharacter, myHumanoid)
        end
    end
end

finish()

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
	local soundFolder = workspace:WaitForChild("HardCoreSound")
	local sound = soundFolder:FindFirstChild("A200J")

	if sound and sound:IsA("Sound") then
		sound.Volume = 3
		sound.Looped = false

		if not sound.IsLoaded then
			sound.Loaded:Wait()
		end

		sound:Play()
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

 local entity = spawner.Create({Entity = {Name = "Cease",Asset = "74118615017772",HeightOffset = 1},Lights = {Flicker = {Enabled = false,Duration = 10},Shatter = false,Repair = false},Earthquake = {Enabled = false},CameraShake = {Enabled = true,Range = 200,Values = {1.5, 20, 0.1, 1}},Movement = {Speed = 100,Delay = 5,Reversed = false},Rebounding = {Enabled = false,Type = "ambush",Min = 4,Max = 4,Delay = math.random(10, 30) / 10},Damage = {Enabled = false,Range = 100,Amount = 125},Crucifixion = {Enabled = false,Range = 100,Resist = false,Break = true},Death = {Type = "Guiding",Hints = {"CEASE", "...", "...", "..."},Cause = "Cease"}}) 
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

function entityBehaviors.SHADOWSW()
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

local s = LoadCustomInstance(76157710463326, workspace)
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
end

function entityBehaviors.CL()
 local Event = game:GetService("ReplicatedStorage").RemotesFolder.AdminPanelRunCommand
    Event:FireServer("Break Lights", {["Lights Affected"] = 100, ["Affect All Rooms"] = true})
    task.wait(1)
    Event:FireServer("LightRoom", {["Light Color"] = Color3.new(0.80784314870834, 0.63644915819168, 0)})
    task.wait(0.1)
    Event:FireServer("DELETE ALL", {})
    task.wait(2)
    
    local function deleteDirectChildModels()
        for _, name in ipairs({"A-200", "A60", "Amin-60", "Black-A60", "Deer god", "DeerGod", "Frostbite", "@&%^#*$Indescribable God!@$*&^!Q(* ", "LightSpeed", "Rebound", "Ripper", "Following_ENEMY", "Silence", "smiler", "Chainsmoker"}) do
            local model = workspace:FindFirstChild(name)
            if model and model:IsA("Model") then model:Destroy() end
        end
    end
    deleteDirectChildModels()
    
    function GetRoom()
        return workspace.CurrentRooms:FindFirstChild(game.ReplicatedStorage.GameData.LatestRoom.Value)
    end
    
    function LoadCustomInstance(source)
        local model
        while task.wait() and not model do
            if tonumber(source) then
                local success, result = pcall(function() return game:GetObjects("rbxassetid://"..tostring(source))[1] end)
                if success and result then model = result end
            end
        end
        if model then
            model.Parent = workspace
            for _, obj in ipairs(model:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") then obj:Destroy() end
            end
        end
        return model
    end
    
    local s = LoadCustomInstance("78378481962514")
    if not s then return end
    s.Name = "CuriLight"
    
    local entity = s:FindFirstChildWhichIsA("BasePart")
    if entity then entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(0,5,-25) end
    
    pcall(function()
        local room = workspace.CurrentRooms:FindFirstChild(tostring(game.ReplicatedStorage.GameData.LatestRoom.Value))
        if room then
            for _, obj in ipairs(room:GetDescendants()) do
                if obj.Name == "PlaySound" and obj:IsA("Sound") then
                    obj:Stop() obj.Playing = false obj.TimePosition = 0 obj.Looped = false
                end
            end
            local fireplace = room.Assets.Fireplace.Fireplace_Logs
            fireplace.ToolEventPrompt.Enabled = false
            local log = fireplace.Log
            log.SparkParticles.Enabled = false
            log.SmokeParticles.Enabled = false
            log.FireParticles.Enabled = false
            log.FireLight.Enabled = false
        end
    end)
    task.wait(0.5)
    
    function GitAud(soundgit, filename)
        local url = soundgit
        local FileName = filename
        writefile(FileName..".mp3", game:HttpGet(url))
        return (getcustomasset or getsynasset)(FileName..".mp3")
    end
    function CustomGitSound(soundlink, vol, filename)
        local sound = Instance.new("Sound")
        sound.SoundId = GitAud(soundlink, filename)
        sound.Parent = workspace
        sound.Name = filename or "CL"
        sound.Volume = vol or 1
        sound:Play()
        return sound
    end
    
    local targetAudioUrl = "https://github.com/Zero0star/RipperMPSound/blob/master/CuriLightSpeak.mp3?raw=true"
    local volume = 2
    local localFileName = "CruiMu"
    
    local function setupCuriLightFeatures()
        local CuriLight = workspace:FindFirstChild("CuriLight")
        if not CuriLight or not CuriLight:IsA("Model") then return end
        
        local humanoid = CuriLight:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            humanoid = Instance.new("Humanoid")
            humanoid.Name = "Humanoid"
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.AutoRotate = false
            humanoid.Parent = CuriLight
        end
        
        local function playAnimation()
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then animator = Instance.new("Animator") animator.Parent = humanoid end
            
            local animationId = "rbxassetid://122746752555782"
            local success, errorMsg = pcall(function()
                local animation = Instance.new("Animation")
                animation.AnimationId = animationId
                animation.Name = "CuriLightAnimation"
                local animationTrack = humanoid:LoadAnimation(animation)
                if animationTrack then 
                    animationTrack.Looped = true
                    animationTrack:Play()
                    return animationTrack
                end
                return nil
            end)
            
            if not success then warn("NO:", errorMsg) end
        end
        
        playAnimation()
        
        local function getPrimaryPart(model)
            if model.PrimaryPart then return model.PrimaryPart end
            local parts = {"HumanoidRootPart", "Head", "Torso", "UpperTorso", "Part"}
            for _, partName in ipairs(parts) do
                local part = model:FindFirstChild(partName)
                if part and part:IsA("BasePart") then return part end
            end
            for _, child in ipairs(model:GetChildren()) do
                if child:IsA("BasePart") then return child end
            end
            return nil
        end
        
        local curiLightPart = getPrimaryPart(CuriLight)
        if not curiLightPart then return end
        
        local CONFIG = {ROTATION_SPEED = 5, SMOOTHNESS = 0.1, HEIGHT_OFFSET = 0, MAX_DISTANCE = 100, ENABLED = true}
        local lastUpdateTime = tick()
        local connection
        
        local function updateLookAt()
            if not CONFIG.ENABLED then return end
            local character = game.Players.LocalPlayer.Character
            if not character then return end
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end
            local distance = (humanoidRootPart.Position - curiLightPart.Position).Magnitude
            if distance > CONFIG.MAX_DISTANCE then return end
            local targetPosition = humanoidRootPart.Position + Vector3.new(0, CONFIG.HEIGHT_OFFSET, 0)
            local curiLightPosition = curiLightPart.Position
            local direction = (targetPosition - curiLightPosition).Unit
            local targetLookAt = CFrame.lookAt(curiLightPosition, curiLightPosition + direction)
            local _, currentY, _ = curiLightPart.CFrame:ToOrientation()
            local _, targetY, _ = targetLookAt:ToOrientation()
            local yawDifference = targetY - currentY
            if yawDifference > math.pi then yawDifference = yawDifference - 2 * math.pi
            elseif yawDifference < -math.pi then yawDifference = yawDifference + 2 * math.pi end
            local deltaTime = tick() - lastUpdateTime
            lastUpdateTime = tick()
            local lerpAmount = 1 - math.exp(-CONFIG.ROTATION_SPEED * deltaTime)
            local lerpedY = currentY + yawDifference * lerpAmount
            local newCFrame = CFrame.new(curiLightPosition) * CFrame.Angles(0, lerpedY, 0)
            curiLightPart.CFrame = newCFrame
        end
        
        connection = game:GetService("RunService").Heartbeat:Connect(updateLookAt)
        
        game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == Enum.KeyCode.T and not gameProcessed then CONFIG.ENABLED = not CONFIG.ENABLED end
        end)
        
        return CuriLight, connection
    end
    local curiModel, curiConnection = setupCuriLightFeatures()
    task.wait(5)
    local sound = CustomGitSound(targetAudioUrl, volume, localFileName)
    task.wait(1)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("Dead Again",true)
    task.wait(3)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("You know better than I how to save yourself.",true)
    task.wait(2.5)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("OH",true)
    task.wait(1.4)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("I think you are using something called admin.",true)
    task.wait(2.8)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("Sorry..",true)
    task.wait(2.2)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("But my appearance is not to save you.",true)
    task.wait(2.5)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("In short, be careful next time...",true)
    task.wait(2.2)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("However, I will always keep an eye on you.",true)
    task.wait(4)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("Okey..",true)
    task.wait(2)
    require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("See U Again",true)
    sound.Ended:Wait()
    if curiConnection then curiConnection:Disconnect() end
    if curiModel then curiModel:Destroy() end
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

function entityBehaviors.MLcur()
local modelID = 90889178594108
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
    anchor.Size = Vector3.new(0.01, 0.01, 0.01)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Massless = true
    anchor.CFrame = entity.CFrame + Vector3.new(0, 6.5, 0)
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
    
    local reversalRed = cachedModel:FindFirstChild("Reversal Red")
    if not reversalRed then
        for _, descendant in ipairs(cachedModel:GetDescendants()) do
            if descendant.Name:lower() == "reversal red" then
                reversalRed = descendant
                break
            end
        end
    end
    
    if reversalRed then
        local doorsCrucifix = reversalRed:FindFirstChild("doors crucifix")
        if not doorsCrucifix then
            for _, descendant in ipairs(reversalRed:GetDescendants()) do
                if descendant:IsA("Sound") and descendant.Name:lower() == "doors crucifix" then
                    doorsCrucifix = descendant
                    break
                end
            end
        end
        
        if doorsCrucifix and doorsCrucifix:IsA("Sound") then
            local sound = doorsCrucifix:Clone()
            sound.Parent = workspace
            sound:Play()
            
            sound.Ended:Connect(function()
                if sound and sound.Parent then
                    sound:Destroy()
                end
            end)
        end
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

function entityBehaviors.Bombie()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local REPLACEMENT_CONFIG = {
    ["compass"] = {assetId = 111123143736711}
}
local CHECK_INTERVAL = 0.3
local trackedTargets = {}

local OFFSET_LEFT = Vector3.new(-10, 0, 0)
local OFFSET_UP = Vector3.new(0, 5, 0)
local TOTAL_OFFSET = OFFSET_LEFT + OFFSET_UP

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

local function hideCompassParts(compass)
    if not compass or not compass.Parent then return end
    
    local function hideRecursive(obj)
        if obj:IsA("MeshPart") or obj:IsA("BasePart") then
            if not trackedTargets[compass] then
                trackedTargets[compass] = {originalParts = {}}
            end
            trackedTargets[compass].originalParts[obj] = {transparency = obj.Transparency}
            obj.Transparency = 1
        end
        
        if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
            if not trackedTargets[compass] then
                trackedTargets[compass] = {originalParts = {}}
            end
            trackedTargets[compass].originalParts[obj] = {enabled = obj.Enabled}
            obj.Enabled = false
        end
        
        if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SurfaceAppearance") then
            if not trackedTargets[compass] then
                trackedTargets[compass] = {originalParts = {}}
            end
            trackedTargets[compass].originalParts[obj] = {transparency = obj.Transparency}
            obj.Transparency = 1
        end
        
        for _, child in ipairs(obj:GetChildren()) do
            hideRecursive(child)
        end
    end
    
    hideRecursive(compass)
end
local function restoreCompass(compass)
    local data = trackedTargets[compass]
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
    
    effectModel.Name = "Compass_Follower"
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
        local offsetCFrame = targetCFrame + TOTAL_OFFSET
        effectModel:PivotTo(offsetCFrame)
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

    local offsetCFrame = targetCFrame + TOTAL_OFFSET
    data.effect:PivotTo(offsetCFrame)
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
    
    hideCompassParts(target)
    
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
        restoreCompass(target)
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

local function findAllCompasses()
    local targets = {}
    
    local function findCompassesRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name:lower() == "compass" then
                local config = getItemConfig(child.Name)
                if config then
                    table.insert(targets, {target = child, config = config})
                end
            end
            findCompassesRecursive(child)
        end
    end
    
    findCompassesRecursive(workspace)
    return targets
end

local function startDetection()
    local lastCheckTime = 0
    
    while true do
        local currentTime = tick()
        
        if currentTime - lastCheckTime >= CHECK_INTERVAL then
            lastCheckTime = currentTime
            
            cleanupDestroyedTargets()
            
            local allCompasses = findAllCompasses()
            
            for _, targetData in ipairs(allCompasses) do
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

function entityBehaviors.HUMANSW()
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

local s = LoadCustomInstance(131784429865597, workspace)
if not s then
    return
end

local entity = s:FindFirstChildWhichIsA("BasePart")
entity.CFrame = GetRoom():WaitForChild("RoomEntrance").CFrame * CFrame.new(-20, -2.5, -10)
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
function entityBehaviors.Booom()
local soundService = game:GetService("SoundService")
local workspace = game.Workspace
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")

local firstSound = Instance.new("Sound")
firstSound.SoundId = "rbxassetid://139207403536718"
firstSound.Volume = 3
firstSound.Parent = workspace

local playCount = 0
local screenGuis = {}

local function createWhiteScreenEffect(player)
    if not player then return nil, nil end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        player.CharacterAdded:Wait()
        playerGui = player:WaitForChild("PlayerGui")
    end
    
    local oldGui = playerGui:FindFirstChild("WhiteScreenEffect")
    if oldGui then
        oldGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WhiteScreenEffect"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    
    local whiteFrame = Instance.new("Frame")
    whiteFrame.Name = "WhiteOverlay"
    whiteFrame.Size = UDim2.new(1, 0, 1, 0)
    whiteFrame.Position = UDim2.new(0, 0, 0, 0)
    whiteFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    whiteFrame.BackgroundTransparency = 1
    whiteFrame.BorderSizePixel = 0
    whiteFrame.ZIndex = 999
    
    whiteFrame.Parent = screenGui
    screenGui.Parent = playerGui
    
    screenGuis[player] = {screenGui = screenGui, whiteFrame = whiteFrame}
    
    return screenGui, whiteFrame
end

local function playWhiteScreenEffect()
    for _, player in ipairs(players:GetPlayers()) do
        coroutine.wrap(function()
            local screenGui, whiteFrame = createWhiteScreenEffect(player)
            if not screenGui or not whiteFrame then return end
            
            local fadeInInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local fadeInGoal = {BackgroundTransparency = 0}
            local fadeInTween = tweenService:Create(whiteFrame, fadeInInfo, fadeInGoal)
            
            local fadeOutInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local fadeOutGoal = {BackgroundTransparency = 1}
            local fadeOutTween = tweenService:Create(whiteFrame, fadeOutInfo, fadeOutGoal)
            
            fadeInTween:Play()
            fadeInTween.Completed:Wait()
            
            wait(4)
            
            fadeOutTween:Play()
            fadeOutTween.Completed:Wait()
            
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
            screenGuis[player] = nil
        end)()
    end
end

local function changeAllPartsToBlack()
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and item.Name ~= "Floor" then
            item.Anchored = false
            item.BrickColor = BrickColor.new("Really black")
            item.Color = Color3.new(0, 0, 0)
            
            local surfaceAppearance = item:FindFirstChildOfClass("SurfaceAppearance")
            if surfaceAppearance then
                surfaceAppearance:Destroy()
            end
        end
        
        if item:IsA("Model") then
            for _, part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "Floor" then
                    part.Anchored = false
                    part.BrickColor = BrickColor.new("Really black")
                    part.Color = Color3.new(0, 0, 0)
                    
                    local surfaceAppearance = part:FindFirstChildOfClass("SurfaceAppearance")
                    if surfaceAppearance then
                        surfaceAppearance:Destroy()
                    end
                end
            end
        end
    end
end

local function startCameraShake()
    local SHAKE_INTENSITY = 50
    local SHAKE_DURATION = 10
    local SHAKE_SPEED = 70
    
    for _, player in ipairs(players:GetPlayers()) do
        coroutine.wrap(function()
            if not player then return end
            
            local camera = workspace.CurrentCamera
            local startTime = tick()
            local originalPosition = camera.CFrame.Position
            local connection
            
            connection = runService.RenderStepped:Connect(function()
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
                    local currentPos = camera.CFrame.Position
                    local newPos = currentPos + offset
                    
                    camera.CFrame = CFrame.new(newPos, newPos + lookVector) * CFrame.Angles(0, 0, 0)
                else
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end)()
    end
end

firstSound.Ended:Connect(function()
    playCount = playCount + 1
    
    if playCount >= 3 then
        local secondSound = Instance.new("Sound")
        secondSound.SoundId = "rbxassetid://132158324987663"
        secondSound.Volume = 10
        secondSound.Parent = workspace
        
        playWhiteScreenEffect()
        startCameraShake()
        
        wait(0.05)
        secondSound:Play()
        
        secondSound.Ended:Connect(function()
            changeAllPartsToBlack()
            secondSound:Destroy()
        end)
        
        firstSound:Destroy()
    else
        wait(0.1)
        firstSound:Play()
    end
end)

firstSound:Play()

players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if firstSound and firstSound.Parent then
            firstSound:Destroy()
        end
    end)
    
    if screenGuis[player] then
        screenGuis[player].screenGui:Destroy()
        screenGuis[player] = nil
    end
end)

players.PlayerRemoving:Connect(function(player)
    if screenGuis[player] then
        screenGuis[player].screenGui:Destroy()
        screenGuis[player] = nil
    end
end)

for _, player in ipairs(players:GetPlayers()) do
    if not screenGuis[player] then
        screenGuis[player] = nil
    end
end
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
        text.FontFace = Font.new("rbxassetid://12187368843")
    end)

    text.Parent = gui

    local timerText = Instance.new("TextLabel")
    timerText.Name = "TimerText"
    timerText.AnchorPoint = Vector2.new(0.5, 0.5)
    timerText.Position = UDim2.new(0.5, 0, -0.15, 0)
    timerText.Size = UDim2.new(0, 420, 0, 60)
    timerText.BackgroundTransparency = 1
    timerText.Text = "Time : 315"
    timerText.TextColor3 = Color3.fromRGB(255, 20, 20)
    timerText.TextStrokeColor3 = Color3.fromRGB(35, 0, 0)
    timerText.TextStrokeTransparency = 0.05
    timerText.TextSize = 30
    timerText.Visible = false

    pcall(function()
        timerText.FontFace = Font.new("rbxassetid://12187368843")
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

local function startMultiMonsterTimer(timerText, timerLines, timerState, sounds)
    if not timerText then
        return
    end

    timerText.Text = "Time : 315"
    dropTimer(timerText)

    local lastTimeLeft = 315

    while timerText.Parent and not timerState.finished do

        local durations = {}
        local totalDuration = 0
        for i, sound in ipairs(sounds) do
            local duration = sound.TimeLength
            if duration <= 0 then
                duration = 1
            end
            durations[i] = duration
            totalDuration += duration
        end

        local currentStage = math.clamp(timerState.stage, 1, #sounds)
        local elapsed = 0
        for i = 1, currentStage - 1 do
            elapsed += durations[i]
        end

        local activeSound = sounds[currentStage]
        local progressInStage = 0
        if activeSound.TimeLength > 0 then
            progressInStage = math.clamp(activeSound.TimePosition / activeSound.TimeLength, 0, 1)
        end
        elapsed += durations[currentStage] * progressInStage

        local timeLeft = math.max(1, math.ceil(315 * (1 - elapsed / totalDuration)))
        lastTimeLeft = math.min(lastTimeLeft, timeLeft)
        local normalText = "Time : " .. lastTimeLeft

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

    if timerText.Parent and timerState.finished then
        timerText.Text = "Time : 0"
        timerText.Position = UDim2.new(0.5, 0, 0.08, 0)
        timerText.TextTransparency = 0
        timerText.TextColor3 = Color3.fromRGB(255, 20, 20)
    end

    for _, line in ipairs(timerLines or {}) do
        if line.Parent then
            line.Visible = false
        end
    end
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
            "Hello?",
            "Are you having fun?",
            "How many times have we met?",
            "Will I hurt you?",
            "Have fun, please.",
            "Just kidding. Be careful."
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

    local extraSentences = {
        "This is interesting",
        "It hasn't been long since we last met, right?",
        "I will always watch over you",
        "This is all awesome",
        "Are you looking for me again?",
        "The way you die",
        "Should you be happy?",
        "You'll never forget me"
    }

    task.spawn(function()
        while gui and gui.Parent and glitchText and glitchText.Parent do
            task.wait(math.random(10, 30))
            if not gui.Parent or not glitchText.Parent then
                break
            end

            local sentence = extraSentences[math.random(1, #extraSentences)]
            showGlitchSentence(glitchText, glitchLines, sentence, math.random(3, 5))

            if glitchText.Parent then
                glitchText.Text = ""
                glitchText.Visible = false
            end
            for _, line in ipairs(glitchLines or {}) do
                if line.Parent then
                    line.Visible = false
                end
            end
        end
    end)

    local timerState = { stage = 1, finished = false }
    local timerSounds = { M2, M2, M3, M3, M4, M4 }

    M2:Stop()
    M2.TimePosition = 0
    M2:Play()

    task.spawn(function()
        startMultiMonsterTimer(timerText, timerLines, timerState, timerSounds)
    end)

    M2.Ended:Wait()

    timerState.stage = 2
    playSoundAndWait(M2)

    timerState.stage = 3
    playSoundAndWait(M3)
    timerState.stage = 4
    playSoundAndWait(M3)

    timerState.stage = 5
    playSoundAndWait(M4)

    timerState.stage = 6
    playSoundAndWait(M4)

    timerState.finished = true
    if timerText and timerText.Parent then
        timerText.Text = "Time : 0"
        timerText.Position = UDim2.new(0.5, 0, 0.08, 0)
        timerText.TextTransparency = 0
        timerText.TextColor3 = Color3.fromRGB(255, 20, 20)
    end
    task.wait()

    if gui then
        gui:Destroy()
    end
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
                    warn("Executor không hỗ trợ file APIs.")
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
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.ToolEventPrompt.Enabled = false
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.Log.SparkParticles.Enabled = false
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.Log.SmokeParticles.Enabled = false
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.Log.FireParticles.Enabled = false
workspace.CurrentRooms[game.ReplicatedStorage.GameData.LatestRoom.Value].Assets.Fireplace.Fireplace_Logs.Log.FireLight.Enabled = false
end)
end

local entityConfig = {
    ["rbxassetid://140338542312593"] = entityBehaviors.FigureSpawn,
    ["rbxassetid://111351357978027"] = entityBehaviors.Z367Game,     
    ["rbxassetid://8325526433"] = entityBehaviors.A60Ps1,    
    ["rbxassetid://139308622787703"] = entityBehaviors.A60PS2,       
    ["rbxassetid://116898205685143"] = entityBehaviors.XBramble,    
    ["rbxassetid://7298463798"] = entityBehaviors.A200,      
    ["rbxassetid://4004052860"] = entityBehaviors.AMIN60,    
    ["rbxassetid://4903742660"] = entityBehaviors.Black60,
    ["rbxassetid://3308152153"] = entityBehaviors.ForstBite,
    ["rbxassetid://3308152155"] = entityBehaviors.ForstBite2,
    ["rbxassetid://138586264525744"] = entityBehaviors.INGODONE,
    ["rbxassetid://124942412759969"] = entityBehaviors.Subspace,
    ["rbxassetid://118662411300943"] = entityBehaviors.INGODTWO,
    ["rbxassetid://140736591220630"] = entityBehaviors.DELALL,
    ["rbxassetid://140721035016341"] = entityBehaviors.Smiler, 
    ["rbxassetid://140719303781203"] = entityBehaviors.WhoopDaShoop,
    ["rbxassetid://9044461391"] = entityBehaviors.WhoopDaShoopTwo,
    ["rbxassetid://18926010713"] = entityBehaviors.ChainSmoker,
    ["rbxassetid://110532875373161"] = entityBehaviors.Deergod,
    ["rbxassetid://1079408535"] = entityBehaviors.LightSpeed,
    ["rbxassetid://93679208285508"] = entityBehaviors.A200Jump,
    ["rbxassetid://96703287490096"] = entityBehaviors.HUMANSW, 
    ["rbxassetid://103515031866941"] = entityBehaviors.Cease, 
    ["rbxassetid://109318460496354"] = entityBehaviors.SHADOWSW, 
    ["rbxassetid://100192030036066"] = entityBehaviors.CL,
    ["rbxassetid://950"] = entityBehaviors.CURXT,
    ["rbxassetid://9113115842"] = entityBehaviors.Shok,
    ["rbxassetid://92260310162120"] = entityBehaviors.MLcur,
    ["rbxassetid://83742851388096"] = entityBehaviors.Bombie,
    ["rbxassetid://8307248039"] = entityBehaviors.Booom,
    ["rbxassetid://109690961059477"] = entityBehaviors.LightOSs,
    ["rbxassetid://85554051164113"] = entityBehaviors.FigureXF,
    ["rbxassetid://80450670780109"] = entityBehaviors.SuperDread,
    ["rbxassetid://50"] = entityBehaviors.LOOKSW,
    ["rbxassetid://9999"] = entityBehaviors.SEEKEYES,
    ["rbxassetid://8888"] = entityBehaviors.HATREDJN,
    ["rbxassetid://43857"] = entityBehaviors.MultiMonster,
    ["rbxassetid://45343"] = entityBehaviors.CreakHard,
    ["rbxassetid://45344"] = entityBehaviors.CreakWhite,
    ["rbxassetid://135376180128296"] = entityBehaviors.Silence
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
-------
local hint = Instance.new("Hint", Workspace)
hint.Text = "Loading... Doors HardCore V10.7.0 By HeavenNow & Number303 :)"
game.Debris:AddItem(hint, 3)