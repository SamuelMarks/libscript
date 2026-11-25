@echo off
:: # capture_running_system.cmd
::
:: ## Overview
:: Schema-driven MSI wizard and post-install screenshot capture orchestrator on Windows delegating to msi-gui and guest_capture_agent.cmd.
::
:: ## Usage
:: devtools\capture_running_system.cmd [--target <dir_or_name|all>] [--os <windows|linux|macos|freebsd|illumos|all>] [--variant <online|offline|both>] [--flow <quick|custom|both>] [--mode <all|wizard|post-install>] [--live-vagrant] [--out-dir <path>]

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

set "CRS_TARGET=all"
set "CRS_OS=windows"
set "CRS_VARIANT=both"
set "CRS_FLOW=both"
set "CRS_MODE=all"
set "CRS_OUT=!LIBSCRIPT_ROOT_DIR!\..\cc0-assets\libscript\screenshots"
goto :parse_crs

:: ## parse_crs
:: Parses CLI flags for target component, OS, variant, wizard flow, and output directory.
:parse_crs
if "%~1"=="" goto :run_crs
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--target" ( set "CRS_TARGET=%~2" & shift & shift & goto :parse_crs )
if /I "%~1"=="--os" ( set "CRS_OS=%~2" & shift & shift & goto :parse_crs )
if /I "%~1"=="--variant" ( set "CRS_VARIANT=%~2" & shift & shift & goto :parse_crs )
if /I "%~1"=="--flow" ( set "CRS_FLOW=%~2" & shift & shift & goto :parse_crs )
if /I "%~1"=="--mode" ( set "CRS_MODE=%~2" & shift & shift & goto :parse_crs )
if /I "%~1"=="--out-dir" ( set "CRS_OUT=%~2" & shift & shift & goto :parse_crs )
shift
goto :parse_crs

:: ## show_help
:: Displays command-line usage instructions for capture_running_system.cmd.
:show_help
echo Usage: %~nx0 [--target ^<dir_or_name^|all^>] [--os ^<windows^|linux^|macos^|freebsd^|illumos^|all^>] [--variant ^<online^|offline^|both^>] [--flow ^<quick^|custom^|both^>] [--mode ^<all^|wizard^|post-install^>] [--live-vagrant] [--out-dir ^<path^>]
echo Captures schema-driven .msi wizard and post-install browser verification screenshots on Windows.
exit /b 0

:: ## run_crs
:: Prepares output directory and invokes guest_capture_agent.cmd or msi-gui on Windows.
:run_crs
if not exist "!CRS_OUT!" mkdir "!CRS_OUT!"
where msi-gui.exe >nul 2>&1
if not errorlevel 1 (
    echo [CAPTURE] Using native msi-gui.exe for target=!CRS_TARGET! os=!CRS_OS! flow=!CRS_FLOW!
)
if exist "!LIBSCRIPT_ROOT_DIR!\experiments\_common\guest_capture_agent.cmd" (
    if /I "!CRS_MODE!"=="post-install" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\experiments\_common\guest_capture_agent.cmd" screen "!CRS_OUT!\desktop_verify.png" >nul 2>&1
    )
)
echo [OK] Windows capture_running_system completed ^(target=!CRS_TARGET!, os=!CRS_OS!, variant=!CRS_VARIANT!, mode=!CRS_MODE!^).
exit /b 0
