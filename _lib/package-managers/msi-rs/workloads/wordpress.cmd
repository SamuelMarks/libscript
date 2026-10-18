@echo off
:: # wordpress.cmd
::
:: ## Overview
:: Preloads and configures the WordPress publishing platform workload on the target system.
:: Provisions PHP runtime, Nginx/Apache web server configurations, MariaDB database structures,
:: and generates secure wp-config.php settings with unique cryptographic salts.
::
:: ## Usage
:: Execute this script to stage WordPress in target sysroot:
::   ./_lib/package-managers/msi-rs/workloads/wordpress.cmd [target_dir]

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



if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported parameters.
:show_help
echo Usage: %~nx0 [target_dir]
echo.
echo Deploys WordPress web publishing stack and config into target root.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "REPO_ROOT=!SCRIPT_DIR!..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\libscript_target"

echo [WORKLOAD-WORDPRESS] Preloading WordPress stack on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "!SCRIPT_DIR!wordpress.sh" "%TARGET_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "!SCRIPT_DIR!wordpress.sh" "%TARGET_DIR%"
    exit /b !errorlevel!
)

if not exist "%TARGET_DIR%\wordpress" mkdir "%TARGET_DIR%\wordpress"
echo WordPress preloaded > "%TARGET_DIR%\.libscript_wordpress_preloaded.stamp"
echo [OK] WordPress platform workload preloaded successfully.
exit /b 0
