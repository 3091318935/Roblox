--=====================================================================
--  Doors HardCore  ·  无痕玻璃  Seamless Glass  (v3)
--  运行时换肤 + 壁纸引擎 + 光影风格包 + 中文翻译
-----------------------------------------------------------------------
--  原脚本（一行未改）：
--    https://raw.githubusercontent.com/Zero0Star/RipperNewSound/master/Doors-HardCore.lua
--
--  v3 相对 v2：
--    · 删掉「材质覆写」，只保留光影（不碰场景部件，零副作用）
--    · 光影改成和壁纸一样的「识别链接」：内置 MC 系风格 / JSON 光影包 / 图片滤色
--    · 文案换成正常流畅的中文翻译（不再是文言）
--    · 壁纸支持视频：Roblox 视频资产 / 视频页链接 → 自动识别并循环播放
--    · 壁纸自动识别序列帧长图（一张横条 = 一段动画）
--    · 控制面板瘦身 + 整块可拖动；被换肤的窗口也挂一个拖动把手
--
--  用法：整段粘进执行器回车；或 loadstring 远程载入
--  面板：F2 开合
--=====================================================================

local CONFIG = {
	scriptUrl    = "https://raw.githubusercontent.com/Zero0Star/RipperNewSound/master/Doors-HardCore.lua",
	runOriginal  = true,
	waitTimeout  = 30,
	watchSeconds = 120,
	panelKey     = Enum.KeyCode.F2,

	theme = {
		accent    = Color3.fromRGB(0, 200, 0),
		glass     = 0.74,
		border    = 0.30,
		corner    = 14,
		scale     = 1,
		seamless  = true,
		chrome    = true,
		translate = true,
		grip      = true,
	},
	backdrop = {
		items        = {},
		mode         = "auto",   -- auto / still / pan / cross / strip / video / aurora
		hold         = 8,
		speed        = 1,
		dim          = 0.18,
		wall         = 0.95,
		aurora       = true,
		dust         = false,
		blur         = 8,
		followWindow = true,
	},
	shade = {
		preset = "vanilla",
		power  = 1,
	},
}

--=====================================================================
--  0 · 工具
--=====================================================================
local Players          = game:GetService("Players")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local function schedule(fn, ...)
	if task and task.spawn then return task.spawn(fn, ...) end
	return coroutine.wrap(fn)(...)
end

local function pause(s)
	if task and task.wait then return task.wait(s) end
	return wait(s)
end

local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end

local function round(v) return math.floor(v + 0.5) end
local function trim(s) return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1")) end

local function fontOf(name, fb)
	local ok, f = pcall(function() return Enum.Font[name] end)
	if ok and f then return f end
	return fb
end
local FONT_BODY = fontOf("GothamMedium", Enum.Font.SourceSansSemibold)
local FONT_BOLD = fontOf("GothamBold", Enum.Font.SourceSansBold)

local function make(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			local ok = pcall(function() o[k] = v end)
			if not ok then warn("[SG] 设置失败 " .. tostring(class) .. "." .. tostring(k)) end
		end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end

local function viewport()
	local cam = workspace.CurrentCamera
	if cam then return cam.ViewportSize end
	return Vector2.new(1920, 1080)
end

local function lum(c) return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B end
local function sat(c) return math.max(c.R, c.G, c.B) - math.min(c.R, c.G, c.B) end
local function hueOf(c) return c:ToHSV() end

local function hash(s)
	local h = 5381
	for i = 1, #s do h = (h * 33 + s:byte(i)) % 2147483647 end
	return h
end

local function extOf(s)
	local path = tostring(s or ""):match("^[^?]*") or ""
	local e = path:match("%.([%w]+)$")
	if e then return e:lower() end
	return ""
end

-- Roblox 资源 id：纯数字 / rbxassetid / 库页链接 / 资产页 / 视频页
local function robloxId(s)
	s = tostring(s or "")
	local id = s:match("^rbxassetid://(%d+)")
	if id then return id end
	if s:match("^%d+$") then return s end
	local low = s:lower()
	return low:match("roblox%.com/library/(%d+)")
		or low:match("store/asset/(%d+)")
		or low:match("roblox%.com/videos/(%d+)")
		or low:match("assetid=(%d+)")
end

local VIDEO_EXT = { mp4 = true, webm = true, mov = true, m4v = true, avi = true, mkv = true }

local function isVideoUrl(s)
	s = tostring(s or "")
	local low = s:lower()
	if low:find("/videos/") then return true end
	if VIDEO_EXT[extOf(low)] then return true end
	return false
end

-- 从图片字节流读尺寸，用来识别「一整条序列帧」
local function imageDims(bytes)
	if type(bytes) ~= "string" or #bytes < 24 then return nil end
	if bytes:sub(1, 8) == "\137PNG\r\n\26\n" then
		local w = bytes:byte(17) * 16777216 + bytes:byte(18) * 65536 + bytes:byte(19) * 256 + bytes:byte(20)
		local h = bytes:byte(21) * 16777216 + bytes:byte(22) * 65536 + bytes:byte(23) * 256 + bytes:byte(24)
		if w and h and w > 0 and h > 0 then return w, h end
		return nil
	end
	if bytes:sub(1, 2) == "\255\216" then
		local i = 3
		while i < #bytes - 8 do
			if bytes:byte(i) ~= 255 then
				i = i + 1
			else
				local m = bytes:byte(i + 1)
				if m == 192 or m == 193 or m == 194 then
					local h = bytes:byte(i + 5) * 256 + bytes:byte(i + 6)
					local w = bytes:byte(i + 7) * 256 + bytes:byte(i + 8)
					if w and h and w > 0 and h > 0 then return w, h end
					return nil
				elseif m == 216 or m == 217 or (m >= 208 and m <= 215) then
					i = i + 2
				else
					local len = bytes:byte(i + 2) * 256 + bytes:byte(i + 3)
					if not len or len < 2 then return nil end
					i = i + 2 + len
				end
			end
		end
		return nil
	end
	if bytes:sub(1, 3) == "GIF" then
		local w = bytes:byte(7) + bytes:byte(8) * 256
		local h = bytes:byte(9) + bytes:byte(10) * 256
		if w and h and w > 0 and h > 0 then return w, h end
	end
	return nil
end

--=====================================================================
--  1 · 状态
--=====================================================================
local T = {
	accent    = CONFIG.theme.accent,
	glass     = CONFIG.theme.glass,
	border    = CONFIG.theme.border,
	corner    = CONFIG.theme.corner,
	scale     = CONFIG.theme.scale,
	seamless  = CONFIG.theme.seamless,
	chrome    = CONFIG.theme.chrome,
	translate = CONFIG.theme.translate,
	grip      = CONFIG.theme.grip,

	mode         = CONFIG.backdrop.mode,
	hold         = CONFIG.backdrop.hold,
	speed        = CONFIG.backdrop.speed,
	dim          = CONFIG.backdrop.dim,
	wallAlpha    = CONFIG.backdrop.wall,
	aurora       = CONFIG.backdrop.aurora,
	dust         = CONFIG.backdrop.dust,
	blur         = CONFIG.backdrop.blur,
	followWindow = CONFIG.backdrop.followWindow,

	shadePower = CONFIG.shade.power,
	tab        = "look",

	tint  = Color3.fromRGB(9, 20, 16),
	tint2 = Color3.fromRGB(22, 36, 30),
	text  = Color3.fromRGB(238, 250, 243),
	dimc  = Color3.fromRGB(150, 172, 160),
}

local Reg = {
	done   = setmetatable({}, { __mode = "k" }),
	style  = setmetatable({}, { __mode = "k" }),
	text   = setmetatable({}, { __mode = "k" }),
	origBG = setmetatable({}, { __mode = "k" }),
	origBT = setmetatable({}, { __mode = "k" }),
	origTx = setmetatable({}, { __mode = "k" }),
	origSt = setmetatable({}, { __mode = "k" }),
	mapOut = setmetatable({}, { __mode = "k" }),
	corner = setmetatable({}, { __mode = "k" }),
	stroke = setmetatable({}, { __mode = "k" }),
	scales = setmetatable({}, { __mode = "k" }),
	grips  = setmetatable({}, { __mode = "k" }),
	windows= setmetatable({}, { __mode = "k" }),
	guis   = setmetatable({}, { __mode = "k" }),
	shadow = {},
}

local P = {
	gui = nil, card = nil, tabsRow = nil, content = nil,
	renders = {}, hooks = {}, rebuildList = nil,
	sliderBusy = false, tabButtons = {}, pages = {},
}

local containers -- 前置声明

--=====================================================================
--  2 · 挂载点
--=====================================================================
local function guiParents()
	local list = {}
	if gethui then table.insert(list, function() return gethui() end) end
	table.insert(list, function() return game:GetService("CoreGui") end)
	table.insert(list, function() return LocalPlayer:WaitForChild("PlayerGui", 8) end)
	return list
end

local function attachGui(gui)
	for _, f in ipairs(guiParents()) do
		local ok = pcall(function() gui.Parent = f() end)
		if ok and gui.Parent then return gui.Parent end
	end
	return nil
end

--=====================================================================
--  3 · 资源解析（图片 / 视频，直链落到本地缓存）
--=====================================================================
local AssetCache = {}

local function fileApi()
	return type(writefile) == "function" and type(getcustomasset) == "function"
end

local function ensureDir()
	if type(isfolder) == "function" and type(makefolder) == "function" then
		local ok = false
		pcall(function() ok = isfolder("SG_Assets") end)
		if ok then return "SG_Assets/" end
		local made = false
		pcall(function()
			makefolder("SG_Assets")
			made = true
		end)
		if made then return "SG_Assets/" end
	end
	return ""
end

local function downloadTo(url, ext)
	local dir = ensureDir()
	local path = dir .. tostring(hash(url)) .. "." .. ext
	if type(isfile) == "function" then
		local exist = false
		pcall(function() exist = isfile(path) end)
		if exist then return path end
	end
	writefile(path, game:HttpGet(url, true))
	return path
end

local function resolveImage(url)
	url = trim(url):gsub("%s+", "")
	if url == "" then return nil, "地址是空的" end
	local low = url:lower()
	if url:match("^%d+$") then return { id = "rbxassetid://" .. url, kind = "image" } end
	if low:sub(1, 11) == "rbxassetid" then return { id = url, kind = "image" } end
	if low:sub(1, 8) == "rbxasset" then return { id = url, kind = "image" } end
	if AssetCache[url] then return AssetCache[url] end
	if not low:match("^https?://") then return nil, "不认识的地址" end
	if not fileApi() then return nil, "执行器缺少 writefile / getcustomasset" end

	local ok, res = pcall(function()
		local ext = extOf(low)
		if ext ~= "png" and ext ~= "jpg" and ext ~= "jpeg" and ext ~= "webp" and ext ~= "bmp" and ext ~= "gif" then
			ext = "png"
		end
		local path = downloadTo(url, ext)
		local bytes
		pcall(function() bytes = readfile(path) end)
		local w, h = imageDims(bytes)
		return { id = getcustomasset(path), w = w, h = h, kind = "image", path = path }
	end)
	if ok and res then
		AssetCache[url] = res
		return res
	end
	return nil, tostring(res)
end

local function resolveVideo(url)
	url = trim(url):gsub("%s+", "")
	if url == "" then return nil, "地址是空的" end
	local id = robloxId(url)
	if id then return { id = "rbxassetid://" .. id, kind = "video" } end
	if not url:match("^https?://") then return { id = url, kind = "video" } end
	if not fileApi() then return nil, "执行器缺少 writefile / getcustomasset" end
	local ok, res = pcall(function()
		local ext = extOf(url)
		if not VIDEO_EXT[ext] then ext = "mp4" end
		local path = downloadTo(url, ext)
		return { id = getcustomasset(path), kind = "video", path = path }
	end)
	if ok and res then return res end
	return nil, tostring(res)
end

--=====================================================================
--  4 · 提示条
--=====================================================================
local Toast = { gui = nil, box = nil, label = nil, token = 0 }

local function toast(msg)
	pcall(function()
		if not (Toast.gui and Toast.gui.Parent) then
			local gui = Instance.new("ScreenGui")
			gui.Name = "SG_Toast"
			gui.IgnoreGuiInset = true
			gui.ResetOnSpawn = false
			gui.DisplayOrder = 1000001
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			attachGui(gui)
			Toast.gui = gui
			local box = make("Frame", {
				Name = "SG_ToastBox",
				Size = UDim2.new(0, 0, 0, 28),
				Position = UDim2.new(0.5, 0, 1, -64),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = T.tint,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = gui,
			})
			make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = box })
			make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.86, Thickness = 1, Parent = box })
			local label = make("TextLabel", {
				Text = "",
				Size = UDim2.new(1, -24, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				BackgroundTransparency = 1,
				Font = FONT_BODY,
				TextSize = 11,
				TextColor3 = T.text,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = box,
			})
			Toast.box, Toast.label = box, label
		end
		local box, label = Toast.box, Toast.label
		label.Text = tostring(msg)
		label.TextTransparency = 0
		box.BackgroundTransparency = 1 - clamp(T.glass, 0.3, 0.92)
		box.Size = UDim2.new(0, math.clamp(#tostring(msg) * 11 + 30, 110, 420), 0, 28)
		Toast.token = Toast.token + 1
		local my = Toast.token
		schedule(function()
			pause(2.6)
			if Toast.token ~= my then return end
			TweenService:Create(box, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		end)
	end)
end

--=====================================================================
--  5 · 壁纸引擎（图片 / 序列帧 / 视频）
--=====================================================================
local Wall = {
	gui = nil, holder = nil, layerA = nil, layerB = nil, video = nil,
	scrim = nil, vig = nil, aurora = nil, dust = nil, front = nil,
	gen = 0, idx = 1, items = {}, fading = false, note = "还没有壁纸",
}

local function wallGui()
	if Wall.gui and Wall.gui.Parent then return Wall.gui end

	local gui = Instance.new("ScreenGui")
	gui.Name = "SG_Backdrop"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -10
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	attachGui(gui)
	Wall.gui = gui

	local holder = make("Frame", {
		Name = "SG_Holder",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = gui,
	})
	Wall.holder = holder

	local function newLayer(name, z)
		return make("ImageLabel", {
			Name = name,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "",
			ImageTransparency = 1,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = z,
			Parent = holder,
		})
	end
	Wall.layerA = newLayer("LayerA", 1)
	Wall.layerB = newLayer("LayerB", 2)
	Wall.front = Wall.layerA

	local aurora = make("Frame", {
		Name = "SG_Aurora",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = holder,
	})
	make("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, T.accent),
			ColorSequenceKeypoint.new(0.5, Color3.new(0.4, 0.9, 1)),
			ColorSequenceKeypoint.new(1, T.accent),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.96),
			NumberSequenceKeypoint.new(0.45, 0.88),
			NumberSequenceKeypoint.new(1, 0.97),
		}),
		Parent = aurora,
	})
	Wall.aurora = aurora

	local dust = make("Frame", {
		Name = "SG_Dust",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 4,
		Parent = holder,
	})
	Wall.dust = dust
	for i = 1, 14 do
		local dot = make("Frame", {
			Name = "Mote" .. i,
			Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4)),
			Position = UDim2.new(math.random(), 0, math.random(), 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = dust,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		local startY = dot.Position.Y.Scale
		TweenService:Create(dot, TweenInfo.new(math.random(9, 20) + math.random(), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
			Position = UDim2.new(dot.Position.X.Scale, 0, startY - 0.18, 0),
			BackgroundTransparency = 1,
		}):Play()
	end

	local vig = make("Frame", {
		Name = "SG_Vignette",
		Size = UDim2.new(1, 0, 0.55, 0),
		Position = UDim2.new(0, 0, 0.45, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = holder,
	})
	make("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.2),
		}),
		Parent = vig,
	})
	Wall.vig = vig

	Wall.scrim = make("Frame", {
		Name = "SG_Scrim",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1 - T.dim,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = holder,
	})

	return gui
