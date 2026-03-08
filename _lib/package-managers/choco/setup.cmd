@echo off
where choco >nul 2>&1
if %ERRORLEVEL% EQU 0 goto :eof

echo [INFO] Bootstrapping Chocolatey (choco) for Windows...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

if exist "%ALLUSERSPROFILE%\chocolatey\bin\choco.exe" (
    echo [INFO] choco successfully installed.
) else (
    echo [ERROR] Failed to install Chocolatey.
)
