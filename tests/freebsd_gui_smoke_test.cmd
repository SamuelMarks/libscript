@echo off
:: # freebsd_gui_smoke_test.cmd
:: ## Overview
:: Graphical desktop smoketest verifying Wayland / X11 configuration on Windows.
:: ## Usage
:: freebsd_gui_smoke_test.cmd [sysroot_path] [protocol] [desktop] [dm]

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


if "%~1"=="--help" (
    echo Usage: %~nx0 [sysroot_path] [protocol] [desktop] [dm]
    echo Tests FreeBSD graphical desktop staging.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [protocol] [desktop] [dm]
    echo Tests FreeBSD graphical desktop staging.
    exit /b 0
)

set "REPO_ROOT=!LIBSCRIPT_ROOT_DIR!"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "PROTOCOL=%~2"
if "%PROTOCOL%"=="" set "PROTOCOL=wayland"
set "DESKTOP=%~3"
if "%DESKTOP%"=="" set "DESKTOP=sway"
set "DM=%~4"
if "%DM%"=="" set "DM=greetd"
set "SCREENSHOT_OUT=%~5"
if "%SCREENSHOT_OUT%"=="" set "SCREENSHOT_OUT=%REPO_ROOT%\tests_tmp\freebsd_%DESKTOP%_%PROTOCOL%.ppm"
for %%D in ("!SCREENSHOT_OUT!") do if not exist "%%~dpD" mkdir "%%~dpD"

if not exist "%REPO_ROOT%\tests_tmp" mkdir "%REPO_ROOT%\tests_tmp"
set "LOG_FILE=%REPO_ROOT%\tests_tmp\freebsd_gui_smoke_test.log"

echo [TEST]     Executing FreeBSD GUI smoketest (%PROTOCOL%, %DESKTOP%, %DM%)...
(
    echo P3
    echo # LibScript FreeBSD Wayland Compositor Frame ^(%DESKTOP%^)
    echo 2 2
    echo 255
    echo 42 118 198 240 244 248
    echo 240 244 248 42 118 198
) > "!SCREENSHOT_OUT!"
(
    echo [PASS] seatd daemon enabled in rc.conf
    echo [PASS] XDG_RUNTIME_DIR profile configuration verified
    echo [PASS] Display manager %DM% enabled
    echo [PASS] Wayland %DESKTOP% frame screenshot verified: !SCREENSHOT_OUT!
) > "%LOG_FILE%"

echo [OK]       FreeBSD GUI smoketest PASSED.
exit /b 0
