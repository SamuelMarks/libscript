@echo off
:: # daemonize.cmd
::
:: ## Overview
:: Minimal daemonization wrapper for Windows using `start /B` and `taskkill`.
::
:: ## Usage
:: Run `daemonize.cmd <action> <json_file>` where action is `start`, `stop`, `up`, or `down`.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

set action=%~1
set json_file=%~2

if not exist "%json_file%" exit /b 0

for /f "delims=" %%i in ('jq -c ".services[]?" "%json_file%" 2^>nul') do (
    set "svc=%%i"
    for /f "delims=" %%n in ('echo !svc! ^| jq -r ".name // empty"') do set "name=%%n"
    for /f "delims=" %%c in ('echo !svc! ^| jq -r ".command // empty"') do set "cmd=%%c"
    
    if not "!name!"=="" if not "!cmd!"=="" (
        if /i "!action!"=="start" (
            echo Configuring and starting service '!name!'...
            if not exist "\tmp\data\!name!" mkdir "\tmp\data\!name!" 2>nul
            
            rem Set environments inline
            for /f "delims=" %%e in ('echo !svc! ^| jq -r ".env | to_entries[]? | \"set \\\"\(.key)=\(.value)\\\"\"" 2^>nul') do (
                %%e
            )
            
            rem Enumerate env files (basic naive support)
            for /f "delims=" %%f in ('echo !svc! ^| jq -r ".env_files[]?" 2^>nul') do (
                if exist "%%f" (
                    for /f "tokens=* delims=" %%l in (%%f) do set "%%l"
                )
            )

            start "!name!" /B cmd.exe /c "!cmd!"
        )
        if /i "!action!"=="up" (
            echo Configuring and starting service '!name!'...
            start "!name!" /B cmd.exe /c "!cmd!"
        )
        if /i "!action!"=="stop" (
            echo Stopping service '!name!'...
            rem Complex to kill without PID, could use taskkill with window title
            taskkill /fi "WINDOWTITLE eq !name!" /f 2>nul
        )
        if /i "!action!"=="down" (
            taskkill /fi "WINDOWTITLE eq !name!" /f 2>nul
        )
    )
)
exit /b 0
