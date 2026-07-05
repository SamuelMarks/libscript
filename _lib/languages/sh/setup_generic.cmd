@echo off
:: ## Overview
:: Windows setup for sh
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%SH_VERSION%"=="" set SH_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%SH_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "SH_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "SH_INSTALL_METHOD=libscript_native"
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
if "%SH_INSTALL_METHOD%"=="mise" ( mise ls sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="asdf" ( asdf list sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="vfox" ( vfox ls sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\sh" ( dir /b "%LIBSCRIPT_HOME%\sh" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%SH_INSTALL_METHOD%"=="mise" ( mise ls sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="asdf" ( asdf list sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="vfox" ( vfox ls sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\sh" ( dir /b "%LIBSCRIPT_HOME%\sh" )
exit /b 0

:action_ls_remote
if "%SH_INSTALL_METHOD%"=="mise" ( mise ls-remote sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="asdf" ( asdf list all sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="vfox" ( vfox ls all sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%SH_RELEASES_URL%"=="" (
    curl -sSL "%SH_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/bminor/bash" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_ls_remote
if "%SH_INSTALL_METHOD%"=="mise" ( mise ls-remote sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="asdf" ( asdf list all sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="vfox" ( vfox ls all sh & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%SH_RELEASES_URL%"=="" (
    curl -sSL "%SH_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/bminor/bash" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%SH_INSTALL_METHOD%"=="mise" ( mise use "sh@%SH_VERSION%" & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="asdf" ( asdf global sh "%SH_VERSION%" & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="vfox" ( vfox use "sh@%SH_VERSION%" & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%SH_VERSION%"=="latest" (set "EXACT_VERSION=%SH_VERSION%"
) else if "%SH_VERSION%"=="lts" (set "EXACT_VERSION=%SH_VERSION%"
) else (
    set "EXACT_VERSION=%SH_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%SH_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\sh\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\sh\%SH_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%SH_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading sh %SH_VERSION% to %DOWNLOAD_DIR%\sh...
    if not exist "%DOWNLOAD_DIR%\sh" mkdir "%DOWNLOAD_DIR%\sh"
    if not "%SH_DOWNLOAD_URL%"=="" (
        curl -sSL "%SH_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\sh\sh-%SH_VERSION%.zip"
    ) else (
        echo SH_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%SH_INSTALL_METHOD%"=="system" (
    winget install sh --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%SH_INSTALL_METHOD%"=="mise" ( mise install "sh@%SH_VERSION%" & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="asdf" ( asdf install sh "%SH_VERSION%" & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="pkgx" ( pkgx install "sh@%SH_VERSION%" & exit /b 0 )
if "%SH_INSTALL_METHOD%"=="vfox" ( vfox add sh & vfox install "sh@%SH_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\sh\%SH_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing sh %SH_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\sh\sh-%SH_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\sh\sh-%SH_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\sh\sh-%SH_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\sh\sh-%SH_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%SH_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%SH_DOWNLOAD_URL%" -o "%TEMP%\sh.zip"
        tar -xf "%TEMP%\sh.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for sh.
    )
) else (
    echo sh %SH_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\sh\%SH_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_sh"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SH_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%SH_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %SH_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_sh"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SH_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%SH_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %SH_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_sh"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SH_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%SH_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %SH_INSTALL_METHOD%.
)
exit /b 0
