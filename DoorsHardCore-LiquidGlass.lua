--=====================================================================
--  Doors HardCore  ·  Liquid Glass Edition
--  为原脚本外挂一层「液态玻璃」换肤引擎（不改原脚本、不重打包）
-----------------------------------------------------------------------
--  原脚本： https://pastefy.app/Bf6hbDY4/raw
--  风格参考：DSH 壁纸引擎（玻璃面 / 发丝渐变描边 / 顶部高光 / 壁纸 / 场景模糊 / #00C800）
--
--  用法：整段粘进执行器回车；或自己传到 gist 后 loadstring 远程载入。
--  运行后：原脚本照常执行 → 它创建的界面被就地重绘成玻璃风 → 右下角出现调参玻璃卡。
--
--  改默认值：直接改下面的 CONFIG。
--=====================================================================

local CONFIG = {
	scriptUrl   = "https://pastefy.app/Bf6hbDY4/raw",
	runOriginal = true,     -- 是否执行原脚本（只想看换肤效果时设 false）
	waitTimeout = 30,       -- 等待原脚本创建界面的最长秒数
	watchSeconds = 60,      -- 之后继续监听新界面元素的秒数

	theme = {
		accent = Color3.fromRGB(0, 200, 0),   -- DSH 默认绿
		glass  = 0.64,                        -- 玻璃不透明度 0~1
		border = 0.46,                        -- 描边强度 0~1
		corner = 18,                          -- 圆角 px
	},
	backdrop = {
		wallpaper    = "",     -- 留空 = 只用场景模糊；可填数字 id、rbxassetid 或图片直链
		dim          = 0.18,   -- 压暗 0~1
		blur         = 12,     -- 场景磨砂 0~24
		followWindow = true,   -- 只在菜单可见时才开磨砂
	},
}

--=====================================================================
--  0. 环境与工具
--=====================================================================
local Players     = game:GetService("Players")
local Lighting    = game:GetService("Lighting")
local TweenService= game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local function schedule(fn, ...)
	if task and task.spawn then return task.spawn(fn, ...) end
	return coroutine.wrap(fn)(...)
end

local function pause(s)
	if task and task.wait then return task.wait(s) end
	return wait(s)
end

local function fontOf(name, fallback)
	local ok, f = pcall(function() return Enum.Font[name] end)
	if ok and f then return f end
	return fallback
end
local FONT_BODY  = fontOf("GothamMedium", Enum.Font.SourceSansSemibold)
local FONT_TITLE = fontOf("GothamBold", Enum.Font.SourceSansBold)

