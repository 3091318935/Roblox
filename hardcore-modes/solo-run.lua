--[[
	solo-run.lua v1.0.0
	只属于你自己的场子：不连任何人、不等任何人、不进任何群。

	它在你头顶 6000 格处凭空造一条无限走廊（纯客户端，别人看不见），
	把 ReplicatedStorage.Entities 里的硬核怪扔进来追你，走到尽头就开下一间。

	用法（先跑 loader.lua 装资源，Entities 里才有怪）：
		loadstring(game:HttpGet("<地址>/hardcore-modes/solo-run.lua"))()

	快捷键 RightCtrl 开面板 / 退出
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local ENV = getgenv and getgenv() or _G

local CFG = {
	version = "1.0.0",
	keybind = Enum.KeyCode.RightControl,
	baseY = 6000,       -- 场子高度（离原地图很远，互不干扰）
	roomLen = 70,       -- 每间长度
	roomWide = 26,      -- 走廊宽度
	roomTall = 16,      -- 层高
	monsterSpeed = 15,  -- 怪速
	graceSeconds = 6,   -- 每间开局几秒后开始追
}

local state = {
	room = 0,
	origin = Vector3.new(0, CFG.baseY, 0),
	folder = nil,
	monsters = {},   -- [model] = true
	cleared = false,
	damageCd = 0,
}

local function say(...)
	print(string.format("[Solo %s] %s", CFG.version, table.concat({ ... }, " ")))
end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------

local hud, hudText

local function buildHud()
	if hud and hud.Parent then return end
	hud = mk("ScreenGui", {
		Name = "SoloRunHud",
		ResetOnSpawn = false,
		DisplayOrder = 7100,
		Parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui"),
	})
	hudText = mk("TextLabel", {
		Size = UDim2.new(0, 360, 0, 60),
		Position = UDim2.new(0.5, -180, 0, 12),
		BackgroundColor3 = Color3.fromRGB(8, 10, 14),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Font = Enum.Font.Code,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 215, 130),
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "SOLO RUN",
		Parent = hud,
	}, hud)
end

local function refreshHud()
	if not hudText then return end
	local n = 0
	for m in pairs(state.monsters) do if m.Parent then n = n + 1 end end
	hudText.Text = string.format("房间 %d    怪 %d    走到尽头开下一间", state.room, n)
end

---------------------------------------------------------------------------
-- 造房间
---------------------------------------------------------------------------

local function ensureFolder()
	if state.folder and state.folder.Parent then return state.folder end
	local f = mk("Folder", { Name = "SoloRunArena", Parent = workspace })
	state.folder = f
	return f
end

local function wipe()
	if state.folder then
		for _, c in ipairs(state.folder:GetChildren()) do
			pcall(function() c:Destroy() end)
		end
	end
	state.monsters = {}
end

local function slab(parent, size, cframe, color)
	return mk("Part", {
		Name = "SoloSlab",
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.Concrete,
		Color = color,
		Size = size,
		CFrame = cframe,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
		Parent = parent,
	})
end

local startRoom   -- 前置声明：门的 Touched 里要调它

local function buildRoom(index)
	local parent = ensureFolder()
	local o = state.origin + Vector3.new(0, 0, index * CFG.roomLen)
	local halfW = CFG.roomWide / 2
	local halfH = CFG.roomTall / 2
	local dark = Color3.fromRGB(38, 36, 34)
	local darker = Color3.fromRGB(24, 23, 22)

	-- 地板 / 天花板
	slab(parent, Vector3.new(CFG.roomWide, 1, CFG.roomLen),
		CFrame.new(o + Vector3.new(0, -0.5, CFG.roomLen / 2)), dark)
	slab(parent, Vector3.new(CFG.roomWide, 1, CFG.roomLen),
		CFrame.new(o + Vector3.new(0, CFG.roomTall, CFG.roomLen / 2)), darker)

	-- 左右墙
	slab(parent, Vector3.new(1, CFG.roomTall, CFG.roomLen),
		CFrame.new(o + Vector3.new(-halfW, halfH, CFG.roomLen / 2)), dark)
	slab(parent, Vector3.new(1, CFG.roomTall, CFG.roomLen),
		CFrame.new(o + Vector3.new(halfW, halfH, CFG.roomLen / 2)), dark)

	-- 起点封口
	slab(parent, Vector3.new(CFG.roomWide, CFG.roomTall, 1),
		CFrame.new(o + Vector3.new(0, halfH, 0)), darker)

	-- 尽头：门（碰到就进下一间）
	local door = slab(parent, Vector3.new(CFG.roomWide - 2, CFG.roomTall - 2, 1),
		CFrame.new(o + Vector3.new(0, (CFG.roomTall - 2) / 2, CFG.roomLen - 1)),
		Color3.fromRGB(150, 120, 60))
	door.Name = "SoloDoor"
	door.Material = Enum.Material.Wood
	door.Touched:Connect(function(hit)
		if state.room ~= index then return end
		local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if hum and hum.Parent == LP.Character then
			state.room = index + 1
			startRoom(state.room, true)
		end
	end)

	-- 一点点照明，否则全靠外面那点光会看不见
	local light = mk("PointLight", {
		Brightness = 1.4,
		Range = 40,
		Color = Color3.fromRGB(255, 240, 210),
		Parent = mk("Part", {
			Anchored = true, CanCollide = false, Transparency = 1,
			Size = Vector3.new(1, 1, 1),
			CFrame = CFrame.new(o + Vector3.new(0, CFG.roomTall - 2, CFG.roomLen * 0.5)),
			Parent = parent,
		}),
	})
	return light
end

---------------------------------------------------------------------------
-- 怪
---------------------------------------------------------------------------

local function entityList()
	local f = RS:FindFirstChild("Entities") or RS:FindFirstChild("HardcoreEntities")
	if not f then return {} end
	local out = {}
	for _, c in ipairs(f:GetChildren()) do
		if c:IsA("Model") or c:IsA("BasePart") then out[#out + 1] = c end
	end
	return out
end

local function fallbackMonster(parent, pos)
	local box = mk("Part", {
		Name = "SoloMonster",
		Anchored = true,
		CanCollide = false,
		Size = Vector3.new(3, 6, 2),
		Color = Color3.fromRGB(6, 6, 8),
		Material = Enum.Material.SmoothPlastic,
		CFrame = CFrame.new(pos),
		Parent = parent,
	})
	mk("PointLight", {
		Brightness = 2, Range = 12, Color = Color3.fromRGB(255, 40, 40),
		Parent = mk("Part", {
			Anchored = true, CanCollide = false, Transparency = 1,
			Size = Vector3.new(0.5, 0.5, 0.5),
			CFrame = CFrame.new(pos) * CFrame.new(0, 1.5, -1.2),
			Parent = parent,
		}),
	})
	return box
end

local function primaryOf(model)
	if model:IsA("BasePart") then return model end
	return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
end

local function chase(model, part)
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not part or not part.Parent then
			pcall(function() conn:Disconnect() end)
			return
		end
		local ch = LP.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local from = part.Position
		local to = hrp.Position
		local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
		if flat.Magnitude < 2.5 then
			-- 抓到：红屏 + 回起点，不真死，不打断节奏
			if tick() - state.damageCd > 2 and hud and hud.Parent then
				state.damageCd = tick()
				local flash = mk("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(180, 0, 0),
					BackgroundTransparency = 0.55,
					BorderSizePixel = 0,
					Parent = hud,
				})
				task.delay(0.25, function() if flash then flash:Destroy() end end)
				pcall(function()
					ch:PivotTo(CFrame.new(state.origin + Vector3.new(
						0, 4, state.room * CFG.roomLen + 6)))
				end)
			end
			return
		end
		local step = flat.Unit * math.min(CFG.monsterSpeed * dt, flat.Magnitude)
		local nextPos = from + step
		if model:IsA("Model") and model.PrimaryPart then
			model:PivotTo(CFrame.lookAt(nextPos,
				Vector3.new(to.X, nextPos.Y, to.Z)))
		else
			part.CFrame = CFrame.lookAt(nextPos,
				Vector3.new(to.X, nextPos.Y, to.Z))
		end
	end)
	return conn
