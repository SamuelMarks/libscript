@echo off
:: ## Overview
:: Windows setup for aria2
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%ARIA2_VERSION%"=="" set ARIA2_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%ARIA2_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "ARIA2_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "ARIA2_INSTALL_METHOD=libscript_native"
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
if "%ARIA2_INSTALL_METHOD%"=="mise" ( mise ls aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="asdf" ( asdf list aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="vfox" ( vfox ls aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\aria2" ( dir /b "%LIBSCRIPT_HOME%\aria2" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%ARIA2_INSTALL_METHOD%"=="mise" ( mise ls aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="asdf" ( asdf list aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="vfox" ( vfox ls aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\aria2" ( dir /b "%LIBSCRIPT_HOME%\aria2" )
exit /b 0

:action_ls_remote
if "%ARIA2_INSTALL_METHOD%"=="mise" ( mise ls-remote aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="asdf" ( asdf list all aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="vfox" ( vfox ls all aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%ARIA2_RELEASES_URL%"=="" (
    curl -sSL "%ARIA2_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_ls_remote
if "%ARIA2_INSTALL_METHOD%"=="mise" ( mise ls-remote aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="asdf" ( asdf list all aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="vfox" ( vfox ls all aria2 & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%ARIA2_RELEASES_URL%"=="" (
    curl -sSL "%ARIA2_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_use
if "%ARIA2_INSTALL_METHOD%"=="mise" ( mise use "aria2@%ARIA2_VERSION%" & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="asdf" ( asdf global aria2 "%ARIA2_VERSION%" & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="vfox" ( vfox use "aria2@%ARIA2_VERSION%" & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%ARIA2_VERSION%"=="latest" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/aria2/aria2/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else if "%ARIA2_VERSION%"=="lts" (for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/aria2/aria2/releases/latest').tag_name -replace '^v',''"`) do set "EXACT_VERSION=%%a"
) else (
    set "EXACT_VERSION=%ARIA2_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%ARIA2_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\aria2\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\aria2\%ARIA2_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%ARIA2_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading aria2 %ARIA2_VERSION% to %DOWNLOAD_DIR%\aria2...
    if not exist "%DOWNLOAD_DIR%\aria2" mkdir "%DOWNLOAD_DIR%\aria2"
    if not "%ARIA2_DOWNLOAD_URL%"=="" (
        curl -sSL "%ARIA2_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\aria2\aria2-%ARIA2_VERSION%.zip"
    ) else (
        echo ARIA2_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%ARIA2_INSTALL_METHOD%"=="system" (
    winget install aria2 --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%ARIA2_INSTALL_METHOD%"=="mise" ( mise install "aria2@%ARIA2_VERSION%" & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="asdf" ( asdf install aria2 "%ARIA2_VERSION%" & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="pkgx" ( pkgx install "aria2@%ARIA2_VERSION%" & exit /b 0 )
if "%ARIA2_INSTALL_METHOD%"=="vfox" ( vfox add aria2 & vfox install "aria2@%ARIA2_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\aria2\%ARIA2_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing aria2 %ARIA2_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\aria2\aria2-%ARIA2_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\aria2\aria2-%ARIA2_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\aria2\aria2-%ARIA2_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\aria2\aria2-%ARIA2_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%ARIA2_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%ARIA2_DOWNLOAD_URL%" -o "%TEMP%\aria2.zip"
        tar -xf "%TEMP%\aria2.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for aria2.
    )
) else (
    echo aria2 %ARIA2_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\aria2\%ARIA2_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_aria2"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ARIA2_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%ARIA2_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %ARIA2_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_aria2"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ARIA2_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%ARIA2_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %ARIA2_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_aria2"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ARIA2_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%ARIA2_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %ARIA2_INSTALL_METHOD%.
)
exit /b 0
