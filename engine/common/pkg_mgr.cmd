@echo off
:: # LibScript Package Manager Module (Windows Batch)
:: ## Overview
:: This module abstracts package management and downloading operations.
:: ## Usage
:: ```batch call "!LIBSCRIPT_ROOT_DIR!\\engine\\common\\pkg_mgr.cmd" :libscript_download <url> <dest> ```

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"


if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

:: Source logging
set "LOG_CMD=!LIBSCRIPT_ROOT_DIR!\engine\common\log.cmd"
set "MAPPER_CMD=!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mapper.cmd"

if not "%~1"=="" (
    set "_pm_sub=%~1"
    if "!_pm_sub:~0,1!"==":" (
        shift
        goto !_pm_sub!
    )
)
goto :eof

:: ## libscript_resolve_install_method
:: Resolves the installation method for a component on Windows, supporting pkg_mgr:<pm>, from-source, libscript_native, and system.
:libscript_resolve_install_method
set "_comp_up=%~1"
set "_req=!%_comp_up%_INSTALL_METHOD!"
if "!_req!"=="" set "_req=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
if "!_req!"=="" set "_req=%LIBSCRIPT_GLOBAL_INSTALL_METHOD%"
if "!_req:~0,8!"=="pkg_mgr:" (
    set "LIBSCRIPT_PKG_MGR=!_req:~8!"
    set "_req=system"
)
if /i not "!_req!"=="libscript_native" if /i not "!_req!"=="system" if /i not "!_req!"=="from-source" (
    set "_req=system"
)
endlocal & set "LIBSCRIPT_PKG_MGR=%LIBSCRIPT_PKG_MGR%" & set "RESOLVED_INSTALL_METHOD=%_req%"
exit /b 0

:: ## detect_pkg_mgr
:: Detects or honors an explicitly requested Windows/ReactOS package manager (rapps, winget, choco, scoop, vcpkg, conan).
:detect_pkg_mgr
set "_comp_up=%~1"
set "_req_pm="
if not "!_comp_up!"=="" set "_req_pm=!%_comp_up%_PKG_MGR!"
if "!_req_pm!"=="" if defined LIBSCRIPT_PKG_MGR set "_req_pm=%LIBSCRIPT_PKG_MGR%"
if /i "!_req_pm!"=="chocolatey" set "_req_pm=choco"
if /i "!_req_pm!"=="libscript_native" set "_req_pm=libscript"
if not "!_req_pm!"=="" (
    set "PKG_MGR=!_req_pm!"
    exit /b 0
)
if "%IS_MSDOS%"=="1" (
    set "PKG_MGR=libscript"
    exit /b 0
)
if /i "%TARGET_OS%"=="msdos" (
    set "PKG_MGR=libscript"
    exit /b 0
)
if "%IS_REACTOS%"=="1" (
    set "PKG_MGR=rapps"
    exit /b 0
)
where rapps.exe >nul 2>&1
if "!errorlevel!" equ "0" (
    set "PKG_MGR=rapps"
    exit /b 0
)
where winget >nul 2>&1
if "!errorlevel!" equ "0" (
    set "PKG_MGR=winget"
    exit /b 0
)
where choco >nul 2>&1
if "!errorlevel!" equ "0" (
    set "PKG_MGR=choco"
    exit /b 0
)
where scoop >nul 2>&1
if "!errorlevel!" equ "0" (
    set "PKG_MGR=scoop"
    exit /b 0
)
set "PKG_MGR=libscript"
exit /b 0

:: ## libscript_depends_via
:: Installs one or more packages explicitly using a specified Windows package manager name.
:libscript_depends_via
set "_via_pm=%~1"
shift
set "_saved_pm=%LIBSCRIPT_PKG_MGR%"
set "LIBSCRIPT_PKG_MGR=%_via_pm%"
call :detect_pkg_mgr
call :libscript_depends %1 %2 %3 %4 %5 %6 %7 %8 %9
set "_rc=!errorlevel!"
set "LIBSCRIPT_PKG_MGR=%_saved_pm%"
exit /b !_rc!

:: ## depends
:: Shorthand alias for libscript_depends resolving system or component-level dependencies.
:depends
goto :libscript_depends

:: ## libscript_depends
:: Resolves and installs system or component-level dependencies on Windows and MS-DOS.
:libscript_depends
if "%LIBSCRIPT_SKIP_SYSTEM_DEPS%"=="1" exit /b 0
if defined LIBSCRIPT_PKG_MGR call :detect_pkg_mgr
if not defined PKG_MGR call :detect_pkg_mgr
goto :depends_loop

:: ## is_installed
:: Checks whether a mapped package is already installed under the active Windows package manager.
:is_installed
set "_chk_pkg=%~1"
if /i "!PKG_MGR!"=="libscript" (
    set "_ls_chk_home=%LIBSCRIPT_HOME%"
    if "!_ls_chk_home!"=="" set "_ls_chk_home=%USERPROFILE%\.libscript"
    if exist "!_ls_chk_home!\!_chk_pkg!\default\bin\!_chk_pkg!.exe" exit /b 0
    if exist "!_ls_chk_home!\!_chk_pkg!\latest\bin\!_chk_pkg!.exe" exit /b 0
    exit /b 1
)
if /i "!PKG_MGR!"=="winget" (
    winget list --exact --id "!_chk_pkg!" >nul 2>&1
    exit /b !errorlevel!
)
if /i "!PKG_MGR!"=="choco" (
    choco list --local-only "!_chk_pkg!" 2>nul | findstr /I /B /C:"!_chk_pkg! " >nul 2>&1
    exit /b !errorlevel!
)
if /i "!PKG_MGR!"=="scoop" (
    scoop list "!_chk_pkg!" 2>nul | findstr /I /C:"!_chk_pkg!" >nul 2>&1
    exit /b !errorlevel!
)
if /i "!PKG_MGR!"=="vcpkg" (
    vcpkg list 2>nul | findstr /I /B /C:"!_chk_pkg!:" >nul 2>&1
    exit /b !errorlevel!
)
if /i "!PKG_MGR!"=="rapps" (
    set "_ros_sd=%SystemDrive%"
    if "!_ros_sd!"=="" set "_ros_sd=C:"
    if exist "!_ros_sd!\libscript\stamps\rapps_!_chk_pkg!.stamp" exit /b 0
    where "!_chk_pkg!" >nul 2>&1
    exit /b !errorlevel!
)
exit /b 1

