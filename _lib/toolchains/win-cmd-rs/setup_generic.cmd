@echo off
:: # setup_generic.cmd
:: ## Overview
:: Windows and MS-DOS setup for win-cmd-rs implementing the Version Manager Contract.
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
if "%WIN_CMD_RS_INSTALL_METHOD%"=="" (
    if not "%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"=="" (
        set "WIN_CMD_RS_INSTALL_METHOD=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
    ) else if not "%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"=="" (
        set "WIN_CMD_RS_INSTALL_METHOD=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
    ) else (
        set "WIN_CMD_RS_INSTALL_METHOD=libscript_native"
    )
)
if "%ACTION%"=="" set "ACTION=install"
if "%WIN_CMD_RS_VERSION%"=="" set "WIN_CMD_RS_VERSION=latest"

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="install" goto :action_install
goto :action_other

:: ## action_ls
:: Lists locally installed versions of win-cmd-rs.
:action_ls
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="libscript_native" (
    if exist "%LIBSCRIPT_HOME%\win-cmd-rs" dir /b "%LIBSCRIPT_HOME%\win-cmd-rs"
    exit /b 0
)
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="from-source" (
    if exist "%LIBSCRIPT_HOME%\win-cmd-rs" dir /b "%LIBSCRIPT_HOME%\win-cmd-rs"
    exit /b 0
)
where wincheck >nul 2>&1 && wincheck --version
exit /b 0

:: ## action_ls_remote
:: Queries available remote versions of win-cmd-rs from GitHub Releases.
:action_ls_remote
set "RELEASES_URL=%WIN_CMD_RS_RELEASES_URL%"
if "!RELEASES_URL!"=="" set "RELEASES_URL=https://api.github.com/repos/SamuelMarks/win-cmd-rs/releases"
echo [ls-remote] Fetching available win-cmd-rs versions from !RELEASES_URL!...
if not "%LIBSCRIPT_OFFLINE%"=="1" (
    if not "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_fetch_stdout "!RELEASES_URL!"
    )
)
exit /b 0

:: ## action_use
:: Activates a specific installed version of win-cmd-rs and updates alias junctions.
:action_use
call :resolve_version
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "win-cmd-rs" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if not exist "!TARGET_DIR!\bin\wincheck.exe" (
    echo Version !EXACT_VERSION! not installed. Installing...
    set "ACTION=install"
    set "STACK="
    set "STACK="
    call "!THIS_FILE!"
    if errorlevel 1 exit /b 1
)
call :update_aliases
exit /b 0

:: ## action_download
:: Downloads the win-cmd-rs release archive into the local cache directory idempotently.
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
set "DL_DIR=!DL_DIR!\win-cmd-rs"
if not exist "!DL_DIR!" mkdir "!DL_DIR!"
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
if exist "!DL_DIR!\!ARCHIVE_NAME!" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [download] Cached win-cmd-rs archive already present at !DL_DIR!\!ARCHIVE_NAME!.
        exit /b 0
    )
)
echo [download] Pre-downloading win-cmd-rs !EXACT_VERSION! from !URL! to !DL_DIR!\!ARCHIVE_NAME!...
set "PACKAGE_NAME=win-cmd-rs"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!DL_DIR!\!ARCHIVE_NAME!" "%WIN_CMD_RS_CHECKSUM%"
exit /b !errorlevel!

:: ## action_install
:: Installs win-cmd-rs via libscript_native release archives, system package manager, or Cargo source build.
:action_install
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="from-source" goto :install_from_source
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="source" goto :install_from_source
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="cargo" goto :install_from_source
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="system" (
    set "LIBSCRIPT_FORCE_SYSTEM_PKG_MGR=1"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends win-cmd-rs
    exit /b !errorlevel!
)
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="winget" (
    set "LIBSCRIPT_PKG_MGR=winget"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends win-cmd-rs
    exit /b !errorlevel!
)
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="choco" (
    set "LIBSCRIPT_PKG_MGR=choco"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends win-cmd-rs
    exit /b !errorlevel!
)
if /i "%WIN_CMD_RS_INSTALL_METHOD%"=="scoop" (
    set "LIBSCRIPT_PKG_MGR=scoop"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_depends win-cmd-rs
    exit /b !errorlevel!
)