local function make(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
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

--=====================================================================
--  1. 主题状态
--=====================================================================
local T = {
	accent = CONFIG.theme.accent,
	glass  = CONFIG.theme.glass,
	border = CONFIG.theme.border,
	corner = CONFIG.theme.corner,

	blur         = CONFIG.backdrop.blur,
	dim          = CONFIG.backdrop.dim,
	followWindow = CONFIG.backdrop.followWindow,

	tint  = Color3.fromRGB(9, 20, 16),      -- 主玻璃底：极深的墨绿黑
	tint2 = Color3.fromRGB(22, 36, 30),     -- 次级面（控件）
	text  = Color3.fromRGB(238, 250, 243),
	dimc  = Color3.fromRGB(150, 172, 160),
}

local Reg = {
	done    = setmetatable({}, { __mode = "k" }),
	style   = setmetatable({}, { __mode = "k" }),
	text    = setmetatable({}, { __mode = "k" }),
	origTxt = setmetatable({}, { __mode = "k" }),
	origBG  = setmetatable({}, { __mode = "k" }),
	origBT  = setmetatable({}, { __mode = "k" }),
	corner  = setmetatable({}, { __mode = "k" }),
	stroke  = setmetatable({}, { __mode = "k" }),
	windows = setmetatable({}, { __mode = "k" }),
	guis    = setmetatable({}, { __mode = "k" }),
	shadow  = {},
}

local Panel = { gui = nil, card = nil, body = nil, sliders = {}, hooks = {} }
local themeHooks = Panel.hooks

local containers -- 前置声明：换肤引擎与面板都要用

local function accentHue()
	local h = T.accent:ToHSV()
	return h
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

--=====================================================================
--  2. 样式原语
--=====================================================================
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

local function styleFor(kind)
	if kind == "window" then
		return T.tint, math.min(0.96, T.glass), T.corner, 1 - 0.46 * T.border
	elseif kind == "panel" then
		return Color3.new(1, 1, 1), 0.045, math.max(8, T.corner * 0.78), 1 - 0.30 * T.border
	elseif kind == "control" then
		return Color3.new(1, 1, 1), 0.075, math.max(6, math.min(12, T.corner * 0.66)), 1 - 0.26 * T.border
	elseif kind == "line" then
		return Color3.new(1, 1, 1), 0.10, 0, 1
	end
	return nil, 1, 0, 1
end

local function applyStyle(o, kind)
	if kind == "chip" then
		-- 彩色控件（开关 / 激活态标签）：保留语义色，只统一到强调色相
		o.BackgroundColor3 = harmonize(Reg.origBG[o] or o.BackgroundColor3)
		if o:IsA("GuiButton") then
			o.BackgroundTransparency = math.min(0.85, 0.48 + (Reg.origBT[o] or 0) * 0.4)
		else
			o.BackgroundTransparency = math.min(0.85, (Reg.origBT[o] or 0) * 0.5)
		end
		o.BorderSizePixel = 0
		ensureCorner(o).CornerRadius = UDim.new(0, math.max(6, math.floor(T.corner * 0.5)))
		ensureStroke(o).Transparency = math.max(0, 1 - 0.35 * T.border)
		return
	end
	if kind == "raw" then
		-- 小圆点 / 滑块轨：只圆角，不动颜色
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
	if strokeT and strokeT < 1 then
		ensureStroke(o).Transparency = math.clamp(strokeT, 0, 1)
	end
end

local function applyText(o)
	local base = Reg.origTxt[o] or T.text
	o.TextColor3 = readable(base)
	o.TextStrokeTransparency = 1
	if o:IsA("TextLabel") or o:IsA("TextButton") then
		if (o.TextSize or 14) >= 18 then
			o.Font = FONT_TITLE
		else
			o.Font = FONT_BODY
		end
	end
end

--=====================================================================
--  3. 背景层（壁纸 + 压暗 + 磨砂）
--=====================================================================
local Backdrop = { gui = nil, image = nil, dim = nil, vig = nil, blur = nil }

local function guiParentCandidates()
	local list = {}
	if gethui then table.insert(list, function() return gethui() end) end
	table.insert(list, function() return game:GetService("CoreGui") end)
	table.insert(list, function() return LocalPlayer:WaitForChild("PlayerGui", 8) end)
	return list
end

local function attachGui(gui)
	for _, f in ipairs(guiParentCandidates()) do
		local ok = pcall(function()
			gui.Parent = f()
		end)
		if ok and gui.Parent then return gui.Parent end
	end
	return nil
end

local function ensureBackdrop()
	if Backdrop.gui and Backdrop.gui.Parent then return Backdrop.gui end

	local gui = Instance.new("ScreenGui")
	gui.Name = "LG_Backdrop"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -10
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	attachGui(gui)
	Backdrop.gui = gui

	Backdrop.image = make("ImageLabel", {
		Name = "LG_Wallpaper",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		Parent = gui,
	})

	local vig = make("Frame", {
		Name = "LG_Vignette",
		Size = UDim2.new(1, 0, 0.5, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Parent = gui,
	})
	make("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.15),
		}),
		Parent = vig,
	})
	Backdrop.vig = vig

	Backdrop.dim = make("Frame", {
		Name = "LG_Dim",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1 - T.dim,
		BorderSizePixel = 0,
		Parent = gui,
	})

	return gui
end

local function ensureBlur()
	if Backdrop.blur and Backdrop.blur.Parent then return Backdrop.blur end
	local b = Instance.new("BlurEffect")
	b.Name = "LG_SceneBlur"
	b.Size = T.blur
	b.Enabled = false
	b.Parent = Lighting
	Backdrop.blur = b
	return b
end

local function applyWallpaper(url)
	url = tostring(url or ""):gsub("%s+", "")
	local img = Backdrop.image
	if not img then return end
	if url == "" then
		img.Image = ""
		img.ImageTransparency = 1
		return
	end

	local imageId = url
	if url:match("^%d+$") then
		imageId = "rbxassetid://" .. url
	elseif url:match("^https?://") then
		local ok, res = pcall(function()
			if not (writefile and getcustomasset) then error("no file api") end
			local name = "lg_wallpaper_" .. tostring(math.random(100000, 999999)) .. ".png"
			writefile(name, game:HttpGet(url, true))
			return getcustomasset(name)
		end)
		if ok and res then
			imageId = res
		else
			imageId = ""
		end
	end

	if imageId == "" then return end
	img.Image = imageId
	img.ImageTransparency = 0.06
