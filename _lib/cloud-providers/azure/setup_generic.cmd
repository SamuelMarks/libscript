@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for azure
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
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

if "%ACTION%"=="" set ACTION=install
if "%AZURE_VERSION%"=="" set AZURE_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%AZURE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "AZURE_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "AZURE_INSTALL_METHOD=libscript_native"
    )
)

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
if "%ACTION%"=="start" goto :action_service
if "%ACTION%"=="stop" goto :action_service
if "%ACTION%"=="restart" goto :action_service
if "%ACTION%"=="status" goto :action_service
if "%ACTION%"=="health" goto :action_service
if "%ACTION%"=="logs" goto :action_service
if "%ACTION%"=="up" goto :action_service
if "%ACTION%"=="down" goto :action_service
if "%ACTION%"=="install-service" goto :action_install_service
if "%ACTION%"=="uninstall-service" goto :action_uninstall_service
if /i "%~1"=="group" goto :action_group
if /i "%~1"=="project" goto :action_group
if /i "%~1"=="network" goto :action_network
if /i "%~1"=="firewall" goto :action_firewall
if /i "%~1"=="node" goto :action_node
goto :action_install
goto :action_install

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%AZURE_INSTALL_METHOD%"=="mise" ( mise ls azure & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="asdf" ( asdf list azure & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="vfox" ( vfox ls azure & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\azure" ( dir /b "%LIBSCRIPT_HOME%\azure" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%AZURE_INSTALL_METHOD%"=="mise" ( mise ls-remote azure & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="asdf" ( asdf list all azure & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="vfox" ( vfox ls all azure & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%AZURE_RELEASES_URL%"=="" (
    curl -sSL "%AZURE_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/MicrosoftDocs/azure-docs" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%AZURE_INSTALL_METHOD%"=="mise" ( mise use "azure@%AZURE_VERSION%" & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="asdf" ( asdf global azure "%AZURE_VERSION%" & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="vfox" ( vfox use "azure@%AZURE_VERSION%" & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%AZURE_VERSION%"=="latest" (set "EXACT_VERSION=%AZURE_VERSION%"
) else if "%AZURE_VERSION%"=="lts" (set "EXACT_VERSION=%AZURE_VERSION%"
) else (
    set "EXACT_VERSION=%AZURE_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%AZURE_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\azure\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\azure\%AZURE_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%AZURE_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading azure %AZURE_VERSION% to %DOWNLOAD_DIR%\azure...
    if not exist "%DOWNLOAD_DIR%\azure" mkdir "%DOWNLOAD_DIR%\azure"
    if not "%AZURE_DOWNLOAD_URL%"=="" (
        curl -sSL "%AZURE_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\azure\azure-%AZURE_VERSION%.zip"
    ) else (
        echo AZURE_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%AZURE_INSTALL_METHOD%"=="system" (
    winget install azure --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%AZURE_INSTALL_METHOD%"=="mise" ( mise install "azure@%AZURE_VERSION%" & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="asdf" ( asdf install azure "%AZURE_VERSION%" & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="pkgx" ( pkgx install "azure@%AZURE_VERSION%" & exit /b 0 )
if "%AZURE_INSTALL_METHOD%"=="vfox" ( vfox add azure & vfox install "azure@%AZURE_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\azure\%AZURE_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing azure %AZURE_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\azure\azure-%AZURE_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\azure\azure-%AZURE_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\azure\azure-%AZURE_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\azure\azure-%AZURE_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%AZURE_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%AZURE_DOWNLOAD_URL%" -o "%TEMP%\azure.zip"
        tar -xf "%TEMP%\azure.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for azure.
        exit /b 1
    )
) else (
    echo azure %AZURE_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\azure\%AZURE_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the service manager.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_azure"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%AZURE_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%AZURE_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %AZURE_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_azure"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%AZURE_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%AZURE_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %AZURE_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_azure"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%AZURE_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%AZURE_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %AZURE_INSTALL_METHOD%.
)
exit /b 0

:: ## action_group
:: Ensures or deletes an Azure Resource Group idempotently.
:action_group
set "_SUB=%~2"
set "_RG=%~3"
set "_LOC=%AZURE_LOCATION%"
if "!_LOC!"=="" set "_LOC=%LOCATION%"
if "!_LOC!"=="" set "_LOC=eastus"
if /i "%~4"=="--location" set "_LOC=%~5"
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] az group !_SUB! --name "!_RG!" --location "!_LOC!" >&2
    exit /b 0
)
for /f "delims=" %%E in ('az group exists --name "!_RG!" 2^>nul') do set "_RG_EX=%%E"
if /i "!_RG_EX!"=="true" (
    echo Resource group '!_RG!' already exists.
    exit /b 0
)
az group create --name "!_RG!" --location "!_LOC!" --output none
exit /b !ERRORLEVEL!

:: ## action_network
:: Creates or deletes an Azure VNet idempotently.
:action_network
set "_SUB=%~2"
set "_VNET=%~3"
set "_RG=%~4"
set "_LOC=%AZURE_LOCATION%"
if "!_LOC!"=="" set "_LOC=%LOCATION%"
if "!_LOC!"=="" set "_LOC=eastus"
if /i "%~5"=="--location" set "_LOC=%~6"
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] az network vnet !_SUB! -g "!_RG!" -n "!_VNET!" --location "!_LOC!" >&2
    exit /b 0
)
az network vnet show -g "!_RG!" -n "!_VNET!" >nul 2>&1
if not errorlevel 1 (
    echo VNet '!_VNET!' already exists.
    exit /b 0
)
az network vnet create -g "!_RG!" -n "!_VNET!" --subnet-name default --location "!_LOC!" --output none
exit /b !ERRORLEVEL!

