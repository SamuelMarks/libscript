@echo off
:: # pre-commit.cmd
::
:: ## Overview
:: Handles operations related to the component '.githooks'.
::
:: ## Usage
:: Execute this script to perform actions for .githooks.

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
cd /d "%LIBSCRIPT_ROOT_DIR%"

if exist "%LIBSCRIPT_ROOT_DIR%\_lib\languages\nodejs\env.cmd" (
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\nodejs\env.cmd" >nul 2>&1
)

echo Running pre-commit hooks...

set "AUDIT_MODE=--staged"
set "GIT_FILE_CMD=git diff --no-ext-diff --cached --name-only --diff-filter=ACM"
if /i "%~1"=="--all" (
    set "AUDIT_MODE=--all"
    set "GIT_FILE_CMD=git ls-files --cached --others --exclude-standard"
)

:: 1. Enforce line endings and indent via Prettier where applicable
where npx >nul 2>&1
if not errorlevel 1 (
    if /i not "%AUDIT_MODE%"=="--all" (
        for /f "tokens=*" %%F in ('git diff --no-ext-diff --cached --name-only --diff-filter=ACM 2^>nul') do (
            if exist "%%F" (
                set "_EXT=%%~xF"
                if /i "!_EXT!"==".json" (
                    call npx --yes prettier --write "%%F" >nul 2>&1
                    git add "%%F"
                ) else if /i "!_EXT!"==".yml" (
                    call npx --yes prettier --write "%%F" >nul 2>&1
                    git add "%%F"
                ) else if /i "!_EXT!"==".yaml" (
                    call npx --yes prettier --write "%%F" >nul 2>&1
                    git add "%%F"
                ) else if /i "!_EXT!"==".md" (
                    call npx --yes prettier --write "%%F" >nul 2>&1
                    git add "%%F"
                )
            )
        )
    )
)

:: 2. Spellcheck
where npx >nul 2>&1
if not errorlevel 1 (
    echo Running spellcheck...
    set "TMP_SPELL=%TEMP%\staged_spell_%RANDOM%.txt"
    !GIT_FILE_CMD! > "!TMP_SPELL!" 2>nul
    if exist "!TMP_SPELL!" (
        for %%S in ("!TMP_SPELL!") do if %%~zS gtr 0 (
            call npx --yes --quiet cspell lint --no-progress --no-summary --no-must-find-files --file-list stdin < "!TMP_SPELL!"
            if errorlevel 1 (
                del /f /q "!TMP_SPELL!" >nul 2>&1
                echo [ERROR] Spellcheck failed. Fix typos or add words to .cspell.json.
                exit /b 1
            )
        )
        del /f /q "!TMP_SPELL!" >nul 2>&1
    )
)

:: 3. LibScript Standards Audit
if exist "devtools\audit\audit_standards.cmd" (
    echo Running LibScript engineering standards audit...
    call "devtools\audit\audit_standards.cmd" !AUDIT_MODE!
    if errorlevel 1 (
        echo [ERROR] Standards audit failed. Please fix violations before committing.
        exit /b 1
    )
)

if exist "devtools\audit\audit_posix.cmd" (
    echo Running POSIX and companion parity audit...
    call "devtools\audit\audit_posix.cmd" !AUDIT_MODE!
    if errorlevel 1 (
        echo [ERROR] POSIX and companion parity audit failed.
        exit /b 1
    )
)

if exist "devtools\audit\audit_version_manager.cmd" (
    echo Running Version Manager Contract audit...
    call "devtools\audit\audit_version_manager.cmd"
    if errorlevel 1 (
        echo [ERROR] Version Manager Contract audit failed.
        exit /b 1
    )
)

if exist "devtools\audit\audit_schema_vars.cmd" (
    echo Running Schema Variable Coverage audit...
    call "devtools\audit\audit_schema_vars.cmd" !AUDIT_MODE!
    if errorlevel 1 (
        echo [ERROR] Schema Variable Coverage audit failed.
        exit /b 1
    )
)

:: 4. ShellCheck (bootstrapped via _lib\toolchains\shellcheck when nonexistent)
call :ensure_shellcheck_bootstrapped
if errorlevel 1 (
    echo [ERROR] ShellCheck bootstrap failed.
    exit /b 1
)
echo Running shellcheck...
set "SHELLCHECK_OPT_ARGS="
shellcheck --list-optional 2>nul | findstr /C:"useless-use-of-cat" >nul 2>&1
if not errorlevel 1 set "SHELLCHECK_OPT_ARGS=-o useless-use-of-cat"
for /f "tokens=*" %%F in ('!GIT_FILE_CMD! 2^>nul ^| findstr /R "\.sh$ ^\.githooks/pre-commit$" ^| findstr /V /R "node_modules \.git/ gen/"') do (
    if exist "%%F" (
        shellcheck -s sh !SHELLCHECK_OPT_ARGS! "%%F"
        if errorlevel 1 (
            echo [ERROR] ShellCheck failed on %%F.
            exit /b 1
        )
    )
)

if exist "devtools\docs-gen\generate_markdown_docs.cmd" (
    echo Regenerating markdown readme files interpolating the json...
    call "devtools\docs-gen\generate_markdown_docs.cmd"
    if errorlevel 1 (
        echo [ERROR] generate_markdown_docs.cmd failed.
        exit /b 1
    )
    for /f "delims=" %%F in ('git ls-files -m ^| findstr /E "README.md"') do (
        where npx >nul 2>&1
        if not errorlevel 1 (
            call npx --yes prettier --write "%%F" >nul 2>&1
        )
        git add "%%F"
    )
)

if exist "tests\update_results.cmd" (
    echo Updating Supported Components in README.md...
    call "tests\update_results.cmd"
    if errorlevel 1 (
        echo [ERROR] update_results.cmd failed.
        exit /b 1
    )
)

if exist "devtools\audit\doc_coverage.cmd" (
    echo Updating Doc Coverage shield in README.md...
    call "devtools\audit\doc_coverage.cmd" --update-readme
    if errorlevel 1 (
        echo [ERROR] Documentation coverage audit failed. Please fix missing documentation before committing.
        exit /b 1
    )
)

git diff --quiet -- README.md >nul 2>&1
if errorlevel 1 (
    where npx >nul 2>&1
    if not errorlevel 1 (
        call npx --yes prettier --write README.md >nul 2>&1
    )
    git add README.md
)

echo Pre-commit hook completed successfully.
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
