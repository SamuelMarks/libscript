@echo off
:: # regen_all_screenshots.cmd
::
:: ## Overview
:: Thin declarative caller that regenerates all .msi wizard stages and post-install
:: desktop and browser verification screenshots across all components and OS platforms
:: via devtools\capture_running_system.cmd.
::
:: ## Usage
:: call devtoolsegen_all_screenshots.cmd [OPTIONS]

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if /I "%~1"=="--help" goto :help
if /I "%~1"=="-h" goto :help
if /I "%~1"=="/?" goto :help
if /I "%~1"=="-?" goto :help
goto :main

:: ## help
:: Prints the help message and exits.
:help
call "!SCRIPT_DIR!\capture_running_system.cmd" --help
exit /b 0

:: ## main
:: Delegates full screenshot regeneration to capture_running_system.cmd.
:main
call "!SCRIPT_DIR!\capture_running_system.cmd" --target all --os all --variant both --flow both --mode all %*
exit /b !ERRORLEVEL!