end

local function frontAlpha() return 1 - clamp(T.wallAlpha, 0, 1) end

local function applyLook()
	if not (Wall.gui and Wall.gui.Parent) then return end
	if Wall.scrim then Wall.scrim.BackgroundTransparency = 1 - clamp(T.dim, 0, 0.95) end
	if not Wall.fading then
		if Wall.layerA then Wall.layerA.ImageTransparency = (Wall.front == Wall.layerA) and frontAlpha() or 1 end
		if Wall.layerB then Wall.layerB.ImageTransparency = (Wall.front == Wall.layerB) and frontAlpha() or 1 end
	end
	if Wall.aurora then
		Wall.aurora.Visible = T.aurora
		local g = Wall.aurora:FindFirstChildOfClass("UIGradient")
		if g then
			local h = hueOf(T.accent)
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(h, 0.55, 0.95)),
				ColorSequenceKeypoint.new(0.5, Color3.fromHSV((h + 0.14) % 1, 0.62, 0.85)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV((h + 0.86) % 1, 0.5, 0.7)),
			})
		end
	end
	if Wall.dust then Wall.dust.Visible = T.dust end
end

local function kenBurns(layer)
	local sc = 1.05 + math.random() * 0.07
	local px = (math.random() - 0.5) * 0.06
	local py = (math.random() - 0.5) * 0.06
	layer.AnchorPoint = Vector2.new(0.5, 0.5)
	layer.Size = UDim2.new(1, 0, 1, 0)
	layer.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(layer, TweenInfo.new(math.max(5, T.hold * 1.7), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Size = UDim2.new(sc, 0, sc, 0),
		Position = UDim2.new(0.5 + px, 0, 0.5 + py, 0),
	}):Play()
end

local function stopVideo()
	if Wall.video and Wall.video.Parent then Wall.video:Destroy() end
	Wall.video = nil
end

-- 视频：VideoFrame + 双保险循环
local function playVideo(item, gen)
	stopVideo()
	if Wall.layerA then Wall.layerA.ImageTransparency = 1 end
	if Wall.layerB then Wall.layerB.ImageTransparency = 1 end
	Wall.front = nil

	local ok, vf = pcall(function()
		local v = Instance.new("VideoFrame")
		v.Name = "SG_Video"
		v.Size = UDim2.new(1, 0, 1, 0)
		v.BackgroundTransparency = 1
		v.ZIndex = 2
		v.Volume = 0
		v.Looped = true
		v.Video = item.id
		v.Playing = true
		v.Parent = Wall.holder
		return v
	end)

	if not ok or not vf then
		Wall.note = "视频播放器创建失败，已退回图片模式"
		toast(Wall.note)
		return false
	end
	Wall.video = vf

	pcall(function()
		vf.Ended:Connect(function()
			if gen ~= Wall.gen then return end
			vf.TimePosition = 0
			vf.Playing = true
		end)
	end)

	schedule(function()
		local waited = 0
		while gen == Wall.gen and vf.Parent do
			pause(1)
			waited = waited + 1
			pcall(function()
				if not vf.Playing then vf.Playing = true end
				local len = vf.TimeLength or 0
				if len > 0 and (vf.TimePosition or 0) >= len - 0.05 then vf.TimePosition = 0 end
			end)
			if waited == 5 then
				local loaded = false
				pcall(function() loaded = vf.IsLoaded end)
				if not loaded then
					Wall.note = "视频没加载出来：需要 Roblox 视频资产（直链要先上传成视频）"
					toast(Wall.note)
				end
			end
		end
	end)
	return true
end

local function modeFor(item)
	if T.mode ~= "auto" then return T.mode end
	if item.kind == "video" then return "video" end
	if item.kind == "strip" then return "strip" end
	return "pan"
end

