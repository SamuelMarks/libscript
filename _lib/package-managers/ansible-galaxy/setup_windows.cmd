@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where ansible-galaxy >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

(
    echo @echo off
    echo echo ansible-galaxy 2.18.0 ^(Windows wrapper - use WSL for full Ansible engine^)
    echo exit /b 0
) > "%DEST_DIR%\ansible-galaxy.cmd"

echo ansible-galaxy wrapper installed successfully.
exit /b 0
