@echo off
:: ## Overview
:: Windows setup for rust
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%RUST_VERSION%"=="" set RUST_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%RUST_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "RUST_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "RUST_INSTALL_METHOD=libscript_native"
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
if "%RUST_INSTALL_METHOD%"=="mise" ( mise ls rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="asdf" ( asdf list rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="vfox" ( vfox ls rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\rust" ( dir /b "%LIBSCRIPT_HOME%\rust" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%RUST_INSTALL_METHOD%"=="mise" ( mise ls rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="asdf" ( asdf list rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="vfox" ( vfox ls rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\rust" ( dir /b "%LIBSCRIPT_HOME%\rust" )
exit /b 0

:action_ls_remote
if "%RUST_INSTALL_METHOD%"=="mise" ( mise ls-remote rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="asdf" ( asdf list all rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="vfox" ( vfox ls all rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%RUST_RELEASES_URL%"=="" (
    curl -sSL "%RUST_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/rust" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_ls_remote
if "%RUST_INSTALL_METHOD%"=="mise" ( mise ls-remote rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="asdf" ( asdf list all rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="vfox" ( vfox ls all rust & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%RUST_RELEASES_URL%"=="" (
    curl -sSL "%RUST_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/rust" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%RUST_INSTALL_METHOD%"=="mise" ( mise use "rust@%RUST_VERSION%" & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="asdf" ( asdf global rust "%RUST_VERSION%" & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="vfox" ( vfox use "rust@%RUST_VERSION%" & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%RUST_VERSION%"=="latest" (set "EXACT_VERSION=%RUST_VERSION%"
) else if "%RUST_VERSION%"=="lts" (set "EXACT_VERSION=%RUST_VERSION%"
) else (
    set "EXACT_VERSION=%RUST_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%RUST_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\rust\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%RUST_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading rust %RUST_VERSION% to %DOWNLOAD_DIR%\rust...
    if not exist "%DOWNLOAD_DIR%\rust" mkdir "%DOWNLOAD_DIR%\rust"
    if not "%RUST_DOWNLOAD_URL%"=="" (
        curl -sSL "%RUST_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%.zip"
    ) else (
        echo RUST_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%RUST_INSTALL_METHOD%"=="system" (
    winget install rust --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%RUST_INSTALL_METHOD%"=="mise" ( mise install "rust@%RUST_VERSION%" & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="asdf" ( asdf install rust "%RUST_VERSION%" & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="pkgx" ( pkgx install "rust@%RUST_VERSION%" & exit /b 0 )
if "%RUST_INSTALL_METHOD%"=="vfox" ( vfox add rust & vfox install "rust@%RUST_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing rust %RUST_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\rust\rust-%RUST_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%RUST_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%RUST_DOWNLOAD_URL%" -o "%TEMP%\rust.zip"
        tar -xf "%TEMP%\rust.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for rust.
    )
) else (
    echo rust %RUST_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\rust\%RUST_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_rust"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%RUST_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%RUST_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %RUST_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_rust"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%RUST_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%RUST_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %RUST_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_rust"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%RUST_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%RUST_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %RUST_INSTALL_METHOD%.
)
exit /b 0