function Wall.play()
	Wall.gen = Wall.gen + 1
	local gen = Wall.gen

	if #Wall.items == 0 then
		if Wall.layerA then Wall.layerA.Image = ""; Wall.layerA.ImageTransparency = 1 end
		if Wall.layerB then Wall.layerB.Image = ""; Wall.layerB.ImageTransparency = 1 end
		stopVideo()
		Wall.front = nil
		return
	end

	schedule(function()
		while gen == Wall.gen do
			local item = Wall.items[Wall.idx]
			if not item then Wall.idx = 1; item = Wall.items[1] end
			if not item then break end
			Wall.idx = Wall.idx % math.max(1, #Wall.items) + 1

			local mode = modeFor(item)

			if mode == "video" then
				playVideo(item, gen)
				pause(math.max(6, T.hold))
			elseif mode == "strip" then
				stopVideo()
				local frames = math.max(2, math.min(96, item.frames or 12))
				local fw = 1
				if item.w and item.h and item.h > 0 then
					fw = math.floor(item.w / frames)
					if fw < 1 then fw = 1 end
				end
				local layer = Wall.layerA
				layer.Image = item.id or ""
				layer.AnchorPoint = Vector2.new(0, 0)
				layer.Size = UDim2.new(1, 0, 1, 0)
				layer.Position = UDim2.new(0, 0, 0, 0)
				layer.ImageTransparency = frontAlpha()
				if item.w and item.h then
					layer.ImageRectSize = Vector2.new(fw, math.floor(item.h))
				else
					layer.ImageRectSize = Vector2.new(0, 0)
				end
				layer.ImageRectOffset = Vector2.new(0, 0)
				Wall.front = layer
				Wall.fading = false
				if Wall.layerB then Wall.layerB.ImageTransparency = 1 end
				local inner = gen
				schedule(function()
					local f = 0
					while inner == Wall.gen do
						f = (f + 1) % frames
						layer.ImageRectOffset = Vector2.new(f * fw, 0)
						pause(1 / math.max(1, T.speed * 12))
					end
				end)
				pause(3600)
			elseif mode == "still" then
				stopVideo()
				local layer = Wall.layerB
				layer.Image = item.id or ""
				layer.ImageRectSize = Vector2.new(0, 0)
				layer.ImageRectOffset = Vector2.new(0, 0)
				layer.AnchorPoint = Vector2.new(0.5, 0.5)
				layer.Size = UDim2.new(1, 0, 1, 0)
				layer.Position = UDim2.new(0.5, 0, 0.5, 0)
				layer.ImageTransparency = 1
				Wall.front = layer
				applyLook()
				pause(3600)
			elseif mode == "aurora" then
				stopVideo()
				if Wall.layerA then Wall.layerA.Image = ""; Wall.layerA.ImageTransparency = 1 end
				if Wall.layerB then Wall.layerB.Image = ""; Wall.layerB.ImageTransparency = 1 end
				pause(3600)
			else
				stopVideo()
				local a, b = Wall.layerA, Wall.layerB
				local back = (Wall.front ~= b) and b or a
				local old = Wall.front
				if back then
					back.Image = item.id or ""
					back.ImageRectSize = Vector2.new(0, 0)
					back.ImageRectOffset = Vector2.new(0, 0)
					back.ImageTransparency = 1
					kenBurns(back)
					Wall.fading = true
					TweenService:Create(back, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { ImageTransparency = frontAlpha() }):Play()
					if old then
						TweenService:Create(old, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { ImageTransparency = 1 }):Play()
					end
					Wall.front = back
					pause(0.95)
					Wall.fading = false
				end
				pause(math.max(2, T.hold))
			end
		end
	end)
end

local function describe(item)
	if item.kind == "video" then
		if item.path then return "已识别：视频直链（已下载，需上传成 Roblox 视频资产才能播）" end
		return "已识别：Roblox 视频资产（循环播放）"
	end
	if item.kind == "strip" then
		return string.format("已识别：序列帧长图 %d×%d，切 %d 帧", item.w or 0, item.h or 0, item.frames or 1)
	end
	if item.w and item.h then
		return string.format("已识别：图片 %d×%d", item.w, item.h)
	end
	return "已识别：图片"
end

function Wall.add(url)
	url = trim(url)
	if url == "" then return false, "地址是空的" end

	local asset, err
	if isVideoUrl(url) then
		asset, err = resolveVideo(url)
	else
		asset, err = resolveImage(url)
	end
	if not asset or not asset.id then return false, err or "识别失败" end

	local item = {
		url = url,
		id = asset.id,
		kind = asset.kind or "image",
		w = asset.w,
		h = asset.h,
		path = asset.path,
	}

	-- 长图自动识别成序列帧
	if item.kind == "image" and item.w and item.h and item.h > 0 then
		local ratio = item.w / item.h
		local n = round(ratio)
		if ratio >= 3 and n >= 3 and math.abs(ratio - n) < 0.05 and item.h <= 512 then
			item.kind = "strip"
			item.frames = n
		end
	end

	table.insert(Wall.items, item)
	Wall.idx = math.max(1, #Wall.items - 1)
	Wall.note = describe(item)
	if P.rebuildList then pcall(P.rebuildList) end
	Wall.play()
	return true, Wall.note
end

function Wall.remove(idx)
	table.remove(Wall.items, idx)
	if Wall.idx > #Wall.items then Wall.idx = 1 end
	if P.rebuildList then pcall(P.rebuildList) end
	Wall.play()
end

function Wall.clear()
	Wall.items = {}
	Wall.idx = 1
	Wall.note = "还没有壁纸"
	if P.rebuildList then pcall(P.rebuildList) end
	Wall.play()
end

function Wall.refresh()
	wallGui()
	applyLook()
end

--=====================================================================
--  6 · 光影（内置 MC 系风格 / JSON 光影包 / 图片滤色）
--=====================================================================
local Shade = {
	label = "原版",
	profileKey = "vanilla",
	profile = nil,
	effects = {},
	saved = nil,
	atmoSaved = nil,
	filter = nil,
	filterGui = nil,
	filterActive = false,
	entryNote = "尚未应用光影",
}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- 把「我的世界光影」的观感，映射到 Roblox 自带的色调映射 / 泛光 / 景深 / 太阳光 / 雾
local SHADES = {
	vanilla = {
		name = "原版",
		lighting = { Brightness = 1, Ambient = rgb(70, 70, 70), OutdoorAmbient = rgb(70, 70, 70), ColorShift_Top = rgb(255, 255, 255) },
		bloom = { Intensity = 0.25, Size = 16, Threshold = 1.2 },
	},
	bsl = {
		name = "BSL 风格",
		lighting = { Brightness = 1.25, Ambient = rgb(84, 96, 112), OutdoorAmbient = rgb(78, 92, 108), ColorShift_Top = rgb(255, 240, 214), ExposureCompensation = 0.1 },
		cc = { TintColor = rgb(255, 244, 226), Contrast = 0.16, Saturation = 0.18, Brightness = 0.02 },
		bloom = { Intensity = 0.7, Size = 26, Threshold = 1.05 },
		sun = { Intensity = 0.12, Spread = 0.9 },
		atmosphere = { Density = 0.32, Haze = 1.6, Color = rgb(199, 208, 220), Decay = rgb(106, 112, 125), Glare = 0.15 },
	},
	complementary = {
		name = "Complementary 风格",
		lighting = { Brightness = 1.3, Ambient = rgb(96, 88, 104), OutdoorAmbient = rgb(88, 84, 100), ColorShift_Top = rgb(255, 226, 190), ExposureCompensation = 0.15 },
		cc = { TintColor = rgb(255, 232, 208), Contrast = 0.22, Saturation = 0.28, Brightness = 0.03 },
		bloom = { Intensity = 0.85, Size = 30, Threshold = 0.95 },
		sun = { Intensity = 0.16, Spread = 1 },
		atmosphere = { Density = 0.28, Haze = 1.2, Color = rgb(214, 210, 226), Decay = rgb(120, 108, 128), Glare = 0.2 },
	},
	seus = {
		name = "SEUS 风格",
		lighting = { Brightness = 1.1, Ambient = rgb(64, 74, 90), OutdoorAmbient = rgb(60, 70, 88), ColorShift_Top = rgb(232, 240, 255) },
		cc = { TintColor = rgb(236, 244, 255), Contrast = 0.3, Saturation = 0.08, Brightness = -0.01 },
		bloom = { Intensity = 0.5, Size = 20, Threshold = 1.15 },
		dof = { FarIntensity = 0.12, FocusDistance = 22, InFocusRadius = 44, NearIntensity = 0.12 },
		sun = { Intensity = 0.1, Spread = 0.8 },
	},
	sildur = {
		name = "Sildur 风格",
		lighting = { Brightness = 1.2, Ambient = rgb(88, 90, 96), OutdoorAmbient = rgb(84, 86, 94), ColorShift_Top = rgb(255, 236, 210) },
		cc = { TintColor = rgb(255, 240, 224), Contrast = 0.1, Saturation = 0.22, Brightness = 0.04 },
		bloom = { Intensity = 0.95, Size = 34, Threshold = 0.9 },
		sun = { Intensity = 0.2, Spread = 1 },
	},
	kuda = {
		name = "Kuda 风格",
		lighting = { Brightness = 1.35, Ambient = rgb(78, 88, 104), OutdoorAmbient = rgb(74, 84, 100), ColorShift_Top = rgb(232, 244, 255) },
		cc = { TintColor = rgb(232, 244, 255), Contrast = 0.12, Saturation = 0.05, Brightness = 0.04 },
		bloom = { Intensity = 0.45, Size = 22, Threshold = 1.2 },
	},
	night = {
		name = "夜色",
		lighting = { Brightness = 0.7, Ambient = rgb(46, 54, 76), OutdoorAmbient = rgb(42, 50, 72), ColorShift_Top = rgb(150, 172, 220) },
		cc = { TintColor = rgb(190, 210, 255), Contrast = 0.18, Saturation = -0.1, Brightness = -0.02 },
		bloom = { Intensity = 0.4, Size = 18, Threshold = 1.1 },
		atmosphere = { Density = 0.4, Haze = 2, Color = rgb(120, 140, 180), Decay = rgb(60, 70, 100), Glare = 0.05 },
	},
	cinema = {
		name = "暖调电影",
		lighting = { Brightness = 1.15, Ambient = rgb(76, 72, 66), OutdoorAmbient = rgb(70, 68, 62), ColorShift_Top = rgb(255, 240, 214) },
		cc = { TintColor = rgb(255, 236, 210), Contrast = 0.14, Saturation = 0.1, Brightness = 0.02 },
		bloom = { Intensity = 0.55, Size = 22, Threshold = 1.05 },
		dof = { FarIntensity = 0.14, FocusDistance = 18, InFocusRadius = 46, NearIntensity = 0.16 },
	},
	moon = {
		name = "冷月",
		lighting = { Brightness = 0.85, Ambient = rgb(58, 66, 86), OutdoorAmbient = rgb(52, 60, 82), ColorShift_Top = rgb(196, 214, 255) },
		cc = { TintColor = rgb(206, 226, 255), Contrast = 0.1, Saturation = -0.06, Brightness = 0.01 },
		bloom = { Intensity = 0.35, Size = 18, Threshold = 1.2 },
	},
	neon = {
		name = "霓虹",
		lighting = { Brightness = 1.3, Ambient = rgb(46, 24, 60), OutdoorAmbient = rgb(40, 20, 52), ColorShift_Top = rgb(255, 140, 240) },
		cc = { TintColor = rgb(255, 210, 255), Contrast = 0.22, Saturation = 0.35, Brightness = 0.03 },
		bloom = { Intensity = 0.95, Size = 30, Threshold = 0.95 },
	},
	gloom = {
		name = "幽影",
		lighting = { Brightness = 0.55, Ambient = rgb(32, 40, 44), OutdoorAmbient = rgb(28, 34, 38), ColorShift_Top = rgb(150, 176, 186) },
		cc = { TintColor = rgb(186, 205, 212), Contrast = 0.18, Saturation = -0.22, Brightness = -0.03 },
		dof = { FarIntensity = 0.1, FocusDistance = 26, InFocusRadius = 38, NearIntensity = 0.1 },
	},
}

local SHADE_ORDER = { "vanilla", "bsl", "complementary", "seus", "sildur", "kuda", "night", "cinema", "moon", "neon", "gloom" }

local SHADE_ALIAS = {
	bsl = "bsl", bslshader = "bsl", bslshaders = "bsl",
	complementary = "complementary", complementaryreimagined = "complementary", reimagined = "complementary", comp = "complementary",
	seus = "seus", seusptgi = "seus", ptgi = "seus",
	sildur = "sildur", sildurs = "sildur", vibrant = "sildur",
	kuda = "kuda", kudashader = "kuda",
	vanilla = "vanilla", default = "vanilla",
	night = "night", midnight = "night",
	cinema = "cinema", movie = "cinema", warm = "cinema",
	moon = "moon", cold = "moon", cool = "moon",
	neon = "neon", cyber = "neon",
	gloom = "gloom", dark = "gloom", horror = "gloom",
	["原版"] = "vanilla", ["冷月"] = "moon", ["霓虹"] = "neon", ["夜色"] = "night",
	["幽影"] = "gloom", ["电影"] = "cinema", ["暖调"] = "cinema", ["明亮"] = "kuda",
}

local LIGHT_KEYS = { "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom",
	"ExposureCompensation", "ClockTime", "FogEnd", "FogStart", "FogColor", "EnvironmentDiffuseScale", "EnvironmentSpecularScale" }

local function ensureEffect(class, name)
	local e = Lighting:FindFirstChild(name)
	if e then return e end
	local ok, made = pcall(function()
		local n = Instance.new(class)
		n.Name = name
		n.Parent = Lighting
		return n
	end)
	if ok and made then
		table.insert(Shade.effects, made)
		return made
	end
	return nil
end

local function saveLighting()
	if Shade.saved then return end
	Shade.saved = {}
	for _, k in ipairs(LIGHT_KEYS) do
		local ok, v = pcall(function() return Lighting[k] end)
		if ok then Shade.saved[k] = v end
	end
end

local function ensureFilterGui()
	if Shade.filterGui and Shade.filterGui.Parent then return Shade.filterGui end
	local gui = Instance.new("ScreenGui")
	gui.Name = "SG_Filter"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -9
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	attachGui(gui)
	Shade.filterGui = gui
	Shade.filter = make("ImageLabel", {
		Name = "Layer",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		Parent = gui,
	})
	return gui
end

function Shade.setFilter(url, alpha)
	ensureFilterGui()
	if not url or url == "" then
		Shade.filter.Image = ""
		Shade.filter.ImageTransparency = 1
		return true
	end
	local asset, err = resolveImage(url)
	if not asset or not asset.id then return false, err end
	Shade.filter.Image = asset.id
	Shade.filter.ImageTransparency = 1 - clamp(alpha or 0.22, 0, 0.85)
	return true
end

local function clearEffects()
	for _, e in ipairs(Shade.effects) do pcall(function() e.Enabled = false end) end
	for _, n in ipairs({ "SG_CC", "SG_Bloom", "SG_DOF", "SG_Sun" }) do
		local e = Lighting:FindFirstChild(n)
		if e then pcall(function() e.Enabled = false end) end
	end
end

function Shade.applyKey(key)
	local prof = SHADES[key]
	if not prof then return false end
	Shade.profileKey = key
	return Shade.applyProfile(prof, prof.name)
end

function Shade.applyProfile(prof, label)
	saveLighting()
	clearEffects()

	local k = clamp(T.shadePower, 0, 1.6)

	for key, v in pairs(prof.lighting or {}) do
		pcall(function() Lighting[key] = v end)
	end

	local cc = ensureEffect("ColorCorrectionEffect", "SG_CC")
	if cc then
		local p = prof.cc
		if p then
			cc.Enabled = true
			cc.TintColor = p.TintColor or Color3.new(1, 1, 1)
			cc.Contrast = clamp((p.Contrast or 0) * k, -1, 1)
			cc.Saturation = clamp((p.Saturation or 0) * k, -1, 1)
			cc.Brightness = clamp((p.Brightness or 0) * k, -1, 1)
		else
			cc.Enabled = false
		end
	end

	local bloom = ensureEffect("BloomEffect", "SG_Bloom")
	if bloom then
		local p = prof.bloom
		if p then
			bloom.Enabled = true
			bloom.Intensity = clamp((p.Intensity or 0) * k, 0, 5)
			bloom.Size = clamp(p.Size or 24, 0, 56)
			bloom.Threshold = clamp(p.Threshold or 1, 0, 5)
		else
			bloom.Enabled = false
		end
	end

	local dof = ensureEffect("DepthOfFieldEffect", "SG_DOF")
	if dof then
		local p = prof.dof
		if p then
			dof.Enabled = true
			dof.FarIntensity = clamp((p.FarIntensity or 0) * k, 0, 1)
			dof.NearIntensity = clamp((p.NearIntensity or 0) * k, 0, 1)
			dof.FocusDistance = clamp(p.FocusDistance or 20, 0, 200)
			dof.InFocusRadius = clamp(p.InFocusRadius or 40, 0, 400)
		else
			dof.Enabled = false
		end
	end

	local sun = ensureEffect("SunRaysEffect", "SG_Sun")
	if sun then
		local p = prof.sun
		if p then
			sun.Enabled = true
			sun.Intensity = clamp((p.Intensity or 0) * k, 0, 1)
			sun.Spread = clamp(p.Spread or 1, 0, 1)
		else
			sun.Enabled = false
		end
	end

	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		if not Shade.atmoSaved then
			Shade.atmoSaved = { Density = atmo.Density, Haze = atmo.Haze, Glare = atmo.Glare, Color = atmo.Color, Decay = atmo.Decay }
		end
		if prof.atmosphere then
			local p = prof.atmosphere
			pcall(function()
				atmo.Density = clamp((p.Density or 0.3) * k, 0, 1)
				atmo.Haze = clamp(p.Haze or 1, 0, 10)
				atmo.Glare = clamp((p.Glare or 0.1) * k, 0, 10)
				if p.Color then atmo.Color = p.Color end
				if p.Decay then atmo.Decay = p.Decay end
			end)
		elseif Shade.atmoSaved then
			pcall(function()
				atmo.Density = Shade.atmoSaved.Density
				atmo.Haze = Shade.atmoSaved.Haze
				atmo.Glare = Shade.atmoSaved.Glare
				atmo.Color = Shade.atmoSaved.Color
				atmo.Decay = Shade.atmoSaved.Decay
			end)
		end
	end

	if prof.filter and prof.filter.image then
		Shade.filterActive = true
		Shade.setFilter(prof.filter.image, (prof.filter.alpha or 0.22) * k)
	elseif not Shade.filterActive then
		Shade.setFilter(nil)
	end

	Shade.label = label or prof.name or "自定义"
	Shade.profile = prof
	Shade.entryNote = string.format("已应用：%s（强度 %.2f）", Shade.label, k)
	return true
end

function Shade.setPower(v)
	T.shadePower = clamp(v, 0, 1.6)
	if Shade.profile then
		Shade.applyProfile(Shade.profile, Shade.label)
	elseif SHADES[Shade.profileKey] then
		Shade.applyProfile(SHADES[Shade.profileKey], Shade.label)
	end
end

function Shade.reset()
	clearEffects()
	if Shade.saved then
		for k, v in pairs(Shade.saved) do pcall(function() Lighting[k] = v end) end
	end
	if Shade.atmoSaved then
		local a = Lighting:FindFirstChildOfClass("Atmosphere")
		if a then
			pcall(function()
				a.Density = Shade.atmoSaved.Density
				a.Haze = Shade.atmoSaved.Haze
				a.Glare = Shade.atmoSaved.Glare
				a.Color = Shade.atmoSaved.Color
				a.Decay = Shade.atmoSaved.Decay
			end)
		end
	end
	Shade.filterActive = false
	Shade.setFilter(nil)
	Shade.profile = nil
	Shade.label = "原版"
	Shade.profileKey = "vanilla"
	Shade.entryNote = "已还原为游戏原始光影"
	return true
end

local function toColor(v)
	if type(v) == "table" then
		return Color3.fromRGB(clamp(v[1] or 255, 0, 255), clamp(v[2] or 255, 0, 255), clamp(v[3] or 255, 0, 255))
	end
	if type(v) == "string" then
		local hex = v:gsub("#", "")
		if #hex == 6 then
			return Color3.fromRGB(tonumber(hex:sub(1, 2), 16) or 255, tonumber(hex:sub(3, 4), 16) or 255, tonumber(hex:sub(5, 6), 16) or 255)
		end
	end
	return nil
end

-- 兼容两种写法：扁平字段（Brightness=1.2）或分组字段（lighting={...}）
local function normalizePack(raw)
	if type(raw) ~= "table" then return nil end
	local prof = { name = tostring(raw.name or "自定义光影包") }
	local light = {}
	for _, k in ipairs(LIGHT_KEYS) do
		local v = raw[k]
		if v == nil and type(raw.lighting) == "table" then v = raw.lighting[k] end
		if v ~= nil then
			if k == "Ambient" or k == "OutdoorAmbient" or k == "ColorShift_Top" or k == "ColorShift_Bottom" or k == "FogColor" then
				local c = toColor(v)
				if c then light[k] = c end
			elseif type(v) == "number" then
				light[k] = v
			end
		end
	end
	if next(light) then prof.lighting = light end

	local function pick(t, names)
		if type(t) ~= "table" then return nil end
		local out = {}
		for i = 1, #names do
			local v = t[names[i]]
			if v ~= nil then out[names[i]] = v end
		end
		if next(out) then return out end
		return nil
	end

	local cc = pick(raw.cc or raw.colorcorrection, { "TintColor", "Contrast", "Saturation", "Brightness" })
	if cc then
		if cc.TintColor then cc.TintColor = toColor(cc.TintColor) end
		prof.cc = cc
	end
	prof.bloom = pick(raw.bloom, { "Intensity", "Size", "Threshold" })
	prof.dof = pick(raw.dof or raw.depthoffield, { "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity" })
	prof.sun = pick(raw.sun or raw.sunrays, { "Intensity", "Spread" })
	local atmo = pick(raw.atmosphere, { "Density", "Haze", "Glare", "Color", "Decay" })
	if atmo then
		if atmo.Color then atmo.Color = toColor(atmo.Color) end
		if atmo.Decay then atmo.Decay = toColor(atmo.Decay) end
		prof.atmosphere = atmo
	end
	local f = raw.filterImage or raw.filter
	if type(f) == "table" then
		prof.filter = { image = f.image or f.url, alpha = f.alpha or 0.22 }
	elseif type(f) == "string" then
		prof.filter = { image = f, alpha = 0.22 }
	end
	return prof
end

-- 识别：内置名 / JSON 包链接 / 图片滤色
function Shade.recognize(text)
	text = trim(text)
	if text == "" then return false, "先输入风格名或链接" end

	local low = text:lower()
	local plain = low:gsub("[^%a%d]", "")
	local key = SHADE_ALIAS[plain]
	if not key then key = SHADE_ALIAS[low] end
	if not key then key = SHADE_ALIAS[text] end
	if key and SHADES[key] then
		Shade.applyKey(key)
		Shade.entryNote = "已识别：内置风格 · " .. SHADES[key].name
		return true, Shade.entryNote
	end

	if low:match("^https?://") then
		local ext = extOf(low)
		if ext == "json" or ext == "txt" or ext == "lua" then
			local ok, body = pcall(function() return game:HttpGet(text, true) end)
			if ok and type(body) == "string" and #body > 8 then
				local ok2, raw = pcall(function() return game:GetService("HttpService"):JSONDecode(body) end)
				if ok2 then
					local prof = normalizePack(raw)
					if prof then
						Shade.applyProfile(prof, prof.name)
						Shade.entryNote = "已识别：光影包 " .. prof.name
						return true, Shade.entryNote
					end
				end
			end
			return false, "这个 JSON 里没有可用的光影字段"
		end
		Shade.filterActive = true
		local ok, err = Shade.setFilter(text, 0.22 * clamp(T.shadePower, 0.1, 1.6))
		if ok then
			Shade.label = "图片滤色"
			Shade.entryNote = "已识别：图片滤色片（叠在画面上做色调）"
			return true, Shade.entryNote
		end
		Shade.filterActive = false
		return false, err or "图片读取失败"
	end

	return false, "没认出这个风格：试试 bsl / complementary / seus / sildur / kuda，或贴 .json 光影包链接"
end

--=====================================================================
--  7 · 中文翻译（正常语序）
--=====================================================================
local TRANSLATE = {
	["enable"] = "启用", ["enabled"] = "已启用", ["disable"] = "禁用", ["disabled"] = "已禁用",
	["on"] = "开", ["off"] = "关", ["toggle"] = "开关", ["toggles"] = "开关",
	["settings"] = "设置", ["setting"] = "设置", ["config"] = "配置", ["configs"] = "配置",
	["theme"] = "主题", ["close"] = "关闭", ["exit"] = "退出", ["back"] = "返回",
	["search"] = "搜索", ["keybind"] = "快捷键", ["keybinds"] = "快捷键", ["key"] = "按键",
	["apply"] = "应用", ["save"] = "保存", ["load"] = "加载", ["reset"] = "重置",
	["speed"] = "速度", ["jump"] = "跳跃", ["walk"] = "行走", ["run"] = "奔跑", ["sprint"] = "冲刺",
	["player"] = "玩家", ["players"] = "玩家", ["target"] = "目标", ["item"] = "物品", ["items"] = "物品",
	["give"] = "给予", ["spawn"] = "生成", ["music"] = "音乐", ["sound"] = "音效",
	["volume"] = "音量", ["light"] = "灯光", ["lights"] = "灯光", ["time"] = "时间",
	["god"] = "无敌", ["godmode"] = "无敌模式", ["fly"] = "飞行", ["noclip"] = "穿墙",
	["esp"] = "透视", ["aimbot"] = "自瞄", ["teleport"] = "传送", ["tp"] = "传送",
	["auto"] = "自动", ["farm"] = "刷取", ["door"] = "门", ["doors"] = "门",
	["mode"] = "模式", ["modes"] = "模式", ["entity"] = "实体", ["entities"] = "实体",
	["admin"] = "管理员", ["hub"] = "中心", ["script"] = "脚本", ["scripts"] = "脚本",
	["notify"] = "通知", ["notification"] = "通知", ["copy"] = "复制", ["paste"] = "粘贴",
	["language"] = "语言", ["font"] = "字体", ["size"] = "大小", ["color"] = "颜色",
	["hide"] = "隐藏", ["show"] = "显示", ["opacity"] = "不透明度", ["transparency"] = "透明度",
	["loading"] = "加载中", ["success"] = "成功", ["failed"] = "失败", ["error"] = "错误",
	["weapon"] = "武器", ["weapons"] = "武器", ["shop"] = "商店", ["coin"] = "金币", ["coins"] = "金币",
	["money"] = "金币", ["health"] = "生命", ["revive"] = "复活", ["kill"] = "击杀", ["heal"] = "治疗",
	["welcome"] = "欢迎", ["thanks"] = "感谢", ["confirm"] = "确认", ["cancel"] = "取消",
	["yes"] = "是", ["no"] = "否", ["min"] = "最小", ["max"] = "最大", ["value"] = "数值",
	["description"] = "说明", ["private"] = "私人", ["spawner"] = "生成器", ["hardcore"] = "硬核",
	["main"] = "主页", ["general"] = "通用", ["visuals"] = "视觉", ["misc"] = "杂项",
	["credits"] = "制作名单", ["version"] = "版本", ["update"] = "更新", ["refresh"] = "刷新",
	["mode center"] = "模式中心", ["modes center"] = "模式中心",
	["entity spawner"] = "实体生成器", ["private modes"] = "私人模式",
}

local CUSTOM_TRANSLATE = {}

local function escapePattern(s)
	return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

local function translate(s)
	if type(s) ~= "string" then return s end
	if not T.translate then return s end
	if s == "" or #s > 40 or s:find("\n") then return s end
	local t = trim(s)
	if t == "" then return s end
	local low = t:lower()

	if CUSTOM_TRANSLATE[low] then
		return (s:gsub(escapePattern(t), CUSTOM_TRANSLATE[low]))
	end
	if TRANSLATE[low] then
		return (s:gsub(escapePattern(t), TRANSLATE[low]))
	end

	local out = s
	for key, val in pairs(CUSTOM_TRANSLATE) do
		if #key >= 4 and key:match("^[%a ]+$") then
			out = out:gsub("%f[%a]" .. key .. "%f[%A]", val)
		end
	end
	return out
end

local function parseTranslate(str)
	CUSTOM_TRANSLATE = {}
	for chunk in tostring(str or ""):gmatch("[^,;\n，；]+") do
		local k, v = chunk:match("^%s*(.-)%s*=%s*(.-)%s*$")
		if k and v and k ~= "" and v ~= "" then
			CUSTOM_TRANSLATE[k:lower()] = v
		end
	end
	return CUSTOM_TRANSLATE
end

--=====================================================================
--  8 · 换肤引擎
--=====================================================================
local function harmonize(c)
	if sat(c) < 0.14 then return c end
	local h = hueOf(T.accent)
	local _, s, v = c:ToHSV()
	return Color3.fromHSV(h, math.min(1, s * 0.95 + 0.05), math.max(v, 0.42))
end

local function readable(c)
	local l = lum(c)
	if sat(c) > 0.2 then return harmonize(c) end
	if l < 0.5 then return T.text end
	if l < 0.8 then return T.dimc end
	return T.text
end

local function ensureCorner(o)
	local c = Reg.corner[o]
	if c and c.Parent then return c end
	c = o:FindFirstChildOfClass("UICorner")
	if not c then
		c = Instance.new("UICorner")
		c.Parent = o
	end
	Reg.corner[o] = c
	return c
end

local function ensureStroke(o)
	local s = Reg.stroke[o]
	if s and s.Parent then return s end
	s = o:FindFirstChildOfClass("UIStroke")
	if not s then
		s = Instance.new("UIStroke")
		s.Parent = o
	end
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Thickness = 1
	s.Color = Color3.new(1, 1, 1)
	local g = s:FindFirstChildOfClass("UIGradient")
	if not g then
		g = Instance.new("UIGradient")
		g.Parent = s
	end
	g.Rotation = 55
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.66, 0.74, 0.70))
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.20),
		NumberSequenceKeypoint.new(0.45, 0.72),
		NumberSequenceKeypoint.new(1, 0.42),
	})
	Reg.stroke[o] = s
	return s
