#!/usr/bin/env python3
"""上传前的音频体检：时长 / 体积 / 码率，顺便能裁到 50 秒内。

Roblox 官方音频上限约 7 分钟、体积有限，但我们要的是「开场 BGM ≤50 秒」。
这个脚本只做本地检查与裁剪，不碰账号、不上传。

用法：
    python tools/audio_check.py song.mp3
    python tools/audio_check.py song.mp3 --trim 45      # 裁出 song_trim.mp3
    python tools/audio_check.py song.mp3 --trim 45 --fade 1.5

依赖：ffprobe / ffmpeg（winget install Gyan.FFmpeg）。没有 ffmpeg 时会退回「只看体积」。
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys


def which(name: str) -> str | None:
    return shutil.which(name)


def probe(path: str) -> dict:
    ffprobe = which("ffprobe")
    if not ffprobe:
        return {}
    try:
        out = subprocess.run(
            [ffprobe, "-v", "error", "-show_entries",
             "format=duration,bit_rate:stream=codec_name,sample_rate,channels",
             "-of", "default=noprint_wrappers=1", path],
            capture_output=True, text=True, check=True,
        ).stdout
    except Exception:
        return {}
    data = {}
    for line in out.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            data[k.strip()] = v.strip()
    return data


def human_size(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.1f} {unit}" if unit != "B" else f"{n} B"
        n /= 1024.0
    return f"{n:.1f} GB"


def trim(src: str, seconds: float, fade: float) -> str:
    ffmpeg = which("ffmpeg")
    if not ffmpeg:
        sys.exit("裁剪需要 ffmpeg：winget install Gyan.FFmpeg")
    base, _ = os.path.splitext(src)
    out = f"{base}_trim.mp3"
    filters = []
    if fade > 0:
        filters.append(f"afade=t=out:st={max(0.0, seconds - fade):.2f}:d={fade:.2f}")
    cmd = [ffmpeg, "-y", "-v", "error", "-i", src, "-t", f"{seconds:.2f}"]
    if filters:
        cmd += ["-af", ",".join(filters)]
    cmd += ["-c:a", "libmp3lame", "-b:a", "192k", out]
    subprocess.run(cmd, check=True)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description="音频体检 / 裁剪（上传 Roblox 之前跑）")
    ap.add_argument("input")
    ap.add_argument("--trim", type=float, default=0, help="裁到多少秒（例如 45）")
    ap.add_argument("--fade", type=float, default=1.2, help="裁剪时尾部淡出秒数")
    args = ap.parse_args()

    src = args.input
    if not os.path.isfile(src):
        sys.exit(f"文件不存在：{src}")

    size = os.path.getsize(src)
    info = probe(src)
    dur = None
    try:
        dur = float(info.get("duration", ""))
    except ValueError:
        dur = None

    print(f"文件：{os.path.basename(src)}")
    print(f"体积：{human_size(size)}")
    if info.get("codec_name"):
        print(f"编码：{info.get('codec_name')}  {info.get('sample_rate', '?')}Hz  {info.get('channels', '?')}ch")
    if info.get("bit_rate"):
        try:
            print(f"码率：{int(info['bit_rate']) // 1000} kbps")
        except ValueError:
            pass

    if dur is None:
        print("时长：未知（没装 ffprobe 时看不了；winget install Gyan.FFmpeg）")
    else:
        print(f"时长：{dur:.2f} 秒")
        if dur <= 50:
            print("结论：✅ 50 秒内，适合当开场 BGM，直接去 Creator → Audio 上传。")
        else:
            print("结论：⚠️ 超过 50 秒 —— 加 --trim 45 裁一版再传。")

    if size > 20 * 1024 * 1024:
        print("提示：体积偏大，上传可能被拒；建议 192kbps 以内重新导出。")

    if args.trim > 0:
        if dur is not None and dur <= args.trim:
            print("原文件本来就更短，跳过裁剪。")
            return
        out = trim(src, args.trim, args.fade)
        print(f"已裁出：{out}（{args.trim:g} 秒，尾部淡出 {args.fade:g} 秒）")
        print("接着去 https://create.roblox.com/dashboard/creations → Audio 上传，拿审核通过的 id。")

    print("\n上传地址：https://create.roblox.com/dashboard/creations （Development Items → Audio）")


if __name__ == "__main__":
    main()