:: ## depends_loop
:: Iterates over requested package arguments, mapping and installing each dependency.
:depends_loop
if "%~1"=="" exit /b 0
set "_generic_pkg=%~1"
if "%LIBSCRIPT_IMAGE_BUILD%"=="1" if defined LIBSCRIPT_TARGET_SYSROOT (
    echo [INFO] [SYSROOT] Recording package dependency '!_generic_pkg!' for offline sysroot !LIBSCRIPT_TARGET_SYSROOT!
    if not exist "!LIBSCRIPT_TARGET_SYSROOT!\var\lib\libscript" mkdir "!LIBSCRIPT_TARGET_SYSROOT!\var\lib\libscript"
    echo.!_generic_pkg!>> "!LIBSCRIPT_TARGET_SYSROOT!\var\lib\libscript\sysroot_deps.list"
    shift
    goto :depends_loop
)
call :is_native_win_dos_port "!_generic_pkg!"
set "_is_native_port=!errorlevel!"
set "_route_comp_pm=0"
if /i "!PKG_MGR!"=="libscript" (
    if "%LIBSCRIPT_FORCE_SYSTEM_PKG_MGR%"=="1" exit /b 1
    set "_route_comp_pm=1"
)
if "!_is_native_port!"=="0" (
    if not "%LIBSCRIPT_FORCE_SYSTEM_PKG_MGR%"=="1" (
        if not defined LIBSCRIPT_PKG_MGR set "_route_comp_pm=1"
    )
)
if "!_route_comp_pm!"=="1" (
    call :libscript_install_component_dep "!_generic_pkg!"
    if "!errorlevel!" neq "0" exit /b 1
    shift
    goto :depends_loop
)
call "%MAPPER_CMD%" :map_package "!_generic_pkg!"
if "!MAPPED_PKG!"=="" set "MAPPED_PKG=!_generic_pkg!"
if "%LIBSCRIPT_DRY_RUN_PKG_MGR%"=="1" (
    echo [INFO] [DRY-RUN] ^(!PKG_MGR!^) install !MAPPED_PKG!
    shift
    goto :depends_loop
)
call :is_installed "!MAPPED_PKG!"
if "!errorlevel!" equ "0" (
    call "!LOG_CMD!" :log_info "[REUSE] Package '!MAPPED_PKG!' is already installed via !PKG_MGR!."
    shift
    goto :depends_loop
)
set "_inst_rc=1"
if /i "!PKG_MGR!"=="winget" (
    winget install --exact --id "!MAPPED_PKG!" --accept-package-agreements --accept-source-agreements --silent
    set "_inst_rc=!errorlevel!"
    if "!_inst_rc!" neq "0" (
        where choco >nul 2>&1
        if "!errorlevel!" equ "0" (
            set "PKG_MGR=choco"
            call "%MAPPER_CMD%" :map_package "!_generic_pkg!"
            if "!MAPPED_PKG!"=="" set "MAPPED_PKG=!_generic_pkg!"
            choco install -y "!MAPPED_PKG!"
            set "_inst_rc=!errorlevel!"
            set "PKG_MGR=winget"
        )
    )
    if "!_inst_rc!" neq "0" (
        where scoop >nul 2>&1
        if "!errorlevel!" equ "0" (
            set "PKG_MGR=scoop"
            call "%MAPPER_CMD%" :map_package "!_generic_pkg!"
            if "!MAPPED_PKG!"=="" set "MAPPED_PKG=!_generic_pkg!"
            scoop install "!MAPPED_PKG!"
            set "_inst_rc=!errorlevel!"
            set "PKG_MGR=winget"
        )
    )
    if "!_inst_rc!" neq "0" (
        if not "%LIBSCRIPT_FORCE_SYSTEM_PKG_MGR%"=="1" (
            call :libscript_install_component_dep "!_generic_pkg!"
            set "_inst_rc=!errorlevel!"
        )
    )
) else if /i "!PKG_MGR!"=="choco" (
    choco install -y "!MAPPED_PKG!"
    set "_inst_rc=!errorlevel!"
) else if /i "!PKG_MGR!"=="scoop" (
    scoop install "!MAPPED_PKG!"
    set "_inst_rc=!errorlevel!"
) else if /i "!PKG_MGR!"=="vcpkg" (
    vcpkg install "!MAPPED_PKG!"
    set "_inst_rc=!errorlevel!"
) else if /i "!PKG_MGR!"=="conan" (
    conan install --requires="!MAPPED_PKG!" --build=missing
    set "_inst_rc=!errorlevel!"
) else if /i "!PKG_MGR!"=="rapps" (
    call :install_via_rapps "!MAPPED_PKG!"
    set "_inst_rc=!errorlevel!"
) else (
    if not "%LIBSCRIPT_FORCE_SYSTEM_PKG_MGR%"=="1" (
        call :libscript_install_component_dep "!_generic_pkg!"
        set "_inst_rc=!errorlevel!"
    ) else (
        set "_inst_rc=1"
    )
)
if "!_inst_rc!" neq "0" exit /b !_inst_rc!
shift
goto :depends_loop

:: ## is_native_win_dos_port
:: Returns 0 if a requested dependency is backed by a dedicated Windows/MS-DOS native component-level package manager.
:is_native_win_dos_port
set "_native_pkg=%~1"
for %%P in (jq jq-windows gawk gawk-windows awk busybox busybox-windows toybox toybox-windows dash dash-windows sh freebsd-usr-bin freebsd-usr-bin-windows sed grep cut tr sort uniq wc head tail xargs find cmp diff patch bmake bsdtar bsdunzip curl 7zip 7za 7z sha256sum file win-cmd-rs wincmd wincheck) do (
    if /i "!_native_pkg!"=="%%P" exit /b 0
)
exit /b 1

:: ## libscript_install_component_dep
:: Installs a dependency via its LibScript component-level package manager on Windows or MS-DOS and updates PATH.
:libscript_install_component_dep
set "_lic_req=%~1"
set "_lic_saved_pm=!PKG_MGR!"
set "PKG_MGR=libscript"
call "%MAPPER_CMD%" :map_package "!_lic_req!"
set "_lic_comp=!MAPPED_PKG!"
if "!_lic_comp!"=="" set "_lic_comp=!_lic_req!"
set "PKG_MGR=!_lic_saved_pm!"

set "_lic_applet="
if /i "!_lic_comp!"=="freebsd-usr-bin" (
    if /i not "!_lic_req!"=="freebsd-usr-bin" (
        if /i not "!_lic_req!"=="freebsd-usr-bin-windows" (
            set "_lic_applet=!_lic_req!"
        )
    )
)

set "_lic_home=%LIBSCRIPT_HOME%"
if "!_lic_home!"=="" set "_lic_home=%USERPROFILE%\.libscript"
set "_lic_bin_chk=!_lic_req!"
if /i "!_lic_req!"=="jq-windows" set "_lic_bin_chk=jq"
if /i "!_lic_req!"=="gawk-windows" set "_lic_bin_chk=gawk"
if /i "!_lic_req!"=="busybox-windows" set "_lic_bin_chk=busybox"
if /i "!_lic_req!"=="toybox-windows" set "_lic_bin_chk=toybox"
if /i "!_lic_req!"=="dash-windows" set "_lic_bin_chk=dash"
if /i "!_lic_req!"=="win-cmd-rs" set "_lic_bin_chk=wincheck"
if /i "!_lic_req!"=="7zip" set "_lic_bin_chk=7za"
if /i "!_lic_req!"=="7z" set "_lic_bin_chk=7za"
if /i "!_lic_req!"=="sha256sum" set "_lic_bin_chk=toybox"
if /i "!_lic_req!"=="file" set "_lic_bin_chk=toybox"

