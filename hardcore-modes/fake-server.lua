--[[
	fake-server.lua  v1.0.0  —— Hardcore Modes 的"本地假服务端"
	==================================================================
	结论先说：那 18 个模式文件里，模型、贴图、道具、怪物逻辑**全部是本地代码**，
	它们唯一等的不是"云端数据"，而是**一个数字在往上加**：

		ReplicatedStorage.GameData.LatestRoom.Value  →  1, 2, 3 ...

	全量 grep 的 158 处命中全是这种形状：
		LatestRoom.Changed:Wait()                          -- 等下一间房
		LatestRoom.Changed:Connect(function() ... end)     -- 房间变了就干活
		workspace.CurrentRooms[LatestRoom.Value]           -- 取当前房间

	原版里这个数字由**服务端**在玩家过门时 +1。你进的场子没有那套服务端，
	数字永远是 0，于是所有模式文件全卡在第一行 Wait() 上 —— 怪不刷、道具不出、
	状态不变，全部由这一个原因造成。

	这个脚本就是把这个数字**在客户端本地伪造出来**，并按房间号补出房间壳，
	让那些等着的代码以为"服务端开新房间了"，自己继续跑下去。

	用法：
		1) 先跑 loader（面板出来）
		2) 再跑本脚本 → 按一下 RightAlt 推一间房，或点「自动」让它每 6 秒 +1
		3) 进电梯/走进房间后点一次，看怪刷不刷

	接口：getgenv().FakeServer = { next, set, auto, stop, value }
--]]

local CFG = {
	version = "1.0.0",
	roomStep = 6,        -- 自动模式：每 6 秒推进一间
	autoStart = false,   -- 载入后是否立刻自动推进
	createRooms = true,  -- 是否补 workspace.CurrentRooms 的房间壳
	keybind = "RightAlt",
	baseY = 6000,        -- 房间壳里那块隐形板子的高度（别落在地图里）
	maxShell = 200,
}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local ENV = (getgenv and getgenv()) or _G
local plr = Players.LocalPlayer

local function log(...)
	print("[FakeServer]", ...)
end

local function ensure(parent, name, class)
	if not parent then return nil end
	local found = parent:FindFirstChild(name)
	if found then return found end
	local ok, obj = pcall(Instance.new, class)
	if not ok or not obj then return nil end
	obj.Name = name
	local ok2 = pcall(function() obj.Parent = parent end)
	if not ok2 then return nil end
	return obj
end

----------------------------------------------------------------------
-- ① 把 GameData.LatestRoom 这个东西弄出来
----------------------------------------------------------------------
local function buildGameData()
	local gd = RS:FindFirstChild("GameData") or ensure(RS, "GameData", "Folder")
	if not gd then return nil, "ReplicatedStorage.GameData 建不出来" end

	local lr = gd:FindFirstChild("LatestRoom")
	if lr and not lr:IsA("ValueBase") then
		-- 对方挂的不是值对象，换掉
		pcall(function() lr:Destroy() end)
		lr = nil
	end
	if not lr then lr = ensure(gd, "LatestRoom", "NumberValue") end
	if not lr then return nil, "GameData.LatestRoom 建不出来" end

	return lr
end

----------------------------------------------------------------------
-- ② 房间壳：workspace.CurrentRooms["1".."N"]
----------------------------------------------------------------------
local function buildRooms()
	local cr = workspace:FindFirstChild("CurrentRooms")
	if not cr then cr = ensure(workspace, "CurrentRooms", "Folder") end
	return cr
end

local function shell(cr, idx)
	if not CFG.createRooms or not cr then return end
	if idx > CFG.maxShell then return end
	local name = tostring(idx)
	if cr:FindFirstChild(name) then return end

	local m = Instance.new("Model")
	m.Name = name

	local assets = Instance.new("Folder")
	assets.Name = "Assets"
	assets.Parent = m

	-- HOTELLua4:11433 会因为找不到 RoomEntrance 直接 error，补一块隐形板子顶住
	local part = Instance.new("Part")
	part.Name = "RoomEntrance"
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(2, 2, 2)
	part.CFrame = CFrame.new(0, CFG.baseY, 0)
	part.Parent = m

	m.Parent = cr
end

----------------------------------------------------------------------
-- ③ 启动
----------------------------------------------------------------------
local lr, why = buildGameData()
if not lr then
	warn("[FakeServer] " .. tostring(why))
	return nil
end

local cr = buildRooms()

-- 有些脚本无超时地等这个文件夹，缺了会挂一整局
ensure(workspace, "HardCoreSound", "Folder")

local state = {
	lr = lr,
	cr = cr,
	value = (type(lr.Value) == "number") and lr.Value or 0,
	auto = false,
	thread = nil,
}

