@echo off
:: # service.cmd
::
:: ## Overview
:: Manages background service lifecycle operations (start, stop, status) for the mysql component.
::
:: ## Usage
:: service.cmd

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

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=status"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "MYSQL_DIR=%LIBSCRIPT_HOME%\mysql\latest"
if not exist "%MYSQL_DIR%\bin\mysqld.exe" (
    for /d %%D in ("%LIBSCRIPT_HOME%\mysql\*") do (
        if exist "%%~fD\bin\mysqld.exe" set "MYSQL_DIR=%%~fD"
    )
)
set "DATA_DIR=%LIBSCRIPT_HOME%\mysql\data"

if /i "%ACTION%"=="start" (
    sc.exe query mysql 2>nul | findstr /C:"RUNNING" >nul 2>&1 && exit /b 0
    sc.exe start mysql >nul 2>&1 && exit /b 0
    if exist "%MYSQL_DIR%\bin\mysqld.exe" (
        if not exist "%DATA_DIR%\mysql" (
            if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
            "%MYSQL_DIR%\bin\mysqld.exe" --initialize-insecure --datadir="%DATA_DIR%" >nul 2>&1
        )
        tasklist /FI "IMAGENAME eq mysqld.exe" 2>nul | findstr /I "mysqld.exe" >nul 2>&1
        if errorlevel 1 (
            start "" /b "%MYSQL_DIR%\bin\mysqld.exe" --datadir="%DATA_DIR%" --port=3306 >nul 2>&1
        )
    )
    exit /b 0
)
if /i "%ACTION%"=="stop" (
    sc.exe stop mysql >nul 2>&1
    taskkill /F /IM mysqld.exe >nul 2>&1
    exit /b 0
)
if /i "%ACTION%"=="restart" (
    call "%~f0" stop
    call "%~f0" start
    exit /b 0
)
if /i "%ACTION%"=="status" (
    sc.exe query mysql 2>nul | findstr /C:"RUNNING" >nul 2>&1 && (echo [RUNNING] mysql & exit /b 0)
    tasklist /FI "IMAGENAME eq mysqld.exe" 2>nul | findstr /I "mysqld.exe" >nul 2>&1 && (echo [RUNNING] mysqld.exe & exit /b 0)
    echo [STOPPED] mysql
    exit /b 1
)
exit /b 0
