@echo off
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping PowerShell Core (pwsh) for Windows...
set "PACKAGE_NAME=powershell"
set "PWSH_URL=https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-x64.msi"
set "PWSH_OUT=%TEMP%\pwsh.msi"

call "%~dp0\..\..\_common\pkg_mgr.cmd" :libscript_download "%PWSH_URL%" "%PWSH_OUT%"

if exist "%PWSH_OUT%" (
    echo [INFO] Running MSI installer for PowerShell Core...
    msiexec.exe /package "%PWSH_OUT%" /quiet /norestart
) else (
    echo [ERROR] Failed to download PowerShell.
)
