@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows and ReactOS setup module for rapps.
:: Provisions isolated rapps-db baseline definitions and CLI wrapper scripts.
::
:: ## Usage
:: _lib\package-managers\rapps\setup_generic.cmd

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
if "%RAPPS_VERSION%"=="" (
    if not "%LIBSCRIPT_RAPPS_VERSION%"=="" (
        set "RAPPS_VERSION=%LIBSCRIPT_RAPPS_VERSION%"
    ) else (
        set "RAPPS_VERSION=0.4.16"
    )
)
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if /i "%ACTION%"=="ls" goto :action_generic
if /i "%ACTION%"=="use" goto :action_generic
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="install" goto :action_install
goto :action_generic

:: ## action_ls_remote
:: Lists known rapps catalog versions.
:action_ls_remote
echo 0.4.15
echo 0.4.16
exit /b 0

:: ## action_download
:: Downloads upstream rapps-db archive when online.
:action_download
if "%LIBSCRIPT_OFFLINE%"=="1" exit /b 0
set "_DB_URL=%RAPPS_DOWNLOAD_URL%"
if "!_DB_URL!"=="" set "_DB_URL=%LIBSCRIPT_RAPPS_DB_URL%"
if "!_DB_URL!"=="" set "_DB_URL=https://github.com/reactos/rapps-db/archive/refs/heads/master.tar.gz"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
if not exist "%DOWNLOAD_DIR%\rapps" mkdir "%DOWNLOAD_DIR%\rapps"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!_DB_URL!" "%DOWNLOAD_DIR%\rapps\rapps-db-%RAPPS_VERSION%.tar.gz" "SKIP"
exit /b 0

:: ## action_install
:: Stages isolated rapps catalog and CLI wrapper idempotently.
:action_install
set "_VER=%RAPPS_VERSION%"
if /i "!_VER!"=="latest" set "_VER=0.4.16"
set "_INST_DIR=%LIBSCRIPT_HOME%\rapps\!_VER!"
set "_STAMP=!_INST_DIR!\.stamp.rapps"
if exist "!_INST_DIR!\bin\rapps.cmd" if exist "!_STAMP!" (
    echo [SKIP] rapps !_VER! is already installed at !_INST_DIR!.
    exit /b 0
)
if not exist "!_INST_DIR!\bin" mkdir "!_INST_DIR!\bin"
if not exist "!_INST_DIR!\db" mkdir "!_INST_DIR!\db"
call :seed_db "!_INST_DIR!\db"
(
    echo @echo off
    echo call "%LIBSCRIPT_ROOT_DIR%\_lib\package-managers\rapps\cli.cmd" %%*
) > "!_INST_DIR!\bin\rapps.cmd"
if not exist "%LIBSCRIPT_HOME%\bin" mkdir "%LIBSCRIPT_HOME%\bin"
copy /y "!_INST_DIR!\bin\rapps.cmd" "%LIBSCRIPT_HOME%\bin\rapps.cmd" >nul 2>&1
echo installed> "!_STAMP!"
echo [OK] Installed rapps !_VER! to !_INST_DIR!.
exit /b 0

:: ## seed_db
:: Writes baseline RAPPS .txt INI entries for offline package metadata lookup.
:seed_db
set "_DBD=%~1"
(
    echo [Section]
    echo Name = 7-Zip
    echo Version = 24.08
    echo URLDownload = https://www.7-zip.org/a/7z2408.exe
    echo SHA256 = SKIP
    echo Installer = exe
    echo SilentParameters = /S
    echo [Section.amd64]
    echo URLDownload = https://www.7-zip.org/a/7z2408-x64.exe
    echo SHA256 = SKIP
    echo Installer = exe
    echo SilentParameters = /S
) > "!_DBD!\7zip.txt"
(
    echo [Section]
    echo Name = SumatraPDF
    echo Version = 3.5.2
    echo URLDownload = https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-install.exe
    echo SHA256 = SKIP
    echo Installer = exe
    echo SilentParameters = -s
) > "!_DBD!\sumatrapdf.txt"
(
    echo [Section]
    echo Name = Notepad++
    echo Version = 8.6.9
    echo URLDownload = https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.9/npp.8.6.9.Installer.exe
    echo SHA256 = SKIP
    echo Installer = exe
    echo SilentParameters = /S
) > "!_DBD!\notepadpp.txt"
(
    echo [Section]
    echo Name = VLC media player
    echo Version = 3.0.21
    echo URLDownload = https://get.videolan.org/vlc/3.0.21/win32/vlc-3.0.21-win32.exe
    echo SHA256 = SKIP
    echo Installer = exe
    echo SilentParameters = /S
) > "!_DBD!\vlc.txt"
exit /b 0

:: ## action_generic
:: Delegates generic lifecycle actions to versioning.cmd.
:action_generic
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_handle_generic_action "rapps" "%ACTION%" "%RAPPS_VERSION%" "libscript_native"
exit /b !errorlevel!
