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

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

:: ## do_run
:: Executes do_run functionality.
:do_run
if exist "%WORDPRESS_WWWROOT%\wp-cron.php" (
    where php >nul 2>&1
    if not errorlevel 1 (
        php "%WORDPRESS_WWWROOT%\wp-cron.php" >nul 2>&1
    )
)
echo [OK] WordPress cron execution completed.
exit /b 0

:: ## do_install
:: Executes do_install functionality.
:do_install
schtasks /create /tn "WordPressCronTask" /tr "php "%WORDPRESS_WWWROOT%\wp-cron.php"" /sc minute /mo 5 /f >nul 2>&1
echo [OK] Registered WordPressCronTask in Windows Task Scheduler.
exit /b 0

:: ## do_uninstall
:: Executes do_uninstall functionality.
:do_uninstall
schtasks /delete /tn "WordPressCronTask" /f >nul 2>&1
echo [OK] Removed WordPressCronTask from Windows Task Scheduler.
exit /b 0

:: ## do_status
:: Executes do_status functionality.
:do_status
schtasks /query /tn "WordPressCronTask" 2>nul
exit /b 0

:: ## show_help
:: Executes show_help functionality.
:show_help
echo WordPress Cron Management on Windows
echo.
echo Usage:
echo   call cron.cmd run
echo   call cron.cmd install
echo   call cron.cmd uninstall
echo   call cron.cmd status
exit /b 0
