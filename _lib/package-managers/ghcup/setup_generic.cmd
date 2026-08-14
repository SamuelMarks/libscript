@echo off
:: ## Overview
:: Windows setup for ghcup
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%GHCUP_VERSION%"=="" set GHCUP_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%GHCUP_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "GHCUP_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "GHCUP_INSTALL_METHOD=libscript_native"
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
if "%GHCUP_INSTALL_METHOD%"=="mise" ( mise ls ghcup & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="asdf" ( asdf list ghcup & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="vfox" ( vfox ls ghcup & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\ghcup" ( dir /b "%LIBSCRIPT_HOME%\ghcup" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%GHCUP_INSTALL_METHOD%"=="mise" ( mise ls-remote ghcup & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="asdf" ( asdf list all ghcup & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="vfox" ( vfox ls all ghcup & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%GHCUP_RELEASES_URL%"=="" (
    curl -sSL "%GHCUP_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/ghcup" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%GHCUP_INSTALL_METHOD%"=="mise" ( mise use "ghcup@%GHCUP_VERSION%" & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="asdf" ( asdf global ghcup "%GHCUP_VERSION%" & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="vfox" ( vfox use "ghcup@%GHCUP_VERSION%" & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%GHCUP_VERSION%"=="latest" (set "EXACT_VERSION=%GHCUP_VERSION%"
) else if "%GHCUP_VERSION%"=="lts" (set "EXACT_VERSION=%GHCUP_VERSION%"
) else (
    set "EXACT_VERSION=%GHCUP_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%GHCUP_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\ghcup\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\ghcup\%GHCUP_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%GHCUP_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading ghcup %GHCUP_VERSION% to %DOWNLOAD_DIR%\ghcup...
    if not exist "%DOWNLOAD_DIR%\ghcup" mkdir "%DOWNLOAD_DIR%\ghcup"
    if not "%GHCUP_DOWNLOAD_URL%"=="" (
        curl -sSL "%GHCUP_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\ghcup\ghcup-%GHCUP_VERSION%.zip"
    ) else (
        echo GHCUP_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%GHCUP_INSTALL_METHOD%"=="system" (
    winget install ghcup --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%GHCUP_INSTALL_METHOD%"=="mise" ( mise install "ghcup@%GHCUP_VERSION%" & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="asdf" ( asdf install ghcup "%GHCUP_VERSION%" & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="pkgx" ( pkgx install "ghcup@%GHCUP_VERSION%" & exit /b 0 )
if "%GHCUP_INSTALL_METHOD%"=="vfox" ( vfox add ghcup & vfox install "ghcup@%GHCUP_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\ghcup\%GHCUP_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing ghcup %GHCUP_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\ghcup\ghcup-%GHCUP_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\ghcup\ghcup-%GHCUP_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\ghcup\ghcup-%GHCUP_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\ghcup\ghcup-%GHCUP_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%GHCUP_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%GHCUP_DOWNLOAD_URL%" -o "%TEMP%\ghcup.zip"
        tar -xf "%TEMP%\ghcup.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for ghcup.
    )
) else (
    echo ghcup %GHCUP_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\ghcup\%GHCUP_VERSION%"
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
        set "SVC_NAME=libscript_ghcup"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GHCUP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%GHCUP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %GHCUP_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_ghcup"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GHCUP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%GHCUP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %GHCUP_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_ghcup"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GHCUP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%GHCUP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %GHCUP_INSTALL_METHOD%.
)
exit /b 0
