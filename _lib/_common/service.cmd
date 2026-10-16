@echo off
:: # service.cmd
setlocal EnableDelayedExpansion
:: # LibScript Service Management Module (Windows Batch)
::
:: ## Overview
:: This module provides operations to start, stop, and manage Windows services.
::
:: ## Usage
:: ```batch
:: call "%LIBSCRIPT_ROOT_DIR%\\_lib\\_common\\service.cmd" :libscript_service start <service_name>
:: ```
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2^>^&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" ^>^&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"



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

set "_ACTION=%~1"
set "_SERVICE=%~2"
if "%_ACTION:~0,1%"==":" (
    set "_ACTION=%~2"
    set "_SERVICE=%~3"
)

if "%_ACTION%"=="" (
    echo [ERROR] Usage: service.cmd ^<action^> ^<service_name^> >&2
    exit /b 1
)
if "%_SERVICE%"=="" (
    echo [ERROR] Usage: service.cmd ^<action^> ^<service_name^> >&2
    exit /b 1
)

if /i "%_ACTION%"=="up" set "_ACTION=start"
if /i "%_ACTION%"=="down" set "_ACTION=stop"
if /i "%_ACTION%"=="query" set "_ACTION=status"

call :libscript_service "%_ACTION%" "%_SERVICE%"
exit /b %ERRORLEVEL%

:: ## libscript_service
:: Executes Windows service management commands using sc.exe.
:libscript_service
set "_SVC_ACT=%~1"
set "_SVC_NAME=%~2"
if /i "%_SVC_ACT%"=="start" (
    sc.exe start "%_SVC_NAME%"
    exit /b !ERRORLEVEL!
)
if /i "%_SVC_ACT%"=="stop" (
    sc.exe stop "%_SVC_NAME%"
    exit /b !ERRORLEVEL!
)
if /i "%_SVC_ACT%"=="restart" (
    sc.exe stop "%_SVC_NAME%" >nul 2>&1
    timeout /t 2 /nobreak >nul 2>&1
    sc.exe start "%_SVC_NAME%"
    exit /b !ERRORLEVEL!
)
if /i "%_SVC_ACT%"=="status" (
    sc.exe query "%_SVC_NAME%"
    exit /b !ERRORLEVEL!
)
if /i "%_SVC_ACT%"=="enable" (
    sc.exe config "%_SVC_NAME%" start= auto
    exit /b !ERRORLEVEL!
)
if /i "%_SVC_ACT%"=="disable" (
    sc.exe config "%_SVC_NAME%" start= disabled
    exit /b !ERRORLEVEL!
)
if /i "%_SVC_ACT%"=="health" (
    sc.exe query "%_SVC_NAME%" | findstr /C:"RUNNING" >nul 2>&1
    exit /b !ERRORLEVEL!
)
if /i "%_SVC_ACT%"=="logs" (
    echo [WARN] Logs not natively supported via sc.exe for %_SVC_NAME%
    exit /b 0
)
echo [ERROR] Unknown service action: %_SVC_ACT% >&2
exit /b 1

