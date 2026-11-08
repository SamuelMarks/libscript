@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for duckdb with reuse-else-create semantics.
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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

if "%ACTION%"=="" set ACTION=install
if "%DUCKDB_VERSION%"=="" set DUCKDB_VERSION=latest

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%DOWNLOAD_DIR%"=="" (
    set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"
)

:: Resolve install method
if "%DUCKDB_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "DUCKDB_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "DUCKDB_INSTALL_METHOD=libscript_native"
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

:: ## find_existing_duckdb
:: Checks LIBSCRIPT_HOME and system PATH for an existing duckdb.exe binary.
:find_existing_duckdb
if exist "%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%\bin\duckdb.exe" (
    "%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%\bin\duckdb.exe" --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)
if exist "%LIBSCRIPT_HOME%\duckdb\default\bin\duckdb.exe" (
    "%LIBSCRIPT_HOME%\duckdb\default\bin\duckdb.exe" --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)
where duckdb >nul 2>&1
if not errorlevel 1 (
    duckdb --version >nul 2>&1
    if not errorlevel 1 exit /b 0
)
exit /b 1

:: ## action_ls
:: Lists all locally installed versions of the component under LIBSCRIPT_HOME.
:action_ls
if "%DUCKDB_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls directly here. & exit /b 0 )
if exist "%LIBSCRIPT_HOME%\duckdb" ( dir /b "%LIBSCRIPT_HOME%\duckdb" )
exit /b 0

:: ## action_ls_remote
:: Lists upstream release versions available for download.
:action_ls_remote
if "%DUCKDB_INSTALL_METHOD%"=="system" ( echo System package manager does not support ls-remote directly here. & exit /b 0 )
if not "%DUCKDB_RELEASES_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "%DUCKDB_RELEASES_URL%"
) else (
    git ls-remote --tags "https://github.com/duckdb/duckdb" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
)
exit /b 0

:: ## resolve_exact_version
:: Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
:resolve_exact_version
if "%DUCKDB_VERSION%"=="latest" (
    set "EXACT_VERSION=1.2.1"
) else if "%DUCKDB_VERSION%"=="lts" (
    set "EXACT_VERSION=1.2.1"
) else if "%DUCKDB_VERSION%"=="stable" (
    set "EXACT_VERSION=1.2.1"
) else if "%DUCKDB_VERSION%"=="" (
    set "EXACT_VERSION=1.2.1"
) else (
    set "EXACT_VERSION=%DUCKDB_VERSION%"
    if "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
)
exit /b 0

:: ## action_use
:: Activates the specified component version by updating the active symlink or junction.
:action_use
if "%DUCKDB_INSTALL_METHOD%"=="system" ( echo Cannot 'use' specific version with system package manager. & exit /b 0 )

call :resolve_exact_version

set "TARGET_DIR=%LIBSCRIPT_HOME%\duckdb\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%"

if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the component release archive into the local offline cache directory.
:action_download
if "%DUCKDB_INSTALL_METHOD%"=="libscript_native" (
    if not "%FORCE_REINSTALL%"=="1" (
        call :find_existing_duckdb
        if not errorlevel 1 (
            echo [REUSE] duckdb is already installed; skipping download.
            exit /b 0
        )
    )
    call :resolve_exact_version
    echo Downloading duckdb %DUCKDB_VERSION% ^(!EXACT_VERSION!^) to %DOWNLOAD_DIR%\duckdb...
    if not exist "%DOWNLOAD_DIR%\duckdb" mkdir "%DOWNLOAD_DIR%\duckdb"
    set "_dl_dest=%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.zip"
    if exist "!_dl_dest!" del /f /q "!_dl_dest!" 2>nul
    if not "%DUCKDB_DOWNLOAD_URL%"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%DUCKDB_DOWNLOAD_URL%" "!_dl_dest!"
    ) else (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://github.com/duckdb/duckdb/releases/download/v!EXACT_VERSION!/duckdb_cli-windows-amd64.zip" "!_dl_dest!"
        if errorlevel 1 (
            if exist "!_dl_dest!" del /f /q "!_dl_dest!" 2>nul
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-windows-amd64.zip" "!_dl_dest!"
        )
    )
)
exit /b 0