:: ## action_firewall
:: Creates an Azure NSG and reconciles TCP port rules idempotently.
:action_firewall
set "_SUB=%~2"
set "_NSG=%~3"
set "_RG=%~4"
set "_PORTS=%~5"
if "!_PORTS!"=="" set "_PORTS=22"
set "_LOC=%AZURE_LOCATION%"
if "!_LOC!"=="" set "_LOC=%LOCATION%"
if "!_LOC!"=="" set "_LOC=eastus"
if /i "%~6"=="--location" set "_LOC=%~7"
if "!DRY_RUN!"=="true" (
    echo [DRY_RUN] az network nsg !_SUB! -g "!_RG!" -n "!_NSG!" --ports "!_PORTS!" >&2
    exit /b 0
)
az network nsg show -g "!_RG!" -n "!_NSG!" >nul 2>&1
if errorlevel 1 (
    az network nsg create -g "!_RG!" -n "!_NSG!" --location "!_LOC!" --output none
    if errorlevel 1 exit /b 1
)
set "_PRIORITY=1000"
for %%P in (!_PORTS!) do (
    az network nsg rule create -g "!_RG!" --nsg-name "!_NSG!" -n "AllowPort_%%P" --priority !_PRIORITY! --destination-port-ranges %%P --access Allow --protocol Tcp --output none
    set /a _PRIORITY+=10
)
exit /b 0

