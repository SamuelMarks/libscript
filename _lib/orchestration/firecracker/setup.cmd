@echo off
:: # setup.cmd
::
:: ## Overview
:: Firecracker MicroVM provider on Windows.
:: Configures microVM specifications and delegates hardware virtualization to vm_builder worker.
::
:: ## Usage
:: setup.cmd [action] [kernel_vmlinux] [rootfs_img] [socket_path] [tap_device]

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
    echo Usage: %~nx0 [action] [kernel] [rootfs]
    echo Firecracker MicroVM provider.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [action] [kernel] [rootfs]
    echo Firecracker MicroVM provider.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\_lib\orchestration\firecracker\setup.sh" %*
exit /b %ERRORLEVEL%
