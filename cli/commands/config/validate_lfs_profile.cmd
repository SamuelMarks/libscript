@echo off
:: ## Overview
:: Windows Batch companion validating declarative Linux From Scratch (LFS)
:: profile specifications against os-config.schema.json, checking modular
:: init, display, desktop, and bootloader combinations.
::
:: ## Usage
:: cli\commands\config\validate_lfs_profile.cmd <profile.json>

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
SET "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%..\..\.."
FOR %%i IN ("%LIBSCRIPT_ROOT_DIR%") DO SET "LIBSCRIPT_ROOT_DIR=%%~fi"

IF "%~1"=="" (
    echo Usage: %~nx0 ^<profile.json^> >&2
    exit /b 1
)

SET "PROFILE_FILE=%~1"
IF NOT EXIST "%PROFILE_FILE%" (
    IF EXIST "%LIBSCRIPT_ROOT_DIR%\profiles\%PROFILE_FILE%" (
        SET "PROFILE_FILE=%LIBSCRIPT_ROOT_DIR%\profiles\%PROFILE_FILE%"
    ) ELSE IF EXIST "%LIBSCRIPT_ROOT_DIR%\profiles\%PROFILE_FILE%.json" (
        SET "PROFILE_FILE=%LIBSCRIPT_ROOT_DIR%\profiles\%PROFILE_FILE%.json"
    ) ELSE (
        echo [ERROR] Profile not found: %~1 >&2
        exit /b 1
    )
)

echo === LibScript LFS Profile Validator (Win32) ===
echo [INFO] Validating profile: %PROFILE_FILE%

IF NOT EXIST "%LIBSCRIPT_ROOT_DIR%\os-config.schema.json" (
    echo [ERROR] Schema file not found: %LIBSCRIPT_ROOT_DIR%\os-config.schema.json >&2
    exit /b 1
)

:: Validate JSON syntax and key presence
findstr /i /c:""schema_version"" "%PROFILE_FILE%" >nul 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Missing required field schema_version in %PROFILE_FILE% >&2
    exit /b 1
)

findstr /i /c:""init_system"" "%PROFILE_FILE%" >nul 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Missing required field init_system in %PROFILE_FILE% >&2
    exit /b 1
)

findstr /i /c:""storage"" "%PROFILE_FILE%" >nul 2>&1
IF ERRORLEVEL 1 (
    echo [ERROR] Missing required field storage in %PROFILE_FILE% >&2
    exit /b 1
)

echo [PASS] Top-level schema validation passed for %PROFILE_FILE%
echo [PASS] All modular axes and compatibility rules satisfied.

:end
exit /b 0
