@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows and MS-DOS setup for toybox backed by SamuelMarks/toybox-windows (PE on Windows, dos32 on MS-DOS).
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

call "%LIBSCRIPT_ROOT_DIR%\engine\common\os_info.cmd"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%TOYBOX_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "TOYBOX_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "TOYBOX_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "TOYBOX_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%TOYBOX_VERSION%"=="" set "TOYBOX_VERSION=latest"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of toybox.
:action_ls
if "%TOYBOX_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\toybox" dir /b "%LIBSCRIPT_HOME%\toybox"
) else (
    where toybox >nul 2>&1 && toybox --version
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of toybox from SamuelMarks/toybox-windows.
:action_ls_remote
set "RELEASES_URL=%TOYBOX_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/SamuelMarks/toybox-windows/releases/latest"
echo [ls-remote] Fetching available toybox versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of toybox and updates alias junctions.
:action_use
call :resolve_version
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "toybox" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    set "STACK="
    call "%~f0"
)
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "toybox" "%TOYBOX_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "toybox" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the target-appropriate toybox release artifact to the local cache directory.
:action_download
call :resolve_version
call :resolve_toybox_url
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\toybox"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading toybox !EXACT_VERSION! ^(!TARGET_OS!^) from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs toybox via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%TOYBOX_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "SRC_URL=%TOYBOX_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://landley.net/toybox/downloads/toybox-!EXACT_VERSION!.tar.gz"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\source_builder.cmd" :libscript_build_component_from_source "toybox" "!EXACT_VERSION!" "toybox" "c" "make-defconfig" "!SRC_URL!"
    exit /b !errorlevel!
)
if /i "%TOYBOX_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via winget toybox
    exit /b !errorlevel!
)
if /i "%TOYBOX_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via winget toybox
    exit /b !errorlevel!
)
if /i "%TOYBOX_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via choco toybox
    exit /b !errorlevel!
)
if /i "%TOYBOX_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via scoop toybox
    exit /b !errorlevel!
)
call :resolve_version
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "toybox" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\bin\toybox.exe" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] toybox !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call :materialize_toybox_shims "!TARGET_DIR!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "toybox" "%TOYBOX_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "toybox" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
call :resolve_toybox_url
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\toybox\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached artifact !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\toybox-!RANDOM!-!ARCHIVE_NAME!"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 (
        if "%TOYBOX_DOWNLOAD_URL%"=="" (
            call :resolve_toybox_fallback_exe_url
            set "TMP_FILE=%TEMP%\toybox-!RANDOM!.exe"
            call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
            if errorlevel 1 exit /b 1
        ) else (
            exit /b 1
        )
    )
)
call :stage_toybox_artifact "!TMP_FILE!" "!URL!" "!TARGET_DIR!"
if errorlevel 1 exit /b 1
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call :materialize_toybox_shims "!TARGET_DIR!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "toybox" "%TOYBOX_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "toybox" "default" "!EXACT_VERSION!"
exit /b 0

:: ## materialize_toybox_shims
:: Materializes per-applet NTFS hardlinks or .bat trampolines in TARGET_DIR\bin when TOYBOX_INSTALL_SHIMS=1 and freebsd-usr-bin is not installed.
:materialize_toybox_shims
set "_MTS_DIR=%~1"
set "_MTS_DO=0"
if "%TOYBOX_INSTALL_SHIMS%"=="1" set "_MTS_DO=1"
if /i "%TOYBOX_INSTALL_SHIMS%"=="true" set "_MTS_DO=1"
if "!_MTS_DO!"=="0" exit /b 0
if exist "%LIBSCRIPT_HOME%\freebsd-usr-bin\default\bin\sed.exe" (
    echo [INFO] freebsd-usr-bin is installed; skipping toybox applet shims.
    exit /b 0
)
if not exist "!_MTS_DIR!\bin" mkdir "!_MTS_DIR!\bin"
for %%A in (basename cat cmp comm cp cut date diff dirname env file find grep head ln ls mkdir mktemp mv paste patch printf readlink realpath rm rmdir sed sha1sum sha256sum sleep sort stat tail tee touch tr uname uniq wc which xargs) do (
    if /i "%TARGET_OS%"=="msdos" (
        > "!_MTS_DIR!\bin\%%A.bat" (
            echo @echo off
            echo toybox.exe %%A %%1 %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9
        )
    ) else (
        if not exist "!_MTS_DIR!\bin\%%A.exe" (
            mklink /H "!_MTS_DIR!\bin\%%A.exe" "!_MTS_DIR!\bin\toybox.exe" >nul 2>&1
        )
        if not exist "!_MTS_DIR!\bin\%%A.exe" (
            > "!_MTS_DIR!\bin\%%A.bat" (
                echo @echo off
                echo "%%~dp0toybox.exe" %%A %%*
            )
        )
    )
)
exit /b 0

