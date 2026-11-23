@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows and MS-DOS setup for freebsd-usr-bin backed by SamuelMarks/freebsd-usr-bin-windows (full suite or single applet).
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
if "%LIBSCRIPT_HOME%"=="" (
    if "%IS_MSDOS%"=="1" (
        set "LIBSCRIPT_HOME=C:\LIBSCRIP"
    ) else (
        set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
    )
)
if "%FREEBSD_USR_BIN_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "FREEBSD_USR_BIN_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "FREEBSD_USR_BIN_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "FREEBSD_USR_BIN_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%FREEBSD_USR_BIN_VERSION%"=="" set "FREEBSD_USR_BIN_VERSION=latest"
set "APPLET=%FREEBSD_USR_BIN_APPLET%"

if "%ACTION%"=="ls" goto :action_ls
if "%ACTION%"=="ls-remote" goto :action_ls_remote
if "%ACTION%"=="use" goto :action_use
if "%ACTION%"=="download" goto :action_download
if "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of freebsd-usr-bin.
:action_ls
if "%FREEBSD_USR_BIN_INSTALL_METHOD%"=="libscript_native" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\dos_83.cmd" :libscript_dos83_comp "freebsd-usr-bin" >nul
    if exist "%LIBSCRIPT_HOME%\!DOS83_COMP!" dir /b "%LIBSCRIPT_HOME%\!DOS83_COMP!"
) else (
    where sed >nul 2>&1 && echo freebsd-usr-bin utilities available on PATH
)
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of freebsd-usr-bin from SamuelMarks/freebsd-usr-bin-windows.
:action_ls_remote
set "RELEASES_URL=%FREEBSD_USR_BIN_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/SamuelMarks/freebsd-usr-bin-windows/releases/latest"
echo [ls-remote] Fetching available freebsd-usr-bin versions from !RELEASES_URL!...
call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
exit /b 0

:: ## action_use
:: Activates a specific installed version of freebsd-usr-bin and updates alias junctions.
:action_use
call :resolve_version
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "freebsd-usr-bin" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if not exist "!TARGET_DIR!" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    set "STACK="
    set "STACK="
    call "!THIS_FILE!"
)
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freebsd-usr-bin" "%FREEBSD_USR_BIN_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freebsd-usr-bin" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_download
:: Downloads the target-appropriate freebsd-usr-bin suite or applet archive to the local cache.
:action_download
call :resolve_version
call :resolve_fub_url
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
set "DL_DIR=!DL_DIR!\freebsd-usr-bin"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
echo [download] Pre-downloading freebsd-usr-bin !EXACT_VERSION! ^(!TARGET_OS!^) from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!"
exit /b !errorlevel!

:: ## action_install
:: Installs freebsd-usr-bin via from-source, system package manager, or libscript_native isolation.
:action_install
if /i "%FREEBSD_USR_BIN_INSTALL_METHOD%"=="from-source" (
    call :resolve_version
    set "SRC_URL=%FREEBSD_USR_BIN_DOWNLOAD_URL%"
    if "!SRC_URL!"=="" set "SRC_URL=https://github.com/SamuelMarks/freebsd-usr-bin-windows/archive/refs/tags/v!EXACT_VERSION!.tar.gz"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\source_builder.cmd" :libscript_build_component_from_source "freebsd-usr-bin" "!EXACT_VERSION!" "sed" "c" "cmake" "!SRC_URL!"
    exit /b !errorlevel!
)
if /i "%FREEBSD_USR_BIN_INSTALL_METHOD%"=="system" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via winget freebsd-usr-bin
    exit /b !errorlevel!
)
if /i "%FREEBSD_USR_BIN_INSTALL_METHOD%"=="winget" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via winget freebsd-usr-bin
    exit /b !errorlevel!
)
if /i "%FREEBSD_USR_BIN_INSTALL_METHOD%"=="choco" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via choco freebsd-usr-bin
    exit /b !errorlevel!
)
if /i "%FREEBSD_USR_BIN_INSTALL_METHOD%"=="scoop" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends_via scoop freebsd-usr-bin
    exit /b !errorlevel!
)
call :resolve_version
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "freebsd-usr-bin" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
set "_PROBE_BIN=sed"
if not "!APPLET!"=="" set "_PROBE_BIN=!APPLET!"
if exist "!TARGET_DIR!\bin\!_PROBE_BIN!.exe" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] freebsd-usr-bin !EXACT_VERSION! ^(!_PROBE_BIN!.exe^) is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freebsd-usr-bin" "%FREEBSD_USR_BIN_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freebsd-usr-bin" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
call :resolve_fub_url
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" set "DL_DIR=%TEMP%\libscript_downloads"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\freebsd-usr-bin\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached artifact !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\freebsd-usr-bin-!RANDOM!-!ARCHIVE_NAME!"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
    if errorlevel 1 (
        if "%FREEBSD_USR_BIN_DOWNLOAD_URL%"=="" (
            if not "!APPLET!"=="" (
                call :resolve_fub_applet_exe_url
                set "TMP_FILE=%TEMP%\freebsd-usr-bin-!RANDOM!.exe"
                call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!"
                if errorlevel 1 exit /b 1
            ) else (
                exit /b 1
            )
        ) else (
            exit /b 1
        )
    )
)
call :stage_fub_artifact "!TMP_FILE!" "!URL!" "!TARGET_DIR!"
if errorlevel 1 exit /b 1
if not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" 2>nul
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freebsd-usr-bin" "%FREEBSD_USR_BIN_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "freebsd-usr-bin" "default" "!EXACT_VERSION!"
exit /b 0

