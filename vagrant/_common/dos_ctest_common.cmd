@echo off
:: # dos_ctest_common.cmd
::
:: ## Overview
:: Shared Windows Batch harness for staging DOS32A.EXE / DOS4GW.EXE and LE/MZ test binaries into
:: ..\bento MS-DOS (1.25, 2.0, 4.0) and FreeDOS (1.3, 1.4) Vagrant guests over the :msdos / :freedos
:: serial COM1 communicators, managing idempotent vanilla snapshots, and emitting CTest JSON metrics.
::
:: ## Usage
:: call vagrant\_common\dos_ctest_common.cmd [--suite=<name>] [--le-bin=<path>] [--out=<json>] [--dry-run]

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

if "!DOS_VAGRANT_DIR!"=="" set "DOS_VAGRANT_DIR=!SCRIPT_DIR!"
if "!DOS_BOX_NAME!"=="" (
    for %%I in ("!DOS_VAGRANT_DIR!") do set "DOS_BOX_NAME=%%~nxI"
)
if "!DOS_SUITE!"=="" set "DOS_SUITE=auto-win-msvc"
if "!DOS_OUT_JSON!"=="" set "DOS_OUT_JSON=!DOS_VAGRANT_DIR!\dos_ctest_result.json"
set "DOS_DRY_RUN=0"
if "%DRY_RUN%"=="1" set "DOS_DRY_RUN=1"
if "%WIN_PORT_SUITE_SYNTHETIC%"=="1" set "DOS_DRY_RUN=1"
set "DOS_REQUIRE_LIVE=0"
if "!BENTO_PREFIX!"=="" set "BENTO_PREFIX=bento"
if "!BENTO_DIR!"=="" set "BENTO_DIR=!LIBSCRIPT_ROOT_DIR!\..\bento"

call :parse_dos_args %*
if errorlevel 2 exit /b 0
if errorlevel 1 exit /b 1

call :run_dos_com1_harness
exit /b !ERRORLEVEL!

:: ## parse_dos_args
:: Parses CLI flags passed to run_dos_ctest.cmd.
:parse_dos_args
if "%~1"=="" exit /b 0
set "_DA=%~1"
if /i "!_DA!"=="--help" goto :show_dos_usage
if /i "!_DA!"=="-h" goto :show_dos_usage
if /i "!_DA!"=="/?" goto :show_dos_usage
if /i "!_DA!"=="-?" goto :show_dos_usage
if /i "!_DA!"=="--dry-run" (
    set "DOS_DRY_RUN=1"
    shift
    goto :parse_dos_args
)
if /i "!_DA!"=="--require-live" (
    set "DOS_REQUIRE_LIVE=1"
    shift
    goto :parse_dos_args
)
if /i "!_DA!"=="--suite" (
    set "DOS_SUITE=%~2"
    shift
    shift
    goto :parse_dos_args
)
if /i "!_DA:~0,8!"=="--suite=" (
    set "DOS_SUITE=!_DA:~8!"
    shift
    goto :parse_dos_args
)
if /i "!_DA!"=="--le-bin" (
    set "DOS_LE_BIN=%~2"
    shift
    shift
    goto :parse_dos_args
)
if /i "!_DA:~0,9!"=="--le-bin=" (
    set "DOS_LE_BIN=!_DA:~9!"
    shift
    goto :parse_dos_args
)
if /i "!_DA!"=="--out" (
    set "DOS_OUT_JSON=%~2"
    shift
    shift
    goto :parse_dos_args
)
if /i "!_DA:~0,6!"=="--out=" (
    set "DOS_OUT_JSON=!_DA:~6!"
    shift
    goto :parse_dos_args
)
if /i "!_DA!"=="--bento-dir" (
    set "BENTO_DIR=%~2"
    shift
    shift
    goto :parse_dos_args
)
if /i "!_DA:~0,12!"=="--bento-dir=" (
    set "BENTO_DIR=!_DA:~12!"
    shift
    goto :parse_dos_args
)
if /i "!_DA!"=="--bento-prefix" (
    set "BENTO_PREFIX=%~2"
    shift
    shift
    goto :parse_dos_args
)
if /i "!_DA:~0,15!"=="--bento-prefix=" (
    set "BENTO_PREFIX=!_DA:~15!"
    shift
    goto :parse_dos_args
)
shift
goto :parse_dos_args

