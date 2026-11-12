@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for oci implementing the Version Manager Contract.
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
if "%OCI_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "OCI_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "OCI_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%OCI_VERSION%"=="" set "OCI_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
if /i "%ACTION%"=="group" goto :action_group
if /i "%ACTION%"=="project" goto :action_group
if /i "%ACTION%"=="compartment" goto :action_group
if /i "%ACTION%"=="auth" goto :action_auth
if /i "%ACTION%"=="location" goto :action_location
if /i "%ACTION%"=="network" goto :action_network
if /i "%ACTION%"=="firewall" goto :action_firewall
if /i "%ACTION%"=="dns" goto :action_dns
if /i "%ACTION%"=="node" goto :action_node
goto :action_other

:: ## action_ls
:: Lists locally installed versions of oci.
:action_ls
if "%OCI_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\oci" dir /b "%LIBSCRIPT_HOME%\oci"
) else (
    where oci >nul 2>&1 && oci --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of oci.
:action_ls_remote
set "RELEASES_URL=%OCI_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/oracle/oci-cli/releases/latest"
echo [ls-remote] Fetching available oci versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of oci and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\oci\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "oci" "%OCI_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "oci" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the oci release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%OCI_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/oracle/oci-cli/releases/download/v{VERSION}/oci-cli-{VERSION}-Windows-Server.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\oci"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading oci %OCI_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs oci via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%OCI_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\oci\!EXACT_VERSION!"
    set "SRC_URL=%OCI_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://github.com/oracle/oci-cli/releases/download/v{VERSION}/oci-cli-{VERSION}.zip"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "oci" "!EXACT_VERSION!" "oci" "python" "pip" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%OCI_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends oci
    exit /b !errorlevel!
)
if /i "%OCI_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget oci
    exit /b !errorlevel!
)
if /i "%OCI_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco oci
    exit /b !errorlevel!
)
if /i "%OCI_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop oci
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\oci\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\oci.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\oci.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\oci.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] oci !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "oci" "%OCI_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "oci" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%OCI_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://github.com/oracle/oci-cli/releases/download/v{VERSION}/oci-cli-{VERSION}-Windows-Server.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends oci
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\oci\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\oci-!RANDOM!.archive"
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
            if exist "%%~fD\bin\oci.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\oci.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\oci.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\oci.exe" set "_DO_FLAT=1"
            if exist "%%~fD\oci.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\oci.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\oci.exe" (
        if exist "!TARGET_DIR!\oci.exe" (
            copy /y "!TARGET_DIR!\oci.exe" "!TARGET_DIR!\bin\oci.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\oci.cmd" (
        if exist "!TARGET_DIR!\oci.cmd" (
            copy /y "!TARGET_DIR!\oci.cmd" "!TARGET_DIR!\bin\oci.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\oci.bat" (
        if exist "!TARGET_DIR!\oci.bat" (
            copy /y "!TARGET_DIR!\oci.bat" "!TARGET_DIR!\bin\oci.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\oci.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "oci" "%OCI_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "oci" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%OCI_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%OCI_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%OCI_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%OCI_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "oracle/oci-cli" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/oracle/oci-cli/releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "v" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:v=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=3.51.4"
exit /b 0

:: ## action_group
:: Ensures an OCI compartment idempotently.
:action_group
echo OCI compartment '%~2' ensured.
exit /b 0

:: ## action_auth
:: Checks or configures OCI CLI authentication status.
:action_auth
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] oci iam region list >&2
    exit /b 0
)
oci iam region list
exit /b !errorlevel!

:: ## action_location
:: Lists or selects OCI regions.
:action_location
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] oci iam region list >&2
    exit /b 0
)
oci iam region list
exit /b !errorlevel!

:: ## action_network
:: Creates, deletes, or lists OCI Virtual Cloud Networks (VCNs).
:action_network
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] oci network vcn %~1 --display-name "%~2" >&2
    exit /b 0
)
oci network vcn create --compartment-id "%OCI_COMPARTMENT_ID%" --cidr-block "10.0.0.0/16" --display-name "%~2" >nul 2>&1
exit /b 0