if not "%FORCE_REINSTALL%"=="1" (
    for %%V in (default latest) do (
        if exist "!_lic_home!\!_lic_comp!\%%V\bin\!_lic_bin_chk!.exe" (
            echo ";!PATH!;" | findstr /I /C:";!_lic_home!\!_lic_comp!\%%V\bin;" >nul 2>&1
            if errorlevel 1 set "PATH=!_lic_home!\!_lic_comp!\%%V\bin;!PATH!"
            exit /b 0
        )
    )
)

set "_lic_setup="
for /d %%C in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
    if /i not "%%~nxC"=="_common" (
        if exist "%%C\!_lic_comp!\setup.cmd" set "_lic_setup=%%C\!_lic_comp!\setup.cmd"
    )
)
if "!_lic_setup!"=="" (
    call "!LOG_CMD!" :log_warn "No component-level package manager found for '!_lic_comp!' ^(requested: '!_lic_req!'^)"
    exit /b 1
)

if "%LIBSCRIPT_DRY_RUN_PKG_MGR%"=="1" (
    echo [INFO] [DRY-RUN] ^(libscript:!_lic_comp!^) install !_lic_req! ^(target=!TARGET_OS!^)
    exit /b 0
)

if defined _LS_ACTIVE_COMP_DEPS (
    echo "!_LS_ACTIVE_COMP_DEPS!" | findstr /I /C:":!_lic_comp!:" >nul 2>&1
    if not errorlevel 1 exit /b 1
)

set "_lic_prev_active=%_LS_ACTIVE_COMP_DEPS%"
set "_LS_ACTIVE_COMP_DEPS=%_LS_ACTIVE_COMP_DEPS%:!_lic_comp!:"
set "_lic_saved_def_im=%LIBSCRIPT_DEFAULT_INSTALL_METHOD%"
set "_lic_saved_app=%FREEBSD_USR_BIN_APPLET%"
set "LIBSCRIPT_DEFAULT_INSTALL_METHOD=libscript_native"
set "JQ_INSTALL_METHOD=libscript_native"
set "GAWK_INSTALL_METHOD=libscript_native"
set "BUSYBOX_INSTALL_METHOD=libscript_native"
set "TOYBOX_INSTALL_METHOD=libscript_native"
set "DASH_INSTALL_METHOD=libscript_native"
set "CURL_INSTALL_METHOD=libscript_native"
set "7ZIP_INSTALL_METHOD=libscript_native"
set "FREEBSD_USR_BIN_INSTALL_METHOD=libscript_native"
set "WIN_CMD_RS_INSTALL_METHOD=libscript_native"
if not "!_lic_applet!"=="" set "FREEBSD_USR_BIN_APPLET=!_lic_applet!"
set "ACTION=install"
set "STACK="
call "!_lic_setup!"
set "_lic_rc=!errorlevel!"
set "_LS_ACTIVE_COMP_DEPS=!_lic_prev_active!"
set "LIBSCRIPT_DEFAULT_INSTALL_METHOD=!_lic_saved_def_im!"
set "FREEBSD_USR_BIN_APPLET=!_lic_saved_app!"
if "!_lic_rc!" neq "0" exit /b !_lic_rc!

for %%V in (default latest) do (
    if exist "!_lic_home!\!_lic_comp!\%%V\bin" (
        echo ";!PATH!;" | findstr /I /C:";!_lic_home!\!_lic_comp!\%%V\bin;" >nul 2>&1
        if errorlevel 1 set "PATH=!_lic_home!\!_lic_comp!\%%V\bin;!PATH!"
        exit /b 0
    )
)
exit /b 0

:: Unified Caching Downloader (Windows)
:: ## libscript_download
:: Downloads a remote artifact with offline cache resolution and SHA-256 checksum verification.
:libscript_download
set "url=%~1"
set "dest=%~2"
set "provided_checksum=%~3"
set "auth_header=%~4"
if "!auth_header!"=="" if defined LIBSCRIPT_DOWNLOAD_AUTH_HEADER set "auth_header=%LIBSCRIPT_DOWNLOAD_AUTH_HEADER%"

if "!dest!"=="" for %%F in ("!url!") do set "dest=%%~nxF"

:: 1. Checksum Resolution
set "checksum_db=%LIBSCRIPT_CHECKSUM_DB%"
if "!checksum_db!"=="" set "checksum_db=!LIBSCRIPT_ROOT_DIR!\_lib\checksums.txt"
set "expected_checksum=!provided_checksum!"
if "!expected_checksum!"=="" (
        if exist "!checksum_db!" (
                for /f "tokens=2" %%i in ('findstr /L /C:"!url!" "!checksum_db!" 2^>nul') do (
                        set "expected_checksum=%%i"
                        goto :found_checksum
                )
        )
)
:: wincheck disable=CMD3005
:: ## found_checksum
:: Verifies the downloaded file SHA-256 digest against the expected checksum.
:found_checksum

:: 2. Aria2 Export Mode
if defined LIBSCRIPT_ARIA2_EXPORT_FILE (
        set "skip_export="
        if exist "!LIBSCRIPT_ARIA2_EXPORT_FILE!" (
                findstr /L /X /C:"!url!" "!LIBSCRIPT_ARIA2_EXPORT_FILE!" >nul 2>&1
                if not errorlevel 1 set "skip_export=1"
        )
        if not defined skip_export (
                echo.!url!>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
                for %%F in ("!dest!") do echo   out=%%~nxF>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
                if not "!expected_checksum!"=="" echo   checksum=sha-256=!expected_checksum!>> "!LIBSCRIPT_ARIA2_EXPORT_FILE!"
        )
        exit /b 0
)

:: 3. Cache Path Resolution
set "cache_dir=%LIBSCRIPT_CACHE_DIR%"
if "!cache_dir!"=="" set "cache_dir=!LIBSCRIPT_ROOT_DIR!\cache\downloads"

if "%DOWNLOAD_DIR%"=="" (
        set "dl_dir=!cache_dir!"
        if defined PACKAGE_NAME (
                set "dl_dir=!dl_dir!\!PACKAGE_NAME!"
        ) else (
                set "dl_dir=!dl_dir!\unknown"
        )
) else (
        set "dl_dir=%DOWNLOAD_DIR%"
)

if not exist "!dl_dir!" mkdir "!dl_dir!"
for %%F in ("!url!") do set "filename=%%~nxF"
set "cache_file=!dl_dir!\!filename!"

