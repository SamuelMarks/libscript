@echo off
:: # versioning.cmd
:: ## Overview
:: Provides common utilities for managing component versions on Windows. It includes subroutines to resolve component version directories, create NTFS directory junctions (`mklink /J`) for version aliases, and inspect existing installations (`:libscript_check_installed_version`).
:: ## Usage
:: Call subroutines like `:libscript_symlink_alias` or `:libscript_check_installed_version` from other batch scripts.

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

if not "%~1"=="" (
    set "_VER_SUB=%~1"
    if "!_VER_SUB:~0,1!"==":" (
        shift
        goto !_VER_SUB!
    )
    if /i "!_VER_SUB!"=="libscript_get_version_dir" (
        shift
        goto :libscript_get_version_dir
    )
)
goto :eof

:: ## libscript_get_version_dir
:: Resolves and prints the installation directory path for a specific component version.
:libscript_get_version_dir
set "_gvd_in_c=%~1"
set "_gvd_in_v=%~2"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_home >nul
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_comp "!_gvd_in_c!" >nul
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_ver "!_gvd_in_v!" >nul
set "LIBSCRIPT_VERSION_DIR=!DOS83_HOME!\!DOS83_COMP!\!DOS83_VER!"
echo.!LIBSCRIPT_VERSION_DIR!
endlocal & set "LIBSCRIPT_VERSION_DIR=%LIBSCRIPT_VERSION_DIR%"
exit /b 0

:: ## libscript_symlink_alias
:: Updates the default or named version symlink/junction to point to the target version.
:libscript_symlink_alias
set "_sa_orig_comp=%~1"
set "alias_name=%~2"
set "_sa_orig_ver=%~3"

call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_home >nul
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_comp "!_sa_orig_comp!" >nul
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_ver "!_sa_orig_ver!" >nul
set "LIBSCRIPT_BASE_DIR=!DOS83_HOME!"
set "component=!DOS83_COMP!"
set "exact_version=!DOS83_VER!"

if "%alias_name%"=="%exact_version%" if not "%LIBSCRIPT_DOS_83%"=="1" goto :eof

set "base_dir=%LIBSCRIPT_BASE_DIR%\%component%"
if not exist "%base_dir%" mkdir "%base_dir%"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_link_compat "!LIBSCRIPT_BASE_DIR!" "!_sa_orig_comp!" "!component!"

set "alias_path=%base_dir%\%alias_name%"
set "exact_path=%base_dir%\%exact_version%"

if "%LIBSCRIPT_DOS_83%"=="1" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_ver "%alias_name%" >nul
    > "%base_dir%\!DOS83_VER!.VER" echo.%exact_version%
    if /i "%alias_name%"=="default" > "%base_dir%\ACTIVE.VER" echo.%exact_version%
    if /i "%alias_name%"=="default" call :libscript_sync_active_bin "!_sa_orig_comp!"
    goto :eof
)

if exist "%base_dir%" (
    dir /al "%base_dir%" 2>nul | findstr /I /C:"%alias_name%" >nul 2>&1
    if not errorlevel 1 rmdir "%alias_path%" >nul 2>&1
)
if exist "%alias_path%" (
    set "_IS_JUNCTION=0"
    where fsutil >nul 2>&1
    if not errorlevel 1 (
        fsutil reparsepoint query "%alias_path%" >nul 2>&1
        if not errorlevel 1 set "_IS_JUNCTION=1"
    )
    if "!_IS_JUNCTION!"=="0" (
        dir /al "%base_dir%" 2>nul | findstr /I /C:"%alias_name%" >nul 2>&1
        if not errorlevel 1 set "_IS_JUNCTION=1"
    )
    if "!_IS_JUNCTION!"=="1" (
        rmdir "%alias_path%" >nul 2>&1
    ) else (
        dir /b "%alias_path%" 2>nul | findstr "." >nul 2>&1
        if errorlevel 1 rmdir "%alias_path%" >nul 2>&1
    )
)
if "%IS_MSDOS%"=="1" (
    > "%base_dir%\%alias_name%.ver" echo.%exact_version%
    if /i "%alias_name%"=="default" > "%base_dir%\ACTIVE.VER" echo.%exact_version%
    mklink /J "%alias_path%" "%exact_path%" >nul 2>&1
) else if not exist "%alias_path%" (
    mklink /J "%alias_path%" "%exact_path%" >nul 2>&1
    if errorlevel 1 (
        > "%base_dir%\%alias_name%.ver" echo.%exact_version%
        if /i "%alias_name%"=="default" > "%base_dir%\ACTIVE.VER" echo.%exact_version%
    )
)
if /i "%alias_name%"=="default" call :libscript_sync_active_bin "!_sa_orig_comp!"
goto :eof

