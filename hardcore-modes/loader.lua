--[[
	Hardcore Modes — self-hosted loader  v1.1.0
	------------------------------------------------------------------
	做三件事：
	  1. 多源取 hub 本体（pastefy → 你自己的镜像 → 本地缓存 → 剪贴板）
	  2. 把 hub 里所有指向 Zero0Star 的资源 URL 改写成你自己的仓库
	     （只要 hardcore-modes/assets/* 存在，就能完全脱离原作者，你自己当房主）
	  3. 成功才落盘，并暴露 getgenv().HC_MODES 方便重开

	用法（一行）：
		loadstring(game:HttpGet("https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/loader.lua"))()

	变体：
		getgenv().HC_FORCE = true          强制重载（默认防重入）
		getgenv().HC_SKIP_REWRITE = true   不改写资源 URL（直连原作者）
		getgenv().HC_MODES.rerun()         重跑
--]]

local CFG = {
	name = "HardcoreModes",
	version = "1.1.3",

	minSize = 4000,
	localFile = "hardcore-modes.lua",
	debug = true,

	-- ① hub 本体来源，按顺序试
	sources = {
		-- GitHub Pages：自己的静态服务器，稳定、不回源被打、不依赖任何代理
		"https://3091318935.github.io/Roblox/hardcore-modes/HARDCORE-Modes.lua",
		"https://fastly.jsdelivr.net/gh/3091318935/Roblox@main/hardcore-modes/HARDCORE-Modes.lua",
		"https://gcore.jsdelivr.net/gh/3091318935/Roblox@main/hardcore-modes/HARDCORE-Modes.lua",
		"https://pastefy.app/Bf6hbDY4/raw",
		"https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/HARDCORE-Modes.lua",
		"https://pastefy.app/Bf6hbDY4/raw?cache=0",
	},

	-- ② 你自己的资源目录（mirror.ps1 生成 + push.ps1 上传）
	rewrite = true,
	-- 顺序有意义：执行器所在网络 raw.githubusercontent.com 经常被污染/超时，
	-- 而 jsDelivr 的 fastly 节点基本通，所以 CDN 排前面，raw 只当最后的兜底。
	assetBases = {
		-- ★ 第一位是你自己的 Pages 站：GitHub 直出，无 CDN 缓存延迟、无第三方
		"https://3091318935.github.io/Roblox/hardcore-modes/assets/",
		"https://fastly.jsdelivr.net/gh/3091318935/Roblox@main/hardcore-modes/assets/",
		"https://gcore.jsdelivr.net/gh/3091318935/Roblox@main/hardcore-modes/assets/",
		"https://cdn.jsdelivr.net/gh/3091318935/Roblox@main/hardcore-modes/assets/",
		"https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/assets/",
		"https://ghfast.top/https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/assets/",
	},

	-- 只改写这些人的 URL（别动你自己的）
	foreignHosts = { "zero0star" },
}

local ENV = (getgenv and getgenv()) or _G

local function log(...)
	if CFG.debug then
		print("[HC " .. CFG.version .. "]", ...)
	end
end

----------------------------------------------------------------------
-- 网络：多实现回退
----------------------------------------------------------------------
local function rawHttp(url)
	if type(game) == "table" or type(game) == "userdata" then
		local ok, body = pcall(function()
			return game:HttpGet(url, true)
		end)
		if ok and type(body) == "string" and #body > 0 then
			return body
		end
	end

	local requesters = {
		ENV.syn and ENV.syn.request,
		ENV.http and ENV.http.request,
		ENV.fluxus and ENV.fluxus.request,
		ENV.http_request,
		ENV.request,
	}
	for _, fn in ipairs(requesters) do
		if type(fn) == "function" then
			local ok, res = pcall(fn, { Url = url, Method = "GET" })
			if ok and type(res) == "table" then
				local body = res.Body or res.body
				if type(body) == "string" and #body > 0 then
					return body
				end
			end
		end
	end
	return nil
end

local function looksLikeHtml(s)
	if type(s) ~= "string" then return false end
	local head = s:sub(1, 400):lower()
	return head:find("<!doctype", 1, true) ~= nil
		or head:find("<html", 1, true) ~= nil
		or head:find("just a moment", 1, true) ~= nil
		or head:find("enable javascript", 1, true) ~= nil
		or head:find("cloudflare", 1, true) ~= nil
end

local function checkSource(src)
	if type(src) ~= "string" then return false, "返回空" end
	if #src < CFG.minSize then return false, "太短(" .. #src .. "B)" end
	if src:sub(1, 1) == "<" then return false, "是 HTML" end
	if looksLikeHtml(src) then return false, "是盾/挑战页" end
	if not (src:find("loadstring", 1, true) or src:find("game:", 1, true) or src:find("return", 1, true)) then
		return false, "不像 Lua"
	end
	return true
end

local function tryUrl(url, tag)
	local body = rawHttp(url)
	local ok, why = checkSource(body)
	if ok then
		log("源可用(" .. tag .. ")", url)
		return body
	end
	log("源失败(" .. tag .. ")", url, why)
	return nil
end

----------------------------------------------------------------------
-- 资源 URL 改写：把 Zero0Star 的 .lua 换成本地镜像
----------------------------------------------------------------------
local resolved = {}

local function assetName(url)
	local clean = url:gsub("[?#].*$", "")
	local name = clean:match("([^/]+)$")
	return name
end

local function isForeign(url)
	local low = string.lower(url)
	for _, h in ipairs(CFG.foreignHosts) do
		if low:find(h, 1, true) then return true end
	end
	return false
end

-- 任何 github raw 地址都改走 jsDelivr（不只是 Zero0Star）。
-- 模式文件自己会去拉一堆第三方依赖（实体生成器、成就、贴图…），
-- 那些仓库一旦改名/删库/DNS 抽风，整段 loadstring 就在第 8 行炸掉。
local function isRawGithub(url)
	return string.find(string.lower(url), "raw.githubusercontent.com", 1, true) ~= nil
end

-- 值不值得拦：自己的目标仓库，或者任何 github raw 地址
local function interested(url)
	return isForeign(url) or isRawGithub(url)
end

-- raw.githubusercontent.com/User/Repo/branch/path  →  jsDelivr 同等地址
-- 兼容带 refs/heads/<branch>/ 的写法。
local function cdnify(url)
	local user, repo, rest = url:match(
		"raw%.githubusercontent%.com/([^/]+)/([^/]+)/(.+)$"
	)
	if not user or not rest then return nil end

	local branch, path = rest:match("^refs/heads/([^/]+)/(.+)$")
	if not branch then
		branch, path = rest:match("^([^/]+)/(.+)$")
	end
	if not branch or not path then return nil end

	return string.format(
		"https://fastly.jsdelivr.net/gh/%s/%s@%s/%s",
		user, repo, branch, path
	)
end

-- 拉回来的东西到底是不是脚本：CDN 的 404 页、Cloudflare 页都不算
local function usable(body)
	if type(body) ~= "string" or #body < 32 then return false end
	if looksLikeHtml(body) then return false end
	if body:sub(1, 1) == "<" then return false end
	if body:find("Couldn't find the requested file", 1, true) then return false end
	if body:find("Couldn’t find the requested file", 1, true) then return false end
	if body:find("404: Not Found", 1, true) then return false end
	if body:find("Package size exceeded", 1, true) then return false end
	return true
end

local function fetchAsset(url)
	if resolved[url] ~= nil then
		return resolved[url] or nil
	end

	local name = assetName(url)
	if not name or name == "" then
		resolved[url] = false
		return nil
	end

	-- 音视频体积大、数量多，默认放行原地址；只镜像 .lua 和裸数据文件
	if name:lower():match("%.mp3$") or name:lower():match("%.ogg$") then
		resolved[url] = false
		return nil
	end

	-- ① 自己的仓库镜像（只有 Zero0Star 那些文件我们有对应副本，按文件名匹配）
	if isForeign(url) then
		for _, base in ipairs(CFG.assetBases) do
			local body = rawHttp(base .. name)
			if usable(body) then
				log("改用镜像资源", name, #body .. "B")
				resolved[url] = body
				return body
			end
		end
	end

	-- ② 其余一律转 jsDelivr 同仓库地址（Vynixu 实体生成器、成就、贴图…）
	local alt = cdnify(url)
	if alt then
		local body = rawHttp(alt)
		if usable(body) then
			log("走 CDN 代原作者", name, #body .. "B")
			resolved[url] = body
			return body
		end
	end

	log("改不动，回退原地址", name)
	resolved[url] = false
	return nil
end

local function installRewrite()
	if not CFG.rewrite then return end
	if ENV.HC_SKIP_REWRITE then return end
	if ENV.__HC_REWRITE then return end
	ENV.__HC_REWRITE = true

	local hooked = false

	-- 方式一：直接给 game.HttpGet 赋值（多数执行器允许）
	local oldGet = game.HttpGet
	if type(oldGet) == "function" then
		local function newGet(self, url, ...)
			if type(url) == "string" and interested(url) then
				local body = fetchAsset(url)
				if body then return body end
			end
			return oldGet(self, url, ...)
		end
		local okAssign = pcall(function() game.HttpGet = newGet end)
		if okAssign and game.HttpGet == newGet then
			hooked = true
			log("改写钩子已装 (game.HttpGet 赋值)")
		elseif type(hookfunction) == "function" then
			-- 多数现代执行器把 game.HttpGet 设成只读，赋值静默失败，
			-- 这时必须用 hookfunction 换掉底层 C 闭包。
			local okHook = pcall(function() hookfunction(oldGet, newGet) end)
			if okHook then
				hooked = true
				log("改写钩子已装 (hookfunction)")
			end
		end
	end

	local oldAsync = game.HttpGetAsync
	if type(oldAsync) == "function" then
		pcall(function()
			game.HttpGetAsync = function(self, url, ...)
				if type(url) == "string" and interested(url) then
					local body = fetchAsset(url)
					if body then return body end
				end
				return oldAsync(self, url, ...)
			end
		end)
	end

	-- 方式二：namecall 兜底
	if not hooked and type(hookmetamethod) == "function" then
		local mt = getrawmetatable and getrawmetatable(game)
		if mt and type(mt.__namecall) == "function" then
			local oldNamecall = mt.__namecall
			local okHook = pcall(function()
				if type(setreadonly) == "function" then setreadonly(mt, false) end
				mt.__namecall = newcclosure(function(self, ...)
					local method = getnamecallmethod()
					if (method == "HttpGet" or method == "HttpGetAsync") and self == game then
						local url = ...
						if type(url) == "string" and interested(url) then
							local body = fetchAsset(url)
							if body then return body end
						end
					end
					return oldNamecall(self, ...)
				end)
				if type(setreadonly) == "function" then setreadonly(mt, true) end
			end)
			if okHook then
				hooked = true
				log("改写钩子已装 (__namecall)")
			end
		end
	end

	-- 方式三：执行器提供的 hookmetamethod（比自己改元表更稳）
	if not hooked and type(hookmetamethod) == "function" then
		local okHook = pcall(function()
			local oldNamecall
			oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
				local method = getnamecallmethod()
				if (method == "HttpGet" or method == "HttpGetAsync") and self == game then
					local url = ...
					if type(url) == "string" and interested(url) then
						local body = fetchAsset(url)
						if body then return body end
					end
				end
				return oldNamecall(self, ...)
			end)
		end)
		if okHook then
			hooked = true
			log("改写钩子已装 (hookmetamethod)")
		end
	end

	if not hooked then
		log("改写钩子装不上，本次直连原作者资源")
	end
end

----------------------------------------------------------------------
-- 主流程
----------------------------------------------------------------------
local function run()
	if ENV.__HC_MODES_ACTIVE and not ENV.HC_FORCE then
		log("已经在运行了；想强开 getgenv().HC_FORCE = true")
		return nil
	end
	ENV.__HC_MODES_ACTIVE = nil

	local chosen, chosenUrl

	for _, url in ipairs(CFG.sources) do
		local body = tryUrl(url, "hub")
		if body then
			chosen, chosenUrl = body, url
			break
		end
	end

	if not chosen and type(readfile) == "function" and type(isfile) == "function" then
		local ok, body = pcall(function()
			if isfile(CFG.localFile) then return readfile(CFG.localFile) end
		end)
		local valid, why = checkSource(ok and body or nil)
		if valid then
			chosen, chosenUrl = body, "local:" .. CFG.localFile
			log("用本地缓存", #body .. "B")
		elseif ok then
			log("本地缓存不可用", why)
		end
	end

	if not chosen and type(getclipboard) == "function" then
		local ok, body = pcall(getclipboard)
		local valid = checkSource(ok and body or nil)
		if valid then
			chosen, chosenUrl = body, "clipboard"
			log("用剪贴板", #body .. "B")
		end
	end

	if not chosen then
		warn("[HC] 所有源都失败，hub 没取到。检查网络 / pastefy 是否还在 / 或者先跑 mirror.ps1")
		return nil
	end

	installRewrite()

	local chunk, cerr = loadstring(chosen, "=" .. CFG.name)
	if not chunk then
		warn("[HC] 编译失败: " .. tostring(cerr))
		return nil
	end

	local ok, err = pcall(chunk)
	ENV.__HC_MODES_ACTIVE = true

	if not ok then
		warn("[HC] 运行出错: " .. tostring(err))
		return nil
	end

	if type(writefile) == "function" then
		pcall(writefile, CFG.localFile, chosen)
	end

	local info = {
		version = CFG.version,
		source = chosenUrl,
		bytes = #chosen,
		rerun = run,
	}
	ENV.HC_MODES = info

	print(string.format("[HC %s] 已启动  源=%s  大小=%dB", CFG.version, chosenUrl, #chosen))
	return info
end

local ok, res = pcall(run)
if not ok then
	warn("[HC] 启动异常: " .. tostring(res))
end
return res
