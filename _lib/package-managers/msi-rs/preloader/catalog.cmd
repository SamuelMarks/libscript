@echo off
:: # catalog.cmd
::
:: ## Overview
:: Dynamic LibScript Component Catalog Engine on Windows scanning _lib/*/*/manifest.json for JSON and table output.
::
:: ## Usage
:: _lib\package-managers\msi-rs\preloader\catalog.cmd [--json] [--search <term>] [--category <name>] [--clean-base]

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

set "MODE=table"
set "SEARCH_TERM="
set "FILTER_CAT="
goto :parse_args

:: ## parse_args
:: Parses command-line options for catalog output mode and filters.
:parse_args
if "%~1"=="" goto :run_catalog
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if /i "%~1"=="--json" (
    set "MODE=json"
    shift
    goto :parse_args
)
if /i "%~1"=="--clean-base" (
    echo []
    exit /b 0
)
if /i "%~1"=="--search" (
    set "SEARCH_TERM=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--category" (
    set "FILTER_CAT=%~2"
    shift
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions and supported query options.
:show_help
echo Usage: %~nx0 [OPTIONS]
echo Scans and displays the dynamic LibScript component catalog.
echo.
echo Options:
echo   --json                 Output full component catalog in JSON format.
echo   --search ^<term^>        Filter components matching search keyword.
echo   --category ^<name^>      Filter components within specified category.
echo   --clean-base           Specify zero components ^(install clean base OS only^).
echo   --help, -h, /?, -?     Show this help message.
exit /b 0

:: ## run_catalog
:: Scans all _lib/*/*/manifest.json files and renders JSON or formatted table rows.
:run_catalog
set "REPO_ROOT=!LIBSCRIPT_ROOT_DIR!"
if /i "!MODE!"=="json" (
    echo [
    set "FIRST_ITEM=1"
) else (
    echo COMPONENT            CATEGORY           DESCRIPTION
    echo -------------------- ------------------ ----------------------------------------
)

for /d %%C in ("!REPO_ROOT!\_lib\*") do (
    set "_CAT_NAME=%%~nxC"
    if /i not "!_CAT_NAME!"=="_common" (
        if "!FILTER_CAT!"=="" (
            call :scan_category "%%~fC" "!_CAT_NAME!"
        ) else if /i "!FILTER_CAT!"=="!_CAT_NAME!" (
            call :scan_category "%%~fC" "!_CAT_NAME!"
        )
    )
)

if /i "!MODE!"=="json" (
    echo ]
)
exit /b 0

:: ## scan_category
:: Iterates component subdirectories within a single _lib category directory.
:scan_category
set "_SC_DIR=%~1"
set "_SC_CAT=%~2"
for /d %%M in ("!_SC_DIR!\*") do (
    if exist "%%~fM\manifest.json" (
        call :emit_manifest "%%~fM\manifest.json" "%%~nxM" "!_SC_CAT!"
    )
)
exit /b 0

:: ## emit_manifest
:: Extracts name, title, and description from a component manifest.json and prints matching records.
:emit_manifest
set "_EM_FILE=%~1"
set "_EM_NAME=%~2"
set "_EM_CAT=%~3"
set "_EM_DESC=!_EM_NAME!"
for /f "tokens=1,* delims=:" %%A in ('findstr /C:"\"description\"" "!_EM_FILE!" 2^>nul') do (
    for /f "tokens=1 delims=," %%Q in ("%%~B") do set "_EM_DESC=%%~Q"
)
if not "!SEARCH_TERM!"=="" (
    echo !_EM_NAME! !_EM_CAT! !_EM_DESC! | findstr /I /C:"!SEARCH_TERM!" >nul 2>&1
    if errorlevel 1 exit /b 0
)
if /i "!MODE!"=="json" (
    if "!FIRST_ITEM!"=="0" (
        echo   ,{"name": "!_EM_NAME!", "category": "!_EM_CAT!", "title": "!_EM_NAME!", "description": "!_EM_DESC!"}
    ) else (
        echo   {"name": "!_EM_NAME!", "category": "!_EM_CAT!", "title": "!_EM_NAME!", "description": "!_EM_DESC!"}
        set "FIRST_ITEM=0"
    )
) else (
    echo !_EM_NAME!   !_EM_CAT!   !_EM_DESC!
)
exit /b 0
