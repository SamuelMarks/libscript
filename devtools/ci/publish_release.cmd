@echo off
:: # publish_release.cmd
::
:: ## Overview
:: Publishes built release packages, installer artifacts, and cryptographic
:: checksums to GitHub Releases via the GitHub CLI in an idempotent manner.
::
:: ## Usage
:: publish_release.cmd devtools/ci/publish_release.cmd --tag <tag> [--dist-dir <dir>] [--title <title>] [--draft] [--prerelease]

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


if "%~1"=="" goto :no_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :parse_args

:: ## show_help
:: Displays usage instructions and supported command-line options.
:show_help
echo Usage: %~nx0 --tag ^<tag^> [OPTIONS]
echo Publishes installer artifacts and checksums to GitHub Releases.
echo.
echo Options:
echo   --tag ^<tag^>         Release tag name (required, e.g. v1.0.0).
echo   --dist-dir ^<dir^>    Directory containing built release assets (default: dist).
echo   --title ^<title^>     Release title (default: matches tag name).
echo   --draft             Publish release as a draft.
echo   --prerelease        Publish release as a pre-release.
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## no_args
:: Handles missing arguments error.
:no_args
echo [ERROR] Missing required arguments. >&2
call :show_help >&2
exit /b 1

:: ## parse_args
:: Parses command-line flags and parameters.
:parse_args
set "REL_TAG="
set "DIST_DIR=dist"
set "REL_TITLE="
set "IS_DRAFT=false"
set "IS_PRERELEASE=false"

:: ## args_loop
:: Performs the args_loop operation and updates component state.
:args_loop
if "%~1"=="" goto :validate_args
if /I "%~1"=="--tag" (
    set "REL_TAG=%~2"
    shift
    shift
    goto :args_loop
)
if /I "%~1"=="--dist-dir" (
    set "DIST_DIR=%~2"
    shift
    shift
    goto :args_loop
)
if /I "%~1"=="--title" (
    set "REL_TITLE=%~2"
    shift
    shift
    goto :args_loop
)
if /I "%~1"=="--draft" (
    set "IS_DRAFT=true"
    shift
    goto :args_loop
)
if /I "%~1"=="--prerelease" (
    set "IS_PRERELEASE=true"
    shift
    goto :args_loop
)
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
echo [ERROR] Unknown option: %~1 >&2
exit /b 1

:: ## validate_args
:: Checks required parameters and paths.
:validate_args
if not defined REL_TAG (
    echo [ERROR] Missing required parameter: --tag ^<tag^> >&2
    exit /b 1
)

if not defined REL_TITLE set "REL_TITLE=%REL_TAG%"

if not exist "%DIST_DIR%" (
    echo [ERROR] Distribution directory not found: %DIST_DIR% >&2
    exit /b 1
)

call :generate_sums "%DIST_DIR%"
goto :execute_publish

:: ## generate_sums
:: Consolidates SHA256 checksums into SHA256SUMS.txt.
:generate_sums
set "_SUMS_DIR=%~1"
set "TMP_SUMS=%_SUMS_DIR%\.SHA256SUMS.tmp"
if exist "%TMP_SUMS%" del /f /q "%TMP_SUMS%"

for %%F in ("%_SUMS_DIR%\*") do (
    set "FNAME=%%~nxF"
    set "FILE_EXT=%%~xF"
    if not "!FNAME!"=="SHA256SUMS.txt" if not "!FILE_EXT!"==".sha256" (
        for %%A in ("%%F") do set "FSIZE=%%~zA"
        if not "!FSIZE!"=="0" (
            set "FILE_HASH="
            where powershell >nul 2>&1
            if !ERRORLEVEL! equ 0 (
                for /f "usebackq delims=" %%H in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[System.IO.File]::OpenRead('%%F');$h=[System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($s)).Replace('-','').ToLower();$s.Close();$h" 2^>nul`) do (
                    set "FILE_HASH=%%H"
                )
            )
            if not defined FILE_HASH (
                where certutil >nul 2>&1
                if !ERRORLEVEL! equ 0 (
                    for /f "tokens=* skip=1" %%H in ('certutil -hashfile "%%F" SHA256 2^>nul') do (
                        if not defined FILE_HASH (
                            set "line=%%H"
                            if not "!line:CertUtil=!"=="!line!" goto :skip_hash_item
                            set "FILE_HASH=!line: =!"
                        )
                    )
                )
            )
            :skip_hash_item
            if defined FILE_HASH (
                >> "%TMP_SUMS%" echo !FILE_HASH!  !FNAME!
            )
        )
    )
)
if exist "%TMP_SUMS%" (
    for %%A in ("%TMP_SUMS%") do set "SUM_SIZE=%%~zA"
    if not "!SUM_SIZE!"=="0" (
        move /y "%TMP_SUMS%" "%_SUMS_DIR%\SHA256SUMS.txt" >nul 2>&1
    ) else (
        del /f /q "%TMP_SUMS%" >nul 2>&1
    )
)
if exist "%_SUMS_DIR%\SHA256SUMS.txt" (
    for %%A in ("%_SUMS_DIR%\SHA256SUMS.txt") do if "%%~zA"=="0" del /f /q "%_SUMS_DIR%\SHA256SUMS.txt" >nul 2>&1
)
exit /b 0

:: ## execute_publish
:: Dispatches to GitHub CLI.
:execute_publish
echo [INFO] Publishing release assets for tag "%REL_TAG%" from "%DIST_DIR%"...

where gh >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] GitHub CLI (gh) not found in PATH. >&2
    exit /b 1
)

set "ASSET_FILES="
set "ASSET_COUNT=0"
for %%F in ("%DIST_DIR%\*") do (
    for %%A in ("%%F") do set "FSIZE=%%~zA"
    if not "!FSIZE!"=="0" (
        set "ASSET_FILES=!ASSET_FILES! "%%F""
        set /a ASSET_COUNT+=1
    )
)

if %ASSET_COUNT% equ 0 (
    echo [ERROR] No valid non-empty assets found in "%DIST_DIR%" to publish. >&2
    exit /b 1
)

gh release view "%REL_TAG%" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [INFO] Release "%REL_TAG%" already exists. Uploading assets with clobber...
    gh release upload "%REL_TAG%" !ASSET_FILES! --clobber
    if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
) else (
    echo [INFO] Creating new release "%REL_TAG%"...
    if "%IS_DRAFT%"=="true" if "%IS_PRERELEASE%"=="true" (
        gh release create "%REL_TAG%" --title "%REL_TITLE%" --generate-notes --draft --prerelease !ASSET_FILES!
        if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    ) else if "%IS_DRAFT%"=="true" (
        gh release create "%REL_TAG%" --title "%REL_TITLE%" --generate-notes --draft !ASSET_FILES!
        if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    ) else if "%IS_PRERELEASE%"=="true" (
        gh release create "%REL_TAG%" --title "%REL_TITLE%" --generate-notes --prerelease !ASSET_FILES!
        if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    ) else (
        gh release create "%REL_TAG%" --title "%REL_TITLE%" --generate-notes !ASSET_FILES!
        if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    )
)

echo [SUCCESS] Release assets successfully published for %REL_TAG%
exit /b 0
