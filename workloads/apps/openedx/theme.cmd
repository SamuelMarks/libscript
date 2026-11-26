@echo off
:: # theme.cmd
:: ## Overview
:: Theming and branding engine for Open edX on Windows. Manages installation, compilation, site binding, listing, and removal of themes.
:: ## Usage
:: call theme.cmd install <name> <git_url> [--branch <branch>] call theme.cmd build <name> call theme.cmd apply <name> [--site <domain>] call theme.cmd list call theme.cmd remove <name> call theme.cmd help ## Exit Codes 0 - Success 1 - Error

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


if "!OPENEDX_INSTALL_DIR!"=="" (
    if exist "%ProgramData%\OpenEdX\install_dir.txt" (
        set /p OPENEDX_INSTALL_DIR=<"%ProgramData%\OpenEdX\install_dir.txt"
    ) else if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)
if "!OPENEDX_INSTALL_DIR:~-1!"==" " set "OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR:~0,-1!"
if "!OPENEDX_INSTALL_DIR:~-1!"=="\" set "OPENEDX_INSTALL_DIR=!OPENEDX_INSTALL_DIR:~0,-1!"

set "THEMES_DIR=!OPENEDX_INSTALL_DIR!\themes"
set "THEME_REGISTRY=!THEMES_DIR!\registry.json"
if not exist "!THEMES_DIR!" mkdir "!THEMES_DIR!"

set "PYTHON_BIN=!OPENEDX_INSTALL_DIR!\.venv\Scripts\python.exe"
if not exist "%PYTHON_BIN%" (
    where python >nul 2>nul
    if not errorlevel 1 (
        set "PYTHON_BIN=python"
    ) else (
        echo [ERROR] Python interpreter not found in virtualenv or PATH. >&2
        exit /b 1
    )
)

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="install" goto do_install
if "%CMD%"=="build" goto do_build
if "%CMD%"=="apply" goto do_apply
if "%CMD%"=="list" goto do_list
if "%CMD%"=="remove" goto do_remove
if "%CMD%"=="delete" goto do_remove

echo [ERROR] Unknown theme command: %CMD% >&2
goto show_help

:: ## do_install
:: Clones or downloads an Open edX custom theme repository.
:do_install
shift
set "THEME_NAME=%~1"
set "GIT_URL=%~2"
if "%THEME_NAME%"=="" (
    echo [ERROR] Theme name required. >&2
    exit /b 1
)
if "%GIT_URL%"=="" (
    echo [ERROR] Theme git URL required. >&2
    exit /b 1
)
shift
shift

set "BRANCH=master"
if "%~1"=="--branch" (
    set "BRANCH=%~2"
    shift
    shift
)

set "DEST_DIR=%THEMES_DIR%\%THEME_NAME%"
echo [INFO] Installing theme '%THEME_NAME%'...
where git >nul 2>nul
if not errorlevel 1 (
    if exist "%DEST_DIR%\.git" (
        pushd "%DEST_DIR%"
        git pull 2>nul
        popd
    ) else (
        if exist "%DEST_DIR%" rmdir /s /q "%DEST_DIR%" >nul 2>&1
        git clone --depth 1 --branch "%BRANCH%" "%GIT_URL%" "%DEST_DIR%" 2>nul || git clone --depth 1 "%GIT_URL%" "%DEST_DIR%" 2>nul
        if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"
    )
) else (
    if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"
)

call :ensure_jq
for %%D in ("%THEME_REGISTRY%") do if not exist "%%~dpD" mkdir "%%~dpD" >nul 2>&1
if not exist "%THEME_REGISTRY%" echo {}> "%THEME_REGISTRY%"
jq --arg n "%THEME_NAME%" --arg u "%GIT_URL%" --arg b "%BRANCH%" ".[$n] = {\"url\": $u, \"branch\": $b, \"installed\": true, \"active\": false}" "%THEME_REGISTRY%" > "%THEME_REGISTRY%.tmp" 2>nul && move /y "%THEME_REGISTRY%.tmp" "%THEME_REGISTRY%" >nul
echo [INFO] Theme '%THEME_NAME%' installed.
exit /b 0

