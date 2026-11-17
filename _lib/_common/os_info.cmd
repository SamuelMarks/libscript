@echo off
:: # os_info.cmd
:: ## Overview
:: Detects and exports environment variables describing the Windows operating system and architecture.
:: ## Usage
:: Call this script to initialize OS, TARGET_OS, ARCH, and PKG_MGR variables on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

:: ## detect_os_info
:: Detects the host operating system, distribution, and CPU architecture.
:detect_os_info
set "_ORIG_OS=%OS%"
set "OS=Windows_NT"
set "TARGET_OS=windows"
set "PKG_OS=windows"
set "IS_REACTOS=0"
set "IS_MSDOS=0"
set "TARGET_OS_FLAVOR=windows"
set "UNAME=Windows_NT"
set "UNAME_LOWER=windows"
set "INIT_SYS=windows-scm"
set "KERNEL_RELEASE=10.0"

set "_NATIVE_DOS=0"
if /i "%_ORIG_OS%"=="MS-DOS" ( set "IS_MSDOS=1" & set "_NATIVE_DOS=1" )
if /i "%_ORIG_OS%"=="DOS" ( set "IS_MSDOS=1" & set "_NATIVE_DOS=1" )
if /i "%LIBSCRIPT_TARGET_OS%"=="msdos" set "IS_MSDOS=1"
if /i "%LIBSCRIPT_TARGET_OS%"=="dos" set "IS_MSDOS=1"
if /i "%LIBSCRIPT_TARGET_OS%"=="dos32" set "IS_MSDOS=1"
if "!IS_MSDOS!"=="0" (
    ver 2>nul | findstr /I "MS-DOS FreeDOS DR-DOS PC-DOS" >nul 2>&1
    if not errorlevel 1 (
        set "IS_MSDOS=1"
        set "_NATIVE_DOS=1"
    )
)

ver 2>nul | findstr /I "ReactOS" >nul 2>&1
if not errorlevel 1 set "IS_REACTOS=1"
if "!IS_REACTOS!"=="0" (
    if "!IS_MSDOS!"=="0" (
        reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2>nul | findstr /I "ReactOS" >nul 2>&1
        if not errorlevel 1 set "IS_REACTOS=1"
    )
)
if /i "%LIBSCRIPT_TARGET_OS%"=="reactos" set "IS_REACTOS=1"

if "!IS_MSDOS!"=="1" (
    set "OS=MS-DOS"
    set "TARGET_OS=msdos"
    set "PKG_OS=msdos"
    set "TARGET_OS_FLAVOR=msdos"
    set "INIT_SYS=none"
    set "KERNEL_RELEASE=6.22"
    set "UNAME=MS-DOS"
    set "UNAME_LOWER=msdos"
) else if "!IS_REACTOS!"=="1" (
    set "TARGET_OS_FLAVOR=reactos"
    set "INIT_SYS=nt-scm"
    set "KERNEL_RELEASE=5.2"
    set "UNAME=ReactOS"
    if /i "%LIBSCRIPT_TARGET_OS%"=="reactos" (
        set "TARGET_OS=reactos"
        set "UNAME_LOWER=reactos"
    )
)
set "UNAME_A=!UNAME! !KERNEL_RELEASE! %PROCESSOR_ARCHITECTURE%"

if "!IS_MSDOS!"=="1" (
    set "ARCH=i386"
    set "ARCH_ALT=dos32"
) else if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "ARCH=x86_64"
    set "ARCH_ALT=amd64"
) else if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "ARCH=aarch64"
    set "ARCH_ALT=arm64"
) else if /i "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set "ARCH=i686"
    set "ARCH_ALT=386"
    if "!IS_REACTOS!"=="0" (
        if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
            set "ARCH=x86_64"
            set "ARCH_ALT=amd64"
        )
    )
) else (
    set "ARCH=%PROCESSOR_ARCHITECTURE%"
    set "ARCH_ALT=%PROCESSOR_ARCHITECTURE%"
)
if not "%LIBSCRIPT_TARGET_ARCH%"=="" (
    set "ARCH=%LIBSCRIPT_TARGET_ARCH%"
)
set "TARGET_ARCH=!ARCH!"
set "LIBSCRIPT_ARCH=!ARCH!"

set "NEW_PATH=!PATH!"
set "_ROS_SYSDRIVE=%SystemDrive%"
if "!_ROS_SYSDRIVE!"=="" set "_ROS_SYSDRIVE=C:"
set "_ROS_BOOT_BIN=!_ROS_SYSDRIVE!\libscript\bootstrap\bin"
if exist "!_ROS_BOOT_BIN!" (
    echo ";!NEW_PATH!;" | findstr /I /C:";!_ROS_BOOT_BIN!;" >nul 2>&1
    if errorlevel 1 set "NEW_PATH=!_ROS_BOOT_BIN!;!NEW_PATH!"
)

if defined LIBSCRIPT_PKG_MGR (
    set "PKG_MGR=%LIBSCRIPT_PKG_MGR%"
) else if "!IS_MSDOS!"=="1" (
    set "PKG_MGR=libscript"
) else if "!IS_REACTOS!"=="1" (
    set "PKG_MGR=rapps"
) else (
    where rapps.exe >nul 2>&1
    if not errorlevel 1 (
        set "PKG_MGR=rapps"
    ) else (
        where winget >nul 2>&1
        if not errorlevel 1 (
            set "PKG_MGR=winget"
        ) else (
            where choco >nul 2>&1
            if not errorlevel 1 (
                set "PKG_MGR=choco"
            ) else (
                where scoop >nul 2>&1
                if not errorlevel 1 (
                    set "PKG_MGR=scoop"
                ) else (
                    set "PKG_MGR=libscript"
                )
            )
        )
    )
)

set "_OUT_HOME=%LIBSCRIPT_HOME%"
set "_OUT_DOS83=%LIBSCRIPT_DOS_83%"
if "!IS_MSDOS!"=="1" (
    if "!_OUT_HOME!"=="" set "_OUT_HOME=C:\LIBSCRIP"
    if "!_NATIVE_DOS!"=="1" if "!_OUT_DOS83!"=="" set "_OUT_DOS83=1"
)

endlocal & (
    set "OS=%OS%"
    set "TARGET_OS=%TARGET_OS%"
    set "PKG_OS=%PKG_OS%"
    set "IS_REACTOS=%IS_REACTOS%"
    set "IS_MSDOS=%IS_MSDOS%"
    set "TARGET_OS_FLAVOR=%TARGET_OS_FLAVOR%"
    set "UNAME=%UNAME%"
    set "UNAME_LOWER=%UNAME_LOWER%"
    set "INIT_SYS=%INIT_SYS%"
    set "KERNEL_RELEASE=%KERNEL_RELEASE%"
    set "UNAME_A=%UNAME_A%"
    set "ARCH=%ARCH%"
    set "ARCH_ALT=%ARCH_ALT%"
    set "TARGET_ARCH=%TARGET_ARCH%"
    set "LIBSCRIPT_ARCH=%LIBSCRIPT_ARCH%"
    set "PKG_MGR=%PKG_MGR%"
    set "PATH=%NEW_PATH%"
    set "LIBSCRIPT_ROOT_DIR=%LIBSCRIPT_ROOT_DIR%"
    set "LIBSCRIPT_HOME=%_OUT_HOME%"
    set "LIBSCRIPT_DOS_83=%_OUT_DOS83%"
    set "STACK=%STACK%"
)
exit /b 0
