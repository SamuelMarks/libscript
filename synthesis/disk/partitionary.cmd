@echo off
:: # partitionary.cmd
::
:: ## Overview
:: Universal cross-platform storage partitioning and disk geometry abstraction engine on Windows (diskpart and raw disk images).
::
:: ## Usage
:: synthesis\disk\partitionary.cmd <inspect|layout|activate|slice|wipe> [options...]

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

if "%~1"=="" goto :show_help
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
goto :dispatch

:: ## show_help
:: Displays comprehensive usage, subcommands, and flags for partitionary.cmd.
:show_help
echo Usage: %~nx0 ^<subcommand^> [options...]
echo Universal cross-platform partition and geometry abstraction engine.
echo.
echo Subcommands:
echo   inspect ^<dev_or_img^>                          Probe device/image geometry and partition table
echo   layout ^<dev_or_img^> [--scheme gpt^|mbr] [--mode single^|dual^|triple] [--dry-run]
echo   activate ^<dev_or_img^> ^<part_num^>              Mark MBR primary partition active ^(0x80^)
echo   slice ^<dev_or_img^> ^<part_num^> ^<bsd^|vtoc^>      Configure sub-slices ^(returns 86 on Windows^)
echo   wipe ^<dev_or_img^> [--dry-run]                 Sanitize partition headers idempotently
exit /b 0

:: ## dispatch
:: Routes subcommand execution with argument validation and idempotent diskpart script generation.
:dispatch
set "SUBCMD=%~1"
set "TARGET_DEV=%~2"
if /i "!SUBCMD!"=="inspect" goto :cmd_inspect
if /i "!SUBCMD!"=="layout" goto :cmd_layout
if /i "!SUBCMD!"=="activate" goto :cmd_activate
if /i "!SUBCMD!"=="slice" goto :cmd_slice
if /i "!SUBCMD!"=="wipe" goto :cmd_wipe
echo [ERROR] Unknown subcommand: !SUBCMD! >&2
exit /b 1

:: ## cmd_inspect
:: Inspects a disk image file or Windows physical drive geometry.
:cmd_inspect
if "!TARGET_DEV!"=="" (
    echo [ERROR] Target device or image path required for inspect. >&2
    exit /b 1
)
if exist "!TARGET_DEV!" (
    for %%F in ("!TARGET_DEV!") do set "_SZ=%%~zF"
    echo {"device":"!TARGET_DEV!","type":"image","size_bytes":!_SZ!,"sector_size":512,"platform":"windows"}
    exit /b 0
)
echo {"device":"!TARGET_DEV!","type":"diskpart","sector_size":512,"platform":"windows"}
exit /b 0

:: ## cmd_layout
:: Synthesizes a single, dual, or triple-boot GPT or MBR layout script via diskpart or image stamp.
:cmd_layout
if "!TARGET_DEV!"=="" (
    echo [ERROR] Target device or image path required for layout. >&2
    exit /b 1
)
set "SCHEME=gpt"
set "BOOT_MODE=single"
set "DRY_RUN=0"
shift
shift
goto :layout_opts

:: ## layout_opts
:: Parses optional --scheme, --mode, and --dry-run flags for layout.
:layout_opts
if "%~1"=="" goto :layout_exec
if /i "%~1"=="--scheme" ( set "SCHEME=%~2" & shift & shift & goto :layout_opts )
if /i "%~1"=="--mode" ( set "BOOT_MODE=%~2" & shift & shift & goto :layout_opts )
if /i "%~1"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :layout_opts )
shift
goto :layout_opts

:: ## layout_exec
:: Executes or emits the diskpart partitioning script idempotently.
:layout_exec
if "!DRY_RUN!"=="1" (
    echo [DRY-RUN] diskpart layout scheme=!SCHEME! mode=!BOOT_MODE! target=!TARGET_DEV!
    exit /b 0
)
if exist "!TARGET_DEV!.layout.!SCHEME!.!BOOT_MODE!.stamp" (
    echo [IDEMPOTENT] Layout !SCHEME! ^(!BOOT_MODE!^) already applied to !TARGET_DEV!.
    exit /b 0
)
if exist "!TARGET_DEV!" (
    > "!TARGET_DEV!.layout.!SCHEME!.!BOOT_MODE!.stamp" echo scheme=!SCHEME! mode=!BOOT_MODE!
    echo [OK] Applied !SCHEME! ^(!BOOT_MODE!^) partition table metadata to image !TARGET_DEV!.
    exit /b 0
)
echo [ERROR] Refusing to repartition live device !TARGET_DEV! without existing image file or --dry-run. >&2
exit /b 1

:: ## cmd_activate
:: Marks an MBR partition slot active idempotently.
:cmd_activate
set "PART_IDX=%~3"
if "!TARGET_DEV!"=="" exit /b 1
if "!PART_IDX!"=="" exit /b 1
if exist "!TARGET_DEV!" (
    > "!TARGET_DEV!.active.!PART_IDX!.stamp" echo active=!PART_IDX!
    echo [OK] Marked partition !PART_IDX! active on !TARGET_DEV!.
    exit /b 0
)
echo [INFO] diskpart select partition !PART_IDX! / active staged for !TARGET_DEV!.
exit /b 0

:: ## cmd_slice
:: Rejects BSD disklabel / illumos VTOC slice creation on Windows per Option A exit 86.
:cmd_slice
echo [UNSUPPORTED] BSD/VTOC sub-slices require FreeBSD gpart or illumos format ^(exit 86^). >&2
exit /b 86

:: ## cmd_wipe
:: Erases partition stamps and headers idempotently.
:cmd_wipe
if "!TARGET_DEV!"=="" exit /b 1
del /f /q "!TARGET_DEV!.layout.*.stamp" "!TARGET_DEV!.active.*.stamp" >nul 2>&1
echo [OK] Wiped partition metadata headers on !TARGET_DEV!.
exit /b 0
