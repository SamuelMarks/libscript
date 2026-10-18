@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for python
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

:: Parse offline and pip options
:: ## arg_parse_loop
:: Parses command-line arguments and populates configuration variables.
:arg_parse_loop
if "%~1"=="" goto :arg_parse_done
if /i "%~1"=="--offline" set "LIBSCRIPT_OFFLINE=1"
if /i "%~1"=="-o" set "LIBSCRIPT_OFFLINE=1"
if /i "%~1"=="--pip-no-index" set "PIP_NO_INDEX=1"
if /i "%~1"=="--pip-find-links" (
    set "PIP_FIND_LINKS=%~2"
    shift
)
if /i "%~1"=="--pip-wheel-dir" (
    set "PIP_WHEEL_DIR=%~2"
    shift
)
shift
goto :arg_parse_loop
:: ## arg_parse_done
:: Continues execution after command-line argument parsing completes.
:arg_parse_done

if "%LIBSCRIPT_OFFLINE%"=="1" (
    set "PIP_NO_INDEX=1"
    if "%PIP_FIND_LINKS%"=="" (
        if not "%PIP_WHEEL_DIR%"=="" (
            set "PIP_FIND_LINKS=%PIP_WHEEL_DIR%"
        ) else if not "%LIBSCRIPT_CACHE_DIR%"=="" (
            set "PIP_FIND_LINKS=%LIBSCRIPT_CACHE_DIR%\wheels"
        ) else (
            set "PIP_FIND_LINKS=!LIBSCRIPT_ROOT_DIR!\cache\wheels"
        )
    )
)

