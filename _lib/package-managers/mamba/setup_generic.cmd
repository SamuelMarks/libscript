@echo off
:: ## Overview
:: Windows setup for mamba
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%MAMBA_VERSION%"=="" set MAMBA_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%MAMBA_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "MAMBA_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "MAMBA_INSTALL_METHOD=libscript_native"
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
if "%MAMBA_INSTALL_METHOD%"=="mise" ( mise ls mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="asdf" ( asdf list mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="vfox" ( vfox ls mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\mamba" ( dir /b "%LIBSCRIPT_HOME%\mamba" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%MAMBA_INSTALL_METHOD%"=="mise" ( mise ls mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="asdf" ( asdf list mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="vfox" ( vfox ls mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\mamba" ( dir /b "%LIBSCRIPT_HOME%\mamba" )
exit /b 0

:action_ls_remote
if "%MAMBA_INSTALL_METHOD%"=="mise" ( mise ls-remote mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="asdf" ( asdf list all mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="vfox" ( vfox ls all mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%MAMBA_RELEASES_URL%"=="" (
    curl -sSL "%MAMBA_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/mamba" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_ls_remote
if "%MAMBA_INSTALL_METHOD%"=="mise" ( mise ls-remote mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="asdf" ( asdf list all mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="vfox" ( vfox ls all mamba & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%MAMBA_RELEASES_URL%"=="" (
    curl -sSL "%MAMBA_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/mamba" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%MAMBA_INSTALL_METHOD%"=="mise" ( mise use "mamba@%MAMBA_VERSION%" & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="asdf" ( asdf global mamba "%MAMBA_VERSION%" & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="vfox" ( vfox use "mamba@%MAMBA_VERSION%" & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%MAMBA_VERSION%"=="latest" (set "EXACT_VERSION=%MAMBA_VERSION%"
) else if "%MAMBA_VERSION%"=="lts" (set "EXACT_VERSION=%MAMBA_VERSION%"
) else (
    set "EXACT_VERSION=%MAMBA_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%MAMBA_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\mamba\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\mamba\%MAMBA_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%MAMBA_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading mamba %MAMBA_VERSION% to %DOWNLOAD_DIR%\mamba...
    if not exist "%DOWNLOAD_DIR%\mamba" mkdir "%DOWNLOAD_DIR%\mamba"
    if not "%MAMBA_DOWNLOAD_URL%"=="" (
        curl -sSL "%MAMBA_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\mamba\mamba-%MAMBA_VERSION%.zip"
    ) else (
        echo MAMBA_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%MAMBA_INSTALL_METHOD%"=="system" (
    winget install mamba --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%MAMBA_INSTALL_METHOD%"=="mise" ( mise install "mamba@%MAMBA_VERSION%" & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="asdf" ( asdf install mamba "%MAMBA_VERSION%" & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="pkgx" ( pkgx install "mamba@%MAMBA_VERSION%" & exit /b 0 )
if "%MAMBA_INSTALL_METHOD%"=="vfox" ( vfox add mamba & vfox install "mamba@%MAMBA_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\mamba\%MAMBA_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing mamba %MAMBA_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\mamba\mamba-%MAMBA_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\mamba\mamba-%MAMBA_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\mamba\mamba-%MAMBA_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\mamba\mamba-%MAMBA_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%MAMBA_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%MAMBA_DOWNLOAD_URL%" -o "%TEMP%\mamba.zip"
        tar -xf "%TEMP%\mamba.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for mamba.
    )
) else (
    echo mamba %MAMBA_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\mamba\%MAMBA_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_mamba"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MAMBA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%MAMBA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %MAMBA_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_mamba"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MAMBA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%MAMBA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %MAMBA_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_mamba"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%MAMBA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%MAMBA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %MAMBA_INSTALL_METHOD%.
)
exit /b 0
