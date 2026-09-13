@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where node >nul 2>&1
if %errorlevel% equ 0 (
    echo Node.js server environment verified.
    exit /b 0
)

echo Node.js not found. Installing nodejs...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install nodejs
exit /b %errorlevel%
