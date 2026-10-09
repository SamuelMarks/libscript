@echo off
:: # iis.cmd
::
:: ## Overview
:: Network control library module for iis.
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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<configuration^>
echo   ^<system.webServer^>
echo     ^<rewrite^>
echo       ^<rules^>

set RULE_ID=1
for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="proxy" (
        echo         ^<rule name="ReverseProxy!RULE_ID!" stopProcessing="true"^>
        echo           ^<match url="^%%a(.*)" /^>
        echo           ^<action type="Rewrite" url="%%c/{R:1}" /^>
        echo         ^</rule^>
        set /a RULE_ID+=1
    ) else if "%%b"=="rewrite" (
        echo         ^<rule name="Rewrite!RULE_ID!" stopProcessing="true"^>
        echo           ^<match url="^%%a(.*)" /^>
        echo           ^<action type="Rewrite" url="%%d" /^>
        echo         ^</rule^>
        set /a RULE_ID+=1
    )
)

echo       ^</rules^>
echo     ^</rewrite^>

:: Note: IIS `appcmd` is usually required for setting Listen ports and Static paths via Virtual Directories.
:: The web.config handles the rewriting and proxying.
:: We will emit comments on how to complete the IIS setup.

echo     ^<!-- To complete IIS Setup for Static paths and Listeners: --^>
for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo     ^<!-- appcmd set site /site.name:"Default Web Site" /+bindings.[protocol='http',bindingInformation='*:%%i:'] --^>
)

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    if "%%b"=="static" (
        echo     ^<!-- appcmd add vdir /app.name:"Default Web Site/" /path:"%%a" /physicalPath:"%%c" --^>
    )
)

echo   ^</system.webServer^>
echo ^</configuration^>
exit /b 0
