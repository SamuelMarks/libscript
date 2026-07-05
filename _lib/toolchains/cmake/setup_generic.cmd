@echo off
:: ## Overview
:: Windows setup for cmake
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%CMAKE_VERSION%"=="" set CMAKE_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%CMAKE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "CMAKE_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "CMAKE_INSTALL_METHOD=libscript_native"
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
if "%CMAKE_INSTALL_METHOD%"=="mise" ( mise ls cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="asdf" ( asdf list cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="vfox" ( vfox ls cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\cmake" ( dir /b "%LIBSCRIPT_HOME%\cmake" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%CMAKE_INSTALL_METHOD%"=="mise" ( mise ls cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="asdf" ( asdf list cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="vfox" ( vfox ls cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\cmake" ( dir /b "%LIBSCRIPT_HOME%\cmake" )
exit /b 0

:action_ls_remote
if "%CMAKE_INSTALL_METHOD%"=="mise" ( mise ls-remote cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="asdf" ( asdf list all cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="vfox" ( vfox ls all cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CMAKE_RELEASES_URL%"=="" (
    curl -sSL "%CMAKE_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_ls_remote
if "%CMAKE_INSTALL_METHOD%"=="mise" ( mise ls-remote cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="asdf" ( asdf list all cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="vfox" ( vfox ls all cmake & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CMAKE_RELEASES_URL%"=="" (
    curl -sSL "%CMAKE_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:action_use
if "%CMAKE_INSTALL_METHOD%"=="mise" ( mise use "cmake@%CMAKE_VERSION%" & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="asdf" ( asdf global cmake "%CMAKE_VERSION%" & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="vfox" ( vfox use "cmake@%CMAKE_VERSION%" & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%CMAKE_VERSION%"=="latest" (set "EXACT_VERSION=%CMAKE_VERSION%"
) else if "%CMAKE_VERSION%"=="lts" (set "EXACT_VERSION=%CMAKE_VERSION%"
) else (
    set "EXACT_VERSION=%CMAKE_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%CMAKE_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\cmake\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\cmake\%CMAKE_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%CMAKE_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading cmake %CMAKE_VERSION% to %DOWNLOAD_DIR%\cmake...
    if not exist "%DOWNLOAD_DIR%\cmake" mkdir "%DOWNLOAD_DIR%\cmake"
    if not "%CMAKE_DOWNLOAD_URL%"=="" (
        curl -sSL "%CMAKE_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\cmake\cmake-%CMAKE_VERSION%.zip"
    ) else (
        echo CMAKE_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%CMAKE_INSTALL_METHOD%"=="system" (
    winget install cmake --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%CMAKE_INSTALL_METHOD%"=="mise" ( mise install "cmake@%CMAKE_VERSION%" & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="asdf" ( asdf install cmake "%CMAKE_VERSION%" & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="pkgx" ( pkgx install "cmake@%CMAKE_VERSION%" & exit /b 0 )
if "%CMAKE_INSTALL_METHOD%"=="vfox" ( vfox add cmake & vfox install "cmake@%CMAKE_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\cmake\%CMAKE_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing cmake %CMAKE_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\cmake\cmake-%CMAKE_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\cmake\cmake-%CMAKE_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\cmake\cmake-%CMAKE_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\cmake\cmake-%CMAKE_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%CMAKE_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%CMAKE_DOWNLOAD_URL%" -o "%TEMP%\cmake.zip"
        tar -xf "%TEMP%\cmake.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for cmake.
    )
) else (
    echo cmake %CMAKE_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\cmake\%CMAKE_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_cmake"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CMAKE_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%CMAKE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %CMAKE_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_cmake"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CMAKE_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%CMAKE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %CMAKE_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_cmake"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CMAKE_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%CMAKE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %CMAKE_INSTALL_METHOD%.
)
exit /b 0
