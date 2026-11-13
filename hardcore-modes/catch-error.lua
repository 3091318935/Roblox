--[[
	catch-error.lua —— 抓模式 1/2/3 为什么不动（不联网，直接贴）
	==================================================================
	在原版那个 place 里用。步骤：
		1) 先注入原版码，面板出来
		2) 贴这个脚本
		3) 再点 02 HOTEL（或 01 / 03）
		4) 看屏幕右下角出现的「捕获」列表，和 F9 里的红字

	它拦三样东西：
		error()  报的错
		warn()   警告
		loadstring 之后每段脚本的运行错误
--]]

local ENV = (getgenv and getgenv()) or _G
local out = {}

local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")

local sg = Instance.new("ScreenGui")
sg.Name = "HC_Catch"
sg.ResetOnSpawn = false
sg.DisplayOrder = 9100
local okH, hui = pcall(function() return gethui and gethui() end)
sg.Parent = (okH and hui) or pg

local box = Instance.new("Frame")
box.Size = UDim2.fromOffset(560, 150)
box.Position = UDim2.new(0, 20, 1, -170)
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
title.Text = "捕获 · 点一下 02 HOTEL 看这里"
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
list.TextColor3 = Color3.fromRGB(240, 160, 160)
list.Text = ""
list.Parent = box

local function push(tag, text)
	local s = tostring(text)
	if #s > 300 then s = s:sub(1, 300) .. "…" end
	table.insert(out, 1, "[" .. tag .. "] " .. s)
	while #out > 9 do table.remove(out) end
	list.Text = table.concat(out, "\n")
	print("[CATCH][" .. tag .. "]", text)
end

-- ① error
local okE, oldError = pcall(function() return error end)
if type(hookfunction) == "function" and okE then
	pcall(function()
		hookfunction(error, function(msg, level)
			push("error", msg)
			return oldError(msg, level)
		end)
	end)
end

-- ② warn
if type(hookfunction) == "function" then
	pcall(function()
		local oldWarn = warn
		hookfunction(warn, function(...)
			local t = {}
			for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
			push("warn", table.concat(t, " "))
			return oldWarn(...)
		end)
	end)
end

-- ③ loadstring 之后的运行错误
if type(hookfunction) == "function" and type(loadstring) == "function" then
	pcall(function()
		local oldLoad = loadstring
		hookfunction(loadstring, function(src, name)
			local fn, err = oldLoad(src, name)
			if not fn then
				push("compile", tostring(err))
				return fn, err
			end
			return function(...)
				local r = { pcall(fn, ...) }
				if not r[1] then
					push("runtime", tostring(r[2]))
					return nil
				end
				return table.unpack(r, 2)
			end
		end)
	end)
end

-- ④ 顺手看一眼信号连接数
task.delay(1, function()
	local RS = game:GetService("ReplicatedStorage")
	local gd = RS:FindFirstChild("GameData")
	local lr = gd and gd:FindFirstChild("LatestRoom")
	if lr and type(getconnections) == "function" then
		local ok, conns = pcall(getconnections, lr.Changed)
		if ok and type(conns) == "table" then
			push("info", "LatestRoom.Changed 连接数 = " .. #conns)
		end
	end
end)

print("[CATCH] 已挂上。现在去面板点 02 HOTEL，然后看屏幕左下和 F9")
ENV.HC_CATCH = out
return out
