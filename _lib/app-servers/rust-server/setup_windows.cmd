@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where cargo >nul 2>&1
if %errorlevel% equ 0 (
    echo Rust server environment verified.
    exit /b 0
)

echo Rust/Cargo not found. Installing rust...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install rust
exit /b %errorlevel%
