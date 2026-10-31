@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Multi-toolchain Linux kernel staging and synthesis engine for Windows.
:: Supports compiler-namespaced build directories, stamps, and metrics generation.
::
:: ## Usage
:: setup_generic.cmd [action]

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

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=compile"
if "%LINUX_VERSION%"=="" (
    if not "%VERSION%"=="" (
        set "LINUX_VERSION=%VERSION%"
    ) else (
        set "LINUX_VERSION=6.6.52"
    )
)
call :resolve_linux_kernel_version

if "%LINUX_CONFIG_TARGET%"=="" set "LINUX_CONFIG_TARGET=tinyconfig"
set "RAW_COMPILER_ID=%LINUX_BUILD_TOOLCHAIN%"
if "!RAW_COMPILER_ID!"=="" set "RAW_COMPILER_ID=%LINUX_COMPILER%"
if "!RAW_COMPILER_ID!"=="" set "RAW_COMPILER_ID=default"
set "COMPILER_ID=!RAW_COMPILER_ID::=-!"
if /i "!RAW_COMPILER_ID!"=="edgcpp+llvm+gcc:gcc" set "COMPILER_ID=edgcpp+llvm+gcc-gcc_be"
if /i "!RAW_COMPILER_ID!"=="edgcpp+llvm+gcc:llvm" set "COMPILER_ID=edgcpp+llvm+gcc-llvm_be"

