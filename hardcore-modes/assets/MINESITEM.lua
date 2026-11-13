if workspace:FindFirstChild("HardcoremUSIC") then
    return
end
local marker = Instance.new("BoolValue")
marker.Name = "HardcoremUSIC"
marker.Value = true
marker.Parent = workspace
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CUSTOM_SEEK_MODEL_ID = "rbxassetid://91573224733706"
local TRUE_SEEK_MODEL_ID = "rbxassetid://130430799749614"

if Workspace:FindFirstChild("hardcoreInit") then
	return
else
	local hardcoreInit = Instance.new("BoolValue", Workspace)
	hardcoreInit.Name = "hardcoreInit"
end

local isReplacingSeek = false
local currentCustomSeek = nil
local latestSeekClone = nil
local thirdSeekModel = nil
local thirdSeekFollowConnection = nil
local thirdSeekAnimConnection = nil
local musicAssets = {}
local endMusicAssets = {}
local otherMusicAssets = {}
local endMusicPlaying = false
local endMusicConnection = nil
local trueSeekModel = nil
local trueSeekFollowConnection = nil
local room51Models = {}
local room51Connections = {}
local room51HeartbeatConnection = nil
local room51Sound1502 = nil
local room51Sound1502Connection = nil

local isCheckingEndSound = false
local isCheckingSoundOpen = false
local isCheckingBang1 = false
local previousEndSoundState = false
local previousSoundOpenState = false
local previousBang1State = false
local soundOpenPlayCount = 0

local musicUrls = {
	N1 = {url = "https://github.com/Zero0Star/RipperNewSound/blob/master/Normal.mp3?raw=true", target = "Normal"},
	I1 = {url = "https://github.com/Zero0Star/RipperNewSound/blob/master/Intro.mp3?raw=true", target = "Intro"},
	H1 = {url = "https://github.com/Zero0Star/RipperNewSound/blob/master/Hype.mp3?raw=true", target = "Hype"},
	E1 = {url = "https://github.com/Zero0Star/RipperNewSound/blob/master/End.mp3?raw=true", target = "End"},
	C1 = {url = "https://github.com/Zero0Star/RipperNewSound/blob/master/Cutscene.mp3?raw=true", target = "Cutscene"},
	C2 = {url = "https://github.com/Zero0Star/RipperNewSound/blob/master/Chill.mp3?raw=true", target = "Chill"}
}

local endMusicUrls = {
	ED1 = "https://github.com/Zero0Star/RipperNewSound/blob/master/End1.mp3?raw=true",
	ED2 = "https://github.com/Zero0Star/RipperNewSound/blob/master/End2.mp3?raw=true",
	ED3 = "https://github.com/Zero0Star/RipperNewSound/blob/master/End3.mp3?raw=true"
}

local otherMusicUrls = {
	GE = "https://github.com/Zero0Star/RipperNewSound/blob/master/GrumbleEnd.mp3?raw=true",
	_1501 = "https://github.com/Zero0Star/RipperNewSound/blob/master/150One.mp3?raw=true",
	_1502 = "https://github.com/Zero0Star/RipperNewSound/blob/master/150Two.mp3?raw=true",
	_1503 = "https://github.com/Zero0Star/RipperNewSound/blob/master/150Three.mp3?raw=true",
	_start = "https://github.com/Zero0Star/RipperNewSound/blob/master/Start.mp3?raw=true"
}

local animConfigs = {
	first = {
		raise = "rbxassetid://73347122874595",
		run = "rbxassetid://10729087054"
	},
	second = {
		raise = "rbxassetid://128243826423807",
		run = "rbxassetid://10729087054"
	},
	third = {
		raise = "rbxassetid://117445669558521"
	}
}

local currentStage = "first"

local function loadAndReplaceSound(name, info)
	spawn(function()
		pcall(function()
			local audioData = game:HttpGet(info.url)
			writefile(name .. ".mp3", audioData)
			local customAsset = (getcustomasset or getsynasset)(name .. ".mp3")
			musicAssets[name] = customAsset
			while true do
				wait(1)
				if ReplicatedStorage:FindFirstChild("FloorReplicated") then
					local seekMusicFolder = ReplicatedStorage.FloorReplicated:FindFirstChild("SeekMusic")
					if seekMusicFolder then
						local targetSound = seekMusicFolder:FindFirstChild(info.target)
						if targetSound then
							targetSound.SoundId = customAsset
							break
						end
					end
				end
			end
		end)
	end)
