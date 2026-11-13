# Hardcore Modes · 自己开 + 别人也能开

目标只有一个：**你和你朋友都能用一行 `loadstring` 打开 pastefy 上那个 DOORS 硬核模式 hub**，不用 VPS、不用平台、不用改脚本。

---

## 1. 结论先说

那个 paste 是 **unlisted（未列出）但 raw 直链对任何人可读** 的，所以"别人也能玩"本来就是成立的 —— 他们复制同一条 `loadstring(game:HttpGet(...))()` 就能开。真正会出事的地方只有三个：

1. paste 被作者删了 / 被 pastefy 限流 → 谁都打不开；
2. 执行器的 `HttpGet` 被 Cloudflare 挑战页拦住 → 拿回来的是 HTML，`loadstring` 编译失败；
3. 脚本自带 key / 白名单 → 别人能下载但开不起来（这跟宿主无关，见第 5 节）。

`loader.lua` 就是把这三件事一次性堵住：多源回退 + 挑战页识别 + 本地缓存。

---

## 2. 三步上线

**① 把 `loader.lua` 放进你自己的仓库**

```
3091318935/Roblox  (main 分支)
└── hardcore-modes/
    ├── loader.lua            ← 本文件
    ├── dump-hub.lua          ← 抓 Discord / 接口用
    └── HARDCORE-Modes.lua    ← 可选：paste 的离线镜像
```

用你现有的 `github/push.ps1` 推就行（它走 GitHub contents API，owner `3091318935`，repo `Roblox`）。

**② 拿到你的启动地址**

```
https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/loader.lua
```

国内加载不动就换这两个等价地址（同样内容）：

```
https://cdn.jsdelivr.net/gh/3091318935/Roblox@main/hardcore-modes/loader.lua
https://ghfast.top/https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/loader.lua
```

**③ 发给别人就这一行**

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/loader.lua"))()
```

进 DOORS（placeId `6839171747`）里执行即可。UI 没出来先看控制台：

- `[HC 1.0.0] 已启动 源=... 大小=...` → 成功，源地址就是它实际用的那条；
- `所有源都失败：...` → 每条源后面会写明原因（太短 / HTML 页面 / 被盾拦了 / 不像 Lua）。

---

## 3. 镜像（这一步决定"别人也能玩"能不能长期成立）

pastefy 上的 unlisted paste 作者一删就没了，所以建议存一份：

1. 浏览器打开 `https://pastefy.app/Bf6hbDY4/raw`，`Ctrl+S` 存成 `HARDCORE-Modes.lua`；
2. 丢进 `hardcore-modes/` 一起推上去；
3. 打开 `loader.lua`，把 `CFG.mirrors` 里第一行注释取消：

```lua
mirrors = {
    "https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/HARDCORE-Modes.lua",
    "https://cdn.jsdelivr.net/gh/3091318935/Roblox@main/hardcore-modes/HARDCORE-Modes.lua",
},
```

顺序是：官方 paste → 官方 paste 免缓存 → 你的镜像 → 本地 `hardcore-modes.lua` → 剪贴板。前四个全挂才会读本地，本地也没有就提示你手动复制。

另外 `writefile` 会在**跑通之后**把脚本存成工作区的 `hardcore-modes.lua`，下次 paste 挂了它直接读本地（Delta / Xeno / Solara / Wave 都有 `writefile`）。

---

## 4. 换 hub / 加别的模式

`loader.lua` 不绑定这一个 paste：

- 换源：改 `CFG.sources` 第一行；
- 想同时挂多个 hub：每个 hub 复制一份 loader、改 `CFG.name` 和 `CFG.localFile`（名字不能撞，否则缓存互相覆盖）；
- 想做菜单式启动器（一个 UI 里列「硬核/无尽/碎片/生日…」）：参照你 `doors-modes/DoorsModes-Hub.lua` 的 `mk()` 写法，把每个按钮的 callback 写成 `loadstring(game:HttpGet(url))()` 即可 —— 这套 UI 你已经有了，不用重写。

---

## 5. key / 白名单怎么判断（决定"别人能不能开"）

执行完看这三个信号，有任意一个就是**必须去原作者社区拿 key**：

| 信号 | 表现 |
| --- | --- |
| 弹 key 输入框 | UI 一出来就要你粘贴一串 `XXXX-XXXX`，或跳转 `gateway.*` / `*.luarmor.net` / `pandadevelopment.net` |
| 请求白名单接口 | `dump-hub.lua` 抓到 `HttpGet` 指向 `/api/v2/...`、`/validate`、`/hwid` |
| 静默失败 | UI 出来了但按钮没反应，控制台有 401 / invalid key |

