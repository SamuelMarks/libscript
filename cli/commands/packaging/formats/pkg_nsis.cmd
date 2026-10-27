@echo off
:: # pkg_nsis.cmd
::
:: ## Overview
:: Implements packaging logic for the 'nsis' format on Windows.
:: 
:: ## Usage
:: Called by the packaging system to produce NSIS installer scripts.

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

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=!SCRIPT_DIR!\..\..\..\.."
)

call "!SCRIPT_DIR!\_common_installer_args.cmd" %*

set "nsi_file=%OUT_FILE%.nsi"
> "%nsi_file%" (
    echo !define APP_NAME "%APP_NAME%"
    echo !define APP_VERSION "%APP_VERSION%"
    echo !define APP_PUBLISHER "%APP_PUBLISHER%"
    echo Name "%APP_NAME% %APP_VERSION%"
    echo OutFile "%OUT_FILE%.exe"
    echo InstallDir "$PROGRAMFILES\%APP_NAME%"
    echo RequestExecutionLevel %nsis_admin%
    echo VIProductVersion "%APP_VERSION%"
    echo VIAddVersionKey "ProductName" "%APP_NAME%"
    echo VIAddVersionKey "CompanyName" "%APP_PUBLISHER%"
    echo VIAddVersionKey "FileDescription" "%WELCOME_TEXT%"
    echo VIAddVersionKey "FileVersion" "%APP_VERSION%"
    if not "%ICON_PATH%"=="" echo Icon "%ICON_PATH%"
    echo Section "MainSection" SEC01
    echo   SetOutPath "$INSTDIR"
    echo   File /r "!LIBSCRIPT_ROOT_DIR!\*.*"
    echo SectionEnd
)

echo Generated %nsi_file%
where makensis >nul 2>&1
if %errorlevel% equ 0 (
    echo Compiling %nsi_file% with makensis...
    makensis "%nsi_file%"
)
exit /b %errorlevel%