end

local function loadEndMusics()
	for name, url in pairs(endMusicUrls) do
		spawn(function()
			pcall(function()
				local audioData = game:HttpGet(url)
				writefile(name .. ".mp3", audioData)
				local customAsset = (getcustomasset or getsynasset)(name .. ".mp3")
				endMusicAssets[name] = customAsset
				
				local sound = Instance.new("Sound")
				sound.SoundId = customAsset
				sound.Volume = 1
				sound.Name = name
				sound.Parent = Workspace
			end)
		end)
	end
end

local function loadOtherAudio()
	for name, url in pairs(otherMusicUrls) do
		spawn(function()
			pcall(function()
				local audioData = game:HttpGet(url)
				writefile(name .. ".mp3", audioData)
				local customAsset = (getcustomasset or getsynasset)(name .. ".mp3")
				otherMusicAssets[name] = customAsset
			end)
		end)
	end
end

local function modifyEndGrumble()
	spawn(function()
		pcall(function()
			while true do
				wait(1)
				if ReplicatedStorage:FindFirstChild("FloorReplicated") then
					local seekMusicFolder = ReplicatedStorage.FloorReplicated:FindFirstChild("SeekMusic")
					if seekMusicFolder then
						local endGrumbleSound = seekMusicFolder:FindFirstChild("EndGrumble")
						if endGrumbleSound and endGrumbleSound:IsA("Sound") then
							endGrumbleSound.SoundId = "rbxassetid://17735373972"
							break
						end
					end
				end
			end
		end)
	end)
end

local function loadAllAudio()
	spawn(function()
		while not otherMusicAssets["_start"] do
			wait(1)
		end
		
		local startSound = Instance.new("Sound")
		startSound.SoundId = otherMusicAssets["_start"]
		startSound.Volume = 0.8
		startSound.Name = "start"
		startSound.Parent = Workspace
		
		spawn(function()
			spawn(function()
				require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("Hardcore Mode MinesRemake.",true)
				wait(2)
				require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("This took us quite a loooong time.",true)
				wait(2)
				require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("Wish you have a fun trip!",true)
			end)
		end)
		
		startSound:Play()
		
		startSound.Ended:Wait()
		startSound:Destroy()
	end)
	
	modifyEndGrumble()
	
	for name, info in pairs(musicUrls) do
		loadAndReplaceSound(name, info)
	end
	loadEndMusics()
	loadOtherAudio()
end

local function cleanupOldSeekModel()
	if currentCustomSeek and currentCustomSeek.Parent then
		currentCustomSeek:Destroy()
		currentCustomSeek = nil
	end
	isReplacingSeek = false
end

local function cleanupThirdSeekModel()
	if thirdSeekModel and thirdSeekModel.Parent then
		thirdSeekModel:Destroy()
		thirdSeekModel = nil
	end
	
	if thirdSeekFollowConnection then
		thirdSeekFollowConnection:Disconnect()
		thirdSeekFollowConnection = nil
	end
	
	if thirdSeekAnimConnection then
		thirdSeekAnimConnection:Disconnect()
		thirdSeekAnimConnection = nil
	end
end

local function cleanupRoom51Models()
	if room51HeartbeatConnection then
		room51HeartbeatConnection:Disconnect()
		room51HeartbeatConnection = nil
	end
	
	for _, conn in ipairs(room51Connections) do
		if conn then
			conn:Disconnect()
		end
	end
	room51Connections = {}
	
	if room51Sound1502 then
		room51Sound1502:Stop()
		room51Sound1502:Destroy()
		room51Sound1502 = nil
	end
	
	if room51Sound1502Connection then
		room51Sound1502Connection:Disconnect()
		room51Sound1502Connection = nil
	end
	
	for _, data in ipairs(room51Models) do
		if data.model and data.model.Parent then
			data.model:Destroy()
		end
	end
	room51Models = {}
