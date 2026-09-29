@echo off
:: # cron.cmd
::
:: ## Overview
:: WordPress background cron management tool on Windows.
:: Runs pending cron events or registers a scheduled task in Windows Task Scheduler.
::
:: ## Usage
::   call cron.cmd <run|install|uninstall|status>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)

set "CMD=%~1"
if "%CMD%"=="" goto do_run
if "%CMD%"=="run" goto do_run
if "%CMD%"=="install" goto do_install
if "%CMD%"=="uninstall" goto do_uninstall
if "%CMD%"=="status" goto do_status
if "%CMD%"=="help" goto show_help

:do_run
if exist "%WORDPRESS_WWWROOT%\wp-cron.php" (
    where php >nul 2>&1
    if not errorlevel 1 (
        php "%WORDPRESS_WWWROOT%\wp-cron.php" >nul 2>&1
    )
)
echo [OK] WordPress cron execution completed.
exit /b 0

:do_install
schtasks /create /tn "WordPressCronTask" /tr "php "%WORDPRESS_WWWROOT%\wp-cron.php"" /sc minute /mo 5 /f >nul 2>&1
echo [OK] Registered WordPressCronTask in Windows Task Scheduler.
exit /b 0

:do_uninstall
schtasks /delete /tn "WordPressCronTask" /f >nul 2>&1
echo [OK] Removed WordPressCronTask from Windows Task Scheduler.
exit /b 0

:do_status
schtasks /query /tn "WordPressCronTask" 2>nul
exit /b 0

:show_help
echo WordPress Cron Management on Windows
echo.
echo Usage:
echo   call cron.cmd run
echo   call cron.cmd install
echo   call cron.cmd uninstall
echo   call cron.cmd status
exit /b 0
