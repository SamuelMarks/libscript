@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup for win-cmd-asm (WINCMD1.COM, WINCMD.COM, 17 DOS utilities, vm8086, asm-conv).
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use, and uninstall capabilities.

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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%ACTION%"=="" set "ACTION=install"
if "%WIN_CMD_ASM_VERSION%"=="" set "WIN_CMD_ASM_VERSION=0.1.0"
call :resolve_version

if /I "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\win-cmd-asm" dir /b "%LIBSCRIPT_HOME%\win-cmd-asm"
    exit /b 0
)
if /I "%ACTION%"=="ls-remote" (
    echo 0.1.0
    exit /b 0
)
if /I "%ACTION%"=="download" (
    echo [INFO] win-cmd-asm !EXACT_VERSION! sources ready.
    exit /b 0
)
if /I "%ACTION%"=="use" (
    if not exist "%LIBSCRIPT_HOME%\win-cmd-asm\!EXACT_VERSION!\bin\asm-conv.exe" exit /b 1
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "win-cmd-asm" "default" "!EXACT_VERSION!"
    exit /b !errorlevel!
)
if /I "%ACTION%"=="bootstrap" goto :do_install
if /I "%ACTION%"=="compile" goto :do_install
if /I "%ACTION%"=="install" goto :do_install
if /I "%ACTION%"=="uninstall" (
    if exist "%LIBSCRIPT_HOME%\win-cmd-asm\!EXACT_VERSION!" rmdir /s /q "%LIBSCRIPT_HOME%\win-cmd-asm\!EXACT_VERSION!"
    exit /b 0
)
call "%LIBSCRIPT_ROOT_DIR%\engine\common\setup_base.cmd" :libscript_handle_generic_action "win-cmd-asm" "%ACTION%" "!EXACT_VERSION!" "from-source" "" "" "" "\"%LIBSCRIPT_HOME%\win-cmd-asm\!EXACT_VERSION!\bin\asm-conv.exe\"" "%LIBSCRIPT_HOME%\win-cmd-asm\!EXACT_VERSION!"
exit /b !errorlevel!

:: ## resolve_version
:: Normalizes WIN_CMD_ASM_VERSION into EXACT_VERSION.
:resolve_version
set "EXACT_VERSION=%WIN_CMD_ASM_VERSION%"
if /I "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=0.1.0"
if /I "!EXACT_VERSION!"=="stable" set "EXACT_VERSION=0.1.0"
if /I "!EXACT_VERSION!"=="lts" set "EXACT_VERSION=0.1.0"
exit /b 0

:: ## do_install
:: Builds asm-conv.exe and stages WINCMD1.COM, WINCMD.COM, and 17 DOS utilities idempotently.
:do_install
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "win-cmd-asm" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\bin\asm-conv.exe" if exist "!TARGET_DIR!\target-dos\dos125\WINCMD1.COM" if exist "!TARGET_DIR!\target-dos\dos16\WINCMD.COM" (
    if not "%FORCE_REINSTALL%"=="1" (
        call :stage_sysroot
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "win-cmd-asm" "%WIN_CMD_ASM_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "win-cmd-asm" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
if not exist "!TARGET_DIR!\target-dos\dos125" mkdir "!TARGET_DIR!\target-dos\dos125"
if not exist "!TARGET_DIR!\target-dos\dos16" mkdir "!TARGET_DIR!\target-dos\dos16"
set "_EMIT_EXE=%TEMP%\wca_emit_!RANDOM!.exe"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\engine\common\dos32\compile_host_c89.cmd" "!SCRIPT_DIR!\src\asm_conv_c89.c" "!TARGET_DIR!\bin\asm-conv.exe"
if errorlevel 1 exit /b 1
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\engine\common\dos32\compile_host_c89.cmd" "!SCRIPT_DIR!\src\emit_dos_suite_c89.c" "!_EMIT_EXE!"
if errorlevel 1 exit /b 1
goto :run_emit

:: ## run_emit
:: Executes the 8086 DOS binary emitter and updates symlinks.
:run_emit
"!_EMIT_EXE!" "!TARGET_DIR!\target-dos"
if exist "!_EMIT_EXE!" del /f /q "!_EMIT_EXE!" >nul 2>&1
call :stage_sysroot
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "win-cmd-asm" "%WIN_CMD_ASM_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "win-cmd-asm" "default" "!EXACT_VERSION!"
exit /b 0

:: ## stage_sysroot
:: Copies DOS shells and utilities into LIBSCRIPT_TARGET_SYSROOT when synthesizing an OS image.
:stage_sysroot
if not "%LIBSCRIPT_IMAGE_BUILD%"=="1" exit /b 0
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" exit /b 0
if /I "%LIBSCRIPT_DOS_STRATUM%"=="dos16-fcb" (
    if not exist "%LIBSCRIPT_TARGET_SYSROOT%" mkdir "%LIBSCRIPT_TARGET_SYSROOT%"
    copy /y "!TARGET_DIR!\target-dos\dos125\WINCMD1.COM" "%LIBSCRIPT_TARGET_SYSROOT%\WINCMD1.COM" >nul
) else (
    if not exist "%LIBSCRIPT_TARGET_SYSROOT%\DOS" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\DOS"
    copy /y "!TARGET_DIR!\target-dos\dos16\*.COM" "%LIBSCRIPT_TARGET_SYSROOT%\DOS\" >nul
    copy /y "!TARGET_DIR!\target-dos\dos125\WINCMD1.COM" "%LIBSCRIPT_TARGET_SYSROOT%\DOS\WINCMD1.COM" >nul
)
exit /b 0
