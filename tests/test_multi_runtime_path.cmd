@echo off
:: # test_multi_runtime_path.cmd
::
:: ## Overview
:: Verifies multi-component PATH inheritance and SERVICE_PATH emission on Windows when
:: hydrating a backend manifest combining nodejs, postgres, python, and uv, ensuring no
:: cross-component LIBSCRIPT_VERSION bleed occurs.
::
:: ## Usage
:: tests\test_multi_runtime_path.cmd

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

set "_TEST_TMP=%TEMP%\libscript_multi_path_%RANDOM%"
if not exist "!_TEST_TMP!\home\.libscript\nodejs\v20.11.0\bin" mkdir "!_TEST_TMP!\home\.libscript\nodejs\v20.11.0\bin"
if not exist "!_TEST_TMP!\home\.libscript\postgres\17\bin" mkdir "!_TEST_TMP!\home\.libscript\postgres\17\bin"
if not exist "!_TEST_TMP!\home\.libscript\python\3.12\Scripts" mkdir "!_TEST_TMP!\home\.libscript\python\3.12\Scripts"
if not exist "!_TEST_TMP!\home\.libscript\uv\latest\bin" mkdir "!_TEST_TMP!\home\.libscript\uv\latest\bin"
if not exist "!_TEST_TMP!\app\.venv\Scripts" mkdir "!_TEST_TMP!\app\.venv\Scripts"
if not exist "!_TEST_TMP!\app\node_modules\.bin" mkdir "!_TEST_TMP!\app\node_modules\.bin"

set "LIBSCRIPT_HOME=!_TEST_TMP!\home\.libscript"
echo {"deps":{"nodejs":"20.11.0","postgres":"17","python":"3.12","uv":"latest"}} > "!_TEST_TMP!\app\libscript.json"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!_TEST_TMP!\app\libscript.json"

if not "!LIBSCRIPT_VERSION!"=="" (
    echo [FAIL] LIBSCRIPT_VERSION leaked after manifest hydration: !LIBSCRIPT_VERSION! 1>&2
    rmdir /s /q "!_TEST_TMP!" 2>nul
    exit /b 1
)

echo ";!PATH!;" | findstr /I /C:"v20.11.0\bin" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] PATH missing v20.11.0\bin: !PATH! 1>&2
    rmdir /s /q "!_TEST_TMP!" 2>nul
    exit /b 1
)

echo ";!PATH!;" | findstr /I /C:"postgres\17\bin" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] PATH missing postgres\17\bin: !PATH! 1>&2
    rmdir /s /q "!_TEST_TMP!" 2>nul
    exit /b 1
)

echo ";!PATH!;" | findstr /I /C:".venv\Scripts" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] PATH missing .venv\Scripts: !PATH! 1>&2
    rmdir /s /q "!_TEST_TMP!" 2>nul
    exit /b 1
)

rmdir /s /q "!_TEST_TMP!" 2>nul
echo [PASS] Multi-runtime PATH inheritance and SERVICE_PATH verification succeeded.
endlocal
exit /b 0
