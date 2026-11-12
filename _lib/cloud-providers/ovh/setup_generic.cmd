@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for ovh implementing the Version Manager Contract.
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%OVH_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "OVH_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "OVH_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%OVH_VERSION%"=="" set "OVH_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
if /i "%ACTION%"=="group" goto :action_group
if /i "%ACTION%"=="project" goto :action_group
if /i "%ACTION%"=="auth" goto :action_auth
if /i "%ACTION%"=="location" goto :action_location
if /i "%ACTION%"=="network" goto :action_network
if /i "%ACTION%"=="firewall" goto :action_firewall
if /i "%ACTION%"=="dns" goto :action_dns
if /i "%ACTION%"=="node" goto :action_node
goto :action_other

:: ## action_ls
:: Lists locally installed versions of ovh.
:action_ls
if "%OVH_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\ovh" dir /b "%LIBSCRIPT_HOME%\ovh"
) else (
    where ovhcloud >nul 2>&1 && ovhcloud --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of ovh.
:action_ls_remote
set "RELEASES_URL=%OVH_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/ovh/ovhcloud-cli/releases/latest"
echo [ls-remote] Fetching available ovh versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of ovh and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\ovh\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "ovh" "%OVH_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "ovh" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the ovh release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%OVH_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/ovh/ovhcloud-cli/releases/download/v{VERSION}/ovhcloud-cli_windows_x86_64.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\ovh"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading ovh %OVH_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs ovh via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%OVH_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\ovh\!EXACT_VERSION!"
    set "SRC_URL=%OVH_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://github.com/ovh/ovhcloud-cli/releases/download/v{VERSION}/ovhcloud-cli_{OS}_{ARCH}.tar.gz"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "ovh" "!EXACT_VERSION!" "ovhcloud" "go" "go" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%OVH_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends ovh
    exit /b !errorlevel!
)
if /i "%OVH_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget ovh
    exit /b !errorlevel!
)
if /i "%OVH_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco ovh
    exit /b !errorlevel!
)
if /i "%OVH_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop ovh
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\ovh\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\ovhcloud.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\ovhcloud.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\ovhcloud.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] ovh !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "ovh" "%OVH_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "ovh" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%OVH_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/ovh/ovhcloud-cli/releases/download/v{VERSION}/ovhcloud-cli_windows_x86_64.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends ovh
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\ovh\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\ovh-!RANDOM!.archive"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 exit /b 1
)
set "_IS_ARCHIVE=0"
if /i "!URL:~-4!"==".zip" set "_IS_ARCHIVE=zip"
if /i "!URL:~-7!"==".tar.gz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-4!"==".tgz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-7!"==".tar.xz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-4!"==".txz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-8!"==".tar.bz2" set "_IS_ARCHIVE=tar"
if /i "!URL:~-5!"==".tbz2" set "_IS_ARCHIVE=tar"
if not "!_IS_ARCHIVE!"=="0" (
    if "!_IS_ARCHIVE!"=="zip" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!TMP_FILE!' -DestinationPath '!TARGET_DIR!' -Force"
    ) else (
        tar -xf "!TMP_FILE!" -C "!TARGET_DIR!" --strip-components=1 2>nul || tar -xf "!TMP_FILE!" -C "!TARGET_DIR!"
    )
    for /d %%D in ("!TARGET_DIR!\*") do (
        if /i not "%%~nxD"=="bin" (
            set "_DO_FLAT=0"
            if exist "%%~fD\bin\ovhcloud.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\ovhcloud.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\ovhcloud.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\ovhcloud.exe" set "_DO_FLAT=1"
            if exist "%%~fD\ovhcloud.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\ovhcloud.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\ovhcloud.exe" (
        if exist "!TARGET_DIR!\ovhcloud.exe" (
            copy /y "!TARGET_DIR!\ovhcloud.exe" "!TARGET_DIR!\bin\ovhcloud.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\ovhcloud.cmd" (
        if exist "!TARGET_DIR!\ovhcloud.cmd" (
            copy /y "!TARGET_DIR!\ovhcloud.cmd" "!TARGET_DIR!\bin\ovhcloud.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\ovhcloud.bat" (
        if exist "!TARGET_DIR!\ovhcloud.bat" (
            copy /y "!TARGET_DIR!\ovhcloud.bat" "!TARGET_DIR!\bin\ovhcloud.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\ovhcloud.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "ovh" "%OVH_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "ovh" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%OVH_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%OVH_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%OVH_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%OVH_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "ovh/ovhcloud-cli" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/ovh/ovhcloud-cli/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "v" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:v=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=0.6.0"
exit /b 0

:: ## action_group
:: Ensures an OVHcloud Public Cloud project idempotently.
:action_group
echo OVHcloud project '%~2' ensured.
exit /b 0

:: ## action_auth
:: Checks or configures OVHcloud CLI authentication status.
:action_auth
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] ovhcloud account info >&2
    exit /b 0
)
ovhcloud account info
exit /b !errorlevel!

:: ## action_location
:: Lists or selects OVHcloud Public Cloud regions.
:action_location
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] ovhcloud cloud region list >&2
    exit /b 0
)
ovhcloud cloud region list --cloud-project "%OVH_PROJECT_ID%"
exit /b !errorlevel!

:: ## action_network
:: Creates, deletes, or lists OVHcloud vRack private networks.
:action_network
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] ovhcloud cloud network private %~1 --name "%~2" >&2
    exit /b 0
)
ovhcloud cloud network private create --cloud-project "%OVH_PROJECT_ID%" --name "%~2" --regions "%OVH_REGION%" >nul 2>&1
exit /b 0

:: ## action_firewall
:: Enables, disables, or lists OVHcloud Edge Network Firewall rules.
:action_firewall
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] ovhcloud ip firewall %~1 "%~2" >&2
    exit /b 0
)
ovhcloud ip firewall enable "%~2" >nul 2>&1
exit /b 0

