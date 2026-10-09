@echo off
setlocal EnableDelayedExpansion
:: # Validates the 'pyenv' backend integration for Python virtual environments.
::
:: ## Overview
:: Execute this script to verify that components can successfully resolve and use Python via 'pyenv'.
::
:: ## Usage
:: call tests\test_python_pyenv_integration.cmd
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

for %%i in ("%LIBSCRIPT_ROOT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fi"

where pyenv >nul 2>nul
if errorlevel 1 (
    echo [WARN] pyenv is not installed. Skipping pyenv integration validation.
    exit /b 0
)

:: Set global environment variables to force 'pyenv'
set "LIBSCRIPT_PYTHON_BACKEND=pyenv"
set "LIBSCRIPT_PYTHON_VENV_BACKEND=venv"
set "LIBSCRIPT_HOME=%TEMP%\libscript_pyenv_test"

echo [INFO] Testing pyenv integration...

:: Test 1: Resolve python executable via pyenv
echo [INFO] Testing Python resolution via pyenv...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\python_env.cmd" libscript_python_resolve > "%TEMP%\resolved_py.txt"
if errorlevel 1 (
    echo [ERROR] Failed to resolve python via pyenv.
    exit /b 1
)
set /p py_path=<"%TEMP%\resolved_py.txt"
del "%TEMP%\resolved_py.txt"
echo [INFO] Resolved python: %py_path%

:: Test 2: Create a venv using the resolved pyenv executable
echo [INFO] Testing venv creation using pyenv executable...
set "VENV_DIR=%LIBSCRIPT_HOME%\test_venv"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\python_env.cmd" libscript_python_venv "%VENV_DIR%"
if errorlevel 1 (
    echo [ERROR] Failed to create venv using pyenv.
    exit /b 1
)

if not exist "%VENV_DIR%\Scripts" (
    if not exist "%VENV_DIR%\bin" (
        echo [ERROR] Failed to create venv using pyenv.
        exit /b 1
    )
)
echo [INFO] Successfully created venv via pyenv at %VENV_DIR%.

echo [INFO] Cleaning up...
rmdir /s /q "%LIBSCRIPT_HOME%"

echo [INFO] pyenv integration validation complete.
exit /b 0