call :resolve_version
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "win-cmd-rs" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\bin\wincheck.exe" (
    if exist "!TARGET_DIR!\bin\wincmd.exe" (
        if not "%FORCE_REINSTALL%"=="1" (
            echo [INFO] win-cmd-rs !EXACT_VERSION! is already installed at !TARGET_DIR!.
            call :update_aliases
            exit /b 0
        )
    )
)

if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
call :resolve_url
if errorlevel 1 goto :install_from_source

set "DL_DIR=%DOWNLOAD_DIR%"
if "!DL_DIR!"=="" (
    if not "%LIBSCRIPT_CACHE_DIR%"=="" (
        set "DL_DIR=%LIBSCRIPT_CACHE_DIR%"
    ) else (
        set "DL_DIR=%LIBSCRIPT_ROOT_DIR%\cache\downloads"
    )
)
for %%F in ("!URL!") do set "ARCHIVE_NAME=%%~nxF"
set "CACHED_DL=!DL_DIR!\win-cmd-rs\!ARCHIVE_NAME!"
if exist "!CACHED_DL!" (
    echo [install] Using cached archive !CACHED_DL!...
    set "TMP_FILE=!CACHED_DL!"
) else (
    set "TMP_FILE=%TEMP%\win-cmd-rs-!RANDOM!-!ARCHIVE_NAME!"
    set "PACKAGE_NAME=win-cmd-rs"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "!URL!" "!TMP_FILE!" "%WIN_CMD_RS_CHECKSUM%"
    if errorlevel 1 (
        if exist "!TMP_FILE!" del /f /q "!TMP_FILE!" >nul 2>&1
        if "%WIN_CMD_RS_DOWNLOAD_URL%"=="" (
            if exist "%LIBSCRIPT_ROOT_DIR%\..\win-cmd-rs\Cargo.toml" goto :install_from_source
            if not "%WIN_CMD_RS_REPO_DIR%"=="" goto :install_from_source
        )
        exit /b 1
    )
)

set "STAGE_DIR=%TEMP%\win-cmd-rs-stage-!RANDOM!"
if not exist "!STAGE_DIR!" mkdir "!STAGE_DIR!"

if /i "!URL:~-4!"==".zip" (
    call :extract_wcr_zip "!TMP_FILE!" "!STAGE_DIR!"
    if errorlevel 1 (
        rmdir /s /q "!STAGE_DIR!" >nul 2>&1
        if /i not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" >nul 2>&1
        exit /b 1
    )
) else (
    copy /y "!TMP_FILE!" "!STAGE_DIR!\wincheck.exe" >nul
)

call :stage_extracted_binaries "!STAGE_DIR!" "!TARGET_DIR!"
set "_STAGE_RC=!errorlevel!"
rmdir /s /q "!STAGE_DIR!" >nul 2>&1
if /i not "!TMP_FILE!"=="!CACHED_DL!" del /f /q "!TMP_FILE!" >nul 2>&1
if not "!_STAGE_RC!"=="0" exit /b 1

call :update_aliases
exit /b 0

