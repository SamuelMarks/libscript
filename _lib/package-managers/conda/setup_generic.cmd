@echo off
:: ## Overview
:: Windows setup for conda
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%CONDA_VERSION%"=="" set CONDA_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%CONDA_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "CONDA_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "CONDA_INSTALL_METHOD=libscript_native"
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
if "%CONDA_INSTALL_METHOD%"=="mise" ( mise ls conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="asdf" ( asdf list conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="vfox" ( vfox ls conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\conda" ( dir /b "%LIBSCRIPT_HOME%\conda" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%CONDA_INSTALL_METHOD%"=="mise" ( mise ls conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="asdf" ( asdf list conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="vfox" ( vfox ls conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\conda" ( dir /b "%LIBSCRIPT_HOME%\conda" )
exit /b 0

:action_ls_remote
if "%CONDA_INSTALL_METHOD%"=="mise" ( mise ls-remote conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="asdf" ( asdf list all conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="vfox" ( vfox ls all conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CONDA_RELEASES_URL%"=="" (
    curl -sSL "%CONDA_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/conda/conda" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_ls_remote
if "%CONDA_INSTALL_METHOD%"=="mise" ( mise ls-remote conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="asdf" ( asdf list all conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="vfox" ( vfox ls all conda & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%CONDA_RELEASES_URL%"=="" (
    curl -sSL "%CONDA_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/conda/conda" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%CONDA_INSTALL_METHOD%"=="mise" ( mise use "conda@%CONDA_VERSION%" & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="asdf" ( asdf global conda "%CONDA_VERSION%" & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="vfox" ( vfox use "conda@%CONDA_VERSION%" & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%CONDA_VERSION%"=="latest" (set "EXACT_VERSION=%CONDA_VERSION%"
) else if "%CONDA_VERSION%"=="lts" (set "EXACT_VERSION=%CONDA_VERSION%"
) else (
    set "EXACT_VERSION=%CONDA_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%CONDA_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\conda\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\conda\%CONDA_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%CONDA_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading conda %CONDA_VERSION% to %DOWNLOAD_DIR%\conda...
    if not exist "%DOWNLOAD_DIR%\conda" mkdir "%DOWNLOAD_DIR%\conda"
    if not "%CONDA_DOWNLOAD_URL%"=="" (
        curl -sSL "%CONDA_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\conda\conda-%CONDA_VERSION%.zip"
    ) else (
        echo CONDA_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%CONDA_INSTALL_METHOD%"=="system" (
    winget install conda --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%CONDA_INSTALL_METHOD%"=="mise" ( mise install "conda@%CONDA_VERSION%" & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="asdf" ( asdf install conda "%CONDA_VERSION%" & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="pkgx" ( pkgx install "conda@%CONDA_VERSION%" & exit /b 0 )
if "%CONDA_INSTALL_METHOD%"=="vfox" ( vfox add conda & vfox install "conda@%CONDA_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\conda\%CONDA_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing conda %CONDA_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\conda\conda-%CONDA_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\conda\conda-%CONDA_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\conda\conda-%CONDA_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\conda\conda-%CONDA_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%CONDA_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%CONDA_DOWNLOAD_URL%" -o "%TEMP%\conda.zip"
        tar -xf "%TEMP%\conda.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for conda.
    )
) else (
    echo conda %CONDA_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\conda\%CONDA_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_conda"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CONDA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%CONDA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %CONDA_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_conda"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CONDA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%CONDA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %CONDA_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_conda"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%CONDA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%CONDA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %CONDA_INSTALL_METHOD%.
)
exit /b 0
