@echo off
:: ## Overview
:: Windows setup for stack
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%STACK_VERSION%"=="" set STACK_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%STACK_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "STACK_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "STACK_INSTALL_METHOD=libscript_native"
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
if "%STACK_INSTALL_METHOD%"=="mise" ( mise ls stack & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="asdf" ( asdf list stack & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="vfox" ( vfox ls stack & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\stack" ( dir /b "%LIBSCRIPT_HOME%\stack" )
exit /b 0

:action_ls_remote
if "%STACK_INSTALL_METHOD%"=="mise" ( mise ls-remote stack & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="asdf" ( asdf list all stack & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="vfox" ( vfox ls all stack & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%STACK_RELEASES_URL%"=="" (
    curl -sSL "%STACK_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/commercialhaskell/stack" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%STACK_INSTALL_METHOD%"=="mise" ( mise use "stack@%STACK_VERSION%" & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="asdf" ( asdf global stack "%STACK_VERSION%" & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="vfox" ( vfox use "stack@%STACK_VERSION%" & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%STACK_VERSION%"=="latest" (set "EXACT_VERSION=%STACK_VERSION%"
) else if "%STACK_VERSION%"=="lts" (set "EXACT_VERSION=%STACK_VERSION%"
) else (
    set "EXACT_VERSION=%STACK_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%STACK_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\stack\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\stack\%STACK_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%STACK_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading stack %STACK_VERSION% to %DOWNLOAD_DIR%\stack...
    if not exist "%DOWNLOAD_DIR%\stack" mkdir "%DOWNLOAD_DIR%\stack"
    if not "%STACK_DOWNLOAD_URL%"=="" (
        curl -sSL "%STACK_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\stack\stack-%STACK_VERSION%.zip"
    ) else (
        echo STACK_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%STACK_INSTALL_METHOD%"=="system" (
    winget install stack --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%STACK_INSTALL_METHOD%"=="mise" ( mise install "stack@%STACK_VERSION%" & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="asdf" ( asdf install stack "%STACK_VERSION%" & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="pkgx" ( pkgx install "stack@%STACK_VERSION%" & exit /b 0 )
if "%STACK_INSTALL_METHOD%"=="vfox" ( vfox add stack & vfox install "stack@%STACK_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\stack\%STACK_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing stack %STACK_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\stack\stack-%STACK_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\stack\stack-%STACK_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\stack\stack-%STACK_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\stack\stack-%STACK_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%STACK_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%STACK_DOWNLOAD_URL%" -o "%TEMP%\stack.zip"
        tar -xf "%TEMP%\stack.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for stack.
    )
) else (
    echo stack %STACK_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\stack\%STACK_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_stack"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%STACK_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%STACK_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %STACK_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_stack"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%STACK_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%STACK_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %STACK_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_stack"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%STACK_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%STACK_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %STACK_INSTALL_METHOD%.
)
exit /b 0
