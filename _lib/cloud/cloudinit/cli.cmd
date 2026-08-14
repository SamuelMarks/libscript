@echo off
:: # cli.cmd
::
:: ## Overview
:: Cloud-init component CLI for generating OS configurations on Windows.
::
:: ## Usage
:: libscript cloudinit generate-mount [--device path] [--mount-point path] [--fs-type type]

set "CMD=%~1"
if not "%CMD%"=="" shift

:: ## parse_args
:: Executes parse_args functionality.
:parse_args
if "%~1"=="" goto validate_args
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
:: Executes validate_args functionality.
:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for cloudinit (generate-mount^). >&2
    exit /b 1
)

if "%CMD%"=="generate-mount" goto execute

echo Error: Unknown cloudinit command '%CMD%' >&2
exit /b 1

:: ## execute
:: Executes execute functionality.
:execute
call "%~dp0api.cmd" :libscript_cloudinit_generate_mount "%LIBSCRIPT_DEVICE%" "%LIBSCRIPT_MOUNT_POINT%" "%LIBSCRIPT_FS_TYPE%"
exit /b %errorlevel%
