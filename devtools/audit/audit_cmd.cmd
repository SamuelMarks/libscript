@echo off
:: # audit_cmd.cmd
:: ## Overview
:: Windows Batch companion for auditing .cmd and .bat scripts across the repository using wincheck from _lib\toolchains\win-cmd-rs, with automatic zero-PowerShell bootstrapping when wincheck is absent from PATH.
:: ## Usage
:: devtools\audit\audit_cmd.cmd [--all | --staged | <file>...] [--severity <level>] [--dialect <dialect>] [--format <fmt>] [--exclude <rules>] [--include <rules>]

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

if /I "%~1"=="--worker-shard" goto :worker_shard_entry

set "_AC_MODE=all"
set "_AC_SEV=%LIBSCRIPT_WINCHECK_SEVERITY%"
if "!_AC_SEV!"=="" set "_AC_SEV=style"
set "_AC_DIA=%LIBSCRIPT_WINCHECK_DIALECT%"
if "!_AC_DIA!"=="" set "_AC_DIA=cmd"
set "_AC_FMT=%LIBSCRIPT_WINCHECK_FORMAT%"
if "!_AC_FMT!"=="" set "_AC_FMT=tty"
set "_AC_EXCL=%LIBSCRIPT_WINCHECK_EXCLUDE%"
if "!_AC_EXCL!"=="" set "_AC_EXCL=CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010"
set "_AC_INCL=%LIBSCRIPT_WINCHECK_INCLUDE%"
set "_AC_EXP_LIST=%TEMP%\libscript_ac_exp_!RANDOM!_!RANDOM!.txt"
set "_AC_CAND_LIST=%TEMP%\libscript_ac_cand_!RANDOM!_!RANDOM!.txt"
type nul > "!_AC_EXP_LIST!"
type nul > "!_AC_CAND_LIST!"
goto :parse_args

