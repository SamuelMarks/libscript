@echo off
setlocal EnableDelayedExpansion
if exist "%SCRIPT_DIR%update_db.cmd" (
    call "%SCRIPT_DIR%update_db.cmd"
) else if exist "%SCRIPT_DIR%update_db.sh" (
    REM If WSL or git bash is available
    sh "%SCRIPT_DIR%update_db.sh"
) else (
    echo Error: update_db script not found. 1>&2
    exit /b 1
)
exit /b !errorlevel!
