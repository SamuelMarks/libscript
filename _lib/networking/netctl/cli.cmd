@echo off
:: # cli.cmd
:: # netctl.cmd
::
:: ## Overview
:: Network control utility for managing local services and ports.
:: 
:: ## Usage
:: Execute this script to manage networking configurations.

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

set NETCTL_DIR=%~dp0
set NETCTL_STATE_FILE=.netctl.json

if "%~1"=="" goto usage

set SINGULAR_MODE=0
set EMIT_FORMAT=

if /I "%~1"=="download" goto :noop
if /I "%~1"=="install" goto :noop
if /I "%~1"=="ls" goto :noop
if /I "%~1"=="ls-remote" goto :noop
if /I "%~1"=="use" goto :noop
if /I "%~1"=="start" goto :noop
if /I "%~1"=="stop" goto :noop
if /I "%~1"=="restart" goto :noop
if /I "%~1"=="install-service" goto :noop
if /I "%~1"=="uninstall-service" goto :noop
if /I "%~1"=="env" goto :noop
if /I "%~1"=="logs" goto :noop
if /I "%~1"=="status" goto :noop
if /I "%~1"=="health" goto :noop
if /I "%~1"=="uninstall" (
    call "%NETCTL_DIR%\uninstall.cmd"
    exit /b %ERRORLEVEL%
)
if /I "%~1"=="test" (
    call "%NETCTL_DIR%\test.cmd"
    exit /b %ERRORLEVEL%
)

if /I "%~1"=="init" (
    call "%NETCTL_DIR%lib\state.cmd" init
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="listen" (
    call "%NETCTL_DIR%lib\state.cmd" listen "%~2"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="static" (
    call "%NETCTL_DIR%lib\state.cmd" static "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="proxy" (
    call "%NETCTL_DIR%lib\state.cmd" proxy "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="rewrite" (
    call "%NETCTL_DIR%lib\state.cmd" rewrite "%~2" "%~3"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="emit" (
    call "%NETCTL_DIR%lib\%~2.cmd"
    exit /b %ERRORLEVEL%
) else if /I "%~1"=="-h" (
    goto usage
) else if /I "%~1"=="--help" (
    goto usage
) else if /I "%~1"=="/?" (
    goto usage
) else if /I "%~1"=="-?" (
    goto usage
) else (
    set SINGULAR_MODE=1
)

if "!SINGULAR_MODE!"=="1" (
    set NETCTL_STATE_FILE=%TEMP%\netctl_state_%RANDOM%.json
    call "%NETCTL_DIR%lib\state.cmd" init
    
:: ## loop
:: Iterates through singular-mode CLI flags to populate temporary netctl state.
    :loop
    if "%~1"=="" goto done_loop
    if /I "%~1"=="--listen" (
        call "%NETCTL_DIR%lib\state.cmd" listen "%~2"
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--static" (
        call "%NETCTL_DIR%lib\state.cmd" static "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--proxy" (
        call "%NETCTL_DIR%lib\state.cmd" proxy "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--rewrite" (
        call "%NETCTL_DIR%lib\state.cmd" rewrite "%~2" "%~3"
        shift
        shift
        shift
        goto loop
    )
    if /I "%~1"=="--emit" (
        set EMIT_FORMAT=%~2
        shift
        shift
        goto loop
    )
    echo Unknown option: %1
    goto usage

:: ## done_loop
:: Emits the requested reverse-proxy configuration and removes temporary state files.
    :done_loop
    if not "!EMIT_FORMAT!"=="" (
        call "%NETCTL_DIR%lib\!EMIT_FORMAT!.cmd"
    )
    if exist "!NETCTL_STATE_FILE!" del "!NETCTL_STATE_FILE!"
)
exit /b 0

:: ## usage
:: Displays command-line usage instructions for netctl on Windows.
:usage
echo netctl - Singular and Additive network config generator
echo.
echo Usage:
echo   netctl [COMMAND] [ARGS...]
echo   netctl [OPTIONS...]
echo.
echo Commands:
echo   init                           Initialize .netctl.json
echo   listen ^<port^>                  Add a listening port
echo   static ^<path^> ^<target^>         Add a static file route
echo   proxy ^<path^> ^<target^>          Add a reverse proxy route
echo   rewrite ^<path^> ^<pattern^>       Add a rewrite rule
echo   emit ^<format^>                  Emit the configuration for a given format
echo                                  Formats: nginx, caddy, apache, iis
echo.
echo Options (Singular mode):
echo   --listen ^<port^>                Add a listening port
echo   --static ^<path^> ^<target^>       Add a static route
echo   --proxy ^<path^> ^<target^>        Add a proxy route
echo   --rewrite ^<path^> ^<pattern^>     Add a rewrite rule
echo   --emit ^<format^>                Emit to specified format and exit
exit /b 1
:: ## noop
:: Handles standard Version Manager Contract lifecycle verbs that are no-ops for netctl.
:noop
echo netctl is a native shell module. No installation or daemon management required.
exit /b 0
