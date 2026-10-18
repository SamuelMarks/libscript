@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and lifecycle implementation for the Custom C Compiler (custom-cc).
::
:: ## Usage
:: setup_generic.cmd [ACTION]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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
if "%CUSTOM_CC_VERSION%"=="" set "CUSTOM_CC_VERSION=latest"
if "%CUSTOM_CC_VERSION%"=="latest" (set "EXACT_VERSION=1.0.0") else (set "EXACT_VERSION=%CUSTOM_CC_VERSION%")
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="uninstall" goto :action_uninstall
goto :action_install

:: ## action_ls
:: Lists installed custom-cc versions under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\custom-cc" dir /b "%LIBSCRIPT_HOME%\custom-cc"
exit /b 0

:: ## action_ls_remote
:: Lists remote custom-cc versions.
:action_ls_remote
echo 1.0.0
echo latest
exit /b 0

:: ## action_use
:: Updates the active custom-cc version alias junction.
:action_use
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "custom-cc" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_download
:: Downloads custom-cc archive into the local offline cache.
:action_download
if not "%CUSTOM_CC_DOWNLOAD_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%CUSTOM_CC_DOWNLOAD_URL%" "!LIBSCRIPT_ROOT_DIR!\cache\downloads\custom-cc\custom-cc-%EXACT_VERSION%.zip"
)
exit /b 0

:: ## action_install
:: Stages the custom-cc wrapper and updates the default junction.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\custom-cc\%EXACT_VERSION%"
if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
copy /y "!SCRIPT_DIR!\cc_wrapper.cmd" "%TARGET_DIR%\bin\custom-cc.cmd" >nul
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "custom-cc" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_uninstall
:: Removes the installed custom-cc version directory.
:action_uninstall
if exist "%LIBSCRIPT_HOME%\custom-cc\%EXACT_VERSION%" rmdir /s /q "%LIBSCRIPT_HOME%\custom-cc\%EXACT_VERSION%"
exit /b 0
