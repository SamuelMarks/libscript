@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for shellcheck implementing the Version Manager Contract.
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use, and uninstall capabilities.
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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%SHELLCHECK_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "SHELLCHECK_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "SHELLCHECK_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%SHELLCHECK_VERSION%"=="" set "SHELLCHECK_VERSION=latest"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of shellcheck.
:action_ls
if /i "%SHELLCHECK_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\shellcheck" dir /b "%LIBSCRIPT_HOME%\shellcheck"
) else (
    where shellcheck >nul 2>&1 && shellcheck --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of shellcheck.
:action_ls_remote
set "RELEASES_URL=%SHELLCHECK_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/koalaman/shellcheck/releases"
echo [ls-remote] Fetching available shellcheck versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of shellcheck and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\shellcheck\!EXACT_VERSION!"
if not exist "!TARGET_DIR!\bin\shellcheck.exe" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    set "STACK="
    call "%~f0"
)
call :update_aliases
exit /b 0

:: ## action_download
:: Downloads the shellcheck release artifact to the local cache directory.
:action_download
call :resolve_version
call :resolve_url
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" (
    if not "%LIBSCRIPT_CACHE_DIR%"=="" (
        set "DL_DIR=%LIBSCRIPT_CACHE_DIR%"
    ) else (
        set "DL_DIR=%LIBSCRIPT_ROOT_DIR%\cache\downloads"
    )
)
set "DL_DIR=!DL_DIR!\shellcheck"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading shellcheck !EXACT_VERSION! from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
set "PACKAGE_NAME=shellcheck"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs shellcheck via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%SHELLCHECK_INSTALL_METHOD%"=="from-source" goto :install_from_source
if /i "%SHELLCHECK_INSTALL_METHOD%"=="source" goto :install_from_source
if /i "%SHELLCHECK_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends shellcheck
    exit /b !errorlevel!
)
if /i "%SHELLCHECK_INSTALL_METHOD%"=="winget" (
    set "LIBSCRIPT_PKG_MGR=winget"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends shellcheck
    exit /b !errorlevel!
)
if /i "%SHELLCHECK_INSTALL_METHOD%"=="choco" (
    set "LIBSCRIPT_PKG_MGR=choco"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends shellcheck
    exit /b !errorlevel!
)
if /i "%SHELLCHECK_INSTALL_METHOD%"=="scoop" (
    set "LIBSCRIPT_PKG_MGR=scoop"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends shellcheck
    exit /b !errorlevel!
)

call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\shellcheck\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\shellcheck.exe" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] shellcheck !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call :update_aliases
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
call :resolve_url

set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" (
    if not "%LIBSCRIPT_CACHE_DIR%"=="" (
        set "DL_DIR=%LIBSCRIPT_CACHE_DIR%"
    ) else (
        set "DL_DIR=%LIBSCRIPT_ROOT_DIR%\cache\downloads"
    )
)
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\shellcheck\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\shellcheck-!RANDOM!-!ARCHIVE_NAME!"
    set "PACKAGE_NAME=shellcheck"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 exit /b 1
)

set "STAGE_DIR=%TEMP%\shellcheck-stage-!RANDOM!"
if not exist "!STAGE_DIR!" mkdir "!STAGE_DIR!"

if /i "!URL:~-4!"==".zip" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!TMP_FILE!' -DestinationPath '!STAGE_DIR!' -Force"
    if errorlevel 1 (
        rmdir /s /q "!STAGE_DIR!" 2>nul
        exit /b 1
    )
    if exist "!STAGE_DIR!\shellcheck.exe" (
        copy /y "!STAGE_DIR!\shellcheck.exe" "!TARGET_DIR!\bin\shellcheck.exe" >nul
    ) else if exist "!STAGE_DIR!\shellcheck-v!EXACT_VERSION!\shellcheck.exe" (
        copy /y "!STAGE_DIR!\shellcheck-v!EXACT_VERSION!\shellcheck.exe" "!TARGET_DIR!\bin\shellcheck.exe" >nul
    ) else if exist "!STAGE_DIR!\bin\shellcheck.exe" (
        copy /y "!STAGE_DIR!\bin\shellcheck.exe" "!TARGET_DIR!\bin\shellcheck.exe" >nul
    )
    if exist "!STAGE_DIR!\LICENSE.txt" copy /y "!STAGE_DIR!\LICENSE.txt" "!TARGET_DIR!\LICENSE.txt" >nul
    if exist "!STAGE_DIR!\README.txt" copy /y "!STAGE_DIR!\README.txt" "!TARGET_DIR!\README.txt" >nul
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\shellcheck.exe" >nul
)