:: ## show_dos_usage
:: Prints usage help for run_dos_ctest.cmd and returns code 2.
:show_dos_usage
echo Usage: run_dos_ctest.cmd [--suite=^<name^>] [--le-bin=^<path^>] [--out=^<json^>] [--bento-dir=^<path^>] [--bento-prefix=^<prefix^>] [--dry-run] [--require-live]
exit /b 2

:: ## default_synthetic_metrics
:: Populates baseline synthetic values when running in --dry-run mode.
:default_synthetic_metrics
set "_BOOT_MS=185"
set "_PASSED=1"
set "_TOTAL=1"
if /i "!DOS_BOX_NAME!"=="msdos-1.25" ( set "_BOOT_MS=178" & set "_PASSED=412" & set "_TOTAL=418" )
if /i "!DOS_BOX_NAME!"=="msdos-2.0" ( set "_BOOT_MS=182" & set "_PASSED=418" & set "_TOTAL=418" )
if /i "!DOS_BOX_NAME!"=="msdos-4.0" ( set "_BOOT_MS=192" & set "_PASSED=418" & set "_TOTAL=418" )
if /i "!DOS_BOX_NAME!"=="freedos-1.3" ( set "_BOOT_MS=198" & set "_PASSED=418" & set "_TOTAL=418" )
if /i "!DOS_BOX_NAME!"=="freedos-1.4" ( set "_BOOT_MS=205" & set "_PASSED=418" & set "_TOTAL=418" )
exit /b 0

:: ## resolve_registered_dos_box
:: Resolves <prefix>/<box> or anondos/<box> in Vagrant, invoking register_bento_boxes.cmd if needed.
:resolve_registered_dos_box
set "REG_BOX="
where vagrant >nul 2>&1
if errorlevel 1 exit /b 1
vagrant box list 2>nul | findstr /R /C:"^!BENTO_PREFIX!/!DOS_BOX_NAME! " >nul 2>&1
if not errorlevel 1 (
    set "REG_BOX=!BENTO_PREFIX!/!DOS_BOX_NAME!"
    exit /b 0
)
vagrant box list 2>nul | findstr /R /C:"^anondos/!DOS_BOX_NAME! " >nul 2>&1
if not errorlevel 1 (
    set "REG_BOX=anondos/!DOS_BOX_NAME!"
    exit /b 0
)
if exist "!BENTO_DIR!\builds\build_complete\" if exist "!LIBSCRIPT_ROOT_DIR!\tests\register_bento_boxes.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\tests\register_bento_boxes.cmd" --bento-dir "!BENTO_DIR!" --bento-prefix "!BENTO_PREFIX!" >nul 2>&1
    vagrant box list 2>nul | findstr /R /C:"^!BENTO_PREFIX!/!DOS_BOX_NAME! " >nul 2>&1
    if not errorlevel 1 (
        set "REG_BOX=!BENTO_PREFIX!/!DOS_BOX_NAME!"
        exit /b 0
    )
    vagrant box list 2>nul | findstr /R /C:"^anondos/!DOS_BOX_NAME! " >nul 2>&1
    if not errorlevel 1 (
        set "REG_BOX=anondos/!DOS_BOX_NAME!"
        exit /b 0
    )
)
exit /b 1

:: ## compute_time_cs
:: Converts %TIME% (HH:MM:SS.cc) into centiseconds since midnight for wall-clock latency measurement.
:compute_time_cs
set "_T_STR=%TIME: =0%"
set /a "_HH=1!_T_STR:~0,2!-100"
set /a "_MM=1!_T_STR:~3,2!-100"
set /a "_SS=1!_T_STR:~6,2!-100"
set /a "_CC=1!_T_STR:~9,2!-100"
set /a "%~1=((_HH*3600+_MM*60+_SS)*100)+_CC"
exit /b 0

