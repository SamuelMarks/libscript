@echo off
:: ## Overview
:: Windows setup for opam
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%OPAM_VERSION%"=="" set OPAM_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%OPAM_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "OPAM_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "OPAM_INSTALL_METHOD=libscript_native"
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
if "%OPAM_INSTALL_METHOD%"=="mise" ( mise ls opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="asdf" ( asdf list opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="vfox" ( vfox ls opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\opam" ( dir /b "%LIBSCRIPT_HOME%\opam" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%OPAM_INSTALL_METHOD%"=="mise" ( mise ls opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="asdf" ( asdf list opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="vfox" ( vfox ls opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\opam" ( dir /b "%LIBSCRIPT_HOME%\opam" )
exit /b 0

:action_ls_remote
if "%OPAM_INSTALL_METHOD%"=="mise" ( mise ls-remote opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="asdf" ( asdf list all opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="vfox" ( vfox ls all opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%OPAM_RELEASES_URL%"=="" (
    curl -sSL "%OPAM_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/opam" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_ls_remote
if "%OPAM_INSTALL_METHOD%"=="mise" ( mise ls-remote opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="asdf" ( asdf list all opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="vfox" ( vfox ls all opam & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%OPAM_RELEASES_URL%"=="" (
    curl -sSL "%OPAM_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/opam" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%OPAM_INSTALL_METHOD%"=="mise" ( mise use "opam@%OPAM_VERSION%" & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="asdf" ( asdf global opam "%OPAM_VERSION%" & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="vfox" ( vfox use "opam@%OPAM_VERSION%" & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%OPAM_VERSION%"=="latest" (set "EXACT_VERSION=%OPAM_VERSION%"
) else if "%OPAM_VERSION%"=="lts" (set "EXACT_VERSION=%OPAM_VERSION%"
) else (
    set "EXACT_VERSION=%OPAM_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%OPAM_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\opam\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\opam\%OPAM_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%OPAM_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading opam %OPAM_VERSION% to %DOWNLOAD_DIR%\opam...
    if not exist "%DOWNLOAD_DIR%\opam" mkdir "%DOWNLOAD_DIR%\opam"
    if not "%OPAM_DOWNLOAD_URL%"=="" (
        curl -sSL "%OPAM_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\opam\opam-%OPAM_VERSION%.zip"
    ) else (
        echo OPAM_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%OPAM_INSTALL_METHOD%"=="system" (
    winget install opam --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%OPAM_INSTALL_METHOD%"=="mise" ( mise install "opam@%OPAM_VERSION%" & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="asdf" ( asdf install opam "%OPAM_VERSION%" & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="pkgx" ( pkgx install "opam@%OPAM_VERSION%" & exit /b 0 )
if "%OPAM_INSTALL_METHOD%"=="vfox" ( vfox add opam & vfox install "opam@%OPAM_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\opam\%OPAM_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing opam %OPAM_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\opam\opam-%OPAM_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\opam\opam-%OPAM_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\opam\opam-%OPAM_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\opam\opam-%OPAM_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%OPAM_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%OPAM_DOWNLOAD_URL%" -o "%TEMP%\opam.zip"
        tar -xf "%TEMP%\opam.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for opam.
    )
) else (
    echo opam %OPAM_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\opam\%OPAM_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_opam"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%OPAM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%OPAM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %OPAM_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_opam"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%OPAM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%OPAM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %OPAM_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_opam"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%OPAM_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%OPAM_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %OPAM_INSTALL_METHOD%.
)
exit /b 0
