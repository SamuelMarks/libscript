@echo off
:: # direct_kernel.cmd
:: ## Overview
:: Packages a target sysroot into a direct-boot kernel + initrd bundle on Windows.
:: ## Usage
:: direct_kernel.cmd [--kernel=<os>] [--allow-stub] [target_sysroot] [output_dir]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

set "KERNEL_KIND=linux"
if not "%LIBSCRIPT_TARGET_OS%"=="" set "KERNEL_KIND=%LIBSCRIPT_TARGET_OS%"

:: ## parse_dk_opts
:: Parses optional --kernel and --allow-stub flags.
:parse_dk_opts
set "_ARG=%~1"
if "!_ARG!"=="" goto :dk_opts_done
if "!_ARG:~0,9!"=="--kernel=" (
    set "KERNEL_KIND=!_ARG:~9!"
    shift
    goto :parse_dk_opts
)
if /I "!_ARG!"=="--allow-stub" (
    set "LIBSCRIPT_ALLOW_STUB=1"
    shift
    goto :parse_dk_opts
)
goto :dk_opts_done

:: ## dk_opts_done
:: Emits direct-kernel bundle or delegates to vm_builder.cmd.
:dk_opts_done
if "%LIBSCRIPT_ALLOW_STUB%"=="1" (
    set "OUT_DIR=%~2"
    if "!OUT_DIR!"=="" set "OUT_DIR=!LIBSCRIPT_ROOT_DIR!\build\images\direct-kernel"
    if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
    if exist "!OUT_DIR!\.stamp.direct_kernel" if exist "!OUT_DIR!\boot-manifest.json" (
        echo [SKIP] Direct-boot kernel bundle already synthesized: !OUT_DIR!
        exit /b 0
    )
    echo LibScript Direct-Boot Kernel Stub> "!OUT_DIR!\kernel.bin"
    echo LibScript Direct-Boot Initrd Stub> "!OUT_DIR!\initrd.img"
    echo {"kernel_family":"!KERNEL_KIND!","kernel_image":"kernel.bin","initrd_image":"initrd.img","mode":"stub"}> "!OUT_DIR!\boot-manifest.json"
    echo mode=stub> "!OUT_DIR!\.stamp.direct_kernel"
    exit /b 0
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\vm_builder.cmd" "!LIBSCRIPT_ROOT_DIR!\cli\commands\package_as\direct_kernel.sh" "--kernel=!KERNEL_KIND!" %*
exit /b !ERRORLEVEL!

:: ## show_help
:: Displays usage instructions for direct_kernel.cmd.
:show_help
echo Usage: %~nx0 [--kernel=^<os^>] [--allow-stub] [target_sysroot] [output_dir]
exit /b 0
