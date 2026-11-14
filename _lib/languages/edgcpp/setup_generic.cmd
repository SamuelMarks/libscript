@echo off
:: # setup_generic.cmd
:: ## Overview
:: Generic Windows setup and lifecycle implementation for the EDG C/C++ Compiler Frontend (edgcpp). Supports downloading official v7.0.1 Windows x86_64/arm64 release archives across edgcpp+llvm+gcc, edgcpp+llvm, and edgcpp+gcc flavors, building from source, and staging edgcpp/edg-cc/edg-c++ compiler driver wrappers.
:: ## Usage
:: setup_generic.cmd [ACTION]

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

if "%ACTION%"=="" set "ACTION=install"
if "%EDGCPP_VERSION%"=="" set "EDGCPP_VERSION=7.0.1"
call :resolve_latest_edgcpp_release
if "%EDGCPP_FLAVOR%"=="" set "EDGCPP_FLAVOR=edgcpp+llvm+gcc"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

set "_win_arch=x86_64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "_win_arch=arm64"
set "EDGCPP_ASSET_NAME=%EDGCPP_FLAVOR%-v%EXACT_VERSION%-windows-%_win_arch%.zip"
if not "%EDGCPP_DOWNLOAD_URL%"=="" (
    set "EDGCPP_ASSET_URL=%EDGCPP_DOWNLOAD_URL%"
    set "EDGCPP_ASSET_SHA256="
) else (
    set "EDGCPP_ASSET_URL=https://github.com/SamuelMarks/edgcpp-compiler/releases/download/v%EXACT_VERSION%/%EDGCPP_ASSET_NAME%"
    set "EDGCPP_ASSET_SHA256=3221b67308aed3d5144a3b6cbc5ac2958f4c4c0ebc126584136279a32f1a1c1d"
    if /i "%EDGCPP_ASSET_NAME%"=="edgcpp+llvm+gcc-v7.0.1-windows-arm64.zip" set "EDGCPP_ASSET_SHA256=0ac2b826cb1dacce195c50da9bdc8062999a15323346dc94ac2a12fbaeb0621b"
    if /i "%EDGCPP_ASSET_NAME%"=="edgcpp+llvm-v7.0.1-windows-x86_64.zip" set "EDGCPP_ASSET_SHA256=9d02a8f933b3eb0c8eb7415f94d6fbeb14d89523f8620a1c966f436c2707a30c"
    if /i "%EDGCPP_ASSET_NAME%"=="edgcpp+llvm-v7.0.1-windows-arm64.zip" set "EDGCPP_ASSET_SHA256=2663c9f8caebb75d43fd6c316fe776ffc25331647380e32f78b29dfd1d272488"
    if /i "%EDGCPP_ASSET_NAME%"=="edgcpp+gcc-v7.0.1-windows-x86_64.zip" set "EDGCPP_ASSET_SHA256=b1c2be566247de89e9663eb0a4e8369b98e2d591d3b5a8ea32a0e8b909fa54b6"
    if /i "%EDGCPP_ASSET_NAME%"=="edgcpp+gcc-v7.0.1-windows-arm64.zip" set "EDGCPP_ASSET_SHA256=8e99c17d62a4104bf6a646018a69dd972e1281561f7c38c6c18bf14e12973b49"
)

if /i "%ACTION%"=="ls" goto :action_ls
if /i "%ACTION%"=="ls-remote" goto :action_ls_remote
if /i "%ACTION%"=="use" goto :action_use
if /i "%ACTION%"=="download" goto :action_download
if /i "%ACTION%"=="verify-modes" goto :action_verify_modes
if /i "%ACTION%"=="build-coverage" goto :action_build_coverage
if /i "%ACTION%"=="build-bug4-ablation" goto :action_build_bug4
if /i "%ACTION%"=="uninstall" goto :action_uninstall
goto :action_install

:: ## resolve_latest_edgcpp_release
:: Resolves semantic version aliases ('latest', 'stable', '7.0', 'v7.0.1') to '7.0.1' on Windows.
:resolve_latest_edgcpp_release
if /i "%EDGCPP_VERSION%"=="latest" (
    set "EXACT_VERSION=7.0.1"
) else if /i "%EDGCPP_VERSION%"=="stable" (
    set "EXACT_VERSION=7.0.1"
) else if /i "%EDGCPP_VERSION%"=="7.0" (
    set "EXACT_VERSION=7.0.1"
) else if /i "%EDGCPP_VERSION%"=="v7.0.1" (
    set "EXACT_VERSION=7.0.1"
) else (
    set "EXACT_VERSION=%EDGCPP_VERSION%"
)
exit /b 0

:: ## action_ls
:: Lists installed edgcpp versions under LIBSCRIPT_HOME.
:action_ls
if exist "%LIBSCRIPT_HOME%\edgcpp" dir /b "%LIBSCRIPT_HOME%\edgcpp"
exit /b 0

