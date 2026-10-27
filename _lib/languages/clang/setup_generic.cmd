@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and lifecycle implementation for the LLVM Clang compiler component.
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
if "%CLANG_VERSION%"=="" set "CLANG_VERSION=latest"
if "%CLANG_VERSION%"=="latest" (set "EXACT_VERSION=18.1.8") else (set "EXACT_VERSION=%CLANG_VERSION%")
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if not "%CLANG_PKG_MGR%"=="" set "LIBSCRIPT_PKG_MGR=%CLANG_PKG_MGR%"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="uninstall" goto :action_uninstall
goto :action_install

:: ## action_ls
:: Lists installed Clang versions under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\clang" dir /b "%LIBSCRIPT_HOME%\clang"
exit /b 0

:: ## action_ls_remote
:: Lists remote Clang release versions.
:action_ls_remote
echo 16.0.6
echo 17.0.6
echo 18.1.8
echo 19.1.0
exit /b 0

:: ## action_use
:: Updates the active Clang version alias junction.
:action_use
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "clang" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_download
:: Downloads Clang archive into the local offline cache.
:action_download
if not "%CLANG_DOWNLOAD_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%CLANG_DOWNLOAD_URL%" "!LIBSCRIPT_ROOT_DIR!\cache\downloads\clang\clang-%EXACT_VERSION%.zip"
)
exit /b 0

:: ## action_install
:: Installs Clang via the configured package manager or stages a local shim.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\clang\%EXACT_VERSION%"
if exist "%TARGET_DIR%\bin\clang.exe" (
    echo [INFO] clang %EXACT_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)
where clang >nul 2>&1
if errorlevel 1 (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends "clang"
)
if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "clang" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_uninstall
:: Removes the installed Clang version directory.
:action_uninstall
if exist "%LIBSCRIPT_HOME%\clang\%EXACT_VERSION%" rmdir /s /q "%LIBSCRIPT_HOME%\clang\%EXACT_VERSION%"
exit /b 0
