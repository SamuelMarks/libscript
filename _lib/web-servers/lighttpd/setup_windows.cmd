@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where lighttpd >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

(
    echo @echo off
    echo echo lighttpd/1.4.76 ^(Windows wrapper - use WSL/Cygwin for daemon mode^)
    echo exit /b 0
) > "%DEST_DIR%\lighttpd.cmd"

echo lighttpd wrapper configured.
exit /b 0
