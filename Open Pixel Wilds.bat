@echo off
rem Gets the newest version of Pixel Wilds and opens it in Godot 4.3.
rem The "Pixel Wilds" desktop shortcut made by setup-windows.ps1 runs this.
cd /d "%~dp0"

set "GIT=git"
where git >nul 2>nul || set "GIT=%ProgramFiles%\Git\cmd\git.exe"
echo Getting the newest version of Pixel Wilds...
"%GIT%" pull --ff-only || (
  echo.
  echo Couldn't get the newest version: no internet, or you changed the same files.
  echo Opening the version you have.
  timeout /t 5 >nul
)

rem Send your own notes (Pixel Wilds Vault\My Notes) up to GitHub so Claude can read them.
rem Everything above this line must stay the same: this file can change while it runs.
set "NOTES=Pixel Wilds Vault\My Notes"
if not exist "%NOTES%" goto godot
"%GIT%" add -A -- "%NOTES%"
"%GIT%" diff --cached --quiet -- "%NOTES%" && goto godot
echo Sending your notes to GitHub...
"%GIT%" -c user.name="Brenden (My Notes)" -c user.email="notes@pixelwilds.invalid" commit -q -m "My Notes from Brenden's PC" -- "%NOTES%" || goto godot
"%GIT%" push -q || (
  echo Couldn't send your notes to GitHub. They're still saved on this PC.
  "%GIT%" reset -q --soft HEAD~1
  timeout /t 3 >nul
)

:godot

set "GODOT=%USERPROFILE%\PixelWilds\Godot\Godot_v4.3-stable_win64.exe"
if not exist "%GODOT%" (
  echo Godot 4.3 isn't installed. Run setup-windows.ps1 again.
  pause
  exit /b 1
)
start "" "%GODOT%" --editor --path "%~dp0godot"
