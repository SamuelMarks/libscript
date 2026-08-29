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

set "LIBSCRIPT_ROOT_DIR=%~dp0.."
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
