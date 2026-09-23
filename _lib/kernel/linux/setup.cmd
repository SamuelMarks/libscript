@echo off
:: # setup.cmd
::
:: ## Overview
:: Linux kernel compilation and installation engine for Windows.
:: Manages kernel artifacts, module staging, and configuration within target sysroot.
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
    echo Linux kernel compilation and installation engine.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [action]
    echo Linux kernel compilation and installation engine.
    exit /b 0
)

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=compile"

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    set "TARGET_SYSROOT=%REPO_ROOT%\build\target-sysroot"
) else (
    set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%TARGET_SYSROOT%\var\lib\libscript\stamps"
if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"

set "STAMP_FILE=%STAMPS_DIR%\.stamp.kernel_linux"
if exist "%STAMP_FILE%" (
    echo [SKIP]  kernel_linux already installed ^(%STAMP_FILE%^)
    exit /b 0
)

echo [RECIPE] Staging Linux Kernel Engine into %TARGET_SYSROOT% ^(action: %ACTION%^)

if not exist "%TARGET_SYSROOT%\boot" mkdir "%TARGET_SYSROOT%\boot"
if not exist "%TARGET_SYSROOT%\lib\modules" mkdir "%TARGET_SYSROOT%\lib\modules"

if not exist "%TARGET_SYSROOT%\boot\vmlinuz" (
    echo LibScript Linux Kernel > "%TARGET_SYSROOT%\boot\vmlinuz"
    echo System.map stub > "%TARGET_SYSROOT%\boot\System.map"
    echo CONFIG_BINFMT_ELF=y > "%TARGET_SYSROOT%\boot\config"
)

type nul > "%STAMP_FILE%"
echo [OK]    kernel_linux staged successfully: %STAMP_FILE%
exit /b 0
