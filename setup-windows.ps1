# Pixel Wilds: one-time setup on a Windows PC.
# Installs Git if it's missing, downloads Godot 4.3, downloads the game,
# puts a "Pixel Wilds" shortcut on the desktop and opens the game in Godot.
#
# Open PowerShell (Start menu, type "PowerShell") and paste:
#   irm https://raw.githubusercontent.com/Brendensob/Brenden.sobanski/main/setup-windows.ps1 | iex
#
# Afterwards, the desktop shortcut gets the newest version and opens it in Godot.
# Press F5 in Godot to play.

$ErrorActionPreference = "Stop"
$repo = "https://github.com/Brendensob/Brenden.sobanski.git"
$root = Join-Path $env:USERPROFILE "PixelWilds"
$game = Join-Path $root "Brenden.sobanski"
$godotDir = Join-Path $root "Godot"
$godot = Join-Path $godotDir "Godot_v4.3-stable_win64.exe"

function Find-Git {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($p in @("$env:ProgramFiles\Git\cmd\git.exe", "${env:ProgramFiles(x86)}\Git\cmd\git.exe", "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe")) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

New-Item -ItemType Directory -Force -Path $root | Out-Null

# 1. Git, which downloads the game and its updates
$git = Find-Git
if (-not $git) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "Please install Git from https://git-scm.com/download/win, then run this again."
    }
    Write-Host "Installing Git..." -ForegroundColor Cyan
    winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements --silent
    $git = Find-Git
    if (-not $git) { throw "Git didn't install. Install it from https://git-scm.com/download/win, then run this again." }
}

# 2. Godot 4.3, the same version the game is made with
if (-not (Test-Path $godot)) {
    Write-Host "Downloading Godot 4.3..." -ForegroundColor Cyan
    $zip = Join-Path $root "godot.zip"
    $ProgressPreference = "SilentlyContinue" # much faster download
    Invoke-WebRequest "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip" -OutFile $zip
    Expand-Archive $zip -DestinationPath $godotDir -Force
    Remove-Item $zip
}

# 3. The game
if (Test-Path (Join-Path $game ".git")) {
    Write-Host "Getting the newest version..." -ForegroundColor Cyan
    & $git -C $game pull --ff-only
} else {
    Write-Host "Downloading the game..." -ForegroundColor Cyan
    & $git clone $repo $game
    if ($LASTEXITCODE -ne 0) { throw "Couldn't download the game." }
}

# 4. A desktop shortcut that updates the game and opens it in Godot
$launcher = Join-Path $game "Open Pixel Wilds.bat"
$shell = New-Object -ComObject WScript.Shell
$link = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Pixel Wilds.lnk"))
$link.TargetPath = $launcher
$link.WorkingDirectory = $game
$link.IconLocation = "$godot,0"
$link.Save()

Write-Host ""
Write-Host "All set! Opening Pixel Wilds in Godot. Press F5 to play." -ForegroundColor Green
Write-Host "Next time, double-click 'Pixel Wilds' on your desktop: it gets the newest version first."
Start-Process $launcher -WorkingDirectory $game
