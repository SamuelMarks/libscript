@echo off
:: ## Overview
:: Windows setup for cpanm
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%CPANM_VERSION%"=="" set CPANM_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%CPANM_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "CPANM_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "CPANM_INSTALL_METHOD=libscript_native"
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
if "%CPANM_INSTALL_METHOD%"=="mise" ( mise ls cpanm & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="asdf" ( asdf list cpanm & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="vfox" ( vfox ls cpanm & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\cpanm" ( dir /b "%LIBSCRIPT_HOME%\cpanm" )
exit /b 0

:action_ls_remote
if "%CPANM_INSTALL_METHOD%"=="mise" ( mise ls-remote cpanm & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="asdf" ( asdf list all cpanm & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="vfox" ( vfox ls all cpanm & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CPANM_RELEASES_URL%"=="" (
    curl -sSL "%CPANM_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/miyagawa/cpanminus" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%CPANM_INSTALL_METHOD%"=="mise" ( mise use "cpanm@%CPANM_VERSION%" & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="asdf" ( asdf global cpanm "%CPANM_VERSION%" & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="vfox" ( vfox use "cpanm@%CPANM_VERSION%" & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%CPANM_VERSION%"=="latest" (set "EXACT_VERSION=%CPANM_VERSION%"
) else if "%CPANM_VERSION%"=="lts" (set "EXACT_VERSION=%CPANM_VERSION%"
) else (
    set "EXACT_VERSION=%CPANM_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%CPANM_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\cpanm\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\cpanm\%CPANM_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%CPANM_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading cpanm %CPANM_VERSION% to %DOWNLOAD_DIR%\cpanm...
    if not exist "%DOWNLOAD_DIR%\cpanm" mkdir "%DOWNLOAD_DIR%\cpanm"
    if not "%CPANM_DOWNLOAD_URL%"=="" (
        curl -sSL "%CPANM_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\cpanm\cpanm-%CPANM_VERSION%.zip"
    ) else (
        echo CPANM_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%CPANM_INSTALL_METHOD%"=="system" (
    winget install cpanm --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%CPANM_INSTALL_METHOD%"=="mise" ( mise install "cpanm@%CPANM_VERSION%" & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="asdf" ( asdf install cpanm "%CPANM_VERSION%" & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="pkgx" ( pkgx install "cpanm@%CPANM_VERSION%" & exit /b 0 )
if "%CPANM_INSTALL_METHOD%"=="vfox" ( vfox add cpanm & vfox install "cpanm@%CPANM_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\cpanm\%CPANM_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing cpanm %CPANM_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\cpanm\cpanm-%CPANM_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\cpanm\cpanm-%CPANM_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\cpanm\cpanm-%CPANM_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\cpanm\cpanm-%CPANM_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%CPANM_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%CPANM_DOWNLOAD_URL%" -o "%TEMP%\cpanm.zip"
        tar -xf "%TEMP%\cpanm.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for cpanm.
    )
) else (
    echo cpanm %CPANM_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\cpanm\%CPANM_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_cpanm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CPANM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%CPANM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %CPANM_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_cpanm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CPANM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%CPANM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %CPANM_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_cpanm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CPANM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%CPANM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %CPANM_INSTALL_METHOD%.
)
exit /b 0