:: ## purge_stale_duckdb_cache
:: Removes any corrupt or zero-byte cached archive matching the given filename.
:purge_stale_duckdb_cache
set "_psdc_fname=%~nx1"
if "!_psdc_fname!"=="" set "_psdc_fname=duckdb_cli-windows-amd64.zip"
if exist "%DOWNLOAD_DIR%\!_psdc_fname!" del /f /q "%DOWNLOAD_DIR%\!_psdc_fname!" 2>nul
if exist "%DOWNLOAD_DIR%\duckdb\!_psdc_fname!" del /f /q "%DOWNLOAD_DIR%\duckdb\!_psdc_fname!" 2>nul
if exist "!LIBSCRIPT_ROOT_DIR!\cache\downloads\!_psdc_fname!" del /f /q "!LIBSCRIPT_ROOT_DIR!\cache\downloads\!_psdc_fname!" 2>nul
if exist "!LIBSCRIPT_ROOT_DIR!\cache\downloads\duckdb\!_psdc_fname!" del /f /q "!LIBSCRIPT_ROOT_DIR!\cache\downloads\duckdb\!_psdc_fname!" 2>nul
if exist "!LIBSCRIPT_ROOT_DIR!\cache\downloads\unknown\!_psdc_fname!" del /f /q "!LIBSCRIPT_ROOT_DIR!\cache\downloads\unknown\!_psdc_fname!" 2>nul
exit /b 0

:: ## action_install
:: Installs and configures the requested version of the component.
:action_install
if not "%FORCE_REINSTALL%"=="1" (
    call :find_existing_duckdb
    if not errorlevel 1 (
        echo [REUSE] duckdb ^(%DUCKDB_VERSION%^) is already installed.
        exit /b 0
    )
)
if /i "%DUCKDB_INSTALL_METHOD%"=="from-source" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "duckdb" "%DUCKDB_VERSION%" "duckdb" "c++"
    exit /b !errorlevel!
)
if "%DUCKDB_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends duckdb
    exit /b !errorlevel!
)

