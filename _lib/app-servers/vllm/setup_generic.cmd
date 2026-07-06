@echo off
:: ## Overview
:: Windows setup for vllm
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%VLLM_VERSION%"=="" set VLLM_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%VLLM_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "VLLM_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "VLLM_INSTALL_METHOD=libscript_native"
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
if "%VLLM_INSTALL_METHOD%"=="mise" ( mise ls vllm & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="asdf" ( asdf list vllm & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="vfox" ( vfox ls vllm & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\vllm" ( dir /b "%LIBSCRIPT_HOME%\vllm" )
exit /b 0

:action_ls_remote
if "%VLLM_INSTALL_METHOD%"=="mise" ( mise ls-remote vllm & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="asdf" ( asdf list all vllm & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="vfox" ( vfox ls all vllm & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%VLLM_RELEASES_URL%"=="" (
    curl -sSL "%VLLM_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/vllm-project/vllm" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%VLLM_INSTALL_METHOD%"=="mise" ( mise use "vllm@%VLLM_VERSION%" & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="asdf" ( asdf global vllm "%VLLM_VERSION%" & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="vfox" ( vfox use "vllm@%VLLM_VERSION%" & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%VLLM_VERSION%"=="latest" (set "EXACT_VERSION=%VLLM_VERSION%"
) else if "%VLLM_VERSION%"=="lts" (set "EXACT_VERSION=%VLLM_VERSION%"
) else (
    set "EXACT_VERSION=%VLLM_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%VLLM_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\vllm\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\vllm\%VLLM_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%VLLM_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading vllm %VLLM_VERSION% to %DOWNLOAD_DIR%\vllm...
    if not exist "%DOWNLOAD_DIR%\vllm" mkdir "%DOWNLOAD_DIR%\vllm"
    if not "%VLLM_DOWNLOAD_URL%"=="" (
        curl -sSL "%VLLM_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\vllm\vllm-%VLLM_VERSION%.zip"
    ) else (
        echo VLLM_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%VLLM_INSTALL_METHOD%"=="system" (
    winget install vllm --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%VLLM_INSTALL_METHOD%"=="mise" ( mise install "vllm@%VLLM_VERSION%" & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="asdf" ( asdf install vllm "%VLLM_VERSION%" & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="pkgx" ( pkgx install "vllm@%VLLM_VERSION%" & exit /b 0 )
if "%VLLM_INSTALL_METHOD%"=="vfox" ( vfox add vllm & vfox install "vllm@%VLLM_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\vllm\%VLLM_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing vllm %VLLM_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\vllm\vllm-%VLLM_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\vllm\vllm-%VLLM_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\vllm\vllm-%VLLM_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\vllm\vllm-%VLLM_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%VLLM_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%VLLM_DOWNLOAD_URL%" -o "%TEMP%\vllm.zip"
        tar -xf "%TEMP%\vllm.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for vllm.
    )
) else (
    echo vllm %VLLM_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\vllm\%VLLM_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_vllm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%VLLM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%VLLM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %VLLM_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_vllm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%VLLM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%VLLM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %VLLM_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_vllm"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%VLLM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%VLLM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %VLLM_INSTALL_METHOD%.
)
exit /b 0
