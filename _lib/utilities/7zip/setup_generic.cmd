@echo off
:: ## Overview
:: Windows setup for 7zip
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%SEVENZIP_VERSION%"=="" set SEVENZIP_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%SEVENZIP_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "SEVENZIP_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "SEVENZIP_INSTALL_METHOD=libscript_native"
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
if "%SEVENZIP_INSTALL_METHOD%"=="mise" ( mise ls 7zip & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="asdf" ( asdf list 7zip & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="vfox" ( vfox ls 7zip & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\7zip" ( dir /b "%LIBSCRIPT_HOME%\7zip" )
exit /b 0

:action_ls_remote
if "%SEVENZIP_INSTALL_METHOD%"=="mise" ( mise ls-remote 7zip & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="asdf" ( asdf list all 7zip & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="vfox" ( vfox ls all 7zip & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%SEVENZIP_RELEASES_URL%"=="" (
    curl -sSL "%SEVENZIP_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_use
if "%SEVENZIP_INSTALL_METHOD%"=="mise" ( mise use "7zip@%SEVENZIP_VERSION%" & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="asdf" ( asdf global 7zip "%SEVENZIP_VERSION%" & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="vfox" ( vfox use "7zip@%SEVENZIP_VERSION%" & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%SEVENZIP_VERSION%"=="latest" (set "EXACT_VERSION=%SEVENZIP_VERSION%"
) else if "%SEVENZIP_VERSION%"=="lts" (set "EXACT_VERSION=%SEVENZIP_VERSION%"
) else (
    set "EXACT_VERSION=%SEVENZIP_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%SEVENZIP_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\7zip\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\7zip\%SEVENZIP_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%SEVENZIP_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading 7zip %SEVENZIP_VERSION% to %DOWNLOAD_DIR%\7zip...
    if not exist "%DOWNLOAD_DIR%\7zip" mkdir "%DOWNLOAD_DIR%\7zip"
    if not "%SEVENZIP_DOWNLOAD_URL%"=="" (
        curl -sSL "%SEVENZIP_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\7zip\7zip-%SEVENZIP_VERSION%.zip"
    ) else (
        echo SEVENZIP_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%SEVENZIP_INSTALL_METHOD%"=="system" (
    winget install 7zip --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%SEVENZIP_INSTALL_METHOD%"=="mise" ( mise install "7zip@%SEVENZIP_VERSION%" & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="asdf" ( asdf install 7zip "%SEVENZIP_VERSION%" & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="pkgx" ( pkgx install "7zip@%SEVENZIP_VERSION%" & exit /b 0 )
if "%SEVENZIP_INSTALL_METHOD%"=="vfox" ( vfox add 7zip & vfox install "7zip@%SEVENZIP_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\7zip\%SEVENZIP_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing 7zip %SEVENZIP_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\7zip\7zip-%SEVENZIP_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\7zip\7zip-%SEVENZIP_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\7zip\7zip-%SEVENZIP_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\7zip\7zip-%SEVENZIP_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%SEVENZIP_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%SEVENZIP_DOWNLOAD_URL%" -o "%TEMP%\7zip.zip"
        tar -xf "%TEMP%\7zip.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for 7zip.
    )
) else (
    echo 7zip %SEVENZIP_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\7zip\%SEVENZIP_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_7zip"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SEVENZIP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%SEVENZIP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %SEVENZIP_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_7zip"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SEVENZIP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%SEVENZIP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %SEVENZIP_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_7zip"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%SEVENZIP_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%SEVENZIP_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %SEVENZIP_INSTALL_METHOD%.
)
exit /b 0
