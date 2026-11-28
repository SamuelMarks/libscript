@echo off
:: # setup_generic.cmd
:: ## Overview
:: Generic Windows setup script for `libtpu-rs` (`SamuelMarks/libtpu-rs`) supporting GitHub Releases (`tpu.dll` + PEP 427 wheel) with automatic Cargo source-build fallback under SIGPLAN `RULE-6` pinned release profiles.
:: ## Usage
:: Called internally by `_lib\toolchains\libtpu-rs\setup.cmd`.

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
if "%ACTION%"=="" set "ACTION=install"
if "%LIBTPU_RS_INSTALL_METHOD%"=="" set "LIBTPU_RS_INSTALL_METHOD=libscript_native"
if "%LIBTPU_RS_VERSION%"=="" set "LIBTPU_RS_VERSION=0.0.52"
if "%LIBTPU_RS_GIT_URL%"=="" set "LIBTPU_RS_GIT_URL=https://github.com/SamuelMarks/libtpu-rs.git"
if "%LIBTPU_RS_CARGO_PROFILE%"=="" set "LIBTPU_RS_CARGO_PROFILE=opt3-lto-thin-cgu1"
if "%LIBTPU_RS_SLIM_FEATURES%"=="" set "LIBTPU_RS_SLIM_FEATURES=--no-default-features"
if "%LIBTPU_RS_JAX_VERSION%"=="" set "LIBTPU_RS_JAX_VERSION=0.4.38"
set "EXACT_VERSION=%LIBTPU_RS_VERSION%"
if /i "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=0.0.52"
if /i "!EXACT_VERSION!"=="lts" set "EXACT_VERSION=0.0.52"

if /i "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\libtpu-rs" dir /b "%LIBSCRIPT_HOME%\libtpu-rs"
    exit /b 0
)
if /i "%ACTION%"=="ls-remote" (
    echo 0.0.52
    exit /b 0
)
if /i "%ACTION%"=="use" (
    call :do_install
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "%LIBTPU_RS_VERSION%" "!EXACT_VERSION!"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "default" "!EXACT_VERSION!"
    exit /b 0
)
if /i "%ACTION%"=="download" exit /b 0
if /i "%ACTION%"=="install" goto :do_install
exit /b 0

:: ## compute_sha256
:: Computes lowercase SHA-256 of a file using certutil and writes it atomically to an output path.
:compute_sha256
set "_CS_IN=%~1"
set "_CS_OUT=%~2"
set "_CS_VAL="
if exist "!_CS_IN!" (
    for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!_CS_IN!" SHA256 2^>nul') do (
        if "!_CS_VAL!"=="" set "_CS_VAL=%%H"
    )
)
if not "!_CS_VAL!"=="" (
    > "!_CS_OUT!.tmp" echo.!_CS_VAL!
    move /y "!_CS_OUT!.tmp" "!_CS_OUT!" >nul
)
exit /b 0

:: ## finalize_windows_libs
:: Writes backward-compatible libtpu_c_api.dll aliases, SHA-256 stamps, and wheel_path.txt metadata.
:finalize_windows_libs
set "_FWL_DIR=%~1"
if exist "!_FWL_DIR!\lib\tpu.dll" (
    copy /y "!_FWL_DIR!\lib\tpu.dll" "!_FWL_DIR!\lib\libtpu_c_api.dll" >nul
    call :compute_sha256 "!_FWL_DIR!\lib\tpu.dll" "!_FWL_DIR!\lib\libtpu_so_sha256.txt"
)
if exist "!_FWL_DIR!\lib\tpu_slim.dll" (
    copy /y "!_FWL_DIR!\lib\tpu_slim.dll" "!_FWL_DIR!\lib\libtpu_c_api_slim.dll" >nul
)
for %%W in ("!_FWL_DIR!\wheels\*.whl") do (
    if exist "%%~fW" (
        > "!_FWL_DIR!\wheels\wheel_path.txt.tmp" echo.%%~fW
        move /y "!_FWL_DIR!\wheels\wheel_path.txt.tmp" "!_FWL_DIR!\wheels\wheel_path.txt" >nul
        goto :fwl_whl_done
    )
)
goto :fwl_whl_done

:: ## fwl_whl_done
:: Continues after recording the first wheel path.
:fwl_whl_done
exit /b 0

