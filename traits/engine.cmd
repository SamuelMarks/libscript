@echo off
:: # engine.cmd
::
:: ## Overview
:: Core Unified Traits Engine resolving priority order and dispatching traits on Windows,
:: including manifest-driven storage and ingress trait execution.
::
:: ## Usage
:: traits\engine.cmd <list|enable|disable|apply|verify|teardown> [trait_name] [--manifest <libscript.json>]

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
set "MANIFEST_FILE="
if "%ACTION%"=="" set "ACTION=list"
if "%TARGET_TRAIT%"=="" set "TARGET_TRAIT=all"

for %%A in (%2 %3 %4 %5 %6) do (
    set "_ta=%%~A"
    if /i "!_ta:~0,11!"=="--manifest=" set "MANIFEST_FILE=!_ta:~11!"
)
if /i "%~2"=="--manifest" (
    set "TARGET_TRAIT=all"
    set "MANIFEST_FILE=%~3"
)
if /i "%~3"=="--manifest" set "MANIFEST_FILE=%~4"

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
        call :run_single_trait "%%T" "%ACTION%"
    )
) else (
    call :run_single_trait "%TARGET_TRAIT%" "%ACTION%"
)
exit /b 0

:: ## run_single_trait
:: Dispatches a single trait action to the concrete trait script.
:run_single_trait
set "_T_NAME=%~1"
set "_T_ACT=%~2"
echo [INFO] Trait "!_T_NAME!": action="!_T_ACT!"
if /i "%DRY_RUN%"=="true" exit /b 0
if "%DRY_RUN%"=="1" exit /b 0
if /i "!_T_NAME!"=="storage" (
    if /i "!_T_ACT!"=="apply" (
        if not "!MANIFEST_FILE!"=="" (
            if exist "!MANIFEST_FILE!" (
                set "STACK="
                call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" prepare-storage "!MANIFEST_FILE!"
            )
        )
    )
)
if /i "!_T_NAME!"=="ingress" (
    if not "!MANIFEST_FILE!"=="" (
        if exist "!MANIFEST_FILE!" (
            if /i "!_T_ACT!"=="apply" (
                set "STACK="
                call "!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\cli.cmd" apply "!MANIFEST_FILE!" --reload
            )
            if /i "!_T_ACT!"=="teardown" (
                set "STACK="
                call "!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\cli.cmd" remove-ingress "!MANIFEST_FILE!" --reload
            )
        )
    )
)
exit /b 0

:: ## help
:: Prints usage help for engine.cmd.
:help
echo Usage: engine.cmd ^<list^|enable^|disable^|apply^|verify^|teardown^> [trait_name] [--manifest ^<libscript.json^>]
exit /b 0