:: ## libscript_sync_active_bin
:: Synchronizes .cmd/.bat shim dispatchers in LIBSCRIPT_HOME\bin for a component's active default version.
:libscript_sync_active_bin
set "_sab_in_c=%~1"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_home >nul
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_comp "!_sab_in_c!" >nul
set "_sab_home=!DOS83_HOME!"
set "_sab_comp=!DOS83_COMP!"
set "_sab_bin=!_sab_home!\bin"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_enabled
if not errorlevel 1 (
    set "_sab_owners=!_sab_home!\BINOWNER"
    set "_sab_owner_file=!_sab_owners!\!_sab_comp!.LST"
    set "_sab_shim_ext=.BAT"
) else (
    set "_sab_owners=!_sab_home!\.bin_owners"
    set "_sab_owner_file=!_sab_owners!\!_sab_comp!.list"
    set "_sab_shim_ext=.cmd"
)
if not exist "!_sab_bin!" mkdir "!_sab_bin!"
if not exist "!_sab_owners!" mkdir "!_sab_owners!"

set "_sab_ver_sub=default"
if not exist "!_sab_home!\!_sab_comp!\default" if exist "!_sab_home!\!_sab_comp!\ACTIVE.VER" (
    set /p _sab_ver_sub=<"!_sab_home!\!_sab_comp!\ACTIVE.VER"
)

if exist "!_sab_owner_file!" (
    for /f "usebackq delims=" %%O in ("!_sab_owner_file!") do (
        if not exist "!_sab_home!\!_sab_comp!\!_sab_ver_sub!\bin\%%O.exe" if not exist "!_sab_home!\!_sab_comp!\!_sab_ver_sub!\bin\%%O.cmd" if not exist "!_sab_home!\!_sab_comp!\!_sab_ver_sub!\%%O.exe" (
            if exist "!_sab_bin!\%%O!_sab_shim_ext!" del /f /q "!_sab_bin!\%%O!_sab_shim_ext!" >nul 2>&1
        )
    )
)
type nul > "!_sab_owner_file!.TMP"
for %%D in ("!_sab_home!\!_sab_comp!\!_sab_ver_sub!\bin" "!_sab_home!\!_sab_comp!\!_sab_ver_sub!") do (
    if exist "%%~fD" (
        for %%E in ("%%~fD\*.exe" "%%~fD\*.cmd" "%%~fD\*.bat") do (
            set "_shim_name=%%~nE"
            set "_shim_target=%%~fE"
            (
                echo @echo off
                echo "!_shim_target!" %%1 %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9
            ) > "!_sab_bin!\!_shim_name!!_sab_shim_ext!"
            echo.!_shim_name!>> "!_sab_owner_file!.TMP"
        )
    )
)
move /y "!_sab_owner_file!.TMP" "!_sab_owner_file!" >nul 2>&1
exit /b 0

:: ## libscript_cleanup_active_bin
:: Redirects active bin shims to a remaining installed version or deletes stale shims on uninstall.
:libscript_cleanup_active_bin
set "_cab_comp=%~1"
if "%LIBSCRIPT_HOME%"=="" (
    set "_cab_home=%USERPROFILE%\.libscript"
) else (
    set "_cab_home=%LIBSCRIPT_HOME%"
)
set "_cab_dir=!_cab_home!\!_cab_comp!"
set "_cab_owner=!_cab_home!\.bin_owners\!_cab_comp!.list"
if exist "!_cab_dir!\default" (
    dir "!_cab_dir!\default" >nul 2>&1
    if errorlevel 1 rmdir "!_cab_dir!\default" >nul 2>&1
)
if exist "!_cab_dir!\default" (
    call :libscript_sync_active_bin "!_cab_comp!"
    exit /b 0
)
set "_cab_fallback="
if exist "!_cab_dir!" (
    for /d %%V in ("!_cab_dir!\*") do (
        set "_vn=%%~nxV"
        if /i not "!_vn!"=="default" if /i not "!_vn!"=="latest" if /i not "!_vn!"=="lts" if /i not "!_vn!"=="stable" (
            set "_cab_fallback=!_vn!"
        )
    )
)
if not "!_cab_fallback!"=="" (
    call :libscript_symlink_alias "!_cab_comp!" "default" "!_cab_fallback!"
    exit /b 0
)
if exist "!_cab_owner!" (
    for /f "usebackq delims=" %%O in ("!_cab_owner!") do (
        if exist "!_cab_home!\bin\%%O.cmd" del /f /q "!_cab_home!\bin\%%O.cmd" >nul 2>&1
    )
    del /f /q "!_cab_owner!" >nul 2>&1
)
exit /b 0

