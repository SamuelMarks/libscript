@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup script for Elasticsearch.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
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

if "%ACTION%"=="" set "ACTION=install"
if "%ELASTICSEARCH_VERSION%"=="" set "ELASTICSEARCH_VERSION=7.17.21"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    where elasticsearch >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] elasticsearch is already installed on the system.
        exit /b 0
    )
    set "TARGET_DIR=%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%"
    if exist "!TARGET_DIR!\bin\elasticsearch.bat" (
        echo [INFO] elasticsearch is already installed in !TARGET_DIR!.
        exit /b 0
    )
    where choco >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing elasticsearch via chocolatey...
        choco install elasticsearch -y
        exit /b 0
    )
    exit /b 0
) else if "%ACTION%"=="uninstall" (
    rmdir /s /q "%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%" 2>nul
    exit /b 0
) else if "%ACTION%"=="test" (
    where elasticsearch >nul 2>&1 || (
        if exist "%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%\bin\elasticsearch.bat" (
            echo [INFO] elasticsearch batch script verified.
            exit /b 0
        )
    )
    echo [INFO] elasticsearch test completed.
    exit /b 0
)

exit /b 0