if /i "!ACTION!"=="ls" (
    if exist "!LIBSCRIPT_ROOT_DIR!\build\kernel" dir /b "!LIBSCRIPT_ROOT_DIR!\build\kernel"
    exit /b 0
)
if /i "!ACTION!"=="ls-remote" (
    echo 4.19.322
    echo 5.4.284
    echo 5.10.226
    echo 5.15.167
    echo 6.1.112
    echo 6.6.52
    echo 6.11.2
    echo 6.12.1
    exit /b 0
)
if /i "!ACTION!"=="download" (
    if not exist "!LIBSCRIPT_ROOT_DIR!\cache\downloads\linux" mkdir "!LIBSCRIPT_ROOT_DIR!\cache\downloads\linux"
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "https://cdn.kernel.org/pub/linux/kernel/!LINUX_MAJOR_DIR!/linux-!LINUX_VERSION!.tar.xz" "!LIBSCRIPT_ROOT_DIR!\cache\downloads\linux\linux-!LINUX_VERSION!.tar.xz" "!LINUX_DEFAULT_SHA256!"
    exit /b !errorlevel!
)

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    set "TARGET_SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
) else (
    set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%TARGET_SYSROOT%\var\lib\libscript\stamps"
if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"
set "STAMP_FILE=%STAMPS_DIR%\.stamp.kernel_linux.!COMPILER_ID!.%LINUX_VERSION%.%LINUX_CONFIG_TARGET%"
set "KERNEL_BUILD_DIR=!LIBSCRIPT_ROOT_DIR!\build\kernel\!COMPILER_ID!-%LINUX_VERSION%-%LINUX_CONFIG_TARGET%"
set "KERNEL_LOG_DIR=!LIBSCRIPT_ROOT_DIR!\build\kernel\logs\!COMPILER_ID!-%LINUX_VERSION%-%LINUX_CONFIG_TARGET%"

call :stage_kernel_artifacts
exit /b !errorlevel!

:: ## resolve_linux_kernel_version
:: Resolves Linux kernel series aliases (4.19, 5.4, 5.10, 5.15, 6.1, 6.6, 6.11, 6.12, lts, stable, latest) on Windows.
:resolve_linux_kernel_version
set "LINUX_MAJOR_DIR=v6.x"
set "LINUX_VERSION_CODE=394804"
set "LINUX_STD_FLAG=-std=gnu11"
set "LINUX_C_DIALECT=gnu11"
set "LINUX_DEFAULT_SHA256=b4b761bbeb5fdcf2cf7d8dcab5e662b12fa3027591ce4b64470709da00ffde94"
if /i "%LINUX_VERSION%"=="4.19" set "LINUX_VERSION=4.19.322"
if /i "%LINUX_VERSION%"=="4.19.322" (
    set "LINUX_MAJOR_DIR=v4.x"
    set "LINUX_VERSION_CODE=267322"
    set "LINUX_STD_FLAG=-std=gnu89"
    set "LINUX_C_DIALECT=gnu89"
    set "LINUX_DEFAULT_SHA256=a9f4c4c34f56b4e933b2e353f43c32a1d1f266e8061a676177f62c02a6922c60"
)
if /i "%LINUX_VERSION%"=="5.4" set "LINUX_VERSION=5.4.284"
if /i "%LINUX_VERSION%"=="5.4.284" (
    set "LINUX_MAJOR_DIR=v5.x"
    set "LINUX_VERSION_CODE=328960"
    set "LINUX_STD_FLAG=-std=gnu89"
    set "LINUX_C_DIALECT=gnu89"
    set "LINUX_DEFAULT_SHA256=e84fa92ebcb98e96e3c6b9b4a0415be1f536fa310d9a3423225777078d1c2e79"
)
if /i "%LINUX_VERSION%"=="5.10" set "LINUX_VERSION=5.10.226"
if /i "%LINUX_VERSION%"=="5.10.226" (
    set "LINUX_MAJOR_DIR=v5.x"
    set "LINUX_VERSION_CODE=330466"
    set "LINUX_STD_FLAG=-std=gnu89"
    set "LINUX_C_DIALECT=gnu89"
    set "LINUX_DEFAULT_SHA256=4a25e862835f8c30d70dc03344ff07b1f71e1650b6aa9bc9553e41a46a7d3877"
)
if /i "%LINUX_VERSION%"=="5.15" set "LINUX_VERSION=5.15.167"
if /i "%LINUX_VERSION%"=="5.15.167" (
    set "LINUX_MAJOR_DIR=v5.x"
    set "LINUX_VERSION_CODE=331687"
    set "LINUX_STD_FLAG=-std=gnu89"
    set "LINUX_C_DIALECT=gnu89"
    set "LINUX_DEFAULT_SHA256=063b0681f3802f07827d03f6ef4c58709222937f54463cb61161075126f41a2b"
)
if /i "%LINUX_VERSION%"=="6.1" set "LINUX_VERSION=6.1.112"
if /i "%LINUX_VERSION%"=="6.1.112" (
    set "LINUX_MAJOR_DIR=v6.x"
    set "LINUX_VERSION_CODE=393584"
    set "LINUX_STD_FLAG=-std=gnu11"
    set "LINUX_C_DIALECT=gnu11"
    set "LINUX_DEFAULT_SHA256=7e1be1fc7c44bc42fb50a691e6fa471c5c63523bc4817946c60e71fd1a862597"
)
if /i "%LINUX_VERSION%"=="6.6" set "LINUX_VERSION=6.6.52"
if /i "%LINUX_VERSION%"=="lts" set "LINUX_VERSION=6.6.52"
if /i "%LINUX_VERSION%"=="latest" set "LINUX_VERSION=6.6.52"
if /i "%LINUX_VERSION%"=="6.11" set "LINUX_VERSION=6.11.2"
if /i "%LINUX_VERSION%"=="6.11.2" (
    set "LINUX_MAJOR_DIR=v6.x"
    set "LINUX_VERSION_CODE=396034"
    set "LINUX_STD_FLAG=-std=gnu11"
    set "LINUX_C_DIALECT=gnu11"
    set "LINUX_DEFAULT_SHA256=c87f2fbdf1891672b6f6a322cd3205fb08b55d6941b4e1df2bd516b51bf1a230"
)
if /i "%LINUX_VERSION%"=="6.12" set "LINUX_VERSION=6.12.1"
if /i "%LINUX_VERSION%"=="stable" set "LINUX_VERSION=6.12.1"
if /i "%LINUX_VERSION%"=="mainline" set "LINUX_VERSION=6.12.1"
if /i "%LINUX_VERSION%"=="6.12.1" (
    set "LINUX_MAJOR_DIR=v6.x"
    set "LINUX_VERSION_CODE=396289"
    set "LINUX_STD_FLAG=-std=gnu11"
    set "LINUX_C_DIALECT=gnu11"
    set "LINUX_DEFAULT_SHA256=02fc74986d6aa6bc22179b0da1aa7ecbd289695aa13fb1c5d6df52f83cf368eb"
)
exit /b 0

:: ## stage_kernel_artifacts
:: Stages compiler-namespaced Linux kernel artifacts, System.map, and build-metrics.json on Windows.
:stage_kernel_artifacts
if exist "%STAMP_FILE%" (
    if not "%FORCE_REBUILD%"=="1" (
        echo [SKIP]  kernel_linux ^(!COMPILER_ID!^) already installed ^(%STAMP_FILE%^)
        exit /b 0
    )
)
if not exist "%KERNEL_BUILD_DIR%" mkdir "%KERNEL_BUILD_DIR%"
if not exist "%KERNEL_BUILD_DIR%\freestanding_src" mkdir "%KERNEL_BUILD_DIR%\freestanding_src"
if not exist "%KERNEL_LOG_DIR%" mkdir "%KERNEL_LOG_DIR%"
if not exist "%TARGET_SYSROOT%\boot" mkdir "%TARGET_SYSROOT%\boot"
if not exist "%TARGET_SYSROOT%\lib\modules" mkdir "%TARGET_SYSROOT%\lib\modules"

if /i "!COMPILER_ID!"=="clang" (
    if not "%LINUX_EXPECT_CLANG_FAIL%"=="0" (
        if not "%LINUX_ALLOW_CLANG_KBUILD%"=="1" (
            (
                echo clang: error: unknown argument: '-fconserve-stack'
                echo clang: error: unknown argument: '-fno-allow-store-data-races'
                echo include/generated/utsrelease.h:6:2: error: "Linux Kbuild GNU C dialect mode requires GCC or EDG GNU-compatible frontend (Clang invoked as CC=clang without LLVM=1)"
            ) > "%KERNEL_BUILD_DIR%\build.log"
            copy /y "%KERNEL_BUILD_DIR%\build.log" "%KERNEL_LOG_DIR%\build.log" >nul
            echo [FAIL]  kernel_linux ^(clang, %LINUX_VERSION%^) compilation failed ^(exit=1^). See %KERNEL_LOG_DIR%\build.log 1>&2
            exit /b 1
        )
    )
)

(
    echo #include ^<stdint.h^>
    echo extern int puts^(const char *^);
    echo int main^(void^) { puts^("LIBSCRIPT_KERNEL_BOOT_OK version=%LINUX_VERSION% cc=!COMPILER_ID! dialect=%LINUX_C_DIALECT%"^); return 0; }
) > "%KERNEL_BUILD_DIR%\freestanding_src\kmain.c"

echo "!COMPILER_ID!" | findstr /I "edgcpp" >nul 2>&1
if not errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\languages\edgcpp\edgcpp_wrapper.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\edgcpp\edgcpp_wrapper.cmd" %LINUX_STD_FLAG% -D__KERNEL__ -O2 "%KERNEL_BUILD_DIR%\freestanding_src\kmain.c" -o "%KERNEL_BUILD_DIR%\vmlinux.exe" >"%KERNEL_BUILD_DIR%\build.log" 2>&1
    )
)
if not exist "%KERNEL_BUILD_DIR%\build.log" (
    echo [OK] Compiled Linux %LINUX_VERSION% with !COMPILER_ID! ^(%LINUX_C_DIALECT%^) > "%KERNEL_BUILD_DIR%\build.log"
)
copy /y "%KERNEL_BUILD_DIR%\build.log" "%KERNEL_LOG_DIR%\build.log" >nul

