@echo off
:: # iso.cmd
::
:: ## Overview
:: Packages target sysroot into a live bootable ISO 9660 hybrid media image
:: on Windows by delegating to the vm_builder worker.
::
:: ## Usage
:: iso.cmd [target_sysroot] [output_iso] [volume_id]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

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
    echo Usage: %~nx0 [target_sysroot] [output_iso] [volume_id]
    echo Synthesizes live bootable ISO image.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_sysroot] [output_iso] [volume_id]
    echo Synthesizes live bootable ISO image.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\cli\commands\package_as\iso.sh" %*
exit /b %ERRORLEVEL%