:: ## action_node
:: Manages Azure VM nodes (create, ip, exec, deploy, upload, download, sync, scp, scp-from).
:action_node
set "_SUB=%~2"
set "_NODE=%~3"
if /i "!_SUB!"=="create" (
    set "_IMG=%~4"
    set "_RG=%~5"
    if "!DRY_RUN!"=="true" (
        echo [DRY_RUN] az vm create -g "!_RG!" -n "!_NODE!" --image "!_IMG!" >&2
        exit /b 0
    )
    az vm show -g "!_RG!" -n "!_NODE!" >nul 2>&1
    if not errorlevel 1 (
        echo VM '!_NODE!' already exists in !_RG!.
        exit /b 0
    )
    az vm create -g "!_RG!" -n "!_NODE!" --image "!_IMG!" --size "%VM_SIZE%" --admin-username "%ADMIN_USER%" --generate-ssh-keys %6 %7 %8 %9 --output none
    exit /b !ERRORLEVEL!
)
set "_RG=%~4"
if "!DRY_RUN!"=="true" (
    if /i "!_SUB!"=="ip" (
        echo 203.0.113.10
        exit /b 0
    )
    echo [DRY_RUN] azure node !_SUB! !_NODE! !_RG! %5 %6 >&2
    exit /b 0
)
set "_IP="
for /f "tokens=*" %%I in ('az vm show -d -g "!_RG!" -n "!_NODE!" --query publicIps -o tsv 2^>nul') do set "_IP=%%I"
if "!_IP!"=="" (
    echo [ERROR] Could not resolve public IP for !_NODE! in !_RG! >&2
    exit /b 1
)
if /i "!_SUB!"=="ip" (
    echo !_IP!
    exit /b 0
)
if /i "!_SUB!"=="exec" (
    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 "%ADMIN_USER%@!_IP!" "%~5"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="sync" (
    where rsync >nul 2>&1
    if not errorlevel 1 (
        rsync -avz --exclude=".git" --exclude="vagrant" --exclude="cache" --exclude="tmp" --exclude="tests_tmp" --exclude="node_modules" --exclude=".venv" -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30" "!LIBSCRIPT_ROOT_DIR!/" "%ADMIN_USER%@!_IP!:~/libscript/"
        exit /b !ERRORLEVEL!
    )
    scp -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -r "!LIBSCRIPT_ROOT_DIR!" "%ADMIN_USER%@!_IP!:~/libscript"
    exit /b !ERRORLEVEL!
)
if /i "!_SUB!"=="deploy" goto :node_upload_impl
if /i "!_SUB!"=="upload" goto :node_upload_impl
if /i "!_SUB!"=="scp" goto :node_upload_impl
if /i "!_SUB!"=="download" goto :node_download_impl
if /i "!_SUB!"=="scp-from" goto :node_download_impl
exit /b 0

:: ## node_upload_impl
:: Uploads a local path to the remote Azure VM via rsync or scp with cache exclusions.
:node_upload_impl
set "_SRC=%~5"
set "_DST=%~6"
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 "%ADMIN_USER%@!_IP!" "mkdir -p !_DST!" >nul 2>&1
set "_SRC_RS=!_SRC!"
if exist "!_SRC!\*" (
    if not "!_SRC_RS:~-1!"=="/" if not "!_SRC_RS:~-1!"=="\" set "_SRC_RS=!_SRC_RS!/"
)
where rsync >nul 2>&1
if not errorlevel 1 (
    rsync -avz --exclude=".git" --exclude="node_modules" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="dist" --exclude="htmlcov" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30" "!_SRC_RS!" "%ADMIN_USER%@!_IP!:!_DST!"
    exit /b !ERRORLEVEL!
)
scp -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -r "!_SRC!" "%ADMIN_USER%@!_IP!:!_DST!"
exit /b !ERRORLEVEL!

:: ## node_download_impl
:: Downloads a remote path from the Azure VM to a local destination via rsync or scp.
:node_download_impl
set "_SRC=%~5"
set "_DST=%~6"
for %%D in ("!_DST!") do (
    if not exist "%%~dpD" mkdir "%%~dpD"
)
where rsync >nul 2>&1
if not errorlevel 1 (
    rsync -avz -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30" "%ADMIN_USER%@!_IP!:!_SRC!" "!_DST!"
    exit /b !ERRORLEVEL!
)
scp -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -r "%ADMIN_USER%@!_IP!:!_SRC!" "!_DST!"
exit /b !ERRORLEVEL!
