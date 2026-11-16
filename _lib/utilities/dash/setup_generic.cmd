@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows and MS-DOS setup for dash backed by SamuelMarks/dash-windows.
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

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\os_info.cmd"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%DASH_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "DASH_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "DASH_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "DASH_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%DASH_VERSION%"=="" set "DASH_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of dash.
:action_ls
if "%DASH_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\dash" dir /b "%LIBSCRIPT_HOME%\dash"
) else (
    where dash >nul 2>&1 && echo dash installed via system
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of dash from SamuelMarks/dash-windows.
:action_ls_remote
set "RELEASES_URL=%DASH_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/SamuelMarks/dash-windows/releases/latest"
echo [ls-remote] Fetching available dash versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of dash and updates alias junctions.
:action_use
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\dash\!EXACT_VERSION!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    set "STACK="
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "dash" "%DASH_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "dash" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the target-appropriate dash release artifact to the local cache directory.
:action_download
call :resolve_version
call :resolve_dash_url
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\dash"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading dash !EXACT_VERSION! ^(!TARGET_OS!^) from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs dash via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%DASH_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "SRC_URL=%DASH_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=http://gondor.apana.org.au/~herbert/dash/files/dash-!EXACT_VERSION!.tar.gz"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\source_builder.cmd" :libscript_build_component_from_source "dash" "!EXACT_VERSION!" "dash" "c" "autotools" "!SRC_URL!"
    exit /b !errorlevel!
)
if /i "%DASH_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget dash
    exit /b !errorlevel!
)
if /i "%DASH_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via winget dash
    exit /b !errorlevel!
)
if /i "%DASH_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via choco dash
    exit /b !errorlevel!
)
if /i "%DASH_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_depends_via scoop dash
    exit /b !errorlevel!
)
call :resolve_version
set "TARGET_DIR=%LIBSCRIPT_HOME%\dash\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\dash.exe" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] dash !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "dash" "%DASH_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "dash" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
call :resolve_dash_url
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\dash\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached artifact !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\dash-!RANDOM!-!ARCHIVE_NAME!"
    call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 (
        if "%DASH_DOWNLOAD_URL%"=="" (
            call :resolve_dash_fallback_url
            set "TMP_FILE=%TEMP%\dash-!RANDOM!-alt"
            call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
            if errorlevel 1 exit /b 1
        ) else (
            exit /b 1
        )
    )
)
call :stage_dash_artifact "!TMP_FILE!" "!URL!" "!TARGET_DIR!"
if errorlevel 1 exit /b 1
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "dash" "%DASH_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\versioning.cmd" :libscript_symlink_alias "dash" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_win_arch
:: Maps ARCH into SamuelMarks/dash-windows asset architecture tags (X64, X86, ARM64).
:resolve_win_arch
set "WIN_ARCH=X64"
if /i "%ARCH%"=="i686" set "WIN_ARCH=X86"
if /i "%ARCH%"=="i386" set "WIN_ARCH=X86"
if /i "%ARCH%"=="x86" set "WIN_ARCH=X86"
if /i "%ARCH%"=="aarch64" set "WIN_ARCH=ARM64"
if /i "%ARCH%"=="arm64" set "WIN_ARCH=ARM64"
exit /b 0

:: ## resolve_dash_url
:: Selects the MS-DOS dos32 archive URL when TARGET_OS=msdos or Windows PE archive URL on Windows.
:resolve_dash_url
call :resolve_win_arch
set "URL=%DASH_DOWNLOAD_URL%"
if not "!URL!"=="" (
    call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
    exit /b 0
)
if /i "%TARGET_OS%"=="msdos" (
    set "URL=https://github.com/SamuelMarks/dash-windows/releases/download/v!EXACT_VERSION!/dash-!EXACT_VERSION!-dos32.zip"
    exit /b 0
)
set "URL=https://github.com/SamuelMarks/dash-windows/releases/download/v!EXACT_VERSION!/dash-!EXACT_VERSION!-!WIN_ARCH!.zip"
exit /b 0

