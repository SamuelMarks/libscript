@echo off
:: # deprovision.cmd
::
:: ## Overview
:: Tears down and deprovisions cloud infrastructure resources on Windows.
:: Performs idempotent infrastructure destruction and resource reclamation.
:: 
:: ## Usage
:: Execute `deprovision.cmd [provider] [node_name] [resource_group] [region]`

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
    echo Usage: %~nx0 [provider] [node_name] [resource_group] [region]
    echo Tears down and deprovisions cloud infrastructure resources.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [provider] [node_name] [resource_group] [region]
    echo Tears down and deprovisions cloud infrastructure resources.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\teardown_cloud.cmd" %*
exit /b %ERRORLEVEL%
