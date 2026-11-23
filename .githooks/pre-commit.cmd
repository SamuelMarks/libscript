@echo off
:: # pre-commit.cmd
:: ## Overview
:: Zero-PowerShell Windows Batch Git pre-commit orchestrator executing staged Prettier normalization,
:: concurrent static audits (`cspell`, `audit_standards`, `audit_posix`, `audit_tiers`,
:: `audit_version_manager`, `audit_schema_vars`, `shellcheck`, `wincheck`, `doc_coverage`),
:: and parallel schema/README synchronization via `engine\common\parallel.cmd` (falling back sequentially on MS-DOS).
:: ## Usage
:: .githooks\pre-commit.cmd [--all]

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

if /I "%~1"=="--sc-worker" goto :sc_worker_entry
if /I "%~1"=="--wc-worker" goto :wc_worker_entry
if /I "%~1"=="--cspell-worker" goto :cspell_worker_entry

set "HOOK_REPO_ROOT=%LIBSCRIPT_ROOT_DIR%"
for /f "delims=" %%R in ('git rev-parse --show-toplevel 2^>nul') do set "HOOK_REPO_ROOT=%%~fR"
cd /d "!HOOK_REPO_ROOT!"

set "_PC_LS_HOME=%LIBSCRIPT_HOME%"
if "!_PC_LS_HOME!"=="" set "_PC_LS_HOME=%USERPROFILE%\.libscript"
if exist "!_PC_LS_HOME!\bin" (
    echo ";!PATH!;" | findstr /I /C:";!_PC_LS_HOME!\bin;" >nul 2>&1
    if errorlevel 1 set "PATH=!PATH!;!_PC_LS_HOME!\bin"
)

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\languages\nodejs\env.cmd" (
    set "_PC_SAVED_ST=!STACK!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\nodejs\env.cmd" >nul 2>&1
    set "STACK=!_PC_SAVED_ST!"
)

where jq >nul 2>&1
if errorlevel 1 if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
    set "_PC_SAVED_ST=!STACK!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
    set "STACK=!_PC_SAVED_ST!"
)

set "_PC_SAVED_ST=!STACK!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :detect_jobs
set "STACK=!_PC_SAVED_ST!"
if "!LIBSCRIPT_RESOLVED_JOBS!"=="" set "LIBSCRIPT_RESOLVED_JOBS=1"

echo Running pre-commit hooks ^(jobs=!LIBSCRIPT_RESOLVED_JOBS!^)...

set "AUDIT_MODE=--staged"
set "GIT_FILE_CMD=git diff --no-ext-diff --cached --name-only --diff-filter=ACM"
if /I "%~1"=="--all" (
    set "AUDIT_MODE=--all"
    set "GIT_FILE_CMD=git ls-files --cached --others --exclude-standard"
)

set "_PC_BASE=%TEMP%"
if "!_PC_BASE!"=="" set "_PC_BASE=!LIBSCRIPT_ROOT_DIR!\tests_tmp"
set "_PC_WORK=!_PC_BASE!\lsp_pc_!RANDOM!_!RANDOM!"
if not exist "!_PC_WORK!" mkdir "!_PC_WORK!"

set "_PC_STAGED=!_PC_WORK!\STAGED.TXT"
set "_PC_CHECK=!_PC_WORK!\CHECK.TXT"
type nul > "!_PC_STAGED!"
type nul > "!_PC_CHECK!"

git diff --no-ext-diff --cached --name-only --diff-filter=ACM > "!_PC_STAGED!" 2>nul
if /I "!AUDIT_MODE!"=="--all" (
    !GIT_FILE_CMD! > "!_PC_CHECK!" 2>nul
) else (
    for /f "usebackq delims=" %%F in ("!_PC_STAGED!") do (
        if exist "%%F" echo.%%F>> "!_PC_CHECK!"
    )
)

