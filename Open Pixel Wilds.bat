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

set "GODOT=%USERPROFILE%\PixelWilds\Godot\Godot_v4.3-stable_win64.exe"
if not exist "%GODOT%" (
  echo Godot 4.3 isn't installed. Run setup-windows.ps1 again.
  pause
  exit /b 1
)
start "" "%GODOT%" --editor --path "%~dp0godot"
