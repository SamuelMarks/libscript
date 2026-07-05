@echo off
:: ## Overview
:: Windows setup for lighttpd
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%LIGHTTPD_VERSION%"=="" set LIGHTTPD_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%LIGHTTPD_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "LIGHTTPD_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "LIGHTTPD_INSTALL_METHOD=libscript_native"
    )
)

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" if "%ACTION%"=="start" goto :action_service
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
if "%LIGHTTPD_INSTALL_METHOD%"=="mise" ( mise ls lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="asdf" ( asdf list lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="vfox" ( vfox ls lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\lighttpd" ( dir /b "%LIBSCRIPT_HOME%\lighttpd" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%LIGHTTPD_INSTALL_METHOD%"=="mise" ( mise ls lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="asdf" ( asdf list lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="vfox" ( vfox ls lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\lighttpd" ( dir /b "%LIBSCRIPT_HOME%\lighttpd" )
exit /b 0

:action_ls_remote
if "%LIGHTTPD_INSTALL_METHOD%"=="mise" ( mise ls-remote lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="asdf" ( asdf list all lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="vfox" ( vfox ls all lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%LIGHTTPD_RELEASES_URL%"=="" (
    curl -sSL "%LIGHTTPD_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_ls_remote
if "%LIGHTTPD_INSTALL_METHOD%"=="mise" ( mise ls-remote lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="asdf" ( asdf list all lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="vfox" ( vfox ls all lighttpd & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%LIGHTTPD_RELEASES_URL%"=="" (
    curl -sSL "%LIGHTTPD_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_use
if "%LIGHTTPD_INSTALL_METHOD%"=="mise" ( mise use "lighttpd@%LIGHTTPD_VERSION%" & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="asdf" ( asdf global lighttpd "%LIGHTTPD_VERSION%" & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="vfox" ( vfox use "lighttpd@%LIGHTTPD_VERSION%" & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%LIGHTTPD_VERSION%"=="latest" (set "EXACT_VERSION=%LIGHTTPD_VERSION%"
) else if "%LIGHTTPD_VERSION%"=="lts" (set "EXACT_VERSION=%LIGHTTPD_VERSION%"
) else (
    set "EXACT_VERSION=%LIGHTTPD_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%LIGHTTPD_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\lighttpd\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\lighttpd\%LIGHTTPD_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%LIGHTTPD_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading lighttpd %LIGHTTPD_VERSION% to %DOWNLOAD_DIR%\lighttpd...
    if not exist "%DOWNLOAD_DIR%\lighttpd" mkdir "%DOWNLOAD_DIR%\lighttpd"
    if not "%LIGHTTPD_DOWNLOAD_URL%"=="" (
        curl -sSL "%LIGHTTPD_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\lighttpd\lighttpd-%LIGHTTPD_VERSION%.zip"
    ) else (
        echo LIGHTTPD_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%LIGHTTPD_INSTALL_METHOD%"=="system" (
    winget install lighttpd --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%LIGHTTPD_INSTALL_METHOD%"=="mise" ( mise install "lighttpd@%LIGHTTPD_VERSION%" & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="asdf" ( asdf install lighttpd "%LIGHTTPD_VERSION%" & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="pkgx" ( pkgx install "lighttpd@%LIGHTTPD_VERSION%" & exit /b 0 )
if "%LIGHTTPD_INSTALL_METHOD%"=="vfox" ( vfox add lighttpd & vfox install "lighttpd@%LIGHTTPD_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\lighttpd\%LIGHTTPD_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing lighttpd %LIGHTTPD_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\lighttpd\lighttpd-%LIGHTTPD_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\lighttpd\lighttpd-%LIGHTTPD_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\lighttpd\lighttpd-%LIGHTTPD_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\lighttpd\lighttpd-%LIGHTTPD_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%LIGHTTPD_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%LIGHTTPD_DOWNLOAD_URL%" -o "%TEMP%\lighttpd.zip"
        tar -xf "%TEMP%\lighttpd.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for lighttpd.
    )
) else (
    echo lighttpd %LIGHTTPD_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\lighttpd\%LIGHTTPD_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_lighttpd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%LIGHTTPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%LIGHTTPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %LIGHTTPD_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_lighttpd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%LIGHTTPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%LIGHTTPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %LIGHTTPD_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_lighttpd"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%LIGHTTPD_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%LIGHTTPD_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %LIGHTTPD_INSTALL_METHOD%.
)
exit /b 0
