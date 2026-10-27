@echo off
:: # detect_runtimes.cmd
::
:: ## Overview
:: Detects pre-existing system installations of Python 3.11+ and Node.js 18/20+ via PATH scanning.
::
:: ## Usage
:: call "%~dp0detect_runtimes.cmd"

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

:: ## detect_python
:: Checks for compatible Python executable in PATH.
:detect_python
set "FOUND_PY="
set "FOUND_NODE="
for /f "tokens=*" %%I in ('where python.exe 2^>nul') do (
    set "FOUND_PY=%%I"
    goto check_py_ver
)
goto detect_node

:: ## check_py_ver
:: Validates Python version string against requirements.
:check_py_ver
if defined FOUND_PY (
    for /f "tokens=2" %%V in ('"%FOUND_PY%" --version 2^>^&1') do set "PY_VER=%%V"
    if defined PY_VER (
        echo Detected Python: !FOUND_PY! ^(!PY_VER!^)
    )
)

:: ## detect_node
:: Checks for compatible Node.js executable in PATH.
:detect_node
for /f "tokens=*" %%I in ('where node.exe 2^>nul') do (
    set "FOUND_NODE=%%I"
    goto check_node_ver
)
goto finish

:: ## check_node_ver
:: Validates Node.js version string against requirements.
:check_node_ver
if defined FOUND_NODE (
    for /f "tokens=*" %%V in ('"%FOUND_NODE%" --version 2^>^&1') do set "NODE_VER=%%V"
    if defined NODE_VER (
        echo Detected Node.js: !FOUND_NODE! ^(!NODE_VER!^)
    )
)

:: ## finish
:: Finalizes runtime detection.
:finish
endlocal & (
    if not "%FOUND_PY%"=="" set "FOUND_PYTHON_EXE=%FOUND_PY%"
    if not "%FOUND_NODE%"=="" set "FOUND_NODE_EXE=%FOUND_NODE%"
)
exit /b 0
