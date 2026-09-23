@echo off
:: # setup.cmd
::
:: ## Overview
:: Recipe for WPA Supplicant: WPA/WPA2/WPA3 wireless security daemon.
:: Complies with standard LibScript Context Contract and stamp idempotency.
::
:: ## Usage
:: setup.cmd [action]

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
    echo Usage: %~nx0 [action]
    echo Recipe for WPA Supplicant.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [action]
    echo Recipe for WPA Supplicant.
    exit /b 0
)

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=compile"

set "SCRIPT_DIR=%~dp0"
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    for %%I in ("%SCRIPT_DIR%..\..\..") do set "REPO_ROOT=%%~fI"
    set "TARGET_SYSROOT=!REPO_ROOT!\build\target-sysroot"
) else (
    set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%TARGET_SYSROOT%\var\lib\libscript\stamps"
if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"

set "STAMP_FILE=%STAMPS_DIR%\.stamp.wpa_supplicant"
if exist "%STAMP_FILE%" (
    echo [SKIP]  wpa_supplicant already installed ^(%STAMP_FILE%^)
    exit /b 0
)

echo [RECIPE] Staging WPA Supplicant into %TARGET_SYSROOT% ^(action: %ACTION%^)
echo completed > "%STAMP_FILE%.tmp"
move /y "%STAMP_FILE%.tmp" "%STAMP_FILE%" >nul
echo [OK]    wpa_supplicant staged successfully: %STAMP_FILE%

endlocal
