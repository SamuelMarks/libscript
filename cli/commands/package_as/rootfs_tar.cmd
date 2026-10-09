@echo off
:: # rootfs_tar.cmd
::
:: ## Overview
:: Packages target sysroot into a compressed rootfs tarball on Windows.
:: Generates container and jail import archives.
::
:: ## Usage
:: rootfs_tar.cmd [target_sysroot] [output_tarball] [compression]

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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [target_sysroot] [output_tarball] [compression]
    echo Synthesizes compressed rootfs tarball.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_sysroot] [output_tarball] [compression]
    echo Synthesizes compressed rootfs tarball.
    exit /b 0
)

for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\cli\commands\package_as\rootfs_tar.sh" %*
exit /b %ERRORLEVEL%
