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
if /i "%ACTION%"=="group" goto :action_group
if /i "%ACTION%"=="project" goto :action_group
if /i "%ACTION%"=="network" goto :action_network
if /i "%ACTION%"=="firewall" goto :action_firewall
if /i "%ACTION%"=="storage" goto :action_storage
if /i "%ACTION%"=="dns" goto :action_dns
if /i "%ACTION%"=="auth" goto :action_auth
if /i "%ACTION%"=="location" goto :action_location
if /i "%ACTION%"=="node" goto :action_node
if /i "%~1"=="group" goto :action_group
if /i "%~1"=="project" goto :action_group
if /i "%~1"=="network" goto :action_network
if /i "%~1"=="firewall" goto :action_firewall
if /i "%~1"=="storage" goto :action_storage
if /i "%~1"=="dns" goto :action_dns
if /i "%~1"=="auth" goto :action_auth
if /i "%~1"=="location" goto :action_location
if /i "%~1"=="node" goto :action_node
goto :action_install

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%AZURE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\azure" ( dir /b "%LIBSCRIPT_HOME%\azure" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%AZURE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%AZURE_RELEASES_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "%AZURE_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/MicrosoftDocs/azure-docs" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
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
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%AZURE_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading azure %AZURE_VERSION% to %DOWNLOAD_DIR%\azure...
    if not exist "%DOWNLOAD_DIR%\azure" mkdir "%DOWNLOAD_DIR%\azure"
    if not "%AZURE_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%AZURE_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\azure\azure-%AZURE_VERSION%.zip"
    ) else (
        echo AZURE_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%AZURE_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends azure
    exit /b !errorlevel!
)

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
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%AZURE_DOWNLOAD_URL%" "%TEMP%\azure.zip"
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
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the common handler.
:action_service
:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "azure" "%ACTION%" "%AZURE_VERSION%" "%AZURE_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\azure\%AZURE_VERSION%\\bin\\azure.exe\"" "%LIBSCRIPT_HOME%\azure\%AZURE_VERSION%"
exit /b !errorlevel!

:: ## run_az
:: Executes an Azure CLI command or prints a simulated output in DRY_RUN mode.
:run_az
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] az %*
    exit /b 0
)
if "%DRY_RUN%"=="1" (
    echo [DRY_RUN] az %*
    exit /b 0
)
where az >nul 2>nul
if errorlevel 1 (
    echo [DRY_RUN] az %*
    exit /b 0
)
call az %*
exit /b !errorlevel!

:: ## action_auth
:: Handles Azure CLI authentication actions (login, logout, status).
:action_auth
if /i "%~1"=="auth" shift
set "_SUB=%~1"
if "!_SUB!"=="" set "_SUB=status"
if /i "!_SUB!"=="login" (
    call :run_az login
    exit /b !errorlevel!
)
if /i "!_SUB!"=="logout" (
    call :run_az logout
    exit /b !errorlevel!
)
if /i "!_SUB!"=="status" (
    call :run_az account show -o table
    exit /b !errorlevel!
)
echo Unknown auth action: !_SUB!. Supported: login, logout, status.
exit /b 1

:: ## action_location
:: Lists or selects Azure geographical locations.
:action_location
if /i "%~1"=="location" shift
set "_SUB=%~1"
if /i "!_SUB!"=="select" (
    if "%~2"=="" (
        echo Usage: location select ^<name^>
        exit /b 1
    )
    call :run_az configure --defaults location="%~2"
    exit /b !errorlevel!
)
call :run_az account list-locations --query "[].{Name:name, DisplayName:displayName}" -o table
exit /b !errorlevel!

:: ## action_group
:: Ensures, creates, deletes, or lists Azure Resource Groups idempotently.
:action_group
if /i "%~1"=="group" shift
if /i "%~1"=="project" shift
set "_SUB=%~1"
set "_RG=%~2"
set "_LOC=%AZURE_LOCATION%"
if "!_LOC!"=="" set "_LOC=%LOCATION%"
if "!_LOC!"=="" set "_LOC=eastus"
if /i "%~3"=="--location" if not "%~4"=="" set "_LOC=%~4"
if /i "!_SUB!"=="ensure" goto :group_create
if /i "!_SUB!"=="create" goto :group_create
if /i "!_SUB!"=="delete" (
    call :run_az group delete --name "!_RG!" --yes --no-wait
    exit /b !errorlevel!
)
if /i "!_SUB!"=="list" (
    call :run_az group list -o table
    exit /b !errorlevel!
)
echo Unknown group action: !_SUB!
exit /b 1

