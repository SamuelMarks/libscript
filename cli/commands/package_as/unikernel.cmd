@echo off
:: # unikernel.cmd
::
:: ## Overview
:: Packages user application and runtime payload into a standalone ELF unikernel
:: microkernel binary on Windows for Firecracker and Cloud-Hypervisor.
::
:: ## Usage
:: unikernel.cmd [app_dir_or_sysroot] [output_elf]

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
    echo Usage: %~nx0 [app_dir_or_sysroot] [output_elf]
    echo Synthesizes standalone unikernel ELF binary.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [app_dir_or_sysroot] [output_elf]
    echo Synthesizes standalone unikernel ELF binary.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\cli\commands\package_as\unikernel.sh" %*
exit /b %ERRORLEVEL%