end

--=====================================================================
--  4. 换肤引擎
--=====================================================================
local function isTopWindow(g)
	local p = g.Parent
	if not p then return false end
	if not (p:IsA("ScreenGui") or p:IsA("Folder") or p:IsA("PlayerGui") or p:IsA("CoreGui")) then
		return false
	end
	local vp = viewport()
	local s = g.AbsoluteSize
	return s.X >= math.max(280, vp.X * 0.16) and s.Y >= math.max(150, vp.Y * 0.13)
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
		s.Name = "LG_Shadow"
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
	if win:FindFirstChild("LG_Highlight") then return end

	local hl = Instance.new("Frame")
	hl.Name = "LG_Highlight"
	hl.Size = UDim2.new(1, -32, 0, 1)
	hl.Position = UDim2.new(0, 16, 0, 1)
	hl.BackgroundColor3 = Color3.new(1, 1, 1)
	hl.BackgroundTransparency = 0.70
	hl.BorderSizePixel = 0
	hl.ZIndex = win.ZIndex + 3
	hl.Parent = win
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.05),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = hl,
	})

	-- 顶部到底部的柔和光泽，玻璃感的来源
	local sheen = Instance.new("Frame")
	sheen.Name = "LG_Sheen"
	sheen.Size = UDim2.new(1, 0, 1, 0)
	sheen.BackgroundColor3 = Color3.new(1, 1, 1)
	sheen.BackgroundTransparency = 0
	sheen.BorderSizePixel = 0
	sheen.ZIndex = 0
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
	if g.Name and g.Name:sub(1, 3) == "LG_" then return end

	if not Reg.done[g] then
		Reg.done[g] = true
		local cls = g.ClassName
		if g:IsA("GuiObject") then
			Reg.origBG[g] = g.BackgroundColor3
			Reg.origBT[g] = g.BackgroundTransparency
		end

		if g:IsA("GuiObject") then
			g.BorderSizePixel = 0
		end

		if g:IsA("TextLabel") or g:IsA("TextButton") or g:IsA("TextBox") then
			Reg.origTxt[g] = g.TextColor3
			Reg.text[g] = true
			applyText(g)
		end

		if cls == "ScrollingFrame" then
			g.BackgroundTransparency = 1
			g.BorderSizePixel = 0
			g.ScrollBarThickness = math.max(2, math.floor((g.ScrollBarThickness or 12) * 0.35))
			g.ScrollBarImageColor3 = Color3.new(1, 1, 1)
			g.ScrollBarImageTransparency = 0.55
		elseif cls == "TextButton" or cls == "ImageButton" then
			local kind = "control"
			if sat(Reg.origBG[g] or Color3.new(0, 0, 0)) > 0.22 then
				kind = "chip" -- 原本就是彩色的按钮（多为激活态）保留强调色
			end
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
	if not ok then
		warn("[LG] 换肤跳过一处节点: " .. tostring(err))
	end
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
		if o.Parent then applyStyle(o, kind) end
	end
	for o in pairs(Reg.text) do
		if o.Parent then applyText(o) end
	end
	if Backdrop.dim then Backdrop.dim.BackgroundTransparency = 1 - T.dim end
	if Backdrop.blur then Backdrop.blur.Size = T.blur end
	for _, fn in ipairs(themeHooks) do
		pcall(fn)
	end
	for _, fn in ipairs(Panel.sliders) do
		pcall(fn)
	end
end

local refreshQueued = false
local function refresh()
	if refreshQueued then return end
	refreshQueued = true
	schedule(function()
		pause(0.04)
		refreshQueued = false
		local ok, err = pcall(refreshNow)
		if not ok then warn("[LG] 刷新失败: " .. tostring(err)) end
	end)
end

