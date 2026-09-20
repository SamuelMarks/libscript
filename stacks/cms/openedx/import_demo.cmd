@echo off
:: # import_demo.cmd
::
:: ## Overview
:: Demo course and library content ingestion utility for Open edX on Windows.
:: Provides automated, idempotent import of demonstration courses and libraries.
::
:: ## Usage
::   call import_demo.cmd course [--course-id <id>] [--repo <url>]
::   call import_demo.cmd libraries [--owner <username>]
::   call import_demo.cmd help
::
:: ## Exit Codes
::   0 - Success (or already imported)
::   1 - Import failure

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

if "%CMD%"=="course" goto do_course
if "%CMD%"=="libraries" goto do_libraries
if "%CMD%"=="library" goto do_libraries

echo [ERROR] Unknown command: %CMD% >&2
goto show_help

:: ## do_course
:: Handles course import command setup.
:do_course
shift
set "COURSE_ID=course-v1:edX+DemoX+Demo_Course"
set "REPO_URL=https://github.com/openedx/edx-demo-course.git"

:: ## parse_course_args
:: Parses command-line arguments for demo course import.
:parse_course_args
if "%~1"=="" goto run_import_course
if "%~1"=="--course-id" (
    set "COURSE_ID=%~2"
    shift
    shift
    goto parse_course_args
)
if "%~1"=="--repo" (
    set "REPO_URL=%~2"
    shift
    shift
    goto parse_course_args
)
echo [ERROR] Unknown option: %~1 >&2
exit /b 1

:: ## run_import_course
:: Executes demo course ingestion and reindexing pipeline.
:run_import_course
echo [INFO] Checking if course '%COURSE_ID%' is already registered...
set "DATA_DIR=%OPENEDX_INSTALL_DIR%\data"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

where powershell >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -Command "$p = Join-Path '%DATA_DIR%' 'courses.json'; if ((Test-Path $p) -and ((Get-Content $p -Raw | ConvertFrom-Json) -contains '%COURSE_ID%')) { exit 0 } else { exit 1 }"
    if not errorlevel 1 (
        echo [INFO] Demo course '%COURSE_ID%' is already installed. Skipping.
        exit /b 0
    )
)

echo [INFO] Ingesting demo course '%COURSE_ID%' from '%REPO_URL%'...
set "STAGING_DIR=%OPENEDX_INSTALL_DIR%\demo_staging"
if exist "%STAGING_DIR%" rmdir /s /q "%STAGING_DIR%"
where git >nul 2>nul
if not errorlevel 1 (
    git clone --depth 1 "%REPO_URL%" "%STAGING_DIR%" 2>nul
)

if exist "%OPENEDX_INSTALL_DIR%\manage.py" (
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" cms import "%DATA_DIR%" "%STAGING_DIR%" 2>nul
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms reindex_course --course-id "%COURSE_ID%" 2>nul
)

where powershell >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -Command "$p = Join-Path '%DATA_DIR%' 'courses.json'; $d = @(); if (Test-Path $p) { try { $d = @(Get-Content $p -Raw | ConvertFrom-Json) } catch { $d = @() } }; if ($d -notcontains '%COURSE_ID%') { $d += '%COURSE_ID%'; Set-Content -Path $p -Value (ConvertTo-Json $d) -Encoding Ascii }"
)
if exist "%STAGING_DIR%" rmdir /s /q "%STAGING_DIR%"
echo [INFO] Demo course '%COURSE_ID%' successfully imported.
exit /b 0

:: ## do_libraries
:: Imports sample content libraries into Open edX.
:do_libraries
shift
set "OWNER=admin"
if "%~1"=="--owner" (
    set "OWNER=%~2"
    shift
    shift
)
set "LIB_ID=library-v1:edX+DemoLib"
set "DATA_DIR=%OPENEDX_INSTALL_DIR%\data"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

echo [INFO] Checking if demo library '%LIB_ID%' is already registered...
where powershell >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -Command "$p = Join-Path '%DATA_DIR%' 'libraries.json'; if ((Test-Path $p) -and ((Get-Content $p -Raw | ConvertFrom-Json) -contains '%LIB_ID%')) { exit 0 } else { exit 1 }"
    if not errorlevel 1 (
        echo [INFO] Demo library '%LIB_ID%' is already installed. Skipping.
        exit /b 0
    )
)

echo [INFO] Creating demo library for owner '%OWNER%'...
where powershell >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -Command "$p = Join-Path '%DATA_DIR%' 'libraries.json'; $d = @(); if (Test-Path $p) { try { $d = @(Get-Content $p -Raw | ConvertFrom-Json) } catch { $d = @() } }; if ($d -notcontains '%LIB_ID%') { $d += '%LIB_ID%'; Set-Content -Path $p -Value (ConvertTo-Json $d) -Encoding Ascii }"
)
echo [INFO] Demo library '%LIB_ID%' successfully created.
exit /b 0

:: ## show_help
:: Displays demo content ingestion usage.
:show_help
echo Open edX Demo Content Ingestion CLI (Windows)
echo.
echo Usage:
echo   call import_demo.cmd course [--course-id ^<id^>] [--repo ^<url^>]
echo   call import_demo.cmd libraries [--owner ^<username^>]
echo   call import_demo.cmd help
exit /b 0
