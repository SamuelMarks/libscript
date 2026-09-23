@echo off
:: # qcow2.cmd
::
:: ## Overview
:: Packages raw disk images or sysroots into compressed virtual machine disk
:: images (qcow2, vmdk, vdi) on Windows via vm_builder worker or qemu-img.
::
:: ## Usage
:: qcow2.cmd [input_image_or_sysroot] [output_image] [target_format]

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
    echo Usage: %~nx0 [input_image_or_sysroot] [output_image] [target_format]
    echo Synthesizes compressed VM disk image.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [input_image_or_sysroot] [output_image] [target_format]
    echo Synthesizes compressed VM disk image.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\cli\commands\package_as\qcow2.sh" %*
exit /b %ERRORLEVEL%
