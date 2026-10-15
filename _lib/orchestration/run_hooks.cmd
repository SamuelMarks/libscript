@echo off
:: # run_hooks.cmd
::
:: ## Overview
:: Executes defined lifecycle hooks from an install manifest on Windows.
::
:: ## Usage
:: Run `run_hooks.cmd <json_file> <hook_type>` (e.g. pre_install, post_install).

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

set json_file=%~1
set hook_type=%~2

if not exist "%json_file%" exit /b 0

for /f "delims=" %%i in ('jq -c ".hooks.%hook_type%[]?" "%json_file%" 2^>nul') do (
    set "hook=%%i"
    for /f "delims=" %%n in ('echo !hook! ^| jq -r ".name // \"unnamed_hook\""') do set "name=%%n"
    for /f "delims=" %%c in ('echo !hook! ^| jq -r ".command // empty"') do set "cmd=%%c"
    for /f "delims=" %%d in ('echo !hook! ^| jq -r ".condition // empty"') do set "cond=%%d"
    
    set skip=0
    if not "!cond!"=="" (
        echo !cond! | findstr /b /c:"unless_exists " >nul
        if not errorlevel 1 (
            set "file=!cond:unless_exists =!"
            if exist "!file!" (
                echo Skipping hook '!name!': !file! exists
                set skip=1
            )
        )
    )
    
    if "!skip!"=="0" if not "!cmd!"=="" (
        echo Executing hook '!name!': !cmd!
        call !cmd!
    )
)
exit /b 0