:: Wave 1: Batched Prettier normalization + idempotent toolchain bootstrap
where npx >nul 2>&1
if not errorlevel 1 if not "%LIBSCRIPT_OFFLINE%"=="1" (
    if /I not "!AUDIT_MODE!"=="--all" (
        call :format_staged_batches
    )
)

call :ensure_shellcheck_bootstrapped
if errorlevel 1 (
    rmdir /s /q "!_PC_WORK!" >nul 2>&1
    exit /b 1
)

set "SHELLCHECK_OPT_ARGS="
shellcheck --list-optional 2>nul | findstr /C:"useless-use-of-cat" >nul 2>&1
if not errorlevel 1 set "SHELLCHECK_OPT_ARGS=-o useless-use-of-cat"

set "_PC_SC_LIST=!_PC_WORK!\SC.TXT"
set "_PC_WC_LIST=!_PC_WORK!\WC.TXT"
type nul > "!_PC_SC_LIST!"
type nul > "!_PC_WC_LIST!"
!GIT_FILE_CMD! -- "*.sh" ".githooks/pre-commit" > "!_PC_WORK!\RAW_SC.TXT" 2>nul
for /f "usebackq delims=" %%S in ("!_PC_WORK!\RAW_SC.TXT") do (
    call :maybe_add_sc_file "%%S"
)
!GIT_FILE_CMD! -- "*.cmd" "*.bat" > "!_PC_WORK!\RAW_WC.TXT" 2>nul
for /f "usebackq delims=" %%W in ("!_PC_WORK!\RAW_WC.TXT") do (
    call :maybe_add_wc_file "%%W"
)

set "_HAS_WC=0"
for %%Z in ("!_PC_WC_LIST!") do if not "%%~zZ"=="0" set "_HAS_WC=1"
if "!_HAS_WC!"=="1" (
    call :ensure_wincheck_bootstrapped
    if errorlevel 1 (
        rmdir /s /q "!_PC_WORK!" >nul 2>&1
        exit /b 1
    )
)

:: Wave 2: Concurrent static audits & linters
set "_WAVE2=!_PC_WORK!\WAVE2.TXT"
type nul > "!_WAVE2!"

set "_HAS_CHK=0"
for %%Z in ("!_PC_CHECK!") do if not "%%~zZ"=="0" set "_HAS_CHK=1"
if "!_HAS_CHK!"=="1" (
    >>"!_WAVE2!" echo call "!THIS_FILE!" --cspell-worker "!_PC_CHECK!"
)
if exist "!HOOK_REPO_ROOT!\devtools\audit\audit_standards.cmd" (
    >>"!_WAVE2!" echo call "!HOOK_REPO_ROOT!\devtools\audit\audit_standards.cmd" !AUDIT_MODE!
)
if exist "!HOOK_REPO_ROOT!\devtools\audit\audit_posix.cmd" (
    >>"!_WAVE2!" echo call "!HOOK_REPO_ROOT!\devtools\audit\audit_posix.cmd" !AUDIT_MODE!
)
if exist "!HOOK_REPO_ROOT!\devtools\audit\audit_tiers.cmd" (
    >>"!_WAVE2!" echo call "!HOOK_REPO_ROOT!\devtools\audit\audit_tiers.cmd" !AUDIT_MODE!
)
if exist "!HOOK_REPO_ROOT!\devtools\audit\audit_version_manager.cmd" (
    set "_RUN_VM=0"
    if /I "!AUDIT_MODE!"=="--all" set "_RUN_VM=1"
    if "!_RUN_VM!"=="0" (
        findstr /R /C:"^_lib[/\\]" "!_PC_CHECK!" >nul 2>&1
        if not errorlevel 1 set "_RUN_VM=1"
    )
    if "!_RUN_VM!"=="1" (
        >>"!_WAVE2!" echo call "!HOOK_REPO_ROOT!\devtools\audit\audit_version_manager.cmd"
    )
)
if exist "!HOOK_REPO_ROOT!\devtools\audit\audit_schema_vars.cmd" (
    set "_RUN_SV=0"
    if /I "!AUDIT_MODE!"=="--all" set "_RUN_SV=1"
    if "!_RUN_SV!"=="0" (
        findstr /R /C:"^_lib[/\\]" /C:"\.schema\.json$" "!_PC_CHECK!" >nul 2>&1
        if not errorlevel 1 set "_RUN_SV=1"
    )
    if "!_RUN_SV!"=="1" (
        >>"!_WAVE2!" echo call "!HOOK_REPO_ROOT!\devtools\audit\audit_schema_vars.cmd" !AUDIT_MODE!
    )
)

