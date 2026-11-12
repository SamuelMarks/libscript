@echo off
:: # scaffold.cmd
:: ## Overview
:: Interactive prompter and non-interactive JSON generator for creating new Tier 1 LibScript component-package-managers under `_lib\<category>\<component>\` on Windows.
:: ## Usage
:: .\libscript.cmd scaffold [--interactive | --from-json=<file>] [--export-json=<file>] [--force] [--dry-run]

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

set "SCAF_MODE=interactive"
set "SCAF_FROM_JSON="
set "SCAF_EXPORT_JSON="
set "SCAF_FORCE=0"
set "SCAF_DRY_RUN=0"

set "SCAF_NAME="
set "SCAF_TITLE="
set "SCAF_CATEGORY="
set "SCAF_DESCRIPTION="
set "SCAF_PROVIDES="
set "SCAF_BINARY_NAME="
set "SCAF_INSTALL_METHOD=libscript_native"
set "SCAF_VERSION_SCHEME=github-release"
set "SCAF_DEFAULT_VERSION=latest"
set "SCAF_VERSION_ALIASES=latest,lts"
set "SCAF_REPOSITORY="
set "SCAF_GITHUB_REPO="
set "SCAF_TAG_PREFIX=v"
set "SCAF_URL_UNIX="
set "SCAF_URL_WINDOWS="
set "SCAF_RELEASES_URL="
set "SCAF_ARCHIVE_UNIX=auto"
set "SCAF_ARCHIVE_WINDOWS=auto"
set "SCAF_STRIP_COMPONENTS=1"
set "SCAF_SRC_LANG=c"
set "SCAF_SRC_BUILD_SYS=autotools"
set "SCAF_SRC_FALLBACK_VER=1.0.0"
set "SCAF_OS_WHITELIST=all"
set "SCAF_OS_BLACKLIST="
set "SCAF_ARCH_WHITELIST=all"
set "SCAF_IS_SERVICE=false"
set "SCAF_PORTS="
set "SCAF_ENABLE_HOOKS=false"
set "SCAF_MULTITENANT=false"
set "SCAF_TEST_CMD="

:: ## parse_args
:: Parses CLI flags for the Windows component scaffolder.
:parse_args
if "%~1"=="" goto :args_done
set "arg=%~1"
if /i "!arg!"=="scaffold" ( shift & goto :parse_args )
if /i "!arg!"=="new-component" ( shift & goto :parse_args )
if /i "!arg!"=="--help" goto :show_scaffold_help
if /i "!arg!"=="-h" goto :show_scaffold_help
if /i "!arg!"=="/?" goto :show_scaffold_help
if /i "!arg!"=="-?" goto :show_scaffold_help
if /i "!arg!"=="--interactive" ( set "SCAF_MODE=interactive" & shift & goto :parse_args )
if /i "!arg!"=="-i" ( set "SCAF_MODE=interactive" & shift & goto :parse_args )
if /i "!arg!"=="--non-interactive" ( set "SCAF_MODE=non-interactive" & shift & goto :parse_args )
if /i "!arg!"=="--force" ( set "SCAF_FORCE=1" & shift & goto :parse_args )
if /i "!arg!"=="-f" ( set "SCAF_FORCE=1" & shift & goto :parse_args )
if /i "!arg!"=="--dry-run" ( set "SCAF_DRY_RUN=1" & shift & goto :parse_args )
if /i "!arg!"=="-n" ( set "SCAF_DRY_RUN=1" & shift & goto :parse_args )
if /i "!arg!"=="--service" ( set "SCAF_IS_SERVICE=true" & shift & goto :parse_args )
if /i "!arg!"=="--hooks" ( set "SCAF_ENABLE_HOOKS=true" & shift & goto :parse_args )
if /i "!arg!"=="--multitenant" ( set "SCAF_MULTITENANT=true" & shift & goto :parse_args )
if /i "!arg:~0,12!"=="--from-json=" (
    set "SCAF_FROM_JSON=!arg:~12!"
    set "SCAF_MODE=json"
    shift
    goto :parse_args
)
if /i "!arg!"=="--from-json" (
    set "SCAF_FROM_JSON=%~2"
    set "SCAF_MODE=json"
    shift
    shift
    goto :parse_args
)
if /i "!arg:~0,14!"=="--export-json=" (
    set "SCAF_EXPORT_JSON=!arg:~14!"
    shift
    goto :parse_args
)
if /i "!arg!"=="--export-json" (
    set "SCAF_EXPORT_JSON=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!arg:~0,7!"=="--name=" ( set "SCAF_NAME=!arg:~7!" & shift & goto :parse_args )
if /i "!arg:~0,8!"=="--title=" ( set "SCAF_TITLE=!arg:~8!" & shift & goto :parse_args )
if /i "!arg:~0,11!"=="--category=" ( set "SCAF_CATEGORY=!arg:~11!" & shift & goto :parse_args )
if /i "!arg:~0,14!"=="--description=" ( set "SCAF_DESCRIPTION=!arg:~14!" & shift & goto :parse_args )
if /i "!arg:~0,14!"=="--binary-name=" ( set "SCAF_BINARY_NAME=!arg:~14!" & shift & goto :parse_args )
if /i "!arg:~0,17!"=="--install-method=" ( set "SCAF_INSTALL_METHOD=!arg:~17!" & shift & goto :parse_args )
if /i "!arg:~0,17!"=="--version-scheme=" ( set "SCAF_VERSION_SCHEME=!arg:~17!" & shift & goto :parse_args )
if /i "!arg:~0,14!"=="--github-repo=" ( set "SCAF_GITHUB_REPO=!arg:~14!" & shift & goto :parse_args )
if /i "!arg:~0,13!"=="--tag-prefix=" ( set "SCAF_TAG_PREFIX=!arg:~13!" & shift & goto :parse_args )
if /i "!arg:~0,6!"=="--url=" ( set "SCAF_URL_UNIX=!arg:~6!" & shift & goto :parse_args )
if /i "!arg:~0,10!"=="--win-url=" ( set "SCAF_URL_WINDOWS=!arg:~10!" & shift & goto :parse_args )
if /i "!arg:~0,15!"=="--releases-url=" ( set "SCAF_RELEASES_URL=!arg:~15!" & shift & goto :parse_args )
if /i "!arg:~0,5!"=="--os=" ( set "SCAF_OS_WHITELIST=!arg:~5!" & shift & goto :parse_args )
if /i "!arg:~0,7!"=="--arch=" ( set "SCAF_ARCH_WHITELIST=!arg:~7!" & shift & goto :parse_args )
if /i "!arg:~0,8!"=="--ports=" ( set "SCAF_PORTS=!arg:~8!" & shift & goto :parse_args )
if /i "!arg:~0,11!"=="--test-cmd=" ( set "SCAF_TEST_CMD=!arg:~11!" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Continues execution after CLI flags are parsed.
:args_done
if /i "!SCAF_MODE!"=="json" (
    call :parse_json_spec "!SCAF_FROM_JSON!"
    if errorlevel 1 exit /b 1
)
if /i "!SCAF_MODE!"=="interactive" (
    call :run_interactive_prompter
    if errorlevel 1 exit /b 1
)

if "!SCAF_NAME!"=="" (
    echo [ERROR] Component name is required. >&2
    exit /b 1
)
if "!SCAF_CATEGORY!"=="" set "SCAF_CATEGORY=utilities"
if "!SCAF_TITLE!"=="" set "SCAF_TITLE=!SCAF_NAME!"
if "!SCAF_DESCRIPTION!"=="" set "SCAF_DESCRIPTION=Installs and manages !SCAF_TITLE! across supported platforms."
if "!SCAF_BINARY_NAME!"=="" set "SCAF_BINARY_NAME=!SCAF_NAME!"
if not "!SCAF_GITHUB_REPO!"=="" (
    if "!SCAF_REPOSITORY!"=="" set "SCAF_REPOSITORY=https://github.com/!SCAF_GITHUB_REPO!"
    if "!SCAF_RELEASES_URL!"=="" set "SCAF_RELEASES_URL=https://api.github.com/repos/!SCAF_GITHUB_REPO!/releases/latest"
    if "!SCAF_URL_UNIX!"=="" set "SCAF_URL_UNIX=https://github.com/!SCAF_GITHUB_REPO!/releases/download/!SCAF_TAG_PREFIX!{VERSION}/!SCAF_NAME!-{VERSION}.tar.gz"
    if "!SCAF_URL_WINDOWS!"=="" set "SCAF_URL_WINDOWS=https://github.com/!SCAF_GITHUB_REPO!/releases/download/!SCAF_TAG_PREFIX!{VERSION}/!SCAF_NAME!-{VERSION}-windows.zip"
)
if "!SCAF_URL_UNIX!"=="" set "SCAF_URL_UNIX=https://example.com/releases/!SCAF_NAME!-{VERSION}.tar.gz"
if "!SCAF_URL_WINDOWS!"=="" set "SCAF_URL_WINDOWS=https://example.com/releases/!SCAF_NAME!-{VERSION}-windows.zip"
if "!SCAF_RELEASES_URL!"=="" set "SCAF_RELEASES_URL=https://example.com/releases"
if "!SCAF_TEST_CMD!"=="" set "SCAF_TEST_CMD=!SCAF_BINARY_NAME! --version"

:: If sh is available on the host (Git for Windows / MSYS2 / WSL), delegate synthesis to scaffold.sh for byte-identical templates
where sh >nul 2>&1
if not errorlevel 1 (
    if /i "!SCAF_MODE!"=="json" (
        set "_SH_ARGS=--from-json=!SCAF_FROM_JSON!"
    ) else (
        set "_SH_ARGS=--non-interactive --name=!SCAF_NAME! --category=!SCAF_CATEGORY! --title=!SCAF_TITLE! --binary-name=!SCAF_BINARY_NAME! --install-method=!SCAF_INSTALL_METHOD! --version-scheme=!SCAF_VERSION_SCHEME! --os=!SCAF_OS_WHITELIST!"
        if not "!SCAF_GITHUB_REPO!"=="" set "_SH_ARGS=!_SH_ARGS! --github-repo=!SCAF_GITHUB_REPO!"
    )
    if "!SCAF_FORCE!"=="1" set "_SH_ARGS=!_SH_ARGS! --force"
    if "!SCAF_DRY_RUN!"=="1" set "_SH_ARGS=!_SH_ARGS! --dry-run"
    if not "!SCAF_EXPORT_JSON!"=="" set "_SH_ARGS=!_SH_ARGS! --export-json=!SCAF_EXPORT_JSON!"
    sh "!SCRIPT_DIR!\scaffold.sh" !_SH_ARGS!
    exit /b !errorlevel!
)

if not "!SCAF_EXPORT_JSON!"=="" (
    call :export_spec_to_json "!SCAF_EXPORT_JSON!"
)

set "COMP_TARGET_DIR=!LIBSCRIPT_ROOT_DIR!\_lib\!SCAF_CATEGORY!\!SCAF_NAME!"
if "!SCAF_DRY_RUN!"=="1" (
    echo [DRY-RUN] Would scaffold component at !COMP_TARGET_DIR!
    exit /b 0
)
if not exist "!COMP_TARGET_DIR!" mkdir "!COMP_TARGET_DIR!"
call :synthesize_component_batch "!COMP_TARGET_DIR!"
echo [SUCCESS] Component !SCAF_CATEGORY!/!SCAF_NAME! scaffolded at !COMP_TARGET_DIR!
exit /b 0

:: ## parse_json_spec
:: Parses a JSON specification file using jq or PowerShell ConvertFrom-Json.
:parse_json_spec
set "_SPEC_FILE=%~1"
if not exist "!_SPEC_FILE!" (
    echo [ERROR] JSON specification file not found: !_SPEC_FILE! >&2
    exit /b 1
)
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.name) { $j.name }"`) do set "SCAF_NAME=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.title) { $j.title }"`) do set "SCAF_TITLE=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.category) { $j.category }"`) do set "SCAF_CATEGORY=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.description) { $j.description }"`) do set "SCAF_DESCRIPTION=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.binary_name) { $j.binary_name }"`) do set "SCAF_BINARY_NAME=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.default_install_method) { $j.default_install_method }"`) do set "SCAF_INSTALL_METHOD=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.version_scheme) { $j.version_scheme }"`) do set "SCAF_VERSION_SCHEME=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.github_repo) { $j.github_repo }"`) do set "SCAF_GITHUB_REPO=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.download_url_template_unix) { $j.download_url_template_unix }"`) do set "SCAF_URL_UNIX=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.download_url_template_windows) { $j.download_url_template_windows }"`) do set "SCAF_URL_WINDOWS=%%V"
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$j = Get-Content -Raw '!_SPEC_FILE!' | ConvertFrom-Json; if ($j.releases_url) { $j.releases_url }"`) do set "SCAF_RELEASES_URL=%%V"
exit /b 0

