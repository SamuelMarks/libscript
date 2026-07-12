@echo off
:: ## Overview
:: Windows setup for busybox
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%BUSYBOX_VERSION%"=="" set BUSYBOX_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%BUSYBOX_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "BUSYBOX_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "BUSYBOX_INSTALL_METHOD=libscript_native"
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
if "%BUSYBOX_INSTALL_METHOD%"=="mise" ( mise ls busybox & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="asdf" ( asdf list busybox & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="vfox" ( vfox ls busybox & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\busybox" ( dir /b "%LIBSCRIPT_HOME%\busybox" )
exit /b 0

:action_ls_remote
if "%BUSYBOX_INSTALL_METHOD%"=="mise" ( mise ls-remote busybox & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="asdf" ( asdf list all busybox & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="vfox" ( vfox ls all busybox & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%BUSYBOX_RELEASES_URL%"=="" (
    curl -sSL "%BUSYBOX_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_use
if "%BUSYBOX_INSTALL_METHOD%"=="mise" ( mise use "busybox@%BUSYBOX_VERSION%" & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="asdf" ( asdf global busybox "%BUSYBOX_VERSION%" & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="vfox" ( vfox use "busybox@%BUSYBOX_VERSION%" & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%BUSYBOX_VERSION%"=="latest" (set "EXACT_VERSION=%BUSYBOX_VERSION%"
) else if "%BUSYBOX_VERSION%"=="lts" (set "EXACT_VERSION=%BUSYBOX_VERSION%"
) else (
    set "EXACT_VERSION=%BUSYBOX_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%BUSYBOX_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\busybox\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\busybox\%BUSYBOX_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%BUSYBOX_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading busybox %BUSYBOX_VERSION% to %DOWNLOAD_DIR%\busybox...
    if not exist "%DOWNLOAD_DIR%\busybox" mkdir "%DOWNLOAD_DIR%\busybox"
    if not "%BUSYBOX_DOWNLOAD_URL%"=="" (
        curl -sSL "%BUSYBOX_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\busybox\busybox-%BUSYBOX_VERSION%.zip"
    ) else (
        echo BUSYBOX_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%BUSYBOX_INSTALL_METHOD%"=="system" (
    winget install busybox --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%BUSYBOX_INSTALL_METHOD%"=="mise" ( mise install "busybox@%BUSYBOX_VERSION%" & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="asdf" ( asdf install busybox "%BUSYBOX_VERSION%" & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="pkgx" ( pkgx install "busybox@%BUSYBOX_VERSION%" & exit /b 0 )
if "%BUSYBOX_INSTALL_METHOD%"=="vfox" ( vfox add busybox & vfox install "busybox@%BUSYBOX_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\busybox\%BUSYBOX_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing busybox %BUSYBOX_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\busybox\busybox-%BUSYBOX_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\busybox\busybox-%BUSYBOX_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\busybox\busybox-%BUSYBOX_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\busybox\busybox-%BUSYBOX_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%BUSYBOX_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%BUSYBOX_DOWNLOAD_URL%" -o "%TEMP%\busybox.zip"
        tar -xf "%TEMP%\busybox.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for busybox.
    )
) else (
    echo busybox %BUSYBOX_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\busybox\%BUSYBOX_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_busybox"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%BUSYBOX_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%BUSYBOX_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %BUSYBOX_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_busybox"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%BUSYBOX_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%BUSYBOX_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %BUSYBOX_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_busybox"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%BUSYBOX_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%BUSYBOX_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %BUSYBOX_INSTALL_METHOD%.
)
exit /b 0
