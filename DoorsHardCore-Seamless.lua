--=====================================================================
--  Doors HardCore  ·  无痕玻璃  Seamless Glass  (v2)
--  给原脚本外挂一层「无缝透明边框」皮肤 + 壁纸引擎 + 材质/光影 + 文辞替换
-----------------------------------------------------------------------
--  原脚本（不改一行）： https://raw.githubusercontent.com/Zero0Star/RipperNewSound/master/Doors-HardCore.lua
--  做法：原脚本照常跑 → 它创建的界面被就地重绘 → 右下角出现「夜行」调参卡
--
--  本次新增（相对 Liquid Glass v1）
--    · 无缝边框：描边/分割线可以完全消失，只有一层极淡玻璃
--    · 壁纸引擎：可以自己加链接，多图轮播 / 缓推镜头 / 整条帧带动画 / 视频 / 极光
--    · 材质 & 光影：客户端材质覆写包 + Lighting 调色预设（可一键还原）
--    · 文辞：把界面里的英文词换成文艺中文（可自填词条）
--    · 尺幅：全局缩放 0.6x ~ 1.6x，配色调色相滑杆
--
--  用法：整段粘进执行器回车；或传到 gist 后 loadstring 远程载入
--  面板开合：F2      （改 CONFIG.panelKey 可换）
--  还原：面板里点「洗砚」，或重新进游戏
--=====================================================================

local CONFIG = {
	scriptUrl    = "https://raw.githubusercontent.com/Zero0Star/RipperNewSound/master/Doors-HardCore.lua",
	runOriginal  = true,    -- false = 只看皮肤，不跑原脚本
	waitTimeout  = 30,      -- 等原脚本界面出现的秒数
	watchSeconds = 120,     -- 之后继续接住新控件的秒数
	panelKey     = Enum.KeyCode.F2,

	theme = {
		accent   = Color3.fromRGB(0, 200, 0),  -- 强调色（DSH 绿）
		glass    = 0.72,   -- 玻璃不透明度 0~1
		border   = 0.35,   -- 描边强度 0~1（0 = 完全无缝）
		corner   = 16,     -- 圆角 px
		scale    = 1,      -- 尺幅
		seamless = true,   -- 无缝模式
		chrome   = true,   -- 顶部高光
		textStyle= true,   -- 文辞替换
	},
	backdrop = {
		items        = {},        -- 壁纸队列：字符串 或 {url=..., kind="image"/"video"}
		mode         = "pan",     -- still / pan / cross / sprite / video / aurora
		hold         = 9,         -- 每张停留秒数
		speed        = 1,         -- 动画速度倍率
		dim          = 0.20,      -- 全屏压暗
		wall         = 0.94,      -- 壁纸浓度
		aurora       = true,      -- 极光层
		dust         = false,     -- 光尘
		blur         = 10,        -- 场景磨砂
		followWindow = true,      -- 只在菜单可见时生效
	},
	scene = {
		lights   = "off",  -- off / cinema / moon / neon / gloom
		material = "off",  -- off / marble / glass / metal / neon / wood / fabric
	},
}

--=====================================================================
--  0 · 环境与工具
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

local function round(v)
	return math.floor(v + 0.5)
end

local function trim(s)
	return (tostring(s or ""):gsub("^%s*(.-)%s*$", "%1"))
end

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

local function lum(c)
	return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function sat(c)
	return math.max(c.R, c.G, c.B) - math.min(c.R, c.G, c.B)
end

local function hueOf(c)
	local h = c:ToHSV()
	return h
end

local function hash(s)
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + s:byte(i)) % 2147483647
	end
	return h
end

-- 从图片字节流里读尺寸（PNG / JPEG / GIF），用来做「整条帧带」切分
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
	accent   = CONFIG.theme.accent,
	glass    = CONFIG.theme.glass,
	border   = CONFIG.theme.border,
	corner   = CONFIG.theme.corner,
	scale    = CONFIG.theme.scale,
	seamless = CONFIG.theme.seamless,
	chrome   = CONFIG.theme.chrome,
	textStyle= CONFIG.theme.textStyle,

	mode         = CONFIG.backdrop.mode,
	hold         = CONFIG.backdrop.hold,
	speed        = CONFIG.backdrop.speed,
	dim          = CONFIG.backdrop.dim,
	wallAlpha    = CONFIG.backdrop.wall,
	aurora       = CONFIG.backdrop.aurora,
	dust         = CONFIG.backdrop.dust,
	blur         = CONFIG.backdrop.blur,
	followWindow = CONFIG.backdrop.followWindow,
	frames       = 8,

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
	windows= setmetatable({}, { __mode = "k" }),
	guis   = setmetatable({}, { __mode = "k" }),
	shadow = {},
}

local P = { gui = nil, card = nil, scroll = nil, renders = {}, hooks = {}, rebuildList = nil }

-- 前置声明：面板按钮和换肤引擎都要用到
local containers

--=====================================================================
--  2 · GUI 挂载点
--=====================================================================
local function guiParentCandidates()
	local list = {}
	if gethui then table.insert(list, function() return gethui() end) end
	table.insert(list, function() return game:GetService("CoreGui") end)
	table.insert(list, function() return LocalPlayer:WaitForChild("PlayerGui", 8) end)
	return list
end

local function attachGui(gui)
	for _, f in ipairs(guiParentCandidates()) do
		local ok = pcall(function() gui.Parent = f() end)
		if ok and gui.Parent then return gui.Parent end
	end
	return nil
end

--=====================================================================
--  3 · 图片资源解析（assetid / 直链 → 本地缓存）
--=====================================================================
local AssetCache = {}

local function fileApi()
	return type(writefile) == "function" and type(getcustomasset) == "function"
end

local function resolveImage(url)
	url = trim(url):gsub("%s+", "")
	if url == "" then return nil, "空链接" end
	local low = url:lower()
	if url:match("^%d+$") then return { id = "rbxassetid://" .. url, kind = "image" } end
	if low:sub(1, 11) == "rbxassetid" then return { id = url, kind = "image" } end
	if low:sub(1, 8) == "rbxasset" then return { id = url, kind = "image" } end
	if AssetCache[url] then return AssetCache[url] end
	if not url:match("^https?://") then return nil, "认不出这个地址" end
	if not fileApi() then return nil, "执行器缺 writefile/getcustomasset" end

	local ok, res = pcall(function()
		local dir = "SG_Assets"
		local canDir = false
		if type(isfolder) == "function" and type(makefolder) == "function" then
			pcall(function() canDir = isfolder(dir) end)
			if not canDir then
				pcall(function()
					makefolder(dir)
					canDir = true
				end)
			end
		end
		local ext = low:match("%.(%a%a%a?%a?)$") or "png"
		ext = ext:lower()
		if ext ~= "png" and ext ~= "jpg" and ext ~= "jpeg" and ext ~= "webp" and ext ~= "bmp" and ext ~= "gif" then
			ext = "png"
		end
		local path = (canDir and (dir .. "/") or "") .. tostring(hash(url)) .. "." .. ext
		local bytes
		if type(isfile) == "function" and type(readfile) == "function" then
			local exists = false
			pcall(function() exists = isfile(path) end)
			if exists then
				local okRead, cached = pcall(readfile, path)
				if okRead and type(cached) == "string" and #cached >= 64 then bytes = cached end
			end
		end
		if type(bytes) ~= "string" or #bytes < 64 then
			bytes = game:HttpGet(url, true)
			if type(bytes) ~= "string" or #bytes < 64 then error("下载内容不像图片") end
			writefile(path, bytes)
		end
		local w, h = imageDims(bytes)
		return { id = getcustomasset(path), w = w, h = h, kind = "image", path = path }
	end)

	if ok and res then
		AssetCache[url] = res
		return res
	end
	return nil, tostring(res)
