@echo off
:: # _profile_dispatch.cmd
::
:: ## Overview
:: Internal T3 helper on Windows that inspects a declarative OS/kernel profile JSON and dispatches
:: format-first `package-as` invocations to the matching distro/kernel packager.
::
:: ## Usage
:: synthesis\formats\_profile_dispatch.cmd <default_format> --profile <profile> [options...]

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

set "FMT=%~1"
if "!FMT!"=="" set "FMT=qcow2"
shift
set "PROFILE="
set "OUTPUT="
set "FWD_FLAGS="
goto :parse_pd

:: ## parse_pd
:: Parses CLI options forwarded from qcow2.cmd, raw_img.cmd, iso.cmd, or direct_kernel.cmd.
:parse_pd
if "%~1"=="" goto :pd_done
set "_A=%~1"
if /I "!_A!"=="--help" goto :show_help
if /I "!_A!"=="-h" goto :show_help
if /I "!_A!"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_pd )
if /I "!_A!"=="-p" ( set "PROFILE=%~2" & shift & shift & goto :parse_pd )
if /I "!_A:~0,10!"=="--profile=" ( set "PROFILE=!_A:~10!" & shift & goto :parse_pd )
if /I "!_A!"=="--format" ( set "FMT=%~2" & shift & shift & goto :parse_pd )
if /I "!_A!"=="-f" ( set "FMT=%~2" & shift & shift & goto :parse_pd )
if /I "!_A:~0,9!"=="--format=" ( set "FMT=!_A:~9!" & shift & goto :parse_pd )
if /I "!_A!"=="--output" ( set "OUTPUT=%~2" & shift & shift & goto :parse_pd )
if /I "!_A!"=="--out" ( set "OUTPUT=%~2" & shift & shift & goto :parse_pd )
if /I "!_A!"=="-o" ( set "OUTPUT=%~2" & shift & shift & goto :parse_pd )
if /I "!_A:~0,9!"=="--output=" ( set "OUTPUT=!_A:~9!" & shift & goto :parse_pd )
if /I "!_A:~0,6!"=="--out=" ( set "OUTPUT=!_A:~6!" & shift & goto :parse_pd )
if /I "!_A!"=="--arch" ( set "FWD_FLAGS=!FWD_FLAGS! --arch %~2" & shift & shift & goto :parse_pd )
if /I "!_A:~0,7!"=="--arch=" ( set "FWD_FLAGS=!FWD_FLAGS! --arch=!_A:~7!" & shift & goto :parse_pd )
if /I "!_A!"=="--initramfs-compress" ( set "FWD_FLAGS=!FWD_FLAGS! --initramfs-compress %~2" & shift & shift & goto :parse_pd )
if /I "!_A:~0,21!"=="--initramfs-compress=" ( set "FWD_FLAGS=!FWD_FLAGS! --initramfs-compress=!_A:~21!" & shift & goto :parse_pd )
if /I "!_A!"=="--dry-run" ( set "FWD_FLAGS=!FWD_FLAGS! --dry-run" & shift & goto :parse_pd )
if /I "!_A!"=="--strict" ( set "FWD_FLAGS=!FWD_FLAGS! --strict" & shift & goto :parse_pd )
if /I "!_A!"=="--allow-stub" ( set "FWD_FLAGS=!FWD_FLAGS! --allow-stub" & shift & goto :parse_pd )
if /I "!_A!"=="--offline" ( set "FWD_FLAGS=!FWD_FLAGS! --offline" & shift & goto :parse_pd )
shift
goto :parse_pd

:: ## pd_done
:: Resolves the profile OS family and calls the appropriate distro format driver.
:pd_done
set "_P=!PROFILE:/=\!"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_P!.json"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\linux\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\linux\!_P!.json"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\lfs\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\lfs\!_P!.json"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\freebsd\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\freebsd\!_P!.json"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\illumos\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\illumos\!_P!.json"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\!_P!.json"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\dos\!_P!.json"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\unikernel\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\unikernel\!_P!.json"
if not exist "!_P!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\rtos\!_P!.json" set "_P=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\rtos\!_P!.json"
set "PROFILE=!_P!"
if not exist "!PROFILE!" (
    echo [ERROR] Profile not found: !PROFILE! >&2
    exit /b 1
)

set "DRIVER=!SCRIPT_DIR!\linux_distro.cmd"
findstr /I /C:"\"freebsd\"" /C:"freebsd_version" "!PROFILE!" >nul 2>&1 && set "DRIVER=!SCRIPT_DIR!\freebsd_distro.cmd"
findstr /I /C:"\"illumos\"" /C:"\"sunos\"" /C:"illumos_version" "!PROFILE!" >nul 2>&1 && set "DRIVER=!SCRIPT_DIR!\illumos_distro.cmd"
findstr /I /C:"\"reactos\"" /C:"reactos_version" "!PROFILE!" >nul 2>&1 && set "DRIVER=!SCRIPT_DIR!\reactos_distro.cmd"
findstr /I /C:"\"freedos\"" /C:"\"msdos\"" /C:"dos_flavor" "!PROFILE!" >nul 2>&1 && set "DRIVER=!SCRIPT_DIR!\dos_distro.cmd"
findstr /I /C:"unikernel-" "!PROFILE!" >nul 2>&1 && set "DRIVER=!SCRIPT_DIR!\unikernel_img.cmd"
findstr /I /C:"rtos-" "!PROFILE!" >nul 2>&1 && set "DRIVER=!SCRIPT_DIR!\rtos_distro.cmd"

set "STACK="
if not "!OUTPUT!"=="" (
    call "!DRIVER!" --profile "!PROFILE!" --format "!FMT!" --output "!OUTPUT!" !FWD_FLAGS!
    exit /b !ERRORLEVEL!
)
call "!DRIVER!" --profile "!PROFILE!" --format "!FMT!" !FWD_FLAGS!
exit /b !ERRORLEVEL!

:: ## show_help
:: Displays usage instructions for _profile_dispatch.cmd.
:show_help
echo Usage: %~nx0 ^<default_format^> --profile ^<path^|preset^> [--output ^<path^>] [--dry-run] [--allow-stub]
exit /b 0