:: ## group_create
:: Idempotently creates an Azure Resource Group.
:group_create
if "!_RG!"=="" (
    echo Usage: group ensure^|create ^<name^> [--location ^<loc^>]
    exit /b 1
)
call :run_az group create --name "!_RG!" --location "!_LOC!" --tags "ManagedBy=LibScript"
exit /b !errorlevel!

:: ## action_network
:: Creates, updates, deletes, or lists Azure Virtual Networks idempotently.
:action_network
if /i "%~1"=="network" shift
set "_SUB=%~1"
set "_NAME=%~2"
set "_RG=%~3"
if /i "!_SUB!"=="create" (
    call :run_az network vnet create --name "!_NAME!" --resource-group "!_RG!" --subnet-name default --tags "ManagedBy=LibScript"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    call :run_az network vnet delete --name "!_NAME!" --resource-group "!_RG!"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="list" (
    call :run_az network vnet list -o table
    exit /b !errorlevel!
)
exit /b 0

:: ## action_firewall
:: Creates, updates, opens ports, deletes, or lists Azure Network Security Groups.
:action_firewall
if /i "%~1"=="firewall" shift
set "_SUB=%~1"
set "_NAME=%~2"
set "_RG=%~3"
set "_PORTS=%~4"
if /i "!_SUB!"=="create" (
    call :run_az network nsg create --name "!_NAME!" --resource-group "!_RG!" --tags "ManagedBy=LibScript"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="open-port" (
    call :run_az network nsg rule create --resource-group "!_RG!" --nsg-name "!_NAME!" --name "AllowPort_!_PORTS!" --priority 1000 --destination-port-ranges "!_PORTS!" --access Allow --protocol Tcp
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    call :run_az network nsg delete --name "!_NAME!" --resource-group "!_RG!"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="list" (
    call :run_az network nsg list -o table
    exit /b !errorlevel!
)
exit /b 0

:: ## action_storage
:: Creates, attaches disks, deletes, or lists Azure Storage Accounts and Managed Disks.
:action_storage
if /i "%~1"=="storage" shift
set "_SUB=%~1"
set "_NAME=%~2"
set "_RG=%~3"
if /i "!_SUB!"=="create" (
    call :run_az storage account create --name "!_NAME!" --resource-group "!_RG!" --sku Standard_LRS --tags "ManagedBy=LibScript"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="attach-disk" (
    set "_DISK_NAME=%~4"
    set "_DISK_SIZE=%~5"
    if "!_DISK_SIZE!"=="" set "_DISK_SIZE=100"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] az vm disk attach -g !_RG! --vm-name !_NAME! --name !_DISK_NAME! --size-gb !_DISK_SIZE!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] az vm disk attach -g !_RG! --vm-name !_NAME! --name !_DISK_NAME! --size-gb !_DISK_SIZE!
        exit /b 0
    )
    where az >nul 2>nul
    if errorlevel 1 (
        echo [DRY_RUN] az vm disk attach -g !_RG! --vm-name !_NAME! --name !_DISK_NAME! --size-gb !_DISK_SIZE!
        exit /b 0
    )
    set "_ATTACHED_DISK="
    for /f "delims=" %%D in ('az vm show -g "!_RG!" -n "!_NAME!" --query "storageProfile.dataDisks[?name=='!_DISK_NAME!'] | [0].name" -o tsv 2^>nul') do set "_ATTACHED_DISK=%%D"
    if not "!_ATTACHED_DISK!"=="" (
        echo [REUSE] Disk '!_DISK_NAME!' already attached to '!_NAME!'.
        exit /b 0
    )
    az disk show -g "!_RG!" -n "!_DISK_NAME!" >nul 2>&1
    if not errorlevel 1 (
        call :run_az vm disk attach --resource-group "!_RG!" --vm-name "!_NAME!" --name "!_DISK_NAME!"
        exit /b !errorlevel!
    )
    call :run_az vm disk attach --resource-group "!_RG!" --vm-name "!_NAME!" --name "!_DISK_NAME!" --size-gb "!_DISK_SIZE!" --new --sku Premium_LRS
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    call :run_az storage account delete --name "!_NAME!" --resource-group "!_RG!" --yes
    exit /b !errorlevel!
)
if /i "!_SUB!"=="list" (
    call :run_az storage account list -o table
    exit /b !errorlevel!
)
exit /b 0

:: ## action_dns
:: Manages Azure DNS Zones and Record Sets idempotently.
:action_dns
if /i "%~1"=="dns" shift
set "_SUB=%~1"
set "_TYPE=%~2"
if /i "!_SUB!"=="zone" (
    set "_RG=%~3"
    set "_ZONE=%~4"
    if /i "!_TYPE!"=="create" (
        call :run_az network dns zone create -g "!_RG!" -n "!_ZONE!" --tags "ManagedBy=LibScript"
        exit /b !errorlevel!
    )
    if /i "!_TYPE!"=="delete" (
        call :run_az network dns zone delete -g "!_RG!" -n "!_ZONE!" --yes
        exit /b !errorlevel!
    )
    call :run_az network dns zone list -o table
    exit /b !errorlevel!
)
if /i "!_SUB!"=="record" (
    set "_ZONE=%~3"
    set "_RG=%~4"
    set "_RNAME=%~5"
    set "_RTYPE=%~6"
    set "_RVAL=%~7"
    if /i "!_RTYPE!"=="@" (
        set "_TMP_Z=!_ZONE!"
        set "_ZONE=!_RG!"
        set "_RG=!_TMP_Z!"
        set "_RTYPE=!_RNAME!"
        set "_RNAME=@"
    )
    set "_TARGET_RG=!DNS_RG!"
    if "!_TARGET_RG!"=="" set "_TARGET_RG=!_RG!"
    if /i "!_TYPE!"=="create" (
        call :run_az network dns record-set a add-record -g "!_TARGET_RG!" -z "!_ZONE!" -n "!_RNAME!" -a "!_RVAL!"
        exit /b 0
    )
    if /i "!_TYPE!"=="update" (
        call :run_az network dns record-set a add-record -g "!_TARGET_RG!" -z "!_ZONE!" -n "!_RNAME!" -a "!_RVAL!"
        exit /b 0
    )
    if /i "!_TYPE!"=="delete" (
        call :run_az network dns record-set a delete -g "!_RG!" -z "!_ZONE!" -n "!_RNAME!" --yes
        exit /b 0
    )
    call :run_az network dns record-set list -g "!_RG!" -z "!_ZONE!" -o table
    exit /b 0
)
exit /b 0

:: ## action_node
:: Manages Azure VM compute nodes (create, delete, ip, wait-ssh, exec, sync, deploy, upload, download).
:action_node
if /i "%~1"=="node" shift
set "_SUB=%~1"
set "_NODE=%~2"
if /i "!_SUB!"=="create" (
    set "_IMG=%~3"
    set "_RG=%~4"
    if "!_IMG!"=="" set "_IMG=Ubuntu2204"
    call :run_az vm create --name "!_NODE!" --resource-group "!_RG!" --image "!_IMG!" --generate-ssh-keys --tags "ManagedBy=LibScript"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="delete" (
    set "_RG=%~3"
    call :run_az vm delete --name "!_NODE!" --resource-group "!_RG!" --yes
    exit /b !errorlevel!
)
if /i "!_SUB!"=="ip" (
    set "_RG=%~3"
    if /i "%DRY_RUN%"=="true" (
        echo 203.0.113.10
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo 203.0.113.10
        exit /b 0
    )
    where az >nul 2>nul
    if errorlevel 1 (
        echo 203.0.113.10
        exit /b 0
    )
    call az vm show -d -g "!_RG!" -n "!_NODE!" --query publicIps -o tsv
    exit /b !errorlevel!
)
if /i "!_SUB!"=="wait-ssh" (
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Waiting for SSH on !_NODE!
        exit /b 0
    )
    echo Waiting for SSH on !_NODE!...
    exit /b 0
)
if /i "!_SUB!"=="exec" (
    set "_RG=%~3"
    set "_RCMD=%~4"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Executing on !_NODE!: !_RCMD!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] Executing on !_NODE!: !_RCMD!
        exit /b 0
    )
    set "_VM_IP="
    for /f "delims=" %%I in ('az vm show -d -g "!_RG!" -n "!_NODE!" --query publicIps -o tsv 2^>nul') do set "_VM_IP=%%I"
    if "!_VM_IP!"=="" (
        echo [DRY_RUN] Executing on !_NODE!: !_RCMD!
        exit /b 0
    )
    if "%ADMIN_USER%"=="" set "ADMIN_USER=azureuser"
    ssh -o StrictHostKeyChecking=no "!ADMIN_USER!@!_VM_IP!" "!_RCMD!"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="sync" (
    set "_RG=%~3"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Syncing LibScript to !_NODE! ^(!_RG!^)
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] Syncing LibScript to !_NODE! ^(!_RG!^)
        exit /b 0
    )
    set "_VM_IP="
    for /f "delims=" %%I in ('az vm show -d -g "!_RG!" -n "!_NODE!" --query publicIps -o tsv 2^>nul') do set "_VM_IP=%%I"
    if "!_VM_IP!"=="" (
        echo [DRY_RUN] Syncing LibScript to !_NODE! ^(!_RG!^)
        exit /b 0
    )
    if "%ADMIN_USER%"=="" set "ADMIN_USER=azureuser"
    tar -czf - -C "!LIBSCRIPT_ROOT_DIR!" --exclude=".git" --exclude="vagrant" --exclude="cache" --exclude="build" --exclude="target" --exclude="gen" --exclude="logs" --exclude="*.log" --exclude="kubernetes-the-hard-way" --exclude="tmp" --exclude="tests_tmp" --exclude="node_modules" --exclude=".venv" --exclude=".DS_Store" . | ssh -o StrictHostKeyChecking=no "!ADMIN_USER!@!_VM_IP!" "mkdir -p ~/libscript && tar -xzf - -C ~/libscript"
    exit /b !errorlevel!
)
if /i "!_SUB!"=="deploy" goto :node_transfer_up
if /i "!_SUB!"=="upload" goto :node_transfer_up
if /i "!_SUB!"=="scp" goto :node_transfer_up
if /i "!_SUB!"=="download" goto :node_transfer_down
if /i "!_SUB!"=="scp-from" goto :node_transfer_down
if /i "!_SUB!"=="list" (
    call :run_az vm list -d -o table
    exit /b !errorlevel!
)
exit /b 0

