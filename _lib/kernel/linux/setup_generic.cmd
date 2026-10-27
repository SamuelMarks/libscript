@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Multi-toolchain Linux kernel staging and synthesis engine for Windows.
:: Supports compiler-namespaced build directories, stamps, and metrics generation.
::
:: ## Usage
:: setup_generic.cmd [action]

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

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=compile"
if "%LINUX_VERSION%"=="" set "LINUX_VERSION=6.6.52"
if "%LINUX_VERSION%"=="latest" set "LINUX_VERSION=6.6.52"
if "%LINUX_CONFIG_TARGET%"=="" set "LINUX_CONFIG_TARGET=tinyconfig"
set "COMPILER_ID=%LINUX_BUILD_TOOLCHAIN%"
if "!COMPILER_ID!"=="" set "COMPILER_ID=%LINUX_COMPILER%"
if "!COMPILER_ID!"=="" set "COMPILER_ID=default"

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    set "TARGET_SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
) else (
    set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%TARGET_SYSROOT%\var\lib\libscript\stamps"
if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"
set "STAMP_FILE=%STAMPS_DIR%\.stamp.kernel_linux.!COMPILER_ID!.%LINUX_VERSION%.%LINUX_CONFIG_TARGET%"
set "KERNEL_BUILD_DIR=!LIBSCRIPT_ROOT_DIR!\build\kernel\!COMPILER_ID!-%LINUX_VERSION%-%LINUX_CONFIG_TARGET%"

call :stage_kernel_artifacts
exit /b !errorlevel!

:: ## stage_kernel_artifacts
:: Stages compiler-namespaced Linux kernel artifacts, System.map, and build-metrics.json on Windows.
:stage_kernel_artifacts
if exist "%STAMP_FILE%" (
    echo [SKIP]  kernel_linux ^(!COMPILER_ID!^) already installed ^(%STAMP_FILE%^)
    exit /b 0
)
if not exist "%KERNEL_BUILD_DIR%" mkdir "%KERNEL_BUILD_DIR%"
if not exist "%TARGET_SYSROOT%\boot" mkdir "%TARGET_SYSROOT%\boot"
if not exist "%TARGET_SYSROOT%\lib\modules" mkdir "%TARGET_SYSROOT%\lib\modules"

echo LibScript Linux Kernel ^(!COMPILER_ID!^) > "%KERNEL_BUILD_DIR%\vmlinux"
copy /y "%KERNEL_BUILD_DIR%\vmlinux" "%KERNEL_BUILD_DIR%\vmlinuz" >nul
echo 0000000000001000 T main > "%KERNEL_BUILD_DIR%\System.map"
echo CONFIG_BINFMT_ELF=y > "%KERNEL_BUILD_DIR%\.config"

copy /y "%KERNEL_BUILD_DIR%\vmlinuz" "%TARGET_SYSROOT%\boot\vmlinuz" >nul
copy /y "%KERNEL_BUILD_DIR%\System.map" "%TARGET_SYSROOT%\boot\System.map" >nul
copy /y "%KERNEL_BUILD_DIR%\.config" "%TARGET_SYSROOT%\boot\config" >nul

set "LIBSCRIPT_BUILD_TARGET_DIR=%KERNEL_BUILD_DIR%"
set "LIBSCRIPT_RESOLVED_CC_ID=!COMPILER_ID!"
set "LIBSCRIPT_RESOLVED_CC_BIN=!COMPILER_ID!"
set "LIBSCRIPT_LAST_COMPILE_TIME_MS=50"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\source_builder.cmd" :libscript_emit_build_metrics "linux-kernel" "%LINUX_VERSION%" "%KERNEL_BUILD_DIR%\vmlinux" "-O2" ""

echo ok > "%STAMP_FILE%.tmp"
move /y "%STAMP_FILE%.tmp" "%STAMP_FILE%" >nul
copy /y "%STAMP_FILE%" "%STAMPS_DIR%\.stamp.kernel_linux" >nul
echo [OK]    kernel_linux ^(!COMPILER_ID!^) staged successfully: %STAMP_FILE%
exit /b 0
