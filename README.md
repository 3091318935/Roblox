# Doors HardCore · 无痕玻璃 Seamless Glass（v2）

把 `Zero0Star/RipperNewSound` 里 **Doors-HardCore.lua** 的界面，换成「无缝透明边框 + 壁纸 + 材质光影 + 文艺文案」的样子。

原脚本 **一行都没改**：它照常联网、照常跑 key 系统、照常工作；皮肤是它把界面建出来之后，在运行时逐层重绘上去的。

---

## 为什么只能「外挂一层」

`Doors-HardCore.lua` 是 wearedevs 混淆过的单行巨物（字符串加密 + 控制流平坦化），里面没有可读的 UI 代码，也无从定位窗口构造函数。所以这里走的路是：

```
原脚本照跑 → 抓它新建的 ScreenGui → 挨个节点改外观（颜色 / 圆角 / 描边 / 字体 / 文案 / 缩放）
```

功能逻辑、按钮回调、事件连接，一律不碰。

---

## 文件

| 文件 | 说明 |
| --- | --- |
| `DoorsHardCore-Seamless.lua` | v2 换肤引擎，单文件、无依赖（约 2.5k 行） |
| `DoorsHardCore-LiquidGlass.lua` | v1 液态玻璃版，留着当备份 |
| `loader.lua` | 一行启动器（发布后把 `USER/REPO` 换成自己的仓库） |
| `LICENSE` | MIT |
| `github/` | 发布工具：`push.ps1` / `push.sh` / `PUBLISH.md` |
| `README.md` | 本文件 |

---

## 用法

**方式一（最快）**：把 `DoorsHardCore-Seamless.lua` 全选粘进执行器，回车。

**方式二（推荐）**：直接走已发布仓库，粘一行就能用：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/3091318935/Roblox/main/DoorsHardCore-Seamless.lua"))()
```

> 仓库：https://github.com/3091318935/Roblox ｜ 上传/更新流程见 [github/PUBLISH.md](github/PUBLISH.md)

**方式三**：只想套皮肤、暂时不跑原脚本 → 把文件里的 `CONFIG.runOriginal` 改成 `false`。

运行后：

1. 右下角出现 **「夜行 · 无痕」** 调参卡；
2. 原脚本正常加载，它的菜单被就地重绘；
3. `F2` 开合调参卡（`CONFIG.panelKey` 可改）。

---

## 面板分组

### 光 · 玻璃

| 控件 | 作用 |
| --- | --- |
| 雾化 BLUR | 给场景挂 `BlurEffect`，0–24。玻璃感主要来自这里（Roblox 没有 `backdrop-filter`，模糊的是 3D 场景，不是 UI 后面的像素） |
| 压暗 SCRIM | 全屏黑纱浓度 |
| 玻璃 GLASS | 面板底色的不透明度 |
| 描边 BORDER | **拉到 0 = 完全无缝**：描边、分割线一起消失，只剩一层极淡的玻璃 |
| 圆角 RADIUS | 全局圆角 |
| 尺幅 SCALE | 原 UI 整体缩放 0.6x–1.6x（给窗口挂 `UIScale`，不改布局） |
| 无缝 / 高光 | 分割线开关 / 顶部高光与投影开关 |
| 色板 + 色调 HUE | 强调色：6 个预设 + 一根色相滑杆，全局彩色元素统一到该色相 |

### 境 · 壁纸

| 控件 | 作用 |
| --- | --- |
| 输入框 + 添加 | 贴链接就能加壁纸，支持三种写法（见下） |
| 列表 | 已加的壁纸，`×` 删除；会写进 `SG_Config.json`，下次自动恢复 |
| 动态方式 MOTION | 静帧 / **缓推镜头** / **多图轮播** / **整条帧带** / 视频 / 纯极光 |
| 停留 / 速度 / 帧数 | 每张停留秒数、动画倍率、帧带切几帧 |
| 壁纸 WALL | 壁纸浓度 |
| 极光 / 光尘 | 一层缓慢旋转的渐变光 + 飘浮光点（纯 GUI，动态感来源之一） |
| 仅菜单可见时生效 | 关掉菜单就收掉壁纸与雾化，正常跑图不挡视线 |

**能贴什么链接**

| 写法 | 例子 | 备注 |
| --- | --- | --- |
| Roblox 图片 id | `1234567890` 或 `rbxassetid://1234567890` | 最稳，不依赖执行器文件 API |
| 图片直链 | `https://i.imgur.com/xxxx.png` | 需要执行器有 `writefile` + `getcustomasset`；脚本会下载到 `SG_Assets/` 并缓存 |
| 视频资产 id | `rbxassetid://视频id`，并把模式切成「视频」 | 走 `VideoFrame`，需要该视频资产可用 |

