#Requires -Version 5.1
<#
  mirror.ps1 — 把 Hardcore Modes hub 依赖的全部资源，从 Zero0Star 的 GitHub 拉到本地

  为什么需要：hub 运行时只做两件事 —— 从 pastefy 取自己，从
  raw.githubusercontent.com/Zero0Star/<repo>/master/*.lua 取模式数据。
  资源在他账号下，他删库 / 改私 / 被封，你这套就废了。镜像一份到你自己的仓库，
  然后 loader 会把所有 Zero0Star 的 URL 改写成你自己的，你就彻底独立，可以自己当房主。

  用法：
      powershell -ExecutionPolicy Bypass -File .\hardcore-modes\mirror.ps1
      powershell -ExecutionPolicy Bypass -File .\hardcore-modes\mirror.ps1 -IncludeHub
      powershell -ExecutionPolicy Bypass -File .\hardcore-modes\mirror.ps1 -WithAudio
      powershell -ExecutionPolicy Bypass -File .\hardcore-modes\mirror.ps1 -Verify

  -IncludeHub  额外抓 hub 本体（pastefy 那份）存成 HARDCORE-Modes.lua
  -WithAudio   额外抓 mp3（RipperNewSound / RipperMPSound，几十 MB，可选）
  -Verify      只检查本地文件是否齐全，不联网
#>
[CmdletBinding()]
param(
    [switch]$IncludeHub,
    [switch]$WithAudio,
    [switch]$Verify,
    [string]$Pad = 'D:\DSH ROBLOX\hardcore-modes\assets'
)

$ErrorActionPreference = 'Stop'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

function Write-Step($m) { Write-Host "[..] $m" -ForegroundColor DarkCyan }
function Write-Ok($m) { Write-Host "[ok] $m" -ForegroundColor Green }
function Write-Warn2($m) { Write-Host "[!!] $m" -ForegroundColor Yellow }

# raw.githubusercontent.com 在国内经常被污染，按成功率排序
$Bases = @(
    'https://raw.githubusercontent.com/Zero0Star/{0}/master/{1}',
    'https://fastly.jsdelivr.net/gh/Zero0Star/{0}@master/{1}',
    'https://ghfast.top/https://raw.githubusercontent.com/Zero0Star/{0}/master/{1}',
    'https://gcore.jsdelivr.net/gh/Zero0Star/{0}@master/{1}'
)

# 仓库 / 文件名（来自 hub 的 const 表和 jsDelivr 清单，全部实测存在）
$Files = @(
    @{ Repo = 'Importantstuff'; Name = 'ARCHIVESITEM.lua' },
    @{ Repo = 'Importantstuff'; Name = 'ArchivesLua.lua' },
    @{ Repo = 'Importantstuff'; Name = 'ArchivesLua2.lua' },
    @{ Repo = 'Importantstuff'; Name = 'ArchivesLua3.lua' },
    @{ Repo = 'Importantstuff'; Name = 'ArchivesSound.lua' },
    @{ Repo = 'Importantstuff'; Name = 'HOTELITEM.lua' },
    @{ Repo = 'Importantstuff'; Name = 'HOTELLua.lua' },
    @{ Repo = 'Importantstuff'; Name = 'HOTELLua2.lua' },
    @{ Repo = 'Importantstuff'; Name = 'HOTELLua4.lua' },
    @{ Repo = 'Importantstuff'; Name = 'HOTELLua5.lua' },
    @{ Repo = 'Importantstuff'; Name = 'HOTELMusic.lua' },
    @{ Repo = 'Importantstuff'; Name = 'HotelSound.lua' },
    @{ Repo = 'Importantstuff'; Name = 'MineItem.lua' },
    @{ Repo = 'Importantstuff'; Name = 'MINESITEM.lua' },
    @{ Repo = 'Importantstuff'; Name = 'MinesMusic.lua' },
    @{ Repo = 'Importantstuff'; Name = 'PANLT' },
    @{ Repo = 'Importantstuff'; Name = 'STOP' },
    @{ Repo = 'RipperNewSound'; Name = 'Charm.lua' }
)

if ($WithAudio) {
    $mp3 = @(
        'DreadJumpFace.mp3','A-333Music2.mp3','BossTime.mp3','MultiMonster1.mp3','MultiMonster2.mp3',
        'MultiMonster3.mp3','MultiMonster4.mp3','Silence.mp3','SilenceFar.mp3','MultiMonsterRebound.mp3',
        'MultiMonsterRipper.mp3','NoRunning.mp3','FrostbitePhase1.mp3','FrostbitePhase2.mp3',
        'FrostbiteEnd.mp3','HatRedPhase2.mp3','LEVELFUN.mp3','ScribbletEnd.mp3','ScribbletStart.mp3',
        'DeerJumpScary.mp3','Z367Music.mp3','RipperDoorend.mp3'
    )
    foreach ($n in $mp3) { $Files += @{ Repo = 'RipperNewSound'; Name = $n } }
    $mp = @('A120Jump.mp3','RipperNewSound.mp3','ReboundSoundV1.mp3','ReboundMovings.mp3','HatredBossMusic.mp3')
    foreach ($n in $mp) { $Files += @{ Repo = 'RipperMPSound'; Name = $n } }
}

if (-not (Test-Path -LiteralPath $Pad)) {
    $null = New-Item -ItemType Directory -Path $Pad -Force
    Write-Step "created $Pad"
}

$okCount = 0
$fail = @()

if ($Verify) {
    Write-Step "verify only: $Pad"
    foreach ($f in $Files) {
        $path = Join-Path $Pad $f.Name
        if ((Test-Path -LiteralPath $path) -and ((Get-Item -LiteralPath $path).Length -gt 512)) {
            $okCount++
        }
        else { $fail += $f.Name }
    }
    Write-Host ("present: {0} / {1}" -f $okCount, $Files.Count) -ForegroundColor Green
    if ($fail.Count) { Write-Warn2 ("missing: " + ($fail -join ', ')) }
    return
}

foreach ($f in $Files) {
    $dest = Join-Path $Pad $f.Name
    if ((Test-Path -LiteralPath $dest) -and ((Get-Item -LiteralPath $dest).Length -gt 512)) {
        Write-Host ("[skip] {0} (exists, {1:N0} B)" -f $f.Name, (Get-Item -LiteralPath $dest).Length) -ForegroundColor DarkGray
        $okCount++
        continue
    }

    $done = $false
    foreach ($tpl in $Bases) {
        $url = $tpl -f $f.Repo, $f.Name
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 90
            if ($resp.StatusCode -eq 200 -and $resp.RawContentLength -gt 512) {
                [System.IO.File]::WriteAllBytes($dest, $resp.Content)
                Write-Ok ("{0} <- {1} ({2:N0} B)" -f $f.Name, ([Uri]$url).Host, (Get-Item -LiteralPath $dest).Length)
                $okCount++
                $done = $true
                break
            }
        }
        catch { }
    }
    if (-not $done) {
        $fail += $f.Name
        Write-Warn2 "$($f.Name) failed on every mirror"
    }
}

if ($IncludeHub) {
    $hubDest = Join-Path (Split-Path -Parent $Pad) 'HARDCORE-Modes.lua'
    $hubUrls = @(
        'https://pastefy.app/Bf6hbDY4/raw',
        'https://raw.githubusercontent.com/3091318935/Roblox/main/hardcore-modes/HARDCORE-Modes.lua'
    )
    foreach ($u in $hubUrls) {
        try {
            $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 90
            if ($r.RawContentLength -gt 4000) {
                [System.IO.File]::WriteAllBytes($hubDest, $r.Content)
                Write-Ok ("hub source <- {0} ({1:N0} B)" -f ([Uri]$u).Host, (Get-Item -LiteralPath $hubDest).Length)
                break
            }
        }
        catch { Write-Warn2 "hub source failed: $u" }
    }
}

Write-Host ''
Write-Host ("mirrored : {0} / {1} files" -f $okCount, $Files.Count) -ForegroundColor Green
Write-Host ("folder   : {0}" -f $Pad)
if ($fail.Count) {
    Write-Host ("failed   : {0}" -f ($fail -join ', ')) -ForegroundColor Yellow
}
Write-Host ''
Write-Host '下一步：powershell -ExecutionPolicy Bypass -File "D:\DSH ROBLOX\github\push.ps1"' -ForegroundColor Cyan
Write-Host '推完之后 loader 会自动把这些资源改写成读你自己的仓库。' -ForegroundColor Cyan