:: 4. Cache Check & Download
set "download_needed=1"
if exist "!cache_file!" (
        for %%A in ("!cache_file!") do set "_cf_size=%%~zA"
        if not "!_cf_size!"=="0" (
                call "!LOG_CMD!" :log_info "[CACHED] !url!"
                set "download_needed=0"
        ) else (
                del /f /q "!cache_file!" >nul 2>&1
        )
)
if "!download_needed!"=="1" (
        if exist "!cache_dir!\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\!filename!)"
                copy /y "!cache_dir!\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\runtimes\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\runtimes\!filename!)"
                copy /y "!cache_dir!\runtimes\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\databases\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\databases\!filename!)"
                copy /y "!cache_dir!\databases\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\wheels\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\wheels\!filename!)"
                copy /y "!cache_dir!\wheels\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\npm\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\npm\!filename!)"
                copy /y "!cache_dir!\npm\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!cache_dir!\codebase\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !cache_dir!\codebase\!filename!)"
                copy /y "!cache_dir!\codebase\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        ) else if exist "!LIBSCRIPT_ROOT_DIR!\cache\!filename!" (
                call "!LOG_CMD!" :log_info "[CACHED] !url! (found in !LIBSCRIPT_ROOT_DIR!\cache\!filename!)"
                copy /y "!LIBSCRIPT_ROOT_DIR!\cache\!filename!" "!cache_file!" >nul 2>&1
                set "download_needed=0"
        )
        if "!download_needed!"=="0" (
                for %%A in ("!cache_file!") do if "%%~zA"=="0" (
                        del /f /q "!cache_file!" >nul 2>&1
                        set "download_needed=1"
                )
        )
)

if "!download_needed!"=="1" (
        if "%LIBSCRIPT_OFFLINE%"=="1" (
                call "!LOG_CMD!" :log_error "Error: [OFFLINE] Cannot download '!url!'. Artifact not found in local cache at '!cache_file!'."
                echo Error: [OFFLINE] Cannot download '!url!'. Artifact not found in local cache at '!cache_file!'. >&2
                if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
                        echo Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests. >&2
                        exit /b 1
                )
                exit /b 1
        )
        if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" (
                call "!LOG_CMD!" :log_error "Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests."
                echo Fatal: LIBSCRIPT_FORCE_OFFLINE=1 strictly prohibits network requests. >&2
                exit /b 1
        )
        if "!IS_MSDOS!"=="1" if exist "!LIBSCRIPT_ROOT_DIR!\engine\common\dos32\wattcp_cfg.cmd" (
                call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos32\wattcp_cfg.cmd" >nul 2>&1
        )

        call "!LOG_CMD!" :log_info "[DOWNLOADING] !url!"
    
        set "download_success=0"
    
        REM Strategy A: curl (PATH, LIBSCRIPT_HOME, ReactOS bootstrap, or lazy _lib/utilities/curl bootstrap)
        call :resolve_pkg_mgr_curl
        if not "!_curl_bin!"=="" (
                call :curl_download_with_retry
        )

        REM Strategy A1b: Authenticated GitHub Releases / Archive bypass (rescues shared-NAT HTTP 403/429)
        if "!download_success!" equ "0" (
                if /i "!url:~0,19!"=="https://github.com/" (
                        call :download_github_authenticated
                )
        )

        REM Strategy A2: wget or busybox wget
        if "!download_success!" equ "0" (
                where wget >nul 2>&1
                if "!errorlevel!" equ "0" (
                        wget -q -O "!cache_file!" "!url!"
                        if "!errorlevel!" equ "0" set "download_success=1"
                )
        )
        if "!download_success!" equ "0" (
                set "_bb_dl=%LIBSCRIPT_HOME%"
                if "!_bb_dl!"=="" set "_bb_dl=%USERPROFILE%\.libscript"
                if exist "!_bb_dl!\busybox\default\bin\busybox.exe" (
                        "!_bb_dl!\busybox\default\bin\busybox.exe" wget -q -O "!cache_file!" "!url!"
                        if "!errorlevel!" equ "0" set "download_success=1"
                )
        )

        REM Strategy B: certutil (native Win32, pre-1803/ReactOS safe without PowerShell/.NET)
        if "!download_success!" equ "0" (
                where certutil >nul 2>&1
                if "!errorlevel!" equ "0" (
                        certutil -urlcache -split -f "!url!" "!cache_file!" >nul
                        if "!errorlevel!" equ "0" set "download_success=1"
                )
        )

        REM Strategy C: PowerShell last-resort fallback
        if "!download_success!" equ "0" (
                where powershell >nul 2>&1
                if "!errorlevel!" equ "0" (
                        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!url!' -OutFile '!cache_file!'"
                        if "!errorlevel!" equ "0" set "download_success=1"
                )
        )

        if "!download_success!" equ "0" (
                call "!LOG_CMD!" :log_error "Download failed for !url!"
                exit /b 1
        )
    
        for %%A in ("!cache_file!") do set size=%%~zA
        if "!size!"=="0" (
                call "!LOG_CMD!" :log_error "Downloaded file is empty"
                if exist "!cache_file!" del /f /q "!cache_file!" >nul 2>&1
                exit /b 1
        )
)

:: 5. Checksum Validation
if not "!expected_checksum!"=="" (
        if /i not "!expected_checksum!"=="SKIP" (
                set "clean_expected=!expected_checksum:sha-256=!"
                set "actual_checksum="
                call :compute_sha256 "!cache_file!"
                if /i not "!actual_checksum!"=="!clean_expected!" (
                        call "!LOG_CMD!" :log_error "Checksum mismatch for !cache_file!. Expected: !clean_expected!, Got: !actual_checksum!"
                        if exist "!cache_file!" del /f /q "!cache_file!" >nul 2>&1
                        exit /b 1
                )
        )
) else (
        if not "%LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB%"=="1" (
                if not "%LIBSCRIPT_DISABLE_CHECKSUM_TXT_UPDATE%"=="1" (
                        set "actual_checksum="
                        call :compute_sha256 "!cache_file!"
                        if not "!actual_checksum!"=="" (
                                findstr /i /c:"!url! !actual_checksum!" "!checksum_db!" >nul 2>&1 || echo !url! !actual_checksum!>> "!checksum_db!"
                        )
                )
        )
)

:: 6. Final Placement
if not "!dest!"=="" (
        if /i not "!dest!"=="!cache_file!" (
                for %%D in ("!dest!") do if not exist "%%~dpD" mkdir "%%~dpD"
                copy /y "!cache_file!" "!dest!" >nul 2>&1
                if not exist "!dest!" (
                        where powershell >nul 2>&1
                        if "!errorlevel!" equ "0" (
                                powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Copy-Item -LiteralPath '!cache_file!' -Destination '!dest!' -Force" >nul 2>&1
                        )
                )
                if not exist "!dest!" (
                        call "!LOG_CMD!" :log_error "Failed to place downloaded artifact at !dest!"
                        exit /b 1
                )
                for %%A in ("!dest!") do if "%%~zA"=="0" (
                        call "!LOG_CMD!" :log_error "Placed artifact at !dest! is empty"
                        del /f /q "!dest!" >nul 2>&1
                        exit /b 1
                )
        )
)
exit /b 0

