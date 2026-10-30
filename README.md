# Doors HardCore · 无痕玻璃 Seamless Glass（v3）

把 `Zero0Star/RipperNewSound` 里 **Doors-HardCore.lua** 的界面，换成「无缝透明边框 + 壁纸 + 光影 + 中文」的样子。

原脚本 **一行都没改**：它照常联网、照常跑 key 系统、照常工作；皮肤是它把界面建出来之后，在运行时逐层重绘上去的。

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/3091318935/Roblox/main/DoorsHardCore-Seamless.lua"))()
```

---

## v3 改了什么

| 改动 | 说明 |
| --- | --- |
| **删掉材质覆写** | 不再遍历 `workspace` 改 `Material`，零副作用；只留光影 |
| **光影可“识别”** | 和壁纸一样贴文字/链接：内置 MC 系风格名、`.json` 光影包、图片滤色片 |
| **文案换正常中文** | 去掉文言味，改成流畅的简体中文翻译，可自定义词条 |
| **壁纸能认视频** | Roblox 视频资产 → `VideoFrame` 原生循环；视频页链接自动抠 id |
| **自动识别序列帧** | 长条拼图自动切成动画帧，一张图就是一段循环动画 |
| **面板可拖动 + 瘦身** | 300×424 分四页；整块按住就能拖；被换肤的窗口还多一个拖动把手 |

---

## 文件

| 文件 | 说明 |
| --- | --- |
| `DoorsHardCore-Seamless.lua` | v3 引擎主体，单文件、无依赖 |
| `DoorsHardCore-LiquidGlass.lua` | v1 液态玻璃版，备份 |
| `loader.lua` | 一行启动器 |
| `LICENSE` | MIT |
| `github/` | 发布工具：`push.ps1` / `push.sh` / `PUBLISH.md` |

---

## 用法

1. 整段粘进执行器回车；或 `loadstring` 远程载入。
2. 右下角出现「无痕 · 外观」面板，`F2` 开合。
3. 面板任意空白处按住就能拖；标题栏的 `–` 折叠、`×` 隐藏。

---

## 面板四页

### 外观

模糊（场景 BlurEffect）/ 压暗 / 玻璃 / 描边 / 圆角 / 缩放，三个开关：无缝边框、顶部高光、窗口拖动把手；下面是 6 个色板 + 一根色调滑杆。

- **描边拉到 0 = 完全无缝**：描边与分割线一起消失，只剩一层极淡玻璃。
- **缩放** 会给窗口挂 `UIScale`，不改任何原始 `Size/Position`。

### 壁纸

贴链接 → 自动识别类型 → 加到列表（`×` 删除，会存进 `SG_Config.json`）。

**能识别什么**

| 贴的东西 | 识别结果 | 播放方式 |
| --- | --- | --- |
| `rbxassetid://数字` / 纯数字 | 图片 | 缓慢放大 / 轮播 / 静帧 |
| 图片直链 `.png .jpg .webp` | 图片（下载进 `SG_Assets/` 缓存） | 同上 |
| 一长条拼图（宽 ÷ 高 = 整数且 ≥3） | **序列帧** | 自动切帧循环播放 |
| `rbxassetid://视频id`、`roblox.com/videos/…` | **视频资产** | `VideoFrame` 原生循环，卡帧会自动续播 |
| `.mp4 / .webm` 直链 | 视频文件（先下载） | 见下方说明 |

- **视频循环**：`Looped = true` + `Ended` 事件续播 + 每秒看门狗兜一次，三者叠着保证不卡在最后一帧。
- **`.mp4` 直链的现实**：Roblox 客户端只认平台内的视频资产，本地文件通常播不了。脚本会把它下到 `SG_Assets/` 并提示你上传到 Creator Dashboard 换成视频 id —— 这条路是唯一能真·播放视频的。
- 另有极光层（缓慢旋转的渐变光）、光尘、「仅菜单显示时出现」开关。

### 光影

同样支持「识别」：

| 输入 | 识别结果 |
| --- | --- |
| `bsl` / `complementary` / `seus` / `sildur` / `kuda` / `vanilla` / `night` / `cinema` / `moon` / `neon` / `gloom`，或中文「冷月 / 霓虹 / 夜色 / 幽影 / 电影」 | 内置风格，直接应用 |
| `https://….json` | 光影包，按字段加载 |
| 任意图片链接 | 全屏滤色片（低透明度叠在画面上做色调） |