echo Running shellcheck...
set "_HAS_SC=0"
for %%Z in ("!_PC_SC_LIST!") do if not "%%~zZ"=="0" set "_HAS_SC=1"
if "!_HAS_SC!"=="1" (
    >>"!_WAVE2!" echo call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_shards "!_PC_SC_LIST!" "!THIS_FILE! --sc-worker"
)
if "!_HAS_WC!"=="1" (
    echo Running wincheck...
    >>"!_WAVE2!" echo call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_shards "!_PC_WC_LIST!" "!THIS_FILE! --wc-worker"
)
if exist "!HOOK_REPO_ROOT!\devtools\audit\doc_coverage.cmd" (
    >>"!_WAVE2!" echo call "!HOOK_REPO_ROOT!\devtools\audit\doc_coverage.cmd" --strict
)

set "_PC_SAVED_ST=!STACK!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_tasks "!_WAVE2!"
set "_W2_RC=!ERRORLEVEL!"
set "STACK=!_PC_SAVED_ST!"
if not "!_W2_RC!"=="0" (
    echo [ERROR] One or more concurrent pre-commit audits failed. 1>&2
    rmdir /s /q "!_PC_WORK!" >nul 2>&1
    exit /b 1
)

:: Wave 3: Parallel + staged fast-path Markdown & README table synchronization
set "_NEED_GMD=0"
set "_NEED_UR=0"
if /I "!AUDIT_MODE!"=="--all" (
    set "_NEED_GMD=1"
    set "_NEED_UR=1"
) else if "!_HAS_CHK!"=="1" (
    findstr /I /R /C:"vars\.schema\.json$" /C:"schemas[/\\]vars[/\\]" /C:"devtools[/\\]docs-gen[/\\]" /C:"README\.md$" "!_PC_CHECK!" >nul 2>&1
    if not errorlevel 1 set "_NEED_GMD=1"
    findstr /I /R /C:"manifest\.json$" /C:"README\.md$" /C:"TODO_PLAN\.md$" /C:"update_results\." "!_PC_CHECK!" >nul 2>&1
    if not errorlevel 1 set "_NEED_UR=1"
)

set "_WAVE3=!_PC_WORK!\WAVE3.TXT"
type nul > "!_WAVE3!"
if "!_NEED_GMD!"=="1" if exist "!HOOK_REPO_ROOT!\devtools\docs-gen\generate_markdown_docs.cmd" (
    echo Regenerating markdown readme files interpolating the json...
    >>"!_WAVE3!" echo call "!HOOK_REPO_ROOT!\devtools\docs-gen\generate_markdown_docs.cmd"
)
if "!_NEED_UR!"=="1" if exist "!HOOK_REPO_ROOT!\tests\update_results.cmd" (
    echo Updating Supported Components in README.md...
    >>"!_WAVE3!" echo call "!HOOK_REPO_ROOT!\tests\update_results.cmd"
)

for %%Z in ("!_WAVE3!") do if not "%%~zZ"=="0" (
    set "_PC_SAVED_ST=!STACK!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\parallel.cmd" :run_tasks "!_WAVE3!" 2
    set "_W3_RC=!ERRORLEVEL!"
    set "STACK=!_PC_SAVED_ST!"
    if not "!_W3_RC!"=="0" (
        rmdir /s /q "!_PC_WORK!" >nul 2>&1
        exit /b 1
    )
)