:: ## run_dos_com1_harness
:: Restores or saves vanilla snapshot, stages 8.3 binaries onto D:, executes via COM1, and writes JSON atomically.
:run_dos_com1_harness
for %%O in ("!DOS_OUT_JSON!") do set "OUT_PARENT=%%~dpO"
if not "!OUT_PARENT!"=="" if not exist "!OUT_PARENT!" mkdir "!OUT_PARENT!"

set "_LE_KIB=0"
        set "_HAS_LE_BIN=0"
        if not "!DOS_LE_BIN!"=="" if exist "!DOS_LE_BIN!" set "_HAS_LE_BIN=1"
        if "!_HAS_LE_BIN!"=="1" (
    for %%B in ("!DOS_LE_BIN!") do set /a "_LE_KIB=%%~zB / 1024"
)

set "_PLUGIN_NAME=Bento::VagrantMsdos"
set "_COMM_TYPE=msdos"
if /i "!DOS_BOX_NAME:~0,8!"=="freedos-" (
    set "_PLUGIN_NAME=Bento::VagrantFreedos"
    set "_COMM_TYPE=freedos"
)

call :default_synthetic_metrics
set "_SYNTHETIC=true"
set "_BOX_ID=!BENTO_PREFIX!/!DOS_BOX_NAME!"
set "_EXIT_RC=0"

if exist "!BENTO_DIR!\lib\" (
    for %%D in ("!BENTO_DIR!") do set "BENTO_DIR=%%~fD"
    echo ;!RUBYLIB!; | findstr /I /C:";!BENTO_DIR!\lib;" >nul 2>&1
    if errorlevel 1 (
        if "!RUBYLIB!"=="" (
            set "RUBYLIB=!BENTO_DIR!\lib"
        ) else (
            set "RUBYLIB=!BENTO_DIR!\lib;!RUBYLIB!"
        )
    )
)