end

---------------------------------------------------------------------------
-- 开一间
---------------------------------------------------------------------------

function startRoom(index, keepFolder)
	if not keepFolder then wipe() end
	state.room = index

	local parent = ensureFolder()
	buildRoom(index)

	local ch = LP.Character
	if ch then
		pcall(function()
			ch:PivotTo(CFrame.new(state.origin + Vector3.new(0, 4, index * CFG.roomLen + 8))
				* CFrame.Angles(0, math.rad(180), 0))
		end)
	end

	-- 清掉上一间的怪引用，然后按房间号放新怪
	state.monsters = {}
	local list = entityList()
	local count = math.min(1 + math.floor(index / 2), 4)

	task.delay(CFG.graceSeconds, function()
		if state.room ~= index then return end
		for i = 1, count do
			if state.room ~= index then return end
			local base = state.origin + Vector3.new(0, 4, index * CFG.roomLen + CFG.roomLen - 10)
			if #list > 0 then
				local src = list[((i - 1) % #list) + 1]
				local clone = src:Clone()
				pcall(function() clone.Parent = parent end)
				pcall(function() clone:PivotTo(CFrame.new(base + Vector3.new((i - 1) * 4 - 6, 0, 0))) end)
				local p = primaryOf(clone)
				if p then
					state.monsters[clone] = true
					chase(clone, p)
				end
			else
				local box = fallbackMonster(parent, base + Vector3.new((i - 1) * 4 - 6, 0, 0))
				state.monsters[box] = true
				chase(box, box)
			end
			task.wait(0.4)
		end
		refreshHud()
	end)

	refreshHud()
end

---------------------------------------------------------------------------
-- 退出 / 重开
---------------------------------------------------------------------------

local function stopAll()
	state.cleared = true
	wipe()
	if state.folder then
		pcall(function() state.folder:Destroy() end)
		state.folder = nil
	end
	if hud then pcall(function() hud:Destroy() end) hud = nil end
	hudText = nil
	ENV.SoloRun = nil
	say("已退出，场子已清空")
end

local panel

local function buildPanel()
	if panel and panel.Parent then panel.Parent = nil return end
	buildHud()
	panel = mk("ScreenGui", {
		Name = "SoloRunPanel",
		ResetOnSpawn = false,
		DisplayOrder = 7101,
		Parent = (gethui and gethui()) or LP:WaitForChild("PlayerGui"),
	})
	local frame = mk("Frame", {
		Size = UDim2.fromOffset(230, 190),
		Position = UDim2.new(1, -242, 0.5, -95),
		BackgroundColor3 = Color3.fromRGB(10, 12, 16),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Parent = panel,
	}, panel)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, frame)
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 210, 120),
		Text = "SOLO RUN  " .. CFG.version,
		Parent = frame,
	}, frame)

	local function btn(text, y, color, fn)
		local b = mk("TextButton", {
			Size = UDim2.new(1, -16, 0, 34),
			Position = UDim2.new(0, 8, 0, y),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Font = Enum.Font.Code,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(235, 236, 240),
			Text = text,
			Parent = frame,
		}, frame)
		b.MouseButton1Click:Connect(function()
			local ok, err = pcall(fn)
			if not ok then say("出错:", tostring(err)) end
		end)
		return b
	end

	btn("第一间从头开始", 34, Color3.fromRGB(30, 44, 34), function()
		wipe(); startRoom(1)
	end)
	btn("直接跳第 5 间", 74, Color3.fromRGB(34, 36, 48), function()
		wipe(); startRoom(5)
	end)
	btn("清空全部", 114, Color3.fromRGB(52, 26, 28), function()
		wipe(); refreshHud()
	end)
	btn("退出并收拾干净", 154, Color3.fromRGB(60, 24, 24), stopAll)
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == CFG.keybind then buildPanel() end
end)

-- 掉出世界就拉回来
task.spawn(function()
	while not state.cleared do
		task.wait(1)
		local ch = LP.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp and state.room > 0 and hrp.Position.Y < CFG.baseY - 20 then
			pcall(function()
				ch:PivotTo(CFrame.new(state.origin + Vector3.new(0, 4, state.room * CFG.roomLen + 8)))
			end)
		end
	end
end)

ENV.SoloRun = {
	version = CFG.version,
	start = function(n) wipe(); startRoom(n or 1) end,
	next = function() startRoom(state.room + 1, true) end,
	stop = stopAll,
	state = state,
}

buildHud()
startRoom(1)
say("已开局 —— RightCtrl 开面板 / 走到走廊尽头开门进下一间")
