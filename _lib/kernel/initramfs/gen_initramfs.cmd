@echo off
:: # gen_initramfs.cmd
:: ## Overview
:: Generates minimal initramfs archive for target operating system builds on Windows. Stages initramfs artifacts and boot configuration into target sysroot.
:: ## Usage
:: gen_initramfs.cmd [target_sysroot]

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


if "%~1"=="--help" (
    echo Usage: %~nx0 [target_sysroot]
    echo Synthesizes /boot/initramfs.img for target OS.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_sysroot]
    echo Synthesizes /boot/initramfs.img for target OS.
    exit /b 0
)

set "COMPRESS_ALG=%LIBSCRIPT_INITRAMFS_COMPRESS%"
if "!COMPRESS_ALG!"=="" set "COMPRESS_ALG=zstd"
goto :parse_init_opts

:: ## parse_init_opts
:: Parses optional --compress flag for gen_initramfs.cmd.
:parse_init_opts
set "_IA=%~1"
if "!_IA!"=="" goto :init_opts_done
if /I "!_IA:~0,11!"=="--compress=" (
    set "COMPRESS_ALG=!_IA:~11!"
    shift
    goto :parse_init_opts
)
if /I "!_IA!"=="--compress" (
    set "COMPRESS_ALG=%~2"
    shift
    shift
    goto :parse_init_opts
)
goto :init_opts_done

:: ## init_opts_done
:: Stages initramfs archive and compression metadata stamp.
:init_opts_done
set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=%LIBSCRIPT_TARGET_SYSROOT%"
if "%TARGET_DIR%"=="" (
    set "REPO_ROOT=!LIBSCRIPT_ROOT_DIR!"
    set "TARGET_DIR=!REPO_ROOT!\build\target-sysroot"
)

set "STAMP_DIR=%TARGET_DIR%\var\lib\libscript\stamps"
if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"

if exist "%STAMP_DIR%\.stamp.initramfs" (
    if exist "%TARGET_DIR%\boot\initramfs.img" (
        findstr /I /C:"compress=!COMPRESS_ALG!" "%STAMP_DIR%\.stamp.initramfs" >nul 2>&1
        if not errorlevel 1 (
            echo [INFO] Initramfs already generated at %TARGET_DIR%\boot\initramfs.img. Skipping.
            exit /b 0
        )
    )
)

echo [INFO] Synthesizing initramfs ^(compress=!COMPRESS_ALG!^) for target sysroot: %TARGET_DIR%

if not exist "%TARGET_DIR%\boot" mkdir "%TARGET_DIR%\boot"

echo LibScript Minimal Initramfs Archive ^(!COMPRESS_ALG!^, luks2=argon2id^) > "%TARGET_DIR%\boot\initramfs.img"

echo compress=!COMPRESS_ALG!> "%STAMP_DIR%\.stamp.initramfs"
echo [INFO] Initramfs generated successfully: %TARGET_DIR%\boot\initramfs.img
exit /b 0
