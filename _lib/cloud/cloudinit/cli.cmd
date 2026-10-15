@echo off
:: # cli.cmd
::
:: ## Overview
:: Cloud-init component CLI for generating OS configurations on Windows.
::
:: ## Usage
:: libscript cloudinit generate-mount [--device path] [--mount-point path] [--fs-type type]
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

set "CMD=%~1"
if not "%CMD%"=="" shift

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto validate_args
if /i "%~1"=="cloudinit" (
    shift
    goto parse_args
)
if "%~1"=="--device" ( set "LIBSCRIPT_DEVICE=%~2" & shift & shift & goto parse_args )
if "%~1"=="--mount-point" ( set "LIBSCRIPT_MOUNT_POINT=%~2" & shift & shift & goto parse_args )
if "%~1"=="--fs-type" ( set "LIBSCRIPT_FS_TYPE=%~2" & shift & shift & goto parse_args )

echo %~1 | findstr /b /c:"--device=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_DEVICE=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--mount-point=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_MOUNT_POINT=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--fs-type=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_FS_TYPE=%%A" & shift & goto parse_args )

echo Error: Unknown argument '%~1' >&2
exit /b 1

:: ## validate_args
:: Validates required command-line arguments and configuration parameters.
:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for cloudinit ^(generate-mount^). >&2
    exit /b 1
)

if /i "%CMD%"=="install" (
    echo Cloud components are operational wrappers and do not require installation.
    exit /b 0
)
if /i "%CMD%"=="test" (
    echo Running mock test for cloudinit...
    exit /b 0
)

if "%CMD%"=="generate-mount" goto execute

echo Error: Unknown cloudinit command '%CMD%' >&2
exit /b 1

:: ## execute
:: Executes the primary orchestration workflow for this script.
:execute
call "%~dp0api.cmd" :libscript_cloudinit_generate_mount "%LIBSCRIPT_DEVICE%" "%LIBSCRIPT_MOUNT_POINT%" "%LIBSCRIPT_FS_TYPE%"
exit /b %errorlevel%
