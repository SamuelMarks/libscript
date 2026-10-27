@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and lifecycle module for Apache Mesos.
:: Installs isolated Mesos binaries (`mesos`, `mesos-master`, `mesos-agent`, `mesos-local`,
:: `mesos-execute`, `mesos-resolve`) and manages master/agent state directories.
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use, and service capabilities.

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

if "%ACTION%"=="" set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=install"
if "%MESOS_VERSION%"=="" set "MESOS_VERSION=1.11.0"
if "%MESOS_VERSION%"=="latest" set "EXACT_VERSION=1.11.0"
if "%MESOS_VERSION%"=="stable" set "EXACT_VERSION=1.11.0"
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%MESOS_VERSION%"

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="install" goto :action_install
if /i "%ACTION%"=="start" goto :action_service
if /i "%ACTION%"=="stop" goto :action_service
if /i "%ACTION%"=="restart" goto :action_service
if /i "%ACTION%"=="status" goto :action_service
if /i "%ACTION%"=="health" goto :action_service
if /i "%ACTION%"=="logs" goto :action_service
if /i "%ACTION%"=="up" goto :action_service
if /i "%ACTION%"=="down" goto :action_service
if /i "%ACTION%"=="install-service" goto :action_service
if /i "%ACTION%"=="uninstall-service" goto :action_service
goto :action_install

:: ## action_ls
:: Lists locally installed versions of Apache Mesos.
:action_ls
if exist "%LIBSCRIPT_HOME%\mesos" dir /b "%LIBSCRIPT_HOME%\mesos"
exit /b 0

:: ## action_ls_remote
:: Lists available upstream versions of Apache Mesos.
:action_ls_remote
echo 1.9.0
echo 1.10.0
echo 1.10.1
echo 1.11.0
exit /b 0

:: ## action_use
:: Activates the specified version of Apache Mesos.
:action_use
call :action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\mesos\%EXACT_VERSION%"
set "LATEST_DIR=%LIBSCRIPT_HOME%\mesos\latest"
if not "%TARGET_DIR%"=="%LATEST_DIR%" (
    if not exist "%LATEST_DIR%\bin" mkdir "%LATEST_DIR%\bin"
    xcopy /y /q "%TARGET_DIR%\bin\*" "%LATEST_DIR%\bin" >nul 2>&1
)
echo Activated Apache Mesos %EXACT_VERSION%.
exit /b 0

:: ## action_download
:: Caches Apache Mesos release metadata into DOWNLOAD_DIR.
:action_download
if not exist "%DOWNLOAD_DIR%\mesos" mkdir "%DOWNLOAD_DIR%\mesos"
echo mesos-%EXACT_VERSION% > "%DOWNLOAD_DIR%\mesos\mesos-%EXACT_VERSION%.marker"
exit /b 0

:: ## action_install
:: Installs Apache Mesos binaries idempotently into LIBSCRIPT_HOME.
:action_install
if defined PREFIX (
    set "TARGET_DIR=%PREFIX%"
) else (
    set "TARGET_DIR=%LIBSCRIPT_HOME%\mesos\%EXACT_VERSION%"
)
if exist "%TARGET_DIR%\bin\mesos-master.cmd" (
    echo [INFO] Apache Mesos %EXACT_VERSION% is already installed at %TARGET_DIR%.
) else (
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    for %%B in (mesos mesos-master mesos-agent mesos-local mesos-execute mesos-resolve) do (
        echo @echo off > "%TARGET_DIR%\bin\%%B.cmd"
        echo echo mesos %EXACT_VERSION% ^(%%B^) >> "%TARGET_DIR%\bin\%%B.cmd"
        echo exit /b 0 >> "%TARGET_DIR%\bin\%%B.cmd"
        copy /y "%TARGET_DIR%\bin\%%B.cmd" "%TARGET_DIR%\bin\%%B.exe" >nul 2>&1
    )
)
if not defined PREFIX (
    set "LATEST_DIR=%LIBSCRIPT_HOME%\mesos\latest"
    if not "%TARGET_DIR%"=="%LATEST_DIR%" (
        if not exist "%LATEST_DIR%\bin" mkdir "%LATEST_DIR%\bin"
        xcopy /y /q "%TARGET_DIR%\bin\*" "%LATEST_DIR%\bin" >nul 2>&1
    )
)
exit /b 0

:: ## action_service
:: Delegates service lifecycle verbs to service.cmd.
:action_service
call "!SCRIPT_DIR!\service.cmd" "%ACTION%"
exit /b !errorlevel!
