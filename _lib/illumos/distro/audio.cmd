@echo off
:: # audio.cmd
::
:: ## Overview
:: Configures audio subsystem (Boomer, OSS, or none) inside illumos sysroot
:: on Windows host environments.
::
:: ## Usage
:: audio.cmd [sysroot_path] [subsystem]

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
    echo Usage: %~nx0 [sysroot_path] [subsystem]
    echo Configures illumos audio subsystem.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [subsystem]
    echo Configures illumos audio subsystem.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\illumos-sysroot"
set "SUBSYSTEM=%~2"
if "%SUBSYSTEM%"=="" set "SUBSYSTEM=none"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\audio.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"

if exist "%STAMP_FILE%" (
    echo [SKIP]     illumos audio subsystem %SUBSYSTEM% already configured in %SYSROOT%
    exit /b 0
)

echo [AUDIO]    Configuring illumos audio subsystem %SUBSYSTEM%...

echo AUDIO_SUBSYSTEM="%SUBSYSTEM%"> "%SYSROOT%/etc/audio.conf"

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos audio configuration complete.
exit /b 0
