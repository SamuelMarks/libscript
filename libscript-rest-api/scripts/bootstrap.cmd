@echo off
:: # bootstrap.cmd
::
:: ## Overview
:: Dependency resolution script for bootstrapping the libscript REST API development environment on Windows.
::
:: ## Usage
:: Run via: `.\scripts\bootstrap.cmd`

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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
goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0
echo Dependency resolution script for bootstrapping the libscript REST API development environment on Windows.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes the primary orchestration workflow for this script.
:main
echo [INFO] Detected Windows. Checking for required build tools...

:: Check for Git
where git >nul 2>&1
if errorlevel 1 (
    echo [INFO] Git not found. Attempting to install via libscript...
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install git latest
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\git-servers\git\env.cmd" call "%LIBSCRIPT_ROOT_DIR%\_lib\git-servers\git\env.cmd"
) else (
    echo [INFO] Git is already installed.
)

:: Check for CMake
where cmake >nul 2>&1
if errorlevel 1 (
    echo [INFO] CMake not found. Attempting to install via libscript...
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install cmake latest
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\cmake\env.cmd" call "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\cmake\env.cmd"
) else (
    echo [INFO] CMake is already installed.
)

:: Check for C Compiler
where cl >nul 2>&1
if errorlevel 1 (
    echo [INFO] MSVC compiler ^(cl.exe^) not found in PATH.
    echo [INFO] Attempting to install via libscript...
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install c latest
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\languages\c\env.cmd" call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\c\env.cmd"
    echo [INFO] NOTE: You may need to run this script from a 'x64 Native Tools Command Prompt for VS' after installation.
) else (
    echo [INFO] MSVC compiler is already installed.
)

:: Check for jq
where jq >nul 2>&1
if errorlevel 1 (
    echo [INFO] jq not found. Attempting to install via libscript...
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install jq latest
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\utilities\jq\env.cmd" call "%LIBSCRIPT_ROOT_DIR%\_lib\utilities\jq\env.cmd"
) else (
    echo [INFO] jq is already installed.
)

echo [INFO] Dependency resolution complete. C compiler, git, and cmake are ready.

:: Fetch c-rest-framework
set "VENDOR_DIR=%SCRIPT_DIR%\..\vendor"
if not exist "%VENDOR_DIR%" mkdir "%VENDOR_DIR%"
if not exist "%VENDOR_DIR%\c-rest-framework\.git" (
    echo [INFO] Cloning c-rest-framework into vendor directory...
    git clone https://github.com/SamuelMarks/c-rest-framework "%VENDOR_DIR%\c-rest-framework"
) else (
    echo [INFO] c-rest-framework already cloned. Pulling latest...
    pushd "%VENDOR_DIR%\c-rest-framework"
    git fetch --all
    git reset --hard @{upstream}
    popd
)

echo [INFO] Framework acquisition complete.
