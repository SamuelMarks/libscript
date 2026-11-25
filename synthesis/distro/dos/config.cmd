@echo off
:: # config.cmd
::
:: ## Overview
:: Generates CRLF CONFIG.SYS / FDCONFIG.SYS and AUTOEXEC.BAT on Windows and validates via dos_batch_lint.cmd.
::
:: ## Usage
:: synthesis\distro\dos\config.cmd [sysroot_dir]

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

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_ROOT_DIR%\build\dos-sysroot"
if not exist "!SYSROOT!" mkdir "!SYSROOT!"

set "DOS_OS=%LIBSCRIPT_TARGET_OS%"
if "!DOS_OS!"=="" set "DOS_OS=freedos"
set "DOS_VER=%LIBSCRIPT_DOS_VERSION%"
if "!DOS_VER!"=="" set "DOS_VER=1.4"
set "STRATUM=%LIBSCRIPT_DOS_STRATUM%"
if "!STRATUM!"=="" set "STRATUM=dos32-dpmi"
set "SHELL_PROV=%LIBSCRIPT_DOS_SHELL_PROVIDER%"
if "!SHELL_PROV!"=="" set "SHELL_PROV=default"

if /I "!STRATUM!"=="dos16-fcb" (
    (
        echo @ECHO OFF
        echo ECHO [LIBSCRIPT] MS-DOS !DOS_VER! flat FCB boot complete
        echo WINCMD1.COM
        echo ECHO [PASS] MSDOS_125_WINCMD1_ASM
    ) > "!SYSROOT!\AUTOEXEC.BAT"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_batch_lint.cmd" "--mode=lint" "!SYSROOT!\AUTOEXEC.BAT"
    exit /b !errorlevel!
)

set "SHELL_LINE=SHELL=C:\COMMAND.COM C:\ /E:1024 /P"
if /I "!SHELL_PROV!"=="win-cmd-asm" set "SHELL_LINE=SHELL=C:\DOS\WINCMD.COM C:\DOS /E:1024 /P"
if /I "!SHELL_PROV!"=="freecom" set "SHELL_LINE=SHELL=C:\DOS\COMMAND.COM C:\DOS /E:1024 /P"

(
    echo FILES=40
    echo BUFFERS=20
    echo LASTDRIVE=Z
) > "!SYSROOT!\CONFIG.SYS"
>> "!SYSROOT!\CONFIG.SYS" echo(!SHELL_LINE!
if /I "!DOS_OS!"=="freedos" copy /y "!SYSROOT!\CONFIG.SYS" "!SYSROOT!\FDCONFIG.SYS" >nul

(
    echo @ECHO OFF
    if /I "!STRATUM!"=="dos32-dpmi" (
        echo SET PATH=C:\DOS;C:\DJGPP\BIN;C:\LIBSCRIP\BIN
        echo SET DJGPP=C:\DJGPP\DJGPP.ENV
        echo SET LFN=n
        echo SET TMPDIR=C:\TMP
        echo SET TEMP=C:\TMP
        echo SET WATTCP.CFG=C:\ETC
        echo ECHO [LIBSCRIPT] !DOS_OS! !DOS_VER! ^(dos32-dpmi^) ready
    ) else (
        echo SET PATH=C:\DOS;C:\LIBSCRIP\BIN
        echo ECHO [LIBSCRIPT] !DOS_OS! !DOS_VER! ^(dos16-handle^) ready
        echo ECHO [PASS] MSDOS_20_WINCMD_ASM
    )
    if exist "!SYSROOT!\ETC\TRAITS\*.BAT" (
        for %%B in ("!SYSROOT!\ETC\TRAITS\*.BAT") do echo CALL C:\ETC\TRAITS\%%~nxB
    )
) > "!SYSROOT!\AUTOEXEC.BAT"

if /I not "!SHELL_PROV!"=="win-cmd-asm" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_batch_lint.cmd" "--mode=lint" "!SYSROOT!\AUTOEXEC.BAT"
    if errorlevel 1 exit /b 1
)
exit /b 0
