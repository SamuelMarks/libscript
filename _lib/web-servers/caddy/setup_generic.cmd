@echo off
:: ## Overview
:: Windows setup for caddy
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%CADDY_VERSION%"=="" set CADDY_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%CADDY_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "CADDY_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "CADDY_INSTALL_METHOD=libscript_native"
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
if "%CADDY_INSTALL_METHOD%"=="mise" ( mise ls caddy & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="asdf" ( asdf list caddy & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="vfox" ( vfox ls caddy & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\caddy" ( dir /b "%LIBSCRIPT_HOME%\caddy" )
exit /b 0

:action_ls_remote
if "%CADDY_INSTALL_METHOD%"=="mise" ( mise ls-remote caddy & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="asdf" ( asdf list all caddy & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="vfox" ( vfox ls all caddy & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CADDY_RELEASES_URL%"=="" (
    curl -sSL "%CADDY_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_use
if "%CADDY_INSTALL_METHOD%"=="mise" ( mise use "caddy@%CADDY_VERSION%" & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="asdf" ( asdf global caddy "%CADDY_VERSION%" & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="vfox" ( vfox use "caddy@%CADDY_VERSION%" & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%CADDY_VERSION%"=="latest" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/caddyserver/caddy/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else if "%CADDY_VERSION%"=="lts" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/caddyserver/caddy/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else (
    set "EXACT_VERSION=%CADDY_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%CADDY_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\caddy\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\caddy\%CADDY_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%CADDY_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading caddy %CADDY_VERSION% to %DOWNLOAD_DIR%\caddy...
    if not exist "%DOWNLOAD_DIR%\caddy" mkdir "%DOWNLOAD_DIR%\caddy"
    if not "%CADDY_DOWNLOAD_URL%"=="" (
        curl -sSL "%CADDY_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\caddy\caddy-%CADDY_VERSION%.zip"
    ) else (
        echo CADDY_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%CADDY_INSTALL_METHOD%"=="system" (
    winget install caddy --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%CADDY_INSTALL_METHOD%"=="mise" ( mise install "caddy@%CADDY_VERSION%" & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="asdf" ( asdf install caddy "%CADDY_VERSION%" & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="pkgx" ( pkgx install "caddy@%CADDY_VERSION%" & exit /b 0 )
if "%CADDY_INSTALL_METHOD%"=="vfox" ( vfox add caddy & vfox install "caddy@%CADDY_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\caddy\%CADDY_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing caddy %CADDY_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\caddy\caddy-%CADDY_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\caddy\caddy-%CADDY_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\caddy\caddy-%CADDY_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\caddy\caddy-%CADDY_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%CADDY_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%CADDY_DOWNLOAD_URL%" -o "%TEMP%\caddy.zip"
        tar -xf "%TEMP%\caddy.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for caddy.
    )
) else (
    echo caddy %CADDY_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\caddy\%CADDY_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_caddy"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CADDY_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%CADDY_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %CADDY_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_caddy"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CADDY_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%CADDY_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %CADDY_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_caddy"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CADDY_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%CADDY_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %CADDY_INSTALL_METHOD%.
)
exit /b 0
