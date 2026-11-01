@echo off
:: # test_scaffold.cmd
:: ## Overview
:: End-to-end test suite for the LibScript component-package-manager scaffolder on Windows.
:: ## Usage
:: .\tests\test_scaffold.cmd

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

echo === Testing LibScript Component-Package-Manager Scaffolder on Windows ===

set "TEST_COMP_A=_test_scaffold_json_pkg"
set "TEST_COMP_B=_test_scaffold_cli_pkg"
set "COMP_A_DIR=!LIBSCRIPT_ROOT_DIR!\_lib\utilities\!TEST_COMP_A!"
set "COMP_B_DIR=!LIBSCRIPT_ROOT_DIR!\_lib\utilities\!TEST_COMP_B!"
set "TMP_SPEC=%TEMP%\scaffold_spec_%RANDOM%.json"
set "TMP_EXPORT=%TEMP%\scaffold_export_%RANDOM%.json"

call :cleanup

echo --- Test 1: Non-interactive JSON spec scaffolding ---
(
    echo {
    echo   "name": "!TEST_COMP_A!",
    echo   "title": "Test JSON Scaffold Utility",
    echo   "category": "utilities",
    echo   "description": "Synthetic utility package manager generated from JSON specification.",
    echo   "homepage": "https://example.com/test-scaffold-json",
    echo   "repository": "https://github.com/example/test-scaffold-json",
    echo   "license": "MIT OR Apache-2.0",
    echo   "default_version": "1.2.3",
    echo   "binary_name": "test-json-bin",
    echo   "version_flag": "--version",
    echo   "os_whitelist": ["linux", "macos", "windows", "freebsd"],
    echo   "install_methods": ["prebuilt-archive", "system-package-manager"],
    echo   "default_install_method": "prebuilt-archive",
    echo   "versioning_scheme": "github-release",
    echo   "github_repo": "example/test-scaffold-json",
    echo   "release_tag_prefix": "v",
    echo   "archive_format_unix": "tar.gz",
    echo   "archive_format_windows": "zip",
    echo   "ProvidesService": false
    echo }
) > "!TMP_SPEC!"

call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" scaffold --from-json="!TMP_SPEC!"
if errorlevel 1 (
    echo [FAIL] scaffold --from-json failed. >&2
    call :cleanup
    exit /b 1
)

for %%F in (manifest.json vars.schema.json README.md cli.sh cli.cmd setup.sh setup.cmd setup_generic.sh setup_generic.cmd env.sh env.cmd service.sh service.cmd status.sh status.cmd logs.sh logs.cmd uninstall.sh uninstall.cmd uninstall_generic.sh uninstall_generic.cmd test.sh test.cmd) do (
    if not exist "!COMP_A_DIR!\%%F" (
        echo [FAIL] Missing expected scaffolded file: !COMP_A_DIR!\%%F >&2
        call :cleanup
        exit /b 1
    )
)

echo --- Test 2: Idempotency check (re-running without --force) ---
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" scaffold --from-json="!TMP_SPEC!"
if errorlevel 1 (
    echo [FAIL] Idempotent re-run of scaffold failed. >&2
    call :cleanup
    exit /b 1
)

echo --- Test 3: Auditing generated component against LibScript standards ---
call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_version_manager.cmd" "!COMP_A_DIR!"
if errorlevel 1 (
    echo [FAIL] audit_version_manager.cmd failed on !COMP_A_DIR! >&2
    call :cleanup
    exit /b 1
)
call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_schema_vars.cmd" "!COMP_A_DIR!"
if errorlevel 1 (
    echo [FAIL] audit_schema_vars.cmd failed on !COMP_A_DIR! >&2
    call :cleanup
    exit /b 1
)

echo --- Test 4: CLI flag-driven scaffolding with --export-json ---
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" new-component --non-interactive --name="!TEST_COMP_B!" --title="Test CLI Scaffold Service" --category="utilities" --description="Synthetic daemon package manager generated via CLI flags." --default-version="2.0.0" --binary="test-cli-daemon" --service=true --default-port=9099 --health-endpoint="http://127.0.0.1:9099/healthz" --export-json="!TMP_EXPORT!"
if errorlevel 1 (
    echo [FAIL] new-component CLI flag scaffolding failed. >&2
    call :cleanup
    exit /b 1
)

if not exist "!TMP_EXPORT!" (
    echo [FAIL] --export-json did not write output file: !TMP_EXPORT! >&2
    call :cleanup
    exit /b 1
)

call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_version_manager.cmd" "!COMP_B_DIR!"
if errorlevel 1 (
    echo [FAIL] audit_version_manager.cmd failed on !COMP_B_DIR! >&2
    call :cleanup
    exit /b 1
)

call :cleanup
echo [PASS] All component scaffolder tests passed on Windows!
exit /b 0

:: ## cleanup
:: Removes temporary test components and JSON specification files.
:cleanup
if exist "!COMP_A_DIR!" rmdir /s /q "!COMP_A_DIR!" >nul 2>&1
if exist "!COMP_B_DIR!" rmdir /s /q "!COMP_B_DIR!" >nul 2>&1
if exist "!TMP_SPEC!" del /f /q "!TMP_SPEC!" >nul 2>&1
if exist "!TMP_EXPORT!" del /f /q "!TMP_EXPORT!" >nul 2>&1
exit /b 0
