@echo off
:: # env.cmd
::
:: ## Overview
:: Environment initialization for Go on Windows.
::
:: ## Usage
:: Sets `GO_VERSION` and prepends Go to PATH.

:: Environment variables for Windows
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

if "%GO_VERSION%"=="" set GO_VERSION=latest
if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_BASE_DIR=%USERPROFILE%\.libscript"
) else (
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_HOME%"
)
if exist "%LIBSCRIPT_BASE_DIR%\go\default\bin\go.exe" (
    set "GOROOT=%LIBSCRIPT_BASE_DIR%\go\default"
) else (
    set "GOROOT=%LIBSCRIPT_BASE_DIR%\go\%GO_VERSION%"
)
for %%P in ("C:\Program Files\Go\bin" "%LIBSCRIPT_BASE_DIR%\go\default\bin" "%GOROOT%\bin") do (
    set "_CAND_P=%%~P"
    if exist "!_CAND_P!" (
        echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
        if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
    )
)
echo ";!PATH!;" | findstr /I /C:";%GOROOT%\bin;" >nul 2>&1
if errorlevel 1 set "PATH=%GOROOT%\bin;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "go" "%GO_VERSION%"

endlocal & (
    set "GO_VERSION=%GO_VERSION%"
    set "GOROOT=%GOROOT%"
    set "LIBSCRIPT_BASE_DIR=%LIBSCRIPT_BASE_DIR%"
    set "PATH=%PATH%"
)
exit /b 0