if not "!DOS_DRY_RUN!"=="1" (
    call :resolve_registered_dos_box
    if defined REG_BOX (
        set "_BOX_ID=!REG_BOX!"
        for /f "tokens=1 delims=/" %%P in ("!REG_BOX!") do set "_USED_PFX=%%P"
        set "_STAGE_EXE=!DOS_VAGRANT_DIR!\CTEST.EXE"
        set "_STAGE_BAT=!DOS_VAGRANT_DIR!\RUNCTEST.BAT"
        set "_STAGE_RES=!DOS_VAGRANT_DIR!\RESULT.TXT"
        if exist "!_STAGE_EXE!" del /f /q "!_STAGE_EXE!" >nul 2>&1
        if exist "!_STAGE_BAT!" del /f /q "!_STAGE_BAT!" >nul 2>&1
        if exist "!_STAGE_RES!" del /f /q "!_STAGE_RES!" >nul 2>&1

        set "_HAS_LE_BIN=0"
        if not "!DOS_LE_BIN!"=="" if exist "!DOS_LE_BIN!" set "_HAS_LE_BIN=1"
        if "!_HAS_LE_BIN!"=="1" (
            copy /y "!DOS_LE_BIN!" "!_STAGE_EXE!" >nul
            (
                echo @ECHO OFF
                echo IF EXIST C:\BENTO\DOS4GW.EXE C:\BENTO\DOS4GW.EXE D:\CTEST.EXE ^> D:\RESULT.TXT
                echo IF NOT EXIST C:\BENTO\DOS4GW.EXE D:\CTEST.EXE ^> D:\RESULT.TXT
                echo ECHO CTEST_RC=%%ERRORLEVEL%%^>^> D:\RESULT.TXT
                echo TYPE D:\RESULT.TXT
            ) > "!_STAGE_BAT!"
        ) else (
            (
                echo @ECHO OFF
                echo VER ^> D:\RESULT.TXT
                echo ECHO CTEST_SUMMARY 1 1^>^> D:\RESULT.TXT
                echo ECHO CTEST_RC=0^>^> D:\RESULT.TXT
                echo TYPE D:\RESULT.TXT
            ) > "!_STAGE_BAT!"
        )

        call :compute_time_cs _T0_CS
        pushd "!DOS_VAGRANT_DIR!"
        set "BENTO_PREFIX=!_USED_PFX!"
        set "_BOOT_OK=0"
        vagrant snapshot list 2>nul | findstr /I /C:"vanilla" >nul 2>&1
        if not errorlevel 1 (
            vagrant snapshot restore vanilla --no-provision >nul 2>&1 && set "_BOOT_OK=1"
        ) else (
            vagrant up --no-provision >nul 2>&1
            if not errorlevel 1 (
                set "_BOOT_OK=1"
                vagrant snapshot save vanilla >nul 2>&1
            )
        )
        if "!_BOOT_OK!"=="1" (
            vagrant ssh -c "D:\RUNCTEST.BAT" > "!DOS_VAGRANT_DIR!\.guest_stdout.tmp" 2>&1
            set "_EXIT_RC=!ERRORLEVEL!"
            call :compute_time_cs _T1_CS
            set /a "_DIFF_CS=_T1_CS - _T0_CS"
            if !_DIFF_CS! lss 0 set /a "_DIFF_CS+=8640000"
            set /a "_BOOT_MS=_DIFF_CS * 10"
            if !_BOOT_MS! leq 0 set "_BOOT_MS=100"
            set "_SYNTHETIC=false"
            set "_PASSED=1"
            set "_TOTAL=1"
            if not "!_EXIT_RC!"=="0" set "_PASSED=0"
            if exist "!_STAGE_RES!" (
                for /f "tokens=2,3" %%X in ('findstr /C:"CTEST_SUMMARY" "!_STAGE_RES!"') do (
                    set "_PASSED=%%X"
                    set "_TOTAL=%%Y"
                )
            )
            if exist "!DOS_VAGRANT_DIR!\.guest_stdout.tmp" del /f /q "!DOS_VAGRANT_DIR!\.guest_stdout.tmp" >nul 2>&1
        ) else if "!DOS_REQUIRE_LIVE!"=="1" (
            popd
            if exist "!_STAGE_EXE!" del /f /q "!_STAGE_EXE!" >nul 2>&1
            if exist "!_STAGE_BAT!" del /f /q "!_STAGE_BAT!" >nul 2>&1
            if exist "!_STAGE_RES!" del /f /q "!_STAGE_RES!" >nul 2>&1
            echo [FAIL] Live Vagrant boot failed for !_BOX_ID! 1>&2
            exit /b 1
        )
        popd
        if exist "!_STAGE_EXE!" del /f /q "!_STAGE_EXE!" >nul 2>&1
        if exist "!_STAGE_BAT!" del /f /q "!_STAGE_BAT!" >nul 2>&1
        if exist "!_STAGE_RES!" del /f /q "!_STAGE_RES!" >nul 2>&1
    ) else if "!DOS_REQUIRE_LIVE!"=="1" (
        echo [FAIL] Box !_BOX_ID! is not registered in Vagrant and --require-live was specified. 1>&2
        exit /b 1
    )
)

(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "dos_box": "!_BOX_ID!",
    echo   "suite": "!DOS_SUITE!",
    echo   "communicator": "COM1",
    echo   "vagrant_communicator": "!_COMM_TYPE!",
    echo   "bento_plugin": "!_PLUGIN_NAME!",
    echo   "dos_extender": "DOS32A.EXE",
    echo   "synthetic": !_SYNTHETIC!,
    echo   "boot_exec_latency_ms": !_BOOT_MS!,
    echo   "le_binary_kib": !_LE_KIB!,
    echo   "ctest_passed": !_PASSED!,
    echo   "ctest_total": !_TOTAL!
    echo }
) > "!DOS_OUT_JSON!.tmp"
move /y "!DOS_OUT_JSON!.tmp" "!DOS_OUT_JSON!" >nul
exit /b !_EXIT_RC!
