@echo off
:: # hooks.cmd
::
:: ## Overview
:: Unified Dual-Layer Lifecycle Hook Dispatcher for Tier 1 physical and logical multi-tenant hooks on Windows.
::
:: ## Usage
:: call _lib\_common\hooks.cmd :libscript_exec_hook <component_dir> <hook_name> [args...]

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

set "FIRST_ARG=%~1"
if not "%FIRST_ARG%"=="" (
    if "%FIRST_ARG:~0,1%"==":" (
        shift
        goto %FIRST_ARG%
    )
    if "%FIRST_ARG%"=="--exec" (
        shift
        goto :libscript_exec_hook
    )
    if "%FIRST_ARG%"=="--has" (
        shift
        goto :libscript_has_hook
    )
)
exit /b 0

:: ## libscript_resolve_component_dir
:: Resolves a component name or path to an absolute directory in _lib.
:libscript_resolve_component_dir
set "COMP_ARG=%~1"
set "RESOLVED_COMP_DIR="
if exist "%COMP_ARG%\manifest.json" (
    for %%I in ("%COMP_ARG%") do set "RESOLVED_COMP_DIR=%%~fI"
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\%COMP_ARG%\manifest.json" (
    for %%I in ("!LIBSCRIPT_ROOT_DIR!\%COMP_ARG%") do set "RESOLVED_COMP_DIR=%%~fI"
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\%COMP_ARG%\manifest.json" (
    for %%I in ("!LIBSCRIPT_ROOT_DIR!\_lib\%COMP_ARG%") do set "RESOLVED_COMP_DIR=%%~fI"
    exit /b 0
)
for /D %%C in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
    if exist "%%C\%COMP_ARG%" (
        for %%I in ("%%C\%COMP_ARG%") do set "RESOLVED_COMP_DIR=%%~fI"
        exit /b 0
    )
)
exit /b 1

:: ## libscript_has_hook
:: Checks whether a component implements a given physical or logical lifecycle hook.
:libscript_has_hook
set "COMP_IN=%~1"
set "HOOK_NAME=%~2"
call :libscript_resolve_component_dir "%COMP_IN%"
if errorlevel 1 exit /b 1
if exist "!RESOLVED_COMP_DIR!\hooks\%HOOK_NAME%.cmd" exit /b 0
exit /b 1

:: ## libscript_exec_hook
:: Executes a component lifecycle hook with standardized context variables.
:libscript_exec_hook
set "COMP_IN=%~1"
set "HOOK_NAME=%~2"
if "%COMP_IN%"=="" exit /b 1
if "%HOOK_NAME%"=="" exit /b 1
call :libscript_resolve_component_dir "%COMP_IN%"
if errorlevel 1 (
    echo [ERROR] Component directory not found for "%COMP_IN%" 1>&2
    exit /b 1
)
for %%N in ("!RESOLVED_COMP_DIR!") do set "LIBSCRIPT_COMPONENT_NAME=%%~nxN"
set "LIBSCRIPT_HOOK_ACTION=%HOOK_NAME%"
if "%LIBSCRIPT_INSTANCE_ROOT%"=="" set "LIBSCRIPT_INSTANCE_ROOT=%USERPROFILE%\.libscript\!LIBSCRIPT_COMPONENT_NAME!"
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" set "LIBSCRIPT_TARGET_SYSROOT=/"
if "%LIBSCRIPT_TENANT_ID%"=="" set "LIBSCRIPT_TENANT_ID=default"
if "%LIBSCRIPT_REMOTE_STRATEGY%"=="" (
    if not "%USER_DB_STRATEGY%"=="" (
        set "LIBSCRIPT_REMOTE_STRATEGY=%USER_DB_STRATEGY%"
    ) else (
        set "LIBSCRIPT_REMOTE_STRATEGY=local"
    )
)
set "HOOK_CMD=!RESOLVED_COMP_DIR!\hooks\%HOOK_NAME%.cmd"
if not exist "!HOOK_CMD!" (
    echo [DEBUG] Optional hook "%HOOK_NAME%" not implemented for component "!LIBSCRIPT_COMPONENT_NAME!"; skipping. 1>&2
    exit /b 0
)
call "!HOOK_CMD!" %3 %4 %5 %6 %7 %8 %9
exit /b %errorlevel%
