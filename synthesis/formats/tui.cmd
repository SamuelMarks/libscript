@echo off
:: # tui.cmd
:: ## Overview
:: Interactive text user interface dispatcher for packaging and management on Windows.
:: ## Usage
:: call tui.cmd [OPTIONS]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

echo ========================================================
echo               LibScript Management Console
echo ========================================================
echo.
echo Select an administrative action for Open edX:
echo   1. User Management (create/staff/superuser)
echo   2. Import Demo Content (course and content libraries)
echo   3. Database Console (MySQL / Mongo / Redis)
echo   4. Full-Stack Healthcheck Diagnostics
echo   5. Configuration Management (get/set/list)
echo   6. Automated Backup Creation
echo   7. Snapshot Restore
echo   8. Celery Workers and Beat Management
echo   9. Theming and Branding Engine
echo  10. XBlock Plugin Management
echo  11. Schema Upgrade and Release Migration
echo  12. Micro-Frontend (MFE) Build and Deploy
echo   0. Exit
echo.

set /p "CHOICE=Enter your choice [0-12]: "

if "%CHOICE%"=="1" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" user %*
) else if "%CHOICE%"=="2" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" demo %*
) else if "%CHOICE%"=="3" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" dbshell %*
) else if "%CHOICE%"=="4" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" healthcheck %*
) else if "%CHOICE%"=="5" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" config %*
) else if "%CHOICE%"=="6" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" backup %*
) else if "%CHOICE%"=="7" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" restore %*
) else if "%CHOICE%"=="8" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" workers %*
) else if "%CHOICE%"=="9" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" theme %*
) else if "%CHOICE%"=="10" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" xblock %*
) else if "%CHOICE%"=="11" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" upgrade %*
) else if "%CHOICE%"=="12" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\openedx\cli.cmd" mfe %*
) else if "%CHOICE%"=="0" (
    echo Exiting.
    exit /b 0
) else (
    echo Invalid selection.
    exit /b 1
)

exit /b %errorlevel%
