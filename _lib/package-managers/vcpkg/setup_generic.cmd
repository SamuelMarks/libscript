@echo off
:: ## Overview
:: Windows setup for vcpkg
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%VCPKG_VERSION%"=="" set VCPKG_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%VCPKG_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "VCPKG_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "VCPKG_INSTALL_METHOD=libscript_native"
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
if "%VCPKG_INSTALL_METHOD%"=="mise" ( mise ls vcpkg & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="asdf" ( asdf list vcpkg & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="vfox" ( vfox ls vcpkg & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\vcpkg" ( dir /b "%LIBSCRIPT_HOME%\vcpkg" )
exit /b 0

:action_ls_remote
if "%VCPKG_INSTALL_METHOD%"=="mise" ( mise ls-remote vcpkg & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="asdf" ( asdf list all vcpkg & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="vfox" ( vfox ls all vcpkg & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%VCPKG_RELEASES_URL%"=="" (
    curl -sSL "%VCPKG_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/microsoft/vcpkg" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%VCPKG_INSTALL_METHOD%"=="mise" ( mise use "vcpkg@%VCPKG_VERSION%" & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="asdf" ( asdf global vcpkg "%VCPKG_VERSION%" & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="vfox" ( vfox use "vcpkg@%VCPKG_VERSION%" & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%VCPKG_VERSION%"=="latest" (set "EXACT_VERSION=%VCPKG_VERSION%"
) else if "%VCPKG_VERSION%"=="lts" (set "EXACT_VERSION=%VCPKG_VERSION%"
) else (
    set "EXACT_VERSION=%VCPKG_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%VCPKG_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\vcpkg\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\vcpkg\%VCPKG_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%VCPKG_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading vcpkg %VCPKG_VERSION% to %DOWNLOAD_DIR%\vcpkg...
    if not exist "%DOWNLOAD_DIR%\vcpkg" mkdir "%DOWNLOAD_DIR%\vcpkg"
    if not "%VCPKG_DOWNLOAD_URL%"=="" (
        curl -sSL "%VCPKG_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\vcpkg\vcpkg-%VCPKG_VERSION%.zip"
    ) else (
        echo VCPKG_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%VCPKG_INSTALL_METHOD%"=="system" (
    winget install vcpkg --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%VCPKG_INSTALL_METHOD%"=="mise" ( mise install "vcpkg@%VCPKG_VERSION%" & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="asdf" ( asdf install vcpkg "%VCPKG_VERSION%" & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="pkgx" ( pkgx install "vcpkg@%VCPKG_VERSION%" & exit /b 0 )
if "%VCPKG_INSTALL_METHOD%"=="vfox" ( vfox add vcpkg & vfox install "vcpkg@%VCPKG_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\vcpkg\%VCPKG_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing vcpkg %VCPKG_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\vcpkg\vcpkg-%VCPKG_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\vcpkg\vcpkg-%VCPKG_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\vcpkg\vcpkg-%VCPKG_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\vcpkg\vcpkg-%VCPKG_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%VCPKG_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%VCPKG_DOWNLOAD_URL%" -o "%TEMP%\vcpkg.zip"
        tar -xf "%TEMP%\vcpkg.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for vcpkg.
    )
) else (
    echo vcpkg %VCPKG_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\vcpkg\%VCPKG_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_vcpkg"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%VCPKG_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%VCPKG_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %VCPKG_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_vcpkg"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%VCPKG_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%VCPKG_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %VCPKG_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_vcpkg"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%VCPKG_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%VCPKG_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %VCPKG_INSTALL_METHOD%.
)
exit /b 0