if "!_NEED_GMD!"=="1" (
    for /f "delims=" %%F in ('git ls-files -m 2^>nul') do (
        if /I "%%~nxF"=="README.md" (
            where npx >nul 2>&1
            if not errorlevel 1 if not "%LIBSCRIPT_OFFLINE%"=="1" (
                call npx --yes prettier --write "%%F" >nul 2>&1
            )
            git add "%%F"
        )
    )
)

if "!_NEED_UR!"=="1" if exist "!HOOK_REPO_ROOT!\devtools\audit\doc_coverage.cmd" (
    echo Updating Doc Coverage shield in README.md...
    call "!HOOK_REPO_ROOT!\devtools\audit\doc_coverage.cmd" --update-readme
    if errorlevel 1 (
        rmdir /s /q "!_PC_WORK!" >nul 2>&1
        exit /b 1
    )
)

if exist "README.md" (
    git diff --quiet -- README.md >nul 2>&1
    if errorlevel 1 (
        where npx >nul 2>&1
        if not errorlevel 1 if not "%LIBSCRIPT_OFFLINE%"=="1" (
            call npx --yes prettier --write README.md >nul 2>&1
        )
        git add README.md
    )
)

rmdir /s /q "!_PC_WORK!" >nul 2>&1
echo Pre-commit hook completed successfully.
exit /b 0

:: ## format_staged_batches
:: Formats staged JSON, YAML, and Markdown files in batches of 40 via Prettier and re-stages them.
:format_staged_batches
set "_FMT_B="
set /a "_FMT_N=0"
for /f "usebackq delims=" %%F in ("!_PC_STAGED!") do (
    if exist "%%F" (
        set "_EXT=%%~xF"
        set "_DO_FMT=0"
        if /I "!_EXT!"==".json" set "_DO_FMT=1"
        if /I "!_EXT!"==".yml" set "_DO_FMT=1"
        if /I "!_EXT!"==".yaml" set "_DO_FMT=1"
        if /I "!_EXT!"==".md" set "_DO_FMT=1"
        if "!_DO_FMT!"=="1" (
            set "_FMT_B=!_FMT_B! "%%F""
            set /a "_FMT_N+=1"
            if "!_FMT_N!"=="40" (
                call npx --yes prettier --write !_FMT_B! >nul 2>&1
                git add -- !_FMT_B! >nul 2>&1
                set "_FMT_B="
                set /a "_FMT_N=0"
            )
        )
    )
)
if not "!_FMT_N!"=="0" (
    call npx --yes prettier --write !_FMT_B! >nul 2>&1
    git add -- !_FMT_B! >nul 2>&1
)
exit /b 0

:: ## maybe_add_sc_file
:: Appends an existing non-excluded POSIX script path to _PC_SC_LIST.
:maybe_add_sc_file
set "_MSC_F=%~1"
set "_MSC_N=!_MSC_F:\=/!"
if not "!_MSC_N:node_modules/=!"=="!_MSC_N!" exit /b 0
if not "!_MSC_N:.git/=!"=="!_MSC_N!" exit /b 0
if /I "!_MSC_N:~0,4!"=="gen/" exit /b 0
if not "!_MSC_N:/gen/=!"=="!_MSC_N!" exit /b 0
if exist "!_MSC_F!" echo.!_MSC_F!>> "!_PC_SC_LIST!"
exit /b 0

