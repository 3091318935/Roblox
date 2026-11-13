--[[
	scan-strings.lua — 从「已加载」的 hub 里把字符串抠出来（找 Discord / key 接口用）
	用法：hub 面板已经开着的情况下，执行器里跑这一行

		loadstring(game:HttpGet("https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/scan-strings.lua"))()

	流程：点开 MINES / HOTEL / ARCHIVES 里你当前允许点的那个 → 再跑本脚本
	输出：控制台 + 工作区 strings-dump.txt + 剪贴板
	之后想重扫：getgenv().HC_STRINGS.scan()
--]]

local ENV = (getgenv and getgenv()) or _G

local PATTERNS = {
	"discord", "%.gg/", "gg/", "invite", "https?://", "luarmor", "pandadev",
	"gateway", "key", "token", "whitelist", "premium", "webhook", "api%.",
}

local SKIP = {
	[""] = true, ["true"] = true, ["false"] = true, ["nil"] = true,
}

local function hit(s)
	if type(s) ~= "string" then return nil end
	if #s < 4 or #s > 900 then return nil end
	if SKIP[s] then return nil end
	local low = string.lower(s)
	for _, p in ipairs(PATTERNS) do
		if string.find(low, p) then
			return p
		end
	end
	return nil
end

local seen = {}
local out = {}
local n = 0

local function push(where, key, value, why)
	local id = where .. "\1" .. tostring(key) .. "\1" .. value
	if seen[id] then return end
	seen[id] = true
	n = n + 1
	local line = string.format("[%03d] %-42s %-16s %s", n, where, "(" .. why .. ")", value)
	table.insert(out, line)
	print(line)
end

-- 1) 扫描表里的字符串（getgc 能拿到运行时所有活着的 Lua 对象）
local scannedTables, scannedFuncs = 0, 0
local BUDGET = 8      -- 秒；执行器会掐超长线程，到点就收手
local t0 = os.clock()
local function overTime() return (os.clock() - t0) > BUDGET end

local function scanTable(t, depth)
	if depth > 2 then return end
	if overTime() then return end
	scannedTables = scannedTables + 1
	local ok = pcall(function()
		for k, v in pairs(t) do
			if type(v) == "string" then
				local why = hit(v)
				if why then push("table(" .. scannedTables .. ")", k, v, why) end
			elseif type(k) == "string" then
				local why = hit(k)
				if why then push("table-key(" .. scannedTables .. ")", k, v, why) end
			elseif type(v) == "table" and depth < 2 then
				-- 浅层递归：只做一层，避免把整个游戏图跑穿
				pcall(scanTable, v, depth + 1)
			end
		end
	end)
end

local function scanFunction(f)
	scannedFuncs = scannedFuncs + 1
	if overTime() then return end
	if debug and debug.getconstants then
		pcall(function()
			for _, c in ipairs(debug.getconstants(f)) do
				if type(c) == "string" then
					local why = hit(c)
					if why then push("const(" .. scannedFuncs .. ")", "-", c, why) end
				end
			end
		end)
	end
end

local function fullScan()
	seen, out, n = {}, {}, 0
	scannedTables, scannedFuncs = 0, 0
	t0 = os.clock()

	local gc = nil
	if type(getgc) == "function" then
		local ok, res = pcall(getgc)
		if ok and type(res) == "table" then gc = res end
	end

	if not gc then
		print("[scan] 这个执行器没有 getgc，退化成只扫 UI + 环境表")
		local function walk(root, label)
			pcall(function()
				for _, d in ipairs(root:GetDescendants()) do
					local ok2, t = pcall(function() return d.Text end)
					if ok2 then
						local why = hit(t)
						if why then push(label .. "." .. d.Name, d.ClassName, t, why) end
					end
					local why2 = hit(d.Name)
					if why2 then push(label .. "." .. d.Name, "Name", d.Name, why2) end
				end
			end)
		end
		walk(game:GetService("CoreGui"), "CoreGui")
		local lp = game:GetService("Players").LocalPlayer
		if lp then walk(lp.PlayerGui, "PlayerGui") end
		scanTable(ENV, 0)
	else
		for _, obj in ipairs(gc) do
			local ty = type(obj)
			if ty == "table" then
				scanTable(obj, 0)
			elseif ty == "function" then
				scanFunction(obj)
			elseif ty == "string" then
				local why = hit(obj)
				if why then push("gc-string", "-", obj, why) end
			end
		end
		print(string.format("[scan] 扫了 %d 个表 / %d 个函数", scannedTables, scannedFuncs))
	end

	local header = table.concat({
		"# HC string scan",
		"# 命中: " .. n,
		"# 执行器: " .. tostring((identifyexecutor or function() return "?" end)()),
		"",
	}, "\n")

	local text = header .. table.concat(out, "\n") .. "\n"

	local wf = writefile or (syn and syn.write_file) or (function() end)
	pcall(wf, "strings-dump.txt", text)
	if setclipboard then pcall(setclipboard, text) end

	print(string.format("[scan] 命中 %d 条 → 工作区 strings-dump.txt（已复制到剪贴板）", n))
	if n == 0 then
		print("[scan] 0 命中 = 这个 hub 的客户端里确实没有 Discord/接口明文，别再找了")
	end
	return text
end

local API = ENV.HC_STRINGS or {}
API.scan = fullScan
API.last = ""
ENV.HC_STRINGS = API

local ok, res = pcall(fullScan)
if ok then API.last = res else print("[scan] 出错: " .. tostring(res)) end