end

local function setupTrueSeekModel(room100)
	if trueSeekModel and trueSeekModel.Parent then
		trueSeekModel:Destroy()
	end
	
	if trueSeekFollowConnection then
		trueSeekFollowConnection:Disconnect()
		trueSeekFollowConnection = nil
	end
	
	local success, model = pcall(function()
		return game:GetObjects(TRUE_SEEK_MODEL_ID)[1]
	end)
	
	if success and model then
		trueSeekModel = model
		
		if not trueSeekModel.PrimaryPart then
			local humanoidRootPart = trueSeekModel:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				trueSeekModel.PrimaryPart = humanoidRootPart
			else
				for _, part in pairs(trueSeekModel:GetDescendants()) do
					if part:IsA("BasePart") then
						trueSeekModel.PrimaryPart = part
						break
					end
				end
			end
		end
		
		if trueSeekModel.PrimaryPart then
			trueSeekModel.PrimaryPart.Anchored = true
		end
		
		trueSeekModel.Parent = Workspace
		
		local damHandler = room100:WaitForChild("_DamHandler", 5)
		if damHandler then
			local trueSeekStuff = damHandler:WaitForChild("TrueSeekStuff", 5)
			if trueSeekStuff then
				local trueSeek = trueSeekStuff:WaitForChild("TrueSeek", 5)
				if trueSeek then
					if trueSeek:IsA("Model") then
						local targetPart
						for _, child in pairs(trueSeek:GetDescendants()) do
							if child:IsA("MeshPart") or child:IsA("BasePart") then
								targetPart = child
								break
							end
						end
						
						if targetPart then
							for _, child in pairs(trueSeek:GetDescendants()) do
								if child:IsA("BasePart") or child:IsA("MeshPart") or child:IsA("Part") or child:IsA("UnionOperation") then
									child.Transparency = 1
								elseif child:IsA("Decal") then
									child.Transparency = 1
								elseif child:IsA("ParticleEmitter") then
									child.Enabled = false
								end
							end
							
							trueSeekFollowConnection = RunService.Heartbeat:Connect(function()
								if trueSeekModel and trueSeekModel.Parent and trueSeek and trueSeek.Parent and trueSeekModel.PrimaryPart and targetPart then
									trueSeekModel:SetPrimaryPartCFrame(targetPart.CFrame)
								end
							end)
						else
							local followPart = Instance.new("Part")
							followPart.Name = "TrueSeekFollowPart"
							followPart.Size = Vector3.new(2, 2, 2)
							followPart.Transparency = 1
							followPart.CanCollide = false
							followPart.Anchored = true
							followPart.Parent = trueSeek
							
							followPart.CFrame = trueSeek:GetPivot()
							
							trueSeekFollowConnection = RunService.Heartbeat:Connect(function()
								if trueSeekModel and trueSeekModel.Parent and trueSeek and trueSeek.Parent and trueSeekModel.PrimaryPart and followPart then
									trueSeekModel:SetPrimaryPartCFrame(followPart.CFrame)
								end
							end)
						end
					elseif trueSeek:IsA("MeshPart") or trueSeek:IsA("BasePart") then
						trueSeek.Transparency = 1
						
						trueSeekFollowConnection = RunService.Heartbeat:Connect(function()
							if trueSeekModel and trueSeekModel.Parent and trueSeek and trueSeek.Parent and trueSeekModel.PrimaryPart then
								trueSeekModel:SetPrimaryPartCFrame(trueSeek.CFrame)
							end
						end)
					end
				end
			end
		end
	end
end