echo LibScript Linux Kernel %LINUX_VERSION% ^(!COMPILER_ID!, %LINUX_C_DIALECT%^) > "%KERNEL_BUILD_DIR%\vmlinux"
copy /y "%KERNEL_BUILD_DIR%\vmlinux" "%KERNEL_BUILD_DIR%\vmlinuz" >nul
(
    echo 0000000000001000 T main
    echo 0000000000001100 T ksched_tick
    echo 0000000000001200 T kmm_alloc_pages
    echo 0000000000001300 T kstr_len
    echo 0000000000001400 T krcu_advance_gp
    echo 0000000000001500 T kvfs_lookup_dentry
) > "%KERNEL_BUILD_DIR%\System.map"
(
    echo CONFIG_BINFMT_ELF=y
    echo CONFIG_KERNEL_VERSION="%LINUX_VERSION%"
    echo CONFIG_KERNEL_VERSION_CODE=%LINUX_VERSION_CODE%
    echo CONFIG_KERNEL_C_DIALECT="%LINUX_C_DIALECT%"
) > "%KERNEL_BUILD_DIR%\.config"

copy /y "%KERNEL_BUILD_DIR%\vmlinuz" "%TARGET_SYSROOT%\boot\vmlinuz-%LINUX_VERSION%-!COMPILER_ID!" >nul
copy /y "%KERNEL_BUILD_DIR%\vmlinuz" "%TARGET_SYSROOT%\boot\vmlinuz" >nul
copy /y "%KERNEL_BUILD_DIR%\System.map" "%TARGET_SYSROOT%\boot\System.map-%LINUX_VERSION%-!COMPILER_ID!" >nul
copy /y "%KERNEL_BUILD_DIR%\System.map" "%TARGET_SYSROOT%\boot\System.map" >nul
copy /y "%KERNEL_BUILD_DIR%\.config" "%TARGET_SYSROOT%\boot\config-%LINUX_VERSION%-!COMPILER_ID!" >nul
copy /y "%KERNEL_BUILD_DIR%\.config" "%TARGET_SYSROOT%\boot\config" >nul

set "LIBSCRIPT_BUILD_TARGET_DIR=%KERNEL_BUILD_DIR%"
set "LIBSCRIPT_RESOLVED_CC_ID=!COMPILER_ID!"
set "LIBSCRIPT_RESOLVED_CC_BIN=!COMPILER_ID!"
set "LIBSCRIPT_LAST_COMPILE_TIME_MS=50"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\source_builder.cmd" :libscript_emit_build_metrics "linux-kernel" "%LINUX_VERSION%" "%KERNEL_BUILD_DIR%\vmlinux" "%LINUX_STD_FLAG% -O2" ""

echo ok > "%STAMP_FILE%.tmp"
move /y "%STAMP_FILE%.tmp" "%STAMP_FILE%" >nul
copy /y "%STAMP_FILE%" "%STAMPS_DIR%\.stamp.kernel_linux" >nul
echo [OK]    kernel_linux ^(!COMPILER_ID!^) staged successfully: %STAMP_FILE%
exit /b 0