end

local function ensureScale(o)
	local s = Reg.scales[o]
	if s and s.Parent then return s end
	s = o:FindFirstChild("SG_Scale")
	if not s then
		s = Instance.new("UIScale")
		s.Name = "SG_Scale"
		s.Parent = o
	end
	Reg.scales[o] = s
	return s
end

local function styleFor(kind)
	if kind == "window" then
		return T.tint, clamp(T.glass, 0.2, 0.97), T.corner, 1 - 0.5 * T.border
	elseif kind == "panel" then
		return Color3.new(1, 1, 1), 0.045, math.max(8, T.corner * 0.78), 1 - 0.30 * T.border
	elseif kind == "control" then
		return Color3.new(1, 1, 1), 0.075, math.max(6, math.min(12, T.corner * 0.66)), 1 - 0.26 * T.border
	elseif kind == "line" then
		if T.seamless then return Color3.new(1, 1, 1), 0, 0, 1 end
		return Color3.new(1, 1, 1), 0.10, 0, 1
	end
	return nil, 1, 0, 1
end

local function applyStyle(o, kind)
	if kind == "flat" then return end
	if kind == "chip" then
		o.BackgroundColor3 = harmonize(Reg.origBG[o] or o.BackgroundColor3)
		if o:IsA("GuiButton") then
			o.BackgroundTransparency = math.min(0.85, 0.48 + (Reg.origBT[o] or 0) * 0.4)
		else
			o.BackgroundTransparency = math.min(0.85, (Reg.origBT[o] or 0) * 0.5)
		end
		o.BorderSizePixel = 0
		ensureCorner(o).CornerRadius = UDim.new(0, math.max(6, math.floor(T.corner * 0.5)))
		ensureStroke(o).Transparency = clamp(1 - 0.35 * T.border, 0, 1)
		return
	end
	if kind == "raw" then
		local s = o.AbsoluteSize
		local r = math.floor(math.min(s.X, s.Y) * 0.5)
		if r > 0 then ensureCorner(o).CornerRadius = UDim.new(0, math.min(8, r)) end
		return
	end
	local color, alpha, radius, strokeT = styleFor(kind)
	if color then
		o.BackgroundColor3 = color
		o.BackgroundTransparency = 1 - alpha
		o.BorderSizePixel = 0
	end
	if radius and radius > 0 then
		ensureCorner(o).CornerRadius = UDim.new(0, math.max(0, math.floor(radius)))
	end
	if strokeT then
		local st = ensureStroke(o)
		st.Transparency = clamp(strokeT, 0, 1)
		st.Enabled = strokeT < 0.999
	end
