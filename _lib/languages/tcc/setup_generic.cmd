@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and lifecycle implementation for the Tiny C Compiler (TCC).
::
:: ## Usage
:: setup_generic.cmd [ACTION]

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

if "%ACTION%"=="" set "ACTION=install"
if "%TCC_VERSION%"=="" set "TCC_VERSION=0.9.27"
if "%TCC_VERSION%"=="latest" (set "EXACT_VERSION=0.9.27") else (set "EXACT_VERSION=%TCC_VERSION%")
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if not "%TCC_PKG_MGR%"=="" set "LIBSCRIPT_PKG_MGR=%TCC_PKG_MGR%"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="uninstall" goto :action_uninstall
goto :action_install

:: ## action_ls
:: Lists installed TCC versions under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\tcc" dir /b "%LIBSCRIPT_HOME%\tcc"
exit /b 0

:: ## action_ls_remote
:: Lists remote TCC release versions.
:action_ls_remote
echo 0.9.26
echo 0.9.27
exit /b 0

:: ## action_use
:: Updates the active TCC version alias junction.
:action_use
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "tcc" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_download
:: Downloads TCC archive into the local offline cache.
:action_download
if not "%TCC_DOWNLOAD_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%TCC_DOWNLOAD_URL%" "!LIBSCRIPT_ROOT_DIR!\cache\downloads\tcc\tcc-%EXACT_VERSION%-win64-bin.zip"
)
exit /b 0

:: ## action_install
:: Installs TCC via the configured package manager or source builder.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\tcc\%EXACT_VERSION%"
if exist "%TARGET_DIR%\bin\tcc.exe" (
    echo [INFO] tcc %EXACT_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)
where tcc >nul 2>&1
if errorlevel 1 (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends "tcc"
)
if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "tcc" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_uninstall
:: Removes the installed TCC version directory.
:action_uninstall
if exist "%LIBSCRIPT_HOME%\tcc\%EXACT_VERSION%" rmdir /s /q "%LIBSCRIPT_HOME%\tcc\%EXACT_VERSION%"
exit /b 0
