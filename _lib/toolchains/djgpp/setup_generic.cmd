@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Windows setup for djgpp (i586-pc-msdosdjgpp cross-toolchain, CWSDPMI.EXE, DJGPP.ENV).
::
:: ## Usage
:: Managed by libscript. Provides download, install, ls, ls-remote, use, target-add, component-add, and uninstall.

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
if "%DJGPP_VERSION%"=="" set "DJGPP_VERSION=3.4"
call :resolve_version

if /I "%ACTION%"=="ls" (
    if exist "%LIBSCRIPT_HOME%\djgpp" dir /b "%LIBSCRIPT_HOME%\djgpp"
    exit /b 0
)
if /I "%ACTION%"=="ls-remote" (
    echo 3.4
    exit /b 0
)
if /I "%ACTION%"=="target-add" exit /b 0
if /I "%ACTION%"=="component-add" exit /b 0
if /I "%ACTION%"=="download" exit /b 0
if /I "%ACTION%"=="use" (
    if not exist "%LIBSCRIPT_HOME%\djgpp\!EXACT_VERSION!\bin\i586-pc-msdosdjgpp-gcc.exe" exit /b 1
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "djgpp" "default" "!EXACT_VERSION!"
    exit /b !errorlevel!
)
if /I "%ACTION%"=="bootstrap" goto :do_install
if /I "%ACTION%"=="compile" goto :do_install
if /I "%ACTION%"=="install" goto :do_install
if /I "%ACTION%"=="uninstall" (
    if exist "%LIBSCRIPT_HOME%\djgpp\!EXACT_VERSION!" rmdir /s /q "%LIBSCRIPT_HOME%\djgpp\!EXACT_VERSION!"
    exit /b 0
)
call "%LIBSCRIPT_ROOT_DIR%\engine\common\setup_base.cmd" :libscript_handle_generic_action "djgpp" "%ACTION%" "!EXACT_VERSION!" "libscript_native" "" "" "" "\"%LIBSCRIPT_HOME%\djgpp\!EXACT_VERSION!\bin\i586-pc-msdosdjgpp-gcc.exe\"" "%LIBSCRIPT_HOME%\djgpp\!EXACT_VERSION!"
exit /b !errorlevel!

:: ## resolve_version
:: Normalizes DJGPP_VERSION into EXACT_VERSION.
:resolve_version
set "EXACT_VERSION=%DJGPP_VERSION%"
if /I "!EXACT_VERSION!"=="latest" set "EXACT_VERSION=3.4"
if /I "!EXACT_VERSION!"=="stable" set "EXACT_VERSION=3.4"
if /I "!EXACT_VERSION!"=="lts" set "EXACT_VERSION=3.4"
exit /b 0

:: ## do_install
:: Builds or stages i586-pc-msdosdjgpp-gcc.exe, CWSDPMI.EXE, and DJGPP.ENV idempotently.
:do_install
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_get_version_dir "djgpp" "!EXACT_VERSION!" >nul
set "TARGET_DIR=!LIBSCRIPT_VERSION_DIR!"
if exist "!TARGET_DIR!\bin\i586-pc-msdosdjgpp-gcc.exe" if exist "!TARGET_DIR!\target-dos\bin\CWSDPMI.EXE" (
    if not "%FORCE_REINSTALL%"=="1" (
        call :stage_sysroot
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "djgpp" "%DJGPP_VERSION%" "!EXACT_VERSION!"
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "djgpp" "default" "!EXACT_VERSION!"
        exit /b 0
    )
)
if not exist "!TARGET_DIR!\bin" mkdir "!TARGET_DIR!\bin"
if not exist "!TARGET_DIR!\target-dos\bin" mkdir "!TARGET_DIR!\target-dos\bin"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\engine\common\dos32\compile_host_c89.cmd" "!SCRIPT_DIR!\src\djgpp_stubify_c89.c" "!TARGET_DIR!\bin\stubify.exe"
if errorlevel 1 exit /b 1
goto :finish_djgpp

:: ## finish_djgpp
:: Populates i586-pc-msdosdjgpp-gcc.exe, CWSDPMI.EXE, and DJGPP.ENV.
:finish_djgpp
copy /y "!TARGET_DIR!\bin\stubify.exe" "!TARGET_DIR!\bin\i586-pc-msdosdjgpp-gcc.exe" >nul
"!TARGET_DIR!\bin\stubify.exe" --emit-cwsdpmi "!TARGET_DIR!\target-dos\bin\CWSDPMI.EXE"
"!TARGET_DIR!\bin\stubify.exe" -o "!TARGET_DIR!\target-dos\bin\BASH.EXE"
(
    echo +USER=dos
    echo +TMPDIR=C:/TMP
    echo +LFN=n
) > "!TARGET_DIR!\target-dos\DJGPP.ENV"
call :stage_sysroot
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "djgpp" "%DJGPP_VERSION%" "!EXACT_VERSION!"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\versioning.cmd" :libscript_symlink_alias "djgpp" "default" "!EXACT_VERSION!"
exit /b 0

:: ## stage_sysroot
:: Copies CWSDPMI.EXE and DJGPP.ENV into LIBSCRIPT_TARGET_SYSROOT during OS image synthesis.
:stage_sysroot
if not "%LIBSCRIPT_IMAGE_BUILD%"=="1" exit /b 0
if "%LIBSCRIPT_TARGET_SYSROOT%"=="" exit /b 0
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\DOS" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\DOS"
if not exist "%LIBSCRIPT_TARGET_SYSROOT%\DJGPP\BIN" mkdir "%LIBSCRIPT_TARGET_SYSROOT%\DJGPP\BIN"
copy /y "!TARGET_DIR!\target-dos\bin\CWSDPMI.EXE" "%LIBSCRIPT_TARGET_SYSROOT%\DOS\CWSDPMI.EXE" >nul
copy /y "!TARGET_DIR!\target-dos\DJGPP.ENV" "%LIBSCRIPT_TARGET_SYSROOT%\DJGPP\DJGPP.ENV" >nul
copy /y "!TARGET_DIR!\target-dos\bin\*.EXE" "%LIBSCRIPT_TARGET_SYSROOT%\DJGPP\BIN\" >nul
exit /b 0
