# 光影包（Seamless Shade Packs）

Roblox 跑不了 Minecraft 的 GLSL 光影包（`.zip` + `shaders/` 那套），引擎里没有可编程管线接口。
这里换个思路：把光影的**观感**拆成 Roblox 自带的后处理 + 光照参数，用一份 JSON 描述，皮肤脚本读到就应用。

## 目录里有什么

| 文件 | 名字 | 观感 |
| --- | --- | --- |
| `index.json` | 清单 | 面板「一键拉云端清单」读的就是它 |
| `aurora-night.json` | 极光夜 | 深蓝底 + 青绿天光，夜景/恐怖图 |
| `dusk-gold.json` | 暮金 | 落日橙调 + 强泛光 |
| `storm-grey.json` | 铅灰暴雨 | 低饱和 + 厚雾 |
| `snow-blind.json` | 雪盲 | 极亮冷白 |
| `deep-blue.json` | 深蓝 | 水下蓝绿 + 厚雾 |
| `film-warm.json` | 暖胶 | 偏黄底片味 + 轻景深 |

## 怎么用

面板 `F2` → **光影** 页：

1. **一键拉云端清单** — 直接读 `lighting/index.json`，把 6 套拉进「我的光影包」，点一行就换。
2. **光影下载页** — 打开本目录（浏览器里看 raw / 下载）。
3. 输入框贴 **单个包的 raw 链接** → 导入并应用，同时存进清单（`SG_Shade.json`，下次开游戏还在）。
4. 输入框贴 **别人的 index.json**（同格式）→ 整份清单拉进来。

## 字段（都可省略）

```json
{
  "name": "包名",
  "lighting": {
    "Brightness": 1.1,
    "Ambient": [96, 76, 64],
    "OutdoorAmbient": [90, 70, 58],
    "ColorShift_Top": [255, 176, 120],
    "ColorShift_Bottom": [120, 70, 54],
    "ExposureCompensation": 0.12,
    "ClockTime": 17.5,
    "FogStart": 40, "FogEnd": 900, "FogColor": [90, 90, 110],
    "EnvironmentDiffuseScale": 0.4, "EnvironmentSpecularScale": 0.4
  },
  "cc":        { "TintColor": [255, 202, 158], "Contrast": 0.2, "Saturation": 0.24, "Brightness": 0.02 },
  "bloom":     { "Intensity": 0.82, "Size": 32, "Threshold": 1.0 },
  "dof":       { "FarIntensity": 0.16, "FocusDistance": 22, "InFocusRadius": 44, "NearIntensity": 0.1 },
  "sun":       { "Intensity": 0.32, "Spread": 1 },
  "atmosphere":{ "Density": 0.4, "Haze": 2.2, "Color": [238, 182, 142], "Decay": [148, 100, 82], "Glare": 0.16 },
  "filterImage": { "image": "https://…/grade.png", "alpha": 0.22 }
}
```

- 颜色两种写法都行：`[r,g,b]`（0–255）或 `"#ffca9e"`
- 也可以扁平写：`{ "name": "x", "Brightness": 1.2, "Contrast": 0.1 }`
- 面板里的「强度」滑杆会统一乘到 cc / bloom / dof / sun / atmosphere 上，`lighting` 直通不受影响
- `filterImage` 是「图片滤色片」：把一张图半透明叠在最上层做整体调色

## 加自己的包

```bash
# 1. 复制一份改参数
cp lighting/film-warm.json lighting/my-pack.json
# 2. 把名字、参数改掉，然后放进清单
#    index.json 的 packs 数组里加一条 { "name": "我的", "url": "…/lighting/my-pack.json" }
# 3. 推上去
powershell -ExecutionPolicy Bypass -File .\github\push.ps1
```

本地测试不用推：直接把文件放进 `D:\DSH ROBLOX\lighting\`，链接填
`file:///D:/DSH ROBLOX/lighting/my-pack.json`（执行器要开 `getcustomasset` 才认）。
