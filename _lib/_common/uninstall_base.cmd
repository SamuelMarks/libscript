@echo off
:: # LibScript Common Uninstall Entrypoint (Windows Batch)
:: ## Overview
:: Standardized entrypoint for component uninstallation on Windows. Resolves root, checks privileges, and delegates to uninstall scripts.
:: ## Usage
:: Your component's `uninstall.cmd` should call this. ```batch @echo off call "%~dp0\..\..\..\_lib\_common\uninstall_base.cmd" ```

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"


set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Resolve LIBSCRIPT_ROOT_DIR
if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

set "_UB_TARGET_DIR=%DIR%"
if "!_UB_TARGET_DIR!"=="" set "_UB_TARGET_DIR=%CD%"
if "!_UB_TARGET_DIR:~-1!"=="\" set "_UB_TARGET_DIR=!_UB_TARGET_DIR:~0,-1!"

if exist "!_UB_TARGET_DIR!\uninstall_windows.cmd" (
    set "STACK="
    call "!_UB_TARGET_DIR!\uninstall_windows.cmd" %*
    exit /b !errorlevel!
)
if exist "!_UB_TARGET_DIR!\uninstall_generic.cmd" (
    set "STACK="
    call "!_UB_TARGET_DIR!\uninstall_generic.cmd" %*
    exit /b !errorlevel!
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\uninstall_generic.cmd" (
    set "DIR=!_UB_TARGET_DIR!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\uninstall_generic.cmd" %*
    exit /b !errorlevel!
)
exit /b 0