--=====================================================================
--  5. 调参面板
--=====================================================================
local function bindSlider(parent, label, minV, maxV, step, get, set, y)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0, y),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	make("TextLabel", {
		Text = label,
		Size = UDim2.new(1, -64, 0, 14),
		BackgroundTransparency = 1,
		Font = FONT_BODY,
		TextSize = 12,
		TextColor3 = T.dimc,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local val = make("TextLabel", {
		Text = "",
		Size = UDim2.new(0, 64, 0, 14),
		Position = UDim2.new(1, -64, 0, 0),
		BackgroundTransparency = 1,
		Font = FONT_BODY,
		TextSize = 12,
		TextColor3 = T.text,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	local track = make("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 0, 23),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.84,
		Parent = row,
	})
	make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local fill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = T.accent,
		BackgroundTransparency = 0.05,
		Parent = track,
	})
	make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local knob = make("Frame", {
		Size = UDim2.new(0, 11, 0, 11),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = T.text,
		Parent = track,
	})
	make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local function render()
		local v = get()
		local a = math.clamp((v - minV) / (maxV - minV), 0, 1)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		if step >= 1 then
			val.Text = tostring(math.floor(v + 0.5))
		else
			val.Text = string.format("%.2f", v)
		end
		fill.BackgroundColor3 = T.accent
	end

	local dragging = false
	local function commit(input)
		local ap = track.AbsolutePosition
		local asz = track.AbsoluteSize
		local a = math.clamp((input.Position.X - ap.X) / math.max(asz.X, 1), 0, 1)
		local v = minV + (maxV - minV) * a
		if step >= 1 then v = math.floor(v / step + 0.5) * step end
		set(math.clamp(v, minV, maxV))
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
	UserInputService.InputEnded:Connect(function()
		dragging = false
	end)

	table.insert(Panel.sliders, render)
	render()
	return row
end

local function makeSwitch(parent, label, get, set, y)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, y),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	make("TextLabel", {
		Text = label,
		Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT_BODY,
		TextSize = 12,
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
		Parent = row,
	})
	make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pill })
	make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.82, Thickness = 1, Parent = pill })
	local dot = make("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = T.dimc,
		Parent = pill,
	})
	make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

	local function render()
		local on = get()
		TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
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
		Parent = row,
	}).MouseButton1Click:Connect(function()
		set(not get())
		render()
	end)

	table.insert(Panel.sliders, render)
	render()
	return row
end

local function pillButton(parent, text, x, w, y, onClick)
	local b = make("TextButton", {
		Text = text,
		Size = UDim2.new(0, w, 0, 30),
		Position = UDim2.new(0, x, 0, y),
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.35,
		Font = FONT_BODY,
		TextSize = 12,
		TextColor3 = T.text,
		Parent = parent,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = b })
	make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.80, Thickness = 1, Parent = b })
	b.MouseButton1Click:Connect(onClick)
	return b
end

