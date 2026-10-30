# Doors HardCore · 无痕玻璃 Seamless Glass（v4）

把 `Zero0Star/RipperNewSound` 里 **Doors-HardCore.lua** 的界面，换成「无缝透明边框 + 壁纸 + 光影 + 中文 + 开场 BGM」的样子。

原脚本 **一行都没改**：它照常联网、照常跑 key 系统、照常工作；皮肤是它把界面建出来之后，在运行时逐层重绘上去的。

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/3091318935/Roblox/main/DoorsHardCore-Seamless.lua"))()
```

---

## v4 改了什么

| 问题 / 需求 | 处理 |
| --- | --- |
| **拖一个栏目，整块面板跟着动** | 拖动只认标题栏那一条（`⋮⋮` 区域），滑块 / 列表 / 输入框再也不会带着面板跑 |
| **导入视频报「视频没加载出来」** | 加资产类型探测：贴进来的是图片就按图片显示，是音频就提示去音乐页；视频失败自动降级成图片，并写清原因 |
| **想要开场 BGM** | 新增「音乐」页：载入音频 id → 点任意模式后开始循环 → 传送（≈进第 0 门）或超时自动淡出 |

v3 起已具备：删掉材质覆写、光影「识别链接」、正常中文翻译、壁纸视频循环、长图自动切序列帧、窗口拖动把手。

---

## 文件

| 文件 | 说明 |
| --- | --- |
| `DoorsHardCore-Seamless.lua` | v4 引擎主体，单文件、无依赖 |
| `DoorsHardCore-LiquidGlass.lua` | v1 液态玻璃版，备份 |
| `loader.lua` | 一行启动器 |
| `LICENSE` | MIT |
| `github/` | 发布工具：`push.ps1` / `push.sh` / `PUBLISH.md` |

---

## 用法

1. 整段粘进执行器回车；或 `loadstring` 远程载入。
2. 右下角出现「无痕 · 外观」面板，`F2` 开合。
3. **拖动只按标题栏**（左边有 `⋮⋮`，标题下面写着提示）；`–` 折叠、`×` 隐藏。

---

## 面板五页

### 外观

模糊 / 压暗 / 玻璃 / 描边 / 圆角 / 缩放；三个开关：无缝边框、顶部高光、窗口拖动把手；6 个色板 + 色调滑杆。

- 描边拉到 0 = 完全无缝，描边与分割线一起消失。
- 缩放给人家的窗口挂 `UIScale`，不动原始 `Size/Position`。

### 壁纸

贴链接 → 自动识别类型 → 进列表（`×` 删除，存进 `SG_Config.json`）。

| 贴的东西 | 识别为 | 播放 |
| --- | --- | --- |
| `rbxassetid://数字` / 纯数字 | 图片 | 缓慢放大 / 轮播 / 静帧 |
| `.png .jpg .webp` 直链 | 图片（缓存到 `SG_Assets/`） | 同上 |
| 长条拼图（宽÷高 = 整数且 ≥3） | 序列帧 | 自动切帧循环 |
| 视频 id / `roblox.com/videos/…` | 视频 | `VideoFrame` 循环 + 续播 + 看门狗 |

**视频为什么容易失败（对应你看到的那条提示）**

Roblox 只认平台内的「**视频**」资产，不认 mp4 文件、也不认图片/音频 id。做法：

1. https://create.roblox.com → **Development Items → Videos** 上传 mp4（有大小 / 时长限制，需要审核）
2. 审核通过后拿 id（纯数字）
3. 面板里贴 `1234567890` 或 `rbxassetid://1234567890` 或视频页链接

v4 现在会自动判断：id 是**图片**就直接当图片显示、是**音频**就提示你去音乐页；真播不出来会退回图片模式，而不是卡一条错误提示。

### 光影

| 输入 | 识别结果 |
| --- | --- |
| `bsl` / `complementary` / `seus` / `sildur` / `kuda` / `vanilla` / `night` / `cinema` / `moon` / `neon` / `gloom`，或中文「冷月/霓虹/夜色/幽影/电影」 | 内置风格 |
| `https://….json` | 光影包，按字段加载 |
| 任意图片 | 全屏滤色片 |

内置是 **MC 光影观感 → Roblox 后处理** 的映射（色调映射 / 泛光 / 景深 / 太阳光 / 雾气 / 曝光），带 0~1.6 强度滑杆和「还原光影」。