内置的 MC 系风格是**观感映射**：把 BSL / Complementary / SEUS 那种暖高光、冷阴影、强泛光、轻微景深，翻译成 Roblox 自己的 `Brightness / Ambient / ColorShift_Top / ExposureCompensation` + `ColorCorrection / Bloom / DepthOfField / SunRays / Atmosphere`。GLSL 光影包本身在 Roblox 里跑不了，这是能做到的最接近的一层。

**强度** 滑杆 0~1.6，整体缩放对比度、饱和、泛光、景深、雾浓度。**还原光影** 会把所有参数写回原值。

**自己写一个光影包**（存成 `.json` 丢任意图床，贴链接即可）：

```json
{
  "name": "My Pack",
  "lighting": {
    "Brightness": 1.25,
    "Ambient": [84, 96, 112],
    "OutdoorAmbient": "#4e5c6c",
    "ColorShift_Top": [255, 240, 214],
    "ExposureCompensation": 0.1
  },
  "cc":    { "TintColor": [255, 244, 226], "Contrast": 0.16, "Saturation": 0.18 },
  "bloom": { "Intensity": 0.7, "Size": 26, "Threshold": 1.05 },
  "dof":   { "FarIntensity": 0.12, "FocusDistance": 22, "InFocusRadius": 44 },
  "sun":   { "Intensity": 0.12, "Spread": 0.9 },
  "atmosphere": { "Density": 0.32, "Haze": 1.6, "Color": [199, 208, 220] },
  "filterImage": "https://…/tint.png"
}
```

颜色支持 `[r,g,b]` 或 `"#rrggbb"`；字段扁平写（`"Brightness": 1.2`）也行。

### 翻译

开关 + 自定义词条（`原文=中文, Settings=设置`）。词表覆盖了常见的界面词：`Enabled → 已启用`、`Settings → 设置`、`Keybind → 快捷键`、`Entity → 实体`、`Give → 给予`…

会记住自己写进去的那份字：原脚本后来改了同一处文字（计数、键位、状态），脚本把这当成新原文重新判断，不会强行改回去。

---

## CONFIG 速查

```lua
local CONFIG = {
    scriptUrl   = ".../Doors-HardCore.lua",
    runOriginal = true,      -- false = 只加载皮肤
    waitTimeout = 30,
    watchSeconds= 120,
    panelKey    = Enum.KeyCode.F2,

    theme = { accent = Color3.fromRGB(0,200,0), glass = 0.74, border = 0.30,
              corner = 14, scale = 1, seamless = true, chrome = true,
              translate = true, grip = true },
    backdrop = { items = {}, mode = "auto", hold = 8, speed = 1, dim = 0.18,
                 wall = 0.95, aurora = true, dust = false, blur = 8, followWindow = true },
    shade = { preset = "vanilla", power = 1 },
}
```

面板改动会存进 `SG_Config.json`，壁纸缓存在 `SG_Assets/`，下次启动自动恢复。

---

## 常见问题

**菜单没变化？** 面板「翻译」页点「重新扫描界面」；或把 `waitTimeout` 提到 60。

**视频只出一帧 / 黑屏？** 直链 mp4 播不了是平台限制，换成 Roblox 视频资产 id；确认视频资产本身是「已验证」状态。

**序列帧被误判？** 播放方式从「自动识别」切成「缓慢放大」或「静帧」即可覆盖。

**光影太亮 / 太糊？** 拉低「强度」，或直接「还原光影」。

**文字看不清？** 玻璃调高、压暗加大，或换白色强调色。

**想彻底恢复？** 「翻译」页的「恢复默认」+「光影」页的「还原光影」；或重新进游戏。

---

## 边界

- Roblox 没有 `backdrop-filter`，模糊的是 3D 场景，不是 UI 背后的像素；玻璃感来自场景模糊 + 半透明面板 + 高光/描边。
- MC 的 GLSL 光影包无法在 Roblox 运行，这里是观感映射 + 可调强度。
- 视频只有 Roblox 视频资产能原生循环；本地/直链 mp4 需要先上传。
- 中文走 Roblox 的 CJK 回退字体，字号很小时会略糊。
- hover 颜色可能短暂回弹：原脚本用 Tween 改色时会跳回它自己的配色。

---

## 发布 / 更新

```powershell
$env:GITHUB_TOKEN = "ghp_xxx"     # 或已有 gh 登录，可省略
powershell -ExecutionPolicy Bypass -File .\github\push.ps1
```

改完文件重跑一次就是更新（脚本按 `sha` 覆盖）。细节见 [github/PUBLISH.md](github/PUBLISH.md)。