:: ## stage_extracted_binaries
:: Locates extracted wincheck.exe, wincmd.exe, optional CWSDPMI.EXE, and docs inside STAGE_DIR and copies them to TARGET_DIR.
:stage_extracted_binaries
set "_SEB_STAGE=%~1"
set "_SEB_TGT=%~2"
for %%T in ("!_SEB_TGT!") do set "_SEB_TGT=%%~fT"
if not exist "!_SEB_TGT!\bin" mkdir "!_SEB_TGT!\bin"
if exist "!_SEB_STAGE!" (
    pushd "!_SEB_STAGE!"
    for /r %%X in (wincheck.exe WINCHECK.EXE) do (
        if exist "%%~fX" (
            copy /y "%%~fX" "!_SEB_TGT!\bin\wincheck.exe" >nul
            if "%IS_MSDOS%"=="1" copy /y "%%~fX" "!_SEB_TGT!\bin\WINCHECK.EXE" >nul
        )
    )
    for /r %%Y in (wincmd.exe WINCMD.EXE) do (
        if exist "%%~fY" (
            copy /y "%%~fY" "!_SEB_TGT!\bin\wincmd.exe" >nul
            if "%IS_MSDOS%"=="1" copy /y "%%~fY" "!_SEB_TGT!\bin\WINCMD.EXE" >nul
        )
    )
    for /r %%D in (CWSDPMI.EXE cwsdpmi.exe) do (
        if exist "%%~fD" copy /y "%%~fD" "!_SEB_TGT!\bin\CWSDPMI.EXE" >nul
    )
    if not "!IS_MSDOS!"=="1" (
        for %%M in (README.md USAGE.md LICENSE-MIT LICENSE-APACHE) do (
            for /r %%L in (%%M) do (
                if exist "%%~fL" copy /y "%%~fL" "!_SEB_TGT!\%%M" >nul
            )
        )
    )
    popd
)
if not exist "!_SEB_TGT!\bin\wincheck.exe" (
    echo Error: wincheck.exe was not found in extracted archive 1>&2
    exit /b 1
)
if not exist "!_SEB_TGT!\bin\wincmd.exe" (
    echo Error: wincmd.exe was not found in extracted archive 1>&2
    exit /b 1
)
exit /b 0