:: ## resolve_pkg_mgr_curl
:: Resolves curl.exe from PATH, LIBSCRIPT_HOME, ReactOS bootstrap bin, or _lib/utilities/curl component bootstrap.
:resolve_pkg_mgr_curl
set "_curl_bin="
where curl >nul 2>&1
if "!errorlevel!" equ "0" (
    set "_curl_bin=curl"
    exit /b 0
)
set "_rpc_home=%LIBSCRIPT_HOME%"
if "!_rpc_home!"=="" set "_rpc_home=%USERPROFILE%\.libscript"
if exist "!_rpc_home!\bin\curl.exe" (
    set "_curl_bin=!_rpc_home!\bin\curl.exe"
    exit /b 0
)
if exist "!_rpc_home!\curl\default\bin\curl.exe" (
    set "_curl_bin=!_rpc_home!\curl\default\bin\curl.exe"
    exit /b 0
)
set "_ros_sd=%SystemDrive%"
if "!_ros_sd!"=="" set "_ros_sd=C:"
if exist "!_ros_sd!\libscript\bootstrap\bin\curl.exe" (
    set "_curl_bin=!_ros_sd!\libscript\bootstrap\bin\curl.exe"
    exit /b 0
)
if not "%_LS_BOOTSTRAP_CURL%"=="1" (
    if /i not "%PACKAGE_NAME%"=="curl" (
        set "_LS_BOOTSTRAP_CURL=1"
        call :libscript_install_component_dep curl >nul 2>&1
        set "_LS_BOOTSTRAP_CURL="
        if exist "!_rpc_home!\curl\default\bin\curl.exe" (
            set "_curl_bin=!_rpc_home!\curl\default\bin\curl.exe"
            exit /b 0
        )
    )
)
exit /b 1

:: ## compute_sha256
:: Computes the lowercase SHA-256 hex digest of a file into actual_checksum using sha256sum, toybox, certutil, or PowerShell.
:compute_sha256
set "_cs_file=%~1"
set "actual_checksum="
if not exist "!_cs_file!" exit /b 1
set "_sha_bin="
where sha256sum >nul 2>&1
if "!errorlevel!" equ "0" set "_sha_bin=sha256sum"
set "_cs_home=%LIBSCRIPT_HOME%"
if "!_cs_home!"=="" set "_cs_home=%USERPROFILE%\.libscript"
if "!_sha_bin!"=="" if exist "!_cs_home!\bin\sha256sum.exe" set "_sha_bin=!_cs_home!\bin\sha256sum.exe"
if "!_sha_bin!"=="" if exist "!_cs_home!\toybox\default\bin\sha256sum.exe" set "_sha_bin=!_cs_home!\toybox\default\bin\sha256sum.exe"
if "!_sha_bin!"=="" (
    set "_ros_sd=%SystemDrive%"
    if "!_ros_sd!"=="" set "_ros_sd=C:"
    if exist "!_ros_sd!\libscript\bootstrap\bin\sha256sum.exe" set "_sha_bin=!_ros_sd!\libscript\bootstrap\bin\sha256sum.exe"
)
if not "!_sha_bin!"=="" (
    for /f "tokens=1" %%a in ('"!_sha_bin!" "!_cs_file!" 2^>nul') do if not defined actual_checksum set "actual_checksum=%%a"
)
if "!actual_checksum!"=="" if exist "!_cs_home!\toybox\default\bin\toybox.exe" (
    for /f "tokens=1" %%a in ('"!_cs_home!\toybox\default\bin\toybox.exe" sha256sum "!_cs_file!" 2^>nul') do if not defined actual_checksum set "actual_checksum=%%a"
)
if "!actual_checksum!"=="" (
    where certutil >nul 2>&1
    if "!errorlevel!" equ "0" (
        for /f "skip=1 tokens=1" %%a in ('certutil -hashfile "!_cs_file!" SHA256 2^>nul') do if not defined actual_checksum set "actual_checksum=%%a"
    )
)
if "!actual_checksum!"=="" (
    if not "%_LS_BOOTSTRAP_TOYBOX%"=="1" if /i not "%PACKAGE_NAME%"=="toybox" (
        set "_LS_BOOTSTRAP_TOYBOX=1"
        call :libscript_install_component_dep toybox >nul 2>&1
        set "_LS_BOOTSTRAP_TOYBOX="
        if exist "!_cs_home!\toybox\default\bin\toybox.exe" (
            for /f "tokens=1" %%a in ('"!_cs_home!\toybox\default\bin\toybox.exe" sha256sum "!_cs_file!" 2^>nul') do if not defined actual_checksum set "actual_checksum=%%a"
        )
    )
)
if "!actual_checksum!"=="" (
    where powershell >nul 2>&1
    if "!errorlevel!" equ "0" (
        for /f "usebackq tokens=*" %%a in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[System.IO.File]::OpenRead('!_cs_file!');$h=[System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($s)).Replace('-','').ToLower();$s.Close();$h" 2^>nul`) do set "actual_checksum=%%a"
    )
)
exit /b 0

:: ## install_via_rapps
:: Installs a package on ReactOS using pre-fetched offline cache installers or rapps.exe /install.
:install_via_rapps
set "_rp_id=%~1"
if "!_rp_id!"=="" exit /b 1
set "_ros_sd=%SystemDrive%"
if "!_ros_sd!"=="" set "_ros_sd=C:"
set "_rp_sub=rapps"
set "_rp_cache=!_ros_sd!\libscript\cache\!_rp_sub!"
set "_rp_stamps=!_ros_sd!\libscript\stamps"
if not exist "!_rp_stamps!" mkdir "!_rp_stamps!"
if exist "!_rp_cache!\!_rp_id!.msi" (
    msiexec.exe /i "!_rp_cache!\!_rp_id!.msi" /qn AGREE_ALL_LICENSES=1
    if "!errorlevel!" equ "0" (
        echo installed> "!_rp_stamps!\rapps_!_rp_id!.stamp"
        exit /b 0
    )
)
if exist "!_rp_cache!\!_rp_id!.exe" (
    set "_rp_flags=/S"
    if exist "!_rp_cache!\!_rp_id!.flags" (
        set /p _rp_flags=<"!_rp_cache!\!_rp_id!.flags"
    )
    "!_rp_cache!\!_rp_id!.exe" !_rp_flags!
    if "!errorlevel!" equ "0" (
        echo installed> "!_rp_stamps!\rapps_!_rp_id!.stamp"
        exit /b 0
    )
)
where rapps.exe >nul 2>&1
if "!errorlevel!" equ "0" (
    if not "%LIBSCRIPT_OFFLINE%"=="1" (
        rapps.exe /install "!_rp_id!"
        if "!errorlevel!" equ "0" (
            echo installed> "!_rp_stamps!\rapps_!_rp_id!.stamp"
            exit /b 0
        )
    )
)
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\!_rp_sub!\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\!_rp_sub!\cli.cmd" install "!_rp_id!"
    exit /b !errorlevel!
)
exit /b 1