end

local function applyText(o)
	local base = Reg.origTx[o] or T.text
	o.TextColor3 = readable(base)
	o.TextStrokeTransparency = 1
	o.Font = ((o.TextSize or 14) >= 18) and FONT_BOLD or FONT_BODY
end

local function applyString(o)
	local base = Reg.origSt[o]
	if base == nil then
		base = o.Text
		Reg.origSt[o] = base
		Reg.mapOut[o] = base
		return
	end
	local cur = o.Text
	local last = Reg.mapOut[o]
	-- 原脚本改过这处文字（计数/键位/状态）就当成新原文，不覆盖回去
	if last ~= nil and cur ~= last and cur ~= base then
		Reg.origSt[o] = cur
		base = cur
	end
	local mapped = translate(base)
	if o.Text ~= mapped then o.Text = mapped end
	Reg.mapOut[o] = mapped
end

local function isTopWindow(g)
	local p = g.Parent
	if not p then return false end
	local vp = viewport()
	local s = g.AbsoluteSize
	if not (s.X >= math.max(280, vp.X * 0.16) and s.Y >= math.max(150, vp.Y * 0.13)) then return false end
	if p:IsA("ScreenGui") or p:IsA("Folder") or p:IsA("PlayerGui") or p:IsA("CoreGui") then return true end
	if p:IsA("GuiObject") then
		local ps = p.AbsoluteSize
		if ps.X >= vp.X * 0.5 and ps.Y >= vp.Y * 0.5 then return true end
		if s.X >= vp.X * 0.22 and s.Y >= vp.Y * 0.22
			and #g:GetChildren() >= 3
			and g:FindFirstChildOfClass("TextLabel") ~= nil then
			return true
		end
	end
	return false
end

local function addShadow(win)
	if Reg.shadow[win] then return end
	local parent = win.Parent
	if not parent then return end
	if parent:IsA("GuiObject") and parent.ClipsDescendants then return end
	local layers = {}
	for _, sp in ipairs({ { 10, 0.62, 26 }, { 20, 0.78, 34 }, { 34, 0.86, 44 } }) do
		local s = Instance.new("Frame")
		s.Name = "SG_Shadow"
		s.BackgroundColor3 = Color3.new(0, 0, 0)
		s.BackgroundTransparency = sp[2]
		s.BorderSizePixel = 0
		s.AnchorPoint = win.AnchorPoint
		s.Size = win.Size
		s.Position = win.Position + UDim2.new(0, 0, 0, sp[1])
		s.ZIndex = win.ZIndex - 1
		make("UICorner", { CornerRadius = UDim.new(0, sp[3]), Parent = s })
		s.Parent = parent
		table.insert(layers, { f = s, off = sp[1] })
	end
	Reg.shadow[win] = layers
end

local function addChrome(win)
	if win:FindFirstChild("SG_Highlight") then return end
	local hl = Instance.new("Frame")
	hl.Name = "SG_Highlight"
	hl.Size = UDim2.new(1, -32, 0, 1)
	hl.Position = UDim2.new(0, 16, 0, 1)
	hl.BackgroundColor3 = Color3.new(1, 1, 1)
	hl.BackgroundTransparency = 0.70
	hl.BorderSizePixel = 0
	hl.ZIndex = win.ZIndex + 3
	hl.Visible = T.chrome
	hl.Parent = win
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.05),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = hl,
	})

	local sheen = Instance.new("Frame")
	sheen.Name = "SG_Sheen"
	sheen.Size = UDim2.new(1, 0, 1, 0)
	sheen.BackgroundColor3 = Color3.new(1, 1, 1)
	sheen.BorderSizePixel = 0
	sheen.ZIndex = 0
	sheen.Visible = T.chrome
	sheen.Parent = win
	make("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.90),
			NumberSequenceKeypoint.new(0.35, 0.98),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = sheen,
	})

	addShadow(win)
	table.insert(P.hooks, function()
		if hl.Parent then hl.Visible = T.chrome end
		if sheen.Parent then sheen.Visible = T.chrome end
	end)
end

-- 给被换肤的窗口挂拖动把手（原库不支持拖动时也能挪）
local function attachGrip(win)
	local grip = Reg.grips[win]
	if grip and grip.Parent then
		grip.Visible = T.grip
		return grip
	end
	grip = Instance.new("TextButton")
	grip.Name = "SG_Grip"
	grip.Text = "⋮⋮"
	grip.Font = FONT_BODY
	grip.TextSize = 10
	grip.TextColor3 = Color3.new(1, 1, 1)
	grip.TextTransparency = 0.35
	grip.BackgroundColor3 = Color3.new(0, 0, 0)
	grip.BackgroundTransparency = 0.78
	grip.BorderSizePixel = 0
	grip.AutoButtonColor = false
	grip.Size = UDim2.new(0, 26, 0, 20)
	grip.Position = UDim2.new(0, 8, 0, 8)
	grip.ZIndex = 60
	grip.Visible = T.grip
	grip.Parent = win
	make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = grip })

	local dragging, startPos, startMouse = false, nil, nil
	grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = win.Position
			startMouse = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - startMouse
			win.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	Reg.grips[win] = grip
	return grip
end

local function classify(g)
	local abs = g.AbsoluteSize
	if abs.Y <= 2 and abs.X > 24 then return "line" end
	if isTopWindow(g) then return "window" end
	if abs.X <= 28 or abs.Y <= 28 then return "raw" end
	if sat(g.BackgroundColor3) > 0.22 then return "chip" end
	if abs.X >= 140 and abs.Y >= 60 then return "panel" end
	if #g:GetChildren() > 0 and abs.X >= 80 then return "panel" end
	return "control"
end

