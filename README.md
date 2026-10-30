# Doors HardCore · 无痕玻璃 Seamless Glass（v6）

把 **Doors-HardCore**（源：`https://pastefy.app/Bf6hbDY4/raw`，备用 `Zero0Star/RipperNewSound` 的 raw）的界面，换成「无缝透明边框 + 壁纸 + 光影 + 中文 + 开场 BGM」的样子。

原脚本 **一行都没改**：它照常联网、照常跑 key 系统、照常工作；皮肤是它把界面建出来之后，在运行时逐层重绘上去的。

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/3091318935/Roblox/main/DoorsHardCore-Seamless.lua"))()
```

---

## v6 改了什么

| 需求 | 处理 |
| --- | --- |
| **字体太大、不好看** | 字族换成 Gotham / GothamSemibold（细一档），面板文字统一再缩 12%；「外观」页加 **面板字号** 0.8~1.3 与 **原界面字号** 0.75~1.2 两根滑杆 |
| **壁纸加载太突兀** | 装载时蒙版 0→透明淡入；每次换壁纸 / 重新播放都会重新淡入 |
| **壁纸盖住 UI、挡住调整** | 壁纸层始终在 `DisplayOrder = -10`（所有 UI 之下），并新增「柔化到背景」：浓度 ×0.6、压暗 +0.10、上下压边；面板底色不透明度提到 0.82，文字更清楚 |
| **关掉窗口后还在** | 菜单关闭 → 蒙版淡出后整层 `Enabled = false`；再打开 → 淡入。时长可调 0.2~2s |

---

## v5 修了什么

| 问题 | 原因 / 处理 |
| --- | --- |
| **拖一根滑块，整排滑块一起动** | 之前所有滑块共用一个全局 `sliderBusy` 标志，任意一根在拖时，其余滑块的 `InputChanged` 也会执行 `commit`。现在每根滑块各自持有 `active`，互不影响 |
| **面板拖动被删掉了** | 恢复：整块面板可拖（标题栏 + 空白处），但改成**矩形命中测试** —— 指针落在滑块 / 按钮 / 输入框 / 列表上就不拖，不再依赖事件顺序 |
| **上传页在哪** | 壁纸页、音乐页各加两个按钮：「上传页」「教程」，能开浏览器就直接开，不能就复制链接到剪贴板 |
| **第三方 mp3 / mp4 想直接用** | 本地工具 `tools/video2strip.py`（mp4/gif → 序列帧长图）与 `tools/audio_check.py`（体检 / 裁到 50 秒）；生成的图还能直接被面板当本地文件读 |

---

## v5.1 小改

- 原脚本地址换成 `https://pastefy.app/Bf6hbDY4/raw`（内容与原 GitHub 版一致）；
- 加了 `fallbackUrl`：pastefy 挂了或被限流，会自动回落 GitHub raw，控制台会打印实际使用的来源；
- 两个源都拉不到时只弹提示，皮肤照常能用。

| 文件 | 说明 |
| --- | --- |
| `DoorsHardCore-Seamless.lua` | v6 引擎主体，单文件、无依赖 |
| `DoorsHardCore-LiquidGlass.lua` | v1 液态玻璃版，备份 |
| `loader.lua` | 一行启动器 |
| `tools/video2strip.py` | 本地 mp4 / gif → 序列帧长图（免上传用动画壁纸） |
| `tools/audio_check.py` | 本地 mp3 体检 / 裁到 50 秒 |
| `tools/README.md` | 上面两个脚本的用法、ffmpeg 安装 |
| `github/` | 发布工具：`push.ps1` / `push.sh` / `PUBLISH.md` |

---

## 用法

1. 整段粘进执行器回车；或 `loadstring` 远程载入。
2. 右下角出现「无痕 · 外观」面板，`F2` 开合。
3. **拖面板**：按标题栏或任意空白处；按在滑块/按钮/输入框/列表上时不会带动面板。

---

## 面板五页

### 外观

模糊 / 压暗 / 玻璃 / 描边 / 圆角 / 缩放 / **面板字号 0.8~1.3** / **原界面字号 0.75~1.2**；开关：无缝边框、顶部高光、窗口拖动把手；6 色板 + 色调滑杆。

字号这两根是分开的：一根管我们这块调参面板，一根管被换肤的原菜单文字，避免“面板好看了但原菜单还是很大”。

### 壁纸

贴链接 → 自动识别 → 进列表（`×` 删除，存 `SG_Config.json`）。

| 贴的东西 | 识别为 | 播放 |
| --- | --- | --- |
| `rbxassetid://数字` / 纯数字 | 图片 | 缓慢放大 / 轮播 / 静帧 |
| `.png .jpg .webp` 直链 | 图片（缓存到 `SG_Assets/`） | 同上 |
| 长条拼图（宽÷高 = 整数且 ≥3） | 序列帧 | 自动切帧循环 |
| 本地文件名，如 `clip_strip.png` | 本地图片（走 `getcustomasset`） | 同上 |
| 视频 id / `roblox.com/videos/…` | 视频 | `VideoFrame` 循环 + 续播 |

播放控制：播放方式 / 停留 / 速度 / **壁纸浓度** / **柔化到背景** / **淡入淡出 0.2~2s** / 极光 / 光尘 / 仅菜单显示时出现。