local function setupThirdSeekChase(room100)
	local damHandler = room100:WaitForChild("_DamHandler", 5)
	if not damHandler then
		return
	end
	
	local outsideCutscene = damHandler:WaitForChild("_OutsideCutscene", 5)
	if not outsideCutscene then
		return
	end
	
	local originalRig = outsideCutscene:WaitForChild("_SeekRig", 5)
	if not originalRig then
		return
	end
	
	local success, model = pcall(function()
		return game:GetObjects(CUSTOM_SEEK_MODEL_ID)[1]
	end)
	
	if not success or not model then
		return
	end
	
	cleanupThirdSeekModel()
	
	thirdSeekModel = model
	thirdSeekModel.Name = "seek3"
	
	for _, child in pairs(thirdSeekModel.Figure:GetChildren()) do
		if child:IsA("Sound") then
			child:Stop()
		end
	end
	
	thirdSeekModel.Parent = Workspace
	
	local customRig = thirdSeekModel:FindFirstChild("SeekRig")
	if not customRig then
		thirdSeekModel:Destroy()
		thirdSeekModel = nil
		return
	end
	
	local root = customRig:FindFirstChild("Root")
	if not root then
		thirdSeekModel:Destroy()
		thirdSeekModel = nil
		return
	end
	
	root.Anchored = true
	
	local originalRoot = originalRig:WaitForChild("Root", 5)
	if not originalRoot then
		return
	end
	
	thirdSeekFollowConnection = RunService.Heartbeat:Connect(function()
		if not originalRig or not originalRig.Parent or not thirdSeekModel or not thirdSeekModel.Parent then
			if thirdSeekFollowConnection then
				thirdSeekFollowConnection:Disconnect()
			end
			return
		end
		
		if originalRoot and root then
			root.CFrame = originalRoot.CFrame
		end
		
		for _, part in pairs(originalRig:GetChildren()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
	end)
	
	local autoAnimate = originalRig:WaitForChild("AutoAnimate", 5)
	if autoAnimate then
		local animator = autoAnimate:WaitForChild("Animator", 5)
		if animator and animator:IsA("Animator") then
			thirdSeekAnimConnection = animator.AnimationPlayed:Connect(function(animationTrack)
				if animationTrack.Animation.AnimationId == "rbxassetid://117445669558521" then
					if thirdSeekAnimConnection then
						thirdSeekAnimConnection:Disconnect()
						thirdSeekAnimConnection = nil
					end
					
					local config = animConfigs.third
					local animController = customRig.AnimationController
					
					if customRig:FindFirstChild("AnimRaise") then
						customRig.AnimRaise.AnimationId = config.raise
						local raiseAnim = animController:LoadAnimation(customRig.AnimRaise)
						raiseAnim:Play()
						
						spawn(function()
							raiseAnim.Stopped:Wait()
						end)
					end
				end
			end)
		end
	end
	
	originalRig.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			cleanupThirdSeekModel()
		end
	end)
end

local function setupEndSequence()
	spawn(function()
		while true do
			wait(1)
			local currentRooms = Workspace:FindFirstChild("CurrentRooms")
			if currentRooms then
				local room100 = currentRooms:FindFirstChild("100")
				if room100 then
					setupTrueSeekModel(room100)
					setupThirdSeekChase(room100)
					
					ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
					
					local damHandler = room100:FindFirstChild("_DamHandler")
					if damHandler then
						local musicFolder = damHandler:FindFirstChild("Music")
						if musicFolder then
							for _, sound in pairs(musicFolder:GetChildren()) do
								if sound:IsA("Sound") then
									sound.Volume = 0.1
								end
							end
						end
					end
					
					local damHandler = room100:FindFirstChild("_DamHandler")
					if damHandler then
						local musicFolder = damHandler:FindFirstChild("Music")
						if musicFolder then
							local endSound = musicFolder:FindFirstChild("End")
							if endSound and endSound:IsA("Sound") then
								local endHasPlayed = false
								previousEndSoundState = endSound.IsPlaying
								
								if endSound.IsPlaying then
									endHasPlayed = true
								end
								
								local ed1Sound = Workspace:FindFirstChild("ED1")
								if ed1Sound and ed1Sound:IsA("Sound") then
									ed1Sound:Play()
									
									if not endHasPlayed then
										spawn(function()
											local startTime = tick()
											local maxCheckTime = 300
											
											while tick() - startTime < maxCheckTime and ed1Sound.IsPlaying and not endHasPlayed do
												local currentState = endSound.IsPlaying
												
												if not previousEndSoundState and currentState then
													endHasPlayed = true
													break
												end
												
												previousEndSoundState = currentState
												wait(0.1)
											end
										end)
									end
									
									ed1Sound.Ended:Wait()
									ed1Sound:Destroy()
								end
								
								if endHasPlayed then
									local ed3Sound = Workspace:FindFirstChild("ED3")
									if ed3Sound and ed3Sound:IsA("Sound") then
										ed3Sound:Play()
										ed3Sound.Ended:Wait()
										ed3Sound:Destroy()
									end
								else
									local ed2Sound = Workspace:FindFirstChild("ED2")
									if ed2Sound and ed2Sound:IsA("Sound") then
										ed2Sound.Looped = true
										ed2Sound:Play()
										
										isCheckingEndSound = true
										
										spawn(function()
											while isCheckingEndSound and endSound and endSound.Parent do
												local currentState = endSound.IsPlaying
												
												if not previousEndSoundState and currentState then
													isCheckingEndSound = false
													
													ed2Sound:Stop()
													ed2Sound:Destroy()
													
													local ed3Sound = Workspace:FindFirstChild("ED3")
													if ed3Sound and ed3Sound:IsA("Sound") then
														ed3Sound:Play()
														ed3Sound.Ended:Wait()
														ed3Sound:Destroy()
													end
													
													break
												end
												
												previousEndSoundState = currentState
												wait(0.1)
											end
										end)
									end
								end
							end
						end
					end
					
					break
				end
			end
		end
	end)
