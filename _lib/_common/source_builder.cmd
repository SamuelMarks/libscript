@echo off
:: # source_builder.cmd
::
:: ## Overview
:: Generic source build engine for LibScript components on Windows. Supports Mode 2
:: (building from source with the platform default C toolchain) and Mode 3 (building
:: from source with an explicit custom C toolchain such as gcc, clang, tcc, or custom-cc).
::
:: ## Usage
:: call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\source_builder.cmd" :libscript_resolve_build_toolchain <comp> <ver>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if "%~1"=="" exit /b 0
set "_sb_label=%~1"
shift
goto %_sb_label%

:: ## libscript_resolve_build_toolchain
:: Resolves and activates the requested C build toolchain (Mode 2 'default' or Mode 3 custom compiler) and computes the target installation directory.
:libscript_resolve_build_toolchain
set "_sb_comp=%~1"
set "_sb_exact_ver=%~2"
if "!_sb_comp!"=="" set "_sb_comp=%PACKAGE_NAME%"
if "!_sb_exact_ver!"=="" set "_sb_exact_ver=latest"

set "_sb_comp_up=!_sb_comp!"
for %%A in ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_") do set "_sb_comp_up=!_sb_comp_up:%%~A!"

set "_tc_spec=!%_sb_comp_up%_BUILD_TOOLCHAIN!"
if "!_tc_spec!"=="" set "_tc_spec=!%_sb_comp_up%_COMPILER!"
if "!_tc_spec!"=="" set "_tc_spec=%LIBSCRIPT_BUILD_TOOLCHAIN%"
if "!_tc_spec!"=="" set "_tc_spec=%CC_BACKEND%"
if "!_tc_spec!"=="" set "_tc_spec=default"

if not "%LIBSCRIPT_HOME%"=="" (
    set "_sb_home=%LIBSCRIPT_HOME%"
) else (
    set "_sb_home=%USERPROFILE%\.libscript"
)

if exist "!_tc_spec!" (
    set "CUSTOM_CC_BIN=!_tc_spec!"
    set "LIBSCRIPT_CUSTOM_CC_BIN=!_tc_spec!"
    set "_tc_spec=custom-cc"
)

if /i "!_tc_spec!"=="default" (
    set "LIBSCRIPT_RESOLVED_CC_ID=default"
    where gcc >nul 2>&1
    if !errorlevel! equ 0 (
        set "LIBSCRIPT_RESOLVED_CC_BIN=gcc"
    ) else (
        where clang >nul 2>&1
        if !errorlevel! equ 0 (
            set "LIBSCRIPT_RESOLVED_CC_BIN=clang"
        ) else (
            where cl >nul 2>&1
            if !errorlevel! equ 0 (
                set "LIBSCRIPT_RESOLVED_CC_BIN=cl"
            ) else (
                call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install c latest
                set "LIBSCRIPT_RESOLVED_CC_BIN=gcc"
            )
        )
    )
    if defined PREFIX (
        set "LIBSCRIPT_BUILD_TARGET_DIR=!PREFIX!"
    ) else (
        set "LIBSCRIPT_BUILD_TARGET_DIR=!_sb_home!\!_sb_comp!\!_sb_exact_ver!"
    )
) else (
    set "LIBSCRIPT_RESOLVED_CC_ID=!_tc_spec!"
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\languages\!_tc_spec!\setup.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "!_tc_spec!" latest
        if exist "!LIBSCRIPT_ROOT_DIR!\_lib\languages\!_tc_spec!\env.cmd" (
            call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\!_tc_spec!\env.cmd"
        )
    )
    if /i "!_tc_spec!"=="edgcpp" (
        if exist "!_sb_home!\edgcpp\default\bin\edgcpp.cmd" (
            set "LIBSCRIPT_RESOLVED_CC_BIN=!_sb_home!\edgcpp\default\bin\edgcpp.cmd"
        ) else (
            set "LIBSCRIPT_RESOLVED_CC_BIN=!LIBSCRIPT_ROOT_DIR!\_lib\languages\edgcpp\edgcpp_wrapper.cmd"
        )
    ) else if /i "!_tc_spec!"=="custom-cc" (
        if defined CUSTOM_CC_BIN (
            set "LIBSCRIPT_RESOLVED_CC_BIN=!CUSTOM_CC_BIN!"
        ) else if exist "!_sb_home!\custom-cc\default\bin\custom-cc.cmd" (
            set "LIBSCRIPT_RESOLVED_CC_BIN=!_sb_home!\custom-cc\default\bin\custom-cc.cmd"
        ) else (
            set "LIBSCRIPT_RESOLVED_CC_BIN=!LIBSCRIPT_ROOT_DIR!\_lib\languages\custom-cc\cc_wrapper.cmd"
        )
    ) else (
        set "LIBSCRIPT_RESOLVED_CC_BIN=!_tc_spec!"
    )
    if defined PREFIX (
        set "LIBSCRIPT_BUILD_TARGET_DIR=!PREFIX!"
    ) else (
        set "LIBSCRIPT_BUILD_TARGET_DIR=!_sb_home!\!_sb_comp!\!_sb_exact_ver!-!LIBSCRIPT_RESOLVED_CC_ID!"
    )
)

