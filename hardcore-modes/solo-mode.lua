--[[
	solo-mode.lua v1.0.0
	自己玩：不依赖房主、不依赖服务端、不依赖 Discord。

	它做两件事：
	1) 把 ReplicatedStorage.Entities 里那 7 个硬核实体（Glitch / Spider / Dread /
	   ScreechRetro / Shade / HideEntityOnSpot / Screech）直接投放到你面前
	2) 给一个最简追击循环，让它们朝你走过来（客户端自己的，别人看不见，但你能玩）

	用法：
		loadstring(game:HttpGet("<你的地址>/hardcore-modes/solo-mode.lua"))()
	快捷键：RightCtrl 开关面板

	先跑一次原始模式（hardcore-modes/loader.lua）把资源装好，Entities 里才有东西。
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local ENV = getgenv and getgenv() or _G

local CFG = {
	name = "SoloMode",
	version = "1.0.0",
	keybind = Enum.KeyCode.RightControl,
	speed = 16,          -- 追击速度（格/秒）
	spawnDistance = 16,  -- 生成距离
}

local chasing = {}   -- [model] = { conn = RBXScriptConnection, speed = number }
local spawned = {}   -- 本次自己投放的所有对象

local function say(...)
	print(string.format("[Solo %s] %s", CFG.version,
		table.concat({ ... }, " ")))
end

---------------------------------------------------------------------------
-- 找 Entities
---------------------------------------------------------------------------

local function entitiesFolder()
	local f = RS:FindFirstChild("Entities")
	return f or RS:FindFirstChild("HardcoreEntities")
end

local function entityList()
	local f = entitiesFolder()
	if not f then return {} end
	local out = {}
	for _, c in ipairs(f:GetChildren()) do
		if c:IsA("Model") or c:IsA("BasePart") or c:IsA("MeshPart") then
			out[#out + 1] = c
		end
	end
	table.sort(out, function(a, b) return a.Name < b.Name end)
	return out
end

---------------------------------------------------------------------------
-- 找到可用的实体生成器（有就用，没有就只做摆放）
---------------------------------------------------------------------------

local spawnerCache
local function getSpawner()
	if spawnerCache ~= nil then return spawnerCache end
	local s = ENV.VynixuEntitySpawnerV2
	if type(s) == "table" then
		spawnerCache = s
		return s
	end
	local urls = {
		"https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua",
		"https://fastly.jsdelivr.net/gh/RegularVynixu/Utilities@main/Doors/Entity%20Spawner/V2/Source.lua",
	}
	for _, u in ipairs(urls) do
		local ok, mod = pcall(function()
			local body = game:HttpGet(u, true)
			if type(body) ~= "string" or #body < 100 then error("空响应") end
			return loadstring(body, "=Spawner")()
		end)
		if ok and type(mod) == "table" then
			spawnerCache = mod
			say("生成器已就绪:", u)
			return mod
		end
	end
	spawnerCache = false
	say("没拿到生成器，本次只能摆放（怪物不会动）")
	return false
end

---------------------------------------------------------------------------
-- 摆放
---------------------------------------------------------------------------

local function anchorCF()
	local ch = LP.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	return hrp.CFrame * CFrame.new(0, 2, -CFG.spawnDistance)
end

local function primaryOf(model)
	if model:IsA("BasePart") then return model end
	if model.PrimaryPart then return model.PrimaryPart end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function placeAt(model, cf)
	local ok = pcall(function()
		if model:IsA("Model") then
			model:PivotTo(cf)
		else
			model.CFrame = cf
		end
	end)
	if not ok then
		local p = primaryOf(model)
		if p then pcall(function() p.CFrame = cf end) end
	end
	pcall(function() model.Parent = workspace end)
end

---------------------------------------------------------------------------
-- 试各种调用形状（这套生成器的签名没公开，四种都试一遍）
---------------------------------------------------------------------------

local function tryRun(spawner, model)
	local shapes = {
		function() return spawner:Run(model) end,
		function() return spawner:Run(model, false) end,
		function() return spawner.Run(spawner, model) end,
		function() return spawner.Run(model) end,
	}
	for i, fn in ipairs(shapes) do
		local ok = pcall(fn)
		if ok then return i end
	end
	return nil
end

---------------------------------------------------------------------------
-- 最简追击
---------------------------------------------------------------------------

local function stopChase(model)
	local rec = chasing[model]
	if rec and rec.conn then
		pcall(function() rec.conn:Disconnect() end)
	end
	chasing[model] = nil
end

local function startChase(model, speed)
	stopChase(model)
	local part = primaryOf(model)
	if not part then return false end
	speed = speed or CFG.speed

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local ch = LP.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if not hrp or not model.Parent then
			stopChase(model)
			return
		end
		local from = part.Position
		local to = hrp.Position
		local dir = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
		if dir.Magnitude < 2 then return end
		local step = dir.Unit * math.min(speed * dt, dir.Magnitude)
		local nextPos = from + step
		if model:IsA("Model") and model.PrimaryPart then
			model:PivotTo(CFrame.lookAt(nextPos, Vector3.new(to.X, nextPos.Y, to.Z)))
		else
			part.CFrame = CFrame.lookAt(nextPos, Vector3.new(to.X, nextPos.Y, to.Z))
		end
	end)
	chasing[model] = { conn = conn, speed = speed }
	return true
end

---------------------------------------------------------------------------
-- 主投放函数
---------------------------------------------------------------------------

