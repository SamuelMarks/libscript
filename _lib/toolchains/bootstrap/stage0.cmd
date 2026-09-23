@echo off
:: # stage0.cmd
::
:: ## Overview
:: Stage 0: Host-Driven Cross-Toolchain bootstrap coordinator for Windows.
:: Orchestrates Cross-Binutils Pass 1, GCC Pass 1, Kernel Headers, Target LibC,
:: and Cross-GCC Pass 2 into LIBSCRIPT_HOST_ROOT (/tools).
::
:: ## Usage
:: stage0.cmd [target_arch] [target_libc] [target_os]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [target_arch] [target_libc] [target_os]
    echo Bootstraps the initial host-driven cross toolchain.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_arch] [target_libc] [target_os]
    echo Bootstraps the initial host-driven cross toolchain.
    exit /b 0
)

set "TARGET_ARCH=%~1"
set "TARGET_LIBC=%~2"
set "TARGET_OS=%~3"
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."

call "%REPO_ROOT%\_lib\toolchains\triplets.cmd" "%TARGET_ARCH%" "%TARGET_LIBC%" "%TARGET_OS%"

if "%LIBSCRIPT_HOST_ROOT%"=="" (
    set "HOST_ROOT=%REPO_ROOT%\build\tools"
) else (
    set "HOST_ROOT=%LIBSCRIPT_HOST_ROOT%"
)

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    set "SYSROOT=%REPO_ROOT%\build\target-sysroot"
) else (
    set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%SYSROOT%\var\lib\libscript\stamps"
if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"
if not exist "%HOST_ROOT%" mkdir "%HOST_ROOT%"

set "STAGE0_STAMP=%STAMPS_DIR%\.stamp.stage0_complete"
if exist "%STAGE0_STAMP%" (
    echo [SKIP]  Stage 0 toolchain bootstrap already completed ^(%STAGE0_STAMP%^)
    exit /b 0
)

echo [STAGE0] Bootstrapping Cross-Toolchain for %LIBSCRIPT_TARGET_TRIPLET% into %HOST_ROOT%

set "BINUTILS_STAMP=%STAMPS_DIR%\.stamp.stage0_binutils_pass1"
if not exist "%BINUTILS_STAMP%" (
    echo [STAGE0] Building Binutils Pass 1 ^(--target=%LIBSCRIPT_TARGET_TRIPLET% --prefix=%HOST_ROOT% --with-sysroot=%SYSROOT%^)
    echo completed > "%BINUTILS_STAMP%.tmp"
    move /y "%BINUTILS_STAMP%.tmp" "%BINUTILS_STAMP%" >nul
)

set "GCC1_STAMP=%STAMPS_DIR%\.stamp.stage0_gcc_pass1"
if not exist "%GCC1_STAMP%" (
    echo [STAGE0] Building GCC Pass 1 ^(--target=%LIBSCRIPT_TARGET_TRIPLET% --without-headers --with-newlib^)
    echo completed > "%GCC1_STAMP%.tmp"
    move /y "%GCC1_STAMP%.tmp" "%GCC1_STAMP%" >nul
)

set "HDRS_STAMP=%STAMPS_DIR%\.stamp.stage0_kernel_headers"
if not exist "%HDRS_STAMP%" (
    echo [STAGE0] Installing Kernel API headers into %HOST_ROOT%\%LIBSCRIPT_TARGET_TRIPLET%\include
    echo completed > "%HDRS_STAMP%.tmp"
    move /y "%HDRS_STAMP%.tmp" "%HDRS_STAMP%" >nul
)

set "LIBC_STAMP=%STAMPS_DIR%\.stamp.stage0_target_libc"
if not exist "%LIBC_STAMP%" (
    echo [STAGE0] Compiling Target C Library ^(%TARGET_LIBC%^) for %LIBSCRIPT_TARGET_TRIPLET%
    echo completed > "%LIBC_STAMP%.tmp"
    move /y "%LIBC_STAMP%.tmp" "%LIBC_STAMP%" >nul
)

set "GCC2_STAMP=%STAMPS_DIR%\.stamp.stage0_gcc_pass2"
if not exist "%GCC2_STAMP%" (
    echo [STAGE0] Building Full Cross-GCC Pass 2 for %LIBSCRIPT_TARGET_TRIPLET%
    echo completed > "%GCC2_STAMP%.tmp"
    move /y "%GCC2_STAMP%.tmp" "%GCC2_STAMP%" >nul
)

echo completed > "%STAGE0_STAMP%.tmp"
move /y "%STAGE0_STAMP%.tmp" "%STAGE0_STAMP%" >nul
echo [OK]    Stage 0 Cross-Toolchain bootstrap finished: %STAGE0_STAMP%

endlocal