:: ## resolve_dash_fallback_url
:: Provides fallback URLs for MS-DOS and Windows dash releases.
:resolve_dash_fallback_url
if /i "%TARGET_OS%"=="msdos" (
    set "URL=https://github.com/SamuelMarks/dash-windows/releases/download/v!EXACT_VERSION!/dash-!EXACT_VERSION!-dos32.exe"
    exit /b 0
)
set "URL=https://github.com/SamuelMarks/dash-windows/releases/download/v!EXACT_VERSION!/dash-windows-!EXACT_VERSION!-win64.zip"
exit /b 0

:: ## stage_dash_artifact
:: Extracts or copies dash into TARGET_DIR\bin\dash.exe and creates bin\sh.exe alias.
:stage_dash_artifact
set "_SDA_FILE=%~1"
set "_SDA_URL=%~2"
set "_SDA_DST=%~3"
if not exist "!_SDA_DST!\bin" mkdir "!_SDA_DST!\bin"
if /i "!_SDA_URL:~-4!"==".zip" (
    call :extract_zip "!_SDA_FILE!" "!_SDA_DST!"
    if errorlevel 1 exit /b 1
    if exist "!_SDA_DST!\dash.exe" copy /y "!_SDA_DST!\dash.exe" "!_SDA_DST!\bin\dash.exe" >nul
    if exist "!_SDA_DST!\DASH.EXE" copy /y "!_SDA_DST!\DASH.EXE" "!_SDA_DST!\bin\dash.exe" >nul
    for %%E in (DOS32A.EXE DOS4GW.EXE) do (
        if exist "!_SDA_DST!\%%E" copy /y "!_SDA_DST!\%%E" "!_SDA_DST!\bin\%%E" >nul
    )
) else (
    copy /y "!_SDA_FILE!" "!_SDA_DST!\bin\dash.exe" >nul
)
if exist "!_SDA_DST!\bin\dash.exe" (
    if not exist "!_SDA_DST!\bin\sh.exe" copy /y "!_SDA_DST!\bin\dash.exe" "!_SDA_DST!\bin\sh.exe" >nul
)
exit /b 0

:: ## extract_zip
:: Extracts a zip archive using PowerShell-free native tools first (7za, 7z, unzip, tar) with PowerShell fallback.
:extract_zip
set "_EZ_SRC=%~1"
set "_EZ_DST=%~2"
where 7za >nul 2>&1
if not errorlevel 1 (
    7za x "!_EZ_SRC!" -o"!_EZ_DST!" -y >nul
    exit /b !errorlevel!
)
where 7z >nul 2>&1
if not errorlevel 1 (
    7z x "!_EZ_SRC!" -o"!_EZ_DST!" -y >nul
    exit /b !errorlevel!
)
where unzip >nul 2>&1
if not errorlevel 1 (
    unzip -q -o "!_EZ_SRC!" -d "!_EZ_DST!"
    exit /b !errorlevel!
)
where tar >nul 2>&1
if not errorlevel 1 (
    tar -xf "!_EZ_SRC!" -C "!_EZ_DST!" 2>nul
    if not errorlevel 1 exit /b 0
)
where powershell >nul 2>&1
if not errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!_EZ_SRC!' -DestinationPath '!_EZ_DST!' -Force"
    exit /b !errorlevel!
)
echo [ERROR] No zip extraction binary ^(7za, 7z, unzip, tar^) available. 1>&2
exit /b 1

:: ## resolve_version
:: Resolves latest or lts version alias into EXACT_VERSION.
:resolve_version
if /i "%DASH_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%DASH_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%DASH_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%DASH_VERSION%"
if /i "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries SamuelMarks/dash-windows GitHub Releases API for the latest tag with offline fallback 0.5.12.
:resolve_remote_gh_tag
set "EXACT_VERSION="
set "_REL_API=%DASH_RELEASES_URL%"
if "!_REL_API!"=="" set "_REL_API=https://api.github.com/repos/SamuelMarks/dash-windows/releases/latest"
for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_resolve_github_tag "!_REL_API!"') do (
    set "EXACT_VERSION=%%T"
)
if not "!EXACT_VERSION!"=="" (
    if /i "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=0.5.12"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" :libscript_handle_generic_action "dash" "%ACTION%" "%DASH_VERSION%" "%DASH_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\dash\%DASH_VERSION%\\bin\\dash.exe\"" "%LIBSCRIPT_HOME%\dash\%DASH_VERSION%"
exit /b !errorlevel!
