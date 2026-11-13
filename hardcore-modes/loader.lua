--[[
	Hardcore Modes · 自建启动器 v1.0.0
	作用：把 pastefy 上那个混淆 hub 包一层，带多源回退 / 防 Cloudflare 挑战页 / 本地缓存，
	     任何人拿到下面这一行都能开，不依赖你自己电脑。

	发布：hardcore-modes/loader.lua 推到 GitHub raw，把 <YOUR_LOADER_URL> 换成实际地址。
	别人（和你自己）用：
		loadstring(game:HttpGet("<YOUR_LOADER_URL>"))()

	想改源：改 CFG.sources / CFG.mirrors 即可；本地缓存文件名 CFG.localFile。
--]]

local CFG = {
	name      = "HardcoreModes",
	version   = "1.0.0",
	minSize   = 4000,                    -- 小于这个字节数一律当失败（挑战页/空响应）
	localFile = "hardcore-modes.lua",    -- 执行器工作区里的离线备份
	debug     = true,

	-- 主源：官方 paste（unlisted，但 raw 直链对任何人可读）
	sources = {
		"https://pastefy.app/Bf6hbDY4/raw",
		"https://pastefy.app/Bf6hbDY4/raw?cache=0",   -- 绕开部分执行器的 GET 缓存
	},

	-- 你自己的镜像（强烈建议至少放一个，paste 被删/被限流时还能开）
	mirrors = {
		-- "https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/HARDCORE-Modes.lua",
		-- "https://cdn.jsdelivr.net/gh/3091318935/Roblox@main/hardcore-modes/HARDCORE-Modes.lua",
		-- "https://ghfast.top/https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/HARDCORE-Modes.lua",
		-- "https://<你的域名>/s/<id>.lua",
	},
}

local function log(...)
	if CFG.debug then
		print("[HC " .. CFG.version .. "]", ...)
	end
end

-- 通用 HTTP：不同执行器能力不同，挨个试
local function httpGet(url)
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end

	local req = (syn and syn.request)
		or (http and http.request)
		or (fluxus and fluxus.request)
		or http_request
		or request

	if req then
		local ok2, res = pcall(function()
			return req({ Url = url, Method = "GET" })
		end)
		if ok2 and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
			return res.Body
		end
	end

	return nil
end

-- 判断拿回来的是不是真脚本
local function checkSource(src)
	if type(src) ~= "string" then return false, "空返回" end
	if #src < CFG.minSize then return false, "太短(" .. #src .. "B)" end
	if src:sub(1, 1) == "<" then return false, "HTML 页面" end

	local low = src:lower()
	if low:find("<!doctype", 1, true)
		or low:find("just a moment", 1, true)
		or low:find("enable javascript", 1, true)
		or low:find("cloudflare", 1, true)
	then
		return false, "被盾拦了（挑战页）"
	end

	if not (low:find("loadstring", 1, true) or low:find("game:", 1, true) or low:find("return", 1, true)) then
		return false, "不像 Lua"
	end

	return true
end

local ENV = (getgenv and getgenv()) or _G

if ENV.__HC_MODES_ACTIVE and not ENV.HC_FORCE then
	log("已经在跑了。要强制重开：getgenv().HC_FORCE = true，再执行一次本 loader")
	return
end

-- 逐源尝试
local tried = {}
local chosen, chosenUrl

local function tryUrl(url, tag)
	local body = httpGet(url)
	if not body then
		tried[#tried + 1] = tag .. " " .. url .. " -> 请求失败"
		return nil
	end
	local ok, why = checkSource(body)
	if not ok then
		tried[#tried + 1] = tag .. " " .. url .. " -> " .. why
		return nil
	end
	return body
end

for _, url in ipairs(CFG.sources) do
	local body = tryUrl(url, "src")
	if body then
		chosen, chosenUrl = body, url
		break
	end
end

if not chosen then
	for _, url in ipairs(CFG.mirrors) do
		local body = tryUrl(url, "mirror")
		if body then
			chosen, chosenUrl = body, url
			break
		end
	end
end

-- 本地离线备份
if not chosen and type(readfile) == "function" then
	local ok, data = pcall(readfile, CFG.localFile)
	if ok and type(data) == "string" then
		local good, why = checkSource(data)
		if good then
			chosen, chosenUrl = data, "local:" .. CFG.localFile
		else
			tried[#tried + 1] = "local -> " .. why
		end
	end
end

-- 剪贴板（手动把脚本全选复制进去也能救急）
if not chosen and type(getclipboard) == "function" then
	local ok, data = pcall(getclipboard)
	if ok and type(data) == "string" then
		local good, why = checkSource(data)
		if good then
			chosen, chosenUrl = data, "clipboard"
		else
			tried[#tried + 1] = "clipboard -> " .. why
		end
	end
end

if not chosen then
	warn("[HC] 所有源都失败：\n  " .. table.concat(tried, "\n  "))
	return
end

local chunk, cerr = loadstring(chosen, "=" .. CFG.name)
if not chunk then
	warn("[HC] 编译失败：" .. tostring(cerr) .. "\n源：" .. tostring(chosenUrl))
	return
end

ENV.__HC_MODES_ACTIVE = true
ENV.HC_MODES = {
	version = CFG.version,
	source  = chosenUrl,
	bytes   = #chosen,
	rerun   = function()
		ENV.HC_FORCE = true
		ENV.__HC_MODES_ACTIVE = false
		return chunk()
	end,
}

local ok, err = pcall(chunk)
if not ok then
	ENV.__HC_MODES_ACTIVE = false
	warn("[HC] 运行时报错：" .. tostring(err) .. "\n源：" .. tostring(chosenUrl))
	return
end

-- 跑通了才落盘，避免把错误页面存成"备份"
if type(writefile) == "function" then
	pcall(writefile, CFG.localFile, chosen)
end

log("已启动", "源=" .. tostring(chosenUrl), "大小=" .. #chosen .. "B",
	"重开=getgenv().HC_MODES.rerun()")
