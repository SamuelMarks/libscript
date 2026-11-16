@echo off
:: # pkg_resolver.cmd
:: ## Overview
:: Cross-OS target package artifact resolver on Windows (`Step 1`) for installer-e2e experiments,
:: resolving `.msi`, `.exe`, `.deb`, `.rpm`, `.pkg`, and `.dmg` packages from GitHub Releases or host builds.
:: ## Usage
:: pkg_resolver.cmd <infer-format|sha256|resolve> [args...]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "PR_ACT=%~1"
if "!PR_ACT!"=="" goto :pr_help
if /i "!PR_ACT!"=="--help" goto :pr_help
if /i "!PR_ACT!"=="-h" goto :pr_help
if /i "!PR_ACT!"=="infer-format" ( call :pr_infer_format_for_os "%~2" "%~3" & if errorlevel 1 exit /b 1 & echo !PR_FMT! & exit /b 0 )
if /i "!PR_ACT!"=="sha256" ( call :pr_compute_sha256 "%~2" & echo !PR_SHA! & exit /b 0 )
if /i "!PR_ACT!"=="resolve" ( call :pr_resolve_artifact "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9" & exit /b !errorlevel! )
echo [ERROR] Unknown pkg_resolver action: !PR_ACT! >&2
exit /b 1

:: ## pr_compute_sha256
:: Computes the SHA-256 hex digest of a file using certutil on Windows.
:pr_compute_sha256
set "PR_SHA=unknown"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "%~1" SHA256 2^>nul') do (
    if "!PR_SHA!"=="unknown" set "PR_SHA=%%H"
)
exit /b 0

:: ## pr_infer_format_for_os
:: Maps a target guest OS slug to its default installer format or validates an explicit format.
:pr_infer_format_for_os
set "_os=%~1"
if "!_os!"=="" set "_os=windows-11"
set "_fmt=%~2"
if "!_fmt!"=="" set "_fmt=auto"
if /i "!_fmt!"=="auto" (
    set "PR_FMT=deb"
    if /i "!_os:~0,3!"=="win" set "PR_FMT=msi"
    if /i "!_os:~0,6!"=="debian" set "PR_FMT=deb"
    if /i "!_os:~0,6!"=="ubuntu" set "PR_FMT=deb"
    if /i "!_os:~0,5!"=="rocky" set "PR_FMT=rpm"
    if /i "!_os:~0,4!"=="rhel" set "PR_FMT=rpm"
    if /i "!_os:~0,5!"=="macos" set "PR_FMT=pkg"
    exit /b 0
)
for %%F in (msi exe deb rpm pkg dmg) do (
    if /i "!_fmt!"=="%%F" ( set "PR_FMT=%%F" & exit /b 0 )
)
echo [ERROR] Unsupported package format: !_fmt! >&2
exit /b 1

:: ## pr_resolve_from_github_release
:: Downloads a release asset matching the stack and format from GitHub Releases idempotently.
:pr_resolve_from_github_release
set "_suite=%~1"
set "_man=%~2"
set "_fmt=%~3"
set "_repo=%~4"
if "!_repo!"=="" set "_repo=SamuelMarks/libscript"
set "_tag=%~5"
if "!_tag!"=="" set "_tag=latest"
set "_pat=%~6"
set "_force=%~7"
for /f "usebackq delims=" %%N in (`jq -r ".name // \"app\"" "!_man!"`) do set "_app=%%N"
set "_cdir=!LIBSCRIPT_ROOT_DIR!\cache\experiments\!_suite!\!_tag!\!_fmt!"
if not exist "!_cdir!" mkdir "!_cdir!"
if not "!_force!"=="1" (
    for %%E in ("!_cdir!\*.!_fmt!") do (
        if exist "%%~fE" (
            echo [SKIP] Reusing cached GitHub Release artifact: %%~fE >&2
            echo %%~fE
            exit /b 0
        )
    )
)
if not "%LIBSCRIPT_MOCK_GITHUB_RELEASE_FILE%"=="" (
    if exist "%LIBSCRIPT_MOCK_GITHUB_RELEASE_FILE%" (
        copy /y "%LIBSCRIPT_MOCK_GITHUB_RELEASE_FILE%" "!_cdir!\!_app!-mock.!_fmt!" >nul
        echo !_cdir!\!_app!-mock.!_fmt!
        exit /b 0
    )
)
if /i "!_tag!"=="latest" (
    set "_api=https://api.github.com/repos/!_repo!/releases/latest"
) else (
    set "_api=https://api.github.com/repos/!_repo!/releases/tags/!_tag!"
)
set "_meta=!_cdir!\release.json"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "!_api!" "!_meta!"
for /f "usebackq delims=" %%U in (`jq -r --arg ext ".!_fmt!" "[.assets[]? | select(.name | endswith($ext))][0].browser_download_url // empty" "!_meta!"`) do set "_asset_url=%%U"
for /f "usebackq delims=" %%F in (`jq -r --arg ext ".!_fmt!" "[.assets[]? | select(.name | endswith($ext))][0].name // empty" "!_meta!"`) do set "_aname=%%F"
if "!_asset_url!"=="" (
    echo [ERROR] No .!_fmt! release asset found in !_repo! ^(!_tag!^) >&2
    exit /b 1
)
set "_dest=!_cdir!\!_aname!"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "!_asset_url!" "!_dest!"
echo !_dest!
exit /b 0