if "%ACTION%"=="" set ACTION=install
if "%PYTHON_VERSION%"=="" set PYTHON_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%PYTHON_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "PYTHON_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "PYTHON_INSTALL_METHOD=libscript_native"
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
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%PYTHON_INSTALL_METHOD%"=="mise" ( mise ls python & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="asdf" ( asdf list python & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="vfox" ( vfox ls python & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\python" ( dir /b "%LIBSCRIPT_HOME%\python" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%PYTHON_INSTALL_METHOD%"=="mise" ( mise ls-remote python & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="asdf" ( asdf list all python & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not have a local list command & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="vfox" ( vfox ls all python & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%PYTHON_RELEASES_URL%"=="" (
    curl -sSL "%PYTHON_RELEASES_URL%"
) else (
    echo ls-remote not fully implemented natively yet.
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%PYTHON_INSTALL_METHOD%"=="mise" ( mise use "python@%PYTHON_VERSION%" & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="asdf" ( asdf global python "%PYTHON_VERSION%" & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="pkgx" ( echo pkgx does not use explicit versions this way & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="vfox" ( vfox use "python@%PYTHON_VERSION%" & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

if "%PYTHON_VERSION%"=="latest" (set "EXACT_VERSION=%PYTHON_VERSION%"
) else if "%PYTHON_VERSION%"=="lts" (set "EXACT_VERSION=%PYTHON_VERSION%"
) else (
    set "EXACT_VERSION=%PYTHON_VERSION%"
)
if "%EXACT_VERSION%"=="" set "EXACT_VERSION=%PYTHON_VERSION%"

set "TARGET_DIR=%LIBSCRIPT_HOME%\python\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\python\%PYTHON_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%PYTHON_INSTALL_METHOD%"=="libscript_native" (
    echo Downloading python %PYTHON_VERSION% to %DOWNLOAD_DIR%\python...
    if not exist "%DOWNLOAD_DIR%\python" mkdir "%DOWNLOAD_DIR%\python"
    if not "%PYTHON_DOWNLOAD_URL%"=="" (
        curl -sSL "%PYTHON_DOWNLOAD_URL%" -o "%DOWNLOAD_DIR%\python\python-%PYTHON_VERSION%.zip"
    ) else (
        echo PYTHON_DOWNLOAD_URL is not defined. Skipping.
    )
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if "%PYTHON_INSTALL_METHOD%"=="system" (
    if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
        winget install --id Python.Python.3.12 -e --source winget --accept-package-agreements --accept-source-agreements
    ) else (
        winget install --id Python.Python.3.12 -e --source winget --accept-package-agreements --accept-source-agreements || winget install --id Python.Python.3.10 -e --source winget -a x64 --accept-package-agreements --accept-source-agreements
    )
    exit /b !errorlevel!
)
if "%PYTHON_INSTALL_METHOD%"=="mise" ( mise install "python@%PYTHON_VERSION%" & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="asdf" ( asdf install python "%PYTHON_VERSION%" & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="pkgx" ( pkgx install "python@%PYTHON_VERSION%" & exit /b 0 )
if "%PYTHON_INSTALL_METHOD%"=="vfox" ( vfox add python & vfox install "python@%PYTHON_VERSION%" & exit /b 0 )

set "TARGET_DIR=%LIBSCRIPT_HOME%\python\%PYTHON_VERSION%"
if not exist "%TARGET_DIR%\bin\python.exe" if not exist "%TARGET_DIR%\python.exe" if not exist "C:\Program Files\Python312\python.exe" if not exist "C:\Users\vagrant\AppData\Local\Programs\Python\Python312-arm64\python.exe" if not exist "C:\Users\vagrant\AppData\Local\Programs\Python\Python312\python.exe" (
    echo Installing python %PYTHON_VERSION% natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    set "_PY_CACHED="
    if defined LIBSCRIPT_CACHE_DIR (
        for %%Z in ("%LIBSCRIPT_CACHE_DIR%\runtimes\python*.zip") do set "_PY_CACHED=%%~fZ"
    )
    if exist "!LIBSCRIPT_ROOT_DIR!\cache\runtimes" (
        for %%Z in ("!LIBSCRIPT_ROOT_DIR!\cache\runtimes\python*.zip") do set "_PY_CACHED=%%~fZ"
    )
    if defined _PY_CACHED (
        echo Extracting Python from offline cache !_PY_CACHED!...
        tar -xf "!_PY_CACHED!" -C "%TARGET_DIR%\bin" 2>nul || powershell -NoProfile -Command "Expand-Archive -Path '!_PY_CACHED!' -DestinationPath '%TARGET_DIR%\bin' -Force"
        copy /y "%TARGET_DIR%\bin\python.exe" "%TARGET_DIR%\python.exe" >nul 2>&1
    ) else if exist "%DOWNLOAD_DIR%\python\python-%PYTHON_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\python\python-%PYTHON_VERSION%.zip" -C "%TARGET_DIR%"
    ) else if exist "%DOWNLOAD_DIR%\python\python-%PYTHON_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\python\python-%PYTHON_VERSION%.tar.gz" -C "%TARGET_DIR%"
    ) else if not "%PYTHON_DOWNLOAD_URL%"=="" (
        echo Downloading and extracting...
        curl -sSL "%PYTHON_DOWNLOAD_URL%" -o "%TEMP%\python.zip"
        tar -xf "%TEMP%\python.zip" -C "%TARGET_DIR%"
    ) else (
        if not "%PROP_OPENEDX_FAST_VERIFY%"=="1" (
            where winget >nul 2>&1
            if not errorlevel 1 (
                echo Installing Python 3.12 via winget...
                winget install --id Python.Python.3.12 -e --silent --accept-package-agreements --accept-source-agreements
            )
        )
        if not exist "C:\Program Files\Python312\python.exe" if not exist "%LOCALAPPDATA%\Programs\Python\Python312-arm64\python.exe" if not exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" if not exist "C:\Users\vagrant\AppData\Local\Programs\Python\Python312-arm64\python.exe" (
            echo Downloading portable Python 3.12...
            set "_PY_ARCH=amd64"
            if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "_PY_ARCH=arm64"
            curl -fSL "https://www.python.org/ftp/python/3.12.8/python-3.12.8-embed-!_PY_ARCH!.zip" -o "%TEMP%\python-embed.zip"
            if exist "%TEMP%\python-embed.zip" (
                tar -xf "%TEMP%\python-embed.zip" -C "%TARGET_DIR%\bin" 2>nul || powershell -NoProfile -Command "Expand-Archive -Path '%TEMP%\python-embed.zip' -DestinationPath '%TARGET_DIR%\bin' -Force"
                copy /y "%TARGET_DIR%\bin\python.exe" "%TARGET_DIR%\python.exe" >nul 2>&1
            )
        )
    )
) else (
    echo python %PYTHON_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\python\%PYTHON_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%"
    mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the service manager.
:action_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_python"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%PYTHON_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else if "%PYTHON_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" "%ACTION%" "%SVC_NAME%"
) else (
    echo %ACTION% not natively implemented for %PYTHON_INSTALL_METHOD%.
)
exit /b 0

:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_python"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%PYTHON_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else if "%PYTHON_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" install "%SVC_NAME%"
) else (
    echo install-service not implemented for %PYTHON_INSTALL_METHOD%.
)
exit /b 0

:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "SVC_NAME=libscript_python"
    ) else (
        set "SVC_NAME=libscript_%PACKAGE_NAME%"
    )
) else (
    set "SVC_NAME=%LIBSCRIPT_SERVICE_NAME%"
)
if "%PYTHON_INSTALL_METHOD%"=="libscript_native" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else if "%PYTHON_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" uninstall "%SVC_NAME%"
) else (
    echo uninstall-service not implemented for %PYTHON_INSTALL_METHOD%.
)
exit /b 0
