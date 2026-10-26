@echo off
:: # verify_screenshots.cmd
::
:: ## Overview
:: Verifies that all generated .msi GUI and post-install browser/desktop verification
:: screenshots in ..\cc0-assets\libscript exist, are non-empty, have valid PNG headers,
:: match every .verification_screenshots[] item declared in <target_dir>\packaging.json,
:: and are tightly cropped across all target OS directories.
::
:: ## Usage
:: devtools\verify_screenshots.cmd [--target <name|dir|all>] [--dir <path>]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help

where sh.exe >nul 2>&1
if not errorlevel 1 (
    sh.exe "!SCRIPT_DIR!\verify_screenshots.sh" %*
    exit /b !ERRORLEVEL!
)

echo [ERROR] POSIX sh is required to run verify_screenshots. >&2
exit /b 1

:: ## show_help
:: Displays usage instructions for verify_screenshots.cmd.
:show_help
echo Usage: %~nx0 [--target ^<name^|dir^|all^>] [--dir ^<path^>]
echo Validates PNG headers, file sizes, declared verification_screenshots, and cropped dimensions.
exit /b 0
