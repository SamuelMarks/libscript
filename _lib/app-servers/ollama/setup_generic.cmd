@echo off
:: ## Overview
:: Windows setup for ollama
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%OLLAMA_VERSION%"=="" set OLLAMA_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%OLLAMA_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "OLLAMA_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "OLLAMA_INSTALL_METHOD=libscript_native"
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
if "%OLLAMA_INSTALL_METHOD%"=="mise" ( mise ls ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="asdf" ( asdf list ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="vfox" ( vfox ls ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\ollama" ( dir /b "%LIBSCRIPT_HOME%\ollama" )
exit /b 0

:action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_install

:action_ls
if "%OLLAMA_INSTALL_METHOD%"=="mise" ( mise ls ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="asdf" ( asdf list ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="vfox" ( vfox ls ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\ollama" ( dir /b "%LIBSCRIPT_HOME%\ollama" )
exit /b 0

:action_ls_remote
if "%OLLAMA_INSTALL_METHOD%"=="mise" ( mise ls-remote ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="asdf" ( asdf list all ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="vfox" ( vfox ls all ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%OLLAMA_RELEASES_URL%"=="" (
    curl -sSL "%OLLAMA_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/ollama/ollama" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_ls_remote
if "%OLLAMA_INSTALL_METHOD%"=="mise" ( mise ls-remote ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="asdf" ( asdf list all ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="vfox" ( vfox ls all ollama & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%OLLAMA_RELEASES_URL%"=="" (
    curl -sSL "%OLLAMA_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/ollama/ollama" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%OLLAMA_INSTALL_METHOD%"=="mise" ( mise use "ollama@%OLLAMA_VERSION%" & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="asdf" ( asdf global ollama "%OLLAMA_VERSION%" & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="vfox" ( vfox use "ollama@%OLLAMA_VERSION%" & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%OLLAMA_VERSION%"=="latest" (set "EXACT_VERSION=%OLLAMA_VERSION%"
) else if "%OLLAMA_VERSION%"=="lts" (set "EXACT_VERSION=%OLLAMA_VERSION%"
) else (
    set "EXACT_VERSION=%OLLAMA_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%OLLAMA_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\ollama\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\ollama\%OLLAMA_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%OLLAMA_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading ollama %OLLAMA_VERSION% to %DOWNLOAD_DIR%\ollama...
    if not exist "%DOWNLOAD_DIR%\ollama" mkdir "%DOWNLOAD_DIR%\ollama"
    if not "%OLLAMA_DOWNLOAD_URL%"=="" (
        curl -sSL "%OLLAMA_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\ollama\ollama-%OLLAMA_VERSION%.zip"
    ) else (
        echo OLLAMA_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%OLLAMA_INSTALL_METHOD%"=="system" (
    winget install ollama --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%OLLAMA_INSTALL_METHOD%"=="mise" ( mise install "ollama@%OLLAMA_VERSION%" & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="asdf" ( asdf install ollama "%OLLAMA_VERSION%" & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="pkgx" ( pkgx install "ollama@%OLLAMA_VERSION%" & exit /b 0 )
if "%OLLAMA_INSTALL_METHOD%"=="vfox" ( vfox add ollama & vfox install "ollama@%OLLAMA_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\ollama\%OLLAMA_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing ollama %OLLAMA_VERSION% natively to %TARGET_DIR%...
    mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\ollama\ollama-%OLLAMA_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\ollama\ollama-%OLLAMA_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\ollama\ollama-%OLLAMA_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\ollama\ollama-%OLLAMA_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%OLLAMA_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%OLLAMA_DOWNLOAD_URL%" -o "%TEMP%\ollama.zip"
        tar -xf "%TEMP%\ollama.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for ollama.
    )
) else (
    echo ollama %OLLAMA_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\ollama\%OLLAMA_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_ollama"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%OLLAMA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%OLLAMA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %OLLAMA_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_ollama"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%OLLAMA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%OLLAMA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %OLLAMA_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_ollama"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%OLLAMA_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%OLLAMA_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %OLLAMA_INSTALL_METHOD%.
)
exit /b 0