local function spawnOne(name, doChase)
	local list = entityList()
	local model
	for _, c in ipairs(list) do
		if c.Name == name then model = c break end
	end
	if not model then
		say("没有这个实体:", name)
		return false
	end

	local cf = anchorCF()
	local spawner = getSpawner()
	local used = nil

	if spawner then
		-- 先试生成器的正规流程（会自己处理动画/AI/清理）
		pcall(function() spawner:Create(model) end)
		used = tryRun(spawner, model)
	end

	local p = primaryOf(model)
	if not p or (p.Position - (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart").Position or p.Position)).Magnitude > 4000 then
		placeAt(model, cf)
	end

	local idx = nil
	for i, c in ipairs(spawned) do if c == model then idx = i end end
	if not idx then spawned[#spawned + 1] = model end

	if doChase ~= false then startChase(model, CFG.speed) end

	say(string.format("%s 投放完成（生成器调用: %s，追击: %s）",
		name, used and ("形状" .. used) or "内置摆放", doChase ~= false and "开" or "关"))
	return true
end

---------------------------------------------------------------------------
-- 界面
---------------------------------------------------------------------------

local gui, frame, listHolder

local function row(parent, text, color, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 0, 26)
	btn.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	btn.BackgroundTransparency = 0.1
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.Code
	btn.TextSize = 13
	btn.TextColor3 = color or Color3.fromRGB(230, 232, 238)
	btn.Text = "  " .. text
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = parent
	btn.MouseButton1Click:Connect(function()
		local ok, err = pcall(onClick)
		if not ok then say("出错:", tostring(err)) end
	end)
	return btn
end

local function rebuild()
	if not listHolder then return end
	for _, c in ipairs(listHolder:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local list = entityList()
	if #list == 0 then
		row(listHolder, "Entities 里没有东西 —— 先跑一次 loader.lua", Color3.fromRGB(255, 140, 140), function() end)
		return
	end
	for _, c in ipairs(list) do
		local isChasing = chasing[c] ~= nil
		row(listHolder, (isChasing and "▶ " or "· ") .. c.Name,
			isChasing and Color3.fromRGB(120, 230, 160) or nil,
			function()
				if chasing[c] then
					stopChase(c)
				else
					spawnOne(c.Name, true)
				end
				rebuild()
			end)
	end
end

local function build()
	if gui and gui.Parent then return end

	gui = Instance.new("ScreenGui")
	gui.Name = "SoloModeGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 7000
	gui.Parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui")

	frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(220, 360)
	frame.Position = UDim2.new(1, -232, 0.5, -180)
	frame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextColor3 = Color3.fromRGB(255, 210, 120)
	title.Text = "SOLO MODE  " .. CFG.version
	title.Parent = frame

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -12, 1, -76)
	scroll.Position = UDim2.new(0, 6, 0, 32)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	end)

	listHolder = scroll

	local bottom = Instance.new("Frame")
	bottom.Size = UDim2.new(1, -12, 0, 32)
	bottom.Position = UDim2.new(0, 6, 1, -40)
	bottom.BackgroundTransparency = 1
	bottom.Parent = frame

	local reset = Instance.new("TextButton")
	reset.Size = UDim2.new(0.5, -4, 1, 0)
	reset.BackgroundColor3 = Color3.fromRGB(60, 20, 24)
	reset.BorderSizePixel = 0
	reset.Font = Enum.Font.Code
	reset.TextSize = 12
	reset.TextColor3 = Color3.fromRGB(255, 190, 190)
	reset.Text = "清除全部"
	reset.Parent = bottom
	reset.MouseButton1Click:Connect(function()
		for m in pairs(chasing) do stopChase(m) end
		for _, m in ipairs(spawned) do
			pcall(function()
				if m and m.Parent and m.Name ~= "Entities" then m:Destroy() end
			end)
		end
		spawned = {}
		rebuild()
		say("已清除")
	end)

	local spawnAll = Instance.new("TextButton")
	spawnAll.Size = UDim2.new(0.5, -4, 1, 0)
	spawnAll.Position = UDim2.new(0.5, 4, 0, 0)
	spawnAll.BackgroundColor3 = Color3.fromRGB(26, 40, 30)
	spawnAll.BorderSizePixel = 0
	spawnAll.Font = Enum.Font.Code
	spawnAll.TextSize = 12
	spawnAll.TextColor3 = Color3.fromRGB(190, 230, 190)
	spawnAll.Text = "全放出来"
	spawnAll.Parent = bottom
	spawnAll.MouseButton1Click:Connect(function()
		for _, c in ipairs(entityList()) do
			pcall(function() spawnOne(c.Name, true) end)
			task.wait(0.2)
		end
		rebuild()
	end)

	rebuild()
end

local function toggle()
	if gui and gui.Parent then
		gui.Parent = nil
		return
	end
	build()
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == CFG.keybind then toggle() end
end)

ENV.SoloMode = {
	version = CFG.version,
	list = function()
		local names = {}
		for _, c in ipairs(entityList()) do names[#names + 1] = c.Name end
		return names
	end,
	spawn = function(name, doChase)
		build()
		return spawnOne(name, doChase)
	end,
	spawnAll = function()
		build()
		for _, c in ipairs(entityList()) do spawnOne(c.Name, true) end
	end,
	chase = startChase,
	stop = stopChase,
	show = build,
	hide = function() if gui then gui.Parent = nil end end,
}

build()
say("已就绪 —— RightCtrl 开关面板；Entities:", #entityList(), "个")
