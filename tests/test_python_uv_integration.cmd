@echo off
setlocal EnableDelayedExpansion
:: # Validates the 'uv' backend integration for Python virtual environments.
::
:: ## Overview
:: Execute this script to verify that components can successfully install using 'uv'.
::
:: ## Usage
:: call tests\test_python_uv_integration.cmd

set "LIBSCRIPT_ROOT_DIR=%~dp0.."
for %%i in ("%LIBSCRIPT_ROOT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fi"

where uv >nul 2>nul
if errorlevel 1 (
    echo [WARN] uv is not installed. Skipping uv integration validation.
    exit /b 0
)

:: Set global environment variables to force 'uv'
set "LIBSCRIPT_PYTHON_BACKEND=uv"
set "LIBSCRIPT_PYTHON_VENV_BACKEND=uv"
set "LIBSCRIPT_HOME=%TEMP%\libscript_uv_test"
set "DOWNLOAD_DIR=%LIBSCRIPT_HOME%\downloads"

echo [INFO] Testing uv integration...

:: Test 1: Resolve python executable via uv
echo [INFO] Testing Python resolution via uv...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\python_env.cmd" libscript_python_resolve > "%TEMP%\resolved_py.txt"
if errorlevel 1 (
    echo [ERROR] Failed to resolve python via uv.
    exit /b 1
)
set /p py_path=<"%TEMP%\resolved_py.txt"
del "%TEMP%\resolved_py.txt"
echo [INFO] Resolved python: %py_path%

:: Test 2: xpk setup
echo [INFO] Testing xpk setup via uv...
set "ACTION=install"
set "PACKAGE_NAME=xpk"
set "XPK_INSTALL_METHOD=libscript_native"
call "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\xpk\setup_generic.cmd"

if not exist "%LIBSCRIPT_HOME%\xpk" (
    echo [ERROR] xpk installation via uv failed.
    exit /b 1
)
echo [INFO] xpk setup via uv successful.

echo [INFO] Cleaning up...
rmdir /s /q "%LIBSCRIPT_HOME%"

echo [INFO] uv integration validation complete.
exit /b 0
