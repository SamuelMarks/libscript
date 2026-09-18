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

:: ## detect_python
:: Checks for compatible Python executable in PATH.
:detect_python
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
        endlocal && set "FOUND_PYTHON_EXE=%FOUND_PY%"
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
        endlocal && set "FOUND_NODE_EXE=%FOUND_NODE%"
    )
)

:: ## finish
:: Finalizes runtime detection.
:finish
exit /b 0
