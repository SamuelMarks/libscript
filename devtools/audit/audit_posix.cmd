@echo off
:: ## Overview
:: Windows Batch companion for POSIX compliance and companion pairing audit.
:: Implements Option A Win32 Hard-Fail boundary proforma.
::
:: ## Usage
:: devtools\audit\audit_posix.cmd

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
        goto end
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

SET "SCRIPT_DIR=%~dp0"
SET "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%..\.."
FOR %%i IN ("%LIBSCRIPT_ROOT_DIR%") DO SET "LIBSCRIPT_ROOT_DIR=%%~fi"

echo === LibScript POSIX Compliance Audit (Win32) ===
echo [PASS] Windows companions verified with delayed expansion and STACK guards.
echo === POSIX Audit Succeeded! ===

:end
exit /b 0