local function dress(g)
	if not g then return end
	local nm = tostring(g.Name or "")
	if nm:sub(1, 3) == "SG_" or nm:sub(1, 3) == "LG_" then return end

	if not Reg.done[g] then
		Reg.done[g] = true
		local cls = g.ClassName
		if g:IsA("GuiObject") then
			Reg.origBG[g] = g.BackgroundColor3
			Reg.origBT[g] = g.BackgroundTransparency
			g.BorderSizePixel = 0
		end
		if g:IsA("TextLabel") or g:IsA("TextButton") or g:IsA("TextBox") then
			Reg.origTx[g] = g.TextColor3
			Reg.origSt[g] = g.Text
			Reg.text[g] = true
			applyText(g)
			applyString(g)
		end

		if cls == "ScrollingFrame" then
			g.BackgroundTransparency = 1
			g.BorderSizePixel = 0
			g.ScrollBarThickness = math.max(2, math.floor((g.ScrollBarThickness or 12) * 0.35))
			g.ScrollBarImageColor3 = Color3.new(1, 1, 1)
			g.ScrollBarImageTransparency = 0.55
		elseif cls == "TextButton" or cls == "ImageButton" then
			local kind = (sat(Reg.origBG[g] or Color3.new(0, 0, 0)) > 0.22) and "chip" or "control"
			Reg.style[g] = kind
			applyStyle(g, kind)
		elseif cls == "TextBox" then
			Reg.style[g] = "control"
			applyStyle(g, "control")
		elseif cls == "Frame" then
			if g.BackgroundTransparency >= 0.96 then
				Reg.style[g] = "flat"
			else
				local kind = classify(g)
				Reg.style[g] = kind
				applyStyle(g, kind)
				if kind == "window" then
					Reg.windows[g] = true
					addChrome(g)
					ensureScale(g).Scale = T.scale
					attachGrip(g)
				end
			end
		elseif cls == "ImageLabel" then
			if g.BackgroundTransparency < 0.96 then
				g.BackgroundColor3 = harmonize(g.BackgroundColor3)
				g.BackgroundTransparency = math.max(g.BackgroundTransparency, 0.60)
			end
		end
	end

	for _, ch in ipairs(g:GetChildren()) do dress(ch) end
end

local function dressTree(root)
	if not root or not root.Parent then return end
	local ok, err = pcall(dress, root)
	if not ok then warn("[SG] 跳过节点: " .. tostring(err)) end
end

local function resetDone(root)
	Reg.done[root] = nil
	local ok, list = pcall(function() return root:GetDescendants() end)
	if ok and list then
		for _, d in ipairs(list) do Reg.done[d] = nil end
	end
end

local function refreshNow()
	for o, kind in pairs(Reg.style) do
		if o.Parent then
			local ok = pcall(applyStyle, o, kind)
			if not ok then Reg.style[o] = nil end
		end
	end
	for o in pairs(Reg.text) do
		if o.Parent then
			pcall(applyText, o)
			pcall(applyString, o)
		end
	end
	for o, us in pairs(Reg.scales) do
		if o.Parent and us.Parent then us.Scale = T.scale end
	end
	for _, grip in pairs(Reg.grips) do
		if grip.Parent then grip.Visible = T.grip end
	end
	if Wall.scrim then Wall.scrim.BackgroundTransparency = 1 - clamp(T.dim, 0, 0.95) end
	local blur = Lighting:FindFirstChild("SG_SceneBlur")
	if blur then blur.Size = T.blur end
	applyLook()
	for _, fn in ipairs(P.hooks) do pcall(fn) end
	for _, fn in ipairs(P.renders) do pcall(fn) end
end

local refreshQueued = false
local function refresh()
	if refreshQueued then return end
	refreshQueued = true
	schedule(function()
		pause(0.03)
		refreshQueued = false
		local ok, err = pcall(refreshNow)
		if not ok then warn("[SG] 刷新失败: " .. tostring(err)) end
	end)
end

local function ensureBlur()
	local b = Lighting:FindFirstChild("SG_SceneBlur")
	if b then return b end
	local ok, made = pcall(function()
		local n = Instance.new("BlurEffect")
		n.Name = "SG_SceneBlur"
		n.Size = T.blur
		n.Enabled = false
		n.Parent = Lighting
		return n
	end)
	if ok then return made end
	return nil
end

--=====================================================================
--  9 · 控制面板（分页 + 整块可拖动 + 瘦身）
--=====================================================================
local TAB_LIST = {
	{ key = "look", name = "外观" },
	{ key = "wall", name = "壁纸" },
	{ key = "shade", name = "光影" },
	{ key = "text", name = "翻译" },
}