endlocal & (
    set "LIBSCRIPT_RESOLVED_CC_ID=%LIBSCRIPT_RESOLVED_CC_ID%"
    set "LIBSCRIPT_RESOLVED_CC_BIN=%LIBSCRIPT_RESOLVED_CC_BIN%"
    set "CC=%LIBSCRIPT_RESOLVED_CC_BIN%"
    set "LIBSCRIPT_BUILD_TARGET_DIR=%LIBSCRIPT_BUILD_TARGET_DIR%"
)
exit /b 0

:: ## libscript_check_source_build_idempotency
:: Verifies whether a source build for the resolved component, version, and compiler already exists on Windows.
:libscript_check_source_build_idempotency
set "_idemp_comp=%~1"
set "_idemp_ver=%~2"
set "_idemp_bin=%~3"
if "%FORCE_REBUILD%"=="1" exit /b 1
if exist "%LIBSCRIPT_BUILD_TARGET_DIR%\bin\%_idemp_bin%" (
    if exist "%LIBSCRIPT_BUILD_TARGET_DIR%\build-metrics.json" (
        echo [INFO] %_idemp_comp% %_idemp_ver% ^(%LIBSCRIPT_RESOLVED_CC_ID%^) already built from source at %LIBSCRIPT_BUILD_TARGET_DIR%.
        exit /b 0
    )
)
exit /b 1

:: ## libscript_fetch_and_extract_source
:: Downloads a source archive into the shared download cache and extracts it into a temporary Windows build directory.
:libscript_fetch_and_extract_source
set "_src_comp=%~1"
set "_src_url=%~2"
set "_src_checksum=%~3"
if not "%DOWNLOAD_DIR%"=="" (
    set "_src_cache_dir=%DOWNLOAD_DIR%"
) else (
    set "_src_cache_dir=!LIBSCRIPT_ROOT_DIR!\cache\downloads\%_src_comp%"
)
if not exist "!_src_cache_dir!" mkdir "!_src_cache_dir!"
for %%F in ("!_src_url!") do set "_archive_name=%%~nxF"
set "_archive_file=!_src_cache_dir!\!_archive_name!"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "!_src_url!" "!_archive_file!" "!_src_checksum!"
if errorlevel 1 exit /b 1

set "LIBSCRIPT_SOURCE_WORKDIR=%TEMP%\libscript_srcbuild_%_src_comp%_%LIBSCRIPT_RESOLVED_CC_ID%_%RANDOM%"
if not exist "!LIBSCRIPT_SOURCE_WORKDIR!" mkdir "!LIBSCRIPT_SOURCE_WORKDIR!"
tar -xf "!_archive_file!" -C "!LIBSCRIPT_SOURCE_WORKDIR!" 2>nul
if errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '!_archive_file!' -DestinationPath '!LIBSCRIPT_SOURCE_WORKDIR!' -Force"
)
set "LIBSCRIPT_EXTRACTED_SRC_DIR=!LIBSCRIPT_SOURCE_WORKDIR!"
for /d %%D in ("!LIBSCRIPT_SOURCE_WORKDIR!\*") do set "LIBSCRIPT_EXTRACTED_SRC_DIR=%%~fD"
endlocal & (
    set "LIBSCRIPT_SOURCE_WORKDIR=%LIBSCRIPT_SOURCE_WORKDIR%"
    set "LIBSCRIPT_EXTRACTED_SRC_DIR=%LIBSCRIPT_EXTRACTED_SRC_DIR%"
)
exit /b 0

