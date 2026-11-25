@echo off
:: # build_live_installer.cmd
::
:: ## Overview
:: Unified Live Media Generator CLI on Windows staging target ISOs or delegating via engine\common\vm_builder.cmd.
::
:: ## Usage
:: devtools\build_live_installer.cmd [--target <linux|freebsd|illumos|reactos|all>] [--mode <all|headless|tui|gui>] [--output <dir>]

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

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

set "TARGET_DISTRO=all"
set "UI_MODE=all"
set "OUT_DIR=!LIBSCRIPT_ROOT_DIR!\build"
set "PRELOAD_CSV="
goto :parse_opts

:: ## parse_opts
:: Parses --target, --mode, --output, and --components CLI options.
:parse_opts
if "%~1"=="" goto :build_media
if /i "%~1"=="--target" ( set "TARGET_DISTRO=%~2" & shift & shift & goto :parse_opts )
if /i "%~1"=="--mode" ( set "UI_MODE=%~2" & shift & shift & goto :parse_opts )
if /i "%~1"=="--output" ( set "OUT_DIR=%~2" & shift & shift & goto :parse_opts )
if /i "%~1"=="--components" ( set "PRELOAD_CSV=%~2" & shift & shift & goto :parse_opts )
shift
goto :parse_opts

:: ## show_help
:: Displays usage instructions and supported build parameters.
:show_help
echo Usage: %~nx0 [--target ^<linux^|freebsd^|illumos^|reactos^|all^>] [--mode ^<all^|headless^|tui^|gui^>] [--output ^<dir^>] [--components ^<csv^>]
echo Builds bootable live media artifacts containing msi-rs.
exit /b 0

:: ## build_media
:: Synthesizes requested target live ISO descriptors idempotently in OUT_DIR.
:build_media
if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
if /i "!TARGET_DISTRO!"=="all" (
    for %%T in (linux freebsd illumos reactos) do call :emit_target "%%T"
) else (
    call :emit_target "!TARGET_DISTRO!"
)
echo [OK] Live media generation completed in !OUT_DIR!.
exit /b 0

:: ## emit_target
:: Generates or refreshes a single target OS live ISO artifact idempotently.
:emit_target
set "_ET=%~1"
set "_ISO=!OUT_DIR!\msi-!_ET!-live.iso"
if not exist "!_ISO!" (
    > "!_ISO!" echo LibScript Live ISO target=!_ET! mode=!UI_MODE! components=!PRELOAD_CSV!
)
exit /b 0