local function buildPanel()
	if Panel.gui and Panel.gui.Parent then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "LG_Panel"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	attachGui(gui)
	Panel.gui = gui

	local card = make("Frame", {
		Name = "LG_Card",
		Size = UDim2.new(0, 292, 0, 432),
		Position = UDim2.new(1, -22, 1, -22),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = T.tint,
		BackgroundTransparency = 1 - T.glass,
		BorderSizePixel = 0,
		Parent = gui,
	})
	Panel.card = card
	make("UICorner", { CornerRadius = UDim.new(0, T.corner), Parent = card })
	local stroke = make("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Transparency = 0.72,
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
		Parent = stroke,
	})

	local hl = make("Frame", {
		Size = UDim2.new(1, -32, 0, 1),
		Position = UDim2.new(0, 16, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.62,
		BorderSizePixel = 0,
		Parent = card,
	})
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = hl,
	})

	local header = make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = card,
	})
	local dot = make("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		Position = UDim2.new(0, 18, 0, 21),
		BackgroundColor3 = T.accent,
		Parent = header,
	})
	make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
	make("TextLabel", {
		Text = "LIQUID GLASS",
		Size = UDim2.new(1, -60, 0, 14),
		Position = UDim2.new(0, 34, 0, 14),
		BackgroundTransparency = 1,
		Font = FONT_TITLE,
		TextSize = 12,
		TextColor3 = T.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})
	make("TextLabel", {
		Text = "DSH WALLPAPER · DOORS",
		Size = UDim2.new(1, -60, 0, 12),
		Position = UDim2.new(0, 34, 0, 28),
		BackgroundTransparency = 1,
		Font = FONT_BODY,
		TextSize = 10,
		TextColor3 = T.dimc,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local collapse = make("TextButton", {
		Text = "-",
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -38, 0, 10),
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.55,
		Font = FONT_BODY,
		TextSize = 14,
		TextColor3 = T.text,
		Parent = header,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = collapse })

	local body = make("Frame", {
		Name = "Body",
		Size = UDim2.new(1, -32, 1, -62),
		Position = UDim2.new(0, 16, 0, 52),
		BackgroundTransparency = 1,
		Parent = card,
	})
	Panel.body = body

	local y = 0
	bindSlider(body, "磨砂 BLUR", 0, 24, 1, function() return T.blur end, function(v)
		T.blur = v
		ensureBlur()
		refresh()
	end, y) y = y + 38

	bindSlider(body, "压暗 SCRIM", 0, 0.7, 0.01, function() return T.dim end, function(v)
		T.dim = v
		refresh()
	end, y) y = y + 38

	bindSlider(body, "玻璃 GLASS", 0.2, 0.95, 0.01, function() return T.glass end, function(v)
		T.glass = v
		refresh()
	end, y) y = y + 38

	bindSlider(body, "描边 BORDER", 0.1, 1, 0.01, function() return T.border end, function(v)
		T.border = v
		refresh()
	end, y) y = y + 38

	bindSlider(body, "圆角 RADIUS", 6, 28, 1, function() return T.corner end, function(v)
		T.corner = v
		refresh()
	end, y) y = y + 42

	make("TextLabel", {
		Text = "强调色 ACCENT",
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, y),
		BackgroundTransparency = 1,
		Font = FONT_BODY,
		TextSize = 12,
		TextColor3 = T.dimc,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = body,
	})
	y = y + 20

	local colors = {
		Color3.fromRGB(0, 200, 0),
		Color3.fromRGB(10, 132, 255),
		Color3.fromRGB(191, 90, 242),
		Color3.fromRGB(255, 159, 10),
		Color3.fromRGB(255, 69, 58),
		Color3.fromRGB(235, 245, 240),
	}
	for i, c in ipairs(colors) do
		local sw = make("TextButton", {
			Text = "",
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, (i - 1) * 30, 0, y),
			BackgroundColor3 = c,
			BackgroundTransparency = 0,
			Parent = body,
		})
		make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sw })
		make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.7, Thickness = 1, Parent = sw })
		sw.MouseButton1Click:Connect(function()
			T.accent = c
			refresh()
		end)
	end
	y = y + 34

	make("TextLabel", {
		Text = "壁纸 WALLPAPER（留空 = 只用模糊）",
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 0, y),
		BackgroundTransparency = 1,
		Font = FONT_BODY,
		TextSize = 10,
		TextColor3 = T.dimc,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = body,
	})
	y = y + 14

	local field = make("TextBox", {
		Text = CONFIG.backdrop.wallpaper or "",
		PlaceholderText = "rbxassetid / https://...",
		Size = UDim2.new(1, -46, 0, 28),
		Position = UDim2.new(0, 0, 0, y),
		BackgroundColor3 = T.tint2,
		BackgroundTransparency = 0.45,
		Font = FONT_BODY,
		TextSize = 11,
		TextColor3 = T.text,
		PlaceholderColor3 = T.dimc,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = body,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = field })
	make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.82, Thickness = 1, Parent = field })
	make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6), Parent = field })

	local apply = make("TextButton", {
		Text = "应用",
		Size = UDim2.new(0, 40, 0, 28),
		Position = UDim2.new(1, -40, 0, y),
		BackgroundColor3 = T.accent,
		BackgroundTransparency = 0.60,
		Font = FONT_BODY,
		TextSize = 11,
		TextColor3 = T.text,
		Parent = body,
	})
	make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = apply })
	apply.MouseButton1Click:Connect(function()
		ensureBackdrop()
		applyWallpaper(field.Text)
	end)
	y = y + 34

	makeSwitch(body, "仅菜单可见时磨砂", function()
		return T.followWindow
	end, function(v)
		T.followWindow = v
	end, y)
	y = y + 34

	pillButton(body, "重新换肤", 0, 126, y, function()
		for _, g in ipairs(containers()) do
			for _, child in ipairs(g:GetChildren()) do
				if child:IsA("ScreenGui") and child.Name:sub(1, 3) ~= "LG_" then
					resetDone(child)
					dressTree(child)
				end
			end
		end
	end)

	pillButton(body, "收起面板", 134, 126, y, function()
		card.Visible = false
		local restore = make("TextButton", {
			Name = "LG_Restore",
			Text = "LG",
			Size = UDim2.new(0, 44, 0, 30),
			Position = UDim2.new(1, -22, 1, -22),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundColor3 = T.tint,
			BackgroundTransparency = 1 - math.min(0.9, T.glass),
			Font = FONT_TITLE,
			TextSize = 11,
			TextColor3 = T.text,
			Parent = gui,
		})
		make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = restore })
		make("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.7, Thickness = 1, Parent = restore })
		restore.MouseButton1Click:Connect(function()
			card.Visible = true
			restore:Destroy()
		end)
	end)

	local collapsed = false
	collapse.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		if collapsed then
			body.Visible = false
			collapse.Text = "+"
			TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 292, 0, 48),
			}):Play()
		else
			body.Visible = true
			collapse.Text = "-"
			TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 292, 0, 432),
			}):Play()
		end
	end)

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

	table.insert(themeHooks, function()
		card.BackgroundColor3 = T.tint
		card.BackgroundTransparency = 1 - T.glass
		dot.BackgroundColor3 = T.accent
	end)
