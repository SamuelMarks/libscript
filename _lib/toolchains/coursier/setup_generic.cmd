@echo off
:: ## Overview
:: Windows setup for coursier
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%COURSIER_VERSION%"=="" set COURSIER_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%COURSIER_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "COURSIER_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "COURSIER_INSTALL_METHOD=libscript_native"
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
if "%COURSIER_INSTALL_METHOD%"=="mise" ( mise ls coursier & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="asdf" ( asdf list coursier & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="vfox" ( vfox ls coursier & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\coursier" ( dir /b "%LIBSCRIPT_HOME%\coursier" )
exit /b 0

:action_ls_remote
if "%COURSIER_INSTALL_METHOD%"=="mise" ( mise ls-remote coursier & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="asdf" ( asdf list all coursier & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="vfox" ( vfox ls all coursier & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%COURSIER_RELEASES_URL%"=="" (
    curl -sSL "%COURSIER_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_use
if "%COURSIER_INSTALL_METHOD%"=="mise" ( mise use "coursier@%COURSIER_VERSION%" & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="asdf" ( asdf global coursier "%COURSIER_VERSION%" & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="vfox" ( vfox use "coursier@%COURSIER_VERSION%" & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%COURSIER_VERSION%"=="latest" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/coursier/coursier/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else if "%COURSIER_VERSION%"=="lts" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/coursier/coursier/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else (
    set "EXACT_VERSION=%COURSIER_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%COURSIER_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\coursier\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\coursier\%COURSIER_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%COURSIER_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading coursier %COURSIER_VERSION% to %DOWNLOAD_DIR%\coursier...
    if not exist "%DOWNLOAD_DIR%\coursier" mkdir "%DOWNLOAD_DIR%\coursier"
    if not "%COURSIER_DOWNLOAD_URL%"=="" (
        curl -sSL "%COURSIER_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\coursier\coursier-%COURSIER_VERSION%.zip"
    ) else (
        echo COURSIER_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%COURSIER_INSTALL_METHOD%"=="system" (
    winget install coursier --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%COURSIER_INSTALL_METHOD%"=="mise" ( mise install "coursier@%COURSIER_VERSION%" & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="asdf" ( asdf install coursier "%COURSIER_VERSION%" & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="pkgx" ( pkgx install "coursier@%COURSIER_VERSION%" & exit /b 0 )
if "%COURSIER_INSTALL_METHOD%"=="vfox" ( vfox add coursier & vfox install "coursier@%COURSIER_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\coursier\%COURSIER_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing coursier %COURSIER_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\coursier\coursier-%COURSIER_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\coursier\coursier-%COURSIER_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\coursier\coursier-%COURSIER_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\coursier\coursier-%COURSIER_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%COURSIER_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%COURSIER_DOWNLOAD_URL%" -o "%TEMP%\coursier.zip"
        tar -xf "%TEMP%\coursier.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for coursier.
    )
) else (
    echo coursier %COURSIER_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\coursier\%COURSIER_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_coursier"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%COURSIER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%COURSIER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %COURSIER_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_coursier"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%COURSIER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%COURSIER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %COURSIER_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_coursier"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%COURSIER_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%COURSIER_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %COURSIER_INSTALL_METHOD%.
)
exit /b 0
