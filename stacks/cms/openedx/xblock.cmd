@echo off
:: # xblock.cmd
::
:: ## Overview
:: XBlock and stack plugin management utility for Open edX on Windows.
:: Installs, uninstalls, and enumerates XBlocks and Python extension plugins.
::
:: ## Usage
::   call xblock.cmd install <package_spec_or_git_url>
::   call xblock.cmd uninstall <package_name>
::   call xblock.cmd list
::   call xblock.cmd help
::
:: ## Exit Codes
::   0 - Success
::   1 - Error

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

set "DATA_DIR=%OPENEDX_INSTALL_DIR%\data"
set "XBLOCK_REGISTRY=%DATA_DIR%\xblocks.json"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

set "PYTHON_BIN=%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe"
if not exist "%PYTHON_BIN%" (
    where python >nul 2>nul
    if not errorlevel 1 (
        set "PYTHON_BIN=python"
    ) else (
        echo [ERROR] Python interpreter not found in virtualenv or PATH. >&2
        exit /b 1
    )
)

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="install" goto do_install
if "%CMD%"=="uninstall" goto do_uninstall
if "%CMD%"=="remove" goto do_uninstall
if "%CMD%"=="list" goto do_list

echo [ERROR] Unknown xblock command: %CMD% >&2
goto show_help

:: ## do_install
:: Installs and migrates an Open edX XBlock plugin package.
:do_install
shift
set "PKG=%~1"
if "%PKG%"=="" (
    echo [ERROR] Package specification required. >&2
    exit /b 1
)
echo [INFO] Installing XBlock '%PKG%'...
"%PYTHON_BIN%" -m pip install "%PKG%" 2>nul
if exist "%OPENEDX_INSTALL_DIR%\manage.py" (
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms migrate --noinput 2>nul
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" cms migrate --noinput 2>nul
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms collectstatic --noinput 2>nul
)
"%PYTHON_BIN%" -c "import json, os; p = r'%XBLOCK_REGISTRY%'; d = json.load(open(p)) if os.path.exists(p) else []; d.append('%PKG%') if '%PKG%' not in d else None; json.dump(d, open(p, 'w'), indent=2)"
echo [INFO] XBlock '%PKG%' installed.
exit /b 0

:: ## do_uninstall
:: Uninstalls and unregisters an Open edX XBlock plugin package.
:do_uninstall
shift
set "PKG=%~1"
if "%PKG%"=="" (
    echo [ERROR] Package name required. >&2
    exit /b 1
)
echo [INFO] Uninstalling XBlock '%PKG%'...
"%PYTHON_BIN%" -m pip uninstall -y "%PKG%" 2>nul
"%PYTHON_BIN%" -c "import json, os; p = r'%XBLOCK_REGISTRY%'; d = json.load(open(p)) if os.path.exists(p) else []; d.remove('%PKG%') if '%PKG%' in d else None; json.dump(d, open(p, 'w'), indent=2)"
echo [INFO] XBlock '%PKG%' uninstalled.
exit /b 0

:: ## do_list
:: Lists discovered and registered XBlocks in the Open edX environment.
:do_list
echo ==========================================================================
echo XBLOCK IDENTIFIER                ENTRY POINT / PACKAGE
echo --------------------------------------------------------------------------
"%PYTHON_BIN%" -c "import json, os, importlib.metadata as im; eps = [f'{e.name:<32} {e.value:<40}' for e in im.entry_points().get('xblock.v1', [])] if hasattr(im.entry_points(), 'get') else []; p = r'%XBLOCK_REGISTRY%'; reg = [f'{k:<32} (registered)' for k in json.load(open(p))] if os.path.exists(p) and os.path.getsize(p) > 0 else []; all_items = eps + [r for r in reg if not any(r.startswith(e[:32]) for e in eps)]; [print(x) for x in all_items] if all_items else print('(No XBlocks currently discovered)')"
echo ==========================================================================
exit /b 0

:: ## show_help
:: Displays XBlock management CLI command usage.
:show_help
echo Open edX XBlock ^& Plugin Management CLI (Windows)
echo.
echo Usage:
echo   call xblock.cmd install ^<package_spec_or_git_url^>
echo   call xblock.cmd uninstall ^<package_name^>
echo   call xblock.cmd list
echo   call xblock.cmd help
exit /b 0
