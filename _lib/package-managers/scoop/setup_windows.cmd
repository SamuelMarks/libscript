@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where scoop >nul 2>&1
if %errorlevel% equ 0 (
    echo scoop is already installed.
    exit /b 0
)

echo Installing scoop via official PowerShell bootstrap...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/ScoopInstaller/Install/master/install.ps1 -OutFile $env:TEMP\install_scoop.ps1; & $env:TEMP\install_scoop.ps1 -RunAsAdmin; Remove-Item $env:TEMP\install_scoop.ps1 -Force -ErrorAction SilentlyContinue"

if exist "%USERPROFILE%\scoop\shims\scoop.cmd" (
    echo scoop installed successfully.
    exit /b 0
)

where scoop >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Failed to install scoop.
exit /b 1
