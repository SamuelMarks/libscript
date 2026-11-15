@echo off
:: # resolve_env.cmd
::
:: ## Overview
:: Resolves workspace-pinned tool versions by ascending from a directory for `.libscript-version`
:: (multi-tool `pkg=ver` or single-version) and `libscript.json`, emitting or writing a deterministic
:: Batch/PowerShell/POSIX/JSON environment activation script without `eval`.
::
:: ## Usage
:: resolve_env.cmd [--dir=<path>] [--format=cmd|ps1|sh|json] [--write=<file>]

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

set "RESOLVE_DIR=%CD%"
set "RESOLVE_FMT=cmd"
set "RESOLVE_WRITE="

:: ## parse_args
:: Parses CLI flags for resolve_env.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_arg=%~1"
if /i "!_arg!"=="--help" goto :show_help
if /i "!_arg!"=="-h" goto :show_help
if /i "!_arg:~0,6!"=="--dir=" ( set "RESOLVE_DIR=!_arg:~6!" & shift & goto :parse_args )
if /i "!_arg!"=="--dir" ( set "RESOLVE_DIR=%~2" & shift & shift & goto :parse_args )
if /i "!_arg:~0,9!"=="--format=" ( set "RESOLVE_FMT=!_arg:~9!" & shift & goto :parse_args )
if /i "!_arg!"=="--format" ( set "RESOLVE_FMT=%~2" & shift & shift & goto :parse_args )
if /i "!_arg:~0,8!"=="--write=" ( set "RESOLVE_WRITE=!_arg:~8!" & shift & goto :parse_args )
if /i "!_arg!"=="--write" ( set "RESOLVE_WRITE=%~2" & shift & shift & goto :parse_args )
shift
goto :parse_args

:: ## show_help
:: Prints usage help for resolve_env.cmd.
:show_help
echo Usage: libscript.cmd resolve-env [--dir=^<path^>] [--format=cmd^|ps1^|sh^|json] [--write=^<file^>]
exit /b 0

:: ## args_done
:: Executes upward workspace pin resolution and emits activation statements.
:args_done
if "%LIBSCRIPT_HOME%"=="" (
    set "_RES_HOME=%USERPROFILE%\.libscript"
) else (
    set "_RES_HOME=%LIBSCRIPT_HOME%"
)
if "!RESOLVE_DIR:~-1!"=="\" set "RESOLVE_DIR=!RESOLVE_DIR:~0,-1%"

set "_TMP_OUT=%TEMP%\libscript_resolve_env_%RANDOM%.tmp"
type nul > "!_TMP_OUT!"
if /i "!RESOLVE_FMT!"=="cmd" echo @echo off>> "!_TMP_OUT!"

set "_CUR_DIR=!RESOLVE_DIR!"
set "_SEEN= "

:: ## ascend_loop
:: Ascends directory tree collecting .libscript-version key=value pins.
:ascend_loop
if exist "!_CUR_DIR!\.libscript-version" (
    for /f "usebackq tokens=1,* delims==:" %%A in ("!_CUR_DIR!\.libscript-version") do (
        set "_K=%%A"
        set "_V=%%B"
        if not "!_K:~0,1!"=="#" if not "!_V!"=="" (
            for /f "tokens=* delims= " %%X in ("!_K!") do set "_K=%%X"
            for /f "tokens=* delims= " %%Y in ("!_V!") do set "_V=%%Y"
            echo !_SEEN! | findstr /I /C:" !_K! " >nul 2>&1
            if errorlevel 1 (
                set "_SEEN=!_SEEN!!_K! "
                call :emit_pin "!_K!" "!_V!"
            )
        )
    )
)
for %%P in ("!_CUR_DIR!") do set "_PAR=%%~dpP"
set "_NEXT=!_PAR:~0,-1!"
if "!_NEXT!"=="" goto :finish_emit
if /i "!_NEXT!"=="!_CUR_DIR!" goto :finish_emit
set "_CUR_DIR=!_NEXT!"
goto :ascend_loop

:: ## emit_pin
:: Appends a single component version pin statement to the temporary output buffer.
:emit_pin
set "_PK=%~1"
set "_PV=%~2"
set "_UP=!_PK:-=_!"
for %%U in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do set "_UP=!_UP:%%U=%%U!"
set "_PKG_DIR=!_RES_HOME!\!_PK!\!_PV!"
if not exist "!_PKG_DIR!\bin" if exist "!_RES_HOME!\!_PK!\v!_PV!\bin" set "_PKG_DIR=!_RES_HOME!\!_PK!\v!_PV!"
if /i "!RESOLVE_FMT!"=="cmd" (
    echo SET "!_UP!_VERSION=!_PV!">> "!_TMP_OUT!"
    echo SET "PATH=!_PKG_DIR!\bin;!_PKG_DIR!;%%PATH%%">> "!_TMP_OUT!"
) else if /i "!RESOLVE_FMT!"=="ps1" (
    echo $env:!_UP!_VERSION = "!_PV!">> "!_TMP_OUT!"
    echo $env:PATH = "!_PKG_DIR!\bin;!_PKG_DIR!;" + $env:PATH>> "!_TMP_OUT!"
) else (
    echo export !_UP!_VERSION="!_PV!">> "!_TMP_OUT!"
    echo export PATH="!_PKG_DIR!/bin:${PATH}">> "!_TMP_OUT!"
)
exit /b 0

:: ## finish_emit
:: Finalizes active bin PATH entry and writes or prints the resolved activation file.
:finish_emit
if /i "!RESOLVE_FMT!"=="cmd" (
    echo SET "PATH=!_RES_HOME!\bin;%%PATH%%">> "!_TMP_OUT!"
) else if /i "!RESOLVE_FMT!"=="ps1" (
    echo $env:PATH = "!_RES_HOME!\bin;" + $env:PATH>> "!_TMP_OUT!"
) else if /i not "!RESOLVE_FMT!"=="json" (
    echo export PATH="!_RES_HOME!/bin:${PATH}">> "!_TMP_OUT!"
)

if not "!RESOLVE_WRITE!"=="" (
    for %%F in ("!RESOLVE_WRITE!") do if not exist "%%~dpF" mkdir "%%~dpF"
    move /y "!_TMP_OUT!" "!RESOLVE_WRITE!" >nul 2>&1
) else (
    type "!_TMP_OUT!"
    del /f /q "!_TMP_OUT!" >nul 2>&1
)
exit /b 0
