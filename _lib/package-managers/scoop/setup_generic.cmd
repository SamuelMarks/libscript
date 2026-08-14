@echo off
:: ## Overview
:: Windows setup for scoop
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%SCOOP_VERSION%"=="" set SCOOP_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%SCOOP_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "SCOOP_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "SCOOP_INSTALL_METHOD=libscript_native"
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
if "%SCOOP_INSTALL_METHOD%"=="mise" ( mise ls scoop & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="asdf" ( asdf list scoop & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="vfox" ( vfox ls scoop & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\scoop" ( dir /b "%LIBSCRIPT_HOME%\scoop" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%SCOOP_INSTALL_METHOD%"=="mise" ( mise ls-remote scoop & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="asdf" ( asdf list all scoop & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="vfox" ( vfox ls all scoop & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%SCOOP_RELEASES_URL%"=="" (
    curl -sSL "%SCOOP_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/ScoopInstaller/Scoop" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%SCOOP_INSTALL_METHOD%"=="mise" ( mise use "scoop@%SCOOP_VERSION%" & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="asdf" ( asdf global scoop "%SCOOP_VERSION%" & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="vfox" ( vfox use "scoop@%SCOOP_VERSION%" & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%SCOOP_VERSION%"=="latest" (set "EXACT_VERSION=%SCOOP_VERSION%"
) else if "%SCOOP_VERSION%"=="lts" (set "EXACT_VERSION=%SCOOP_VERSION%"
) else (
    set "EXACT_VERSION=%SCOOP_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%SCOOP_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\scoop\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\scoop\%SCOOP_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%SCOOP_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading scoop %SCOOP_VERSION% to %DOWNLOAD_DIR%\scoop...
    if not exist "%DOWNLOAD_DIR%\scoop" mkdir "%DOWNLOAD_DIR%\scoop"
    if not "%SCOOP_DOWNLOAD_URL%"=="" (
        curl -sSL "%SCOOP_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\scoop\scoop-%SCOOP_VERSION%.zip"
    ) else (
        echo SCOOP_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%SCOOP_INSTALL_METHOD%"=="system" (
    winget install scoop --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%SCOOP_INSTALL_METHOD%"=="mise" ( mise install "scoop@%SCOOP_VERSION%" & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="asdf" ( asdf install scoop "%SCOOP_VERSION%" & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="pkgx" ( pkgx install "scoop@%SCOOP_VERSION%" & exit /b 0 )
if "%SCOOP_INSTALL_METHOD%"=="vfox" ( vfox add scoop & vfox install "scoop@%SCOOP_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\scoop\%SCOOP_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing scoop %SCOOP_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\scoop\scoop-%SCOOP_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\scoop\scoop-%SCOOP_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\scoop\scoop-%SCOOP_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\scoop\scoop-%SCOOP_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%SCOOP_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%SCOOP_DOWNLOAD_URL%" -o "%TEMP%\scoop.zip"
        tar -xf "%TEMP%\scoop.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for scoop.
    )
) else (
    echo scoop %SCOOP_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\scoop\%SCOOP_VERSION%"
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
        set "SVC_NAME=libscript_scoop"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SCOOP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%SCOOP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %SCOOP_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_scoop"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SCOOP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%SCOOP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %SCOOP_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_scoop"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SCOOP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%SCOOP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %SCOOP_INSTALL_METHOD%.
)
exit /b 0
