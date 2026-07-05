@echo off
:: ## Overview
:: Windows setup for choco
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%CHOCO_VERSION%"=="" set CHOCO_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%CHOCO_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "CHOCO_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "CHOCO_INSTALL_METHOD=libscript_native"
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
if "%CHOCO_INSTALL_METHOD%"=="mise" ( mise ls choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="asdf" ( asdf list choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="vfox" ( vfox ls choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\choco" ( dir /b "%LIBSCRIPT_HOME%\choco" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%CHOCO_INSTALL_METHOD%"=="mise" ( mise ls choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="asdf" ( asdf list choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="vfox" ( vfox ls choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\choco" ( dir /b "%LIBSCRIPT_HOME%\choco" )
exit /b 0

:action_ls_remote
if "%CHOCO_INSTALL_METHOD%"=="mise" ( mise ls-remote choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="asdf" ( asdf list all choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="vfox" ( vfox ls all choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CHOCO_RELEASES_URL%"=="" (
    curl -sSL "%CHOCO_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/choco" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_ls_remote
if "%CHOCO_INSTALL_METHOD%"=="mise" ( mise ls-remote choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="asdf" ( asdf list all choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="vfox" ( vfox ls all choco & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CHOCO_RELEASES_URL%"=="" (
    curl -sSL "%CHOCO_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/choco" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%CHOCO_INSTALL_METHOD%"=="mise" ( mise use "choco@%CHOCO_VERSION%" & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="asdf" ( asdf global choco "%CHOCO_VERSION%" & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="vfox" ( vfox use "choco@%CHOCO_VERSION%" & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%CHOCO_VERSION%"=="latest" (set "EXACT_VERSION=%CHOCO_VERSION%"
) else if "%CHOCO_VERSION%"=="lts" (set "EXACT_VERSION=%CHOCO_VERSION%"
) else (
    set "EXACT_VERSION=%CHOCO_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%CHOCO_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\choco\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\choco\%CHOCO_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%CHOCO_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading choco %CHOCO_VERSION% to %DOWNLOAD_DIR%\choco...
    if not exist "%DOWNLOAD_DIR%\choco" mkdir "%DOWNLOAD_DIR%\choco"
    if not "%CHOCO_DOWNLOAD_URL%"=="" (
        curl -sSL "%CHOCO_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\choco\choco-%CHOCO_VERSION%.zip"
    ) else (
        echo CHOCO_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%CHOCO_INSTALL_METHOD%"=="system" (
    winget install choco --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%CHOCO_INSTALL_METHOD%"=="mise" ( mise install "choco@%CHOCO_VERSION%" & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="asdf" ( asdf install choco "%CHOCO_VERSION%" & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="pkgx" ( pkgx install "choco@%CHOCO_VERSION%" & exit /b 0 )
if "%CHOCO_INSTALL_METHOD%"=="vfox" ( vfox add choco & vfox install "choco@%CHOCO_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\choco\%CHOCO_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing choco %CHOCO_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\choco\choco-%CHOCO_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\choco\choco-%CHOCO_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\choco\choco-%CHOCO_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\choco\choco-%CHOCO_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%CHOCO_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%CHOCO_DOWNLOAD_URL%" -o "%TEMP%\choco.zip"
        tar -xf "%TEMP%\choco.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for choco.
    )
) else (
    echo choco %CHOCO_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\choco\%CHOCO_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_choco"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CHOCO_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%CHOCO_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %CHOCO_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_choco"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CHOCO_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%CHOCO_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %CHOCO_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_choco"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CHOCO_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%CHOCO_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %CHOCO_INSTALL_METHOD%.
)
exit /b 0