:: ## libscript_resolve_workspace_version
:: Ascends from a directory looking for .libscript-version or libscript.json workspace pins.
:libscript_resolve_workspace_version
set "_rwv_comp=%~1"
set "_rwv_dir=%~2"
if "!_rwv_dir!"=="" set "_rwv_dir=%CD%"
if "!_rwv_dir:~-1!"=="\" set "_rwv_dir=!_rwv_dir:~0,-1!"
goto :rwv_ascend

:: ## rwv_ascend
:: Internal loop ascending parent directories for workspace version resolution.
:rwv_ascend
set "_rwv_found="
if exist "!_rwv_dir!\.libscript-version" (
    set "_rwv_single="
    set /a _rwv_cnt=0
    for /f "usebackq tokens=1,* delims==:" %%A in ("!_rwv_dir!\.libscript-version") do (
        set "_k=%%A"
        set "_v=%%B"
        if not "!_k:~0,1!"=="#" (
            for /f "tokens=* delims= " %%K in ("!_k!") do set "_k=%%K"
            if not "!_v!"=="" (
                for /f "tokens=* delims= " %%W in ("!_v!") do set "_v=%%W"
                if /i "!_k!"=="!_rwv_comp!" if "!_rwv_found!"=="" set "_rwv_found=!_v!"
            ) else (
                set "_rwv_single=!_k!"
                set /a _rwv_cnt+=1
            )
        )
    )
    if "!_rwv_found!"=="" if "!_rwv_cnt!" EQU "1" if not "!_rwv_single!"=="" set "_rwv_found=!_rwv_single!"
)
if not "!_rwv_found!"=="" goto :rwv_emit
if exist "!_rwv_dir!\libscript.json" (
    where jq >nul 2>&1
    if not errorlevel 1 (
        for /f "usebackq delims=" %%J in (`jq -r --arg c "!_rwv_comp!" "(.deps[$c] // .dependencies[$c] // .[$c] // empty) | if type == \"object\" then (.version // empty) elif type == \"string\" then . else empty end" "!_rwv_dir!\libscript.json" 2^>nul`) do (
            if not "%%J"=="" if not "%%J"=="null" if "!_rwv_found!"=="" set "_rwv_found=%%J"
        )
    )
)
if not "!_rwv_found!"=="" goto :rwv_emit
for %%P in ("!_rwv_dir!") do set "_rwv_parent=%%~dpP"
set "_rwv_next=!_rwv_parent:~0,-1!"
if "!_rwv_next!"=="" exit /b 1
if /i "!_rwv_next!"=="!_rwv_dir!" exit /b 1
set "_rwv_dir=!_rwv_next!"
goto :rwv_ascend

:: ## rwv_emit
:: Prints the resolved workspace version and exports LIBSCRIPT_WORKSPACE_VERSION across endlocal.
:rwv_emit
echo.!_rwv_found!
endlocal & set "LIBSCRIPT_WORKSPACE_VERSION=%_rwv_found%"
exit /b 0