:: ## install_from_source
:: Compiles wincmd.exe and wincheck.exe from a local checkout or upstream source archive using Cargo.
:install_from_source
call :resolve_version
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "win-cmd-rs" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\bin\wincheck.exe" (
    if exist "!TARGET_DIR!\bin\wincmd.exe" (
        if not "%FORCE_REINSTALL%"=="1" (
            echo [INFO] win-cmd-rs !EXACT_VERSION! is already installed at !TARGET_DIR!.
            call :update_aliases
            exit /b 0
        )
    )
)
where cargo >nul 2>&1
if errorlevel 1 (
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install rust latest
    for %%R in ("%LIBSCRIPT_HOME%\rust\default\bin" "%LIBSCRIPT_HOME%\rust\latest\bin" "%USERPROFILE%\.cargo\bin") do (
        if exist "%%~R" set "PATH=%%~R;!PATH!"
    )
)
set "_SRC_DIR=%WIN_CMD_RS_REPO_DIR%"
if "!_SRC_DIR!"=="" (
    if exist "%LIBSCRIPT_ROOT_DIR%\..\win-cmd-rs\Cargo.toml" (
        set "_SRC_DIR=%LIBSCRIPT_ROOT_DIR%\..\win-cmd-rs"
    )
)
set "_CLEAN_SRC=0"
if "!_SRC_DIR!"=="" (
    set "_SRC_TMP=%TEMP%\win-cmd-rs-src-!RANDOM!"
    if not exist "!_SRC_TMP!" mkdir "!_SRC_TMP!"
    set "PACKAGE_NAME=win-cmd-rs"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "https://github.com/SamuelMarks/win-cmd-rs/archive/refs/tags/v!EXACT_VERSION!.zip" "!_SRC_TMP!\src.zip" "%WIN_CMD_RS_CHECKSUM%"
    if not errorlevel 1 (
        call :extract_wcr_zip "!_SRC_TMP!\src.zip" "!_SRC_TMP!\tree"
        if errorlevel 1 exit /b 1
        for /d %%D in ("!_SRC_TMP!\tree\*") do set "_SRC_DIR=%%~fD"
    ) else (
        call :clone_wcr_source "!_SRC_TMP!\repo"
        if errorlevel 1 (
            if exist "!_SRC_TMP!" rmdir /s /q "!_SRC_TMP!" >nul 2>&1
            exit /b 1
        )
        set "_SRC_DIR=!_SRC_TMP!\repo"
    )
    set "_CLEAN_SRC=1"
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
set "CARGO_TARGET_DIR=%TEMP%\wcr-build-!RANDOM!"
cargo build --release --bins --manifest-path "!_SRC_DIR!\Cargo.toml"
set "_CB_RC=!errorlevel!"
if "!_CB_RC!"=="0" (
    copy /y "!CARGO_TARGET_DIR!\release\wincheck.exe" "!TARGET_DIR!\bin\wincheck.exe" >nul
    copy /y "!CARGO_TARGET_DIR!\release\wincmd.exe" "!TARGET_DIR!\bin\wincmd.exe" >nul
)
if exist "!CARGO_TARGET_DIR!" rmdir /s /q "!CARGO_TARGET_DIR!" >nul 2>&1
if "!_CLEAN_SRC!"=="1" if exist "!_SRC_TMP!" rmdir /s /q "!_SRC_TMP!" >nul 2>&1
if not "!_CB_RC!"=="0" exit /b !_CB_RC!
call :update_aliases
exit /b 0

:: ## clone_wcr_source
:: Clones the tagged win-cmd-rs repository shallowly via git when archive download is unavailable.
:clone_wcr_source
if "%LIBSCRIPT_OFFLINE%"=="1" exit /b 1
if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" exit /b 1
where git >nul 2>&1
if errorlevel 1 exit /b 1
echo [INFO] Source archive download unavailable; cloning tag v!EXACT_VERSION! via git...
git clone --depth 1 --branch "v!EXACT_VERSION!" "https://github.com/SamuelMarks/win-cmd-rs.git" "%~1"
exit /b !errorlevel!

:: ## resolve_version
:: Resolves latest, stable, or lts version aliases into EXACT_VERSION and strips any leading 'v'.
:resolve_version
set "_RAW_VER=%WIN_CMD_RS_VERSION%"
if /i "!_RAW_VER!"=="latest" goto :resolve_remote_tag
if /i "!_RAW_VER!"=="stable" goto :resolve_remote_tag
if /i "!_RAW_VER!"=="lts" goto :resolve_remote_tag
if /i "!_RAW_VER:~0,1!"=="v" set "_RAW_VER=!_RAW_VER:~1!"
set "EXACT_VERSION=!_RAW_VER!"
exit /b 0

:: ## resolve_remote_tag
:: Queries GitHub Releases API for the latest tag with offline cache inspection and 0.0.1 fallback.
:resolve_remote_tag
set "EXACT_VERSION="
set "_REL_API=%WIN_CMD_RS_RELEASES_URL%"
if "!_REL_API!"=="" set "_REL_API=https://api.github.com/repos/SamuelMarks/win-cmd-rs/releases/latest"
if not "%LIBSCRIPT_OFFLINE%"=="1" (
    if not "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
        for /f "delims=" %%T in ('call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_resolve_github_tag "!_REL_API!"') do (
            set "EXACT_VERSION=%%T"
        )
    )
)
if "!EXACT_VERSION!"=="" (
    if exist "%LIBSCRIPT_HOME%\win-cmd-rs" (
        for /d %%C in ("%LIBSCRIPT_HOME%\win-cmd-rs\*") do (
            set "_CN=%%~nxC"
            if /i not "!_CN!"=="default" if /i not "!_CN!"=="latest" if /i not "!_CN!"=="stable" if /i not "!_CN!"=="lts" (
                if exist "%%~fC\bin\wincheck.exe" set "EXACT_VERSION=!_CN!"
            )
        )
    )
)
if "!EXACT_VERSION!"=="" set "EXACT_VERSION=0.0.1"
if /i "!EXACT_VERSION:~0,1!"=="v" set "EXACT_VERSION=!EXACT_VERSION:~1!"
exit /b 0