**动态壁纸怎么来**

- **缓推镜头**：一张静态图也能动 —— 缓慢放大 + 平移（Ken Burns），配极光层就有呼吸感；
- **多图轮播**：加 3–8 张图，自动交叉淡入淡出；
- **整条帧带**：一张横向拼好的序列帧（比如 8 帧并排），脚本会从 PNG/JPEG 头里读到像素宽高，自动切成 8 帧循环播放；
- **视频**：Roblox 视频资产，真·动态；
- GIF 不能直接播（Roblox 不支持 GIF），会提示你拆图或换 mp4 视频 id。

### 影 · 光影与材质

| 控件 | 作用 |
| --- | --- |
| 光影 LIGHTING | 原始 / 暖调电影 / 冷月 / 霓虹 / 幽影。改 `Brightness`、`Ambient`、`ColorShift_Top`，并挂 `ColorCorrectionEffect`、`BloomEffect`、`DepthOfFieldEffect` |
| 材质 MATERIAL | 原始 / 大理石 / 玻璃 / 金属 / 霓虹 / 木纹 / 布艺。遍历 `workspace` 把 `Material` + `Reflectance` 覆写（分批暂停，不卡死），跳过自己角色 |
| 应用 / 还原 | 材质可反复应用；「还原材质」按记录表逐部件写回；「全部还原」连光影一起复位 |
| 重新换肤 | 重扫一遍界面 |

> 材质与光影都是**客户端本地**的，别人看到的是原样；对判定、碰撞没有任何影响。

### 文 · 辞章

| 控件 | 作用 |
| --- | --- |
| 文辞替换 | 开/关文艺词表 |
| 自定义词条 | 格式 `原文=译文, Enabled=开卷, Settings=笺注`，覆盖内置词表 |
| 重新换肤 / 洗砚 | 重扫界面 / 全部回到初始状态 |

内置词表把界面里常见的英文词换成文言味的中文（`Enabled → 开卷`、`Settings → 笺注`、`Keybind → 手札`、`Entity → 异影`…）。

**不会把动态文本改坏**：脚本会记住自己写进去的那份字；如果原脚本后来改了同一处文字（计数、键位、状态），它会把这当成新原文重新判断，不会强行改回去。

---

## 排版为什么算「更简洁」

在不碰原有控件层级、不改任何 `Size`/`Position` 的前提下：

- 所有边框 `BorderSizePixel = 0`，圆角统一（窗口 16 / 控件 6–12）；
- 分割线在无缝模式下整条隐去，不再有硬线把内容切碎；
- `ScrollingFrame` 滚动条收细到 3px、透明度统一；
- 字体统一 Gotham 族（≥18px 用 Bold），文字描边一律去掉；
- 彩色元素全部归到强调色相，不再红黄蓝紫打架；
- 窗口 22px 柔和投影 + 顶部 1px 高光 + 从顶到底的玻璃光泽，替代原来的实心深灰。

---

## CONFIG 速查