:: ## libscript_check_installed_version
:: Checks whether a component satisfying the requested version is already installed in LIBSCRIPT_HOME or system PATH on Windows.
:libscript_check_installed_version
set "_civ_comp=%~1"
set "_civ_req=%~2"
if "!_civ_req!"=="" set "_civ_req=latest"
if "%LIBSCRIPT_HOME%"=="" (
    set "_civ_home=%USERPROFILE%\.libscript"
) else (
    set "_civ_home=%LIBSCRIPT_HOME%"
)
set "_civ_prefix=!_civ_req:.x=!"
set "_civ_prefix=!_civ_prefix:.*=!"
if /i "!_civ_comp!"=="nodejs" (
    if exist "!_civ_home!\nodejs\!_civ_req!\node.exe" exit /b 0
    if exist "!_civ_home!\nodejs\!_civ_req!\bin\node.exe" exit /b 0
    if exist "!_civ_home!\nodejs" (
        for /d %%D in ("!_civ_home!\nodejs\*") do (
            if exist "%%~fD\node.exe" (
                for /f "delims=" %%V in ('"%%~fD\node.exe" -v 2^>nul') do (
                    set "_nv=%%V"
                    set "_nv=!_nv:v=!"
                    if /i "!_civ_req!"=="latest" exit /b 0
                    echo.!_nv! | findstr /b /c:"!_civ_prefix!." >nul 2>&1
                    if not errorlevel 1 exit /b 0
                )
            )
        )
    )
    where node >nul 2>&1
    if not errorlevel 1 (
        for /f "delims=" %%V in ('node -v 2^>nul') do (
            set "_nv=%%V"
            set "_nv=!_nv:v=!"
            if /i "!_civ_req!"=="latest" exit /b 0
            echo.!_nv! | findstr /b /c:"!_civ_prefix!." >nul 2>&1
            if not errorlevel 1 exit /b 0
        )
    )
    exit /b 1
)
if /i "!_civ_comp!"=="python" (
    if exist "!_civ_home!\python\!_civ_req!\python.exe" exit /b 0
    if exist "!_civ_home!\python\!_civ_req!\bin\python.exe" exit /b 0
    for /f "delims=" %%P in ('where python 2^>nul') do (
        echo "%%~fP" | findstr /i "WindowsApps" >nul 2>&1
        if errorlevel 1 (
            if /i "!_civ_req!"=="latest" exit /b 0
            for /f "tokens=2" %%V in ('"%%~fP" --version 2^>^&1') do (
                echo.%%V | findstr /b /c:"!_civ_prefix!." >nul 2>&1
                if not errorlevel 1 exit /b 0
                if "%%V"=="!_civ_prefix!" exit /b 0
            )
        )
    )
    exit /b 1
)
if /i "!_civ_comp!"=="valkey" (
    where valkey-server >nul 2>&1
    if not errorlevel 1 exit /b 0
    where redis-server >nul 2>&1
    if not errorlevel 1 exit /b 0
    if exist "!_civ_home!\valkey\!_civ_req!\bin" exit /b 0
    exit /b 1
)
if /i "!_civ_comp!"=="redis" (
    where redis-server >nul 2>&1
    if not errorlevel 1 exit /b 0
    where valkey-server >nul 2>&1
    if not errorlevel 1 exit /b 0
    if exist "!_civ_home!\redis\!_civ_req!\bin" exit /b 0
    exit /b 1
)
if /i "!_civ_comp!"=="postgres" (
    where psql >nul 2>&1
    if not errorlevel 1 exit /b 0
    exit /b 1
)
if exist "!_civ_home!\!_civ_comp!\!_civ_req!\bin" exit /b 0
where !_civ_comp! >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

:: ## libscript_handle_generic_action
:: Centralizes common version manager lifecycle actions (ls, ls-remote, use, download, service, install-service, uninstall-service, uninstall) for setup_generic.cmd scripts.
:libscript_handle_generic_action
set "_hga_comp=%~1"
set "_hga_act=%~2"
set "_hga_ver=%~3"
set "_hga_method=%~4"
set "_hga_dl=%~5"
set "_hga_rel=%~6"
set "_hga_repo=%~7"
set "_hga_exec=%~8"
set "_hga_wd=%~9"

if "!_hga_ver!"=="" set "_hga_ver=latest"
if "!_hga_method!"=="" set "_hga_method=libscript_native"
if "%LIBSCRIPT_HOME%"=="" (
    set "_hga_home=%USERPROFILE%\.libscript"
) else (
    set "_hga_home=%LIBSCRIPT_HOME%"
)
if "%DOWNLOAD_DIR%"=="" (
    set "_hga_dldir=%TEMP%\libscript_downloads"
) else (
    set "_hga_dldir=%DOWNLOAD_DIR%"
)
if "%LIBSCRIPT_SERVICE_NAME%"=="" (
    if "%PACKAGE_NAME%"=="" (
        set "_hga_svc=libscript_!_hga_comp!"
    ) else (
        set "_hga_svc=libscript_%PACKAGE_NAME%"
    )
) else (
    set "_hga_svc=%LIBSCRIPT_SERVICE_NAME%"
)
if "!_hga_wd!"=="" set "_hga_wd=!_hga_home!\!_hga_comp!\!_hga_ver!"
if "!_hga_exec!"=="" set "_hga_exec=\"!_hga_wd!\bin\!_hga_comp!.exe\""

