@echo off
:: ## Overview
:: Windows setup for go-pm
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%GO_PM_VERSION%"=="" set GO_PM_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%GO_PM_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "GO_PM_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "GO_PM_INSTALL_METHOD=libscript_native"
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
if "%GO_PM_INSTALL_METHOD%"=="mise" ( mise ls go-pm & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="asdf" ( asdf list go-pm & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="vfox" ( vfox ls go-pm & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\go-pm" ( dir /b "%LIBSCRIPT_HOME%\go-pm" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%GO_PM_INSTALL_METHOD%"=="mise" ( mise ls-remote go-pm & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="asdf" ( asdf list all go-pm & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="vfox" ( vfox ls all go-pm & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%GO_PM_RELEASES_URL%"=="" (
    curl -sSL "%GO_PM_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/go-pm" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%GO_PM_INSTALL_METHOD%"=="mise" ( mise use "go-pm@%GO_PM_VERSION%" & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="asdf" ( asdf global go-pm "%GO_PM_VERSION%" & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="vfox" ( vfox use "go-pm@%GO_PM_VERSION%" & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%GO_PM_VERSION%"=="latest" (set "EXACT_VERSION=%GO_PM_VERSION%"
) else if "%GO_PM_VERSION%"=="lts" (set "EXACT_VERSION=%GO_PM_VERSION%"
) else (
    set "EXACT_VERSION=%GO_PM_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%GO_PM_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\go-pm\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\go-pm\%GO_PM_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%GO_PM_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading go-pm %GO_PM_VERSION% to %DOWNLOAD_DIR%\go-pm...
    if not exist "%DOWNLOAD_DIR%\go-pm" mkdir "%DOWNLOAD_DIR%\go-pm"
    if not "%GO_PM_DOWNLOAD_URL%"=="" (
        curl -sSL "%GO_PM_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\go-pm\go-pm-%GO_PM_VERSION%.zip"
    ) else (
        echo GO_PM_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%GO_PM_INSTALL_METHOD%"=="system" (
    winget install go-pm --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%GO_PM_INSTALL_METHOD%"=="mise" ( mise install "go-pm@%GO_PM_VERSION%" & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="asdf" ( asdf install go-pm "%GO_PM_VERSION%" & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="pkgx" ( pkgx install "go-pm@%GO_PM_VERSION%" & exit /b 0 )
if "%GO_PM_INSTALL_METHOD%"=="vfox" ( vfox add go-pm & vfox install "go-pm@%GO_PM_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\go-pm\%GO_PM_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing go-pm %GO_PM_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\go-pm\go-pm-%GO_PM_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\go-pm\go-pm-%GO_PM_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\go-pm\go-pm-%GO_PM_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\go-pm\go-pm-%GO_PM_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%GO_PM_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%GO_PM_DOWNLOAD_URL%" -o "%TEMP%\go-pm.zip"
        tar -xf "%TEMP%\go-pm.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for go-pm.
        exit /b 1
    )
) else (
    echo go-pm %GO_PM_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\go-pm\%GO_PM_VERSION%"
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
        set "SVC_NAME=libscript_go-pm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GO_PM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%GO_PM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %GO_PM_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_go-pm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GO_PM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%GO_PM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %GO_PM_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_go-pm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%GO_PM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%GO_PM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %GO_PM_INSTALL_METHOD%.
)
exit /b 0