:: ## action_ls_remote
:: Lists remote edgcpp versions available from GitHub Releases.
:action_ls_remote
echo 7.0.0
echo 7.0.1
echo latest
exit /b 0

:: ## action_use
:: Updates the active edgcpp version alias junction.
:action_use
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp" "default" "%EXACT_VERSION%"
exit /b 0

:: ## action_download
:: Downloads the edgcpp release archive into the local offline cache.
:action_download
if not exist "!LIBSCRIPT_ROOT_DIR!\cache\downloads\edgcpp" mkdir "!LIBSCRIPT_ROOT_DIR!\cache\downloads\edgcpp"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%EDGCPP_ASSET_URL%" "!LIBSCRIPT_ROOT_DIR!\cache\downloads\edgcpp\%EDGCPP_ASSET_NAME%" "%EDGCPP_ASSET_SHA256%"
exit /b 0

:: ## action_install
:: Downloads/extracts the edgcpp v7.0.1 release archive, stages driver wrappers, and updates the default junction.
:action_install
set "TARGET_DIR=%LIBSCRIPT_HOME%\edgcpp\%EXACT_VERSION%-%EDGCPP_FLAVOR%"
set "_meta_ok=1"
if not "%EDGCPP_ASSET_SHA256%"=="" (
    if exist "%TARGET_DIR%\edgcpp-release-metadata.json" (
        findstr /I /C:"\"asset_sha256\": \"%EDGCPP_ASSET_SHA256%\"" "%TARGET_DIR%\edgcpp-release-metadata.json" >nul 2>&1
        if errorlevel 1 set "_meta_ok=0"
    )
)
if "!_meta_ok!"=="1" (
    if exist "%TARGET_DIR%\bin\edgcpp.cmd" (
        if exist "%TARGET_DIR%\bin\cpfe.exe" (
            if exist "%TARGET_DIR%\edgcpp-release-metadata.json" (
                if not "%FORCE_REBUILD%"=="1" (
                    echo [INFO] edgcpp %EXACT_VERSION% ^(%EDGCPP_FLAVOR%^) is already installed at %TARGET_DIR%.
                    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp" "%EXACT_VERSION%" "%EXACT_VERSION%-%EDGCPP_FLAVOR%"
                    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp" "%EDGCPP_FLAVOR%" "%EXACT_VERSION%-%EDGCPP_FLAVOR%"
                    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp" "default" "%EXACT_VERSION%-%EDGCPP_FLAVOR%"
                    exit /b 0
                )
            )
        )
    )
)
if not exist "%TARGET_DIR%\bin" mkdir "%TARGET_DIR%\bin"
if not exist "%TARGET_DIR%\include_c99" mkdir "%TARGET_DIR%\include_c99"
if not exist "%TARGET_DIR%\include_c++" mkdir "%TARGET_DIR%\include_c++"

if not exist "!LIBSCRIPT_ROOT_DIR!\cache\downloads\edgcpp" mkdir "!LIBSCRIPT_ROOT_DIR!\cache\downloads\edgcpp"
set "_dl_zip=!LIBSCRIPT_ROOT_DIR!\cache\downloads\edgcpp\%EDGCPP_ASSET_NAME%"
if "!_meta_ok!"=="0" (
    if exist "!_dl_zip!" del /f /q "!_dl_zip!" >nul 2>&1
)
if not exist "!_dl_zip!" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%EDGCPP_ASSET_URL%" "!_dl_zip!" "%EDGCPP_ASSET_SHA256%"
)
if exist "!_dl_zip!" (
    tar -xf "!_dl_zip!" --strip-components=1 -C "%TARGET_DIR%" 2>nul
    if errorlevel 1 (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '!_dl_zip!' -DestinationPath '%TARGET_DIR%' -Force" 2>nul
    )
)
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edgcpp.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edg-cc.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edgcpp-c-be.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edgcpp-cp-be.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edgcpp-fe-only.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edgcpp-legacy.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edgcpp-gcc-be.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edgcpp-llvm-be.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edg-c++.cmd" >nul
copy /y "!SCRIPT_DIR!\edgcpp_wrapper.cmd" "%TARGET_DIR%\bin\edg-cxx.cmd" >nul
if not exist "%TARGET_DIR%\include_c99\stdint.h" (
    (
        echo #ifndef _EDG_STDINT_H
        echo #define _EDG_STDINT_H
        echo typedef signed char int8_t;
        echo typedef short int16_t;
        echo typedef int int32_t;
        echo typedef long long int64_t;
        echo typedef unsigned char uint8_t;
        echo typedef unsigned short uint16_t;
        echo typedef unsigned int uint32_t;
        echo typedef unsigned long long uint64_t;
        echo typedef long long intptr_t;
        echo typedef unsigned long long uintptr_t;
        echo typedef long long intmax_t;
        echo typedef unsigned long long uintmax_t;
        echo #endif
    ) > "%TARGET_DIR%\include_c99\stdint.h"
)
if not exist "%TARGET_DIR%\include_c99\stddef.h" (
    (
        echo #ifndef _EDG_STDDEF_H
        echo #define _EDG_STDDEF_H
        echo typedef unsigned long long size_t;
        echo typedef long long ptrdiff_t;
        echo #ifndef NULL
        echo #define NULL ^(^(void*^)0^)
        echo #endif
        echo #endif
    ) > "%TARGET_DIR%\include_c99\stddef.h"
)
(
    echo {
    echo   "component": "edgcpp",
    echo   "version": "%EXACT_VERSION%",
    echo   "flavor": "%EDGCPP_FLAVOR%",
    echo   "asset_name": "%EDGCPP_ASSET_NAME%",
    echo   "asset_sha256": "%EDGCPP_ASSET_SHA256%",
    echo   "repository": "https://github.com/SamuelMarks/edgcpp-compiler"
    echo }
) > "%TARGET_DIR%\edgcpp-release-metadata.json.tmp"
move /y "%TARGET_DIR%\edgcpp-release-metadata.json.tmp" "%TARGET_DIR%\edgcpp-release-metadata.json" >nul
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp" "%EXACT_VERSION%" "%EXACT_VERSION%-%EDGCPP_FLAVOR%"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp" "%EDGCPP_FLAVOR%" "%EXACT_VERSION%-%EDGCPP_FLAVOR%"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp" "%EDGCPP_VERSION%" "%EXACT_VERSION%-%EDGCPP_FLAVOR%"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\versioning.cmd" :libscript_symlink_alias "edgcpp" "default" "%EXACT_VERSION%-%EDGCPP_FLAVOR%"
exit /b 0