:: ## maybe_add_wc_file
:: Appends an existing non-excluded Windows Batch script path to _PC_WC_LIST.
:maybe_add_wc_file
set "_MWC_F=%~1"
set "_MWC_N=!_MWC_F:\=/!"
if not "!_MWC_N:node_modules/=!"=="!_MWC_N!" exit /b 0
if not "!_MWC_N:.git/=!"=="!_MWC_N!" exit /b 0
if not "!_MWC_N:tests_tmp/=!"=="!_MWC_N!" exit /b 0
if not "!_MWC_N:cache/=!"=="!_MWC_N!" exit /b 0
if not "!_MWC_N:build/=!"=="!_MWC_N!" exit /b 0
if /I "!_MWC_N:~0,4!"=="gen/" exit /b 0
if not "!_MWC_N:/gen/=!"=="!_MWC_N!" exit /b 0
if exist "!_MWC_F!" echo.!_MWC_F!>> "!_PC_WC_LIST!"
exit /b 0

:: ## load_shellcheck_env
:: Loads the isolated ShellCheck version manager PATH while preserving STACK state.
:load_shellcheck_env
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\shellcheck\env.cmd" (
    set "_SC_SAVED_STACK=%STACK%"
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\shellcheck\env.cmd" >nul 2>&1
    set "STACK=!_SC_SAVED_STACK!"
)
exit /b 0

:: ## ensure_shellcheck_bootstrapped
:: Ensures shellcheck is available on PATH on Windows, installing it via LibScript when nonexistent.
:ensure_shellcheck_bootstrapped
call :load_shellcheck_env
where shellcheck >nul 2>&1
if not errorlevel 1 exit /b 0
echo [BOOTSTRAP] shellcheck not found on PATH; installing via LibScript version manager...
set "_SC_BOOT_VER=%SHELLCHECK_VERSION%"
if "!_SC_BOOT_VER!"=="" set "_SC_BOOT_VER=latest"
set "_PC_SAVED_STACK=%STACK%"
set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install shellcheck "!_SC_BOOT_VER!"
set "_SC_INST_RC=!errorlevel!"
set "STACK=!_PC_SAVED_STACK!"
if not "!_SC_INST_RC!"=="0" (
    echo [ERROR] Failed to bootstrap shellcheck via LibScript version manager. 1>&2
    exit /b 1
)
call :load_shellcheck_env
where shellcheck >nul 2>&1
if errorlevel 1 (
    echo [ERROR] shellcheck still not found on PATH after bootstrap. 1>&2
    exit /b 1
)
exit /b 0

:: ## load_wincheck_env
:: Loads the isolated win-cmd-rs version manager PATH while preserving STACK state.
:load_wincheck_env
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\win-cmd-rs\env.cmd" (
    set "_WC_SAVED_STACK=%STACK%"
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\toolchains\win-cmd-rs\env.cmd" >nul 2>&1
    set "STACK=!_WC_SAVED_STACK!"
)
exit /b 0

:: ## ensure_wincheck_bootstrapped
:: Ensures wincheck is available on PATH on Windows, installing win-cmd-rs via LibScript when nonexistent.
:ensure_wincheck_bootstrapped
call :load_wincheck_env
where wincheck >nul 2>&1
if not errorlevel 1 exit /b 0
echo [BOOTSTRAP] wincheck not found on PATH; installing via LibScript version manager...
set "_WC_BOOT_VER=%WIN_CMD_RS_VERSION%"
if "!_WC_BOOT_VER!"=="" set "_WC_BOOT_VER=latest"
set "_PC_SAVED_STACK=%STACK%"
set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install win-cmd-rs "!_WC_BOOT_VER!"
set "_WC_INST_RC=!errorlevel!"
set "STACK=!_PC_SAVED_STACK!"
if not "!_WC_INST_RC!"=="0" (
    echo [ERROR] Failed to bootstrap win-cmd-rs ^(wincheck^) via LibScript version manager. 1>&2
    exit /b 1
)
call :load_wincheck_env
where wincheck >nul 2>&1
if errorlevel 1 (
    echo [ERROR] wincheck still not found on PATH after bootstrap. 1>&2
    exit /b 1
)
exit /b 0