:: ## run_interactive_prompter
:: Prompts the user interactively on the Windows console for component metadata.
:run_interactive_prompter
echo.
echo +--------------------------------------------------------------------+
echo ^|       LibScript Component-Package-Manager Interactive Wizard       ^|
echo +--------------------------------------------------------------------+
echo.
set /p "SCAF_NAME=1. Component name (lowercase, e.g., fd, zoxide, ripgrep) [!SCAF_NAME!]: "
if "!SCAF_CATEGORY!"=="" set "SCAF_CATEGORY=utilities"
set /p "SCAF_CATEGORY=2. Component category [!SCAF_CATEGORY!]: "
if "!SCAF_TITLE!"=="" set "SCAF_TITLE=!SCAF_NAME!"
set /p "SCAF_TITLE=3. Human-readable title [!SCAF_TITLE!]: "
if "!SCAF_DESCRIPTION!"=="" set "SCAF_DESCRIPTION=Installs and manages !SCAF_TITLE! across supported platforms."
set /p "SCAF_DESCRIPTION=4. Concise description [!SCAF_DESCRIPTION!]: "
set /p "SCAF_INSTALL_METHOD=5. Default install method (libscript_native/system/from-source) [!SCAF_INSTALL_METHOD!]: "
set /p "SCAF_VERSION_SCHEME=6. Version scheme (github-release/semver/custom-url) [!SCAF_VERSION_SCHEME!]: "
if /i "!SCAF_VERSION_SCHEME!"=="github-release" (
    set /p "SCAF_GITHUB_REPO=   GitHub owner/repo (e.g., BurntSushi/ripgrep) [!SCAF_GITHUB_REPO!]: "
    set /p "SCAF_TAG_PREFIX=   Release tag prefix [!SCAF_TAG_PREFIX!]: "
)
set /p "SCAF_URL_UNIX=7. Default Unix download URL template [!SCAF_URL_UNIX!]: "
set /p "SCAF_URL_WINDOWS=8. Default Windows download URL template [!SCAF_URL_WINDOWS!]: "
set /p "SCAF_RELEASES_URL=9. Upstream releases URL [!SCAF_RELEASES_URL!]: "
if "!SCAF_BINARY_NAME!"=="" set "SCAF_BINARY_NAME=!SCAF_NAME!"
set /p "SCAF_BINARY_NAME=10. Primary binary executable name [!SCAF_BINARY_NAME!]: "
set /p "SCAF_OS_WHITELIST=11. OS whitelist (comma-separated) [!SCAF_OS_WHITELIST!]: "
if "!SCAF_EXPORT_JSON!"=="" (
    set /p "SCAF_EXPORT_JSON=12. Optional path to export answers as JSON spec (or ENTER to skip): "
)
exit /b 0