:: ## action_verify_modes
:: Builds all 4 backend configurations of edgcpp-compiler-multibackend on Windows via CMake.
:action_verify_modes
set "_src_repo=%EDGCPP_SOURCE_DIR%"
if "!_src_repo!"=="" set "_src_repo=%EDG_REPO%"
if not exist "!_src_repo!\CMakeLists.txt" exit /b 1
cmake -S "!_src_repo!" -B "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-modes\both" -DCMAKE_BUILD_TYPE=Release -DEDG_ENABLE_LLVM_BACKEND=ON -DEDG_ENABLE_GCC_BACKEND=ON -DBUILD_TESTING=ON
if errorlevel 1 exit /b 1
cmake --build "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-modes\both"
exit /b !errorlevel!

:: ## action_build_coverage
:: Builds coverage-instrumented edgcpp-compiler-multibackend binaries on Windows.
:action_build_coverage
set "_src_repo=%EDGCPP_SOURCE_DIR%"
if "!_src_repo!"=="" set "_src_repo=%EDG_REPO%"
if not exist "!_src_repo!\CMakeLists.txt" exit /b 1
cmake -S "!_src_repo!" -B "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-llvm-cov" -DCMAKE_BUILD_TYPE=Debug -DEDG_ENABLE_LLVM_BACKEND=ON -DBUILD_TESTING=ON
if errorlevel 1 exit /b 1
cmake --build "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-llvm-cov"
exit /b !errorlevel!

:: ## action_build_bug4
:: Builds isolated Bug #4 legacy array-decay ablation binary on Windows.
:action_build_bug4
set "_src_repo=%EDGCPP_SOURCE_DIR%"
if "!_src_repo!"=="" set "_src_repo=%EDG_REPO%"
if not exist "!_src_repo!\CMakeLists.txt" exit /b 1
cmake -S "!_src_repo!" -B "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-bug4-legacy" -DCMAKE_BUILD_TYPE=Release -DEDG_ENABLE_LLVM_BACKEND=ON -DCMAKE_C_FLAGS="-DEDG_BENCH_LEGACY_ARRAY_DECAY_LOAD=1" -DCMAKE_CXX_FLAGS="-DEDG_BENCH_LEGACY_ARRAY_DECAY_LOAD=1"
if errorlevel 1 exit /b 1
cmake --build "!LIBSCRIPT_ROOT_DIR!\build\edgcpp-bug4-legacy"
exit /b !errorlevel!

:: ## action_uninstall
:: Removes the installed edgcpp version directory.
:action_uninstall
if exist "%LIBSCRIPT_HOME%\edgcpp\%EXACT_VERSION%-%EDGCPP_FLAVOR%" rmdir /s /q "%LIBSCRIPT_HOME%\edgcpp\%EXACT_VERSION%-%EDGCPP_FLAVOR%"
if exist "%LIBSCRIPT_HOME%\edgcpp\%EXACT_VERSION%" rmdir /s /q "%LIBSCRIPT_HOME%\edgcpp\%EXACT_VERSION%"
if exist "%LIBSCRIPT_HOME%\edgcpp\%EDGCPP_FLAVOR%" rmdir /s /q "%LIBSCRIPT_HOME%\edgcpp\%EDGCPP_FLAVOR%"
if exist "%LIBSCRIPT_HOME%\edgcpp\default" rmdir /s /q "%LIBSCRIPT_HOME%\edgcpp\default"
exit /b 0