:: ## pr_build_anew_on_host
:: Builds the target package format anew on the host using LibScript's packaging entrypoints.
:pr_build_anew_on_host
set "_suite=%~1"
set "_man=%~2"
set "_os=%~3"
set "_fmt=%~4"
set "_var=%~5"
if "!_var!"=="" set "_var=offline"
set "_force=%~6"
for /f "usebackq delims=" %%N in (`jq -r ".name // \"app\"" "!_man!"`) do set "_app=%%N"
for /f "usebackq delims=" %%T in (`jq -r ".title // .name // \"LibScript App\"" "!_man!"`) do set "_title=%%T"
for /f "usebackq delims=" %%V in (`jq -r ".version // \"1.0.0.0\"" "!_man!"`) do set "_ver=%%V"
set "_out_dir=!LIBSCRIPT_ROOT_DIR!\build\experiments\!_suite!\packages\!_os!\!_fmt!"
if not exist "!_out_dir!" mkdir "!_out_dir!"
set "_out_pkg=!_out_dir!\!_app!-!_ver!-!_var!.!_fmt!"
if not "!_force!"=="1" (
    if exist "!_out_pkg!" (
        echo [SKIP] Reusing host-built !_fmt! package: !_out_pkg! >&2
        echo !_out_pkg!
        exit /b 0
    )
)
if "%LIBSCRIPT_MOCK_ARTIFACT_BUILD%"=="1" (
    echo MOCK_PACKAGE:!_app!:!_fmt!:!_ver!> "!_out_pkg!"
    echo !_out_pkg!
    exit /b 0
)
if /i "!_fmt!"=="msi" (
    if /i "!_app!"=="openedx" (
        if exist "!LIBSCRIPT_ROOT_DIR!\packaging\build.cmd" (
            set "STACK="
            call "!LIBSCRIPT_ROOT_DIR!\packaging\build.cmd" --!_var! --out-dir "!_out_dir!" >&2
            for %%M in ("!_out_dir!\*.msi") do (
                if not "%%~fM"=="!_out_pkg!" copy /y "%%~fM" "!_out_pkg!" >nul
            )
            echo !_out_pkg!
            exit /b 0
        )
    )
)
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package_as "!_fmt!" --app-name "!_title!" --app-version "!_ver!" --out-file "!_out_dir!\!_app!-!_ver!-!_var!" "!_app!" latest >&2
if not exist "!_out_pkg!" (
    echo [ERROR] Host package build did not produce !_out_pkg! >&2
    exit /b 1
)
echo !_out_pkg!
exit /b 0

:: ## pr_resolve_artifact
:: Main Step 1 router dispatching `github-release` vs `build`.
:pr_resolve_artifact
set "_suite=%~1"
set "_man=%~2"
set "_os=%~3"
call :pr_infer_format_for_os "!_os!" "%~4"
if errorlevel 1 exit /b 1
set "_src=%~5"
if "!_src!"=="" set "_src=github-release"
if /i "!_src!"=="github-release" (
    call :pr_resolve_from_github_release "!_suite!" "!_man!" "!PR_FMT!" "%~6" "%~7" "%~8" "!FORCE_REBUILD!"
    exit /b !errorlevel!
)
if /i "!_src!"=="build" (
    call :pr_build_anew_on_host "!_suite!" "!_man!" "!_os!" "!PR_FMT!" "offline" "!FORCE_REBUILD!"
    exit /b !errorlevel!
)
echo [ERROR] Unsupported package source: !_src! >&2
exit /b 1

:: ## pr_help
:: Prints CLI usage for pkg_resolver.cmd.
:pr_help
echo Usage: pkg_resolver.cmd ^<infer-format^|sha256^|resolve^> [args...]
exit /b 0
