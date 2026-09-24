@echo off
setlocal EnableDelayedExpansion
:: # build_openedx_msi.cmd
::
:: ## Overview
:: Generates a WiX Windows Installer (.msi) package for Open edX on Windows.
:: Supports lightweight online installer and air-gapped offline installer with pre-bundled dependencies.
:: Delegates to generic packaging\build_msi.cmd with stacks\cms\openedx target.
::
:: ## Usage
:: call packaging\build_openedx_msi.cmd [OPTIONS]
::
:: ## Parameters
:: --offline, -o       : Build completely air-gapped offline installer (~1 GB)
:: --online            : Build lightweight online installer (~4 MB) (default)
:: --hydrate-cache     : Pre-fetch and verify all offline assets prior to building MSI
:: --cache-dir <dir>   : Override offline dependency cache directory
:: --out <name>        : Override output base file name
:: --version <ver>     : Package version (default: 22.1.0.0)

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Finds the root directory of the libscript repository.
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root
set "VARIANT=online"
if "%LIBSCRIPT_OFFLINE%"=="1" set "VARIANT=offline"
set "HYDRATE_CACHE=0"
set "CACHE_DIR=%LIBSCRIPT_ROOT_DIR%\cache"
if defined LIBSCRIPT_CACHE_DIR set "CACHE_DIR=%LIBSCRIPT_CACHE_DIR%"
set "MANIFEST_PATH=%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx\offline_bundle.json"
set "OUT_FILE="
set "APP_VERSION="
set "EXTRA_ARGS="

:parse_loop
if "%~1"=="" goto after_parse
if /I "%~1"=="--offline" (
    set "VARIANT=offline"
    shift
    goto parse_loop
)
if /I "%~1"=="-o" (
    set "VARIANT=offline"
    shift
    goto parse_loop
)
if /I "%~1"=="--online" (
    set "VARIANT=online"
    shift
    goto parse_loop
)
if /I "%~1"=="--hydrate-cache" (
    set "HYDRATE_CACHE=1"
    shift
    goto parse_loop
)
if /I "%~1"=="--cache-dir" (
    set "CACHE_DIR=%~2"
    shift & shift
    goto parse_loop
)
if /I "%~1"=="--out" (
    set "OUT_FILE=%~2"
    shift & shift
    goto parse_loop
)
if /I "%~1"=="--version" (
    set "APP_VERSION=%~2"
    shift & shift
    goto parse_loop
)
if /I "%~1"=="--help" goto show_help
if /I "%~1"=="-h" goto show_help
if /I "%~1"=="/?" goto show_help

set "EXTRA_ARGS=%EXTRA_ARGS% %1"
shift
goto parse_loop

:show_help
echo Open edX Windows Installer (.msi) Generator
echo.
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --online          Build lightweight online installer (~4 MB) (default)
echo   --offline, -o     Build completely air-gapped offline installer (~1 GB)
echo   --hydrate-cache   Pre-fetch and verify all offline dependencies before building
echo   --cache-dir ^<dir^> Override offline artifact cache directory
echo   --out ^<name^>      Override output base file name
echo   --version ^<ver^>   Package version (default: 22.1.0.0)
echo   --help, -h        Show this help text
exit /b 0

:after_parse
if /i "%VARIANT%"=="offline" (
    if not exist "%CACHE_DIR%\runtimes\python-3.11.9-embed-amd64.zip" (
        set "HYDRATE_CACHE=1"
    )
)

if "%HYDRATE_CACHE%"=="1" (
    echo [INFO] Hydrating offline cache before MSI build...
    call "%SCRIPT_DIR%\hydrate_offline_cache.cmd" --manifest "%MANIFEST_PATH%" --cache-dir "%CACHE_DIR%"
)

set "OUT_ARG="
if defined OUT_FILE set "OUT_ARG=--out %OUT_FILE%"
set "VER_ARG="
if defined APP_VERSION set "VER_ARG=--version %APP_VERSION%"

:: Delegate build to generic build_msi.cmd
call "%SCRIPT_DIR%\build_msi.cmd" stacks\cms\openedx --variant %VARIANT% --cache-dir "%CACHE_DIR%" %OUT_ARG% %VER_ARG% %EXTRA_ARGS%
exit /b %ERRORLEVEL%