:: ## cspell_worker_entry
:: Runs cspell spellcheck against the candidate list file %~2 when cspell or npx is available.
:cspell_worker_entry
set "_CSW_LIST=%~2"
if "!_CSW_LIST!"=="" exit /b 0
if not exist "!_CSW_LIST!" exit /b 0
where cspell >nul 2>&1
if not errorlevel 1 (
    echo Running spellcheck...
    call cspell lint --no-progress --no-summary --no-must-find-files --file-list stdin < "!_CSW_LIST!"
    if errorlevel 1 (
        echo [ERROR] Spellcheck failed. Fix typos or add words to .cspell.json. 1>&2
        exit /b 1
    )
    exit /b 0
)
where npx >nul 2>&1
if not errorlevel 1 if not "%LIBSCRIPT_OFFLINE%"=="1" (
    echo Running spellcheck...
    call npx --yes --quiet cspell lint --no-progress --no-summary --no-must-find-files --file-list stdin < "!_CSW_LIST!"
    if errorlevel 1 (
        echo [ERROR] Spellcheck failed. Fix typos or add words to .cspell.json. 1>&2
        exit /b 1
    )
)
exit /b 0

:: ## sc_worker_entry
:: Runs shellcheck in pure Batch batches of 50 across shard file %~2.
:sc_worker_entry
set "_SCW_SHARD=%~2"
if "!_SCW_SHARD!"=="" exit /b 0
if not exist "!_SCW_SHARD!" exit /b 0
call :load_shellcheck_env
set "SHELLCHECK_OPT_ARGS="
shellcheck --list-optional 2>nul | findstr /C:"useless-use-of-cat" >nul 2>&1
if not errorlevel 1 set "SHELLCHECK_OPT_ARGS=-o useless-use-of-cat"
set "_SCW_B="
set /a "_SCW_N=0"
set "_SCW_FAIL=0"
for /f "usebackq delims=" %%F in ("!_SCW_SHARD!") do (
    set "_SCW_B=!_SCW_B! "%%F""
    set /a "_SCW_N+=1"
    if "!_SCW_N!"=="50" (
        shellcheck -s sh !SHELLCHECK_OPT_ARGS! !_SCW_B!
        if errorlevel 1 set "_SCW_FAIL=1"
        set "_SCW_B="
        set /a "_SCW_N=0"
    )
)
if not "!_SCW_N!"=="0" (
    shellcheck -s sh !SHELLCHECK_OPT_ARGS! !_SCW_B!
    if errorlevel 1 set "_SCW_FAIL=1"
)
if "!_SCW_FAIL!"=="1" exit /b 1
exit /b 0

:: ## wc_worker_entry
:: Runs wincheck in pure Batch batches of 60 across shard file %~2.
:wc_worker_entry
set "_WCW_SHARD=%~2"
if "!_WCW_SHARD!"=="" exit /b 0
if not exist "!_WCW_SHARD!" exit /b 0
call :load_wincheck_env
set "_WCW_EXCL=%LIBSCRIPT_WINCHECK_EXCLUDE%"
if "!_WCW_EXCL!"=="" set "_WCW_EXCL=CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010"
set "_WCW_B="
set /a "_WCW_N=0"
set "_WCW_FAIL=0"
for /f "usebackq delims=" %%F in ("!_WCW_SHARD!") do (
    set "_WCW_B=!_WCW_B! "%%F""
    set /a "_WCW_N+=1"
    if "!_WCW_N!"=="60" (
        wincheck --exclude "!_WCW_EXCL!" !_WCW_B!
        if errorlevel 1 set "_WCW_FAIL=1"
        set "_WCW_B="
        set /a "_WCW_N=0"
    )
)
if not "!_WCW_N!"=="0" (
    wincheck --exclude "!_WCW_EXCL!" !_WCW_B!
    if errorlevel 1 set "_WCW_FAIL=1"
)
if "!_WCW_FAIL!"=="1" exit /b 1
exit /b 0
