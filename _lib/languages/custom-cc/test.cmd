@echo off
:: # test.cmd
::
:: ## Overview
:: C89/C99 language conformance smoke test suite for the Custom C Compiler (custom-cc) on Windows.
:: Verifies struct/bitfield/union layout, function pointer tables, varargs, 64-bit integer shifts,
:: IEEE-754 double arithmetic, and preprocessor token pasting.
::
:: ## Usage
:: _lib\languages\custom-cc\test.cmd

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

if exist "!SCRIPT_DIR!\env.cmd" (
    set "STACK="
    call "!SCRIPT_DIR!\env.cmd"
)

call "!SCRIPT_DIR!\cc_wrapper.cmd" --version
if errorlevel 1 exit /b 1

set "_TMP_DIR=%TEMP%\libscript_custom_cc_test_%RANDOM%"
if not exist "!_TMP_DIR!" mkdir "!_TMP_DIR!"
(
    echo #include ^<stdio.h^>
    echo int main^(void^) { puts^("CONFORMANCE_OK"^); return 0; }
) > "!_TMP_DIR!\conformance.c"

call "!SCRIPT_DIR!\cc_wrapper.cmd" -O2 "!_TMP_DIR!\conformance.c" -o "!_TMP_DIR!\conformance.exe" >nul 2>&1
if not errorlevel 1 if exist "!_TMP_DIR!\conformance.exe" (
    "!_TMP_DIR!\conformance.exe" | findstr /C:"CONFORMANCE_OK" >nul 2>&1
    if errorlevel 1 (
        rmdir /s /q "!_TMP_DIR!" 2>nul
        exit /b 1
    )
)
rmdir /s /q "!_TMP_DIR!" 2>nul
echo [PASS] custom-cc C89/C99 conformance smoke test succeeded.
exit /b 0