end

--=====================================================================
--  4 · 鱼雁（提示条）
--=====================================================================
local Toast = { gui = nil, box = nil, label = nil, token = 0 }

local function toast(msg)
	local ok = pcall(function()
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
				Size = UDim2.new(0, 0, 0, 30),
				Position = UDim2.new(0.5, 0, 1, -76),
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
				Size = UDim2.new(1, -26, 1, 0),
				Position = UDim2.new(0, 13, 0, 0),
				BackgroundTransparency = 1,
				Font = FONT_BODY,
				TextSize = 12,
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
		local w = math.clamp(#tostring(msg) * 12 + 34, 120, 420)
		box.Size = UDim2.new(0, w, 0, 30)
		Toast.token = Toast.token + 1
		local my = Toast.token
		schedule(function()
			pause(2.6)
			if Toast.token ~= my then return end
			TweenService:Create(box, TweenInfo.new(0.5), {
				BackgroundTransparency = 1,
			}):Play()
			TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		end)
	end)
	if not ok then warn("[SG] toast 失败: " .. tostring(msg)) end
end

--=====================================================================
--  5 · 壁纸引擎
--=====================================================================
local Wall = {
	gui = nil, holder = nil, layerA = nil, layerB = nil,
	scrim = nil, vig = nil, aurora = nil, dust = nil, front = nil,
	gen = 0, idx = 1, items = {}, fading = false,
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

	-- 极光层：一块极淡的渐变，缓慢旋转
	local aurora = make("Frame", {
		Name = "SG_Aurora",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = holder,
	})
	local grad = make("UIGradient", {
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
	Wall.auroraGradient = grad

	-- 光尘
	local dust = make("Frame", {
		Name = "SG_Dust",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 4,
		Parent = holder,
	})
	Wall.dust = dust
	for i = 1, 16 do
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
		local dur = math.random(9, 20) + math.random()
		local startY = dot.Position.Y.Scale
		local tw = TweenService:Create(dot, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
			Position = UDim2.new(dot.Position.X.Scale, 0, startY - 0.18, 0),
			BackgroundTransparency = 1,
		})
		tw:Play()
	end

	-- 顶部渐隐
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

	local scrim = make("Frame", {
		Name = "SG_Scrim",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1 - T.dim,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = holder,
	})
	Wall.scrim = scrim

	return gui
end

local function frontAlpha()
	return 1 - clamp(T.wallAlpha, 0, 1)
end

local function applyLook()
	if not (Wall.gui and Wall.gui.Parent) then return end
	if Wall.scrim then Wall.scrim.BackgroundTransparency = 1 - clamp(T.dim, 0, 0.95) end
	if not Wall.fading then
		if Wall.layerA then
			Wall.layerA.ImageTransparency = (Wall.front == Wall.layerA) and frontAlpha() or 1
		end
		if Wall.layerB then
			Wall.layerB.ImageTransparency = (Wall.front == Wall.layerB) and frontAlpha() or 1
		end
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
	local tw = TweenService:Create(layer, TweenInfo.new(math.max(5, T.hold * 1.7), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Size = UDim2.new(sc, 0, sc, 0),
		Position = UDim2.new(0.5 + px, 0, 0.5 + py, 0),
	})
	tw:Play()
end

local function showVideo(item)
	if Wall.video and Wall.video.Parent then Wall.video:Destroy() end
	local ok, vf = pcall(function()
		local v = Instance.new("VideoFrame")
		v.Name = "SG_Video"
		v.Size = UDim2.new(1, 0, 1, 0)
		v.BackgroundTransparency = 1
		v.ZIndex = 2
		v.Looped = true
		v.Volume = 0
		v.Video = item.id
		v.Playing = true
		v.Parent = Wall.holder
		return v
	end)
	if ok and vf then
		Wall.video = vf
		if Wall.layerA then Wall.layerA.ImageTransparency = 1 end
		if Wall.layerB then Wall.layerB.ImageTransparency = 1 end
		if Wall.front then Wall.front = nil end
		toast("视频壁纸已装载")
	else
		toast("这个执行器/资源不支持 VideoFrame")
	end
end

local function stopLoops()
	Wall.gen = Wall.gen + 1
	return Wall.gen
end

local function playPlaylist()
	local gen = stopLoops()
	local items = Wall.items
	if #items == 0 then
		if Wall.layerA then Wall.layerA.Image = ""; Wall.layerA.ImageTransparency = 1 end
		if Wall.layerB then Wall.layerB.Image = ""; Wall.layerB.ImageTransparency = 1 end
		if Wall.video and Wall.video.Parent then Wall.video:Destroy() end
		Wall.video = nil
		Wall.front = nil
		return
	end

	schedule(function()
		local first = true
		while gen == Wall.gen do
			local item = Wall.items[Wall.idx]
			if not item then Wall.idx = 1; item = Wall.items[1] end
			if not item then break end
			Wall.idx = Wall.idx % math.max(1, #Wall.items) + 1

			if T.mode == "video" then
				showVideo(item)
				pause(2)
			elseif T.mode == "sprite" and item.w and item.h then
				local frames = math.max(2, math.min(64, round(T.frames)))
				local fw = math.floor(item.w / frames)
				if fw < 1 then fw = 1 end
				local layer = Wall.layerA
				if Wall.video and Wall.video.Parent then Wall.video:Destroy() end
				Wall.video = nil
				layer.Image = item.id or ""
				layer.ImageRectSize = Vector2.new(fw, item.h)
				layer.ImageRectOffset = Vector2.new(0, 0)
				layer.AnchorPoint = Vector2.new(0, 0)
				layer.Size = UDim2.new(1, 0, 1, 0)
				layer.Position = UDim2.new(0, 0, 0, 0)
				layer.ImageTransparency = frontAlpha()
				Wall.front = layer
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
				pause(math.max(2, T.hold))
			elseif T.mode == "still" then
				local layer = Wall.layerB
				if Wall.video and Wall.video.Parent then Wall.video:Destroy() end
				Wall.video = nil
				if layer then
					layer.Image = item.id or ""
					layer.ImageTransparency = 1
					layer.Size = UDim2.new(1, 0, 1, 0)
					layer.Position = UDim2.new(0.5, 0, 0.5, 0)
					layer.AnchorPoint = Vector2.new(0.5, 0.5)
					Wall.front = layer
					applyLook()
				end
				pause(3600)
			elseif T.mode == "aurora" then
				if Wall.layerA then Wall.layerA.Image = ""; Wall.layerA.ImageTransparency = 1 end
				if Wall.layerB then Wall.layerB.Image = ""; Wall.layerB.ImageTransparency = 1 end
				pause(3600)
			else
				-- pan / cross：交叉淡入 + 缓推镜头
				local a, b = Wall.layerA, Wall.layerB
				local useBack = (Wall.front ~= b) and b or a
				local useFront = Wall.front
				if useBack then
					useBack.Image = item.id or ""
					useBack.ImageTransparency = 1
					useBack.ImageRectSize = Vector2.new(0, 0)
					useBack.ImageRectOffset = Vector2.new(0, 0)
					kenBurns(useBack)
					Wall.fading = true
					TweenService:Create(useBack, TweenInfo.new(0.9, Enum.EasingStyle.Sine), {
						ImageTransparency = frontAlpha(),
					}):Play()
					if useFront then
						TweenService:Create(useFront, TweenInfo.new(0.9, Enum.EasingStyle.Sine), {
							ImageTransparency = 1,
						}):Play()
					end
					Wall.front = useBack
					pause(0.95)
					Wall.fading = false
				end
				pause(math.max(2, T.hold))
			end
		end
	end)
end

function Wall.refresh()
	wallGui()
	applyLook()
end

function Wall.add(url, kind)
	url = trim(url)
	if url == "" then return false, "空链接" end
	if url:lower():match("%.gif$") then
		return false, "GIF 无法直接播放，请拆成多张图或用 .mp4 视频 id"
	end
	local asset, err = resolveImage(url)
	if not asset or not asset.id then return false, err or "解析失败" end
	table.insert(Wall.items, {
		url = url,
		id = asset.id,
		w = asset.w,
		h = asset.h,
		kind = kind or (T.mode == "video" and "video" or "image"),
	})
	Wall.idx = math.max(1, #Wall.items - 1)
	if P.rebuildList then pcall(P.rebuildList) end
	playPlaylist()
	return true
end

function Wall.clear()
	Wall.items = {}
	Wall.idx = 1
	if P.rebuildList then pcall(P.rebuildList) end
	playPlaylist()
end

function Wall.remove(idx)
	table.remove(Wall.items, idx)
	if Wall.idx > #Wall.items then Wall.idx = 1 end
	if P.rebuildList then pcall(P.rebuildList) end
	playPlaylist()
end

function Wall.applyAll()
	for i, it in ipairs(Wall.items) do
		if type(it) == "string" then
			local asset = resolveImage(it)
			if asset and asset.id then
				Wall.items[i] = { url = it, id = asset.id, w = asset.w, h = asset.h, kind = "image" }
			end
		end
	end
	playPlaylist()
	if P.rebuildList then pcall(P.rebuildList) end
end

--=====================================================================
--  6 · 光影 & 材质
--=====================================================================
local Scene = {
	lightsPreset = "off",
	savedLighting = nil,
	effects = {},
	matPreset = "off",
	matSaved = setmetatable({}, { __mode = "k" }),
	matToken = 0,
}

local LIGHT_PRESETS = {
	off = nil,
	cinema = {
		lighting = {
			Brightness = 1.15,
			Ambient = Color3.fromRGB(76, 72, 66),
			OutdoorAmbient = Color3.fromRGB(70, 68, 62),
			ColorShift_Top = Color3.fromRGB(255, 240, 214),
		},
		cc = { TintColor = Color3.fromRGB(255, 236, 210), Contrast = 0.14, Saturation = 0.10, Brightness = 0.02 },
		bloom = { Intensity = 0.55, Size = 22, Threshold = 1.05 },
		dof = { FarIntensity = 0.14, FocusDistance = 18, InFocusRadius = 46, NearIntensity = 0.18 },
	},
	moon = {
		lighting = {
			Brightness = 0.85,
			Ambient = Color3.fromRGB(58, 66, 86),
			OutdoorAmbient = Color3.fromRGB(52, 60, 82),
			ColorShift_Top = Color3.fromRGB(196, 214, 255),
		},
		cc = { TintColor = Color3.fromRGB(206, 226, 255), Contrast = 0.10, Saturation = -0.06, Brightness = 0.01 },
		bloom = { Intensity = 0.35, Size = 18, Threshold = 1.2 },
	},
	neon = {
		lighting = {
			Brightness = 1.3,
			Ambient = Color3.fromRGB(46, 24, 60),
			OutdoorAmbient = Color3.fromRGB(40, 20, 52),
			ColorShift_Top = Color3.fromRGB(255, 140, 240),
		},
		cc = { TintColor = Color3.fromRGB(255, 210, 255), Contrast = 0.22, Saturation = 0.35, Brightness = 0.03 },
		bloom = { Intensity = 0.95, Size = 30, Threshold = 0.95 },
	},
	gloom = {
		lighting = {
			Brightness = 0.55,
			Ambient = Color3.fromRGB(32, 40, 44),
			OutdoorAmbient = Color3.fromRGB(28, 34, 38),
			ColorShift_Top = Color3.fromRGB(150, 176, 186),
		},
		cc = { TintColor = Color3.fromRGB(186, 205, 212), Contrast = 0.18, Saturation = -0.22, Brightness = -0.03 },
		dof = { FarIntensity = 0.10, FocusDistance = 26, InFocusRadius = 38, NearIntensity = 0.12 },
	},
}

local LIGHT_ORDER = { "off", "cinema", "moon", "neon", "gloom" }
local LIGHT_NAME = {
	off = "原始",
	cinema = "暖调电影",
	moon = "冷月",
	neon = "霓虹",
	gloom = "幽影",
}

local MAT_PRESETS = {
	off = nil,
	marble = { m = Enum.Material.Marble, r = 0.04, name = "大理石" },
	glass  = { m = Enum.Material.Glass,  r = 0.14, name = "玻璃" },
	metal  = { m = Enum.Material.Metal,  r = 0.30, name = "金属" },
	neon   = { m = Enum.Material.Neon,   r = 0.00, name = "霓虹" },
	wood   = { m = Enum.Material.WoodPlanks, r = 0.02, name = "木纹" },
	fabric = { m = Enum.Material.Fabric, r = 0.00, name = "布艺" },
}
local MAT_ORDER = { "off", "marble", "glass", "metal", "neon", "wood", "fabric" }

local LIGHT_PROPS = { "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ClockTime", "FogEnd", "FogColor" }

local function ensureEffect(class, name, props)
	local e = Lighting:FindFirstChild(name)
	if not e then
		local ok, made = pcall(function()
			local n = Instance.new(class)
			n.Name = name
			n.Parent = Lighting
			return n
		end)
		if not ok or not made then return nil end
		e = made
		table.insert(Scene.effects, e)
	end
	if props then
		for k, v in pairs(props) do pcall(function() e[k] = v end) end
	end
	pcall(function() e.Enabled = true end)
	return e
end

function Scene.applyLights(name)
	if Scene.savedLighting == nil then
		Scene.savedLighting = {}
		for _, k in ipairs(LIGHT_PROPS) do
			local ok, v = pcall(function() return Lighting[k] end)
			if ok then Scene.savedLighting[k] = v end
		end
	end

	for _, e in ipairs(Scene.effects) do pcall(function() e.Enabled = false end) end
	Scene.lightsPreset = name or "off"

	local def = LIGHT_PRESETS[Scene.lightsPreset]
	if not def then
		for k, v in pairs(Scene.savedLighting) do pcall(function() Lighting[k] = v end) end
		return true
	end
	for k, v in pairs(def.lighting or {}) do pcall(function() Lighting[k] = v end) end
	if def.cc then ensureEffect("ColorCorrectionEffect", "SG_CC", def.cc) end
	if def.bloom then ensureEffect("BloomEffect", "SG_Bloom", def.bloom) end
	if def.dof then ensureEffect("DepthOfFieldEffect", "SG_DOF", def.dof) end
	if def.sun then ensureEffect("SunRaysEffect", "SG_Sun", def.sun) end
	return true
end

function Scene.restoreMats()
	Scene.matToken = Scene.matToken + 1
	for part, old in pairs(Scene.matSaved) do
		pcall(function()
			if part.Parent then
				part.Material = old.m
				part.Reflectance = old.r
			end
		end)
		Scene.matSaved[part] = nil
	end
end

function Scene.applyMats(name)
	Scene.matToken = Scene.matToken + 1
	local token = Scene.matToken
	Scene.matPreset = name or "off"
	local def = MAT_PRESETS[Scene.matPreset]
	if not def then
		Scene.restoreMats()
		return true
	end
	schedule(function()
		local n = 0
		local char = LocalPlayer.Character
		for _, d in ipairs(workspace:GetDescendants()) do
			if token ~= Scene.matToken then return end
			if d:IsA("BasePart") then
				local skip = false
				if char and d:IsDescendantOf(char) then skip = true end
				if not skip then
					if not Scene.matSaved[d] then
						Scene.matSaved[d] = { m = d.Material, r = d.Reflectance }
					end
					pcall(function()
						d.Material = def.m
						d.Reflectance = def.r
					end)
					n = n + 1
					if n % 200 == 0 then pause() end
				end
			end
		end
		toast("材质「" .. def.name .. "」已落在 " .. tostring(n) .. " 个部件上")
	end)
	return true
end

function Scene.resetAll()
	Scene.applyLights("off")
	Scene.restoreMats()
end

--=====================================================================
--  7 · 文辞（文艺词表）
--=====================================================================
local TEXT_MAP = {
	["enable"] = "开卷", ["enabled"] = "已开卷", ["disable"] = "掩卷", ["disabled"] = "已掩卷",
	["on"] = "启", ["off"] = "止", ["toggle"] = "启止", ["toggles"] = "启止",
	["settings"] = "笺注", ["setting"] = "笺注", ["config"] = "存稿", ["configs"] = "存稿",
	["theme"] = "色调", ["close"] = "收卷", ["exit"] = "退席", ["back"] = "回望",
	["search"] = "寻章", ["keybind"] = "手札", ["keybinds"] = "手札", ["key"] = "手札",
	["apply"] = "落墨", ["save"] = "收存", ["load"] = "展卷", ["reset"] = "洗砚",
	["speed"] = "疾徐", ["jump"] = "跃起", ["walk"] = "缓行", ["run"] = "疾走",
	["player"] = "旅人", ["players"] = "旅人", ["target"] = "所指", ["item"] = "器物", ["items"] = "器物",
	["give"] = "赠予", ["spawn"] = "唤出", ["music"] = "声律", ["sound"] = "声律",
	["volume"] = "响度", ["light"] = "灯火", ["lights"] = "灯火", ["time"] = "时辰",
	["god"] = "不坏", ["godmode"] = "不坏之身", ["fly"] = "浮游", ["noclip"] = "穿墙",
	["esp"] = "窥影", ["aimbot"] = "引矢", ["teleport"] = "瞬行", ["tp"] = "瞬行",
	["auto"] = "自运", ["farm"] = "采撷", ["door"] = "门扉", ["doors"] = "门扉",
	["mode"] = "式", ["modes"] = "诸式", ["entity"] = "异影", ["entities"] = "异影",
	["admin"] = "执事", ["hub"] = "雅集", ["script"] = "卷册", ["scripts"] = "卷册",
	["notify"] = "鱼雁", ["notification"] = "鱼雁", ["copy"] = "誊录", ["paste"] = "粘帖",
	["language"] = "文辞", ["font"] = "字体", ["size"] = "尺幅", ["color"] = "丹青",
	["hide"] = "隐去", ["show"] = "显现", ["opacity"] = "浓淡", ["transparency"] = "浓淡",
	["loading"] = "稍候", ["success"] = "如意", ["failed"] = "未果", ["error"] = "差错",
	["weapon"] = "兵刃", ["weapons"] = "兵刃", ["shop"] = "市集", ["coin"] = "铜钱",
	["coins"] = "铜钱", ["money"] = "铜钱", ["health"] = "气血", ["revive"] = "还魂",
	["kill"] = "断念", ["heal"] = "回春", ["welcome"] = "相逢", ["thanks"] = "承情",
	["hardcore"] = "硬骨", ["mode center"] = "诸式之枢", ["modes center"] = "诸式之枢",
	["entity spawner"] = "唤影", ["private"] = "私室", ["private modes"] = "私室诸式",
}

local CUSTOM_MAP = {}

local function mapText(s)
	if type(s) ~= "string" then return s end
	if not T.textStyle then return s end
	if s == "" or #s > 32 or s:find("\n") then return s end
	local t = trim(s)
	if t == "" then return s end
	local low = t:lower()

	if CUSTOM_MAP[low] then
		return (s:gsub(t:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"), CUSTOM_MAP[low]))
	end
	if TEXT_MAP[low] then
		return (s:gsub(t:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"), TEXT_MAP[low]))
	end

	local out = s
	for key, val in pairs(CUSTOM_MAP) do
		if #key >= 4 and key:match("^[%a ]+$") then
			out = out:gsub("%f[%a]" .. key .. "%f[%A]", val)
		end
	end
	return out
end

local function parseCustom(str)
	CUSTOM_MAP = {}
	for chunk in tostring(str or ""):gmatch("[^,;\n，；]+") do
		local k, v = chunk:match("^%s*(.-)%s*=%s*(.-)%s*$")
		if k and v and k ~= "" and v ~= "" then
			CUSTOM_MAP[k:lower()] = v
		end
	end
	return CUSTOM_MAP
end

--=====================================================================
--  8 · 换肤引擎
--=====================================================================
local function accentHue()
	return hueOf(T.accent)
end

local function harmonize(c)
	if sat(c) < 0.14 then return c end
	local _, s, v = c:ToHSV()
	return Color3.fromHSV(accentHue(), math.min(1, s * 0.95 + 0.05), math.max(v, 0.42))
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
		if r > 0 then
			ensureCorner(o).CornerRadius = UDim.new(0, math.min(8, r))
		end
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
	if (o.TextSize or 14) >= 18 then
		o.Font = FONT_BOLD
	else
		o.Font = FONT_BODY
	end
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
	-- 文本被原脚本改过（计数 / 键位 / 状态），就把它当成新的原文，不覆盖回去
	if last ~= nil and cur ~= last and cur ~= base then
		Reg.origSt[o] = cur
		base = cur
	end
	local mapped = mapText(base)
	if o.Text ~= mapped then o.Text = mapped end
	Reg.mapOut[o] = mapped
end

local function isTopWindow(g)
	local p = g.Parent
	if not p then return false end
	local vp = viewport()
	local s = g.AbsoluteSize
	local big = s.X >= math.max(280, vp.X * 0.16) and s.Y >= math.max(150, vp.Y * 0.13)
	if not big then return false end
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
	local specs = {
		{ 10, 0.62, 26 },
		{ 20, 0.78, 34 },
		{ 34, 0.86, 44 },
	}
	for _, sp in ipairs(specs) do
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
		hl.Visible = T.chrome
		sheen.Visible = T.chrome
	end)
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
	if g.Name and (g.Name:sub(1, 3) == "SG_" or g.Name:sub(1, 3) == "LG_") then return end

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
			local kind = "control"
			if sat(Reg.origBG[g] or Color3.new(0, 0, 0)) > 0.22 then kind = "chip" end
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
				end
			end
		elseif cls == "ImageLabel" then
			if g.BackgroundTransparency < 0.96 then
				g.BackgroundColor3 = harmonize(g.BackgroundColor3)
				g.BackgroundTransparency = math.max(g.BackgroundTransparency, 0.60)
			end
		end
	end

	for _, ch in ipairs(g:GetChildren()) do
		dress(ch)
	end
end

local function dressTree(root)
	if not root or not root.Parent then return end
	local ok, err = pcall(dress, root)
	if not ok then warn("[SG] 跳过一处节点: " .. tostring(err)) end
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
		pause(0.04)
		refreshQueued = false
		local ok, err = pcall(refreshNow)
		if not ok then warn("[SG] 刷新失败: " .. tostring(err)) end
	end)
end

--=====================================================================
--  9 · 调参面板「夜行」
--=====================================================================
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

local function pillButton(parent, text, props, onClick)
	local cfg = {
		Text = text,
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.35,
		Font = FONT_BODY,
		TextSize = 12,
		TextColor3 = T.text,
		AutoButtonColor = false,
		Parent = parent,
	}
	for k, v in pairs(props or {}) do cfg[k] = v end
	local b = make("TextButton", cfg)
	make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = b })
	make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.82, Thickness = 1, Parent = b })
	b.MouseButton1Click:Connect(onClick)
	table.insert(P.hooks, function()
		b.TextColor3 = T.text
		b.BackgroundColor3 = T.tint2
	end)
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
		Size = UDim2.new(0, 324, 0, 500),
		Position = UDim2.new(1, -20, 1, -20),
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
	make("UIGradient", {
		Rotation = 55,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.5, 0.75),
			NumberSequenceKeypoint.new(1, 0.35),
		}),
		Parent = cardStroke,
	})

	local header = make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = card,
	})
	local dot = make("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		Position = UDim2.new(0, 18, 0, 23),
		BackgroundColor3 = T.accent,
		Parent = header,
	})
	make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
	make("TextLabel", {
		Text = "夜 行 · 无 痕",
		Size = UDim2.new(1, -70, 0, 15),
		Position = UDim2.new(0, 34, 0, 15),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		TextSize = 12,
		TextColor3 = T.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	make("TextLabel", {
		Text = "SEAMLESS · 玻璃 / 壁纸 / 光影",
		Size = UDim2.new(1, -70, 0, 12),
		Position = UDim2.new(0, 34, 0, 30),
		BackgroundTransparency = 1,
		Font = FONT_BODY,
		TextSize = 9,
		TextColor3 = T.dimc,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local collapse = make("TextButton", {
		Text = "–",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -38, 0, 12),
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.55,
		AutoButtonColor = false,
		Font = FONT_BODY,
		TextSize = 14,
		TextColor3 = T.text,
		Parent = header,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 9), Parent = collapse })

	local scroll = make("ScrollingFrame", {
		Name = "Body",
		Size = UDim2.new(1, -32, 1, -68),
		Position = UDim2.new(0, 16, 0, 58),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.accent,
		ScrollBarImageTransparency = 0.45,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = card,
	})
	P.scroll = scroll

	local body = make("Frame", {
		Name = "Canvas",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = scroll,
	})
	local y = 0

	local function nextRow(h)
		local row = make("Frame", {
			Size = UDim2.new(1, 0, 0, h),
			Position = UDim2.new(0, 0, 0, y),
			BackgroundTransparency = 1,
			Parent = body,
		})
		y = y + h
		return row
	end

	local function addHeader(text)
		local row = nextRow(30)
		make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0, 4),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.88,
			BorderSizePixel = 0,
			Parent = row,
		})
		make("TextLabel", {
			Text = text,
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 11),
			BackgroundTransparency = 1,
			Font = FONT_BOLD,
			TextSize = 11,
			TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		return row
	end

	local function addNote(text)
		local row = nextRow(20)
		make("TextLabel", {
			Text = text,
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 3),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 10,
			TextColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = row,
		})
		return row
	end

	local function addSlider(label, minV, maxV, step, get, set)
		local row = nextRow(38)
		local cap = make("TextLabel", {
			Text = label,
			Size = UDim2.new(1, -70, 0, 14),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 11,
			TextColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local val = make("TextLabel", {
			Text = "",
			Size = UDim2.new(0, 70, 0, 14),
			Position = UDim2.new(1, -70, 0, 0),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 11,
			TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
		local track = make("Frame", {
			Size = UDim2.new(1, 0, 0, 5),
			Position = UDim2.new(0, 0, 0, 24),
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
			Size = UDim2.new(0, 11, 0, 11),
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
			if step >= 1 then
				val.Text = tostring(math.floor(v + 0.5))
			else
				val.Text = string.format("%.2f", v)
			end
			fill.BackgroundColor3 = T.accent
			cap.TextColor3 = T.dimc
			val.TextColor3 = T.text
			knob.BackgroundColor3 = T.text
		end

		local dragging = false
		local function commit(input)
			local ap = track.AbsolutePosition
			local asz = track.AbsoluteSize
			local a = clamp((input.Position.X - ap.X) / math.max(asz.X, 1), 0, 1)
			local v = minV + (maxV - minV) * a
			if step >= 1 then v = math.floor(v / step + 0.5) * step end
			set(clamp(v, minV, maxV))
			render()
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				commit(input)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				commit(input)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		table.insert(P.renders, render)
		render()
		return row
	end

	local function addSwitch(label, get, set)
		local row = nextRow(30)
		make("TextLabel", {
			Text = label,
			Size = UDim2.new(1, -50, 1, 0),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 11,
			TextColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local pill = make("Frame", {
			Size = UDim2.new(0, 36, 0, 20),
			Position = UDim2.new(1, -36, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = T.tint2,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Parent = row,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })
		make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.84, Thickness = 1, Parent = pill })
		local dotS = make("Frame", {
			Size = UDim2.new(0, 14, 0, 14),
			Position = UDim2.new(0, 3, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = T.dimc,
			BorderSizePixel = 0,
			Parent = pill,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dotS })

		local function render()
			local on = get()
			TweenService:Create(dotS, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, on and 19 or 3, 0.5, 0),
				BackgroundColor3 = on and T.accent or T.dimc,
			}):Play()
			TweenService:Create(pill, TweenInfo.new(0.18), {
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

	local function addCycler(label, getText, onNext)
		local row = nextRow(34)
		make("TextLabel", {
			Text = label,
			Size = UDim2.new(1, -140, 0, 14),
			Position = UDim2.new(0, 0, 0, 6),
			BackgroundTransparency = 1,
			Font = FONT_BODY,
			TextSize = 11,
			TextColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local btn = make("TextButton", {
			Text = "",
			Size = UDim2.new(0, 132, 0, 26),
			Position = UDim2.new(1, -132, 0, 0),
			BackgroundColor3 = T.tint2,
			BackgroundTransparency = 0.45,
			AutoButtonColor = false,
			Font = FONT_BODY,
			TextSize = 11,
			TextColor3 = T.text,
			Parent = row,
		})
		make("UICorner", { CornerRadius = UDim.new(0, 9), Parent = btn })
		make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.84, Thickness = 1, Parent = btn })
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

	local function addButtons(specs)
		local row = nextRow(34)
		local n = #specs
		for i, sp in ipairs(specs) do
			local b = make("TextButton", {
				Text = sp.text,
				Size = UDim2.new(1 / n, -((n - 1) * 8) / n, 0, 28),
				Position = UDim2.new((i - 1) / n, (i - 1) * 8, 0, 0),
				BackgroundColor3 = sp.accent and T.accent or T.tint2,
				BackgroundTransparency = sp.accent and 0.55 or 0.35,
				AutoButtonColor = false,
				Font = FONT_BODY,
				TextSize = 11,
				TextColor3 = T.text,
				Parent = row,
			})
			make("UICorner", { CornerRadius = UDim.new(0, 9), Parent = b })
			make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.84, Thickness = 1, Parent = b })
			b.MouseButton1Click:Connect(sp.cb)
			table.insert(P.hooks, function()
				b.TextColor3 = T.text
				b.BackgroundColor3 = sp.accent and T.accent or T.tint2
			end)
		end
		return row
	end

	local function addInput(placeholder, buttonText, onApply)
		local row = nextRow(34)
		local box = make("TextBox", {
			Text = "",
			PlaceholderText = placeholder,
			Size = UDim2.new(1, -66, 0, 28),
			BackgroundColor3 = T.tint2,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Font = FONT_BODY,
			TextSize = 11,
			TextColor3 = T.text,
			PlaceholderColor3 = T.dimc,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = row,
		})
		make("UICorner", { CornerRadius = UDim.new(0, 9), Parent = box })
		make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.84, Thickness = 1, Parent = box })
		make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6), Parent = box })
		local b = pillButton(row, buttonText, {
			Size = UDim2.new(0, 60, 0, 28),
			Position = UDim2.new(1, -60, 0, 0),
		}, function()
			onApply(box)
		end)
		table.insert(P.hooks, function()
			box.TextColor3 = T.text
			box.BackgroundColor3 = T.tint2
		end)
		return row, box, b
	end

	local function addSwatches()
		local row = nextRow(34)
		local palette = {
			Color3.fromRGB(0, 200, 0),
			Color3.fromRGB(10, 132, 255),
			Color3.fromRGB(191, 90, 242),
			Color3.fromRGB(255, 159, 10),
			Color3.fromRGB(255, 69, 58),
			Color3.fromRGB(235, 245, 240),
		}
		for i, c in ipairs(palette) do
			local sw = make("TextButton", {
				Text = "",
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(0, (i - 1) * 30, 0, 2),
				BackgroundColor3 = c,
				BackgroundTransparency = 0,
				AutoButtonColor = false,
				Parent = row,
			})
			make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sw })
			make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.7, Thickness = 1, Parent = sw })
			sw.MouseButton1Click:Connect(function()
				T.accent = c
				refresh()
			end)
		end
		return row
	end

	--──────────────── 光 · 玻璃 ────────────────
	addHeader("光 · 玻 璃")
	addSlider("雾化 BLUR", 0, 24, 1, function() return T.blur end, function(v)
		T.blur = v
		local b = ensureBlur()
		if b then b.Size = v end
		refresh()
	end)
	addSlider("压暗 SCRIM", 0, 0.7, 0.01, function() return T.dim end, function(v)
		T.dim = v
		applyLook()
	end)
	addSlider("玻璃 GLASS", 0.2, 0.95, 0.01, function() return T.glass end, function(v)
		T.glass = v
		refresh()
	end)
	addSlider("描边 BORDER（0 = 完全无缝）", 0, 1, 0.01, function() return T.border end, function(v)
		T.border = v
		refresh()
	end)
	addSlider("圆角 RADIUS", 0, 28, 1, function() return T.corner end, function(v)
		T.corner = v
		refresh()
	end)
	addSlider("尺幅 SCALE", 0.6, 1.6, 0.01, function() return T.scale end, function(v)
		T.scale = v
		refresh()
	end)
	addSwitch("无缝 SEAMLESS", function() return T.seamless end, function(v)
		T.seamless = v
		refresh()
	end)
	addSwitch("高光 CHROME", function() return T.chrome end, function(v)
		T.chrome = v
		refresh()
	end)
	addSwatches()
	addSlider("色调 HUE", 0, 1, 0.01, function()
		return hueOf(T.accent)
	end, function(v)
		local _, s, val = T.accent:ToHSV()
		T.accent = Color3.fromHSV(v, math.max(0.25, s), math.max(0.55, val))
		refresh()
	end)

	--──────────────── 境 · 壁纸 ────────────────
	addHeader("境 · 壁 纸")
	local _, urlBox = addInput("贴图直链 / rbxassetid 数字", "添 加", function(box)
		local ok, err = Wall.add(box.Text)
		if ok then
			box.Text = ""
			toast("壁纸已入卷")
			if P.save then pcall(P.save) end
		else
			toast(tostring(err))
		end
	end)

	local list = make("ScrollingFrame", {
		Name = "SG_WallList",
		Size = UDim2.new(1, 0, 0, 92),
		Position = UDim2.new(0, 0, 0, y),
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.70,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = T.accent,
		ScrollBarImageTransparency = 0.55,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = body,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = list })
	make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 5), Parent = list })
	y = y + 98

	local function rebuildList()
		for _, ch in ipairs(list:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local yy = 0
		if #Wall.items == 0 then
			make("TextLabel", {
				Text = "还没有壁纸 · 贴个链接上去吧",
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Font = FONT_BODY,
				TextSize = 10,
				TextColor3 = T.dimc,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = list,
			})
		end
		for i, it in ipairs(Wall.items) do
			local row = make("Frame", {
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.new(0, 0, 0, yy),
				BackgroundTransparency = 1,
				Parent = list,
			})
			make("TextLabel", {
				Text = tostring(i) .. " · " .. tostring(it.url or "?"):sub(1, 46),
				Size = UDim2.new(1, -26, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT_BODY,
				TextSize = 10,
				TextColor3 = T.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})
			local del = make("TextButton", {
				Text = "×",
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(1, -18, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = T.tint2,
				BackgroundTransparency = 0.4,
				AutoButtonColor = false,
				Font = FONT_BODY,
				TextSize = 12,
				TextColor3 = T.text,
				Parent = row,
			})
			make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = del })
			del.MouseButton1Click:Connect(function()
				Wall.remove(i)
				if P.save then pcall(P.save) end
			end)
			yy = yy + 22
		end
		list.CanvasSize = UDim2.new(0, 0, 0, math.max(yy, 20))
	end
	P.rebuildList = rebuildList
	rebuildList()
	table.insert(P.hooks, function()
		list.BackgroundColor3 = T.tint2
	end)

	local MODES = { "still", "pan", "cross", "sprite", "video", "aurora" }
	local MODE_NAME = {
		still = "静帧",
		pan = "缓推镜头",
		cross = "多图轮播",
		sprite = "整条帧带",
		video = "视频",
		aurora = "纯极光",
	}
	addCycler("动态方式 MOTION", function()
		return MODE_NAME[T.mode] or T.mode
	end, function()
		local i = 1
		for k, v in ipairs(MODES) do
			if v == T.mode then i = k break end
		end
		T.mode = MODES[i % #MODES + 1]
		playPlaylist()
	end)
	addSlider("停留 HOLD", 3, 30, 1, function() return T.hold end, function(v)
		T.hold = v
	end)
	addSlider("速度 SPEED", 0.2, 3, 0.01, function() return T.speed end, function(v)
		T.speed = v
	end)
	addSlider("帧数 FRAMES（帧带模式）", 2, 48, 1, function() return T.frames end, function(v)
		T.frames = v
	end)
	addSlider("壁纸 WALL", 0.2, 1, 0.01, function() return T.wallAlpha end, function(v)
		T.wallAlpha = v
		applyLook()
	end)
	addSwitch("极光 AURORA", function() return T.aurora end, function(v)
		T.aurora = v
		applyLook()
	end)
	addSwitch("光尘 DUST", function() return T.dust end, function(v)
		T.dust = v
		applyLook()
	end)
	addSwitch("仅菜单可见时生效", function() return T.followWindow end, function(v)
		T.followWindow = v
	end)
	addButtons({
		{ text = "重新播放", cb = function() playPlaylist() end },
		{ text = "清空壁纸", cb = function()
			Wall.clear()
			if P.save then pcall(P.save) end
			toast("壁纸已清空")
		end },
	})

	--──────────────── 影 · 光影与材质 ────────────────
	addHeader("影 · 光 影 与 材 质")
	addCycler("光影 LIGHTING", function()
		return LIGHT_NAME[Scene.lightsPreset] or Scene.lightsPreset
	end, function()
		local i = 1
		for k, v in ipairs(LIGHT_ORDER) do
			if v == Scene.lightsPreset then i = k break end
		end
		Scene.applyLights(LIGHT_ORDER[i % #LIGHT_ORDER + 1])
		if P.save then pcall(P.save) end
	end)
	addCycler("材质 MATERIAL", function()
		local def = MAT_PRESETS[Scene.matPreset]
		return def and def.name or "原始"
	end, function()
		local i = 1
		for k, v in ipairs(MAT_ORDER) do
			if v == Scene.matPreset then i = k break end
		end
		Scene.applyMats(MAT_ORDER[i % #MAT_ORDER + 1])
		if P.save then pcall(P.save) end
	end)
	addButtons({
		{ text = "应用材质", accent = true, cb = function()
			Scene.applyMats(Scene.matPreset)
		end },
		{ text = "还原材质", cb = function()
			Scene.restoreMats()
			Scene.matPreset = "off"
			toast("材质已还原")
		end },
	})
	addButtons({
		{ text = "还原光影", cb = function()
			Scene.applyLights("off")
			toast("光影已还原")
		end },
		{ text = "全部还原", cb = function()
			Scene.resetAll()
			toast("光影与材质都已还原")
		end },
	})
	addNote("材质与光影只在本地生效，别人看到的是原样。")

	--──────────────── 文 · 辞章 ────────────────
	addHeader("文 · 辞 章")
	addSwitch("文辞替换", function() return T.textStyle end, function(v)
		T.textStyle = v
		refresh()
	end)
	local _, dictBox = addInput("原文=译文, 另一条=词", "落 墨", function(box)
		parseCustom(box.Text)
		refresh()
		toast("词条已改")
	end)
	addNote("例：Enabled=开卷, Settings=笺注")
	addButtons({
		{ text = "重新换肤", cb = function()
			for _, c in ipairs(containers()) do
				for _, child in ipairs(c:GetChildren()) do
					if child:IsA("ScreenGui") and child.Name:sub(1, 3) ~= "SG_" and child.Name:sub(1, 3) ~= "LG_" then
						resetDone(child)
						dressTree(child)
					end
				end
			end
			toast("已重扫界面")
		end },
		{ text = "洗 砚", accent = true, cb = function()
			Scene.resetAll()
			Wall.clear()
			T.accent = CONFIG.theme.accent
			T.seamless = CONFIG.theme.seamless
			T.border = CONFIG.theme.border
			T.scale = 1
			refresh()
			toast("已回到初始")
		end },
	})

	body.Size = UDim2.new(1, 0, 0, y + 8)
	scroll.CanvasSize = UDim2.new(0, 0, 0, y + 16)

	-- 折叠
	local collapsed = false
	collapse.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		scroll.Visible = not collapsed
		collapse.Text = collapsed and "+" or "–"
		TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = collapsed and UDim2.new(0, 324, 0, 52) or UDim2.new(0, 324, 0, 500),
		}):Play()
	end)

	-- 拖动
	local dragging, dragStart, startPos = false, nil, nil
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = card.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - dragStart
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
	end)
end

--=====================================================================
-- 10 · 原脚本执行 + 界面接管
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
					if sub:IsA("ScreenGui") and not old[sub] then
						table.insert(out, sub)
					end
				end
			end
		end
	end
end

local function newScreenGuis(old)
	local out = {}
	for _, c in ipairs(containers()) do
		pcall(collect, c, out, old)
	end
	return out
end

local function runOriginal()
	local okHttp, src = pcall(function()
		return game:HttpGet(CONFIG.scriptUrl, true)
	end)
	if not okHttp or type(src) ~= "string" or #src < 100 then
		warn("[SG] 拉取原脚本失败: " .. tostring(src))
		return
	end
	local compile = loadstring or load
	if not compile then
		warn("[SG] 当前执行器没有 loadstring")
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
			toast("没抓到原界面：点「重新换肤」，或把 waitTimeout 调大")
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
	-- 磨砂 / 背景层跟菜单同步
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

	-- 阴影跟随窗口
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

	-- 极光缓慢旋转
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
-- 11 · 面板开合 / 状态存取
--=====================================================================
local function bindKey()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == CONFIG.panelKey then
			if P.gui and P.gui.Parent then
				P.gui.Enabled = not P.gui.Enabled
			end
		end
	end)
end

local function saveState()
	if type(writefile) ~= "function" then return end
	local items = {}
	for _, it in ipairs(Wall.items) do
		if type(it) == "table" then table.insert(items, it.url) end
	end
	local payload = {
		accent = { round(T.accent.R * 255), round(T.accent.G * 255), round(T.accent.B * 255) },
		glass = T.glass, border = T.border, corner = T.corner, scale = T.scale,
		seamless = T.seamless, chrome = T.chrome, textStyle = T.textStyle,
		mode = T.mode, hold = T.hold, speed = T.speed, dim = T.dim, wall = T.wallAlpha,
		aurora = T.aurora, dust = T.dust, blur = T.blur, followWindow = T.followWindow,
		lights = Scene.lightsPreset, material = Scene.matPreset,
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
	T.textStyle = bool(d.textStyle, T.textStyle)
	T.mode = type(d.mode) == "string" and d.mode or T.mode
	T.hold = num(d.hold, T.hold)
	T.speed = num(d.speed, T.speed)
	T.dim = num(d.dim, T.dim)
	T.wallAlpha = num(d.wall, T.wallAlpha)
	T.aurora = bool(d.aurora, T.aurora)
	T.dust = bool(d.dust, T.dust)
	T.blur = num(d.blur, T.blur)
	T.followWindow = bool(d.followWindow, T.followWindow)
	if type(d.lights) == "string" and LIGHT_PRESETS[d.lights] ~= nil or d.lights == "off" then
		Scene.lightsPreset = d.lights
	end
	if type(d.material) == "string" then Scene.matPreset = d.material end
	if type(d.items) == "table" then
		for _, u in ipairs(d.items) do
			if type(u) == "string" and u ~= "" then table.insert(Wall.items, u) end
		end
	end
end

--=====================================================================
-- 12 · 启动
--=====================================================================
local function boot()
	loadState()

	-- 追加 CONFIG 里预置的壁纸
	for _, it in ipairs(CONFIG.backdrop.items or {}) do
		if type(it) == "string" and it ~= "" then
			table.insert(Wall.items, it)
		elseif type(it) == "table" and type(it.url) == "string" and it.url ~= "" then
			table.insert(Wall.items, it.url)
		end
	end

	if CONFIG.scene.lights and CONFIG.scene.lights ~= "off" then
		Scene.lightsPreset = CONFIG.scene.lights
	end
	if CONFIG.scene.material and CONFIG.scene.material ~= "off" then
		Scene.matPreset = CONFIG.scene.material
	end

	Wall.refresh()
	ensureBlur()
	buildPanel()
	bindKey()

	if #Wall.items > 0 then
		schedule(function()
			pause(0.25)
			Wall.applyAll()
		end)
	end

	if Scene.lightsPreset and Scene.lightsPreset ~= "off" then
		pcall(Scene.applyLights, Scene.lightsPreset)
	end
	if Scene.matPreset and Scene.matPreset ~= "off" then
		pcall(Scene.applyMats, Scene.matPreset)
	end

	-- 先拍快照，再跑原脚本，避免原脚本先一步把界面建好而我们错过
	startWatch()

	if CONFIG.runOriginal then
		schedule(runOriginal)
	end

	startLive()

	toast("夜行 · 无痕 已就位 · F2 开合面板")
end

--=====================================================================
-- 13 · 对外接口 / 清理
--=====================================================================
local function destroy()
	pcall(function() if P.gui then P.gui:Destroy() end end)
	pcall(function() if Wall.gui then Wall.gui:Destroy() end end)
	pcall(function() if Toast.gui then Toast.gui:Destroy() end end)
	local blur = Lighting:FindFirstChild("SG_SceneBlur")
	if blur then pcall(function() blur:Destroy() end) end
	for _, layers in pairs(Reg.shadow) do
		for _, l in ipairs(layers) do
			pcall(function() if l.f then l.f:Destroy() end end)
		end
	end
	pcall(Scene.resetAll)
end

if getgenv and getgenv().SEAMLESS_DHC and getgenv().SEAMLESS_DHC.destroy then
	pcall(getgenv().SEAMLESS_DHC.destroy)
end

print("[SG] Doors HardCore · 无痕玻璃 v2 启动")

local okBoot, errBoot = pcall(boot)
if not okBoot then
	warn("[SG] 启动失败: " .. tostring(errBoot))
end

if getgenv then
	getgenv().SEAMLESS_DHC = {
		destroy = destroy,
		wall = Wall,
		scene = Scene,
		state = T,
		refresh = refresh,
		save = saveState,
		panel = P,
	}
end
