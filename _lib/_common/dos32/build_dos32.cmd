@echo off
:: # build_dos32.cmd
::
:: ## Overview
:: Compiles and caches LibScript's zero-dependency C89 MS-DOS (`dos32`) execution substrate
:: helpers (`ls-wincmd`, `ls-dash-dos`, `ls-watt-curl`), supporting both OpenWatcom `wcl386`
:: (`-bt=dos -mf -3r -ox`) for 32-bit DOS `LE` / `DOS32A.EXE` targets and Win32 C89 host
:: compilers (`cl.exe`, `gcc.exe`, `clang.exe`).
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\dos32\build_dos32.cmd" <ls-wincmd|ls-dash-dos|ls-watt-curl> [--target host|dos32] [--out <path>]

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

set "_TOOL=%~1"
if "!_TOOL!"=="" exit /b 1
shift

set "_TARGET=host"
set "_OUT="

:: ## parse_loop
:: Parses optional --target and --out parameters.
:parse_loop
if "%~1"=="" goto :do_build
set "_A=%~1"
if /i "!_A!"=="--target" ( set "_TARGET=%~2" & shift & shift & goto :parse_loop )
if /i "!_A:~0,9!"=="--target=" ( set "_TARGET=!_A:~9!" & shift & goto :parse_loop )
if /i "!_A!"=="--out" ( set "_OUT=%~2" & shift & shift & goto :parse_loop )
if /i "!_A:~0,6!"=="--out=" ( set "_OUT=!_A:~6!" & shift & goto :parse_loop )
shift
goto :parse_loop

:: ## do_build
:: Compiles the requested dos32 or Win32 helper binary.
:do_build
set "_SRC="
set "_DOS_NAME="
set "_HOST_NAME="
set "_EXTRA_LIBS="

if /i "!_TOOL!"=="ls-wincmd" (
    set "_SRC=!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos32\ls_wincmd.c"
    set "_DOS_NAME=WINCMD.EXE"
    set "_HOST_NAME=LSWINCMD.EXE"
)
if /i "!_TOOL!"=="wincmd" (
    set "_SRC=!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos32\ls_wincmd.c"
    set "_DOS_NAME=WINCMD.EXE"
    set "_HOST_NAME=LSWINCMD.EXE"
)
if /i "!_TOOL!"=="ls-dash-dos" (
    set "_SRC=!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos32\ls_dash_dos.c"
    set "_DOS_NAME=DASH.EXE"
    set "_HOST_NAME=LSDASHD.EXE"
)
if /i "!_TOOL!"=="ls-watt-curl" (
    set "_SRC=!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos32\ls_watt_curl.c"
    set "_DOS_NAME=CURL.EXE"
    set "_HOST_NAME=LSWCURL.EXE"
    set "_EXTRA_LIBS=ws2_32.lib"
)
if /i "!_TOOL!"=="ls-mkdos-smoke" (
    set "_SRC=!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos32\ls_mkdos_smoke_img.c"
    set "_DOS_NAME=MKDOSSMK.EXE"
    set "_HOST_NAME=LSMKDOSS.EXE"
)

if "!_SRC!"=="" exit /b 1
if not exist "!_SRC!" exit /b 1

set "_LS_H=%LIBSCRIPT_HOME%"
if "!_LS_H!"=="" set "_LS_H=%USERPROFILE%\.libscript"
set "_CACHE=!_LS_H!\DOS32HLP"
if not exist "!_CACHE!" mkdir "!_CACHE!" 2>nul

if /i "!_TARGET!"=="dos32" (
    if "!_OUT!"=="" set "_OUT=!_CACHE!\!_DOS_NAME!"
    if exist "!_OUT!" goto :emit_out
    set "_WCL="
    for /f "delims=" %%W in ('where wcl386.exe 2^>nul') do if "!_WCL!"=="" set "_WCL=%%W"
    if "!_WCL!"=="" if not "%WATCOM%"=="" if exist "%WATCOM%\binnt\wcl386.exe" set "_WCL=%WATCOM%\binnt\wcl386.exe"
    if "!_WCL!"=="" if not "%WATCOM%"=="" if exist "%WATCOM%\binnt64\wcl386.exe" set "_WCL=%WATCOM%\binnt64\wcl386.exe"
    if not "!_WCL!"=="" (
        "!_WCL!" -q -bt=dos -mf -3r -ox -fe="!_OUT!" "!_SRC!" >nul 2>&1
        if exist "!_OUT!" goto :emit_out
    )
    exit /b 1
)

if "!_OUT!"=="" set "_OUT=!_CACHE!\!_HOST_NAME!"
if exist "!_OUT!" goto :emit_out

where cl.exe >nul 2>&1
if not errorlevel 1 (
    cl.exe /nologo /O2 /Fe:"!_OUT!" "!_SRC!" !_EXTRA_LIBS! /Fo:"%TEMP%\dos32_%RANDOM%.obj" >nul 2>&1
    if exist "!_OUT!" goto :emit_out
)

for %%C in (gcc.exe clang.exe) do (
    where %%C >nul 2>&1
    if not errorlevel 1 (
        if /i "!_TOOL!"=="ls-watt-curl" (
            %%C -std=c89 -O2 "!_SRC!" -lws2_32 -o "!_OUT!" >nul 2>&1
        ) else (
            %%C -std=c89 -O2 "!_SRC!" -o "!_OUT!" >nul 2>&1
        )
        if exist "!_OUT!" goto :emit_out
    )
)
exit /b 1

:: ## emit_out
:: Prints and exports DOS32_HELPER_BIN across endlocal scope.
:emit_out
echo !_OUT!
endlocal & set "DOS32_HELPER_BIN=%_OUT%"
exit /b 0
