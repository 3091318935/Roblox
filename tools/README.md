# tools · 本地转换工具

两个脚本，把「第三方 mp3 / mp4」变成 **Roblox 能直接用的东西**。
它们只在你电脑上跑，不碰账号、不上传，输出文件由你自己传。

需要 Python（DSH 自带一份就行）和 Pillow；视频那块还需要 ffmpeg：

```powershell
winget install Gyan.FFmpeg     # 装完重开一个终端
python -c "import PIL; print(PIL.__version__)"
```

---

## video2strip.py —— mp4 / gif → 序列帧长图

Roblox 客户端不能直接播本地 mp4，但可以把视频摊成一张「横向长条图」，
脚本识别到「宽 ÷ 高 = 整数且 ≥3」就按帧循环播放 —— 免上传，立刻能用。

```powershell
python tools\video2strip.py clip.mp4 --frames 12 --height 240
python tools\video2strip.py clip.webm --frames 24 --height 320 --out wall.png
python tools\video2strip.py anim.gif --frames 16          # GIF 不需要 ffmpeg
```

输出 `clip_strip.png`，例如 `2880×240`（12 帧 × 240×240）。

用法二选一：

1. **免上传**：把 PNG 放进执行器的 workspace 文件夹，面板「壁纸」页贴文件名（`clip_strip.png`）；
2. **走资产**：上传成 Roblox 图片，贴 `rbxassetid://<id>`。

帧数建议 8~24：越多越顺，图也越大（Roblox 单图有尺寸上限，宽度别超过 8192）。

---

## audio_check.py —— mp3 体检 / 裁到 50 秒

```powershell
python tools\audio_check.py song.mp3
python tools\audio_check.py song.mp3 --trim 45 --fade 1.5
```

会打印时长、体积、编码、码率，并给结论：

- `≤50 秒` → 直接去 Creator → Audio 上传，拿审核通过的 id 贴进「音乐」页；
- `>50 秒` → 加 `--trim 45` 生成 `song_trim.mp3`（尾部自动淡出），再传。

上传页：<https://create.roblox.com/dashboard/creations>（Development Items → Audio）
文档：<https://create.roblox.com/docs/audio/assets>

---

## 为什么不能「一键自动上传」

上传走的 Creator Dashboard 是**网页登录态**接口（需要你的 Roblox cookie + CSRF 令牌），
执行器跑在游戏客户端里，没有、也不该拿这些凭证。所以自动化只能做到「文件侧」：
转换、体检、裁剪、生成可直接贴进去的 id 或文件名。真正点「上传」那一下要走官方页面。