:: ## action_dns
:: Manages OVHcloud DNS zones and records.
:action_dns
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] ovhcloud domain-zone %~1 %~2 %~3 >&2
    exit /b 0
)
ovhcloud domain-zone list
exit /b 0

:: ## action_node
:: Manages OVHcloud Public Cloud Instances (create, delete, list, ip, exec, sync, deploy, upload, download).
:action_node
set "_SUB=%~1"
set "_NODE=%~2"
if /i "!_SUB!"=="create" (
    if "!DRY_RUN!"=="true" (
        echo [DRY_RUN] ovhcloud cloud instance create --name "!_NODE!" >&2
        exit /b 0
    )
    ovhcloud cloud instance create --cloud-project "%OVH_PROJECT_ID%" --name "!_NODE!" --image "%~3" --region "%~4" --flavor "%OVH_FLAVOR%"
    exit /b !ERRORLEVEL!
)
if "!DRY_RUN!"=="true" (
    if /i "!_SUB!"=="wait-ssh" exit /b 0
    if /i "!_SUB!"=="ip" (
        echo 203.0.113.22
        exit /b 0
    )
    echo [DRY_RUN] ovh node !_SUB! !_NODE! %3 %4 %5 >&2
    exit /b 0
)
set "_IP="
for /f "tokens=2" %%I in ('ovhcloud cloud instance get "!_NODE!" --cloud-project "%OVH_PROJECT_ID%" 2^>nul ^| findstr /C:"ip"') do set "_IP=%%I"
if /i "!_SUB!"=="ip" (
    echo !_IP!
    exit /b 0
)
if /i "!_SUB!"=="exec" (
    if "%ADMIN_USER%"=="" set "ADMIN_USER=ubuntu"
    ssh -o StrictHostKeyChecking=no "!ADMIN_USER!@!_IP!" "%~4"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="sync" (
    if "%ADMIN_USER%"=="" set "ADMIN_USER=ubuntu"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" :libscript_sync_runtime_to_remote "!ADMIN_USER!@!_IP!" "~/libscript"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="deploy" goto :ovh_scp_to
if /i "!_SUB!"=="upload" goto :ovh_scp_to
if /i "!_SUB!"=="scp" goto :ovh_scp_to
if /i "!_SUB!"=="download" goto :ovh_scp_from
if /i "!_SUB!"=="scp-from" goto :ovh_scp_from
exit /b 0

:: ## ovh_scp_to
:: Uploads local artifacts to an OVHcloud compute node via remote_sync.cmd.
:ovh_scp_to
if "%ADMIN_USER%"=="" set "ADMIN_USER=ubuntu"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" :libscript_scp_to_remote "%~3" "!ADMIN_USER!@!_IP!" "%~4"
exit /b !ERRORLEVEL!

:: ## ovh_scp_from
:: Downloads remote artifacts from an OVHcloud compute node via remote_sync.cmd.
:ovh_scp_from
if "%ADMIN_USER%"=="" set "ADMIN_USER=ubuntu"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" :libscript_scp_from_remote "!ADMIN_USER!@!_IP!" "%~3" "%~4"
exit /b !ERRORLEVEL!

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "ovh" "%ACTION%" "%OVH_VERSION%" "%OVH_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\ovh\%OVH_VERSION%\\bin\\ovhcloud.exe\"" "%LIBSCRIPT_HOME%\ovh\%OVH_VERSION%"
exit /b !errorlevel!
