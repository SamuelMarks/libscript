@echo off
:: # env_base.cmd
::
:: ## Overview
:: Foundational environment initialization module for LibScript components on Windows.
:: Resolves the component package name, active version, and idempotently prepends
:: the component's binary directory to PATH across endlocal scope.
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" [dir]

setlocal EnableDelayedExpansion
set "CALLER_FILE=!THIS_FILE!"
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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "_EB_PKG=%PACKAGE_NAME%"
if "!_EB_PKG!"=="" if not "!CALLER_FILE!"=="" (
    for %%D in ("!CALLER_FILE!") do set "_EB_DIR=%%~dpD"
    if "!_EB_DIR:~-1!"=="\" set "_EB_DIR=!_EB_DIR:~0,-1!"
    for %%N in ("!_EB_DIR!") do set "_EB_PKG=%%~nxN"
)
set "_EB_VER=%LIBSCRIPT_VERSION%"
if "!_EB_VER!"=="" set "_EB_VER=latest"
set "_NEW_PATH=!PATH!"
if not "!_EB_PKG!"=="" if /i not "!_EB_PKG!"=="_common" (
    set "_CAND=!LIBSCRIPT_HOME!\!_EB_PKG!\!_EB_VER!\bin"
    echo ";!_NEW_PATH!;" | findstr /I /C:";!_CAND!;" >nul 2>&1
    if errorlevel 1 set "_NEW_PATH=!_CAND!;!_NEW_PATH!"
)

endlocal & (
    set "LIBSCRIPT_ROOT_DIR=%LIBSCRIPT_ROOT_DIR%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%_NEW_PATH%"
)
exit /b 0