rmdir /s /q "!STAGE_DIR!" 2>nul
if /i not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul

if not exist "!TARGET_DIR!\bin\shellcheck.exe" (
    echo Error: shellcheck.exe was not extracted into "!TARGET_DIR!\bin\shellcheck.exe" 1>&2
    exit /b 1
)

call :update_aliases
exit /b 0

:: ## install_from_source
:: Compiles shellcheck from source using Cabal when available or the LibScript source_builder fallback.
:install_from_source
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\shellcheck\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\shellcheck.exe" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] shellcheck !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call :update_aliases
        exit /b 0
    )
)
where cabal >nul 2>&1
if not errorlevel 1 (
    if not "%LIBSCRIPT_OFFLINE%"=="1" (
        if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
        cabal update && cabal install "ShellCheck-!EXACT_VERSION!" --installdir="!TARGET_DIR!\bin" --install-method=copy --overwrite-policy=always
        if exist "!TARGET_DIR!\bin\shellcheck.exe" (
            call :update_aliases
            exit /b 0
        )
    )
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "shellcheck" "!EXACT_VERSION!" "shellcheck" "c"
set "_sb_rc=!errorlevel!"
if "!_sb_rc!"=="0" call :update_aliases
exit /b !_sb_rc!

:: ## resolve_version
:: Resolves latest, stable, or lts version aliases into EXACT_VERSION and strips leading 'v'.
:resolve_version
set "_RAW_VER=%SHELLCHECK_VERSION%"
if /i "!_RAW_VER!"=="latest" goto :resolve_remote_tag
if /i "!_RAW_VER!"=="stable" goto :resolve_remote_tag
if /i "!_RAW_VER!"=="lts" goto :resolve_remote_tag
if /i "!_RAW_VER:~0,1!"=="v" set "_RAW_VER=!_RAW_VER:~1!"
set "EXACT_VERSION=!_RAW_VER!"
exit /b 0

:: ## resolve_remote_tag
:: Queries GitHub Releases API for the latest tag with offline cache and 0.11.0 fallback.
:resolve_remote_tag
set "EXACT_VERSION="
if not "%LIBSCRIPT_OFFLINE%"=="1" (
    if not "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
        for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos/koalaman/shellcheck/releases/latest"') do (
            set "EXACT_VERSION=%%T"
        )
    )
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=0.11.0"
if /i "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
exit /b 0

:: ## resolve_url
:: Resolves the Windows download URL and substitutes {VERSION} with EXACT_VERSION.
:resolve_url
set "URL=%SHELLCHECK_DOWNLOAD_URL%"
if "!URL!"=="" (
    set "URL=https://github.com/koalaman/shellcheck/releases/download/v!EXACT_VERSION!/shellcheck-v!EXACT_VERSION!.zip"
) else (
    call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
)
exit /b 0

:: ## update_aliases
:: Updates version alias and default directory junctions for shellcheck.
:update_aliases
set "_ALIAS_NAME=%SHELLCHECK_VERSION%"
if /i "!_ALIAS_NAME:~0,1!"=="v" set "_ALIAS_NAME=!_ALIAS_NAME:~1!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "shellcheck" "!_ALIAS_NAME!" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "shellcheck" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "shellcheck" "%ACTION%" "%SHELLCHECK_VERSION%" "%SHELLCHECK_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\shellcheck\%SHELLCHECK_VERSION%\\bin\\shellcheck.exe\"" "%LIBSCRIPT_HOME%\shellcheck\%SHELLCHECK_VERSION%"
exit /b !errorlevel!
