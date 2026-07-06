@echo off
:: ## Overview
:: Windows setup for iis
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%IIS_VERSION%"=="" set IIS_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%IIS_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "IIS_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "IIS_INSTALL_METHOD=libscript_native"
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
if "%IIS_INSTALL_METHOD%"=="mise" ( mise ls iis & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="asdf" ( asdf list iis & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="vfox" ( vfox ls iis & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\iis" ( dir /b "%LIBSCRIPT_HOME%\iis" )
exit /b 0

:action_ls_remote
if "%IIS_INSTALL_METHOD%"=="mise" ( mise ls-remote iis & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="asdf" ( asdf list all iis & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="vfox" ( vfox ls all iis & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%IIS_RELEASES_URL%"=="" (
    curl -sSL "%IIS_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_use
if "%IIS_INSTALL_METHOD%"=="mise" ( mise use "iis@%IIS_VERSION%" & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="asdf" ( asdf global iis "%IIS_VERSION%" & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="vfox" ( vfox use "iis@%IIS_VERSION%" & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%IIS_VERSION%"=="latest" (set "EXACT_VERSION=%IIS_VERSION%"
) else if "%IIS_VERSION%"=="lts" (set "EXACT_VERSION=%IIS_VERSION%"
) else (
    set "EXACT_VERSION=%IIS_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%IIS_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\iis\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\iis\%IIS_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%IIS_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading iis %IIS_VERSION% to %DOWNLOAD_DIR%\iis...
    if not exist "%DOWNLOAD_DIR%\iis" mkdir "%DOWNLOAD_DIR%\iis"
    if not "%IIS_DOWNLOAD_URL%"=="" (
        curl -sSL "%IIS_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\iis\iis-%IIS_VERSION%.zip"
    ) else (
        echo IIS_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%IIS_INSTALL_METHOD%"=="system" (
    winget install iis --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%IIS_INSTALL_METHOD%"=="mise" ( mise install "iis@%IIS_VERSION%" & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="asdf" ( asdf install iis "%IIS_VERSION%" & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="pkgx" ( pkgx install "iis@%IIS_VERSION%" & exit /b 0 )
if "%IIS_INSTALL_METHOD%"=="vfox" ( vfox add iis & vfox install "iis@%IIS_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\iis\%IIS_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing iis %IIS_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\iis\iis-%IIS_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\iis\iis-%IIS_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\iis\iis-%IIS_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\iis\iis-%IIS_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%IIS_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%IIS_DOWNLOAD_URL%" -o "%TEMP%\iis.zip"
        tar -xf "%TEMP%\iis.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for iis.
    )
) else (
    echo iis %IIS_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\iis\%IIS_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_iis"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%IIS_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%IIS_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %IIS_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_iis"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%IIS_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%IIS_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %IIS_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_iis"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%IIS_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%IIS_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %IIS_INSTALL_METHOD%.
)
exit /b 0
