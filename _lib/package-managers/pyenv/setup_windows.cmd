@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where pyenv >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "%USERPROFILE%\.pyenv\pyenv-win\bin\pyenv.bat" exit /b 0

where choco >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing pyenv-win via choco...
    choco install -y pyenv-win
    if not errorlevel 1 exit /b 0
)

echo Installing pyenv-win via PowerShell bootstrap...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1' -OutFile '$env:TEMP\install-pyenv-win.ps1'; & '$env:TEMP\install-pyenv-win.ps1'; Remove-Item '$env:TEMP\install-pyenv-win.ps1' -Force -ErrorAction SilentlyContinue"

if exist "%USERPROFILE%\.pyenv\pyenv-win\bin\pyenv.bat" (
    echo pyenv-win installed successfully.
    exit /b 0
)

where pyenv >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Failed to install pyenv.
exit /b 1