local function setRoom(n)
	if type(n) ~= "number" then return end
	state.value = n
	pcall(function() state.lr.Value = n end)   -- 客户端写服务端值：本地生效
	shell(state.cr, n)
end

local function nextRoom()
	setRoom(state.value + 1)
	log("推进到房间 " .. tostring(state.value))
	return state.value
end

local function autoLoop()
	if state.thread then return end
	state.thread = task.spawn(function()
		while state.auto do
			nextRoom()
			task.wait(CFG.roomStep)
		end
		state.thread = nil
	end)
end

local function setAuto(on)
	state.auto = (on == true)
	if state.auto then
		autoLoop()
		log("自动推进：开（每 " .. CFG.roomStep .. " 秒一间）")
	else
		log("自动推进：关")
	end
end

----------------------------------------------------------------------
-- ④ 小面板
----------------------------------------------------------------------
local COL = {
	bg = Color3.fromRGB(18, 20, 26),
	line = Color3.fromRGB(58, 64, 78),
	txt = Color3.fromRGB(232, 236, 244),
	dim = Color3.fromRGB(140, 148, 164),
	main = Color3.fromRGB(214, 178, 96),
}

local function guiParent()
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and hui then return hui end
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and cg then return cg end
	return plr:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "FakeServerUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6003
gui.Parent = guiParent()

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(248, 118)
frame.Position = UDim2.new(0, 24, 0, 300)
frame.BackgroundColor3 = COL.bg
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = COL.line
stroke.Thickness = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -16, 0, 28)
title.Position = UDim2.new(0, 10, 0, 4)
title.Font = Enum.Font.GothamMedium
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = COL.main
title.Text = "假服务端 · 房间推进"
title.Parent = frame

local info = Instance.new("TextLabel")
info.BackgroundTransparency = 1
info.Size = UDim2.new(1, -20, 0, 38)
info.Position = UDim2.new(0, 10, 0, 30)
info.Font = Enum.Font.Code
info.TextSize = 12
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.TextColor3 = COL.txt
info.Text = "LatestRoom: ?"
info.Parent = frame

local function mkBtn(text, x, w)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 12
	b.TextColor3 = COL.txt
	b.Text = text
	b.Size = UDim2.fromOffset(w, 26)
	b.Position = UDim2.fromOffset(x, 82)
	b.Parent = frame
	local s = Instance.new("UIStroke")
	s.Color = COL.line
	s.Thickness = 1
	s.Parent = b
	return b
end

local btnNext = mkBtn("+1 房间", 10, 72)
local btnAuto = mkBtn("自动:关", 88, 70)
local btnZero = mkBtn("归零", 164, 56)

local function refresh()
	info.Text = string.format(
		"LatestRoom: %s\n自动: %s   房间壳: %s",
		tostring(state.value),
		state.auto and "开" or "关",
		CFG.createRooms and "开" or "关"
	)
	btnAuto.Text = state.auto and "自动:开" or "自动:关"
end

btnNext.MouseButton1Click:Connect(function()
	nextRoom()
	refresh()
end)

btnAuto.MouseButton1Click:Connect(function()
	setAuto(not state.auto)
	refresh()
end)

btnZero.MouseButton1Click:Connect(function()
	setRoom(0)
	refresh()
end)

refresh()

UIS.InputBegan:Connect(function(input, busy)
	if busy then return end
	if input.KeyCode == Enum.KeyCode[CFG.keybind] then
		nextRoom()
		refresh()
	end
end)

----------------------------------------------------------------------
-- ⑤ 诊断 + 暴露接口
----------------------------------------------------------------------
local function diag()
	local gd = RS:FindFirstChild("GameData")
	local roomCount = 0
	if state.cr then
		local ok, list = pcall(function() return state.cr:GetChildren() end)
		if ok and list then roomCount = #list end
	end
	log("GameData:", gd and "有" or "无")
	log("LatestRoom 类:", state.lr.ClassName, "值:", tostring(state.lr.Value))
	log("CurrentRooms:", state.cr and "有" or "无", "(" .. roomCount .. " 间)")
	log("HardCoreSound:", workspace:FindFirstChild("HardCoreSound") and "有" or "无")
	log("按 " .. CFG.keybind .. " 手动推一间；面板上「自动」每 " .. CFG.roomStep .. " 秒推一间")
end

diag()

local api = {
	next = nextRoom,
	set = setRoom,
	auto = setAuto,
	stop = function()
		state.auto = false
		pcall(function() gui:Destroy() end)
	end,
	get value() return state.value end,
	lr = state.lr,
}
ENV.FakeServer = api

if CFG.autoStart then setAuto(true) end

return api
