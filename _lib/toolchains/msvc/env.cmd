@echo off
:: # env.cmd
::
:: ## Overview
:: Environment variable definitions for the msvc component, resolving cl.exe, dumpbin.exe, msival2.exe, and darice.cub.
::
:: ## Usage
:: Source this script to configure environment variables.

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

if "%MSVC_ARCH%"=="" set "MSVC_ARCH=x64"
if "%MSVC_CRT%"=="" set "MSVC_CRT=MD"
if "%MSVC_DARICE_CUB_PATH%"=="" (
    for %%K in ("C:\Program Files (x86)\Windows Kits\10\bin\10.*\x64\darice.cub" "C:\Program Files (x86)\Windows Kits\10\bin\x64\darice.cub") do (
        if exist "%%~fK" set "MSVC_DARICE_CUB_PATH=%%~fK"
    )
)

set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "msvc"

endlocal & (
    set "PATH=%PATH%"
    set "MSVC_ARCH=%MSVC_ARCH%"
    set "MSVC_CRT=%MSVC_CRT%"
    set "MSVC_DARICE_CUB_PATH=%MSVC_DARICE_CUB_PATH%"
)
exit /b 0