if /i "!_hga_act!"=="ls" (
    if /i "!_hga_method!"=="system" (
        echo System package manager does not support ls directly here.
        exit /b 0
    )
    if exist "!_hga_home!\!_hga_comp!" dir /b "!_hga_home!\!_hga_comp!"
    exit /b 0
)
if /i "!_hga_act!"=="ls-remote" (
    if /i "!_hga_method!"=="system" (
        echo System package manager does not support ls-remote directly here.
        exit /b 0
    )
    if not "!_hga_rel!"=="" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_fetch_stdout "!_hga_rel!"
        exit /b 0
    )
    if not "!_hga_repo!"=="" (
        git ls-remote --tags "!_hga_repo!" 2^>nul ^| findstr /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"
        exit /b 0
    )
    echo No versions found
    exit /b 0
)
if /i "!_hga_act!"=="use" (
    if /i "!_hga_method!"=="system" (
        echo Cannot 'use' specific version with system package manager.
        exit /b 0
    )
    set "_hga_exact=!EXACT_VERSION!"
    if "!_hga_exact!"=="" set "_hga_exact=!_hga_ver!"
    if not exist "!_hga_home!\!_hga_comp!\!_hga_exact!" (
        if exist "!DIR!\setup.cmd" (
            echo [INFO] !_hga_comp! !_hga_exact! is not installed. Installing it now...
            set "STACK="
            set "ACTION=install"
            call "!DIR!\setup.cmd" install "!_hga_comp!" "!_hga_ver!"
            if errorlevel 1 exit /b !errorlevel!
        )
    )
    call :libscript_symlink_alias "!_hga_comp!" "!_hga_ver!" "!_hga_exact!"
    call :libscript_symlink_alias "!_hga_comp!" "default" "!_hga_exact!"
    exit /b 0
)
if /i "!_hga_act!"=="download" (
    if /i "!_hga_method!"=="libscript_native" (
        echo Downloading !_hga_comp! !_hga_ver! to !_hga_dldir!\!_hga_comp!...
        if not exist "!_hga_dldir!\!_hga_comp!" mkdir "!_hga_dldir!\!_hga_comp!"
        if not "!_hga_dl!"=="" (
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\engine\common\pkg_mgr.cmd" :libscript_download "!_hga_dl!" "!_hga_dldir!\!_hga_comp!\!_hga_comp!-!_hga_ver!.zip"
        ) else (
            echo Download URL is not defined for !_hga_comp!. Skipping.
        )
    )
    exit /b 0
)
for %%S in (start stop restart status health logs up down) do (
    if /i "!_hga_act!"=="%%S" (
        if exist "!SCRIPT_DIR!\service.cmd" (
            set "STACK="
            call "!SCRIPT_DIR!\service.cmd" "!_hga_act!"
            exit /b !errorlevel!
        )
        if /i "!_hga_method!"=="libscript_native" (
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\engine\common\service.cmd" "!_hga_act!" "!_hga_svc!"
        ) else if /i "!_hga_method!"=="system" (
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\engine\common\service.cmd" "!_hga_act!" "!_hga_svc!"
        ) else (
            echo !_hga_act! not natively implemented for !_hga_method!.
        )
        exit /b 0
    )
)
if /i "!_hga_act!"=="install-service" (
    if /i "!_hga_method!"=="libscript_native" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\service_install.cmd" install "!_hga_svc!" "!_hga_exec!" "!_hga_wd!" "!_hga_comp! service"
    ) else if /i "!_hga_method!"=="system" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\service_install.cmd" install "!_hga_svc!" "!_hga_exec!" "!_hga_wd!" "!_hga_comp! service"
    ) else (
        echo install-service not implemented for !_hga_method!.
    )
    exit /b 0
)
if /i "!_hga_act!"=="uninstall-service" (
    if /i "!_hga_method!"=="libscript_native" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\service_install.cmd" uninstall "!_hga_svc!"
    ) else if /i "!_hga_method!"=="system" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\service_install.cmd" uninstall "!_hga_svc!"
    ) else (
        echo uninstall-service not implemented for !_hga_method!.
    )
    exit /b 0
)
if /i "!_hga_act!"=="uninstall" (
    if /i "!_hga_method!"=="libscript_native" (
        echo Uninstalling !_hga_comp! !_hga_ver!...
        if exist "!_hga_home!\!_hga_comp!\!_hga_ver!" (
            rmdir /s /q "!_hga_home!\!_hga_comp!\!_hga_ver!" 2>nul
        )
        call :libscript_cleanup_active_bin "!_hga_comp!"
    ) else (
        echo Uninstall not implemented or supported for !_hga_method!.
    )
    exit /b 0
)
exit /b 1
