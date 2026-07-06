@echo off
:: ## Overview
:: Windows setup for duckdb
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%DUCKDB_VERSION%"=="" set DUCKDB_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%DUCKDB_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "DUCKDB_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "DUCKDB_INSTALL_METHOD=libscript_native"
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
if "%DUCKDB_INSTALL_METHOD%"=="mise" ( mise ls duckdb & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="asdf" ( asdf list duckdb & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="vfox" ( vfox ls duckdb & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\duckdb" ( dir /b "%LIBSCRIPT_HOME%\duckdb" )
exit /b 0

:action_ls_remote
if "%DUCKDB_INSTALL_METHOD%"=="mise" ( mise ls-remote duckdb & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="asdf" ( asdf list all duckdb & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="vfox" ( vfox ls all duckdb & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%DUCKDB_RELEASES_URL%"=="" (
    curl -sSL "%DUCKDB_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/duckdb/duckdb" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%DUCKDB_INSTALL_METHOD%"=="mise" ( mise use "duckdb@%DUCKDB_VERSION%" & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="asdf" ( asdf global duckdb "%DUCKDB_VERSION%" & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="vfox" ( vfox use "duckdb@%DUCKDB_VERSION%" & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%DUCKDB_VERSION%"=="latest" (set "EXACT_VERSION=%DUCKDB_VERSION%"
) else if "%DUCKDB_VERSION%"=="lts" (set "EXACT_VERSION=%DUCKDB_VERSION%"
) else (
    set "EXACT_VERSION=%DUCKDB_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%DUCKDB_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\duckdb\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%DUCKDB_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading duckdb %DUCKDB_VERSION% to %DOWNLOAD_DIR%\duckdb...
    if not exist "%DOWNLOAD_DIR%\duckdb" mkdir "%DOWNLOAD_DIR%\duckdb"
    if not "%DUCKDB_DOWNLOAD_URL%"=="" (
        curl -sSL "%DUCKDB_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.zip"
    ) else (
        echo DUCKDB_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%DUCKDB_INSTALL_METHOD%"=="system" (
    winget install duckdb --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%DUCKDB_INSTALL_METHOD%"=="mise" ( mise install "duckdb@%DUCKDB_VERSION%" & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="asdf" ( asdf install duckdb "%DUCKDB_VERSION%" & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="pkgx" ( pkgx install "duckdb@%DUCKDB_VERSION%" & exit /b 0 )
if "%DUCKDB_INSTALL_METHOD%"=="vfox" ( vfox add duckdb & vfox install "duckdb@%DUCKDB_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing duckdb %DUCKDB_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%DUCKDB_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%DUCKDB_DOWNLOAD_URL%" -o "%TEMP%\duckdb.zip"
        tar -xf "%TEMP%\duckdb.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for duckdb.
    )
) else (
    echo duckdb %DUCKDB_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_duckdb"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DUCKDB_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%DUCKDB_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %DUCKDB_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_duckdb"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DUCKDB_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%DUCKDB_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %DUCKDB_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_duckdb"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DUCKDB_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%DUCKDB_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %DUCKDB_INSTALL_METHOD%.
)
exit /b 0