:: ## resolve_url
:: Resolves the Windows or MS-DOS release archive URL and substitutes template variables.
:resolve_url
set "_WCR_ARCH=%LIBSCRIPT_TARGET_ARCH%"
if "!_WCR_ARCH!"=="" set "_WCR_ARCH=%ARCH%"
if "!_WCR_ARCH!"=="" set "_WCR_ARCH=%PROCESSOR_ARCHITECTURE%"
set "_WCR_TARGET=x86_64-pc-windows-msvc"
if /i "%IS_MSDOS%"=="1" (
    set "_WCR_TARGET=i586-pc-msdosdjgpp"
) else if /i "%LIBSCRIPT_TARGET_OS%"=="msdos" (
    set "_WCR_TARGET=i586-pc-msdosdjgpp"
) else if /i "%LIBSCRIPT_TARGET_OS:~0,7%"=="freedos" (
    set "_WCR_TARGET=i586-pc-msdosdjgpp"
) else if /i "%LIBSCRIPT_TARGET_OS:~0,5%"=="msdos" (
    set "_WCR_TARGET=i586-pc-msdosdjgpp"
) else if /i "!_WCR_ARCH!"=="ARM64" (
    set "_WCR_TARGET=aarch64-pc-windows-msvc"
) else if /i "!_WCR_ARCH!"=="aarch64" (
    set "_WCR_TARGET=aarch64-pc-windows-msvc"
) else if /i "!_WCR_ARCH!"=="AMD64" (
    set "_WCR_TARGET=x86_64-pc-windows-msvc"
) else if /i "!_WCR_ARCH!"=="x86_64" (
    set "_WCR_TARGET=x86_64-pc-windows-msvc"
) else if /i "!_WCR_ARCH!"=="x64" (
    set "_WCR_TARGET=x86_64-pc-windows-msvc"
) else (
    if "%WIN_CMD_RS_DOWNLOAD_URL%"=="" exit /b 1
)
set "URL=%WIN_CMD_RS_DOWNLOAD_URL%"
if "!URL!"=="" (
    set "URL=https://github.com/SamuelMarks/win-cmd-rs/releases/download/v!EXACT_VERSION!/win-cmd-rs-v!EXACT_VERSION!-!_WCR_TARGET!.zip"
) else (
    call set "URL=%%URL:{VERSION}=!EXACT_VERSION!%%"
    call set "URL=%%URL:{RUST_TARGET}=!_WCR_TARGET!%%"
    call set "URL=%%URL:{EXT}=zip%%"
)
exit /b 0

:: ## update_aliases
:: Updates version alias and default directory junctions and synchronizes active bin shims.
:update_aliases
set "_ALIAS_NAME=%WIN_CMD_RS_VERSION%"
if /i "!_ALIAS_NAME:~0,1!"=="v" set "_ALIAS_NAME=!_ALIAS_NAME:~1!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "win-cmd-rs" "!_ALIAS_NAME!" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "win-cmd-rs" "default" "!EXACT_VERSION!"
exit /b 0

:: ## action_other
:: Delegates generic lifecycle actions such as uninstall to setup_base.cmd.
:action_other
call "%LIBSCRIPT_ROOT_DIR%\engine\common\setup_base.cmd" :libscript_handle_generic_action "win-cmd-rs" "%ACTION%" "%WIN_CMD_RS_VERSION%" "%WIN_CMD_RS_INSTALL_METHOD%" "" "" "" "\"%LIBSCRIPT_HOME%\win-cmd-rs\%WIN_CMD_RS_VERSION%\bin\wincheck.exe\"" "%LIBSCRIPT_HOME%\win-cmd-rs\%WIN_CMD_RS_VERSION%"
exit /b !errorlevel!

:: ## extract_wcr_zip
:: Extracts a zip archive using native zero-PowerShell extractors (7za, 7z, bsdunzip, unzip, tar) before PowerShell fallback.
:extract_wcr_zip
set "_WCR_ZIP=%~1"
set "_WCR_DST=%~2"
for %%Z in (7za.exe 7z.exe 7za 7z) do (
    where %%Z >nul 2>&1
    if not errorlevel 1 (
        %%Z x "!_WCR_ZIP!" -o"!_WCR_DST!" -y >nul 2>&1
        if not errorlevel 1 exit /b 0
    )
)
for %%U in (bsdunzip.exe unzip.exe bsdunzip unzip) do (
    where %%U >nul 2>&1
    if not errorlevel 1 (
        %%U -q -o "!_WCR_ZIP!" -d "!_WCR_DST!" >nul 2>&1
        if not errorlevel 1 exit /b 0
    )
)
for %%T in (tar.exe tar) do (
    where %%T >nul 2>&1
    if not errorlevel 1 (
        %%T -xf "!_WCR_ZIP!" -C "!_WCR_DST!" >nul 2>&1
        if not errorlevel 1 exit /b 0
    )
)
where powershell.exe >nul 2>&1
if not errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!_WCR_ZIP!' -DestinationPath '!_WCR_DST!' -Force"
    exit /b !errorlevel!
)
exit /b 1