end

local function setupRoom49Listener()
	spawn(function()
		while true do
			wait(1)
			local currentRooms = Workspace:FindFirstChild("CurrentRooms")
			if currentRooms then
				local room49 = currentRooms:FindFirstChild("49")
				if room49 then
					local deletedCount = 0
					local maxDeleteCount = 2
					
					local targetRoom49 = room49
					local isListening = true
					
					local roomRemovedConnection
					roomRemovedConnection = targetRoom49.AncestryChanged:Connect(function(_, parent)
						if parent == nil then
							isListening = false
							if roomRemovedConnection then
								roomRemovedConnection:Disconnect()
							end
						end
					end)
					
					while isListening and targetRoom49 and targetRoom49.Parent do
						if deletedCount >= maxDeleteCount then
							break
						end
						
						local seekClones = Workspace:FindFirstChild("SeekMovingNewClone")
						if seekClones then
							local function searchForEndGrumble(object)
								for _, child in pairs(object:GetChildren()) do
									if child:IsA("Sound") and child.Name == "EndGrumble" then
										child:Destroy()
										deletedCount = deletedCount + 1
									end
									searchForEndGrumble(child)
								end
							end
							
							searchForEndGrumble(seekClones)
						end
						
						local room50 = currentRooms:FindFirstChild("50")
						if room50 then
							local function searchForEndGrumbleInRoom50(object)
								for _, child in pairs(object:GetChildren()) do
									if child:IsA("Sound") and child.Name == "EndGrumble" then
										child:Destroy()
										deletedCount = deletedCount + 1
									end
									searchForEndGrumbleInRoom50(child)
								end
							end
							
							searchForEndGrumbleInRoom50(room50)
						end
						
						wait(0.5)
					end
					
					break
				end
			end
		end
	end)
end

local function setupGEAudio()
	spawn(function()
		while true do
			wait(1)
			local currentRooms = Workspace:FindFirstChild("CurrentRooms")
			if currentRooms then
				local room49 = currentRooms:FindFirstChild("49")
				if room49 then
					ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
					
					while not otherMusicAssets["GE"] do
						wait(1)
					end
					
					local sound = Instance.new("Sound")
					sound.SoundId = otherMusicAssets["GE"]
					sound.Volume = 1.5
					sound.Name = "GE"
					sound.Parent = Workspace
					
					sound:Play()
					
					sound.Ended:Wait()
					
					sound:Destroy()
					
					break
				end
			end
		end
	end)
end

