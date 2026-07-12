@echo off
:: ## Overview
:: Windows setup for azure-cli
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%AZURE_CLI_VERSION%"=="" set AZURE_CLI_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%AZURE_CLI_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "AZURE_CLI_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "AZURE_CLI_INSTALL_METHOD=libscript_native"
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
goto :action_install
goto :action_install

:action_ls
if "%AZURE_CLI_INSTALL_METHOD%"=="mise" ( mise ls azure-cli & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="asdf" ( asdf list azure-cli & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="vfox" ( vfox ls azure-cli & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\azure-cli" ( dir /b "%LIBSCRIPT_HOME%\azure-cli" )
exit /b 0

:action_ls_remote
if "%AZURE_CLI_INSTALL_METHOD%"=="mise" ( mise ls-remote azure-cli & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="asdf" ( asdf list all azure-cli & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="vfox" ( vfox ls all azure-cli & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%AZURE_CLI_RELEASES_URL%"=="" (
    curl -sSL "%AZURE_CLI_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/azure-cli" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%AZURE_CLI_INSTALL_METHOD%"=="mise" ( mise use "azure-cli@%AZURE_CLI_VERSION%" & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="asdf" ( asdf global azure-cli "%AZURE_CLI_VERSION%" & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="vfox" ( vfox use "azure-cli@%AZURE_CLI_VERSION%" & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%AZURE_CLI_VERSION%"=="latest" (set "EXACT_VERSION=%AZURE_CLI_VERSION%"
) else if "%AZURE_CLI_VERSION%"=="lts" (set "EXACT_VERSION=%AZURE_CLI_VERSION%"
) else (
    set "EXACT_VERSION=%AZURE_CLI_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%AZURE_CLI_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\azure-cli\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\azure-cli\%AZURE_CLI_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%AZURE_CLI_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading azure-cli %AZURE_CLI_VERSION% to %DOWNLOAD_DIR%\azure-cli...
    if not exist "%DOWNLOAD_DIR%\azure-cli" mkdir "%DOWNLOAD_DIR%\azure-cli"
    if not "%AZURE_CLI_DOWNLOAD_URL%"=="" (
        curl -sSL "%AZURE_CLI_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\azure-cli\azure-cli-%AZURE_CLI_VERSION%.zip"
    ) else (
        echo AZURE_CLI_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%AZURE_CLI_INSTALL_METHOD%"=="system" (
    winget install azure-cli --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%AZURE_CLI_INSTALL_METHOD%"=="mise" ( mise install "azure-cli@%AZURE_CLI_VERSION%" & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="asdf" ( asdf install azure-cli "%AZURE_CLI_VERSION%" & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="pkgx" ( pkgx install "azure-cli@%AZURE_CLI_VERSION%" & exit /b 0 )
if "%AZURE_CLI_INSTALL_METHOD%"=="vfox" ( vfox add azure-cli & vfox install "azure-cli@%AZURE_CLI_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\azure-cli\%AZURE_CLI_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing azure-cli %AZURE_CLI_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\azure-cli\azure-cli-%AZURE_CLI_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\azure-cli\azure-cli-%AZURE_CLI_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\azure-cli\azure-cli-%AZURE_CLI_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\azure-cli\azure-cli-%AZURE_CLI_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%AZURE_CLI_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%AZURE_CLI_DOWNLOAD_URL%" -o "%TEMP%\azure-cli.zip"
        tar -xf "%TEMP%\azure-cli.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for azure-cli.
    )
) else (
    echo azure-cli %AZURE_CLI_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\azure-cli\%AZURE_CLI_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_azure-cli"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%AZURE_CLI_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%AZURE_CLI_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %AZURE_CLI_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_azure-cli"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%AZURE_CLI_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%AZURE_CLI_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %AZURE_CLI_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_azure-cli"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%AZURE_CLI_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%AZURE_CLI_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %AZURE_CLI_INSTALL_METHOD%.
)
exit /b 0
