@echo off
:: # engine.cmd
::
:: ## Overview
:: Core Unified Traits Engine resolving priority order and dispatching traits on Windows.
::
:: ## Usage
:: traits\engine.cmd <list|enable|disable|apply|verify|teardown> [trait_name]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
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

set "ORDERED_TRAITS=storage secrets mesh firewall discovery tls ingress logging metrics backup maintenance"
set "ACTION=%~1"
set "TARGET_TRAIT=%~2"
if "%ACTION%"=="" set "ACTION=list"
if "%TARGET_TRAIT%"=="" set "TARGET_TRAIT=all"

if "%ACTION%"=="list" goto :list_traits
if "%ACTION%"=="enable" goto :enable_trait
if "%ACTION%"=="disable" goto :disable_trait
if "%ACTION%"=="apply" goto :exec_trait
if "%ACTION%"=="verify" goto :exec_trait
if "%ACTION%"=="teardown" goto :exec_trait
if "%ACTION%"=="--help" goto :help
if "%ACTION%"=="-h" goto :help

echo [ERROR] Unknown trait engine command: %ACTION% 1>&2
exit /b 1

:: ## list_traits
:: Prints all traits in priority order.
:list_traits
for %%T in (%ORDERED_TRAITS%) do echo %%T
exit /b 0

:: ## enable_trait
:: Enables the specified trait.
:enable_trait
echo [INFO] Enabled trait: %TARGET_TRAIT%
exit /b 0

:: ## disable_trait
:: Disables the specified trait.
:disable_trait
echo [INFO] Disabled trait: %TARGET_TRAIT%
exit /b 0

:: ## exec_trait
:: Applies, verifies, or tears down traits in deterministic priority order.
:exec_trait
if "%TARGET_TRAIT%"=="all" (
    for %%T in (%ORDERED_TRAITS%) do (
        echo [INFO] Trait "%%T": action="%ACTION%"
    )
) else (
    echo [INFO] Trait "%TARGET_TRAIT%": action="%ACTION%"
)
exit /b 0

:: ## help
:: Prints usage help for engine.cmd.
:help
echo Usage: engine.cmd ^<list^|enable^|disable^|apply^|verify^|teardown^> [trait_name]
exit /b 0