:: ## export_spec_to_json
:: Writes the collected specification to a JSON file.
:export_spec_to_json
set "_OUT_JSON=%~1"
(
    echo {
    echo   "$schema": "./component-scaffold.schema.json",
    echo   "name": "!SCAF_NAME!",
    echo   "title": "!SCAF_TITLE!",
    echo   "category": "!SCAF_CATEGORY!",
    echo   "description": "!SCAF_DESCRIPTION!",
    echo   "binary_name": "!SCAF_BINARY_NAME!",
    echo   "default_install_method": "!SCAF_INSTALL_METHOD!",
    echo   "version_scheme": "!SCAF_VERSION_SCHEME!",
    echo   "github_repo": "!SCAF_GITHUB_REPO!",
    echo   "tag_prefix": "!SCAF_TAG_PREFIX!",
    echo   "download_url_template_unix": "!SCAF_URL_UNIX!",
    echo   "download_url_template_windows": "!SCAF_URL_WINDOWS!",
    echo   "releases_url": "!SCAF_RELEASES_URL!",
    echo   "os_whitelist": ["!SCAF_OS_WHITELIST!"]
    echo }
) > "!_OUT_JSON!"
echo [OK] Exported component scaffold JSON spec to !_OUT_JSON!
exit /b 0

:: ## synthesize_component_batch
:: Generates the full Version Manager Contract component files when sh is unavailable on Windows.
:synthesize_component_batch
set "_CDIR=%~1"
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "('!SCAF_NAME!'.ToUpper() -replace '[^A-Z0-9]', '_')"`) do set "COMP_PREFIX=%%P"
if not exist "!_CDIR!\manifest.json" (
    (
        echo {
        echo   "$schema": "../../_common/manifest.schema.json",
        echo   "name": "!SCAF_NAME!",
        echo   "title": "!SCAF_TITLE!",
        echo   "description": "!SCAF_DESCRIPTION!",
        echo   "category": "!SCAF_CATEGORY!",
        echo   "provides": ["!SCAF_NAME!"],
        echo   "os_whitelist": ["all"]
        echo }
    ) > "!_CDIR!\manifest.json"
)
if not exist "!_CDIR!\vars.schema.json" (
    (
        echo {
        echo   "$schema": "https://json-schema.org/draft/2020-12/schema",
        echo   "$id": "/_lib/!SCAF_CATEGORY!/!SCAF_NAME!/vars.schema.json",
        echo   "title": "!SCAF_TITLE! variables",
        echo   "description": "Configuration variables for !SCAF_NAME!",
        echo   "type": "object",
        echo   "properties": {
        echo     "!COMP_PREFIX!_INSTALL_METHOD": {
        echo       "description": "How to install !SCAF_NAME!.",
        echo       "type": "string",
        echo       "enum": ["system", "libscript_native", "from-source"],
        echo       "default": "!SCAF_INSTALL_METHOD!"
        echo     },
        echo     "!COMP_PREFIX!_VERSION": {
        echo       "description": "Specific version of !SCAF_NAME! to install.",
        echo       "type": "string",
        echo       "default": "!SCAF_DEFAULT_VERSION!"
        echo     },
        echo     "!COMP_PREFIX!_DOWNLOAD_URL": {
        echo       "description": "Override URL for downloading !SCAF_NAME! binary or archive artifacts.",
        echo       "type": "string"
        echo     },
        echo     "!COMP_PREFIX!_RELEASES_URL": {
        echo       "description": "Override URL for querying !SCAF_NAME! available remote releases.",
        echo       "type": "string"
        echo     }
        echo   }
        echo }
    ) > "!_CDIR!\vars.schema.json"
)
if not exist "!_CDIR!\README.md" (
    (
        echo # !SCAF_NAME!
        echo.
        echo ## Purpose ^& Current State
        echo.
        echo **Purpose**: !SCAF_DESCRIPTION!
        echo.
        echo ## Usage
        echo.
        echo ```sh
        echo libscript install !SCAF_NAME!
        echo ```
        echo.
        echo ## Configuration Options
        echo.
        echo ^<!-- BEGIN_VARS --^>
        echo ^| Variable ^| Description ^| Default ^|
        echo ^|---^|---^|---^|
        echo ^| `!COMP_PREFIX!_INSTALL_METHOD` ^| How to install !SCAF_NAME!. ^| `!SCAF_INSTALL_METHOD!` ^|
        echo ^| `!COMP_PREFIX!_VERSION` ^| Specific version of !SCAF_NAME! to install. ^| `!SCAF_DEFAULT_VERSION!` ^|
        echo ^<!-- END_VARS --^>
        echo.
        echo ## Platform Support
        echo.
        echo ^<!-- BEGIN_PLATFORMS --^>
        echo - Linux
        echo - macOS
        echo - Windows
        echo ^<!-- END_PLATFORMS --^>
    ) > "!_CDIR!\README.md"
)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$shFile = '!SCRIPT_DIR!\scaffold.sh'; $cdir = '!_CDIR!'; " ^
    "$content = Get-Content -LiteralPath $shFile -Raw; " ^
    "$map = @{ " ^
    "  '__SCAF_NAME__' = '!SCAF_NAME!'; " ^
    "  '__SCAF_TITLE__' = '!SCAF_TITLE!'; " ^
    "  '__SCAF_CATEGORY__' = '!SCAF_CATEGORY!'; " ^
    "  '__SCAF_DESCRIPTION__' = '!SCAF_DESCRIPTION!'; " ^
    "  '__SCAF_BINARY_NAME__' = '!SCAF_BINARY_NAME!'; " ^
    "  '__SCAF_INSTALL_METHOD__' = '!SCAF_INSTALL_METHOD!'; " ^
    "  '__SCAF_DEFAULT_VERSION__' = if ('!SCAF_DEFAULT_VERSION!') { '!SCAF_DEFAULT_VERSION!' } else { 'latest' }; " ^
    "  '__SCAF_VERSION_SCHEME__' = '!SCAF_VERSION_SCHEME!'; " ^
    "  '__SCAF_GITHUB_REPO__' = '!SCAF_GITHUB_REPO!'; " ^
    "  '__SCAF_TAG_PREFIX__' = '!SCAF_TAG_PREFIX!'; " ^
    "  '__SCAF_URL_UNIX__' = '!SCAF_URL_UNIX!'; " ^
    "  '__SCAF_URL_WINDOWS__' = '!SCAF_URL_WINDOWS!'; " ^
    "  '__SCAF_RELEASES_URL__' = '!SCAF_RELEASES_URL!'; " ^
    "  '__SCAF_STRIP_COMPONENTS__' = '!SCAF_STRIP_COMPONENTS!'; " ^
    "  '__SCAF_SRC_URL__' = '!SCAF_URL_UNIX!'; " ^
    "  '__SCAF_SRC_LANG__' = '!SCAF_SRC_LANG!'; " ^
    "  '__SCAF_SRC_BUILD_SYS__' = '!SCAF_SRC_BUILD_SYS!'; " ^
    "  '__SCAF_SRC_FALLBACK_VER__' = '!SCAF_SRC_FALLBACK_VER!'; " ^
    "  '__SCAF_TEST_CMD__' = '!SCAF_TEST_CMD!'; " ^
    "  '__COMP_PREFIX__' = '!COMP_PREFIX!' " ^
    "}; " ^
    "$matches = [regex]::Matches($content, 'write_component_file\s+\"\$\{_comp_dir\}/([^\"]+)\"\s+(\d+)\s+(\d+)\s+<<\s+''EOF''\r?\n([\s\S]*?)\r?\nEOF'); " ^
    "foreach ($m in $matches) { " ^
    "  $fname = $m.Groups[1].Value; $isCrlf = ($m.Groups[3].Value -eq '1'); $body = $m.Groups[4].Value; " ^
    "  foreach ($k in $map.Keys) { $body = $body.Replace($k, $map[$k]) }; " ^
    "  $outPath = Join-Path $cdir $fname; " ^
    "  if (-not (Test-Path $outPath) -or '!SCAF_FORCE!' -eq '1') { " ^
    "    $lines = $body -split '\r?\n'; " ^
    "    $sep = if ($isCrlf) { \"`r`n\" } else { \"`n\" }; " ^
    "    [System.IO.File]::WriteAllText($outPath, ($lines -join $sep) + $sep, (New-Object System.Text.UTF8Encoding $false)) " ^
    "  } " ^
    "}"
exit /b 0

:: ## show_scaffold_help
:: Displays usage instructions and CLI options for the Windows component scaffolder.
:show_scaffold_help
echo LibScript Component-Package-Manager Scaffolder
echo ==============================================
echo.
echo Usage:
echo   .\libscript.cmd scaffold [OPTIONS]
echo   .\libscript.cmd new-component [OPTIONS]
echo.
echo Modes:
echo   --interactive, -i          Run interactive prompter to configure component (default)
echo   --from-json=^<file^>         Non-interactively generate component from JSON spec file
echo   --non-interactive          Run non-interactively using CLI flags
echo.
echo Options:
echo   --export-json=^<file^>       Export normalized component specification to a JSON file
echo   --force, -f                Overwrite existing component files (default: idempotent skip)
echo   --dry-run, -n              Print planned files without writing to disk
echo   --name=^<name^>              Component identifier (e.g., ripgrep, fd)
echo   --category=^<category^>      Target category under _lib/ (e.g., utilities, databases)
echo   --description=^<text^>       Concise component description
echo   --help, -h, /?, -?         Show this help message
exit /b 0