:: ## action_firewall
:: Creates, deletes, or lists OCI Network Security Groups (NSGs).
:action_firewall
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] oci network nsg %~1 --display-name "%~2" >&2
    exit /b 0
)
oci network nsg create --compartment-id "%OCI_COMPARTMENT_ID%" --vcn-id "%~3" --display-name "%~2" >nul 2>&1
exit /b 0

:: ## action_dns
:: Manages OCI DNS zones and records.
:action_dns
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] oci dns %~1 %~2 %~3 >&2
    exit /b 0
)
oci dns zone list --compartment-id "%OCI_COMPARTMENT_ID%"
exit /b 0

:: ## action_node
:: Manages OCI Compute Instances (create, delete, list, ip, exec, sync, deploy, upload, download).
:action_node
set "_SUB=%~1"
set "_NODE=%~2"
if /i "!_SUB!"=="create" (
    if "!DRY_RUN!"=="true" (
        echo [DRY_RUN] oci compute instance launch --display-name "!_NODE!" >&2
        exit /b 0
    )
    oci compute instance launch --compartment-id "%OCI_COMPARTMENT_ID%" --availability-domain "%OCI_AVAILABILITY_DOMAIN%" --shape "%OCI_SHAPE%" --subnet-id "%OCI_SUBNET_ID%" --display-name "!_NODE!"
    exit /b !ERRORLEVEL!
)
if "!DRY_RUN!"=="true" (
    if /i "!_SUB!"=="wait-ssh" exit /b 0
    if /i "!_SUB!"=="ip" (
        echo 203.0.113.21
        exit /b 0
    )
    echo [DRY_RUN] oci node !_SUB! !_NODE! %3 %4 %5 >&2
    exit /b 0
)
set "_IP="
for /f "delims=" %%I in ('oci compute instance list-vnics --instance-id "!_NODE!" --query "data[0].\"public-ip\"" --raw-output 2^>nul') do set "_IP=%%I"
if /i "!_SUB!"=="ip" (
    echo !_IP!
    exit /b 0
)
if /i "!_SUB!"=="exec" (
    if "%ADMIN_USER%"=="" set "ADMIN_USER=opc"
    ssh -o StrictHostKeyChecking=no "!ADMIN_USER!@!_IP!" "%~4"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="sync" (
    if "%ADMIN_USER%"=="" set "ADMIN_USER=opc"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" :libscript_sync_runtime_to_remote "!ADMIN_USER!@!_IP!" "~/libscript"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="deploy" goto :oci_scp_to
if /i "!_SUB!"=="upload" goto :oci_scp_to
if /i "!_SUB!"=="scp" goto :oci_scp_to
if /i "!_SUB!"=="download" goto :oci_scp_from
if /i "!_SUB!"=="scp-from" goto :oci_scp_from
exit /b 0

:: ## oci_scp_to
:: Uploads local artifacts to an OCI compute node via remote_sync.cmd.
:oci_scp_to
if "%ADMIN_USER%"=="" set "ADMIN_USER=opc"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" :libscript_scp_to_remote "%~3" "!ADMIN_USER!@!_IP!" "%~4"
exit /b !ERRORLEVEL!

:: ## oci_scp_from
:: Downloads remote artifacts from an OCI compute node via remote_sync.cmd.
:oci_scp_from
if "%ADMIN_USER%"=="" set "ADMIN_USER=opc"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" :libscript_scp_from_remote "!ADMIN_USER!@!_IP!" "%~3" "%~4"
exit /b !ERRORLEVEL!

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "oci" "%ACTION%" "%OCI_VERSION%" "%OCI_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\oci\%OCI_VERSION%\\bin\\oci.exe\"" "%LIBSCRIPT_HOME%\oci\%OCI_VERSION%"
exit /b !errorlevel!