call :resolve_exact_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\duckdb\!EXACT_VERSION!"
if not exist "%TARGET_DIR%\bin\duckdb.exe" (
    echo Installing duckdb %DUCKDB_VERSION% ^(!EXACT_VERSION!^) natively to %TARGET_DIR%...
    if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
    set "_extracted_ok=0"
    if exist "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.zip" -C "%TARGET_DIR%\bin" 2>nul
        if exist "%TARGET_DIR%\bin\duckdb.exe" (
            set "_extracted_ok=1"
        ) else (
            del /f /q "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.zip" 2>nul
        )
    ) else if exist "%DOWNLOAD_DIR%\duckdb\duckdb-!EXACT_VERSION!.zip" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\duckdb\duckdb-!EXACT_VERSION!.zip" -C "%TARGET_DIR%\bin" 2>nul
        if exist "%TARGET_DIR%\bin\duckdb.exe" (
            set "_extracted_ok=1"
        ) else (
            del /f /q "%DOWNLOAD_DIR%\duckdb\duckdb-!EXACT_VERSION!.zip" 2>nul
        )
    ) else if exist "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.tar.gz" (
        echo Extracting from cache...
        tar -xf "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.tar.gz" -C "%TARGET_DIR%" 2>nul
        if exist "%TARGET_DIR%\bin\duckdb.exe" (
            set "_extracted_ok=1"
        ) else (
            del /f /q "%DOWNLOAD_DIR%\duckdb\duckdb-%DUCKDB_VERSION%.tar.gz" 2>nul
        )
    )
    if "!_extracted_ok!"=="0" (
        if not "%DUCKDB_DOWNLOAD_URL%"=="" (
            echo Downloading and extracting...
            if exist "%TEMP%\duckdb_cli.zip" del /f /q "%TEMP%\duckdb_cli.zip" 2>nul
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%DUCKDB_DOWNLOAD_URL%" "%TEMP%\duckdb_cli.zip"
            if errorlevel 1 (
                call :purge_stale_duckdb_cache "%DUCKDB_DOWNLOAD_URL%"
                call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%DUCKDB_DOWNLOAD_URL%" "%TEMP%\duckdb_cli.zip"
                if errorlevel 1 (
                    echo [ERROR] Failed to download duckdb from %DUCKDB_DOWNLOAD_URL% 1>&2
                    exit /b 1
                )
            )
            tar -xf "%TEMP%\duckdb_cli.zip" -C "%TARGET_DIR%\bin"
            del /f /q "%TEMP%\duckdb_cli.zip" 2>nul
        ) else (
            if exist "%TEMP%\duckdb_cli.zip" del /f /q "%TEMP%\duckdb_cli.zip" 2>nul
            set "_dl_ok=0"
            call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://github.com/duckdb/duckdb/releases/download/v!EXACT_VERSION!/duckdb_cli-windows-amd64.zip" "%TEMP%\duckdb_cli.zip"
            if not errorlevel 1 if exist "%TEMP%\duckdb_cli.zip" (
                tar -xf "%TEMP%\duckdb_cli.zip" -C "%TARGET_DIR%\bin" 2>nul
                if exist "%TARGET_DIR%\bin\duckdb.exe" set "_dl_ok=1"
            )
            if "!_dl_ok!"=="0" (
                call :purge_stale_duckdb_cache "duckdb_cli-windows-amd64.zip"
                if exist "%TEMP%\duckdb_cli.zip" del /f /q "%TEMP%\duckdb_cli.zip" 2>nul
                call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-windows-amd64.zip" "%TEMP%\duckdb_cli.zip"
                if not errorlevel 1 if exist "%TEMP%\duckdb_cli.zip" (
                    tar -xf "%TEMP%\duckdb_cli.zip" -C "%TARGET_DIR%\bin" 2>nul
                    if exist "%TARGET_DIR%\bin\duckdb.exe" set "_dl_ok=1"
                )
            )
            if exist "%TEMP%\duckdb_cli.zip" del /f /q "%TEMP%\duckdb_cli.zip" 2>nul
            if "!_dl_ok!"=="0" (
                echo [ERROR] No download URL or cache available for duckdb. 1>&2
                exit /b 1
            )
        )
    )
    if exist "%TARGET_DIR%\duckdb.exe" if not exist "%TARGET_DIR%\bin\duckdb.exe" (
        move /y "%TARGET_DIR%\duckdb.exe" "%TARGET_DIR%\bin\duckdb.exe" >nul 2>&1
    )
    if not exist "%TARGET_DIR%\bin\duckdb.exe" (
        echo [ERROR] DuckDB binary verification failed at %TARGET_DIR%\bin\duckdb.exe. 1>&2
        exit /b 1
    )
    "%TARGET_DIR%\bin\duckdb.exe" --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] DuckDB binary execution check failed at %TARGET_DIR%\bin\duckdb.exe. 1>&2
        exit /b 1
    )
) else (
    echo duckdb %DUCKDB_VERSION% is already installed.
)
set "ALIAS_DIR=%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" (
        dir /al "%ALIAS_DIR%" >nul 2>&1
        if not errorlevel 1 rmdir "%ALIAS_DIR%" >nul 2>&1
    )
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
set "DEFAULT_DIR=%LIBSCRIPT_HOME%\duckdb\default"
if not "%TARGET_DIR%"=="%DEFAULT_DIR%" (
    if exist "%DEFAULT_DIR%" rmdir "%DEFAULT_DIR%" 2>nul
    mklink /J "%DEFAULT_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions (start, stop, restart, status) to the common handler.
:action_service
:: ## action_install_service
:: Registers and configures the component as a persistent system service.
:action_install_service
:: ## action_uninstall_service
:: Stops and removes the registered system service for the component.
:action_uninstall_service
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "duckdb" "%ACTION%" "%DUCKDB_VERSION%" "%DUCKDB_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%\\bin\\duckdb.exe\"" "%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%"
exit /b !errorlevel!