:: ## parse_args
:: Parses CLI options and explicit target file paths.
:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="--help" goto :show_help
if "%~1"=="/?" goto :show_help
if "%~1"=="-?" goto :show_help
if /I "%~1"=="--all" (
    set "_AC_MODE=all"
    shift
    goto :parse_args
)
if /I "%~1"=="--staged" (
    set "_AC_MODE=staged"
    shift
    goto :parse_args
)
if /I "%~1"=="-s" (
    set "_AC_SEV=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--severity" (
    set "_AC_SEV=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="-d" (
    set "_AC_DIA=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--dialect" (
    set "_AC_DIA=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="-f" (
    set "_AC_FMT=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--format" (
    set "_AC_FMT=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="-e" (
    set "_AC_EXCL=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--exclude" (
    set "_AC_EXCL=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="-i" (
    set "_AC_INCL=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--include" (
    set "_AC_INCL=%~2"
    shift
    shift
    goto :parse_args
)
set "_AC_ARG=%~1"
if /I "!_AC_ARG:~0,11!"=="--severity=" (
    set "_AC_SEV=!_AC_ARG:~11!"
    shift
    goto :parse_args
)
if /I "!_AC_ARG:~0,10!"=="--dialect=" (
    set "_AC_DIA=!_AC_ARG:~10!"
    shift
    goto :parse_args
)
if /I "!_AC_ARG:~0,9!"=="--format=" (
    set "_AC_FMT=!_AC_ARG:~9!"
    shift
    goto :parse_args
)
if /I "!_AC_ARG:~0,10!"=="--exclude=" (
    set "_AC_EXCL=!_AC_ARG:~10!"
    shift
    goto :parse_args
)
if /I "!_AC_ARG:~0,10!"=="--include=" (
    set "_AC_INCL=!_AC_ARG:~10!"
    shift
    goto :parse_args
)
set "_AC_MODE=explicit"
echo.%~1>> "!_AC_EXP_LIST!"
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions and exits with status 0.
:show_help
del /f /q "!_AC_EXP_LIST!" "!_AC_CAND_LIST!" >nul 2>&1
echo Usage: devtools\audit\audit_cmd.cmd [--all ^| --staged ^| ^<file^>...] [--exclude ^<rules^>]
echo Audits Windows Batch ^(.cmd and .bat^) scripts using wincheck ^(default exclude: CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010^).
exit /b 0

:: ## args_done
:: Collects candidate .cmd and .bat files and dispatches sharded wincheck workers via parallel.cmd.
:args_done
echo === LibScript Windows Batch ^(.cmd / .bat^) Static Analysis Audit ^(wincheck^) ===

if /I "!_AC_MODE!"=="staged" (
    for /f "delims=" %%F in ('git -C "!LIBSCRIPT_ROOT_DIR!" diff --no-ext-diff --cached --name-only --diff-filter=ACM -- "*.cmd" "*.bat" 2^>nul') do (
        call :maybe_append_repo_rel "%%F"
    )
) else if /I "!_AC_MODE!"=="explicit" (
    for /f "usebackq delims=" %%F in ("!_AC_EXP_LIST!") do (
        call :maybe_append_explicit "%%F"
    )
) else (
    for /f "delims=" %%F in ('git -C "!LIBSCRIPT_ROOT_DIR!" ls-files --cached --others --exclude-standard -- "*.cmd" "*.bat" 2^>nul') do (
        call :maybe_append_repo_rel "%%F"
    )
)
del /f /q "!_AC_EXP_LIST!" >nul 2>&1

set "_AC_HAS_ANY=0"
for %%Z in ("!_AC_CAND_LIST!") do if not "%%~zZ"=="0" set "_AC_HAS_ANY=1"
if "!_AC_HAS_ANY!"=="0" (
    del /f /q "!_AC_CAND_LIST!" >nul 2>&1
    echo [PASS] No .cmd or .bat scripts matched for auditing.
    exit /b 0
)

call :ensure_wincheck_bootstrapped
if errorlevel 1 (
    del /f /q "!_AC_CAND_LIST!" >nul 2>&1
    exit /b 1
)

set "_AC_SAVED_ST=!STACK!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_shards "!_AC_CAND_LIST!" "!THIS_FILE! --worker-shard"
set "_AC_RC=!ERRORLEVEL!"
set "STACK=!_AC_SAVED_ST!"
del /f /q "!_AC_CAND_LIST!" >nul 2>&1
if not "!_AC_RC!"=="0" exit /b 1
echo [PASS] All audited Windows Batch ^(.cmd / .bat^) scripts pass wincheck static analysis.
exit /b 0

:: ## maybe_append_repo_rel
:: Appends a repository-relative .cmd/.bat path if not in an excluded scratch directory.
:maybe_append_repo_rel
set "_MAR_REL=%~1"
set "_MAR_WIN=!_MAR_REL:/=\!"
echo "!_MAR_WIN!" | findstr /I /C:"node_modules\" /C:"tests_tmp\" /C:".git\" /C:"gen\" /C:"cache\" /C:"build\" >nul 2>&1
if not errorlevel 1 exit /b 0
if exist "!LIBSCRIPT_ROOT_DIR!\!_MAR_WIN!" (
    echo.!LIBSCRIPT_ROOT_DIR!\!_MAR_WIN!>> "!_AC_CAND_LIST!"
)
exit /b 0

:: ## maybe_append_explicit
:: Appends an explicit CLI path if it ends with .cmd or .bat and exists on disk.
:maybe_append_explicit
set "_MAE_P=%~1"
for %%E in ("!_MAE_P!") do set "_MAE_EXT=%%~xE"
if /I not "!_MAE_EXT!"==".cmd" if /I not "!_MAE_EXT!"==".bat" exit /b 0
if exist "!_MAE_P!" (
    echo.!_MAE_P!>> "!_AC_CAND_LIST!"
    exit /b 0
)
if exist "!LIBSCRIPT_ROOT_DIR!\!_MAE_P!" (
    echo.!LIBSCRIPT_ROOT_DIR!\!_MAE_P!>> "!_AC_CAND_LIST!"
)
exit /b 0

:: ## ensure_wincheck_bootstrapped
:: Loads win-cmd-rs env.cmd and auto-installs wincheck via libscript.cmd if missing.
:ensure_wincheck_bootstrapped
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-cmd-rs\env.cmd" (
    set "_AC_SAVED_ST=!STACK!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-cmd-rs\env.cmd" >nul 2>&1
    set "STACK=!_AC_SAVED_ST!"
)
where wincheck >nul 2>&1
if not errorlevel 1 exit /b 0
echo [BOOTSTRAP] wincheck not found on PATH; installing via LibScript win-cmd-rs component... >&2
set "_AC_BOOT_VER=%WIN_CMD_RS_VERSION%"
if "!_AC_BOOT_VER!"=="" set "_AC_BOOT_VER=latest"
set "_AC_SAVED_ST=!STACK!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install win-cmd-rs "!_AC_BOOT_VER!"
set "_AC_BRC=!ERRORLEVEL!"
set "STACK=!_AC_SAVED_ST!"
if not "!_AC_BRC!"=="0" (
    echo [ERROR] Failed to bootstrap wincheck via LibScript win-cmd-rs. >&2
    exit /b 1
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-cmd-rs\env.cmd" (
    set "_AC_SAVED_ST=!STACK!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-cmd-rs\env.cmd" >nul 2>&1
    set "STACK=!_AC_SAVED_ST!"
)
where wincheck >nul 2>&1
if errorlevel 1 (
    echo [ERROR] wincheck binary still missing on PATH after win-cmd-rs bootstrap. >&2
    exit /b 1
)
exit /b 0

:: ## worker_shard_entry
:: Processes one shard of .cmd/.bat paths in pure Batch batches of 50 without PowerShell.
:worker_shard_entry
set "_WS_SHARD=%~2"
if "!_WS_SHARD!"=="" exit /b 0
if not exist "!_WS_SHARD!" exit /b 0
if "!_AC_SEV!"=="" set "_AC_SEV=style"
if "!_AC_DIA!"=="" set "_AC_DIA=cmd"
if "!_AC_FMT!"=="" set "_AC_FMT=tty"
if not defined _AC_EXCL set "_AC_EXCL=CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010"
set "_WS_BASE=--severity !_AC_SEV! --dialect !_AC_DIA! --format !_AC_FMT!"
if not "!_AC_EXCL!"=="" set "_WS_BASE=!_WS_BASE! --exclude !_AC_EXCL!"
if not "!_AC_INCL!"=="" set "_WS_BASE=!_WS_BASE! --include !_AC_INCL!"
set "_WS_BATCH="
set /a "_WS_CNT=0"
set "_WS_FAIL=0"
set "_WS_TMP_BASE=%TEMP%"
if "!_WS_TMP_BASE!"=="" set "_WS_TMP_BASE=%TMP%"
if "!_WS_TMP_BASE!"=="" set "_WS_TMP_BASE=!LIBSCRIPT_ROOT_DIR!\build"
if not exist "!_WS_TMP_BASE!" mkdir "!_WS_TMP_BASE!" >nul 2>&1
for %%A in ("!_WS_TMP_BASE!") do set "_WS_TMP_BASE=%%~fA"
set "_WS_CMD1002_TMP=!_WS_TMP_BASE!\ls_wc_1002_!RANDOM!_!RANDOM!.txt"
for /f "usebackq delims=" %%B in ("!_WS_SHARD!") do (
    set "_WS_BATCH=!_WS_BATCH! "%%B""
    set /a "_WS_CNT+=1"
    if "!_WS_CNT!"=="50" (
        wincheck !_WS_BASE! !_WS_BATCH!
        if errorlevel 1 set "_WS_FAIL=1"
        wincheck --dialect !_AC_DIA! --format tty --include CMD1002 !_WS_BATCH! > "!_WS_CMD1002_TMP!" 2>&1
        findstr /C:"The input line is too long" "!_WS_CMD1002_TMP!"
        if not errorlevel 1 set "_WS_FAIL=1"
        set "_WS_BATCH="
        set /a "_WS_CNT=0"
    )
)
if not "!_WS_CNT!"=="0" (
    wincheck !_WS_BASE! !_WS_BATCH!
    if errorlevel 1 set "_WS_FAIL=1"
    wincheck --dialect !_AC_DIA! --format tty --include CMD1002 !_WS_BATCH! > "!_WS_CMD1002_TMP!" 2>&1
    findstr /C:"The input line is too long" "!_WS_CMD1002_TMP!"
    if not errorlevel 1 set "_WS_FAIL=1"
)
del /f /q "!_WS_CMD1002_TMP!" >nul 2>&1
if "!_WS_FAIL!"=="1" exit /b 1
exit /b 0
