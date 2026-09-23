@echo off
:: # setup.cmd
::
:: ## Overview
:: Solo5 and MirageOS tender execution engine on Windows.
:: Configures unikernel execution parameters and delegates virtualization to vm_builder worker.
::
:: ## Usage
:: setup.cmd [action] [unikernel_bin] [tender_type]

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
    echo Usage: %~nx0 [action] [unikernel_bin] [tender_type]
    echo Solo5 and MirageOS tender execution engine.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [action] [unikernel_bin] [tender_type]
    echo Solo5 and MirageOS tender execution engine.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\_lib\orchestration\solo5\setup.sh" %*
exit /b %ERRORLEVEL%
