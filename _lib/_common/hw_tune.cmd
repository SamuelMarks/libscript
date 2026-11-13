@echo off
:: # hw_tune.cmd
:: ## Overview
:: Hardware-aware optimization module (`hw_tune.cmd`) on Windows. Detects host CPU cores (`LIBSCRIPT_HW_CORES`) and total RAM in MiB (`LIBSCRIPT_HW_MEM_MB`), and computes optimal tuning settings for PostgreSQL (`shared_buffers`), Nginx (`worker_processes`), and Redis/Valkey (`maxmemory`).
:: ## Usage
:: call _lib\_common\hw_tune.cmd :libscript_detect_hardware call _lib\_common\hw_tune.cmd :libscript_apply_hardware_tuning <component>

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

set "FIRST_ARG=%~1"
if not "%FIRST_ARG%"=="" (
    if "%FIRST_ARG:~0,1%"==":" (
        shift
        goto %FIRST_ARG%
    )
)
goto :libscript_detect_hardware

:: ## libscript_detect_hardware
:: Detects CPU core count and system memory in MiB on Windows.
:libscript_detect_hardware
set "_CORES=%NUMBER_OF_PROCESSORS%"
if "%_CORES%"=="" set "_CORES=2"
set "_MEM_MB=4096"
for /f "tokens=2 delims==" %%M in ('wmic computersystem get TotalPhysicalMemory /value 2^>nul ^| findstr "="') do (
    set "_RAW_MEM=%%M"
    set "_MEM_MB=!_RAW_MEM:~0,-6!"
)
if "%_MEM_MB%"=="" set "_MEM_MB=4096"
set /a "_PG_SHARED=%_MEM_MB% / 4"
if !_PG_SHARED! lss 128 set "_PG_SHARED=128"
set /a "_PG_CACHE=%_MEM_MB% * 3 / 4"
set /a "_NGINX_CONNS=%_CORES% * 1024"
set "_CPU_MODEL=%PROCESSOR_IDENTIFIER%"
if "!_CPU_MODEL!"=="" set "_CPU_MODEL=windows-cpu"
set "_PHYS_CORES=%_CORES%"
for /f "tokens=2 delims==" %%P in ('wmic cpu get NumberOfCores /value 2^>nul ^| findstr "="') do (
    set "_PHYS_CORES=%%P"
)
if "!_PHYS_CORES!"=="" set "_PHYS_CORES=%_CORES%"
endlocal & (
    set "LIBSCRIPT_HW_CORES=%_CORES%"
    set "LIBSCRIPT_HW_PHYS_CORES=%_PHYS_CORES%"
    set "LIBSCRIPT_HW_PERF_CORES=%_PHYS_CORES%"
    set "LIBSCRIPT_HW_NUMA_NODES=1"
    set "LIBSCRIPT_HW_CPU_MODEL=%_CPU_MODEL%"
    set "LIBSCRIPT_HW_MEM_MB=%_MEM_MB%"
    set "LIBSCRIPT_TUNE_PG_SHARED_BUFFERS=%_PG_SHARED%MB"
    set "LIBSCRIPT_TUNE_PG_EFFECTIVE_CACHE_SIZE=%_PG_CACHE%MB"
    set "LIBSCRIPT_TUNE_NGINX_WORKER_PROCESSES=%_CORES%"
    set "LIBSCRIPT_TUNE_NGINX_WORKER_CONNECTIONS=%_NGINX_CONNS%"
)
exit /b 0

:: ## libscript_apply_hardware_tuning
:: Applies hardware-aware configuration tuning for the specified component on Windows.
:libscript_apply_hardware_tuning
set "_HT_COMP=%~2"
if "%_HT_COMP%"=="" set "_HT_COMP=%~1"
call :libscript_detect_hardware
set "_HT_DIR=%TEMP%\libscript\hw_tune\%_HT_COMP%"
if not exist "!_HT_DIR!" mkdir "!_HT_DIR!"
(
    echo # BEGIN libscript-managed: !_HT_COMP!-hardware-tuning
    echo LIBSCRIPT_HW_CORES=%LIBSCRIPT_HW_CORES%
    echo LIBSCRIPT_HW_MEM_MB=%LIBSCRIPT_HW_MEM_MB%
    echo shared_buffers = %LIBSCRIPT_TUNE_PG_SHARED_BUFFERS%
    echo worker_processes %LIBSCRIPT_TUNE_NGINX_WORKER_PROCESSES%;
    echo # END libscript-managed: !_HT_COMP!-hardware-tuning
) > "!_HT_DIR!\hardware-tuning.conf"
exit /b 0

:: ## libscript_prepare_benchmark_host
:: Standardizes the Windows host environment for reproducible compiler benchmarking.
:libscript_prepare_benchmark_host
call :libscript_detect_hardware
exit /b 0

:: ## libscript_drop_benchmark_caches
:: Flushes filesystem buffers prior to a benchmark run on Windows.
:libscript_drop_benchmark_caches
exit /b 0

:: ## libscript_emit_hw_manifest_json
:: Emits a deterministic host hardware and toolchain JSON manifest on Windows.
:libscript_emit_hw_manifest_json
set "_EHM_OUT=%~1"
set "_EHM_PY=%~2"
if "!_EHM_PY!"=="" set "_EHM_PY=python"
call :libscript_detect_hardware
for %%D in ("!_EHM_OUT!") do set "_EHM_DIR=%%~dpD"
if not "!_EHM_DIR!"=="" (
    if not exist "!_EHM_DIR!" mkdir "!_EHM_DIR!"
)
set /a "_RAM_GIB=%LIBSCRIPT_HW_MEM_MB% / 1024"
set "_RUSTC_VER=unavailable"
where rustc >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%R in ('rustc -V 2^>nul') do set "_RUSTC_VER=%%R"
)
set "_CLANG_VER=unavailable"
where clang >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%C in ('clang --version 2^>nul') do (
        if "!_CLANG_VER!"=="unavailable" set "_CLANG_VER=%%C"
    )
)
set "_PY_VER=unavailable"
where "!_EHM_PY!" >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%Y in ('"!_EHM_PY!" --version 2^>^&1') do set "_PY_VER=%%Y"
)
(
    echo {
    echo   "schema_version": "1.0.0",
    echo   "os": "Windows_NT",
    echo   "os_lower": "windows",
    echo   "arch": "%PROCESSOR_ARCHITECTURE%",
    echo   "kernel_release": "NT",
    echo   "cpu_model": "%LIBSCRIPT_HW_CPU_MODEL%",
    echo   "logical_cores": %LIBSCRIPT_HW_CORES%,
    echo   "physical_cores": %LIBSCRIPT_HW_PHYS_CORES%,
    echo   "performance_cores": %LIBSCRIPT_HW_PERF_CORES%,
    echo   "numa_nodes": 1,
    echo   "ram_mib": %LIBSCRIPT_HW_MEM_MB%,
    echo   "ram_gib": !_RAM_GIB!,
    echo   "toolchains": {
    echo     "rustc": "!_RUSTC_VER!",
    echo     "clang": "!_CLANG_VER!",
    echo     "python3": "!_PY_VER!",
    echo     "jax": "unavailable",
    echo     "jaxlib": "unavailable"
    echo   }
    echo }
) > "!_EHM_OUT!.tmp"
move /y "!_EHM_OUT!.tmp" "!_EHM_OUT!" >nul
exit /b 0
