@echo off
:: # test.cmd
:: ## Overview
:: Test suite for the win-cmd-rs component on Windows (wincheck static analyzer and wincmd interpreter).
::
:: ## Usage
:: Execute this script to perform a component-specific smoke test.

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

call "!SCRIPT_DIR!\env.cmd"
wincheck --version
if errorlevel 1 exit /b 1

set "_WCR_SMOKE=%TEMP%\wcr-smoke-!RANDOM!"
if not exist "!_WCR_SMOKE!" mkdir "!_WCR_SMOKE!"

> "!_WCR_SMOKE!\clean.cmd" echo @echo off
>> "!_WCR_SMOKE!\clean.cmd" echo setlocal EnableDelayedExpansion
>> "!_WCR_SMOKE!\clean.cmd" echo echo^(ok
>> "!_WCR_SMOKE!\clean.cmd" echo exit /b 0

wincheck --severity error "!_WCR_SMOKE!\clean.cmd"
if errorlevel 1 (
    rmdir /s /q "!_WCR_SMOKE!" >nul 2>&1
    echo [FAIL] wincheck rejected valid clean.cmd fixture 1>&2
    exit /b 1
)
echo [PASS] wincheck accepted valid .cmd script

> "!_WCR_SMOKE!\broken.cmd" echo @echo off
>> "!_WCR_SMOKE!\broken.cmd" echo if 1==1 ^(
>> "!_WCR_SMOKE!\broken.cmd" echo     :: illegal block comment
>> "!_WCR_SMOKE!\broken.cmd" echo     echo bad
>> "!_WCR_SMOKE!\broken.cmd" echo ^)

wincheck --severity error "!_WCR_SMOKE!\broken.cmd" >nul 2>&1
if not errorlevel 1 (
    rmdir /s /q "!_WCR_SMOKE!" >nul 2>&1
    echo [FAIL] wincheck failed to flag CMD1001 broken.cmd fixture 1>&2
    exit /b 1
)
echo [PASS] wincheck detected CMD1001 defect in broken .cmd script

> "!_WCR_SMOKE!\arith.cmd" echo @echo off
>> "!_WCR_SMOKE!\arith.cmd" echo setlocal EnableDelayedExpansion
>> "!_WCR_SMOKE!\arith.cmd" echo set /a "X=6*7"
>> "!_WCR_SMOKE!\arith.cmd" echo echo.!X!

where wincmd.exe >nul 2>&1
if not errorlevel 1 (
    wincmd.exe --version
    if errorlevel 1 (
        rmdir /s /q "!_WCR_SMOKE!" >nul 2>&1
        exit /b 1
    )
    set "_WCMD_GOT="
    for /f "delims=" %%R in ('wincmd.exe /C "!_WCR_SMOKE!\arith.cmd" 2^>nul') do (
        set "_WCMD_GOT=%%R"
    )
    if not "!_WCMD_GOT!"=="42" (
        rmdir /s /q "!_WCR_SMOKE!" >nul 2>&1
        echo [FAIL] Expected wincmd arithmetic output 42, got "!_WCMD_GOT!" 1>&2
        exit /b 1
    )
    echo [PASS] wincmd arithmetic evaluation ^(6*7=42^) verified
)
rmdir /s /q "!_WCR_SMOKE!" >nul 2>&1
exit /b 0
