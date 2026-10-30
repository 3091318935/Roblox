#!/usr/bin/env python3
"""把本地视频 / GIF 转成「序列帧长图」PNG —— Roblox 不用上传视频也能当动画壁纸。

原理：把视频均匀抽 N 帧，横向拼成一张长条图。面板里贴这张图后，
脚本识别到「宽 ÷ 高 = 整数且 ≥3」，就会按 N 帧循环播放。

用法（Windows，需先装 ffmpeg：winget install Gyan.FFmpeg）：
    python tools/video2strip.py clip.mp4 --frames 12 --height 240
    python tools/video2strip.py clip.webm --frames 24 --height 320 --out wall.png
    python tools/video2strip.py anim.gif --frames 16          # GIF 不需要 ffmpeg

输出：默认 <输入名>_strip.png，同目录。

放哪儿：把 PNG 丢进执行器的 workspace 文件夹，面板里贴文件名（如 wall_strip.png），
或上传成 Roblox 图片后贴 rbxassetid。
"""

from __future__ import annotations

import argparse
import glob
import os
import shutil
import subprocess
import sys
import tempfile

try:
    from PIL import Image
except ImportError:
    sys.exit("需要 Pillow：pip install pillow")


def which(name: str) -> str | None:
    return shutil.which(name)


def probe_duration(path: str) -> float | None:
    ffprobe = which("ffprobe")
    if not ffprobe:
        return None
    try:
        out = subprocess.run(
            [ffprobe, "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", path],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        return float(out)
    except Exception:
        return None


def load_gif_frames(path: str, want: int) -> list[Image.Image]:
    im = Image.open(path)
    total = getattr(im, "n_frames", 1) or 1
    step = max(1, total // want)
    frames = []
    for i in range(0, total, step):
        im.seek(i)
        frames.append(im.convert("RGBA").copy())
        if len(frames) >= want:
            break
    return frames


def extract_video_frames(path: str, want: int, height: int) -> list[Image.Image]:
    ffmpeg = which("ffmpeg")
    if not ffmpeg:
        sys.exit("没找到 ffmpeg。装一下：winget install Gyan.FFmpeg（装完重开终端）")

    dur = probe_duration(path)
    fps = (want / dur) if dur and dur > 0 else 12.0
    tmp = tempfile.mkdtemp(prefix="v2s_")
    pattern = os.path.join(tmp, "f_%04d.png")
    cmd = [
        ffmpeg, "-y", "-v", "error", "-i", path,
        "-vf", f"fps={max(fps, 0.1):.6f},scale=-2:{height}",
        "-frames:v", str(want), pattern,
    ]
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as exc:
        sys.exit(f"ffmpeg 抽帧失败：{exc}")

    files = sorted(glob.glob(os.path.join(tmp, "f_*.png")))[:want]
    if not files:
        sys.exit("没抽到帧：换个文件或加大 --frames")
    return [Image.open(f).convert("RGBA") for f in files]


def fit(frame: Image.Image, size: tuple[int, int]) -> Image.Image:
    """等比缩放到高度一致，再居中裁到统一宽度，保证每帧尺寸相同。"""
    w, h = size
    scale = h / frame.height
    nw = max(1, int(round(frame.width * scale)))
    resized = frame.resize((nw, h), Image.LANCZOS)
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.paste(resized, ((w - nw) // 2, 0), resized)
    return canvas


def main() -> None:
    ap = argparse.ArgumentParser(description="视频 / GIF → 序列帧长图 PNG")
    ap.add_argument("input", help="mp4 / webm / mov / gif")
    ap.add_argument("--frames", type=int, default=12, help="抽多少帧（3~48 比较好用）")
    ap.add_argument("--height", type=int, default=240, help="每帧高度（像素）")
    ap.add_argument("--out", default=None, help="输出文件名")
    args = ap.parse_args()

    src = args.input
    if not os.path.isfile(src):
        sys.exit(f"文件不存在：{src}")

    want = max(3, min(48, args.frames))
    ext = os.path.splitext(src)[1].lower()

    if ext == ".gif":
        frames = load_gif_frames(src, want)
    else:
        frames = extract_video_frames(src, want, args.height)

    if not frames:
        sys.exit("没有可用帧")

    base_w = max(8, int(round(frames[0].width * args.height / frames[0].height)))
    frames = [fit(f, (base_w, args.height)) for f in frames]

    strip = Image.new("RGBA", (base_w * len(frames), args.height), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * base_w, 0))

    out = args.out or os.path.splitext(src)[0] + "_strip.png"
    strip.save(out)

    print(f"已生成：{out}")
    print(f"尺寸：{strip.width}×{strip.height}，{len(frames)} 帧（单帧 {base_w}×{args.height}）")
    print("面板用法：把这张图放进执行器 workspace，壁纸栏贴文件名；")
    print(f"或者上传成 Roblox 图片后贴 rbxassetid://<id>（宽高比 {strip.width / strip.height:.2f}）。")


if __name__ == "__main__":
    main()