```lua
local CONFIG = {
    scriptUrl   = ".../Doors-HardCore.lua", -- 原脚本地址（可换镜像）
    runOriginal = true,     -- false = 只加载皮肤
    waitTimeout = 30,       -- 等界面出现的秒数
    watchSeconds= 120,      -- 之后继续监听新控件的秒数
    panelKey    = Enum.KeyCode.F2,

    theme = { accent=Color3.fromRGB(0,200,0), glass=0.72, border=0.35,
              corner=16, scale=1, seamless=true, chrome=true, textStyle=true },
    backdrop = { items={},  -- 预置壁纸，例如 {"rbxassetid://123456"}
                 mode="pan", hold=9, speed=1, dim=0.20, wall=0.94,
                 aurora=true, dust=false, blur=10, followWindow=true },
    scene = { lights="off", material="off" },  -- 开局就套预设
}
```

面板里的改动会存到 `SG_Config.json`（执行器工作目录），下次启动自动读回；壁纸缓存在 `SG_Assets/`。

---

## 常见问题

**菜单没变化？**
点面板的「重新换肤」。还不行：把 `waitTimeout` 调到 60；确认执行器有 `loadstring` 和 `game:HttpGet`；有些执行器 `CoreGui` 受保护，脚本会自动退回 `PlayerGui`（那样若手机端有权限问题，换个执行器更省事）。

**壁纸直链没反应？**
执行器要支持 `writefile` + `getcustomasset`。不支持就改用 Roblox 图片 id（`rbxassetid://...`），那条路不需要文件 API。

**雾化把画面糊住了？**
「雾化」拉到 0，或关掉「仅菜单可见时生效」。

**缩放之后窗口跑偏？**
`UIScale` 是按控件锚点缩放的，原窗口锚点不在左上就会往一侧长。把「尺幅」拉回 1 即恢复。

**文字看不清？**
「玻璃」拉高、「压暗」加大，或换成白色强调色。

**hover 时颜色会回弹？**
原脚本若用 Tween 改 hover 颜色，会短暂跳回它自己的配色 —— 运行时换肤的固有限制，除非改它源码（混淆，改不了）。

**想彻底恢复？**
面板「洗砚」→ 光影材质一起还原；或者直接重新进游戏。

---

## 边界说明

- Roblox 没有 CSS 的 `backdrop-filter`，**无法模糊 GUI 后面的像素**；玻璃感来自「场景 3D 模糊 + 半透明面板 + 高光/描边」。
- 中文用的是 Roblox 的 CJK 回退字体，字号偏小时会略糊。
- 材质覆写会遍历 `workspace`，大场景下第一遍大约几秒（分批让帧）。
- **物品贴图（TextureId）没有做通用替换**：Doors 的道具是各自的模型/贴图，要按名字逐个改，容易误伤实体判定；所以这里只做「材质 + 反射率」这一层，加上 Lighting 后处理当光影。
- 壁纸直链依赖执行器的 `writefile` / `getcustomasset`；`rbxassetid://` 那条路不需要文件 API。
- hover 颜色可能短暂回弹：原脚本用 Tween 改色时会跳回它自己的配色，运行时换肤绕不过去。

---

## 发布 / 分享

仓库里自带一键发布（REST API，不需要装 git）：

```powershell
$env:GITHUB_TOKEN = "ghp_xxx"          # fine-grained 给 Contents + Administration 读写；classic 给 repo
powershell -ExecutionPolicy Bypass -File .\github\push.ps1
```

它会：建仓库（默认 `DoorsHardCore-SeamlessGlass`，`-Repo` 可改）→ 上传 6 个文件 → 把 `loader.lua` 里的占位符换成你的真实地址 → 把下面这行复制到剪贴板：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/DoorsHardCore-Seamless.lua"))()
```

权限怎么配、怎么手传、以后怎么更新、踩坑对照表 → [github/PUBLISH.md](github/PUBLISH.md)。