:: ## do_build
:: Compiles assets for a custom Open edX theme.
:do_build
shift
set "THEME_NAME=%~1"
if "%THEME_NAME%"=="" (
    echo [ERROR] Theme name required. >&2
    exit /b 1
)
set "DEST_DIR=%THEMES_DIR%\%THEME_NAME%"
if not exist "%DEST_DIR%" (
    echo [ERROR] Theme '%THEME_NAME%' not found. >&2
    exit /b 1
)
echo [INFO] Compiling assets for theme '%THEME_NAME%'...
if exist "%DEST_DIR%\package.json" (
    pushd "%DEST_DIR%"
    npm install 2>nul
    npm run build 2>nul
    popd
)
if exist "%OPENEDX_INSTALL_DIR%\manage.py" (
    "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%\manage.py" lms collectstatic --noinput 2>nul
)
echo [INFO] Theme '%THEME_NAME%' build completed.
exit /b 0

:: ## do_apply
:: Sets an installed Open edX theme as the active theme.
:do_apply
shift
set "THEME_NAME=%~1"
if "%THEME_NAME%"=="" (
    echo [ERROR] Theme name required. >&2
    exit /b 1
)
shift
set "DOMAIN=openedx.local"
if "%~1"=="--site" (
    set "DOMAIN=%~2"
    shift
    shift
)
set "DEST_DIR=%THEMES_DIR%\%THEME_NAME%"
if not exist "%DEST_DIR%" (
    echo [ERROR] Theme '%THEME_NAME%' not installed. >&2
    exit /b 1
)
call :ensure_jq
echo [INFO] Applying theme '%THEME_NAME%' to %DOMAIN%...
if exist "%THEME_REGISTRY%" (
    jq --arg n "%THEME_NAME%" "with_entries(.value.active = (.key == $n))" "%THEME_REGISTRY%" > "%THEME_REGISTRY%.tmp" 2>nul && move /y "%THEME_REGISTRY%.tmp" "%THEME_REGISTRY%" >nul
)
echo [INFO] Theme '%THEME_NAME%' applied.
exit /b 0

:: ## do_list
:: Lists all registered Open edX themes and active states.
:do_list
call :ensure_jq
echo ============================================================================
echo THEME NAME               ACTIVE     SOURCE URL
echo ----------------------------------------------------------------------------
if exist "%THEME_REGISTRY%" (
    for /f "tokens=1,2,3 delims=	" %%A in ('jq -r "to_entries[] | \"\(.key)\t\(.value.active // false)\t\(.value.url // \"local\")\"" "%THEME_REGISTRY%" 2^>nul') do (
        echo %%A                      %%B        %%C
    )
)
echo ============================================================================
exit /b 0

:: ## do_remove
:: Removes an installed Open edX theme from disk and registry.
:do_remove
shift
set "THEME_NAME=%~1"
if "%THEME_NAME%"=="" (
    echo [ERROR] Theme name required. >&2
    exit /b 1
)
call :ensure_jq
echo [INFO] Removing theme '%THEME_NAME%'...
if exist "%THEMES_DIR%\%THEME_NAME%" rmdir /s /q "%THEMES_DIR%\%THEME_NAME%"
if exist "%THEME_REGISTRY%" (
    jq --arg n "%THEME_NAME%" "del(.[$n])" "%THEME_REGISTRY%" > "%THEME_REGISTRY%.tmp" 2>nul && move /y "%THEME_REGISTRY%.tmp" "%THEME_REGISTRY%" >nul
)
echo [INFO] Theme '%THEME_NAME%' removed.
exit /b 0

:: ## ensure_jq
:: Ensures jq is available on PATH via LibScript's _lib\utilities\jq component.
:ensure_jq
where jq >nul 2>&1
if errorlevel 1 if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
)
where jq >nul 2>&1
if errorlevel 1 (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install jq latest >nul 2>&1
    set "STACK="
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
)
exit /b 0

:: ## show_help
:: Displays theme management CLI command usage.
:show_help
echo Open edX Theming ^& Branding CLI (Windows)
echo.
echo Usage:
echo   call theme.cmd install ^<name^> ^<git_url^> [--branch ^<branch^>]
echo   call theme.cmd build ^<name^>
echo   call theme.cmd apply ^<name^> [--site ^<domain^>]
echo   call theme.cmd list
echo   call theme.cmd remove ^<name^>
echo   call theme.cmd help
exit /b 0
