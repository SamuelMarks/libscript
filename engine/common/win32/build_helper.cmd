@echo off
:: # build_helper.cmd
::
:: ## Overview
:: Resolves or compiles cached zero-CRT/Win32 C89 system helpers (`ls-daemon.exe`,
:: `ls-elevate.exe`, `ls-pe-arch.exe`) on Windows without PowerShell.
::
:: ## Usage
:: call "!LIBSCRIPT_ROOT_DIR!\engine\common\win32\build_helper.cmd" :resolve_helper ls-daemon

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

if "%~1"==":resolve_helper" shift
if "%~1"=="resolve_helper" shift
if "%~1"=="" exit /b 1
goto :resolve_helper

:: ## resolve_helper
:: Locates or compiles the requested Win32 C89 helper binary and exports LS_HELPER_BIN.
:resolve_helper
set "_RH_NAME=%~1"
set "_RH_SRC="
set "_RH_MSVC_LIBS=kernel32.lib"
set "_RH_GCC_LIBS=-lkernel32"
if /i "!_RH_NAME!"=="ls-daemon" (
    set "_RH_SRC=ls_daemon.c"
    set "_RH_MSVC_LIBS=kernel32.lib ws2_32.lib"
    set "_RH_GCC_LIBS=-lws2_32 -lkernel32"
)
if /i "!_RH_NAME!"=="ls-elevate" (
    set "_RH_SRC=ls_elevate.c"
    set "_RH_MSVC_LIBS=kernel32.lib shell32.lib"
    set "_RH_GCC_LIBS=-lshell32 -lkernel32"
)
if /i "!_RH_NAME!"=="ls-pe-arch" (
    set "_RH_SRC=ls_pe_arch.c"
    set "_RH_MSVC_LIBS="
    set "_RH_GCC_LIBS="
)
if "!_RH_SRC!"=="" exit /b 1

if "%IS_MSDOS%"=="1" exit /b 1
if /i "%TARGET_OS%"=="msdos" exit /b 1

for /f "delims=" %%P in ('where "!_RH_NAME!.exe" 2^>nul') do (
    set "_FOUND_BIN=%%P"
    goto :return_helper
)

REM wincheck disable=CMD3006
set "_RH_HOME=%LIBSCRIPT_HOME%"
if "!_RH_HOME!"=="" set "_RH_HOME=%USERPROFILE%\.libscript"
if exist "!_RH_HOME!\bin\!_RH_NAME!.exe" (
    set "_FOUND_BIN=!_RH_HOME!\bin\!_RH_NAME!.exe"
    goto :return_helper
)

set "_RH_SD=%SystemDrive%"
if "!_RH_SD!"=="" set "_RH_SD=C:"
if exist "!_RH_SD!\libscript\bootstrap\bin\!_RH_NAME!.exe" (
    set "_FOUND_BIN=!_RH_SD!\libscript\bootstrap\bin\!_RH_NAME!.exe"
    goto :return_helper
)

set "_RH_CPATH=!LIBSCRIPT_ROOT_DIR!\engine\common\win32\!_RH_SRC!"
if not exist "!_RH_CPATH!" exit /b 1
if not exist "!_RH_HOME!\bin" mkdir "!_RH_HOME!\bin"
set "_RH_OUT=!_RH_HOME!\bin\!_RH_NAME!.exe"

if exist "!_RH_HOME!\c\default\bin" set "PATH=!_RH_HOME!\c\default\bin;!PATH!"

where cl.exe >nul 2>&1
if not errorlevel 1 (
    set "_RH_OBJ=%TEMP%\!_RH_NAME!_!RANDOM!.obj"
    cl.exe /nologo /O1 "!_RH_CPATH!" /Fo"!_RH_OBJ!" /Fe"!_RH_OUT!" /link !_RH_MSVC_LIBS! >nul 2>&1
    set "_CC_RC=!errorlevel!"
    del /f /q "!_RH_OBJ!" 2>nul
    if "!_CC_RC!"=="0" if exist "!_RH_OUT!" (
        set "_FOUND_BIN=!_RH_OUT!"
        goto :return_helper
    )
)

for %%C in (gcc.exe clang.exe tcc.exe cc.exe) do (
    where %%C >nul 2>&1
    if not errorlevel 1 (
        %%C -std=c89 -O2 "!_RH_CPATH!" -o "!_RH_OUT!" !_RH_GCC_LIBS! >nul 2>&1
        if not errorlevel 1 if exist "!_RH_OUT!" (
            set "_FOUND_BIN=!_RH_OUT!"
            goto :return_helper
        )
    )
)
exit /b 1

:: ## return_helper
:: Exports LS_HELPER_BIN across the endlocal boundary at top-level parse scope.
:return_helper
endlocal & set "LS_HELPER_BIN=%_FOUND_BIN%"
exit /b 0
