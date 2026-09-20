@echo off
:: # pkg_tui.cmd
::
:: ## Overview
:: Interactive text user interface dispatcher for packaging and management on Windows.
:: 
:: ## Usage
::   call pkg_tui.cmd [OPTIONS]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

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
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" user %*
) else if "%CHOICE%"=="2" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" demo %*
) else if "%CHOICE%"=="3" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" dbshell %*
) else if "%CHOICE%"=="4" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" healthcheck %*
) else if "%CHOICE%"=="5" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" config %*
) else if "%CHOICE%"=="6" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" backup %*
) else if "%CHOICE%"=="7" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" restore %*
) else if "%CHOICE%"=="8" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" workers %*
) else if "%CHOICE%"=="9" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" theme %*
) else if "%CHOICE%"=="10" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" xblock %*
) else if "%CHOICE%"=="11" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" upgrade %*
) else if "%CHOICE%"=="12" (
    call "%~dp0..\..\..\..\stacks\cms\openedx\cli.cmd" mfe %*
) else if "%CHOICE%"=="0" (
    echo Exiting.
    exit /b 0
) else (
    echo Invalid selection.
    exit /b 1
)

exit /b %errorlevel%
