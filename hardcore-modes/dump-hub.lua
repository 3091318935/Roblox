--[[
	dump-hub.lua v1.1 — 把混淆 hub 里藏着的 Discord 邀请 / 接口域名 / key 系统抠出来
	适用：Luraph / Ironbrew2 / 自研 VM 这类"字符串全编码 + dispatcher"的 hub

	用法（执行器里一行）：
		loadstring(game:HttpGet("<YOUR_DUMP_URL>"))()

	它会：装钩子 → 自己拉目标脚本并执行 → 等 8 秒 → 把抓到的所有可疑字符串
	写到工作区 hub-dump.txt，同时丢进剪贴板。

	换目标：getgenv().HC_TARGET = "https://pastefy.app/xxxx/raw"，再执行一次。
	跑完想手动补抓：点一下 hub UI 里的 Discord / Key 按钮，然后执行
		getgenv().HC_DUMP.dump()
--]]

local ENV = (getgenv and getgenv()) or _G
local TARGET = ENV.HC_TARGET or "https://pastefy.app/Bf6hbDY4/raw"
local WAIT_SECONDS = 8

local OUT, SEEN = {}, {}

local function push(tag, s)
	if type(s) ~= "string" or #s < 5 then return end
	local key = tag .. "\0" .. s
	if SEEN[key] then return end
	SEEN[key] = true
	OUT[#OUT + 1] = tag .. "\t" .. s
end

local function interesting(s)
	if type(s) ~= "string" or #s < 5 then return false end
	local low = s:lower()
	return low:find("discord", 1, true)
		or low:find("http", 1, true)
		or low:find("invite", 1, true)
		or low:find("luarmor", 1, true)
		or low:find("key", 1, true)
		or low:find("token", 1, true)
		or low:find("api.", 1, true)
end

-- ── 钩子 ───────────────────────────────────────────────
local realLoadstring = loadstring

local hook = rawget(ENV, "hookfunction") or hookfunction or detour_function
if type(hook) == "function" then
	pcall(function()
		local oldGet = game.HttpGet
		hook(oldGet, function(self, url, ...)
			push("HttpGet", tostring(url))
			return oldGet(self, url, ...)
		end)
	end)
	pcall(function()
		local oldAsync = game.HttpGetAsync
		if type(oldAsync) == "function" then
			hook(oldAsync, function(self, url, ...)
				push("HttpGetAsync", tostring(url))
				return oldAsync(self, url, ...)
			end)
		end
	end)
end

for _, name in ipairs({ "request", "http_request" }) do
	local fn = rawget(ENV, name)
	if type(fn) == "function" then
		ENV[name] = function(t)
			if type(t) == "table" and t.Url then
				push(name, tostring(t.Url))
			end
			return fn(t)
		end
	end
end

if type(ENV.setclipboard) == "function" then
	local oldClip = ENV.setclipboard
	ENV.setclipboard = function(s)
		if interesting(s) then push("setclipboard", s) end
		return oldClip(s)
	end
end

if type(ENV.loadstring) == "function" then
	local oldLoadstring = ENV.loadstring
	ENV.loadstring = function(s, n)
		if type(s) == "string" and interesting(s:sub(1, 300)) then
			push("loadstring[" .. tostring(n) .. "]", s:sub(1, 300))
		end
		return oldLoadstring(s, n)
	end
end

-- ── 扫描 ───────────────────────────────────────────────
local function scanValue(v, tag, depth)
	if depth > 2 then return end
	if type(v) == "string" then
		if interesting(v) then push(tag, v) end
		return
	end
	if type(v) ~= "table" then return end

	local n = 0
	for k, sub in pairs(v) do
		n = n + 1
		if n > 200 then break end
		if type(k) == "string" and interesting(k) then push(tag .. ".key", k) end
		scanValue(sub, tag, depth + 1)
	end
end

local function scanEnv()
	local n = 0
	for k, v in pairs(ENV) do
		n = n + 1
		if n > 600 then break end
		if type(k) == "string" and interesting(k) then push("env.key", k) end
		if type(v) == "string" and interesting(v) then push("env.value", v) end
	end
end

local function scanGui()
	local roots = {}
	local okCore, core = pcall(function() return game:GetService("CoreGui") end)
	if okCore and core then roots[#roots + 1] = core end

	local okPlr, plr = pcall(function() return game:GetService("Players").LocalPlayer end)
	if okPlr and plr then
		local okPg, pg = pcall(function() return plr:FindFirstChildOfClass("PlayerGui") end)
		if okPg and pg then roots[#roots + 1] = pg end
	end

	for _, root in ipairs(roots) do
		local okList, list = pcall(function() return root:GetDescendants() end)
		if okList and type(list) == "table" then
			for _, obj in ipairs(list) do
				local okText, txt = pcall(function() return obj.Text end)
				if okText and type(txt) == "string" and #txt > 1 then
					push("UI.text", tostring(obj.ClassName) .. "|" .. tostring(obj.Name) .. "|" .. txt)
				end
				local okName, nm = pcall(function() return obj.Name end)
				if okName and type(nm) == "string" and interesting(nm) then
					push("UI.name", nm)
				end
			end
		end
	end
end

local function scanConstants(f)
	if type(f) ~= "function" then return end
	local dbg = rawget(ENV, "debug") or debug
	if type(dbg) ~= "table" then return end

	if type(dbg.getconstants) == "function" then
		local ok, list = pcall(dbg.getconstants, f)
		if ok and type(list) == "table" then
			for _, c in ipairs(list) do
				if type(c) == "string" and interesting(c) then push("const", c) end
			end
		end
	end

	if type(dbg.getupvalues) == "function" then
		local ok, ups = pcall(dbg.getupvalues, f)
		if ok and type(ups) == "table" then
			for _, u in ipairs(ups) do
				if type(u) == "string" then
					if interesting(u) then push("upvalue", u) end
				else
					scanValue(u, "upvalue", 1)
				end
			end
		end
	end
end

-- ── 输出 ───────────────────────────────────────────────
local function dump()
	scanEnv()
	scanGui()

	local text = table.concat(OUT, "\n")
	if type(writefile) == "function" then
		pcall(writefile, "hub-dump.txt", text)
	end
	if type(setclipboard) == "function" then
		pcall(setclipboard, text)
	end

	local head = {}
	for i = 1, math.min(#OUT, 25) do
		head[#head + 1] = OUT[i]
	end
	if #OUT == 0 then
		head[#head + 1] = "（没抓到东西：把 WAIT_SECONDS 调大，或点一下 hub 里的按钮再 getgenv().HC_DUMP.dump()）"
	end

	warn("[HC-DUMP] 共 " .. #OUT .. " 条 → hub-dump.txt / 剪贴板\n" .. table.concat(head, "\n"))
	return OUT
end

ENV.HC_DUMP = { dump = dump, out = OUT }
ENV.HC_DUMP_INSTALLED = true

-- ── 执行目标 + 收尾 ─────────────────────────────────────
task.spawn(function()
	local okFetch, src = pcall(function() return game:HttpGet(TARGET, true) end)

	if not okFetch or type(src) ~= "string" or #src < 100 then
		push("FETCH_FAIL", tostring(src))
	else
		local f, cerr = realLoadstring(src, "=HCTarget")
		if not f then
			push("COMPILE_FAIL", tostring(cerr))
		else
			pcall(f)                       -- hub 内部报错不打断后面 dump
			task.wait(0.3)
			scanConstants(f)
		end
	end

	task.wait(WAIT_SECONDS)
	dump()
end)