local function setupRoom51Listener()
	spawn(function()
		while true do
			wait(1)
			local currentRooms = Workspace:FindFirstChild("CurrentRooms")
			if currentRooms then
				local room51 = currentRooms:FindFirstChild("51")
				if room51 then
					while not otherMusicAssets["_1501"] or not otherMusicAssets["_1502"] or not otherMusicAssets["_1503"] do
						wait(1)
					end
					
					local room50 = currentRooms:FindFirstChild("50")
					if not room50 then
						return
					end
					
					local nestHandler = room50:WaitForChild("_NestHandler", 5)
					if not nestHandler then
						return
					end
					
					local minesGateFront = nestHandler:WaitForChild("_MinesGateFront", 5)
					if not minesGateFront then
						return
					end
					
					local frontGate = minesGateFront:WaitForChild("FrontGate", 5)
					if not frontGate or not frontGate:IsA("MeshPart") then
						return
					end
					
					local soundOpen = frontGate:FindFirstChild("SoundOpen")
					if not soundOpen or not soundOpen:IsA("Sound") or soundOpen.SoundId ~= "rbxassetid://17750116436" then
						return
					end
					
					local bang1Sound = frontGate:FindFirstChild("Bang1")
					if not bang1Sound or not bang1Sound:IsA("Sound") or bang1Sound.SoundId ~= "rbxassetid://70984289818399" then
						return
					end
					
					previousSoundOpenState = soundOpen.IsPlaying
					previousBang1State = bang1Sound.IsPlaying
					isCheckingSoundOpen = true
					soundOpenPlayCount = 0
					
					spawn(function()
						while isCheckingSoundOpen and soundOpen and soundOpen.Parent do
							local currentSoundOpenState = soundOpen.IsPlaying
							
							if not previousSoundOpenState and currentSoundOpenState then
								soundOpenPlayCount = soundOpenPlayCount + 1
								
								if soundOpenPlayCount == 2 then
									isCheckingSoundOpen = false
									
									spawn(function()
										cleanupRoom51Models()
										
										local function loadModel(id)
											local success, models = pcall(function()
												return game:GetObjects("rbxassetid://" .. tostring(id))
											end)
											if success and #models > 0 then
												return models[1]:Clone()
											end
											return nil
										end
										
										local targetModel = workspace.CurrentRooms:WaitForChild("50", 5)
										if not targetModel then
											return
										end
										
										local nestHandler = targetModel:WaitForChild("_NestHandler", 5)
										if not nestHandler then
											return
										end
										
										local grumblesFolder = nestHandler:WaitForChild("Grumbles", 5)
										if not grumblesFolder then
											return
										end
										
										local grumbos = {}
										
										for _, child in ipairs(grumblesFolder:GetChildren()) do
											if child.Name == "Grumbo" then
												table.insert(grumbos, child)
											end
										end
										
										if #grumbos == 0 then
											return
										end
										
										local spawnedModels = {}
										
										for _, grumbo in ipairs(grumbos) do
											for _, part in ipairs(grumbo:GetDescendants()) do
												if part:IsA("MeshPart") or part:IsA("Part") then
													part.Transparency = 1
												end
											end
											
											local model = loadModel(78138776025222)
											if model then
												model.Parent = Workspace
												table.insert(spawnedModels, {model = model, target = grumbo})
											end
										end
										
										if #spawnedModels == 0 then
											return
										end
										
										local function playAnimation(model)
											local mysteriousGrumble = model
											local animationController = mysteriousGrumble:FindFirstChild("AnimationController")
											if animationController then
												local animator = animationController:FindFirstChild("Animator")
												if not animator then
													animator = Instance.new("Animator")
													animator.Parent = animationController
												end
												if animator then
													local animation = Instance.new("Animation")
													animation.AnimationId = "rbxassetid://18687934629"
													local success, errorMsg = pcall(function()
														local track = animator:LoadAnimation(animation)
														if track then
															track:Play()
														end
													end)
												end
											end
										end
										
										for _, data in ipairs(spawnedModels) do
											spawn(function()
												wait(0.5)
												playAnimation(data.model)
											end)
										end
										
										require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).titlelocation("Break Out Prison",true)
										
										local heartbeatConnection = RunService.Heartbeat:Connect(function()
											for _, data in ipairs(spawnedModels) do
												if data.model and data.model.PrimaryPart and data.model.Parent and
												data.target and data.target.PrimaryPart and data.target.Parent then
													data.model:SetPrimaryPartCFrame(data.target:GetPrimaryPartCFrame())
												end
											end
										end)
										
										table.insert(room51Connections, heartbeatConnection)
										room51Models = spawnedModels
										room51HeartbeatConnection = heartbeatConnection
									end)
									
									spawn(function()
										if nestHandler then
											local ambienceFolder = nestHandler:FindFirstChild("Ambience")
											if ambienceFolder then
												local intenseSound = ambienceFolder:FindFirstChild("Intense")
												if intenseSound and intenseSound:IsA("Sound") then
													intenseSound:Destroy()
												end
												
												local normalFolder = ambienceFolder:FindFirstChild("Normal")
												if normalFolder then
													for i = 1, 5 do
														local soundName = "Ambience" .. tostring(i)
														local ambientSound = normalFolder:FindFirstChild(soundName)
														if ambientSound and ambientSound:IsA("Sound") then
															ambientSound:Destroy()
														end
													end
												end
											end
										end
									end)
									
									local sound1501 = Instance.new("Sound")
									sound1501.SoundId = otherMusicAssets["_1501"]
									sound1501.Volume = 1.5
									sound1501.Name = "1501"
									sound1501.Parent = Workspace
									sound1501:Play()
									
									sound1501.Ended:Wait()
									sound1501:Destroy()
									
									local sound1502 = Instance.new("Sound")
									sound1502.SoundId = otherMusicAssets["_1502"]
									sound1502.Volume = 1.5
									sound1502.Looped = true
									sound1502.Name = "1502"
									sound1502.Parent = Workspace
									sound1502:Play()
									
									room51Sound1502 = sound1502
									
									isCheckingBang1 = true
									previousBang1State = bang1Sound.IsPlaying
									
									spawn(function()
										while isCheckingBang1 and bang1Sound and bang1Sound.Parent do
											local currentBang1State = bang1Sound.IsPlaying
											
											if not previousBang1State and currentBang1State then
												isCheckingBang1 = false
												
												if sound1502 and sound1502.Parent then
													sound1502:Stop()
													sound1502:Destroy()
												end
												
												local sound1503 = Instance.new("Sound")
												sound1503.SoundId = otherMusicAssets["_1503"]
												sound1503.Volume = 1.5
												sound1503.Name = "1503"
												sound1503.Parent = Workspace
												sound1503:Play()
												
												sound1503.Ended:Wait()
												sound1503:Destroy()
											end
											
											previousBang1State = currentBang1State
											wait(0.1)
										end
									end)
								end
							end
							
							previousSoundOpenState = currentSoundOpenState
							wait(0.1)
						end
					end)
					
					local roomRemovedConnection
					roomRemovedConnection = room51.AncestryChanged:Connect(function(_, parent)
						if parent == nil then
							isCheckingSoundOpen = false
							isCheckingBang1 = false
							cleanupRoom51Models()
							soundOpenPlayCount = 0
							
							if roomRemovedConnection then
								roomRemovedConnection:Disconnect()
							end
						end
					end)
					
					break
				end
			end
		end
	end)
