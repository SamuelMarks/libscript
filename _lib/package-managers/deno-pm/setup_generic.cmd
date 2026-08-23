@echo off
:: ## Overview
:: Windows setup for deno-pm
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%DENO_PM_VERSION%"=="" set DENO_PM_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%DENO_PM_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "DENO_PM_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "DENO_PM_INSTALL_METHOD=libscript_native"
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
if "%DENO_PM_INSTALL_METHOD%"=="mise" ( mise ls deno-pm & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="asdf" ( asdf list deno-pm & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="vfox" ( vfox ls deno-pm & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\deno-pm" ( dir /b "%LIBSCRIPT_HOME%\deno-pm" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%DENO_PM_INSTALL_METHOD%"=="mise" ( mise ls-remote deno-pm & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="asdf" ( asdf list all deno-pm & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="vfox" ( vfox ls all deno-pm & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%DENO_PM_RELEASES_URL%"=="" (
    curl -sSL "%DENO_PM_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/rycont/pm-b310-w2-reversing-deno" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%DENO_PM_INSTALL_METHOD%"=="mise" ( mise use "deno-pm@%DENO_PM_VERSION%" & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="asdf" ( asdf global deno-pm "%DENO_PM_VERSION%" & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="vfox" ( vfox use "deno-pm@%DENO_PM_VERSION%" & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%DENO_PM_VERSION%"=="latest" (set "EXACT_VERSION=%DENO_PM_VERSION%"
) else if "%DENO_PM_VERSION%"=="lts" (set "EXACT_VERSION=%DENO_PM_VERSION%"
) else (
    set "EXACT_VERSION=%DENO_PM_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%DENO_PM_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\deno-pm\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\deno-pm\%DENO_PM_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%DENO_PM_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading deno-pm %DENO_PM_VERSION% to %DOWNLOAD_DIR%\deno-pm...
    if not exist "%DOWNLOAD_DIR%\deno-pm" mkdir "%DOWNLOAD_DIR%\deno-pm"
    if not "%DENO_PM_DOWNLOAD_URL%"=="" (
        curl -sSL "%DENO_PM_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\deno-pm\deno-pm-%DENO_PM_VERSION%.zip"
    ) else (
        echo DENO_PM_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%DENO_PM_INSTALL_METHOD%"=="system" (
    winget install deno-pm --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%DENO_PM_INSTALL_METHOD%"=="mise" ( mise install "deno-pm@%DENO_PM_VERSION%" & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="asdf" ( asdf install deno-pm "%DENO_PM_VERSION%" & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="pkgx" ( pkgx install "deno-pm@%DENO_PM_VERSION%" & exit /b 0 )
if "%DENO_PM_INSTALL_METHOD%"=="vfox" ( vfox add deno-pm & vfox install "deno-pm@%DENO_PM_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\deno-pm\%DENO_PM_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing deno-pm %DENO_PM_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\deno-pm\deno-pm-%DENO_PM_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\deno-pm\deno-pm-%DENO_PM_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\deno-pm\deno-pm-%DENO_PM_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\deno-pm\deno-pm-%DENO_PM_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%DENO_PM_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%DENO_PM_DOWNLOAD_URL%" -o "%TEMP%\deno-pm.zip"
        tar -xf "%TEMP%\deno-pm.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for deno-pm.
        exit /b 1
    )
) else (
    echo deno-pm %DENO_PM_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\deno-pm\%DENO_PM_VERSION%"
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
        set "SVC_NAME=libscript_deno-pm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DENO_PM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%DENO_PM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %DENO_PM_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_deno-pm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DENO_PM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%DENO_PM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %DENO_PM_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_deno-pm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%DENO_PM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%DENO_PM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %DENO_PM_INSTALL_METHOD%.
)
exit /b 0
