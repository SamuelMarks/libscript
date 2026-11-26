@echo off
:: # xblock.cmd
:: ## Overview
:: XBlock and stack plugin management utility for Open edX on Windows. Installs, uninstalls, and enumerates XBlocks and Python extension plugins.
:: ## Usage
:: call xblock.cmd install <package_spec_or_git_url> call xblock.cmd uninstall <package_name> call xblock.cmd list call xblock.cmd help ## Exit Codes 0 - Success 1 - Error

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
call :ensure_jq
echo [INFO] Installing XBlock '%PKG%'...
"%PYTHON_BIN%" -m pip install "%PKG%" 2>nul
if exist "%OPENEDX_INSTALL_DIR%\manage.py" (
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms migrate --noinput 2>nul
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" cms migrate --noinput 2>nul
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms collectstatic --noinput 2>nul
)
for %%D in ("%XBLOCK_REGISTRY%") do if not exist "%%~dpD" mkdir "%%~dpD" >nul 2>&1
if not exist "%XBLOCK_REGISTRY%" echo []> "%XBLOCK_REGISTRY%"
jq --arg pkg "%PKG%" "if index($pkg) then . else . + [$pkg] end" "%XBLOCK_REGISTRY%" > "%XBLOCK_REGISTRY%.tmp" 2>nul && move /y "%XBLOCK_REGISTRY%.tmp" "%XBLOCK_REGISTRY%" >nul
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
call :ensure_jq
echo [INFO] Uninstalling XBlock '%PKG%'...
"%PYTHON_BIN%" -m pip uninstall -y "%PKG%" 2>nul
if exist "%XBLOCK_REGISTRY%" (
    jq --arg pkg "%PKG%" "map(select(. != $pkg))" "%XBLOCK_REGISTRY%" > "%XBLOCK_REGISTRY%.tmp" 2>nul && move /y "%XBLOCK_REGISTRY%.tmp" "%XBLOCK_REGISTRY%" >nul
)
echo [INFO] XBlock '%PKG%' uninstalled.
exit /b 0

:: ## do_list
:: Lists discovered and registered XBlocks in the Open edX environment.
:do_list
call :ensure_jq
echo ==========================================================================
echo XBLOCK IDENTIFIER                ENTRY POINT / PACKAGE
echo --------------------------------------------------------------------------
set "_XB_COUNT=0"
if exist "%XBLOCK_REGISTRY%" (
    for /f "delims=" %%X in ('jq -r ".[]" "%XBLOCK_REGISTRY%" 2^>nul') do (
        echo %%X                              ^(registered^)
        set /a "_XB_COUNT+=1"
    )
)
if "!_XB_COUNT!"=="0" echo ^(No XBlocks currently discovered^)
echo ==========================================================================
exit /b 0

:: ## ensure_jq
:: Ensures jq is available on PATH via LibScript's _lib\utilities\jq component.
:ensure_jq
where jq >nul 2>&1
if errorlevel 1 if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
)
where jq >nul 2>&1
if errorlevel 1 (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install jq latest >nul 2>&1
    set "STACK="
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
)
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
