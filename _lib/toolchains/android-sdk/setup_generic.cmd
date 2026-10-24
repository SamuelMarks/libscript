@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup for the android-sdk component.
:: Downloads and unpacks Google's commandlinetools, accepts licenses, and installs Android SDK platforms.
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use, and uninstall capabilities.

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
if "%ANDROID_SDK_VERSION%"=="" set "ANDROID_SDK_VERSION=11076708"
if "%ANDROID_SDK_VERSION%"=="latest" set "ANDROID_SDK_VERSION=11076708"
if "%ANDROID_PLATFORM%"=="" set "ANDROID_PLATFORM=platforms;android-34"
if "%ANDROID_BUILD_TOOLS%"=="" set "ANDROID_BUILD_TOOLS=build-tools;34.0.0"

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="install" goto :action_install
if /i "%ACTION%"=="uninstall" goto :action_uninstall
echo [INFO] android-sdk is a build toolchain and does not run a background daemon.
exit /b 0

:: ## action_ls
:: Lists locally installed versions of android-sdk.
:action_ls
if exist "%LIBSCRIPT_HOME%\android-sdk" dir /b "%LIBSCRIPT_HOME%\android-sdk"
exit /b 0

:: ## action_ls_remote
:: Lists available upstream commandlinetools versions.
:action_ls_remote
echo 11076708
exit /b 0

:: ## action_use
:: Activates the specified version of android-sdk.
:action_use
set "TARGET_DIR=%LIBSCRIPT_HOME%\android-sdk\%ANDROID_SDK_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\android-sdk\latest"
if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" >nul 2>&1
mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
exit /b 0

:: ## action_download
:: Downloads the Windows commandlinetools zip archive into the local cache.
:action_download
if not exist "%DOWNLOAD_DIR%\android-sdk" mkdir "%DOWNLOAD_DIR%\android-sdk"
set "DL_URL=https://dl.google.com/android/repository/commandlinetools-win-%ANDROID_SDK_VERSION%_latest.zip"
if not "%ANDROID_SDK_DOWNLOAD_URL%"=="" set "DL_URL=%ANDROID_SDK_DOWNLOAD_URL%"
curl -sSL "!DL_URL!" -o "%DOWNLOAD_DIR%\android-sdk\commandlinetools-%ANDROID_SDK_VERSION%.zip"
exit /b 0

:: ## action_install
:: Installs Android commandlinetools and accepts SDK licenses idempotently.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\android-sdk\%ANDROID_SDK_VERSION%"
if exist "%TARGET_DIR%\cmdline-tools\latest\bin\sdkmanager.bat" (
    echo [INFO] android-sdk %ANDROID_SDK_VERSION% is already installed.
    exit /b 0
)
if not exist "%TARGET_DIR%\cmdline-tools" mkdir "%TARGET_DIR%\cmdline-tools"
set "DL_URL=https://dl.google.com/android/repository/commandlinetools-win-%ANDROID_SDK_VERSION%_latest.zip"
if not "%ANDROID_SDK_DOWNLOAD_URL%"=="" set "DL_URL=%ANDROID_SDK_DOWNLOAD_URL%"
set "ZIP_FILE=%TEMP%\android_cmdtools_%RANDOM%.zip"
curl -sSL "!DL_URL!" -o "!ZIP_FILE!"
set "EXT_DIR=%TEMP%\android_ext_%RANDOM%"
if not exist "!EXT_DIR!" mkdir "!EXT_DIR!"
tar -xf "!ZIP_FILE!" -C "!EXT_DIR!"
del /f /q "!ZIP_FILE!" >nul 2>&1
if exist "!EXT_DIR!\cmdline-tools" (
    xcopy /E /I /Y "!EXT_DIR!\cmdline-tools\*" "%TARGET_DIR%\cmdline-tools\latest" >nul 2>&1
)
rmdir /s /q "!EXT_DIR!" >nul 2>&1
set "ALIAS_DIR=%LIBSCRIPT_HOME%\android-sdk\latest"
if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" >nul 2>&1
mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
exit /b 0

:: ## action_uninstall
:: Removes the installed Android SDK directory.
:action_uninstall
set "TARGET_DIR=%LIBSCRIPT_HOME%\android-sdk\%ANDROID_SDK_VERSION%"
if exist "%TARGET_DIR%" rmdir /s /q "%TARGET_DIR%"
exit /b 0