:: ## libscript_extract_archive
:: Extracts .zip, .7z, .tar.gz, .tgz, or .tar.xz archives using 7za/7z (_lib/utilities/7zip), tar, unzip, or PowerShell fallback.
:libscript_extract_archive
set "_lea_arc=%~1"
set "_lea_dest=%~2"
if "!_lea_arc!"=="" exit /b 1
if "!_lea_dest!"=="" exit /b 1
if not exist "!_lea_dest!" mkdir "!_lea_dest!"
set "_lea_home=%LIBSCRIPT_HOME%"
if "!_lea_home!"=="" set "_lea_home=%USERPROFILE%\.libscript"
set "_7z_bin="
where 7za >nul 2>&1 && set "_7z_bin=7za"
if "!_7z_bin!"=="" where 7z >nul 2>&1 && set "_7z_bin=7z"
if "!_7z_bin!"=="" if exist "!_lea_home!\bin\7za.exe" set "_7z_bin=!_lea_home!\bin\7za.exe"
if "!_7z_bin!"=="" if exist "!_lea_home!\7zip\default\bin\7za.exe" set "_7z_bin=!_lea_home!\7zip\default\bin\7za.exe"
if "!_7z_bin!"=="" if exist "!_lea_home!\7zip\default\bin\7z.exe" set "_7z_bin=!_lea_home!\7zip\default\bin\7z.exe"
if "!_7z_bin!"=="" (
    set "_ros_sd=%SystemDrive%"
    if "!_ros_sd!"=="" set "_ros_sd=C:"
    if exist "!_ros_sd!\libscript\bootstrap\bin\7za.exe" set "_7z_bin=!_ros_sd!\libscript\bootstrap\bin\7za.exe"
)
if not "!_7z_bin!"=="" (
    "!_7z_bin!" x -y -o"!_lea_dest!" "!_lea_arc!" >nul
    if "!errorlevel!" equ "0" exit /b 0
)
where tar >nul 2>&1
if "!errorlevel!" equ "0" (
    tar -xf "!_lea_arc!" -C "!_lea_dest!" 2>nul
    if "!errorlevel!" equ "0" exit /b 0
)
where unzip >nul 2>&1
if "!errorlevel!" equ "0" (
    unzip -oq "!_lea_arc!" -d "!_lea_dest!" 2>nul
    if "!errorlevel!" equ "0" exit /b 0
)
if exist "!_lea_home!\freebsd-usr-bin\default\bin\bsdtar.exe" (
    "!_lea_home!\freebsd-usr-bin\default\bin\bsdtar.exe" -xf "!_lea_arc!" -C "!_lea_dest!" 2>nul
    if "!errorlevel!" equ "0" exit /b 0
)
if exist "!_lea_home!\freebsd-usr-bin\default\bin\bsdunzip.exe" (
    "!_lea_home!\freebsd-usr-bin\default\bin\bsdunzip.exe" -oq "!_lea_arc!" -d "!_lea_dest!" 2>nul
    if "!errorlevel!" equ "0" exit /b 0
)
if not "%_LS_BOOTSTRAP_7ZIP%"=="1" if /i not "%PACKAGE_NAME%"=="7zip" (
    set "_LS_BOOTSTRAP_7ZIP=1"
    call :libscript_install_component_dep 7zip >nul 2>&1
    set "_LS_BOOTSTRAP_7ZIP="
    if exist "!_lea_home!\7zip\default\bin\7za.exe" (
        "!_lea_home!\7zip\default\bin\7za.exe" x -y -o"!_lea_dest!" "!_lea_arc!" >nul
        if "!errorlevel!" equ "0" exit /b 0
    )
)
where powershell >nul 2>&1
if "!errorlevel!" equ "0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '!_lea_arc!' -DestinationPath '!_lea_dest!' -Force" >nul 2>&1
    exit /b !errorlevel!
)
call "!LOG_CMD!" :log_error "No archive extractor (7za, tar, unzip, or powershell) found to unpack !_lea_arc!"
exit /b 1

:: ## libscript_fetch
:: Delegates artifact retrieval to libscript_download.
:libscript_fetch
call :libscript_download %*
exit /b %errorlevel%

:: ## resolve_gh_token
:: Resolves GITHUB_TOKEN or GH_TOKEN into _pm_gh_tok when defined.
:resolve_gh_token
set "_pm_gh_tok=%GITHUB_TOKEN%"
if "!_pm_gh_tok!"=="" set "_pm_gh_tok=%GH_TOKEN%"
exit /b 0

:: ## curl_download_with_retry
:: Executes curl with -fL HTTP failure gating and bounded transient retry/backoff.
:curl_download_with_retry
set "_cdr_max=%LIBSCRIPT_DOWNLOAD_RETRIES%"
if "!_cdr_max!"=="" set "_cdr_max=3"
if /i "!url:~0,7!"=="file://" set "_cdr_max=1"
set "_cdr_try=1"
goto :curl_retry_loop

:: ## curl_retry_loop
:: Performs an individual curl download attempt and checks for non-empty output.
:curl_retry_loop
if exist "!cache_file!" del /f /q "!cache_file!" >nul 2>&1
if not "!auth_header!"=="" (
    "!_curl_bin!" -fL -A "libscript/1.0" --connect-timeout 15 -H "!auth_header!" "!url!" -o "!cache_file!"
) else (
    "!_curl_bin!" -fL -A "libscript/1.0" --connect-timeout 15 "!url!" -o "!cache_file!"
)
if "!errorlevel!" equ "0" (
    if exist "!cache_file!" (
        for %%Z in ("!cache_file!") do (
            if not "%%~zZ"=="0" (
                set "download_success=1"
                exit /b 0
            )
        )
    )
)
set /a "_cdr_rem=_cdr_max - _cdr_try"
if "!_cdr_rem!"=="0" exit /b 1
if "!_cdr_rem:~0,1!"=="-" exit /b 1
if not "%LIBSCRIPT_DOWNLOAD_RETRY_DELAY%"=="0" ping -n 3 127.0.0.1 >nul 2>&1
set /a "_cdr_try+=1"
goto :curl_retry_loop

