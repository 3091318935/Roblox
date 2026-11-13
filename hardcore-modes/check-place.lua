--[[
	check-place.lua  v1.0.0  —— 这个场子能不能跑 HARDCORE-Modes？
	==================================================================
	模式是"挂件"：它自己不带房间、不带服务器，只往**已经存在的 DOORS 式场子**上挂。
	所以只要某个体检项缺一项，就一定不刷怪。跑这个 10 秒出结论：

		兼容 → 直接上 loader，怪会跟着真房间刷，别人进来也能一起玩
		不兼容 → 缺哪一项会直接打出来，换场子

	用法：进游戏后执行一行即可，不需要先跑 loader。
--]]

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local rows = {}
local function add(name, ok, detail)
	rows[#rows + 1] = { name = name, ok = ok, detail = detail or "" }
end

-- ① 房间推进信号（最关键的一项）
local gd = RS:FindFirstChild("GameData")
local lr = gd and gd:FindFirstChild("LatestRoom")
add("GameData.LatestRoom", lr ~= nil and lr:IsA("ValueBase") ~= false,
	lr and (lr.ClassName .. " = " .. tostring(lr.Value)) or "不存在")

-- ② 房间容器
local cr = workspace:FindFirstChild("CurrentRooms")
local roomN = 0
if cr then
	local ok, list = pcall(function() return cr:GetChildren() end)
	if ok and list then roomN = #list end
end
add("workspace.CurrentRooms", cr ~= nil, cr and (roomN .. " 间") or "不存在")

-- ③ 玩家 UI 锚点
local plr = Players.LocalPlayer
local pg = plr:FindFirstChild("PlayerGui")
local mainUI = pg and pg:FindFirstChild("MainUI")
add("PlayerGui.MainUI", mainUI ~= nil, mainUI and "有" or "不存在")

-- ④ 模式要建的音效容器（可自动补，只是提示）
add("workspace.HardCoreSound", workspace:FindFirstChild("HardCoreSound") ~= nil, "缺了 loader 会自动补")

-- ⑤ 怪物容器（模式把怪塞这里）
local ent = workspace:FindFirstChild("Entities")
add("workspace.Entities", ent ~= nil, ent and ("有") or "不存在")

-- 输出
print("== 场子兼容性检测 ==")
print(string.format("placeId = %d   JobId = %s", game.PlaceId, tostring(game.JobId)))
local allOK = true
for _, r in ipairs(rows) do
	local mark = r.ok and "[OK]  " or "[缺]  "
	if not r.ok and (r.name == "GameData.LatestRoom" or r.name == "workspace.CurrentRooms") then
		allOK = false
	end
	print(mark .. r.name .. "   " .. r.detail)
end
print(allOK and "=> 兼容，可以跑 loader" or "=> 不兼容，换一个 DOORS 场子")

-- 屏幕上也打一份，免得控制台被刷掉
do
	local sg = Instance.new("ScreenGui")
	sg.Name = "PlaceCheck"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 9000
	local ok, hui = pcall(function() return gethui and gethui() end)
	sg.Parent = (ok and hui) or pg

	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(330, 30 + #rows * 18 + 30)
	box.Position = UDim2.new(0, 20, 0, 120)
	box.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
	box.BackgroundTransparency = 0.08
	box.BorderSizePixel = 0
	box.Parent = sg

	local line = 8
	for _, r in ipairs(rows) do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, -16, 0, 18)
		t.Position = UDim2.fromOffset(8, line)
		t.Font = Enum.Font.Code
		t.TextSize = 12
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = r.ok and Color3.fromRGB(120, 220, 150) or Color3.fromRGB(240, 120, 120)
		t.Text = (r.ok and "OK  " or "缺  ") .. r.name .. "  " .. r.detail
		t.Parent = box
		line = line + 18
	end

	local res = Instance.new("TextLabel")
	res.BackgroundTransparency = 1
	res.Size = UDim2.new(1, -16, 0, 22)
	res.Position = UDim2.fromOffset(8, line + 2)
	res.Font = Enum.Font.GothamMedium
	res.TextSize = 13
	res.TextXAlignment = Enum.TextXAlignment.Left
	res.TextColor3 = allOK and Color3.fromRGB(120, 220, 150) or Color3.fromRGB(240, 120, 120)
	res.Text = allOK and "兼容 → 可以跑 loader" or "不兼容 → 换场子"
	res.Parent = box

	task.delay(20, function()
		pcall(function() sg:Destroy() end)
	end)
end

return allOK
