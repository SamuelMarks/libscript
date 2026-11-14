@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows setup for edgcpp-backends-suite implementing the Version Manager Contract.
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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%EDGCPP_BACKENDS_SUITE_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "EDGCPP_BACKENDS_SUITE_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "EDGCPP_BACKENDS_SUITE_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%EDGCPP_BACKENDS_SUITE_VERSION%"=="" set "EDGCPP_BACKENDS_SUITE_VERSION=1.0.0"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of edgcpp-backends-suite.
:action_ls
if "%EDGCPP_BACKENDS_SUITE_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\edgcpp-backends-suite" dir /b "%LIBSCRIPT_HOME%\edgcpp-backends-suite"
) else (
    where edgcpp-backends-suite >nul 2>&1 && edgcpp-backends-suite --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of edgcpp-backends-suite.
:action_ls_remote
set "RELEASES_URL=%EDGCPP_BACKENDS_SUITE_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://example.com/releases"
echo [ls-remote] Fetching available edgcpp-backends-suite versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of edgcpp-backends-suite and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\edgcpp-backends-suite\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp-backends-suite" "%EDGCPP_BACKENDS_SUITE_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp-backends-suite" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the edgcpp-backends-suite release artifact to the local cache directory.
:action_download
call :resolve_version
set "URL=%EDGCPP_BACKENDS_SUITE_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://example.com/releases/edgcpp-backends-suite-{VERSION}-windows.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\edgcpp-backends-suite"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading edgcpp-backends-suite %EDGCPP_BACKENDS_SUITE_VERSION% from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs edgcpp-backends-suite via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%EDGCPP_BACKENDS_SUITE_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "TARGET_DIR=%LIBSCRIPT_HOME%\edgcpp-backends-suite\!EXACT_VERSION!"
    set "SRC_URL=%EDGCPP_BACKENDS_SUITE_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://example.com/releases/edgcpp-backends-suite-{VERSION}.tar.gz"
    call set "SRC_URL=%%SRC_URL:{VERSION}=!EXACT_VERSION!%%"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "edgcpp-backends-suite" "!EXACT_VERSION!" "edgcpp-backends-suite" "c" "autotools" "!SRC_URL!"
    exit /b !errorlevel!
)
if "%EDGCPP_BACKENDS_SUITE_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends edgcpp-backends-suite
    exit /b !errorlevel!
)
if /i "%EDGCPP_BACKENDS_SUITE_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget edgcpp-backends-suite
    exit /b !errorlevel!
)
if /i "%EDGCPP_BACKENDS_SUITE_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco edgcpp-backends-suite
    exit /b !errorlevel!
)
if /i "%EDGCPP_BACKENDS_SUITE_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop edgcpp-backends-suite
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\edgcpp-backends-suite\!EXACT_VERSION!"
set "_BIN_FOUND=0"
if exist "!TARGET_DIR!\bin\edgcpp-backends-suite.exe" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\edgcpp-backends-suite.cmd" set "_BIN_FOUND=1"
if exist "!TARGET_DIR!\bin\edgcpp-backends-suite.bat" set "_BIN_FOUND=1"
if "!_BIN_FOUND!"=="1" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] edgcpp-backends-suite !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp-backends-suite" "%EDGCPP_BACKENDS_SUITE_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp-backends-suite" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
set "URL=%EDGCPP_BACKENDS_SUITE_DOWNLOAD_URL%"
if "!URL!"=="" set "URL=https://example.com/releases/edgcpp-backends-suite-{VERSION}-windows.zip"
call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
if "!URL!"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends edgcpp-backends-suite
    exit /b !errorlevel!
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\edgcpp-backends-suite\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\edgcpp-backends-suite-!RANDOM!.archive"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 exit /b 1
)
set "_IS_ARCHIVE=0"
if /i "!URL:~-4!"==".zip" set "_IS_ARCHIVE=zip"
if /i "!URL:~-7!"==".tar.gz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-4!"==".tgz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-7!"==".tar.xz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-4!"==".txz" set "_IS_ARCHIVE=tar"
if /i "!URL:~-8!"==".tar.bz2" set "_IS_ARCHIVE=tar"
if /i "!URL:~-5!"==".tbz2" set "_IS_ARCHIVE=tar"
if not "!_IS_ARCHIVE!"=="0" (
    if "!_IS_ARCHIVE!"=="zip" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!TMP_FILE!' -DestinationPath '!TARGET_DIR!' -Force"
    ) else (
        tar -xf "!TMP_FILE!" -C "!TARGET_DIR!" --strip-components=1 2>nul || tar -xf "!TMP_FILE!" -C "!TARGET_DIR!"
    )
    for /d %%D in ("!TARGET_DIR!\*") do (
        if /i not "%%~nxD"=="bin" (
            set "_DO_FLAT=0"
            if exist "%%~fD\bin\edgcpp-backends-suite.exe" set "_DO_FLAT=1"
            if exist "%%~fD\bin\edgcpp-backends-suite.bat" set "_DO_FLAT=1"
            if exist "%%~fD\bin\edgcpp-backends-suite.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\edgcpp-backends-suite.exe" set "_DO_FLAT=1"
            if exist "%%~fD\edgcpp-backends-suite.cmd" set "_DO_FLAT=1"
            if exist "%%~fD\edgcpp-backends-suite.bat" set "_DO_FLAT=1"
            if "!_DO_FLAT!"=="1" (
                move /y "%%~fD" "!TARGET_DIR!_flat" >nul
                xcopy /E /I /Y "!TARGET_DIR!_flat\*" "!TARGET_DIR!\" >nul
                rmdir /s /q "!TARGET_DIR!_flat"
            )
        )
    )
    if not exist "!TARGET_DIR!\bin\edgcpp-backends-suite.exe" (
        if exist "!TARGET_DIR!\edgcpp-backends-suite.exe" (
            copy /y "!TARGET_DIR!\edgcpp-backends-suite.exe" "!TARGET_DIR!\bin\edgcpp-backends-suite.exe" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\edgcpp-backends-suite.cmd" (
        if exist "!TARGET_DIR!\edgcpp-backends-suite.cmd" (
            copy /y "!TARGET_DIR!\edgcpp-backends-suite.cmd" "!TARGET_DIR!\bin\edgcpp-backends-suite.cmd" >nul
        )
    )
    if not exist "!TARGET_DIR!\bin\edgcpp-backends-suite.bat" (
        if exist "!TARGET_DIR!\edgcpp-backends-suite.bat" (
            copy /y "!TARGET_DIR!\edgcpp-backends-suite.bat" "!TARGET_DIR!\bin\edgcpp-backends-suite.bat" >nul
        )
    )
) else (
    copy /y "!TMP_FILE!" "!TARGET_DIR!\bin\edgcpp-backends-suite.exe" >nul
)
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp-backends-suite" "%EDGCPP_BACKENDS_SUITE_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp-backends-suite" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%EDGCPP_BACKENDS_SUITE_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%EDGCPP_BACKENDS_SUITE_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%EDGCPP_BACKENDS_SUITE_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%EDGCPP_BACKENDS_SUITE_VERSION%"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries GitHub Releases API for the latest tag with offline fallback.
:resolve_remote_gh_tag
set "EXACT_VERSION="
if not "" == "" (
    for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "https://api.github.com/repos//releases/latest"') do (
        set "EXACT_VERSION=%%T"
    )
)
if not "v" == "" (
    if not "!EXACT_VERSION!"=="" set "EXACT_VERSION=!EXACT_VERSION:v=!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=1.0.0"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "edgcpp-backends-suite" "%ACTION%" "%EDGCPP_BACKENDS_SUITE_VERSION%" "%EDGCPP_BACKENDS_SUITE_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\edgcpp-backends-suite\%EDGCPP_BACKENDS_SUITE_VERSION%\\bin\\edgcpp-backends-suite.exe\"" "%LIBSCRIPT_HOME%\edgcpp-backends-suite\%EDGCPP_BACKENDS_SUITE_VERSION%"
exit /b !errorlevel!