- **柔化到背景**：浓度自动 ×0.6、压暗 +0.10、上下压边，壁纸只当背景光，不抢 UI；
- 壁纸层固定 `DisplayOrder = -10`，永远在菜单和我们这块面板下面，且不注册任何输入；
- 菜单关闭 → 淡出后整层隐藏；再打开 → 淡入。

页底两个按钮：**视频上传页** / **上传教程**（`openbrowser` → `openurl` → 复制链接，逐级降级）。

**视频的现实**：Roblox 只认平台「视频」资产。做法是 Creator Dashboard → Development Items → Videos 传 mp4（有大小/时长限制、要审核）→ 拿 id 贴进来。贴错类型（图片/音频 id）脚本会用 `GetProductInfo` 探测出来并按正确类型处理。

### 光影

`bsl` / `complementary` / `seus` / `sildur` / `kuda` / `vanilla` / `night` / `cinema` / `moon` / `neon` / `gloom`（也认中文「冷月/霓虹/夜色/幽影/电影」）→ 内置风格；`.json` 链接 → 光影包；图片链接 → 滤色片。带 0~1.6 强度与「还原光影」。

### 音乐

音频 id、音量、最长播放（默认 45s）、循环、点任意模式后播放、传送后自动停、试听/停止；页底 **音频上传页** / **音频文档** 按钮。

停止条件先到先停：超时 / 传送（≈进第 0 门）/ 手动。

### 翻译

中文替换开关 + 自定义词条（`原文=中文, Settings=设置`），不会覆盖原脚本后续改动的数值/键位/状态。

---

## 第三方 mp3 / mp4 怎么变成 Roblox 能用的

```powershell
# 一次性依赖
winget install Gyan.FFmpeg
python -c "import PIL; print(PIL.__version__)"

# 视频 → 序列帧长图（不上传也能当动画壁纸）
python tools\video2strip.py clip.mp4 --frames 12 --height 240
# → clip_strip.png，丢进执行器 workspace，壁纸页贴 clip_strip.png

# 音频体检 / 裁到 50 秒内
python tools\audio_check.py song.mp3 --trim 45
# → song_trim.mp3，去 Creator → Audio 上传，拿 id 贴音乐页
```

为什么不直接「一键上传」：上传走的是 Creator Dashboard 的网页登录态接口（需要你的 Roblox cookie + CSRF），执行器跑在客户端里，没有也不该拿这些凭证。所以自动化只做到文件侧——转换、体检、裁剪、生成可直接用的图或 id，点「上传」那一下走官方页面。

---

## CONFIG 速查

```lua
local CONFIG = {
    scriptUrl   = "https://pastefy.app/Bf6hbDY4/raw",
    fallbackUrl = "https://raw.githubusercontent.com/Zero0Star/RipperNewSound/master/Doors-HardCore.lua",
    runOriginal = true,
    waitTimeout = 30, watchSeconds = 120,
    panelKey    = Enum.KeyCode.F2,
    theme = { accent = Color3.fromRGB(0,200,0), glass = 0.82, border = 0.30,
              corner = 14, scale = 1, seamless = true, chrome = true,
              translate = true, grip = true, uiFont = 1.0, textScale = 1.0 },
    backdrop = { items = {}, mode = "auto", hold = 8, speed = 1, dim = 0.22,
                 wall = 0.80, soft = true, fade = 0.85,
                 aurora = true, dust = false, blur = 8, followWindow = true },
    shade = { preset = "vanilla", power = 1 },
}
```

面板改动存 `SG_Config.json`（含音乐 id / 音量 / 开关），壁纸缓存 `SG_Assets/`。

---

## 常见问题

**滑块还是一起动？** 确认拉的是 v5（控制台会打印 `无痕玻璃 v5 启动`），旧版缓存脚本要重新 `HttpGet` 一次。

**拖面板没反应？** 按在控件上了；换标题栏或行与行之间的空白。

**视频/音频不出？** 必须是平台资产：视频 → Development Items → Videos，音频 → Audio，都要审核通过；`GetProductInfo` 探测出来类型不对会直接提示。

**BGM 一进游戏就停？** 出生点算了一次传送，把「传送后自动停」关掉，用「最长播放」控制。

**菜单没变化？** 「翻译」页点「重新扫描界面」，或调大 `waitTimeout`。

---

## 边界

- Roblox 没有 `backdrop-filter`，模糊的是 3D 场景；玻璃感来自场景模糊 + 半透明面板 + 高光。
- MC 的 GLSL 光影包无法在 Roblox 运行，这里是观感映射。
- 视频 / 音频必须是平台资产；直链只能缓存，不能直接播。
- 中文走 CJK 回退字体，小字号会略糊。
- hover 颜色可能短暂回弹（原脚本用 Tween 改色）。

---

## 发布 / 更新

```powershell
$env:GITHUB_TOKEN = "ghp_xxx"     # 已有 gh 登录可省略
powershell -ExecutionPolicy Bypass -File .\github\push.ps1
```

改完重跑一次就是更新（按 `sha` 覆盖，含 `tools/`）。细节见 [github/PUBLISH.md](github/PUBLISH.md)。
