@echo off
:: # netctl.cmd
::
:: ## Overview
:: Network control utility for managing local services and ports.
:: 
:: ## Usage
:: Execute this script to manage networking configurations.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set NETCTL_DIR=%~dp0
set NETCTL_STATE_FILE=.netctl.json

if "%~1"=="" goto usage

set SINGULAR_MODE=0
set EMIT_FORMAT=

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
:: Executes loop functionality.
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
:: Executes done_loop functionality.
    :done_loop
    if not "!EMIT_FORMAT!"=="" (
        call "%NETCTL_DIR%lib\!EMIT_FORMAT!.cmd"
    )
    if exist "!NETCTL_STATE_FILE!" del "!NETCTL_STATE_FILE!"
)
exit /b 0

:: ## usage
:: Executes usage functionality.
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