这三个都指向同一件事：**脚本本体可以随便传，能不能用取决于对方账号系统**。所以"别人也能玩"在带 key 的情况下只能是"他们自己去拿 key"，宿主换谁都一样。

---

## 6. 那个 Discord 在哪（已核实的线索 + 确定性抓法）

先说结论：**没有公开索引页能直接跳到它**。这个 hub 是 unlisted paste + 自定义 VM 混淆，Discord 邀请只存在于**解码后的字符串**里，网页搜索抓不到。以下是我实际查证过的东西，可以直接拿去用：

**已核实**

- paste 元数据（`https://pastefy.app/api/v2/paste/Bf6hbDY4`）：标题 **`HARDCORE-Modes`**，作者 pastefy 账号 **`HOWNEW396`**（显示名 `HOWNEW-396`，user_id `lkMCNpaQ`），`visibility: UNLISTED`，创建于 **2026-10-30**。
- pastefy 没有"按用户列 paste"的公开接口（`/api/v2/user/lkMCNpaQ` 与 `/pastes` 都是 404），搜索接口是坏的（Elasticsearch 500）。
- 它跑的游戏是**官方 DOORS**：placeId `6839171747` → universeId `2440500124`。同一套"脚本模式"合集在社区里公开流传的版本（Mercury UI、判 `game.placeId == 6839171747`）里，模式作者署名是 **noonie & ping**（硬核模式）、**noonie & ping & Chrono**（硬核重置版）、**The Jabiss**（碎片/朦胧）、**plamen6789**（生日/困难）、**cool59572**（恐惧）、**C87FM & Crow & Cheeto & sandwich**（无尽），另有 `The backdoor` 系列（kiwi / upoi）。你要找的"MK → Heaven"这条线，就是这批人里改名重组的那一支。
- ScriptBlox 上以该游戏为目标的脚本都只是零散功能脚本（Spawn Notifier / ESP / auto open），没有这个 hub 的条目。

**确定性抓法（推荐，1 分钟）**

Discord 邀请一定在脚本运行时的字符串或 UI 里，用执行器自己把它挖出来：

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/dump-hub.lua"))()
```

它做的事：钩 `game:HttpGet` / `request` / `setclipboard` / `loadstring` → 自己拉目标脚本并执行 → 8 秒后扫 `getgenv()`、CoreGui/PlayerGui 全部 `Text`、函数常量与 upvalue → 结果写 `hub-dump.txt` 并复制到剪贴板。

- hub UI 出来后**手动点一下里面的 Discord / Key 按钮**，再执行 `getgenv().HC_DUMP.dump()`，邀请链接基本都会掉出来；
- 想抓别的 hub：`getgenv().HC_TARGET = "https://..."`，再跑一次。

**如果 dump 出来还是空的，按这个顺序找**

1. **Discord 服务器目录**（服务端渲染、能直接搜描述）：`discordbotlist.com/servers`、`disboard.org`（Cloudflare 挡脚本，浏览器能开）、`discadia.com`，关键词 `doors`、`doors scripts`、`heaven`；
2. **V3rmillion** 搜索区搜 `doors hardcore`、`noonie`、`heaven hub` —— 这类 hub 的作者几乎都在上面发帖；
3. **YouTube**：搜 `doors hardcore mode script`，按"最新上传"排，视频描述/置顶评论里通常就是邀请；
4. **ScriptBlox 作者页**：`scriptblox.com/script/DOORS-Hardcore-Remake-NOT-MINE-25429` 这类帖子的上传者主页，经常挂着自家 hub 的 discord；
5. 最后一个笨办法但有效：在执行器里跑完 hub 后看 UI 底部的 `Link` / 水印文本 —— Mercury 那套模板的 `Link` 字段就是社区地址。

---

## 7. 文件

| 文件 | 作用 |
| --- | --- |
| `loader.lua` | 你发给别人的那一层：多源回退 + 挑战页识别 + 本地缓存 + 重开接口 `getgenv().HC_MODES.rerun()` |
| `dump-hub.lua` | 从混淆脚本里抠 Discord / 接口 / key 系统 |
| `HARDCORE-Modes.lua` | 可选离线镜像（自己 `Ctrl+S` 存一份） |
