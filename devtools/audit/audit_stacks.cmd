@echo off
:: # audit_stacks.cmd
:: ## Overview
:: Zero-PowerShell Windows Batch stack, constellation, and payload README auditor.
:: ## Usage
:: devtools\audit\audit_stacks.cmd [--fix] [--strict]

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

set "FIX_MODE=0"
set "STRICT_MODE=0"
goto :parse_args

:: ## parse_args
:: Parses CLI flags for audit_stacks.cmd.
:parse_args
if "%~1"=="" goto :run_audit
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--fix" set "FIX_MODE=1"
if /I "%~1"=="--strict" set "STRICT_MODE=1"
shift
goto :parse_args

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [--fix] [--strict]
echo Performs an audit and validation of all defined application stacks.
echo.
echo Options:
echo   --fix               Append missing Orchestrated Components section stub to README.md.
echo   --strict            Exit with status 1 if any stack README violations are found.
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## run_audit
:: Iterates over workloads\apps, workloads\constellations, and workloads\payloads directories.
:run_audit
set "STACK_ERRORS=0"
if exist "!LIBSCRIPT_ROOT_DIR!\workloads\apps" (
    for /d %%S in ("!LIBSCRIPT_ROOT_DIR!\workloads\apps\*") do call :check_stack_dir "%%~fS" "%%~nxS"
)
if exist "!LIBSCRIPT_ROOT_DIR!\workloads\constellations" (
    for /d %%S in ("!LIBSCRIPT_ROOT_DIR!\workloads\constellations\*") do call :check_stack_dir "%%~fS" "%%~nxS"
)
if exist "!LIBSCRIPT_ROOT_DIR!\workloads\payloads" (
    for /d %%C in ("!LIBSCRIPT_ROOT_DIR!\workloads\payloads\*") do (
        for /d %%S in ("%%~fC\*") do call :check_stack_dir "%%~fS" "%%~nxS"
    )
)
echo Stack audit complete.
if "!STRICT_MODE!"=="1" if not "!STACK_ERRORS!"=="0" exit /b 1
exit /b 0

:: ## check_stack_dir
:: Validates that a stack directory has a README.md documenting orchestrated components.
:check_stack_dir
set "_SD=%~1"
set "_SN=%~2"
if not exist "!_SD!\README.md" (
    echo WARNING: Stack !_SN! is missing a README.md
    set /a STACK_ERRORS+=1
    exit /b 0
)
findstr /I /C:"components" /C:"orchestrates" /C:"libscript.json" "!_SD!\README.md" >nul 2>&1
if errorlevel 1 (
    echo WARNING: Stack !_SN! README may not explicitly list orchestrated _lib components or libscript.json usage.
    set /a STACK_ERRORS+=1
    if "!FIX_MODE!"=="1" (
        echo.>> "!_SD!\README.md"
        echo ## Orchestrated Components>> "!_SD!\README.md"
        echo This stack orchestrates the following LibScript components:>> "!_SD!\README.md"
        echo - ^(Please document required components here^)>> "!_SD!\README.md"
    )
)
exit /b 0
