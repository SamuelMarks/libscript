@echo off
:: ## Overview
:: Windows setup for pyenv
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%PYENV_VERSION%"=="" set PYENV_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%PYENV_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "PYENV_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "PYENV_INSTALL_METHOD=libscript_native"
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
if "%PYENV_INSTALL_METHOD%"=="mise" ( mise ls pyenv & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="asdf" ( asdf list pyenv & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="vfox" ( vfox ls pyenv & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\pyenv" ( dir /b "%LIBSCRIPT_HOME%\pyenv" )
exit /b 0

:: ## action_ls_remote
:: Executes action_ls_remote functionality.
:action_ls_remote
if "%PYENV_INSTALL_METHOD%"=="mise" ( mise ls-remote pyenv & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="asdf" ( asdf list all pyenv & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="vfox" ( vfox ls all pyenv & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%PYENV_RELEASES_URL%"=="" (
    curl -sSL "%PYENV_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/pyenv" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## action_use
:: Executes action_use functionality.
:action_use
if "%PYENV_INSTALL_METHOD%"=="mise" ( mise use "pyenv@%PYENV_VERSION%" & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="asdf" ( asdf global pyenv "%PYENV_VERSION%" & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="vfox" ( vfox use "pyenv@%PYENV_VERSION%" & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%PYENV_VERSION%"=="latest" (set "EXACT_VERSION=%PYENV_VERSION%"
) else if "%PYENV_VERSION%"=="lts" (set "EXACT_VERSION=%PYENV_VERSION%"
) else (
    set "EXACT_VERSION=%PYENV_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%PYENV_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\pyenv\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\pyenv\%PYENV_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Executes action_download functionality.
:action_download
if "%PYENV_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading pyenv %PYENV_VERSION% to %DOWNLOAD_DIR%\pyenv...
    if not exist "%DOWNLOAD_DIR%\pyenv" mkdir "%DOWNLOAD_DIR%\pyenv"
    if not "%PYENV_DOWNLOAD_URL%"=="" (
        curl -sSL "%PYENV_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\pyenv\pyenv-%PYENV_VERSION%.zip"
    ) else (
        echo PYENV_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Executes action_install functionality.
:action_install
if "%PYENV_INSTALL_METHOD%"=="system" (
    winget install pyenv --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%PYENV_INSTALL_METHOD%"=="mise" ( mise install "pyenv@%PYENV_VERSION%" & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="asdf" ( asdf install pyenv "%PYENV_VERSION%" & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="pkgx" ( pkgx install "pyenv@%PYENV_VERSION%" & exit /b 0 )
if "%PYENV_INSTALL_METHOD%"=="vfox" ( vfox add pyenv & vfox install "pyenv@%PYENV_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\pyenv\%PYENV_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing pyenv %PYENV_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\pyenv\pyenv-%PYENV_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\pyenv\pyenv-%PYENV_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\pyenv\pyenv-%PYENV_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\pyenv\pyenv-%PYENV_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%PYENV_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%PYENV_DOWNLOAD_URL%" -o "%TEMP%\pyenv.zip"
        tar -xf "%TEMP%\pyenv.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for pyenv.
        exit /b 1
    )
) else (
    echo pyenv %PYENV_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\pyenv\%PYENV_VERSION%"
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
        set "SVC_NAME=libscript_pyenv"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%PYENV_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%PYENV_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %PYENV_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Executes action_install_service functionality.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_pyenv"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%PYENV_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%PYENV_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %PYENV_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Executes action_uninstall_service functionality.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_pyenv"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%PYENV_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%PYENV_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %PYENV_INSTALL_METHOD%.
)
exit /b 0
