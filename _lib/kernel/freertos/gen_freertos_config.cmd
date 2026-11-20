@echo off
:: # gen_freertos_config.cmd
::
:: ## Overview
:: Deterministic FreeRTOSConfig.h synthesizer on Windows from declarative parameters.
::
:: ## Usage
:: gen_freertos_config.cmd <out_dir> [os_config_json]

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

set "OUT_DIR=%~1"
if "!OUT_DIR!"=="" (
    echo [ERROR] Usage: gen_freertos_config.cmd ^<out_dir^> [os_config_json] >&2
    exit /b 1
)
if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"

set "PORT=%FREERTOS_PORT%"
if "!PORT!"=="" set "PORT=%LIBSCRIPT_RTOS_BOARD%"
if "!PORT!"=="" set "PORT=win32_sim"
set "HEAP_IMPL=%FREERTOS_HEAP_IMPL%"
if "!HEAP_IMPL!"=="" set "HEAP_IMPL=heap_4"
set "TICK_HZ=%FREERTOS_TICK_RATE_HZ%"
if "!TICK_HZ!"=="" set "TICK_HZ=1000"
set "HEAP_BYTES=%FREERTOS_TOTAL_HEAP_BYTES%"
if "!HEAP_BYTES!"=="" set "HEAP_BYTES=32768"
set "MAX_PRIO=%FREERTOS_MAX_PRIORITIES%"
if "!MAX_PRIO!"=="" set "MAX_PRIO=8"
set "MIN_STACK=%FREERTOS_MINIMAL_STACK_WORDS%"
if "!MIN_STACK!"=="" set "MIN_STACK=128"
set "DYN_ALLOC=1"
if /I "!HEAP_IMPL!"=="static_only" (
    set "DYN_ALLOC=0"
    set "HEAP_BYTES=0"
)

set "HDR=!OUT_DIR!\FreeRTOSConfig.h"
> "!HDR!" echo /* Auto-generated deterministically by LibScript gen_freertos_config.cmd */
>> "!HDR!" echo #ifndef FREERTOS_CONFIG_H
>> "!HDR!" echo #define FREERTOS_CONFIG_H
>> "!HDR!" echo #define configRTOS_PORT_NAME "!PORT!"
>> "!HDR!" echo #define configRTOS_HEAP_IMPL "!HEAP_IMPL!"
>> "!HDR!" echo #define configUSE_PREEMPTION 1
>> "!HDR!" echo #define configUSE_TICKLESS_IDLE 0
>> "!HDR!" echo #define configNUMBER_OF_CORES 1
>> "!HDR!" echo #define configTICK_RATE_HZ ^( ^( uint32_t ^) !TICK_HZ! ^)
>> "!HDR!" echo #define configMAX_PRIORITIES ^( !MAX_PRIO! ^)
>> "!HDR!" echo #define configMINIMAL_STACK_SIZE ^( ^( uint16_t ^) !MIN_STACK! ^)
>> "!HDR!" echo #define configTOTAL_HEAP_SIZE ^( ^( size_t ^) ^( !HEAP_BYTES! ^) ^)
>> "!HDR!" echo #define configSUPPORT_STATIC_ALLOCATION 1
>> "!HDR!" echo #define configSUPPORT_DYNAMIC_ALLOCATION !DYN_ALLOC!
>> "!HDR!" echo #define configUSE_MUTEXES 1
>> "!HDR!" echo #define configUSE_COUNTING_SEMAPHORES 1
>> "!HDR!" echo #define configUSE_TIMERS 1
>> "!HDR!" echo #define configCHECK_FOR_STACK_OVERFLOW 2
>> "!HDR!" echo #endif
> "!OUT_DIR!\heap_selection.txt" echo.!HEAP_IMPL!
exit /b 0