自建光影包：

```json
{ "name":"My Pack",
  "lighting": { "Brightness":1.25, "Ambient":[84,96,112], "ColorShift_Top":"#fff0d6" },
  "cc": { "TintColor":[255,244,226], "Contrast":0.16, "Saturation":0.18 },
  "bloom": { "Intensity":0.7, "Size":26, "Threshold":1.05 },
  "sun": { "Intensity":0.12, "Spread":0.9 },
  "atmosphere": { "Density":0.32, "Haze":1.6 } }
```

### 音乐（v4 新增）

| 控件 | 作用 |
| --- | --- |
| 音频 id 输入 | `rbxassetid://数字` 或纯数字；mp3 直链播不了 |
| 音量 | 0~1，实时生效 |
| 最长播放 | 0 = 不限；默认 45 秒（贴合 50 秒内的曲子） |
| 循环播放 | `Looped` |
| 点任意模式后播放 | 你在注入菜单里点第一个按钮后开始播（默认开） |
| 传送后自动停 | 角色位置突变 > 60 格就淡出，≈进第 0 门那一刻（默认开） |
| 试听 / 停止 | 手动控制 |

停止条件三选一先到先停：**超时** / **传送** / **手动**。这样 BGM 只盖住「选模式 → 进入第 0 门」这段，不会一路跟着跑。

> 音频要走 Roblox 音频资产：https://create.roblox.com → **Audio** 上传（50 秒内的曲子正好合适），拿审核通过的 id。别人上传的音频如果设了私有，你也用不了。

### 翻译

开关 + 自定义词条（`原文=中文, Settings=设置`）。词表覆盖常见界面词，且不会覆盖原脚本后续改动的数值 / 键位 / 状态文字。

---

## CONFIG 速查

```lua
local CONFIG = {
    scriptUrl   = ".../Doors-HardCore.lua",
    runOriginal = true,
    waitTimeout = 30, watchSeconds = 120,
    panelKey    = Enum.KeyCode.F2,

    theme = { accent = Color3.fromRGB(0,200,0), glass = 0.74, border = 0.30,
              corner = 14, scale = 1, seamless = true, chrome = true,
              translate = true, grip = true },
    backdrop = { items = {}, mode = "auto", hold = 8, speed = 1, dim = 0.18,
                 wall = 0.95, aurora = true, dust = false, blur = 8, followWindow = true },
    shade = { preset = "vanilla", power = 1 },
}
```

面板改动存在 `SG_Config.json`（含音乐 id、音量、开关），壁纸缓存在 `SG_Assets/`。

---

## 常见问题

**拖一下面板就整块动？** v4 已修：只有标题栏能拖。如果还在旧版，重新拉一次脚本。

**视频还是不出画面？** 先看面板「壁纸」页那行识别结果：写着「已识别：图片」= 你贴的是图片 id；写着「视频」但仍黑屏 = 视频资产没过审或被执行器挡了 → 换序列帧长图，或换个执行器。

**BGM 不响？** 确认是音频 id（不是图片 id）、音量 > 0、执行器有 `SoundService` 权限；Roblox 部分音频有地区/隐私限制。

**BGM 一进游戏就停？** 角色出生点算了一次「传送」，把「传送后自动停」关掉，改用「最长播放」控制。

**菜单没变化？** 「翻译」页点「重新扫描界面」，或调大 `waitTimeout`。

---

## 边界

- Roblox 没有 `backdrop-filter`，模糊的是 3D 场景，玻璃感来自场景模糊 + 半透明面板 + 高光/描边。
- MC 的 GLSL 光影包无法在 Roblox 运行，这里是观感映射。
- 视频 / 音频都必须是平台资产；直链文件只能缓存，不能直接播。
- 中文走 CJK 回退字体，小字号会略糊。
- hover 颜色可能短暂回弹（原脚本用 Tween 改色）。

---

## 发布 / 更新

```powershell
$env:GITHUB_TOKEN = "ghp_xxx"     # 已有 gh 登录可省略
powershell -ExecutionPolicy Bypass -File .\github\push.ps1
```

改完重跑一次就是更新（按 `sha` 覆盖）。细节见 [github/PUBLISH.md](github/PUBLISH.md)。