:: ## download_github_authenticated
:: Rescues GitHub release asset and archive downloads via gh CLI, GitHub REST API, or codeload.github.com.
:download_github_authenticated
call :resolve_gh_token
set "_gda_rest=!url:~19!"
for /f "tokens=1,2* delims=/" %%A in ("!_gda_rest!") do (
    set "_gda_owner=%%A"
    set "_gda_repo=%%B"
    set "_gda_tail=%%C"
)
if "!_gda_owner!"=="" exit /b 1
if "!_gda_repo!"=="" exit /b 1
if /i "!_gda_tail:~0,18!"=="releases/download/" (
    set "_gda_rel_tail=!_gda_tail:~18!"
    for /f "tokens=1* delims=/" %%T in ("!_gda_rel_tail!") do (
        set "_gda_tag=%%T"
        set "_gda_asset=%%U"
    )
    for /f "tokens=1 delims=?" %%Q in ("!_gda_asset!") do set "_gda_asset=%%Q"
    if not "!_gda_tag!"=="" if not "!_gda_asset!"=="" (
        call :download_github_release_asset
        if "!download_success!" equ "1" exit /b 0
    )
    exit /b 1
)
if /i "!_gda_tail:~0,8!"=="archive/" (
    set "_gda_arch=!_gda_tail:~8!"
    for /f "tokens=1 delims=?" %%Q in ("!_gda_arch!") do set "_gda_arch=%%Q"
    call :download_github_codeload_archive
    if "!download_success!" equ "1" exit /b 0
)
exit /b 1

:: ## download_github_release_asset
:: Downloads a GitHub release asset using gh release download or authenticated api.github.com REST endpoint.
:download_github_release_asset
where gh >nul 2>&1
if "!errorlevel!" equ "0" (
    set "_gh_can_use=0"
    if not "!_pm_gh_tok!"=="" set "_gh_can_use=1"
    if "!_gh_can_use!"=="0" (
        gh auth status >nul 2>&1
        if "!errorlevel!" equ "0" set "_gh_can_use=1"
    )
    if "!_gh_can_use!"=="1" (
        if exist "!cache_file!" del /f /q "!cache_file!" >nul 2>&1
        if exist "!dl_dir!\!_gda_asset!" del /f /q "!dl_dir!\!_gda_asset!" >nul 2>&1
        if not "!_pm_gh_tok!"=="" set "GH_TOKEN=!_pm_gh_tok!"
        gh release download "!_gda_tag!" -R "!_gda_owner!/!_gda_repo!" -p "!_gda_asset!" -D "!dl_dir!" --clobber >nul 2>&1
        if "!errorlevel!" equ "0" (
            if /i not "!dl_dir!\!_gda_asset!"=="!cache_file!" (
                if exist "!dl_dir!\!_gda_asset!" move /y "!dl_dir!\!_gda_asset!" "!cache_file!" >nul 2>&1
            )
            if exist "!cache_file!" (
                for %%Z in ("!cache_file!") do (
                    if not "%%~zZ"=="0" (
                        set "download_success=1"
                        exit /b 0
                    )
                )
            )
        )
    )
)
if "!_pm_gh_tok!"=="" exit /b 1
if "!_curl_bin!"=="" call :resolve_pkg_mgr_curl
if "!_curl_bin!"=="" exit /b 1
set "_gda_api_base=%LIBSCRIPT_GITHUB_API_BASE%"
if "!_gda_api_base!"=="" set "_gda_api_base=https://api.github.com"
set "_gda_jq="
where jq >nul 2>&1 && set "_gda_jq=jq"
if "!_gda_jq!"=="" (
    set "_gda_home=%LIBSCRIPT_HOME%"
    if "!_gda_home!"=="" set "_gda_home=%USERPROFILE%\.libscript"
    if exist "!_gda_home!\bin\jq.exe" set "_gda_jq=!_gda_home!\bin\jq.exe"
    if "!_gda_jq!"=="" if exist "!_gda_home!\jq\default\bin\jq.exe" set "_gda_jq=!_gda_home!\jq\default\bin\jq.exe"
)
if "!_gda_jq!"=="" exit /b 1
set "_gda_json=%TEMP%\ls_gh_rel_!RANDOM!_!RANDOM!.json"
set "_gda_url_out=%TEMP%\ls_gh_url_!RANDOM!_!RANDOM!.txt"
"!_curl_bin!" -fsSL -A "libscript/1.0" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !_pm_gh_tok!" "!_gda_api_base!/repos/!_gda_owner!/!_gda_repo!/releases/tags/!_gda_tag!" -o "!_gda_json!" 2>nul
set "_gda_asset_api="
if exist "!_gda_json!" (
    "!_gda_jq!" -r --arg n "!_gda_asset!" ".assets[]? | select(.name == $n) | .url" "!_gda_json!" > "!_gda_url_out!" 2>nul
    del /f /q "!_gda_json!" >nul 2>&1
    if exist "!_gda_url_out!" (
        for /f "usebackq delims=" %%U in ("!_gda_url_out!") do if "!_gda_asset_api!"=="" set "_gda_asset_api=%%U"
        del /f /q "!_gda_url_out!" >nul 2>&1
    )
)
if "!_gda_asset_api!"=="" exit /b 1
if exist "!cache_file!" del /f /q "!cache_file!" >nul 2>&1
"!_curl_bin!" -fsSL -A "libscript/1.0" -H "Accept: application/octet-stream" -H "Authorization: Bearer !_pm_gh_tok!" "!_gda_asset_api!" -o "!cache_file!" 2>nul
if "!errorlevel!" equ "0" (
    if exist "!cache_file!" (
        for %%Z in ("!cache_file!") do (
            if not "%%~zZ"=="0" (
                set "download_success=1"
                exit /b 0
            )
        )
    )
)
exit /b 1

:: ## download_github_codeload_archive
:: Downloads a GitHub tag/branch archive directly from codeload.github.com to bypass github.com web 403 limits.
:download_github_codeload_archive
if "!_curl_bin!"=="" call :resolve_pkg_mgr_curl
if "!_curl_bin!"=="" exit /b 1
set "_gda_cl_url="
if /i "!_gda_arch:~-7!"==".tar.gz" (
    set "_gda_ref=!_gda_arch:~0,-7!"
    set "_gda_cl_url=https://codeload.github.com/!_gda_owner!/!_gda_repo!/tar.gz/!_gda_ref!"
)
if /i "!_gda_arch:~-4!"==".zip" (
    set "_gda_ref=!_gda_arch:~0,-4!"
    set "_gda_cl_url=https://codeload.github.com/!_gda_owner!/!_gda_repo!/zip/!_gda_ref!"
)
if "!_gda_cl_url!"=="" exit /b 1
if not "!_pm_gh_tok!"=="" (
    if exist "!cache_file!" del /f /q "!cache_file!" >nul 2>&1
    "!_curl_bin!" -fsSL -A "libscript/1.0" -H "Authorization: Bearer !_pm_gh_tok!" "!_gda_cl_url!" -o "!cache_file!" 2>nul
    if "!errorlevel!" equ "0" (
        if exist "!cache_file!" (
            for %%Z in ("!cache_file!") do (
                if not "%%~zZ"=="0" (
                    set "download_success=1"
                    exit /b 0
                )
            )
        )
    )
)
if exist "!cache_file!" del /f /q "!cache_file!" >nul 2>&1
"!_curl_bin!" -fsSL -A "libscript/1.0" "!_gda_cl_url!" -o "!cache_file!" 2>nul
if "!errorlevel!" equ "0" (
    if exist "!cache_file!" (
        for %%Z in ("!cache_file!") do (
            if not "%%~zZ"=="0" (
                set "download_success=1"
                exit /b 0
            )
        )
    )
)
exit /b 1

