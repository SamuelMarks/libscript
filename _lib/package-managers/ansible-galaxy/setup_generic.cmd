@echo off
:: ## Overview
:: Windows setup for ansible-galaxy
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.

if "%ACTION%"=="" set ACTION=install
if "%ANSIBLE_GALAXY_VERSION%"=="" set ANSIBLE_GALAXY_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "ANSIBLE_GALAXY_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "ANSIBLE_GALAXY_INSTALL_METHOD=libscript_native"
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
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="mise" ( mise ls ansible-galaxy & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="asdf" ( asdf list ansible-galaxy & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="vfox" ( vfox ls ansible-galaxy & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\ansible-galaxy" ( dir /b "%LIBSCRIPT_HOME%\ansible-galaxy" )
exit /b 0

:action_ls_remote
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="mise" ( mise ls-remote ansible-galaxy & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="asdf" ( asdf list all ansible-galaxy & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="vfox" ( vfox ls all ansible-galaxy & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%ANSIBLE_GALAXY_RELEASES_URL%"=="" (
    curl -sSL "%ANSIBLE_GALAXY_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/libscript/ansible-galaxy" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:action_use
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="mise" ( mise use "ansible-galaxy@%ANSIBLE_GALAXY_VERSION%" & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="asdf" ( asdf global ansible-galaxy "%ANSIBLE_GALAXY_VERSION%" & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="vfox" ( vfox use "ansible-galaxy@%ANSIBLE_GALAXY_VERSION%" & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%ANSIBLE_GALAXY_VERSION%"=="latest" (set "EXACT_VERSION=%ANSIBLE_GALAXY_VERSION%"
) else if "%ANSIBLE_GALAXY_VERSION%"=="lts" (set "EXACT_VERSION=%ANSIBLE_GALAXY_VERSION%"
) else (
    set "EXACT_VERSION=%ANSIBLE_GALAXY_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%ANSIBLE_GALAXY_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\ansible-galaxy\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\ansible-galaxy\%ANSIBLE_GALAXY_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_download
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading ansible-galaxy %ANSIBLE_GALAXY_VERSION% to %DOWNLOAD_DIR%\ansible-galaxy...
    if not exist "%DOWNLOAD_DIR%\ansible-galaxy" mkdir "%DOWNLOAD_DIR%\ansible-galaxy"
    if not "%ANSIBLE_GALAXY_DOWNLOAD_URL%"=="" (
        curl -sSL "%ANSIBLE_GALAXY_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\ansible-galaxy\ansible-galaxy-%ANSIBLE_GALAXY_VERSION%.zip"
    ) else (
        echo ANSIBLE_GALAXY_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:action_install
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="system" (
    winget install ansible-galaxy --accept-package-agreements --accept-source-agreements
    exit /b !errorlevel!
)
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="mise" ( mise install "ansible-galaxy@%ANSIBLE_GALAXY_VERSION%" & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="asdf" ( asdf install ansible-galaxy "%ANSIBLE_GALAXY_VERSION%" & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="pkgx" ( pkgx install "ansible-galaxy@%ANSIBLE_GALAXY_VERSION%" & exit /b 0 )
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="vfox" ( vfox add ansible-galaxy & vfox install "ansible-galaxy@%ANSIBLE_GALAXY_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\ansible-galaxy\%ANSIBLE_GALAXY_VERSION%"
if not exist "%TARGET_DIR%\bin" (
    echo Installing ansible-galaxy %ANSIBLE_GALAXY_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    if exist "%DOWNLOAD_DIR%\ansible-galaxy\ansible-galaxy-%ANSIBLE_GALAXY_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\ansible-galaxy\ansible-galaxy-%ANSIBLE_GALAXY_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\ansible-galaxy\ansible-galaxy-%ANSIBLE_GALAXY_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\ansible-galaxy\ansible-galaxy-%ANSIBLE_GALAXY_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%ANSIBLE_GALAXY_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%ANSIBLE_GALAXY_DOWNLOAD_URL%" -o "%TEMP%\ansible-galaxy.zip"
        tar -xf "%TEMP%\ansible-galaxy.zip" -C "%TARGET_DIR%"
    ) else (
        echo No download URL or cache available for ansible-galaxy.
    )
) else (
    echo ansible-galaxy %ANSIBLE_GALAXY_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\ansible-galaxy\%ANSIBLE_GALAXY_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_ansible-galaxy"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %ANSIBLE_GALAXY_INSTALL_METHOD%.
)
exit /b 0

:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_ansible-galaxy"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %ANSIBLE_GALAXY_INSTALL_METHOD%.
)
exit /b 0

:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_ansible-galaxy"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%ANSIBLE_GALAXY_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %ANSIBLE_GALAXY_INSTALL_METHOD%.
)
exit /b 0
