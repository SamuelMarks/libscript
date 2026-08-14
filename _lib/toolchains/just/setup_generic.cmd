@echo off
:: ## Overview
:: Windows setup for just
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%JUST_VERSION%"=="" set JUST_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%JUST_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "JUST_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "JUST_INSTALL_METHOD=libscript_native"
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
if "%JUST_INSTALL_METHOD%"=="mise" ( mise ls just & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="asdf" ( asdf list just & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="vfox" ( vfox ls just & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\just" ( dir /b "%LIBSCRIPT_HOME%\just" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%JUST_INSTALL_METHOD%"=="mise" ( mise ls-remote just & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="asdf" ( asdf list all just & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="vfox" ( vfox ls all just & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%JUST_RELEASES_URL%"=="" (
    curl -sSL "%JUST_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%JUST_INSTALL_METHOD%"=="mise" ( mise use "just@%JUST_VERSION%" & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="asdf" ( asdf global just "%JUST_VERSION%" & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="vfox" ( vfox use "just@%JUST_VERSION%" & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%JUST_VERSION%"=="latest" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/casey/just/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else if "%JUST_VERSION%"=="lts" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/casey/just/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else (
    set "EXACT_VERSION=%JUST_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%JUST_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\just\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\just\%JUST_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%JUST_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading just %JUST_VERSION% to %DOWNLOAD_DIR%\just...
    if not exist "%DOWNLOAD_DIR%\just" mkdir "%DOWNLOAD_DIR%\just"
    if not "%JUST_DOWNLOAD_URL%"=="" (
        curl -sSL "%JUST_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\just\just-%JUST_VERSION%.zip"
    ) else (
        echo JUST_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%JUST_INSTALL_METHOD%"=="system" (
    winget install just --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%JUST_INSTALL_METHOD%"=="mise" ( mise install "just@%JUST_VERSION%" & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="asdf" ( asdf install just "%JUST_VERSION%" & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="pkgx" ( pkgx install "just@%JUST_VERSION%" & exit /b 0 )
if "%JUST_INSTALL_METHOD%"=="vfox" ( vfox add just & vfox install "just@%JUST_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\just\%JUST_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing just %JUST_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\just\just-%JUST_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\just\just-%JUST_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\just\just-%JUST_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\just\just-%JUST_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%JUST_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%JUST_DOWNLOAD_URL%" -o "%TEMP%\just.zip"
        tar -xf "%TEMP%\just.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for just.
    )
) else (
    echo just %JUST_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\just\%JUST_VERSION%"
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
        set "SVC_NAME=libscript_just"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%JUST_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%JUST_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %JUST_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_just"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%JUST_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%JUST_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %JUST_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_just"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%JUST_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%JUST_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %JUST_INSTALL_METHOD%.
)
exit /b 0
