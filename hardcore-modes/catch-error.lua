--[[
	catch-error.lua v1.1 —— 抓模式 1/2/3 卡在哪
	==================================================================
	v1.0 的 loadstring 钩子把 PANLT 搞成 C stack overflow，已删。
	现在只做三件事，全部只读：
		1) error / warn 钩子（轻量）
		2) 查 workspace.HardcoreOne 标记是否存在
		3) 试拉 HOTELLua 第一个 GetObjects 资产，看权限

	用法：贴进执行器，看左下角那块黑框。
--]]

local ENV = (getgenv and getgenv()) or _G

local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name = "HC_Catch"
sg.ResetOnSpawn = false
sg.DisplayOrder = 9100
local okH, hui = pcall(function() return gethui and gethui() end)
sg.Parent = (okH and hui) or pg

local box = Instance.new("Frame")
box.Size = UDim2.fromOffset(620, 210)
box.Position = UDim2.new(0, 20, 1, -230)
box.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
box.BackgroundTransparency = 0.05
box.BorderSizePixel = 0
box.Parent = sg

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -12, 0, 20)
title.Position = UDim2.fromOffset(6, 2)
title.Font = Enum.Font.GothamMedium
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(214, 178, 96)
title.Text = "诊断 · 只读"
title.Parent = box

local list = Instance.new("TextLabel")
list.BackgroundTransparency = 1
list.Size = UDim2.new(1, -12, 1, -26)
list.Position = UDim2.fromOffset(6, 22)
list.Font = Enum.Font.Code
list.TextSize = 11
list.TextWrapped = true
list.TextXAlignment = Enum.TextXAlignment.Left
list.TextYAlignment = Enum.TextYAlignment.Top
list.TextColor3 = Color3.fromRGB(220, 220, 220)
list.Text = ""
list.Parent = box

local out = {}
local function push(tag, text)
	local s = tostring(text)
	if #s > 320 then s = s:sub(1, 320) .. "…" end
	table.insert(out, "[" .. tag .. "] " .. s)
	while #out > 11 do table.remove(out, 1) end
	list.Text = table.concat(out, "\n")
	print("[DIAG][" .. tag .. "]", text)
end

-- ① 标记检查：HardCoreOne / HardcoreOne 一旦存在，HOTELLua 第 1 行就直接 return
for _, n in ipairs({ "HardcoreOne", "HardCoreOne", "HardcoreITEM", "HardCoreSound" }) do
	push("mark", n .. " = " .. (workspace:FindFirstChild(n) and "有" or "无"))
end

-- ② 资产权限：HOTELLua.lua:57 就是靠这个 id 起头，拉不到会死循环
task.spawn(function()
	local id = "83840759413024"
	local ok, a, b = pcall(function()
		local objs = game:GetObjects("rbxassetid://" .. id)
		return #objs, (objs[1] and objs[1].Name) or "?"
	end)
	if ok then
		push("asset", "GetObjects " .. id .. " OK  数量=" .. tostring(a) .. " 名字=" .. tostring(b))
	else
		push("asset", "GetObjects " .. id .. " 失败: " .. tostring(a))
	end
end)

-- ③ error / warn
if type(hookfunction) == "function" then
	local okE, oldError = pcall(function() return error end)
	if okE then
		pcall(function()
			hookfunction(error, function(msg, level)
				push("error", msg)
				return oldError(msg, level)
			end)
		end)
	end
	local okW, oldWarn = pcall(function() return warn end)
	if okW then
		pcall(function()
			hookfunction(warn, function(...)
				local t = {}
				for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
				push("warn", table.concat(t, " "))
				return oldWarn(...)
			end)
		end)
	end
end

-- ④ 连接数
task.delay(1, function()
	local RS = game:GetService("ReplicatedStorage")
	local gd = RS:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom")
	if lr and type(getconnections) == "function" then
		local ok, conns = pcall(getconnections, lr.Changed)
		if ok and type(conns) == "table" then
			push("conn", "LatestRoom.Changed 连接数 = " .. #conns)
		end
	end
	push("conn", "LatestRoom 当前值 = " .. tostring(lr and lr.Value))
end)

ENV.HC_DIAG = out
push("info", "把上面这些发我；点 02 HOTEL 若出现红字也发我")
return out
