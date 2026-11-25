@echo off
:: # dos_83.cmd
::
:: ## Overview
:: MS-DOS FAT16 8.3 filename and path prefix helper (`LIBSCRIPT_DOS_83=1` / `IS_MSDOS=1`).
:: Maps long or hyphenated LibScript component directory names (`freebsd-usr-bin` -> `FBSDUBIN`,
:: `sqlite-tools` -> `SQLITETL`) via `engine\common\dos_83_map.tsv` and normalizes default
:: `LIBSCRIPT_HOME` (`C:\LIBSCRIP`) and multi-dot version segments (`15.0.0` -> `15_0_0`).
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\engine\common\dos_83.cmd" :libscript_dos83_comp "freebsd-usr-bin"

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

if "%~1"=="" exit /b 0
set "_D83_SUB=%~1"
if "!_D83_SUB:~0,1!"==":" (
    shift
    goto !_D83_SUB!
)
goto :!_D83_SUB!

:: ## libscript_dos83_enabled
:: Exits 0 if MS-DOS / 8.3 component mapping is enabled, or 1 if disabled.
:libscript_dos83_enabled
if "%LIBSCRIPT_DOS_83%"=="0" exit /b 1
if "%LIBSCRIPT_DOS_83%"=="1" exit /b 0
if "%IS_MSDOS%"=="1" exit /b 0
if /i "%TARGET_OS%"=="msdos" exit /b 0
if /i "%LIBSCRIPT_TARGET_OS%"=="msdos" exit /b 0
if /i "%LIBSCRIPT_TARGET_OS%"=="dos" exit /b 0
if /i "%LIBSCRIPT_TARGET_OS%"=="dos32" exit /b 0
exit /b 1

:: ## libscript_dos83_home
:: Resolves and exports DOS83_HOME (C:\LIBSCRIP on MS-DOS when LIBSCRIPT_HOME is unset).
:libscript_dos83_home
if not "%LIBSCRIPT_HOME%"=="" (
    set "_OUT_H=%LIBSCRIPT_HOME%"
    goto :emit_home
)
call :libscript_dos83_enabled
if not errorlevel 1 (
    set "_OUT_H=C:\LIBSCRIP"
) else (
    set "_OUT_H=%USERPROFILE%\.libscript"
)
goto :emit_home

:: ## emit_home
:: Exports DOS83_HOME across endlocal scope and echoes the resolved path.
:emit_home
echo.!_OUT_H!
endlocal & set "DOS83_HOME=%_OUT_H%"
exit /b 0

:: ## libscript_dos83_comp
:: Maps a component name to its 8.3 uppercase directory name via dos_83_map.tsv when MS-DOS / 8.3 mode is active.
:libscript_dos83_comp
set "_IN_C=%~1"
call :libscript_dos83_enabled
if errorlevel 1 (
    set "_OUT_C=!_IN_C!"
    goto :emit_comp
)
set "_OUT_C="
set "_TSV=!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83_map.tsv"
if exist "!_TSV!" (
    for /f "usebackq tokens=1,2" %%A in ("!_TSV!") do (
        set "_R1=%%A"
        if not "!_R1:~0,1!"=="#" (
            if /i "%%A"=="!_IN_C!" set "_OUT_C=%%B"
        )
    )
)
if "!_OUT_C!"=="" (
    set "_TMP_C=!_IN_C:-=!"
    set "_TMP_C=!_TMP_C:_=!"
    set "_TMP_C=!_TMP_C:.=!"
    for %%U in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do set "_TMP_C=!_TMP_C:%%U=%%U!"
    set "_OUT_C=!_TMP_C:~0,8!"
    if "!_OUT_C!"=="" set "_OUT_C=COMP"
)
goto :emit_comp

:: ## emit_comp
:: Exports DOS83_COMP across endlocal scope and echoes the mapped directory name.
:emit_comp
echo.!_OUT_C!
endlocal & set "DOS83_COMP=%_OUT_C%"
exit /b 0

:: ## libscript_dos83_ver
:: Normalizes a version token to strict FAT16 8.3 rules when LIBSCRIPT_DOS_83=1.
:libscript_dos83_ver
set "_IN_V=%~1"
if not "%LIBSCRIPT_DOS_83%"=="1" (
    set "_OUT_V=!_IN_V!"
    goto :emit_ver
)
if /i "!_IN_V:~0,1!"=="v" set "_IN_V=!_IN_V:~1!"
set "_TMP_V=!_IN_V:.=_!"
set "_TMP_V=!_TMP_V:-=_!"
set "_TMP_V=!_TMP_V:+=_!"
for %%U in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do set "_TMP_V=!_TMP_V:%%U=%%U!"
set "_OUT_V=!_TMP_V:~0,8!"
if "!_OUT_V!"=="" set "_OUT_V=VER"
goto :emit_ver

:: ## emit_ver
:: Exports DOS83_VER across endlocal scope and echoes the normalized version directory name.
:emit_ver
echo.!_OUT_V!
endlocal & set "DOS83_VER=%_OUT_V%"
exit /b 0

:: ## libscript_dos83_link_compat
:: Creates a convenience junction <home>\<orig_comp> -> <mapped_comp> when cross-staging on NTFS without strict LIBSCRIPT_DOS_83=1.
:libscript_dos83_link_compat
set "_LC_H=%~1"
set "_LC_O=%~2"
set "_LC_M=%~3"
if "%LIBSCRIPT_DOS_83%"=="1" exit /b 0
if /i "!_LC_O!"=="!_LC_M!" exit /b 0
if exist "!_LC_H!\!_LC_M!" if not exist "!_LC_H!\!_LC_O!\" (
    rmdir /q "!_LC_H!\!_LC_O!" >nul 2>&1
    mklink /J "!_LC_H!\!_LC_O!" "!_LC_H!\!_LC_M!" >nul 2>&1
)
exit /b 0