:: ## try_windows_release_download
:: Attempts to download prebuilt Windows x86_64 release zip via pkg_mgr.cmd when LIBTPU_RS_DOWNLOAD_URL is provided.
:try_windows_release_download
set "_TWR_DIR=%~1"
if "%LIBSCRIPT_OFFLINE%"=="1" exit /b 1
if not "%LIBTPU_RS_DOWNLOAD_URL%"=="" (
    set "_DL_ZIP=%LIBSCRIPT_ROOT_DIR%\cache\downloads\libtpu-rs\libtpu-windows-x86_64.zip"
    if not exist "%LIBSCRIPT_ROOT_DIR%\cache\downloads\libtpu-rs" mkdir "%LIBSCRIPT_ROOT_DIR%\cache\downloads\libtpu-rs"
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\pkg_mgr.cmd" :libscript_download "%LIBTPU_RS_DOWNLOAD_URL%" "!_DL_ZIP!" ""
    if exist "!_DL_ZIP!" (
        tar -xf "!_DL_ZIP!" -C "!_TWR_DIR!\lib" 2>nul
        if exist "!_TWR_DIR!\lib\tpu.dll" (
            call :finalize_windows_libs "!_TWR_DIR!"
            exit /b 0
        )
    )
)
exit /b 1

:: ## do_install
:: Installs libtpu-rs (`tpu.dll`, `libtpu_c_api.dll`, PEP 427 wheel, and helper shim) idempotently on Windows.
:do_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\libtpu-rs\!EXACT_VERSION!"
if exist "!TARGET_DIR!\bin\libtpu-rs-env.cmd" (
    if not "%FORCE_REINSTALL%"=="1" (
        echo [INFO] libtpu-rs !EXACT_VERSION! is already installed at !TARGET_DIR!.
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "%LIBTPU_RS_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
if not exist "!TARGET_DIR!\lib" mkdir "!TARGET_DIR!\lib"
if not exist "!TARGET_DIR!\wheels" mkdir "!TARGET_DIR!\wheels"
set "CARGO_PROFILE_RELEASE_OPT_LEVEL=3"
set "CARGO_PROFILE_RELEASE_LTO=thin"
set "CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1"
> "!TARGET_DIR!\cargo_profile.json.tmp" echo {"profile":"%LIBTPU_RS_CARGO_PROFILE%","opt_level":"3","lto":"thin","codegen_units":1}
move /y "!TARGET_DIR!\cargo_profile.json.tmp" "!TARGET_DIR!\cargo_profile.json" >nul

if not "%LIBTPU_RS_SO_PATH%"=="" (
    if exist "%LIBTPU_RS_SO_PATH%" (
        copy /y "%LIBTPU_RS_SO_PATH%" "!TARGET_DIR!\lib\tpu.dll" >nul
        if not "%LIBTPU_RS_SDK_SO_PATH%"=="" (
            if exist "%LIBTPU_RS_SDK_SO_PATH%" copy /y "%LIBTPU_RS_SDK_SO_PATH%" "!TARGET_DIR!\lib\sdk.dll" >nul
        )
        if not "%LIBTPU_RS_WHEEL_PATH%"=="" (
            if exist "%LIBTPU_RS_WHEEL_PATH%" (
                for %%F in ("%LIBTPU_RS_WHEEL_PATH%") do copy /y "%LIBTPU_RS_WHEEL_PATH%" "!TARGET_DIR!\wheels\%%~nxF" >nul
            )
        )
        call :finalize_windows_libs "!TARGET_DIR!"
        goto :after_native_or_source
    )
)

if /i "%LIBTPU_RS_INSTALL_METHOD%"=="libscript_native" (
    if "%LIBTPU_RS_REPO_DIR%"=="" (
        call :try_windows_release_download "!TARGET_DIR!"
        if not errorlevel 1 goto :after_native_or_source
    )
)

set "_SRC_REPO=%LIBTPU_RS_REPO_DIR%"
if "!_SRC_REPO!"=="" (
    if exist "%LIBSCRIPT_ROOT_DIR%\..\libtpu-rs" set "_SRC_REPO=%LIBSCRIPT_ROOT_DIR%\..\libtpu-rs"
)
if "!_SRC_REPO!"=="" (
    if not "%LIBSCRIPT_OFFLINE%"=="1" (
        set "_CLONE_DST=%LIBSCRIPT_ROOT_DIR%\cache\src\libtpu-rs"
        if not exist "!_CLONE_DST!\.git" (
            if not exist "%LIBSCRIPT_ROOT_DIR%\cache\src" mkdir "%LIBSCRIPT_ROOT_DIR%\cache\src"
            git clone --depth 1 "%LIBTPU_RS_GIT_URL%" "!_CLONE_DST!"
        )
        if exist "!_CLONE_DST!\Cargo.toml" set "_SRC_REPO=!_CLONE_DST!"
    )
)
if not "!_SRC_REPO!"=="" (
    if exist "!_SRC_REPO!\Cargo.toml" (
        where cargo >nul 2>&1
        if errorlevel 1 call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install rust latest
        pushd "!_SRC_REPO!"
        cargo build --release -p libtpu-c-api
        popd
        set "_BUILT_DLL="
        if exist "!_SRC_REPO!\target\release\tpu.dll" set "_BUILT_DLL=!_SRC_REPO!\target\release\tpu.dll"
        if "!_BUILT_DLL!"=="" (
            if exist "!_SRC_REPO!\target\release\libtpu_c_api.dll" set "_BUILT_DLL=!_SRC_REPO!\target\release\libtpu_c_api.dll"
        )
        if not "!_BUILT_DLL!"=="" (
            copy /y "!_BUILT_DLL!" "!TARGET_DIR!\lib\tpu.unstripped.dll" >nul
            copy /y "!_BUILT_DLL!" "!TARGET_DIR!\lib\tpu.dll" >nul
            where strip >nul 2>&1
            if not errorlevel 1 strip --strip-unneeded "!TARGET_DIR!\lib\tpu.dll" 2>nul
        )
        pushd "!_SRC_REPO!"
        cargo build --release -p libtpu-c-api --target-dir "!_SRC_REPO!\target\release-slim" %LIBTPU_RS_SLIM_FEATURES%
        popd
        set "_SLIM_DLL="
        if exist "!_SRC_REPO!\target\release-slim\release\tpu.dll" set "_SLIM_DLL=!_SRC_REPO!\target\release-slim\release\tpu.dll"
        if "!_SLIM_DLL!"=="" (
            if exist "!_SRC_REPO!\target\release-slim\release\libtpu_c_api.dll" set "_SLIM_DLL=!_SRC_REPO!\target\release-slim\release\libtpu_c_api.dll"
        )
        if not "!_SLIM_DLL!"=="" (
            copy /y "!_SLIM_DLL!" "!TARGET_DIR!\lib\tpu_slim.unstripped.dll" >nul
            copy /y "!_SLIM_DLL!" "!TARGET_DIR!\lib\tpu_slim.dll" >nul
            where strip >nul 2>&1
            if not errorlevel 1 strip --strip-unneeded "!TARGET_DIR!\lib\tpu_slim.dll" 2>nul
        )
        if exist "!_SRC_REPO!\pyproject.toml" (
            if not "%LIBSCRIPT_OFFLINE%"=="1" (
                where uv >nul 2>&1
                if not errorlevel 1 (
                    pushd "!_SRC_REPO!"
                    uv build --wheel --out-dir "!TARGET_DIR!\wheels"
                    popd
                )
            )
        )
        call :finalize_windows_libs "!TARGET_DIR!"
    )
)

goto :after_native_or_source

:: ## after_native_or_source
:: Continues installation after binary/wheel acquisition completes.
:after_native_or_source
set "_REQ_F=!TARGET_DIR!\jax_requirements.txt"
(
    echo jax==%LIBTPU_RS_JAX_VERSION%
    echo jaxlib==%LIBTPU_RS_JAX_VERSION%
) > "!_REQ_F!"
if not "%LIBSCRIPT_OFFLINE%"=="1" (
    if "%LIBTPU_RS_SO_PATH%"=="" (
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\python_env.cmd" libscript_python_venv "!TARGET_DIR!\venv" "" "!_REQ_F!"
    )
)
(
    echo @echo off
    echo echo libtpu-rs !EXACT_VERSION! ^(!TARGET_DIR!^)
) > "!TARGET_DIR!\bin\libtpu-rs-env.cmd.tmp"
move /y "!TARGET_DIR!\bin\libtpu-rs-env.cmd.tmp" "!TARGET_DIR!\bin\libtpu-rs-env.cmd" >nul
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "%LIBTPU_RS_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "libtpu-rs" "default" "!EXACT_VERSION!"
exit /b 0