:: ## resolve_win_arch
:: Maps ARCH into SamuelMarks/freebsd-usr-bin-windows asset architecture tags (X64, X86, ARM64).
:resolve_win_arch
set "WIN_ARCH=X64"
if /i "%ARCH%"=="i686" set "WIN_ARCH=X86"
if /i "%ARCH%"=="i386" set "WIN_ARCH=X86"
if /i "%ARCH%"=="x86" set "WIN_ARCH=X86"
if /i "%ARCH%"=="aarch64" set "WIN_ARCH=ARM64"
if /i "%ARCH%"=="arm64" set "WIN_ARCH=ARM64"
exit /b 0

:: ## resolve_fub_url
:: Selects MS-DOS dos32 vs Windows PE suite or single-applet archive URLs.
:resolve_fub_url
call :resolve_win_arch
set "URL=%FREEBSD_USR_BIN_DOWNLOAD_URL%"
if not "!URL!"=="" (
    call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
    exit /b 0
)
if /i "%TARGET_OS%"=="msdos" (
    if not "!APPLET!"=="" (
        set "URL=https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v!EXACT_VERSION!/!APPLET!-!EXACT_VERSION!-dos32.zip"
    ) else (
        set "URL=https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v!EXACT_VERSION!/freebsd-usr-bin-!EXACT_VERSION!-dos32.zip"
    )
    exit /b 0
)
if not "!APPLET!"=="" (
    set "URL=https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v!EXACT_VERSION!/!APPLET!-!EXACT_VERSION!-windows.zip"
) else (
    set "URL=https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v!EXACT_VERSION!/freebsd-usr-bin-!EXACT_VERSION!-!WIN_ARCH!.zip"
)
exit /b 0

:: ## resolve_fub_applet_exe_url
:: Provides fallback standalone .exe URL for a single FreeBSD usr.bin applet.
:resolve_fub_applet_exe_url
call :resolve_win_arch
if /i "%TARGET_OS%"=="msdos" (
    set "URL=https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v!EXACT_VERSION!/!APPLET!-!EXACT_VERSION!-dos32.exe"
    exit /b 0
)
set "URL=https://github.com/SamuelMarks/freebsd-usr-bin-windows/releases/download/v!EXACT_VERSION!/!APPLET!-!EXACT_VERSION!-!WIN_ARCH!.exe"
exit /b 0

:: ## stage_fub_artifact
:: Extracts or copies FreeBSD usr.bin executables into TARGET_DIR\bin.
:stage_fub_artifact
set "_SFA_FILE=%~1"
set "_SFA_URL=%~2"
set "_SFA_DST=%~3"
if not exist "!_SFA_DST!\bin" mkdir "!_SFA_DST!\bin"
if /i "!_SFA_URL:~-4!"==".zip" (
    call :extract_zip "!_SFA_FILE!" "!_SFA_DST!"
    if errorlevel 1 exit /b 1
    for %%X in ("!_SFA_DST!\*.exe" "!_SFA_DST!\*.EXE") do (
        if exist "%%~fX" copy /y "%%~fX" "!_SFA_DST!\bin\%%~nxX" >nul
    )
    exit /b 0
)
set "_OUT_BIN=sed.exe"
if not "!APPLET!"=="" set "_OUT_BIN=!APPLET!.exe"
copy /y "!_SFA_FILE!" "!_SFA_DST!\bin\!_OUT_BIN!" >nul
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
if /i "%FREEBSD_USR_BIN_VERSION%"=="latest" goto :resolve_remote_gh_tag
if /i "%FREEBSD_USR_BIN_VERSION%"=="lts" goto :resolve_remote_gh_tag
if /i "%FREEBSD_USR_BIN_VERSION%"=="stable" goto :resolve_remote_gh_tag
set "EXACT_VERSION=%FREEBSD_USR_BIN_VERSION%"
if /i "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
exit /b 0

:: ## resolve_remote_gh_tag
:: Queries SamuelMarks/freebsd-usr-bin-windows GitHub Releases API for the latest tag with offline fallback 15.0.0.
:resolve_remote_gh_tag
set "EXACT_VERSION="
set "_REL_API=%FREEBSD_USR_BIN_RELEASES_URL%"
if "!_REL_API!"=="" set "_REL_API=https://api.github.com/repos/SamuelMarks/freebsd-usr-bin-windows/releases/latest"
for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_resolve_github_tag "!_REL_API!"') do (
    set "EXACT_VERSION=%%T"
)
if not "!EXACT_VERSION!"=="" (
    if /i "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=15.0.0"
exit /b 0

:: ## action_other
:: Delegates service and lifecycle actions to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\engine\common\setup_base.cmd" :libscript_handle_generic_action "freebsd-usr-bin" "%ACTION%" "%FREEBSD_USR_BIN_VERSION%" "%FREEBSD_USR_BIN_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\freebsd-usr-bin\%FREEBSD_USR_BIN_VERSION%\\bin\\sed.exe\"" "%LIBSCRIPT_HOME%\freebsd-usr-bin\%FREEBSD_USR_BIN_VERSION%"
exit /b !errorlevel!
