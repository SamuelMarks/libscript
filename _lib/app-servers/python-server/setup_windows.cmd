@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where python >nul 2>&1
if %errorlevel% equ 0 (
    echo Python server environment verified.
    exit /b 0
)

echo Python not found. Installing python...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install python
exit /b %errorlevel%
