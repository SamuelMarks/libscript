@echo off
:: # audio.cmd
::
:: ## Overview
:: Configures audio subsystems (native FreeBSD OSS, PipeWire, or none)
:: inside FreeBSD target sysroot on Windows environments.
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
    echo Configures FreeBSD audio subsystem.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [sysroot_path] [subsystem]
    echo Configures FreeBSD audio subsystem.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%REPO_ROOT%\build\freebsd-sysroot"
set "SUBSYSTEM=%~2"
if "%SUBSYSTEM%"=="" set "SUBSYSTEM=oss"

set "STAMP_DIR=%SYSROOT%\.libscript_stamps"
set "STAMP_FILE=%STAMP_DIR%\audio_%SUBSYSTEM%.stamp"

if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"
if not exist "%SYSROOT%\boot" mkdir "%SYSROOT%\boot"
if not exist "%SYSROOT%\etc" mkdir "%SYSROOT%\etc"

if exist "%STAMP_FILE%" (
    echo [SKIP]     FreeBSD audio subsystem %SUBSYSTEM% already configured in %SYSROOT%
    exit /b 0
)

echo [AUDIO]    Configuring audio subsystem: %SUBSYSTEM%...

if "%SUBSYSTEM%"=="oss" (
    echo snd_driver_load="YES">> "%SYSROOT%\boot\loader.conf"
    echo add path 'dsp*' mode 0666 group audio>> "%SYSROOT%\etc\devfs.rules"
)
if "%SUBSYSTEM%"=="pipewire" (
    echo snd_driver_load="YES">> "%SYSROOT%\boot\loader.conf"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       Audio subsystem %SUBSYSTEM% configured.
exit /b 0