:: ## libscript_fetch_stdout
:: Fetches the contents of a URL to stdout via curl (_lib/utilities/curl) before falling back to libscript_download.
:libscript_fetch_stdout
set "_lfs_url=%~1"
if "!_lfs_url!"=="" exit /b 1
if "%LIBSCRIPT_OFFLINE%"=="1" exit /b 1
if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" exit /b 1
call :resolve_pkg_mgr_curl
set "_lfs_hdr=%LIBSCRIPT_DOWNLOAD_AUTH_HEADER%"
if "!_lfs_hdr!"=="" (
    if /i "!_lfs_url:~0,23!"=="https://api.github.com/" (
        call :resolve_gh_token
        if not "!_pm_gh_tok!"=="" set "_lfs_hdr=Authorization: Bearer !_pm_gh_tok!"
    )
)
if not "!_curl_bin!"=="" (
    if not "!_lfs_hdr!"=="" (
        "!_curl_bin!" -fsSL -A "libscript/1.0" -H "!_lfs_hdr!" "!_lfs_url!" 2>nul
        if "!errorlevel!" equ "0" exit /b 0
    )
    "!_curl_bin!" -fsSL -A "libscript/1.0" "!_lfs_url!" 2>nul
    exit /b !errorlevel!
)
set "_lfs_tmp=%TEMP%\libscript_fetch_%RANDOM%.tmp"
call :libscript_download "!_lfs_url!" "!_lfs_tmp!" "SKIP" >nul 2>&1
if exist "!_lfs_tmp!" (
    type "!_lfs_tmp!"
    del /f /q "!_lfs_tmp!" >nul 2>&1
    exit /b 0
)
exit /b 1

:: ## libscript_resolve_github_tag
:: Resolves the latest release tag_name from a GitHub API releases/latest URL via curl + jq without PowerShell.
:libscript_resolve_github_tag
set "_lrgt_url=%~1"
if "!_lrgt_url!"=="" exit /b 1
if "%LIBSCRIPT_OFFLINE%"=="1" exit /b 1
if "%LIBSCRIPT_FORCE_OFFLINE%"=="1" exit /b 1
call :resolve_pkg_mgr_curl
call :resolve_gh_token
set "_lrgt_jq="
where jq >nul 2>&1 && set "_lrgt_jq=jq"
if "!_lrgt_jq!"=="" (
    set "_lrgt_home=%LIBSCRIPT_HOME%"
    if "!_lrgt_home!"=="" set "_lrgt_home=%USERPROFILE%\.libscript"
    if exist "!_lrgt_home!\bin\jq.exe" set "_lrgt_jq=!_lrgt_home!\bin\jq.exe"
    if "!_lrgt_jq!"=="" if exist "!_lrgt_home!\jq\default\bin\jq.exe" set "_lrgt_jq=!_lrgt_home!\jq\default\bin\jq.exe"
)
if not "!_curl_bin!"=="" (
    if not "!_lrgt_jq!"=="" (
        set "_lrgt_tmp=%TEMP%\ls_gh_tag_!RANDOM!_!RANDOM!.json"
        set "_lrgt_out=%TEMP%\ls_gh_tag_!RANDOM!_!RANDOM!.out"
        if not "!_pm_gh_tok!"=="" (
            "!_curl_bin!" -fsSL -A "libscript/1.0" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !_pm_gh_tok!" "!_lrgt_url!" -o "!_lrgt_tmp!" 2>nul
        )
        if not exist "!_lrgt_tmp!" (
            "!_curl_bin!" -fsSL -A "libscript/1.0" "!_lrgt_url!" -o "!_lrgt_tmp!" 2>nul
        )
        if exist "!_lrgt_tmp!" (
            "!_lrgt_jq!" -r ".tag_name // empty" "!_lrgt_tmp!" > "!_lrgt_out!" 2>nul
            del /f /q "!_lrgt_tmp!" >nul 2>&1
            if exist "!_lrgt_out!" (
                set "_tag_val="
                for /f "usebackq delims=" %%T in ("!_lrgt_out!") do if "!_tag_val!"=="" set "_tag_val=%%T"
                del /f /q "!_lrgt_out!" >nul 2>&1
                if not "!_tag_val!"=="" (
                    if "!_tag_val:~0,1!"=="v" set "_tag_val=!_tag_val:~1!"
                    echo.!_tag_val!
                    exit /b 0
                )
            )
        )
    )
)
where powershell >nul 2>&1
if "!errorlevel!" equ "0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (Invoke-RestMethod -Uri '!_lrgt_url!').tag_name -replace '^v',''" 2>nul
    exit /b !errorlevel!
)
exit /b 1

:: ## libscript_uninstall_pkg
:: Uninstalls a package using the active Windows/ReactOS package manager (rapps, winget, choco, scoop).
:libscript_uninstall_pkg
set "_un_pkg=%~1"
if "!_un_pkg!"=="" exit /b 0
if not defined PKG_MGR call :detect_pkg_mgr
if /i "!PKG_MGR!"=="rapps" (
    set "_ros_sd=%SystemDrive%"
    if "!_ros_sd!"=="" set "_ros_sd=C:"
    if exist "!_ros_sd!\libscript\stamps\rapps_!_un_pkg!.stamp" del /f /q "!_ros_sd!\libscript\stamps\rapps_!_un_pkg!.stamp" >nul 2>&1
)
if /i "!PKG_MGR!"=="winget" (
    where winget >nul 2>&1 && winget uninstall --id "!_un_pkg!" --silent --accept-source-agreements >nul 2>&1
)
if /i "!PKG_MGR!"=="choco" (
    where choco >nul 2>&1 && choco uninstall "!_un_pkg!" -y >nul 2>&1
)
if /i "!PKG_MGR!"=="scoop" (
    where scoop >nul 2>&1 && scoop uninstall "!_un_pkg!" >nul 2>&1
)
exit /b 0

:: ## libscript_http_post_json
:: Sends an HTTP POST JSON request via curl.exe when available.
:libscript_http_post_json
set "_lhp_url=%~1"
set "_lhp_body=%~2"
set "_lhp_timeout=%~3"
if "!_lhp_timeout!"=="" set "_lhp_timeout=120"
if "!_lhp_url!"=="" exit /b 1
where curl.exe >nul 2>&1
if "!errorlevel!" equ "0" (
    curl.exe -sS --connect-timeout 5 --max-time "!_lhp_timeout!" -H "Content-Type: application/json" -d "!_lhp_body!" "!_lhp_url!" >nul 2>&1
    exit /b !errorlevel!
)
exit /b 0