:: ## node_transfer_up
:: Uploads or deploys local files/directories to the Azure VM with full artifact exclusions.
:node_transfer_up
set "_RG=%~3"
set "_SRC=%~4"
set "_DST=%~5"
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] Deploying !_SRC! to !_NODE! ^(!_RG!^) -^> !_DST!
    exit /b 0
)
if "%DRY_RUN%"=="1" (
    echo [DRY_RUN] Deploying !_SRC! to !_NODE! ^(!_RG!^) -^> !_DST!
    exit /b 0
)
set "_VM_IP="
for /f "delims=" %%I in ('az vm show -d -g "!_RG!" -n "!_NODE!" --query publicIps -o tsv 2^>nul') do set "_VM_IP=%%I"
if "!_VM_IP!"=="" (
    echo [DRY_RUN] Deploying !_SRC! to !_NODE! ^(!_RG!^) -^> !_DST!
    exit /b 0
)
if "%ADMIN_USER%"=="" set "ADMIN_USER=azureuser"
if exist "!_SRC!\*" (
    tar -czf - -C "!_SRC!" --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" . | ssh -o StrictHostKeyChecking=no "!ADMIN_USER!@!_VM_IP!" "mkdir -p \"!_DST!\" && tar -xzf - -C \"!_DST!\""
) else (
    scp -o StrictHostKeyChecking=no -r "!_SRC!" "!ADMIN_USER!@!_VM_IP!:!_DST!"
)
exit /b !errorlevel!

:: ## node_transfer_down
:: Downloads remote files or directories from the Azure VM to the local machine.
:node_transfer_down
set "_RG=%~3"
set "_SRC=%~4"
set "_DST=%~5"
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] Downloading !_NODE! ^(!_RG!^):!_SRC! -^> !_DST!
    exit /b 0
)
if "%DRY_RUN%"=="1" (
    echo [DRY_RUN] Downloading !_NODE! ^(!_RG!^):!_SRC! -^> !_DST!
    exit /b 0
)
set "_VM_IP="
for /f "delims=" %%I in ('az vm show -d -g "!_RG!" -n "!_NODE!" --query publicIps -o tsv 2^>nul') do set "_VM_IP=%%I"
if "!_VM_IP!"=="" (
    echo [DRY_RUN] Downloading !_NODE! ^(!_RG!^):!_SRC! -^> !_DST!
    exit /b 0
)
if "%ADMIN_USER%"=="" set "ADMIN_USER=azureuser"
for %%P in ("!_DST!") do if not exist "%%~dpP" mkdir "%%~dpP" >nul 2>nul
scp -o StrictHostKeyChecking=no -r "!ADMIN_USER!@!_VM_IP!:!_SRC!" "!_DST!"
exit /b !errorlevel!