end

local function replaceSeekModel()
	local function checkAndReplace()
		wait(3.5)
		if isReplacingSeek then
			return
		end
		if not Workspace:FindFirstChild("SeekMovingNewClone") then
			return
		end
		local originalSeek = Workspace.SeekMovingNewClone
		if latestSeekClone and latestSeekClone == originalSeek then
			return
		end
		latestSeekClone = originalSeek
		isReplacingSeek = true
		cleanupOldSeekModel()
		local originalRig = originalSeek:FindFirstChild("SeekRig")
		if not originalRig then
			isReplacingSeek = false
			return
		end
		local customSeekModel
		local success, err = pcall(function()
			customSeekModel = game:GetObjects(CUSTOM_SEEK_MODEL_ID)[1]
		end)
		if not success or not customSeekModel then
			isReplacingSeek = false
			return
		end
		customSeekModel.Name = "seek2"
		for _, child in pairs(customSeekModel.Figure:GetChildren()) do
			if child:IsA("Sound") then
				child:Stop()
			end
		end
		if originalRig.Head:FindFirstChild("Eye") then
			originalRig.Head.Eye:Destroy()
		end
		if originalRig.Head:FindFirstChild("Black") then
			originalRig.Head.Black:Destroy()
		end
		for _, child in pairs(originalRig:GetDescendants()) do
			if child.Name == "StringCheese" then
				child:Destroy()
			end
		end
		customSeekModel.Parent = Workspace
		currentCustomSeek = customSeekModel
		local customRig = customSeekModel:FindFirstChild("SeekRig")
		if not customRig then
			cleanupOldSeekModel()
			return
		end
		if not customRig:FindFirstChild("Root") then
			cleanupOldSeekModel()
			return
		end
		customRig:FindFirstChild("Root").Anchored = true
		local followConnection
		followConnection = RunService.Heartbeat:Connect(function()
			if not originalSeek or not originalSeek.Parent or not customSeekModel or not customSeekModel.Parent then
				if followConnection then
					followConnection:Disconnect()
				end
				return
			end
			if originalRig:FindFirstChild("Root") and customRig:FindFirstChild("Root") then
				customRig:FindFirstChild("Root").CFrame = originalRig:FindFirstChild("Root").CFrame
			end
			for _, sound in pairs(originalSeek.Figure:GetChildren()) do
				if sound:IsA("Sound") then
					sound:Stop()
				end
			end
			for _, part in pairs(originalRig:GetChildren()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
		end)
		if customRig then
			local animController = customRig.AnimationController
			local animator = originalRig.AnimationController:WaitForChild("Animator")
			local config = animConfigs[currentStage]
			
			local function playCustomAnimations()
				if customRig:FindFirstChild("AnimRaise") then
					customRig.AnimRaise.AnimationId = config.raise
				end
				if customRig:FindFirstChild("AnimRun") then
					customRig.AnimRun.AnimationId = config.run
				end
				local raiseAnim = animController:LoadAnimation(customRig.AnimRaise)
				raiseAnim:Play()
				
				spawn(function()
					wait(250)
					if originalSeek and originalSeek.Parent then
						originalSeek:Destroy()
					end
					if customSeekModel and customSeekModel.Parent then
						customSeekModel:Destroy()
						currentCustomSeek = nil
					end
					if followConnection then
						followConnection:Disconnect()
					end
					isReplacingSeek = false
					latestSeekClone = nil
				end)
				
				raiseAnim.Stopped:Wait()
				animController:LoadAnimation(customRig.AnimRun):Play()
			end
			
			local connection
			connection = animator.AnimationPlayed:Connect(function(animationTrack)
				connection:Disconnect()
				playCustomAnimations()
			end)
		end
		spawn(function()
			ReplicatedStorage.GameData.LatestRoom.Changed:Wait()
			require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption("使用你的体力!!!", true)
			if customSeekModel and customSeekModel.Parent then
				for _, child in pairs(customSeekModel.Figure:GetChildren()) do
					if child:IsA("Sound") and child.Name ~= "Scream" then
						child.Volume = 0.4
						child:Play()
					end
				end
			end
		end)
		originalSeek.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				if followConnection then
					followConnection:Disconnect()
				end
				cleanupOldSeekModel()
				latestSeekClone = nil
				if currentStage == "first" then
					currentStage = "second"
				end
			end
		end)
	end
	if ReplicatedStorage:FindFirstChild("GameData") and ReplicatedStorage.GameData:FindFirstChild("LatestRoom") then
		ReplicatedStorage.GameData.LatestRoom.Changed:Connect(checkAndReplace)
	else
		spawn(function()
			while true do
				wait(2)
				if Workspace:FindFirstChild("SeekMovingNewClone") and not isReplacingSeek then
					checkAndReplace()
				end
			end
		end)
	end
end

loadAllAudio()
replaceSeekModel()
setupEndSequence()
setupRoom49Listener()
setupGEAudio()
setupRoom51Listener()
local hint = Instance.new("Hint", Workspace)
hint.Text = "LoadingMinesMusic... Doors HardCore V10.5 by HeavenNow :)"
game.Debris:AddItem(hint, 3)