end

--=====================================================================
--  6. 原脚本执行 + 界面监听
--=====================================================================
containers = function()
	local list = {}
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
		warn("[LG] 拉取原脚本失败: " .. tostring(src))
		return
	end
	local compile = loadstring or load
	if not compile then
		warn("[LG] 当前执行器没有 loadstring")
		return
	end
	local fn, err = compile(src)
	if not fn then
		warn("[LG] 编译失败: " .. tostring(err))
		return
	end
	local ok, e = pcall(fn)
	if not ok then
		warn("[LG] 原脚本报错（换肤不受影响）: " .. tostring(e))
	end
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

local function start()
	ensureBackdrop()
	ensureBlur()
	if CONFIG.backdrop.wallpaper and CONFIG.backdrop.wallpaper ~= "" then
		pcall(applyWallpaper, CONFIG.backdrop.wallpaper)
	end
	buildPanel()

	local before = snapshot()
	local watched = {}

	local function adopt(gui)
		if watched[gui] then return end
		watched[gui] = true
		if gui.Name and gui.Name:sub(1, 3) == "LG_" then return end
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

	if CONFIG.runOriginal then
		schedule(runOriginal)
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
		local endTime = tick() + CONFIG.watchSeconds
		while tick() < endTime do
			for _, g in ipairs(newScreenGuis(before)) do
				before[g] = true
				schedule(adopt, g)
			end
			pause(0.6)
		end
	end)

	schedule(function()
		while true do
			pause(0.25)
			local blur = Backdrop.blur
			if not blur or not blur.Parent then blur = ensureBlur() end
			local anyVisible = false
			for win in pairs(Reg.windows) do
				if effectivelyVisible(win) then
					anyVisible = true
					break
				end
			end
			if next(Reg.windows) == nil then
				for gui in pairs(Reg.guis) do
					if effectivelyVisible(gui) then
						anyVisible = true
						break
					end
				end
			end
			if T.followWindow then
				blur.Enabled = anyVisible and T.blur > 0
			else
				blur.Enabled = T.blur > 0
			end
			-- 壁纸 / 压暗层跟着菜单一起显示，避免菜单关掉后画面还是暗的
			if Backdrop.gui and Backdrop.gui.Parent then
				if T.followWindow and next(Reg.windows) ~= nil then
					pcall(function() Backdrop.gui.Enabled = anyVisible end)
				elseif not Backdrop.gui.Enabled then
					pcall(function() Backdrop.gui.Enabled = true end)
				end
			end
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
							f.Visible = win.Visible
						end
					end
				end
			end
		end
	end)
end

if getgenv and getgenv().LIQUID_GLASS_DHC and getgenv().LIQUID_GLASS_DHC.Destroy then
	pcall(function() getgenv().LIQUID_GLASS_DHC:Destroy() end)
end

print("[LG] Doors HardCore · Liquid Glass Edition 启动")

local okStart, errStart = pcall(start)
if not okStart then
	warn("[LG] 启动失败: " .. tostring(errStart))
end

if getgenv then
	getgenv().LIQUID_GLASS_DHC = {
		Destroy = function()
			pcall(function() if Panel.gui then Panel.gui:Destroy() end end)
			pcall(function() if Backdrop.gui then Backdrop.gui:Destroy() end end)
			pcall(function() if Backdrop.blur then Backdrop.blur:Destroy() end end)
			for _, layers in pairs(Reg.shadow) do
				for _, l in ipairs(layers) do
					pcall(function() if l.f then l.f:Destroy() end end)
				end
			end
		end,
	}
end
