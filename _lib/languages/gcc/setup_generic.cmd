@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and lifecycle implementation for the GNU Compiler Collection (GCC).
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
if "%GCC_VERSION%"=="" set "GCC_VERSION=latest"
if "%GCC_VERSION%"=="latest" (set "EXACT_VERSION=14.2.0") else (set "EXACT_VERSION=%GCC_VERSION%")
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if not "%GCC_PKG_MGR%"=="" set "LIBSCRIPT_PKG_MGR=%GCC_PKG_MGR%"
if "%GCC_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "GCC_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "GCC_INSTALL_METHOD=system"
    )
)

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="uninstall" goto :action_uninstall
goto :action_install

:: ## action_ls
:: Lists installed GCC versions under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\gcc" dir /b "%LIBSCRIPT_HOME%\gcc"
exit /b 0

:: ## action_ls_remote
:: Lists remote GCC release versions.
:action_ls_remote
echo 12.4.0
echo 13.3.0
echo 14.2.0
exit /b 0

:: ## action_use
:: Updates the active GCC version alias junction.
:action_use
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "gcc" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_download
:: Downloads GCC archive into the local offline cache.
:action_download
if not "%GCC_DOWNLOAD_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%GCC_DOWNLOAD_URL%" "!LIBSCRIPT_ROOT_DIR!\cache\downloads\gcc\gcc-%EXACT_VERSION%.zip"
)
exit /b 0

:: ## action_install
:: Installs GCC via the configured package manager or stages a local shim.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\gcc\%EXACT_VERSION%"
if exist "%TARGET_DIR%\bin\gcc.exe" (
    echo [INFO] gcc %EXACT_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)
where gcc >nul 2>&1
if errorlevel 1 (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends "gcc"
)
if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "gcc" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_uninstall
:: Removes the installed GCC version directory.
:action_uninstall
if exist "%LIBSCRIPT_HOME%\gcc\%EXACT_VERSION%" rmdir /s /q "%LIBSCRIPT_HOME%\gcc\%EXACT_VERSION%"
exit /b 0
