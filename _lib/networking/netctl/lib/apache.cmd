@echo off
:: # apache.cmd
::
:: ## Overview
:: Network control library module for apache.
:: 
:: ## Usage
:: This script provides internal functions and should not be executed directly.

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

if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo Listen %%i
)
echo.

set FIRST_PORT=
for /f "delims=" %%i in ('jq -r ".listen[0] // \"80\"" "%NETCTL_STATE_FILE%"') do (
    set FIRST_PORT=%%i
)

echo ^<VirtualHost *:%FIRST_PORT%^>

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="static" (
        echo     Alias "%%a" "%%c"
        echo     ^<Directory "%%c"^>
        echo         Require all granted
        echo     ^</Directory^>
    ) else if "%%b"=="proxy" (
        echo     ProxyPass "%%a" "%%c"
        echo     ProxyPassReverse "%%a" "%%c"
    ) else if "%%b"=="rewrite" (
        echo     RewriteEngine On
        echo     RewriteRule "^%%a(.*)$" "%%d" [L]
    )
)

echo ^</VirtualHost^>
exit /b 0
