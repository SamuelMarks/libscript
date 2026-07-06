@echo off
:: ## Overview
:: Windows setup for asdf
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%ASDF_VERSION%"=="" set ASDF_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%ASDF_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "ASDF_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "ASDF_INSTALL_METHOD=libscript_native"
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
if "%ASDF_INSTALL_METHOD%"=="mise" ( mise ls asdf & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="asdf" ( asdf list asdf & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="vfox" ( vfox ls asdf & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\asdf" ( dir /b "%LIBSCRIPT_HOME%\asdf" )
exit /b 0

:action_ls_remote
if "%ASDF_INSTALL_METHOD%"=="mise" ( mise ls-remote asdf & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="asdf" ( asdf list all asdf & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="vfox" ( vfox ls all asdf & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%ASDF_RELEASES_URL%"=="" (
    curl -sSL "%ASDF_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/asdf" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%ASDF_INSTALL_METHOD%"=="mise" ( mise use "asdf@%ASDF_VERSION%" & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="asdf" ( asdf global asdf "%ASDF_VERSION%" & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="vfox" ( vfox use "asdf@%ASDF_VERSION%" & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%ASDF_VERSION%"=="latest" (set "EXACT_VERSION=%ASDF_VERSION%"
) else if "%ASDF_VERSION%"=="lts" (set "EXACT_VERSION=%ASDF_VERSION%"
) else (
    set "EXACT_VERSION=%ASDF_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%ASDF_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\asdf\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\asdf\%ASDF_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%ASDF_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading asdf %ASDF_VERSION% to %DOWNLOAD_DIR%\asdf...
    if not exist "%DOWNLOAD_DIR%\asdf" mkdir "%DOWNLOAD_DIR%\asdf"
    if not "%ASDF_DOWNLOAD_URL%"=="" (
        curl -sSL "%ASDF_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\asdf\asdf-%ASDF_VERSION%.zip"
    ) else (
        echo ASDF_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%ASDF_INSTALL_METHOD%"=="system" (
    winget install asdf --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%ASDF_INSTALL_METHOD%"=="mise" ( mise install "asdf@%ASDF_VERSION%" & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="asdf" ( asdf install asdf "%ASDF_VERSION%" & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="pkgx" ( pkgx install "asdf@%ASDF_VERSION%" & exit /b 0 )
if "%ASDF_INSTALL_METHOD%"=="vfox" ( vfox add asdf & vfox install "asdf@%ASDF_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\asdf\%ASDF_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing asdf %ASDF_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\asdf\asdf-%ASDF_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\asdf\asdf-%ASDF_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\asdf\asdf-%ASDF_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\asdf\asdf-%ASDF_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%ASDF_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%ASDF_DOWNLOAD_URL%" -o "%TEMP%\asdf.zip"
        tar -xf "%TEMP%\asdf.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for asdf.
    )
) else (
    echo asdf %ASDF_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\asdf\%ASDF_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_asdf"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ASDF_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%ASDF_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %ASDF_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_asdf"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ASDF_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%ASDF_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %ASDF_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_asdf"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ASDF_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%ASDF_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %ASDF_INSTALL_METHOD%.
)
exit /b 0
