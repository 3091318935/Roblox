#Requires -Version 5.1
<#
  mirror.ps1 -- pull every asset the Hardcore Modes hub needs from Zero0Star's GitHub
                into a local folder, so you can host them yourself.

  Why: the hub fetches its mode data from
      raw.githubusercontent.com/Zero0Star/<repo>/master/*.lua
  Those files live under his account. If he deletes the repo, makes it private or
  his GitHub goes away, your setup dies with it. Mirror them once, push them to
  your own repo, and loader.lua rewrites every Zero0Star URL to your copy.

  Usage:
      powershell -ExecutionPolicy Bypass -File .\hardcore-modes\mirror.ps1
      powershell -ExecutionPolicy Bypass -File .\hardcore-modes\mirror.ps1 -IncludeHub
      powershell -ExecutionPolicy Bypass -File .\hardcore-modes\mirror.ps1 -WithAudio
      powershell -ExecutionPolicy Bypass -File .\hardcore-modes\mirror.ps1 -Verify

  -IncludeHub   also grab the hub source itself from pastefy -> HARDCORE-Modes.lua
  -WithAudio    also grab the mp3 set (RipperNewSound / RipperMPSound, tens of MB)
  -Verify       local files only, no network
  -Pad          target folder (default D:\DSH ROBLOX\hardcore-modes\assets)

  NOTE: keep this file ASCII-only. Windows PowerShell 5.1 reads .ps1 as ANSI, so
  UTF-8 Chinese text inside it can break the parser with "UnexpectedToken".
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

$wc = New-Object System.Net.WebClient
$wc.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) mirror.ps1')
$wc.Proxy = [System.Net.WebRequest]::DefaultWebProxy

function Write-Step($m) { Write-Host "[..] $m" -ForegroundColor DarkCyan }
function Write-Ok($m) { Write-Host "[ok] $m" -ForegroundColor Green }
function Write-Warn2($m) { Write-Host "[!!] $m" -ForegroundColor Yellow }

# raw.githubusercontent.com is often DNS-poisoned in CN -> a bad address hangs until
# timeout. jsDelivr first because it answers fast; raw is the last resort.
$Bases = @(
    'https://fastly.jsdelivr.net/gh/Zero0Star/{0}@master/{1}',
    'https://gcore.jsdelivr.net/gh/Zero0Star/{0}@master/{1}',
    'https://cdn.jsdelivr.net/gh/Zero0Star/{0}@master/{1}',
    'https://raw.githubusercontent.com/Zero0Star/{0}/master/{1}',
    'https://ghfast.top/https://raw.githubusercontent.com/Zero0Star/{0}/master/{1}'
)

# Repo / file pairs taken from the hub's const table and jsDelivr's file listing.
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
    $lastErr = ''
    foreach ($tpl in $Bases) {
        $url = $tpl -f $f.Repo, $f.Name
        try {
            # WebClient returns a real byte[], Invoke-WebRequest .Content is a String in
            # PowerShell 5.1 and WriteAllBytes() rejects it -> every file looked "failed".
            $bytes = $wc.DownloadData($url)
            if ($bytes -and $bytes.Length -gt 512) {
                [System.IO.File]::WriteAllBytes($dest, $bytes)
                Write-Ok ("{0} <- {1} ({2:N0} B)" -f $f.Name, ([Uri]$url).Host, $bytes.Length)
                $okCount++
                $done = $true
                break
            }
            $lastErr = "too small ($($bytes.Length) B)"
        }
        catch {
            $lastErr = $_.Exception.Message
            if ($lastErr.Length -gt 90) { $lastErr = $lastErr.Substring(0, 90) }
        }
    }
    if (-not $done) {
        $fail += $f.Name
        Write-Warn2 ("{0} failed: {1}" -f $f.Name, $lastErr)
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
            $bytes = $wc.DownloadData($u)
            if ($bytes -and $bytes.Length -gt 4000) {
                [System.IO.File]::WriteAllBytes($hubDest, $bytes)
                Write-Ok ("hub source <- {0} ({1:N0} B)" -f ([Uri]$u).Host, $bytes.Length)
                break
            }
        }
        catch {
            $msg = $_.Exception.Message
            if ($msg.Length -gt 90) { $msg = $msg.Substring(0, 90) }
            Write-Warn2 ("hub source failed: {0} ({1})" -f ([Uri]$u).Host, $msg)
        }
    }
}

Write-Host ''
Write-Host ("mirrored : {0} / {1} files" -f $okCount, $Files.Count) -ForegroundColor Green
Write-Host ("folder   : {0}" -f $Pad)
if ($fail.Count) {
    Write-Host ("failed   : {0}" -f ($fail -join ', ')) -ForegroundColor Yellow
}
Write-Host ''
Write-Host 'next: powershell -ExecutionPolicy Bypass -File "D:\DSH ROBLOX\github\push.ps1"' -ForegroundColor Cyan