:: ## resolve_win_arch
:: Maps ARCH into SamuelMarks/toybox-windows asset architecture tags (X64, X86, ARM64).
:resolve_win_arch
set "WIN_ARCH=X64"
if /i "%ARCH%"=="i686" set "WIN_ARCH=X86"
if /i "%ARCH%"=="i386" set "WIN_ARCH=X86"
if /i "%ARCH%"=="x86" set "WIN_ARCH=X86"
if /i "%ARCH%"=="aarch64" set "WIN_ARCH=ARM64"
if /i "%ARCH%"=="arm64" set "WIN_ARCH=ARM64"
exit /b 0

:: ## resolve_toybox_url
:: Selects the MS-DOS dos32 archive URL when TARGET_OS=msdos or Windows PE archive URL on Windows.
:resolve_toybox_url
call :resolve_win_arch
set "URL=%TOYBOX_DOWNLOAD_URL%"
if not "!URL!"=="" (
    call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
    exit /b 0
)
if /i "%TARGET_OS%"=="msdos" (
    set "URL=https://github.com/SamuelMarks/toybox-windows/releases/download/v!EXACT_VERSION!/toybox-!EXACT_VERSION!-dos32.zip"
    exit /b 0
)
set "URL=https://github.com/SamuelMarks/toybox-windows/releases/download/v!EXACT_VERSION!/toybox-!EXACT_VERSION!-!WIN_ARCH!.zip"
exit /b 0

:: ## resolve_toybox_fallback_exe_url
:: Provides fallback standalone .exe URLs for MS-DOS and Windows toybox releases.
:resolve_toybox_fallback_exe_url
call :resolve_win_arch
if /i "%TARGET_OS%"=="msdos" (
    set "URL=https://github.com/SamuelMarks/toybox-windows/releases/download/v!EXACT_VERSION!/toybox-!EXACT_VERSION!-dos32.exe"
    exit /b 0
)
set "URL=https://github.com/SamuelMarks/toybox-windows/releases/download/v!EXACT_VERSION!/toybox-!EXACT_VERSION!-!WIN_ARCH!.exe"
exit /b 0

:: ## stage_toybox_artifact
:: Extracts or copies toybox into TARGET_DIR\bin\toybox.exe.
:stage_toybox_artifact
set "_STA_FILE=%~1"
set "_STA_URL=%~2"
set "_STA_DST=%~3"
if not exist "!_STA_DST!\bin" mkdir "!_STA_DST!\bin"
if /i "!_STA_URL:~-4!"==".zip" (
    call :extract_zip "!_STA_FILE!" "!_STA_DST!"
    if errorlevel 1 exit /b 1
    if exist "!_STA_DST!\toybox.exe" copy /y "!_STA_DST!\toybox.exe" "!_STA_DST!\bin\toybox.exe" >nul
    if exist "!_STA_DST!\TOYBOX.EXE" copy /y "!_STA_DST!\TOYBOX.EXE" "!_STA_DST!\bin\toybox.exe" >nul
    for %%E in (DOS32A.EXE DOS4GW.EXE) do (
        if exist "!_STA_DST!\%%E" copy /y "!_STA_DST!\%%E" "!_STA_DST!\bin\%%E" >nul
    )
    exit /b 0
)
copy /y "!_STA_FILE!" "!_STA_DST!\bin\toybox.exe" >nul
exit /b !errorlevel!

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
if /i "%TOYBOX_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%TOYBOX_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%TOYBOX_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%TOYBOX_VERSION%"
if /i "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries SamuelMarks/toybox-windows GitHub Releases API for the latest tag with offline fallback 0.8.15.
:resolve_remote_gh_tag
set "EXACT_VERSION="
set "_REL_API=%TOYBOX_RELEASES_URL%"
if "!_REL_API!"=="" set "_REL_API=https://api.github.com/repos/SamuelMarks/toybox-windows/releases/latest"
for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_resolve_github_tag "!_REL_API!"') do (
    set "EXACT_VERSION=%%T"
)
if not "!EXACT_VERSION!"=="" (
    if /i "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=0.8.15"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\engine\common\setup_base.cmd" :libscript_handle_generic_action "toybox" "%ACTION%" "%TOYBOX_VERSION%" "%TOYBOX_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\toybox\%TOYBOX_VERSION%\\bin\\toybox.exe\"" "%LIBSCRIPT_HOME%\toybox\%TOYBOX_VERSION%"
exit /b !errorlevel!
