@echo off
:: # env.cmd
::
:: ## Overview
:: Windows environment configuration and PATH setup for zephyr-sdk.
::
:: ## Usage
:: call _lib\toolchains\zephyr-sdk\env.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%ZEPHYR_SDK_VERSION%"=="" (
    set "ZEPHYR_SDK_VERSION=0.17.0"
)
if "%ZEPHYR_SDK_INSTALL_DIR%"=="" (
    set "ZEPHYR_SDK_INSTALL_DIR=%LIBSCRIPT_HOME%\zephyr-sdk\%ZEPHYR_SDK_VERSION%"
)
if "%ZEPHYR_TOOLCHAIN_VARIANT%"=="" (
    set "ZEPHYR_TOOLCHAIN_VARIANT=zephyr"
)

for %%D in (
    "%ZEPHYR_SDK_INSTALL_DIR%\bin"
    "%ZEPHYR_SDK_INSTALL_DIR%\arm-zephyr-eabi\bin"
    "%ZEPHYR_SDK_INSTALL_DIR%\aarch64-zephyr-elf\bin"
    "%ZEPHYR_SDK_INSTALL_DIR%\x86_64-zephyr-elf\bin"
    "%ZEPHYR_SDK_INSTALL_DIR%\riscv64-zephyr-elf\bin"
) do (
    if exist "%%~D" (
        echo ";!PATH!;" | findstr /I /C:";%%~D;" >nul 2>&1
        if errorlevel 1 set "PATH=%%~D;!PATH!"
    )
)
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "zephyr-sdk" "%ZEPHYR_SDK_VERSION%"

endlocal & (
    set "ZEPHYR_SDK_VERSION=%ZEPHYR_SDK_VERSION%"
    set "ZEPHYR_SDK_INSTALL_DIR=%ZEPHYR_SDK_INSTALL_DIR%"
    set "ZEPHYR_TOOLCHAIN_VARIANT=%ZEPHYR_TOOLCHAIN_VARIANT%"
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "PATH=%PATH%"
)
exit /b 0
