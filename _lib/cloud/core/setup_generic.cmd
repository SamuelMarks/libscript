@echo off
:: ## Overview
:: Windows setup for core
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install
if "%CORE_VERSION%"=="" set CORE_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%CORE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "CORE_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "CORE_INSTALL_METHOD=libscript_native"
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

:: ## action_ls
:: Executes action_ls functionality.
:action_ls
if "%CORE_INSTALL_METHOD%"=="mise" ( mise ls core & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="asdf" ( asdf list core & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="vfox" ( vfox ls core & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\core" ( dir /b "%LIBSCRIPT_HOME%\core" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%CORE_INSTALL_METHOD%"=="mise" ( mise ls-remote core & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="asdf" ( asdf list all core & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="vfox" ( vfox ls all core & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CORE_RELEASES_URL%"=="" (
    curl -sSL "%CORE_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/google/cloud-core" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%CORE_INSTALL_METHOD%"=="mise" ( mise use "core@%CORE_VERSION%" & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="asdf" ( asdf global core "%CORE_VERSION%" & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="vfox" ( vfox use "core@%CORE_VERSION%" & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%CORE_VERSION%"=="latest" (set "EXACT_VERSION=%CORE_VERSION%"
) else if "%CORE_VERSION%"=="lts" (set "EXACT_VERSION=%CORE_VERSION%"
) else (
    set "EXACT_VERSION=%CORE_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%CORE_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\core\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\core\%CORE_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%CORE_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading core %CORE_VERSION% to %DOWNLOAD_DIR%\core...
    if not exist "%DOWNLOAD_DIR%\core" mkdir "%DOWNLOAD_DIR%\core"
    if not "%CORE_DOWNLOAD_URL%"=="" (
        curl -sSL "%CORE_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\core\core-%CORE_VERSION%.zip"
    ) else (
        echo CORE_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%CORE_INSTALL_METHOD%"=="system" (
    winget install core --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%CORE_INSTALL_METHOD%"=="mise" ( mise install "core@%CORE_VERSION%" & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="asdf" ( asdf install core "%CORE_VERSION%" & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="pkgx" ( pkgx install "core@%CORE_VERSION%" & exit /b 0 )
if "%CORE_INSTALL_METHOD%"=="vfox" ( vfox add core & vfox install "core@%CORE_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\core\%CORE_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing core %CORE_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\core\core-%CORE_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\core\core-%CORE_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\core\core-%CORE_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\core\core-%CORE_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%CORE_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%CORE_DOWNLOAD_URL%" -o "%TEMP%\core.zip"
        tar -xf "%TEMP%\core.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for core.
        exit /b 1
    )
) else (
    echo core %CORE_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\core\%CORE_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Executes action_service functionality.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_core"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CORE_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%CORE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %CORE_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_core"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CORE_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%CORE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %CORE_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_core"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CORE_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%CORE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %CORE_INSTALL_METHOD%.
)
exit /b 0
