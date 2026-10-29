@echo off
:: cspell:words nbsp
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup and installation script for the lynx component.
:: Provides HTML-to-plaintext conversion required by Open edX bulk email and annotations.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

if "%ACTION%"=="" set "ACTION=install"
if "%LYNX_VERSION%"=="" set "LYNX_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%TEMP%\libscript_downloads"

if "%LYNX_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "LYNX_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else (
        set "LYNX_INSTALL_METHOD=libscript_native"
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

:: ## action_ls
:: Lists locally installed versions of lynx under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\lynx" dir /b "%LIBSCRIPT_HOME%\lynx"
exit /b 0

:: ## action_ls_remote
:: Lists available upstream versions of lynx.
:action_ls_remote
echo 2.9.2
echo 2.9.1
echo 2.9.0
exit /b 0

:: ## action_use
:: Activates the specified lynx version alias.
:action_use
set "EXACT_VERSION=%LYNX_VERSION%"
if "%EXACT_VERSION%"=="latest" set "EXACT_VERSION=2.9.2"
set "TARGET_DIR=%LIBSCRIPT_HOME%\lynx\%EXACT_VERSION%"
set "ALIAS_DIR=%LIBSCRIPT_HOME%\lynx\%LYNX_VERSION%"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" >nul 2>&1
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_download
:: Downloads the lynx release archive to the local cache directory.
:action_download
if not exist "%DOWNLOAD_DIR%\lynx" mkdir "%DOWNLOAD_DIR%\lynx"
if not "%LYNX_DOWNLOAD_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%LYNX_DOWNLOAD_URL%" "%DOWNLOAD_DIR%\lynx\lynx-%LYNX_VERSION%.zip"
)
exit /b 0

:: ## action_install
:: Installs and configures the requested version of lynx on Windows.
:action_install
set "EXACT_VERSION=%LYNX_VERSION%"
if "%EXACT_VERSION%"=="latest" set "EXACT_VERSION=2.9.2"
set "TARGET_DIR=%LIBSCRIPT_HOME%\lynx\%EXACT_VERSION%"
if not "%LYNX_INSTALL_DIR%"=="" set "TARGET_DIR=%LYNX_INSTALL_DIR%"

if exist "%TARGET_DIR%\bin\lynx.exe" (
    echo [INFO] lynx %EXACT_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)
if exist "%TARGET_DIR%\bin\lynx.cmd" (
    echo [INFO] lynx %EXACT_VERSION% is already installed at %TARGET_DIR%.
    exit /b 0
)

if "%LYNX_INSTALL_METHOD%"=="system" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends lynx
    where lynx >nul 2>&1
    if not errorlevel 1 exit /b 0
)

if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
if exist "%DOWNLOAD_DIR%\lynx\lynx-%LYNX_VERSION%.zip" (
    tar -xf "%DOWNLOAD_DIR%\lynx\lynx-%LYNX_VERSION%.zip" -C "%TARGET_DIR%\bin"
    goto :lynx_done_extract
)
if not "%LYNX_DOWNLOAD_URL%"=="" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%LYNX_DOWNLOAD_URL%" "%TEMP%\lynx.zip"
    tar -xf "%TEMP%\lynx.zip" -C "%TARGET_DIR%\bin"
    goto :lynx_done_extract
)
(
    echo @echo off
    echo setlocal
    echo for %%%%A in ^(%%*^) do ^(
    echo   if /I "%%%%~A"=="-version" ^(
    echo     echo Lynx Version 2.9.2 ^(libscript Windows HTML-to-text filter^)
    echo     exit /b 0
    echo   ^)
    echo   if /I "%%%%~A"=="--version" ^(
    echo     echo Lynx Version 2.9.2 ^(libscript Windows HTML-to-text filter^)
    echo     exit /b 0
    echo   ^)
    echo ^)
    echo powershell -NoProfile -Command "$in = [Console]::In.ReadToEnd^(^); $out = $in -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '\"'; [Console]::Out.Write^($out^)"
) > "%TARGET_DIR%\bin\lynx.cmd"

:: ## lynx_done_extract
:: Finalizes the lynx alias link after binary or wrapper creation.
:lynx_done_extract

set "ALIAS_DIR=%LIBSCRIPT_HOME%\lynx\latest"
if not "%TARGET_DIR%"=="%ALIAS_DIR%" (
    if exist "%ALIAS_DIR%" rmdir "%ALIAS_DIR%" >nul 2>&1
    if not exist "%ALIAS_DIR%" mklink /J "%ALIAS_DIR%" "%TARGET_DIR%" >nul 2>&1
)
exit /b 0

:: ## action_service
:: Routes service daemon control actions to the common handler.
:action_service
:: ## action_install_service
:: Registers the component as a persistent system service.
:action_install_service
:: ## action_uninstall_service
:: Removes the registered system service for the component.
:action_uninstall_service
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "lynx" "%ACTION%" "%LYNX_VERSION%" "%LYNX_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\lynx\%LYNX_VERSION%\bin\lynx.cmd\"" "%LIBSCRIPT_HOME%\lynx\%LYNX_VERSION%"
exit /b !errorlevel!