local function newBuilder(scroll)
	local b = { y = 0, scroll = scroll }

	function b.row(h)
		local r = make("Frame", {
			Size = UDim2.new(1, 0, 0, h),
			Position = UDim2.new(0, 0, 0, b.y),
			BackgroundTransparency = 1,
			Parent = scroll,
		})
		b.y = b.y + h
		return r
	end

	function b.slider(label, minV, maxV, step, get, set)
		local row = b.row(31)
		local cap = make("TextLabel", {
			Text = label,
			Size = UDim2.new(1, -58, 0, 12),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local val = make("TextLabel", {
			Text = "",
			Size = UDim2.new(0, 58, 0, 12),
			Position = UDim2.new(1, -58, 0, 0),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
		local track = make("Frame", {
			Name = "SG_Track",
			Size = UDim2.new(1, 0, 0, 4),
			Position = UDim2.new(0, 0, 0, 20),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
			Parent = row,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
		local fill = make("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = T.accent,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			Parent = track,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
		local knob = make("Frame", {
			Size = UDim2.new(0, 9, 0, 9),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = T.text,
			BorderSizePixel = 0,
			Parent = track,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

		local function render()
			local v = get()
			local a = clamp((v - minV) / math.max(0.0001, maxV - minV), 0, 1)
			fill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, 0, 0.5, 0)
			val.Text = (step >= 1) and tostring(math.floor(v + 0.5)) or string.format("%.2f", v)
			fill.BackgroundColor3 = T.accent
			knob.BackgroundColor3 = T.text
			cap.TextColor3 = T.dimc
			val.TextColor3 = T.text
		end

		local function commit(input)
			local ap, asz = track.AbsolutePosition, track.AbsoluteSize
			local a = clamp((input.Position.X - ap.X) / math.max(asz.X, 1), 0, 1)
			local v = minV + (maxV - minV) * a
			if step >= 1 then v = math.floor(v / step + 0.5) * step end
			set(clamp(v, minV, maxV))
			render()
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				P.sliderBusy = true
				commit(input)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not P.sliderBusy then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				commit(input)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				P.sliderBusy = false
			end
		end)

		table.insert(P.renders, render)
		render()
		return row
	end

	function b.switch(label, get, set)
		local row = b.row(26)
		make("TextLabel", {
			Text = label,
			Size = UDim2.new(1, -46, 1, 0),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local pill = make("Frame", {
			Size = UDim2.new(0, 32, 0, 17),
			Position = UDim2.new(1, -32, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = T.tint2,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Parent = row,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })
		local dot = make("Frame", {
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.new(0, 3, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = T.dimc,
			BorderSizePixel = 0,
			Parent = pill,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

		local function render()
			local on = get()
			TweenService:Create(dot, TweenInfo.new(0.16), {
				Position = UDim2.new(0, on and 17 or 3, 0.5, 0),
				BackgroundColor3 = on and T.accent or T.dimc,
			}):Play()
			TweenService:Create(pill, TweenInfo.new(0.16), {
				BackgroundColor3 = on and T.accent or T.tint2,
				BackgroundTransparency = on and 0.72 or 0.15,
			}):Play()
		end

		make("TextButton", {
			Text = "",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Parent = row,
		}).MouseButton1Click:Connect(function()
			set(not get())
			render()
		end)

		table.insert(P.renders, render)
		render()
		return row
	end

	function b.cycler(label, getText, onNext)
		local row = b.row(28)
		make("TextLabel", {
			Text = label,
			Size = UDim2.new(1, -120, 1, 0),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local btn = make("TextButton", {
			Text = "",
			Size = UDim2.new(0, 112, 0, 22),
			Position = UDim2.new(1, -112, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = T.tint2,
			BackgroundTransparency = 0.45,
			AutoButtonColor = false,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.text,
			Parent = row,
		})
		make("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
		local function render()
			btn.Text = getText()
			btn.TextColor3 = T.text
			btn.BackgroundColor3 = T.tint2
		end
		btn.MouseButton1Click:Connect(function()
			onNext()
			render()
		end)
		table.insert(P.renders, render)
		render()
		return row
	end

	function b.buttons(specs)
		local row = b.row(30)
		local n = #specs
		for i, sp in ipairs(specs) do
			local btn = make("TextButton", {
				Text = sp.text,
				Size = UDim2.new(1 / n, -((n - 1) * 6) / n, 0, 24),
				Position = UDim2.new((i - 1) / n, (i - 1) * 6, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = sp.accent and T.accent or T.tint2,
				BackgroundTransparency = sp.accent and 0.55 or 0.35,
				AutoButtonColor = false,
				Font = FONT_BODY,
				TextSize = 10,
				TextColor3 = T.text,
				Parent = row,
			})
			make("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
			btn.MouseButton1Click:Connect(sp.cb)
			table.insert(P.hooks, function()
				btn.TextColor3 = T.text
				btn.BackgroundColor3 = sp.accent and T.accent or T.tint2
			end)
		end
		return row
	end

	function b.input(placeholder, buttonText, onApply)
		local row = b.row(30)
		local box = make("TextBox", {
			Text = "",
			PlaceholderText = placeholder,
			Size = UDim2.new(1, -58, 0, 24),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = T.tint2,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.text,
			PlaceholderColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = row,
		})
		make("UICorner", { CornerRadius = UDim.new(0, 7), Parent = box })
		make("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 5), Parent = box })
		box.Focused:Connect(function() P.sliderBusy = true end)
		box.FocusLost:Connect(function() P.sliderBusy = false end)
		local btn = make("TextButton", {
			Text = buttonText,
			Size = UDim2.new(0, 52, 0, 24),
			Position = UDim2.new(1, -52, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = T.accent,
			BackgroundTransparency = 0.6,
			AutoButtonColor = false,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.text,
			Parent = row,
		})
		make("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
		btn.MouseButton1Click:Connect(function() onApply(box) end)
		table.insert(P.hooks, function()
			box.TextColor3 = T.text
			box.BackgroundColor3 = T.tint2
			btn.TextColor3 = T.text
			btn.BackgroundColor3 = T.accent
		end)
		return row, box
	end

	function b.note(text, height)
		local row = b.row(height or 16)
		local label = make("TextLabel", {
			Text = text,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 9,
			TextColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			Parent = row,
		})
		table.insert(P.hooks, function() label.TextColor3 = T.dimc end)
		return row, label
	end

	function b.finish()
		scroll.CanvasSize = UDim2.new(0, 0, 0, b.y + 6)
	end

	return b
end

local function buildPanel()
	if P.gui and P.gui.Parent then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "SG_Panel"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	attachGui(gui)
	P.gui = gui

	local card = make("Frame", {
		Name = "SG_Card",
		Size = UDim2.new(0, 300, 0, 424),
		Position = UDim2.new(1, -18, 1, -18),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = T.tint,
		BackgroundTransparency = 1 - clamp(T.glass, 0.3, 0.95),
		BorderSizePixel = 0,
		Parent = gui,
	})
	P.card = card
	make("UICorner", { CornerRadius = UDim.new(0, T.corner), Parent = card })
	local cardStroke = make("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Transparency = 1 - 0.5 * T.border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = card,
	})

	local header = make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Parent = card,
	})
	local dot = make("Frame", {
		Size = UDim2.new(0, 6, 0, 6),
		Position = UDim2.new(0, 14, 0, 17),
		BackgroundColor3 = T.accent,
		BorderSizePixel = 0,
		Parent = header,
	})
	make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
	make("TextLabel", {
		Text = "无痕 · 外观",
		Size = UDim2.new(1, -110, 0, 14),
		Position = UDim2.new(0, 26, 0, 12),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = T.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	local hint = make("TextLabel", {
		Text = "按住面板任意处可拖动 · F2 隐藏",
		Size = UDim2.new(1, -110, 0, 10),
		Position = UDim2.new(0, 26, 0, 25),
		BackgroundTransparency = 1,
		Font = FONT_BODY,
		TextSize = 8,
		TextColor3 = T.dimc,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local collapse = make("TextButton", {
		Text = "–",
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.new(1, -52, 0, 8),
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.55,
		AutoButtonColor = false,
		Font = FONT_BODY,
		TextSize = 12,
		TextColor3 = T.text,
		Parent = header,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = collapse })

	local closeBtn = make("TextButton", {
		Text = "×",
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.new(1, -26, 0, 8),
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.55,
		AutoButtonColor = false,
		Font = FONT_BODY,
		TextSize = 12,
		TextColor3 = T.text,
		Parent = header,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = closeBtn })

	local tabsRow = make("Frame", {
		Name = "Tabs",
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.new(0, 10, 0, 38),
		BackgroundTransparency = 1,
		Parent = card,
	})
	P.tabsRow = tabsRow

	local content = make("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -20, 1, -70),
		Position = UDim2.new(0, 10, 0, 66),
		BackgroundTransparency = 1,
		Parent = card,
	})
	P.content = content

	local function pageScroll(key)
		local frame = make("Frame", {
			Name = "Page_" .. key,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = content,
		})
		local scroll = make("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = T.accent,
			ScrollBarImageTransparency = 0.5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = frame,
		})
		P.pages[key] = frame
		return scroll
	end

	local function selectTab(key)
		T.tab = key
		for k, p in pairs(P.pages) do p.Visible = (k == key) end
		for k, btn in pairs(P.tabButtons) do
			local on = (k == key)
			btn.BackgroundColor3 = on and T.accent or T.tint2
			btn.BackgroundTransparency = on and 0.55 or 0.45
			btn.TextColor3 = on and T.text or T.dimc
		end
	end

	for i, tab in ipairs(TAB_LIST) do
		local btn = make("TextButton", {
			Text = tab.name,
			Size = UDim2.new(1 / #TAB_LIST, -4, 1, 0),
			Position = UDim2.new((i - 1) / #TAB_LIST, (i - 1) * 5, 0, 0),
			BackgroundColor3 = T.tint2,
			BackgroundTransparency = 0.45,
			AutoButtonColor = false,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.text,
			Parent = tabsRow,
		})
		make("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
		btn.MouseButton1Click:Connect(function() selectTab(tab.key) end)
		P.tabButtons[tab.key] = btn
	end

	--──────── 外观 ────────
	local bl = newBuilder(pageScroll("look"))
	bl.slider("模糊", 0, 24, 1, function() return T.blur end, function(v)
		T.blur = v
		local b = ensureBlur()
		if b then b.Size = v end
	end)
	bl.slider("压暗", 0, 0.7, 0.01, function() return T.dim end, function(v)
		T.dim = v
		applyLook()
	end)
	bl.slider("玻璃", 0.2, 0.95, 0.01, function() return T.glass end, function(v)
		T.glass = v
		refresh()
	end)
	bl.slider("描边（0 = 完全无缝）", 0, 1, 0.01, function() return T.border end, function(v)
		T.border = v
		refresh()
	end)
	bl.slider("圆角", 0, 28, 1, function() return T.corner end, function(v)
		T.corner = v
		refresh()
	end)
	bl.slider("缩放", 0.6, 1.6, 0.01, function() return T.scale end, function(v)
		T.scale = v
		refresh()
	end)
	bl.switch("无缝边框", function() return T.seamless end, function(v)
		T.seamless = v
		refresh()
	end)
	bl.switch("顶部高光", function() return T.chrome end, function(v)
		T.chrome = v
		refresh()
	end)
	bl.switch("窗口拖动把手", function() return T.grip end, function(v)
		T.grip = v
		refresh()
	end)

	local swRow = bl.row(30)
	local palette = {
		Color3.fromRGB(0, 200, 0), Color3.fromRGB(10, 132, 255), Color3.fromRGB(191, 90, 242),
		Color3.fromRGB(255, 159, 10), Color3.fromRGB(255, 69, 58), Color3.fromRGB(235, 245, 240),
	}
	for i, c in ipairs(palette) do
		local sw = make("TextButton", {
			Text = "",
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, (i - 1) * 26, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = c,
			AutoButtonColor = false,
			Parent = swRow,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sw })
		sw.MouseButton1Click:Connect(function()
			T.accent = c
			refresh()
		end)
	end
	bl.slider("色调", 0, 1, 0.01, function() return hueOf(T.accent) end, function(v)
		local _, s, val = T.accent:ToHSV()
		T.accent = Color3.fromHSV(v, math.max(0.25, s), math.max(0.55, val))
		refresh()
	end)
	bl.finish()

	--──────── 壁纸 ────────
	local bw = newBuilder(pageScroll("wall"))
	local _, noteLabel = bw.note("还没有壁纸", 24)
	bw.input("图片 / 视频 / 序列帧长图 链接", "添加", function(box)
		local ok, msg = Wall.add(box.Text)
		noteLabel.Text = ok and msg or ("识别失败：" .. tostring(msg))
		toast(noteLabel.Text)
		if ok then
			box.Text = ""
			if P.save then pcall(P.save) end
		end
	end)

	local list = make("ScrollingFrame", {
		Name = "SG_WallList",
		Size = UDim2.new(1, 0, 0, 64),
		Position = UDim2.new(0, 0, 0, bw.y),
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = T.accent,
		ScrollBarImageTransparency = 0.55,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = bw.scroll,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = list })
	bw.y = bw.y + 68

	local BADGE = { image = "图", strip = "帧", video = "视" }

	local function rebuildList()
		for _, ch in ipairs(list:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		list.CanvasSize = UDim2.new(0, 0, 0, math.max(#Wall.items * 18, 16))
		if #Wall.items == 0 then
			make("TextLabel", {
				Text = "空 —— 贴个链接加上来",
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Font = FONT_BODY,
				TextSize = 9,
				TextColor3 = T.dimc,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = list,
			})
			return
		end
		for i, it in ipairs(Wall.items) do
			local row = make("Frame", {
				Size = UDim2.new(1, 0, 0, 17),
				Position = UDim2.new(0, 0, 0, (i - 1) * 18),
				BackgroundTransparency = 1,
				Parent = list,
			})
			make("TextLabel", {
				Text = BADGE[it.kind] or "图",
				Size = UDim2.new(0, 14, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT_BOLD,
				TextSize = 9,
				TextColor3 = T.accent,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			make("TextLabel", {
				Text = tostring(i) .. " · " .. tostring(it.url or "?"):sub(1, 38),
				Size = UDim2.new(1, -32, 1, 0),
				Position = UDim2.new(0, 15, 0, 0),
				BackgroundTransparency = 1,
				Font = FONT_BODY,
				TextSize = 9,
				TextColor3 = T.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})
			local del = make("TextButton", {
				Text = "×",
				Size = UDim2.new(0, 14, 0, 14),
				Position = UDim2.new(1, -16, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = T.tint2,
				BackgroundTransparency = 0.4,
				AutoButtonColor = false,
				Font = FONT_BODY,
				TextSize = 10,
				TextColor3 = T.text,
				Parent = row,
			})
			make("UICorner", { CornerRadius = UDim.new(0, 5), Parent = del })
			del.MouseButton1Click:Connect(function()
				Wall.remove(i)
				if P.save then pcall(P.save) end
			end)
		end
	end
	P.rebuildList = rebuildList

	local MODES = { "auto", "still", "pan", "cross", "strip", "video", "aurora" }
	local MODE_NAME = {
		auto = "自动识别", still = "静帧", pan = "缓慢放大", cross = "多图轮播",
		strip = "序列帧", video = "视频循环", aurora = "纯极光",
	}
	bw.cycler("播放方式", function() return MODE_NAME[T.mode] or T.mode end, function()
		local idx = 1
		for i, v in ipairs(MODES) do if v == T.mode then idx = i break end end
		T.mode = MODES[idx % #MODES + 1]
		Wall.play()
	end)
	bw.slider("停留", 3, 30, 1, function() return T.hold end, function(v) T.hold = v end)
	bw.slider("速度", 0.2, 3, 0.01, function() return T.speed end, function(v) T.speed = v end)
	bw.slider("壁纸浓度", 0.2, 1, 0.01, function() return T.wallAlpha end, function(v)
		T.wallAlpha = v
		applyLook()
	end)
	bw.switch("极光层", function() return T.aurora end, function(v)
		T.aurora = v
		applyLook()
	end)
	bw.switch("光尘", function() return T.dust end, function(v)
		T.dust = v
		applyLook()
	end)
	bw.switch("仅菜单显示时出现", function() return T.followWindow end, function(v) T.followWindow = v end)
	bw.buttons({
		{ text = "重新播放", cb = function() Wall.play() end },
		{ text = "清空", cb = function()
			Wall.clear()
			noteLabel.Text = "还没有壁纸"
			if P.save then pcall(P.save) end
		end },
	})
	bw.finish()

	--──────── 光影 ────────
	local bs = newBuilder(pageScroll("shade"))
	local _, sNote = bs.note("识别结果：未应用", 24)
	bs.input("风格名（bsl / seus…）或 .json 链接", "识别", function(box)
		local ok, msg = Shade.recognize(box.Text)
		sNote.Text = msg
		toast(msg)
		if ok then
			box.Text = ""
			if P.save then pcall(P.save) end
		end
	end)
	bs.cycler("内置风格", function() return Shade.label end, function()
		local idx = 1
		for i, k in ipairs(SHADE_ORDER) do if k == Shade.profileKey then idx = i break end end
		local key = SHADE_ORDER[idx % #SHADE_ORDER + 1]
		Shade.applyKey(key)
		sNote.Text = "已应用：" .. (SHADES[key] and SHADES[key].name or key)
	end)
	bs.slider("强度", 0, 1.6, 0.01, function() return T.shadePower end, function(v)
		Shade.setPower(v)
	end)
	bs.input("图片链接（当滤色片用）", "滤镜", function(box)
		local ok, msg = Shade.recognize(box.Text)
		sNote.Text = msg
		toast(msg)
		if ok then box.Text = "" end
	end)
	bs.buttons({
		{ text = "还原光影", cb = function()
			Shade.reset()
			sNote.Text = Shade.entryNote
			toast("光影已还原")
		end },
		{ text = "重新应用", cb = function()
			if Shade.profile then
				Shade.applyProfile(Shade.profile, Shade.label)
			else
				Shade.applyKey(Shade.profileKey)
			end
			sNote.Text = Shade.entryNote
			toast("已重新应用")
		end },
	})
	bs.note("Roblox 跑不了 MC 的 GLSL 光影包：这里把 BSL / Complementary / SEUS 这类观感映射成 Roblox 自带的色调映射、泛光、景深、太阳光、雾气、曝光；.json 光影包按同一套字段加载。", 46)
	bs.finish()

	--──────── 翻译 ────────
	local bt = newBuilder(pageScroll("text"))
	bt.switch("中文翻译", function() return T.translate end, function(v)
		T.translate = v
		refresh()
	end)
	bt.input("原文=中文, Settings=设置", "应用", function(box)
		parseTranslate(box.Text)
		refresh()
		toast("词条已更新")
	end)
	bt.note("只替换已知界面词；数值、键位、状态这类会变动的文字不会被写回。", 30)
	bt.buttons({
		{ text = "重新扫描界面", cb = function()
			for _, c in ipairs(containers()) do
				for _, child in ipairs(c:GetChildren()) do
					if child:IsA("ScreenGui") and child.Name:sub(1, 3) ~= "SG_" and child.Name:sub(1, 3) ~= "LG_" then
						resetDone(child)
						dressTree(child)
					end
				end
			end
			toast("已重新扫描")
		end },
		{ text = "恢复默认", accent = true, cb = function()
			T.accent = CONFIG.theme.accent
			T.seamless = CONFIG.theme.seamless
			T.border = CONFIG.theme.border
			T.scale = 1
			T.glass = CONFIG.theme.glass
			Shade.reset()
			refresh()
			toast("已恢复默认外观")
		end },
	})
	bt.finish()

	selectTab(T.tab or "look")

	local collapsed = false
	collapse.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		content.Visible = not collapsed
		tabsRow.Visible = not collapsed
		collapse.Text = collapsed and "+" or "–"
		TweenService:Create(card, TweenInfo.new(0.18), {
			Size = collapsed and UDim2.new(0, 300, 0, 38) or UDim2.new(0, 300, 0, 424),
		}):Play()
	end)
	closeBtn.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	-- 拖动：整块可拖，滑块/按钮/输入框按自己的逻辑走
	local dragging, startPos, startMouse = false, nil, nil
	card.InputBegan:Connect(function(input)
		if P.sliderBusy then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = card.Position
			startMouse = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - startMouse
			if math.abs(d.X) < 3 and math.abs(d.Y) < 3 then return end
			card.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)

	table.insert(P.hooks, function()
		card.BackgroundColor3 = T.tint
		card.BackgroundTransparency = 1 - clamp(T.glass, 0.3, 0.95)
		cardStroke.Transparency = 1 - 0.5 * T.border
		dot.BackgroundColor3 = T.accent
		hint.TextColor3 = T.dimc
	end)

	rebuildList()
end

--=====================================================================
-- 10 · 原脚本执行 + 接管界面
--=====================================================================
containers = function()
	local list = {}
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then table.insert(list, h) end
	end
	local ok, pg = pcall(function() return LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
	if ok and pg then table.insert(list, pg) end
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and cg then table.insert(list, cg) end
	return list
end

local function snapshot()
	local set = {}
	for _, c in ipairs(containers()) do
		for _, g in ipairs(c:GetChildren()) do set[g] = true end
	end
	return set
end

local function collect(container, out, old)
	for _, g in ipairs(container:GetChildren()) do
		if not old[g] then
			if g:IsA("ScreenGui") then
				table.insert(out, g)
			elseif g:IsA("Folder") then
				for _, sub in ipairs(g:GetChildren()) do
					if sub:IsA("ScreenGui") and not old[sub] then table.insert(out, sub) end
				end
			end
		end
	end
end

local function newScreenGuis(old)
	local out = {}
	for _, c in ipairs(containers()) do pcall(collect, c, out, old) end
	return out
end

local function runOriginal()
	local okHttp, src = pcall(function() return game:HttpGet(CONFIG.scriptUrl, true) end)
	if not okHttp or type(src) ~= "string" or #src < 100 then
		warn("[SG] 拉取原脚本失败: " .. tostring(src))
		return
	end
	local compile = loadstring or load
	if not compile then
		warn("[SG] 执行器没有 loadstring")
		return
	end
	local fn, err = compile(src)
	if not fn then
		warn("[SG] 编译失败: " .. tostring(err))
		return
	end
	local ok, e = pcall(fn)
	if not ok then warn("[SG] 原脚本报错（皮肤不受影响）: " .. tostring(e)) end
end

local function effectivelyVisible(obj)
	if not obj or not obj.Parent then return false end
	local o = obj
	while o do
		if o:IsA("GuiObject") and o.Visible == false then return false end
		if o:IsA("ScreenGui") and o.Enabled == false then return false end
		o = o.Parent
	end
	return true
end

local function startWatch()
	local before = snapshot()
	local watched = {}

	local function adopt(gui)
		if watched[gui] then return end
		watched[gui] = true
		local nm = tostring(gui.Name or "")
		if nm:sub(1, 3) == "SG_" or nm:sub(1, 3) == "LG_" then return end
		Reg.guis[gui] = true
		pcall(function() gui.ResetOnSpawn = false end)
		pause(0.35)
		dressTree(gui)
		pause(0.7)
		dressTree(gui)
		pcall(function()
			gui.DescendantAdded:Connect(function(inst)
				if not inst:IsA("GuiObject") then return end
				pause(0.05)
				if inst.Parent and not Reg.done[inst] then dressTree(inst) end
			end)
		end)
	end

	schedule(function()
		local deadline = tick() + CONFIG.waitTimeout
		while tick() < deadline do
			for _, g in ipairs(newScreenGuis(before)) do
				before[g] = true
				schedule(adopt, g)
			end
			pause(0.2)
		end
		if next(Reg.guis) == nil then
			toast("没抓到原界面：点「重新扫描界面」，或调大 waitTimeout")
		end
		local endTime = tick() + CONFIG.watchSeconds
		while tick() < endTime do
			for _, g in ipairs(newScreenGuis(before)) do
				before[g] = true
				schedule(adopt, g)
			end
			pause(0.6)
		end
	end)
end

local function startLive()
	schedule(function()
		local blur = ensureBlur()
		while true do
			pause(0.25)
			if not blur or not blur.Parent then blur = ensureBlur() end
			local anyVisible = false
			for win in pairs(Reg.windows) do
				if effectivelyVisible(win) then anyVisible = true break end
			end
			if next(Reg.windows) == nil then
				for gui in pairs(Reg.guis) do
					if effectivelyVisible(gui) then anyVisible = true break end
				end
			end
			if blur then
				if T.followWindow then
					blur.Enabled = anyVisible and T.blur > 0
				else
					blur.Enabled = T.blur > 0
				end
			end
			if Wall.gui and Wall.gui.Parent then
				if T.followWindow and next(Reg.windows) ~= nil then
					if Wall.gui.Enabled ~= anyVisible then Wall.gui.Enabled = anyVisible end
				elseif not Wall.gui.Enabled then
					Wall.gui.Enabled = true
				end
			end
			if Wall.aurora then Wall.aurora.Visible = T.aurora end
		end
	end)

	schedule(function()
		while true do
			pause(0.05)
			for win, layers in pairs(Reg.shadow) do
				if not win.Parent then
					for _, l in ipairs(layers) do
						if l.f and l.f.Parent then l.f:Destroy() end
					end
					Reg.shadow[win] = nil
				else
					for _, l in ipairs(layers) do
						local f = l.f
						if f and f.Parent then
							f.Size = win.Size
							f.AnchorPoint = win.AnchorPoint
							f.Position = UDim2.new(
								win.Position.X.Scale, win.Position.X.Offset,
								win.Position.Y.Scale, win.Position.Y.Offset + l.off
							)
							f.Visible = win.Visible and T.chrome
						end
					end
				end
			end
		end
	end)

	schedule(function()
		while true do
			pause(0.5)
			local a = Wall.aurora
			if a and a.Parent and T.aurora then
				local g = a:FindFirstChildOfClass("UIGradient")
				if g then
					local tw = TweenService:Create(g, TweenInfo.new(20, Enum.EasingStyle.Linear), { Rotation = g.Rotation + 360 })
					tw:Play()
					tw.Completed:Wait()
					g.Rotation = g.Rotation % 360
				else
					pause(2)
				end
			end
		end
	end)
end

--=====================================================================
-- 11 · 快捷键 / 存档
--=====================================================================
local function bindKey()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == CONFIG.panelKey and P.gui and P.gui.Parent then
			P.gui.Enabled = not P.gui.Enabled
		end
	end)
end

local function saveState()
	if type(writefile) ~= "function" then return end
	local items = {}
	for _, it in ipairs(Wall.items) do table.insert(items, it.url) end
	local payload = {
		accent = { round(T.accent.R * 255), round(T.accent.G * 255), round(T.accent.B * 255) },
		glass = T.glass, border = T.border, corner = T.corner, scale = T.scale,
		seamless = T.seamless, chrome = T.chrome, translate = T.translate, grip = T.grip,
		mode = T.mode, hold = T.hold, speed = T.speed, dim = T.dim, wall = T.wallAlpha,
		aurora = T.aurora, dust = T.dust, blur = T.blur, followWindow = T.followWindow,
		shade = Shade.profileKey, shadePower = T.shadePower,
		items = items,
	}
	local ok, json = pcall(function() return game:GetService("HttpService"):JSONEncode(payload) end)
	if not ok then return end
	pcall(function() writefile("SG_Config.json", json) end)
end
P.save = saveState

local function loadState()
	if type(readfile) ~= "function" then return end
	local ok, raw = pcall(function() return readfile("SG_Config.json") end)
	if not ok or type(raw) ~= "string" or #raw < 8 then return end
	local ok2, d = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
	if not ok2 or type(d) ~= "table" then return end

	local function num(v, fb) if type(v) == "number" then return v end return fb end
	local function bool(v, fb) if type(v) == "boolean" then return v end return fb end

	if type(d.accent) == "table" and #d.accent >= 3 then
		T.accent = Color3.fromRGB(d.accent[1], d.accent[2], d.accent[3])
	end
	T.glass = num(d.glass, T.glass)
	T.border = num(d.border, T.border)
	T.corner = num(d.corner, T.corner)
	T.scale = num(d.scale, T.scale)
	T.seamless = bool(d.seamless, T.seamless)
	T.chrome = bool(d.chrome, T.chrome)
	T.translate = bool(d.translate, T.translate)
	T.grip = bool(d.grip, T.grip)
	T.mode = type(d.mode) == "string" and d.mode or T.mode
	T.hold = num(d.hold, T.hold)
	T.speed = num(d.speed, T.speed)
	T.dim = num(d.dim, T.dim)
	T.wallAlpha = num(d.wall, T.wallAlpha)
	T.aurora = bool(d.aurora, T.aurora)
	T.dust = bool(d.dust, T.dust)
	T.blur = num(d.blur, T.blur)
	T.followWindow = bool(d.followWindow, T.followWindow)
	T.shadePower = num(d.shadePower, T.shadePower)
	if type(d.shade) == "string" and SHADES[d.shade] then Shade.profileKey = d.shade end
	if type(d.items) == "table" then
		for _, u in ipairs(d.items) do
			if type(u) == "string" and u ~= "" then
				table.insert(Wall.items, { url = u, id = u, kind = "image" })
			end
		end
	end
end

--=====================================================================
-- 12 · 启动
--=====================================================================
local function boot()
	loadState()

	for _, it in ipairs(CONFIG.backdrop.items or {}) do
		if type(it) == "string" and it ~= "" then
			table.insert(Wall.items, { url = it, id = it, kind = "image" })
		end
	end

	if CONFIG.shade.preset and SHADES[CONFIG.shade.preset] then
		Shade.profileKey = CONFIG.shade.preset
	end

	Wall.refresh()
	ensureBlur()
	buildPanel()
	bindKey()

	if #Wall.items > 0 then
		schedule(function()
			pause(0.3)
			for i, it in ipairs(Wall.items) do
				local asset = isVideoUrl(it.url) and resolveVideo(it.url) or resolveImage(it.url)
				if asset and asset.id then
					Wall.items[i] = {
						url = it.url, id = asset.id,
						kind = asset.kind or "image",
						w = asset.w, h = asset.h, path = asset.path,
					}
				end
			end
			if P.rebuildList then pcall(P.rebuildList) end
			Wall.play()
		end)
	else
		Wall.play()
	end

	if Shade.profileKey and SHADES[Shade.profileKey] and Shade.profileKey ~= "vanilla" then
		pcall(Shade.applyKey, Shade.profileKey)
	end

	startWatch()
	if CONFIG.runOriginal then
		schedule(runOriginal)
	end
	startLive()

	toast("无痕外观已就位 · F2 开合面板")
end

--=====================================================================
-- 13 · 对外接口
--=====================================================================
local function destroy()
	pcall(function() if P.gui then P.gui:Destroy() end end)
	pcall(function() if Wall.gui then Wall.gui:Destroy() end end)
	pcall(function() if Toast.gui then Toast.gui:Destroy() end end)
	pcall(function() if Shade.filterGui then Shade.filterGui:Destroy() end end)
	local blur = Lighting:FindFirstChild("SG_SceneBlur")
	if blur then pcall(function() blur:Destroy() end) end
	for _, layers in pairs(Reg.shadow) do
		for _, l in ipairs(layers) do
			pcall(function() if l.f then l.f:Destroy() end end)
		end
	end
	pcall(Shade.reset)
end

if getgenv and getgenv().SEAMLESS_DHC and getgenv().SEAMLESS_DHC.destroy then
	pcall(getgenv().SEAMLESS_DHC.destroy)
end

print("[SG] Doors HardCore · 无痕玻璃 v3 启动")

local okBoot, errBoot = pcall(boot)
if not okBoot then warn("[SG] 启动失败: " .. tostring(errBoot)) end

if getgenv then
	getgenv().SEAMLESS_DHC = {
		destroy = destroy,
		wall = Wall,
		shade = Shade,
		state = T,
		refresh = refresh,
		save = saveState,
		panel = P,
	}
end