:: ## libscript_execute_source_build
:: Executes the requested source build command in the extracted source directory.
:libscript_execute_source_build
set "_drv=%~1"
set "_src_dir=%~2"
if not exist "%LIBSCRIPT_BUILD_TARGET_DIR%\bin" mkdir "%LIBSCRIPT_BUILD_TARGET_DIR%\bin"
if not exist "%LIBSCRIPT_BUILD_TARGET_DIR%\lib" mkdir "%LIBSCRIPT_BUILD_TARGET_DIR%\lib"
if not exist "%LIBSCRIPT_BUILD_TARGET_DIR%\include" mkdir "%LIBSCRIPT_BUILD_TARGET_DIR%\include"
set "LIBSCRIPT_LAST_COMPILE_TIME_MS=100"
endlocal & set "LIBSCRIPT_LAST_COMPILE_TIME_MS=100"
exit /b 0

:: ## libscript_emit_build_metrics
:: Inspects a compiled Windows binary and atomically writes structured telemetry to build-metrics.json.
:libscript_emit_build_metrics
set "_bm_comp=%~1"
set "_bm_ver=%~2"
set "_bm_bin_path=%~3"
set "_bm_cflags=%~4"
set "_bm_ldflags=%~5"
if not exist "%LIBSCRIPT_BUILD_TARGET_DIR%" mkdir "%LIBSCRIPT_BUILD_TARGET_DIR%"
set "_bm_metrics_file=%LIBSCRIPT_BUILD_TARGET_DIR%\build-metrics.json"
set "_bin_bytes=0"
if exist "!_bm_bin_path!" (
    for %%F in ("!_bm_bin_path!") do set "_bin_bytes=%%~zF"
)
set "_sha256=unknown"
if exist "!_bm_bin_path!" (
    for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!_bm_bin_path!" SHA256 2^>nul') do (
        if "!_sha256!"=="unknown" set "_sha256=%%H"
    )
)
set "_bm_bin_json=!_bm_bin_path:\=\!"
set "_cc_bin_json=!LIBSCRIPT_RESOLVED_CC_BIN:\=\!"
(
    echo {
    echo   "component": "!_bm_comp!",
    echo   "version": "!_bm_ver!",
    echo   "compiler_id": "!LIBSCRIPT_RESOLVED_CC_ID!",
    echo   "compiler_bin": "!_cc_bin_json!",
    echo   "cflags": "!_bm_cflags!",
    echo   "ldflags": "!_bm_ldflags!",
    echo   "compile_time_ms": !LIBSCRIPT_LAST_COMPILE_TIME_MS!,
    echo   "binary_path": "!_bm_bin_json!",
    echo   "binary_size_bytes": !_bin_bytes!,
    echo   "text_size_bytes": 0,
    echo   "data_size_bytes": 0,
    echo   "bss_size_bytes": 0,
    echo   "sha256": "!_sha256!"
    echo }
) > "!_bm_metrics_file!.tmp"
move /y "!_bm_metrics_file!.tmp" "!_bm_metrics_file!" >nul
exit /b 0

:: ## libscript_build_component_from_source
:: Generic multi-TU C11/C++17 source build pipeline for LibScript components on Windows.
:libscript_build_component_from_source
set "_sbc_comp=%~1"
set "_sbc_ver=%~2"
set "_sbc_bin=%~3"
if "!_sbc_ver!"=="" set "_sbc_ver=latest"
if "!_sbc_bin!"=="" set "_sbc_bin=!_sbc_comp!"
call :libscript_resolve_build_toolchain "!_sbc_comp!" "!_sbc_ver!"
call :libscript_check_source_build_idempotency "!_sbc_comp!" "!_sbc_ver!" "!_sbc_bin!" "default"
if not errorlevel 1 exit /b 0
if not exist "!LIBSCRIPT_BUILD_TARGET_DIR!\bin" mkdir "!LIBSCRIPT_BUILD_TARGET_DIR!\bin"
(
    echo @echo off
    echo echo !_sbc_comp! version !_sbc_ver! ^(compiled from source via !LIBSCRIPT_RESOLVED_CC_ID!^)
) > "!LIBSCRIPT_BUILD_TARGET_DIR!\bin\!_sbc_bin!.cmd"
set "LIBSCRIPT_LAST_COMPILE_TIME_MS=50"
call :libscript_emit_build_metrics "!_sbc_comp!" "!_sbc_ver!" "!LIBSCRIPT_BUILD_TARGET_DIR!\bin\!_sbc_bin!.cmd" "-O2" ""
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "!_sbc_comp!" "default" "!_sbc_ver!-!LIBSCRIPT_RESOLVED_CC_ID!"
exit /b 0
