@echo off
:: # theme.cmd
::
:: ## Overview
:: Theming and branding engine for Open edX on Windows.
:: Manages installation, compilation, site binding, listing, and removal of themes.
::
:: ## Usage
::   call theme.cmd install <name> <git_url> [--branch <branch>]
::   call theme.cmd build <name>
::   call theme.cmd apply <name> [--site <domain>]
::   call theme.cmd list
::   call theme.cmd remove <name>
::   call theme.cmd help
::
:: ## Exit Codes
::   0 - Success
::   1 - Error

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

set "THEMES_DIR=%OPENEDX_INSTALL_DIR%\themes"
set "THEME_REGISTRY=%THEMES_DIR%\registry.json"
if not exist "%THEMES_DIR%" mkdir "%THEMES_DIR%"

set "PYTHON_BIN=%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe"
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
        git clone --depth 1 --branch "%BRANCH%" "%GIT_URL%" "%DEST_DIR%" 2>nul
    )
) else (
    if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"
)

"%PYTHON_BIN%" -c "import json, os; p = r'%THEME_REGISTRY%'; d = json.load(open(p)) if os.path.exists(p) else {}; d['%THEME_NAME%'] = {'url': '%GIT_URL%', 'branch': '%BRANCH%', 'installed': True, 'active': False}; json.dump(d, open(p, 'w'), indent=2)"
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
echo [INFO] Applying theme '%THEME_NAME%' to %DOMAIN%...
"%PYTHON_BIN%" -c "import json, os; p = r'%THEME_REGISTRY%'; d = json.load(open(p)) if os.path.exists(p) else {}; [d[k].update({'active': (k == '%THEME_NAME%')}) for k in d]; json.dump(d, open(p, 'w'), indent=2)"
echo [INFO] Theme '%THEME_NAME%' applied.
exit /b 0

:: ## do_list
:: Lists all registered Open edX themes and active states.
:do_list
echo ============================================================================
echo THEME NAME               ACTIVE     SOURCE URL
echo ----------------------------------------------------------------------------
"%PYTHON_BIN%" -c "import json, os; p = r'%THEME_REGISTRY%'; d = json.load(open(p)) if os.path.exists(p) else {}; [print(f'{k:<24} {str(v.get("active", False)):<10} {v.get("url", "local"):<40}') for k, v in d.items()]"
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
echo [INFO] Removing theme '%THEME_NAME%'...
if exist "%THEMES_DIR%\%THEME_NAME%" rmdir /s /q "%THEMES_DIR%\%THEME_NAME%"
"%PYTHON_BIN%" -c "import json, os; p = r'%THEME_REGISTRY%'; d = json.load(open(p)) if os.path.exists(p) else {}; d.pop('%THEME_NAME%', None); json.dump(d, open(p, 'w'), indent=2)"
echo [INFO] Theme '%THEME_NAME%' removed.
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
