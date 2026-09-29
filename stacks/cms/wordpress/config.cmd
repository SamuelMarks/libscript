@echo off
:: # config.cmd
::
:: ## Overview
:: Configuration tool for WordPress 7.1.2 on Windows.
:: Inspects and mutates wp-config.php settings.
::
:: ## Usage
::   call config.cmd <get|set|dump> [key] [value]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)
set "WP_CONFIG=%WORDPRESS_WWWROOT%\wp-config.php"

if not exist "%WP_CONFIG%" (
    echo [ERROR] wp-config.php not found at %WP_CONFIG% >&2
    exit /b 1
)

set "CMD=%~1"
if "%CMD%"=="" goto do_dump
if "%CMD%"=="dump" goto do_dump
if "%CMD%"=="get" goto do_get
if "%CMD%"=="set" goto do_set
if "%CMD%"=="help" goto show_help

:do_get
shift
set "KEY=%~1"
if "%KEY%"=="" (
    echo [ERROR] Usage: config.cmd get ^<KEY^> >&2
    exit /b 1
)
for /f "tokens=2 delims='" %%a in ('findstr /i "'%KEY%'" "%WP_CONFIG%"') do (
    echo %%a
    exit /b 0
)
exit /b 1

:do_set
shift
set "KEY=%~1"
shift
set "VAL=%~1"
if "%KEY%"=="" (
    echo [ERROR] Usage: config.cmd set ^<KEY^> ^<VALUE^> >&2
    exit /b 1
)
findstr /i "'%KEY%'" "%WP_CONFIG%" >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -Command "(Get-Content '%WP_CONFIG%') -replace 'define\(\s*''%KEY%''.*', "define( '%KEY%', '%VAL%' );" | Set-Content '%WP_CONFIG%'"
) else (
    powershell -NoProfile -Command "$c = Get-Content '%WP_CONFIG%'; $idx = [array]::FindIndex($c, [Predicate[string]]{ param($l) $l -match 'wp-settings.php' }); if ($idx -ge 0) { $c = $c[0..($idx-1)] + "define( '%KEY%', '%VAL%' );" + $c[$idx..($c.Length-1)] } else { $c += "define( '%KEY%', '%VAL%' );" }; $c | Set-Content '%WP_CONFIG%'"
)
echo [OK] Config key %KEY% updated.
exit /b 0

:do_dump
echo === WordPress 7.1.2 Configuration Constants ===
findstr /i "define" "%WP_CONFIG%" | findstr /v "KEY SALT"
exit /b 0

:show_help
echo WordPress Configuration Management on Windows
echo.
echo Usage:
echo   call config.cmd get ^<KEY^>
echo   call config.cmd set ^<KEY^> ^<VALUE^>
echo   call config.cmd dump
exit /b 0
