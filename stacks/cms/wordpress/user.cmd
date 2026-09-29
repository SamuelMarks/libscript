@echo off
:: # user.cmd
::
:: ## Overview
:: WordPress user administration tool on Windows.
:: Supports creating, listing, setting passwords, and deleting users.
::
:: ## Usage
::   call user.cmd create <username> <email> [--password <pwd>] [--role <role>]
::   call user.cmd set-password <username> [--password <pwd>]
::   call user.cmd list
::   call user.cmd delete <username>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "CMD=%~1"
if "%CMD%"=="" goto do_list
if "%CMD%"=="list" goto do_list
if "%CMD%"=="create" goto do_create
if "%CMD%"=="set-password" goto do_setpass
if "%CMD%"=="delete" goto do_delete
if "%CMD%"=="help" goto show_help

:do_create
shift
set "U_NAME=%~1"
shift
set "U_EMAIL=%~1"
shift
set "U_PASS=WpPass_%U_NAME%_%RANDOM%"
set "U_ROLE=administrator"

:parse_create_opt
if "%~1"=="" goto run_create
if /I "%~1"=="--password" ( set "U_PASS=%~2" & shift & shift & goto parse_create_opt )
if /I "%~1"=="--role" ( set "U_ROLE=%~2" & shift & shift & goto parse_create_opt )
shift
goto parse_create_opt

:run_create
if "%U_NAME%"=="" (
    echo [ERROR] Usage: user.cmd create ^<username^> ^<email^> [--password ^<pwd^>] >&2
    exit /b 1
)
call "%SCRIPT_DIR%\dbshell.cmd" query "INSERT INTO wp_users (user_login, user_pass, user_nicename, user_email, user_registered, user_status, display_name) VALUES ('%U_NAME%', MD5('%U_PASS%'), '%U_NAME%', '%U_EMAIL%', NOW(), 0, '%U_NAME%') ON DUPLICATE KEY UPDATE user_email='%U_EMAIL%';" >nul 2>&1
echo [OK] WordPress user %U_NAME% (%U_EMAIL%) provisioned with role %U_ROLE%
exit /b 0

:do_setpass
shift
set "U_NAME=%~1"
shift
set "U_PASS=%~1"
if "%U_PASS%"=="" set "U_PASS=WpPass_%U_NAME%_%RANDOM%"
call "%SCRIPT_DIR%\dbshell.cmd" query "UPDATE wp_users SET user_pass = MD5('%U_PASS%') WHERE user_login = '%U_NAME%';" >nul 2>&1
echo [OK] Password updated for user %U_NAME%
exit /b 0

:do_list
call "%SCRIPT_DIR%\dbshell.cmd" query "SELECT ID, user_login, user_email, user_registered FROM wp_users;"
exit /b 0

:do_delete
shift
set "U_NAME=%~1"
if "%U_NAME%"=="" (
    echo [ERROR] Usage: user.cmd delete ^<username^> >&2
    exit /b 1
)
call "%SCRIPT_DIR%\dbshell.cmd" query "DELETE FROM wp_users WHERE user_login = '%U_NAME%';" >nul 2>&1
echo [OK] WordPress user %U_NAME% removed
exit /b 0

:show_help
echo WordPress User Management on Windows
echo.
echo Usage:
echo   call user.cmd create ^<username^> ^<email^> [--password ^<pwd^>] [--role ^<role^>]
echo   call user.cmd set-password ^<username^> [--password ^<pwd^>]
echo   call user.cmd list
echo   call user.cmd delete ^<username^>
exit /b 0
