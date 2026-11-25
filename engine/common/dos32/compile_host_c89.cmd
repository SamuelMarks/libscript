@echo off
:: # compile_host_c89.cmd
::
:: ## Overview
:: Compiles a portable zero-dependency C89 host utility on Windows using cl.exe, gcc.exe,
:: clang.exe, or zig.exe cc, bootstrapping _lib\languages\zig via LibScript when needed.
::
:: ## Usage
:: call engine\common\dos32\compile_host_c89.cmd <source.c> <output.exe>

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

set "_SRC_C=%~1"
set "_OUT_EXE=%~2"
if "!_SRC_C!"=="" exit /b 1
if "!_OUT_EXE!"=="" exit /b 1
for %%D in ("!_OUT_EXE!") do if not exist "%%~dpD" mkdir "%%~dpD"

where cl.exe >nul 2>&1
if not errorlevel 1 (
    set "_TMP_OBJ=%TEMP%\c89_!RANDOM!.obj"
    cl.exe /nologo /O2 /Fo:"!_TMP_OBJ!" /Fe:"!_OUT_EXE!" "!_SRC_C!" >nul
    if exist "!_TMP_OBJ!" del /f /q "!_TMP_OBJ!" >nul 2>&1
    if exist "!_OUT_EXE!" exit /b 0
)

for %%G in (gcc.exe clang.exe cc.exe) do (
    where %%G >nul 2>&1
    if not errorlevel 1 (
        %%G -O2 "!_SRC_C!" -o "!_OUT_EXE!" >nul 2>&1
        if exist "!_OUT_EXE!" exit /b 0
    )
)

call :try_zig_cc
if exist "!_OUT_EXE!" exit /b 0

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install zig 0.13.0 >nul
call :try_zig_cc
if exist "!_OUT_EXE!" exit /b 0

echo [ERROR] No C89 compiler available to build !_OUT_EXE! 1>&2
exit /b 1

:: ## try_zig_cc
:: Attempts compilation using zig.exe on PATH or in LIBSCRIPT_HOME\zig.
:try_zig_cc
where zig.exe >nul 2>&1
if not errorlevel 1 (
    zig.exe cc -O2 "!_SRC_C!" -o "!_OUT_EXE!"
    if exist "!_OUT_EXE!" exit /b 0
)
set "_LSH=%LIBSCRIPT_HOME%"
if "!_LSH!"=="" set "_LSH=%USERPROFILE%\.libscript"
for %%Z in ("!_LSH!\zig\0.13.0\zig.exe" "!_LSH!\zig\latest\zig.exe" "!_LSH!\zig\default\zig.exe" "%USERPROFILE%\.libscript\zig\0.13.0\zig.exe") do (
    if exist "%%~Z" (
        "%%~Z" cc -O2 "!_SRC_C!" -o "!_OUT_EXE!"
        if exist "!_OUT_EXE!" exit /b 0
    )
)
exit /b 1
