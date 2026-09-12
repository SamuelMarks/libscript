@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # run_native_tests.cmd
::
:: ## Overview
:: Runs native tests directly on the current Windows host environment across
:: specified targets or categories without Vagrant. Results are written to tests_tmp.
::
:: ## Usage
:: tests\run_native_tests.cmd [TARGETS...|all] [--category <category>] [--dry-run] [--help]
:: Examples:
::   tests\run_native_tests.cmd sqlite curl
::   tests\run_native_tests.cmd --category databases
::   tests\run_native_tests.cmd all

set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"

set "REPO_ROOT=%THIS_DIR%\.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"

set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"
if not exist "%TESTS_TMP_DIR%" mkdir "%TESTS_TMP_DIR%"

set "DRY_RUN=0"
set "ARGS="

:: ## parse_args
:: Parses command line arguments and switches.
:parse_args
if "%~1"=="" goto :done_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--dry-run" (
    set "DRY_RUN=1"
    shift
    goto :parse_args
)
if /I "%~1"=="--category" (
    set "CAT_NAME=%~2"
    if exist "%REPO_ROOT%\_lib\!CAT_NAME!\*" (
        for /d %%D in ("%REPO_ROOT%\_lib\!CAT_NAME!\*") do (
            set "cname=%%~nxD"
            if not "!cname:~0,1!"=="_" (
                set "ARGS=!ARGS! !cname!"
            )
        )
    ) else (
        echo Error: Category '!CAT_NAME!' not found in %REPO_ROOT%\_lib\
        exit /b 1
    )
    shift
    shift
    goto :parse_args
)
set "ARGS=!ARGS! %1"
shift
goto :parse_args

:: ## done_args
:: Finalizes target list after argument parsing.
:done_args
if "!ARGS!"=="" set "ARGS=databases languages toolchains"

set "TARGETS="
for %%A in (!ARGS!) do (
    if /I "%%A"=="all" (
        for /d %%C in ("%REPO_ROOT%\_lib\*") do (
            set "cat_name=%%~nxC"
            if not "!cat_name:~0,1!"=="_" (
                for /d %%D in ("%%C\*") do (
                    set "comp_name=%%~nxD"
                    if not "!comp_name:~0,1!"=="_" (
                        set "TARGETS=!TARGETS! !comp_name!"
                    )
                )
            )
        )
    ) else if exist "%REPO_ROOT%\_lib\%%A\*" (
        for /d %%D in ("%REPO_ROOT%\_lib\%%A\*") do (
            set "comp_name=%%~nxD"
            if not "!comp_name:~0,1!"=="_" (
                set "TARGETS=!TARGETS! !comp_name!"
            )
        )
    ) else (
        set "FOUND=0"
        for /d %%C in ("%REPO_ROOT%\_lib\*") do (
            if exist "%%C\%%A\*" (
                set "TARGETS=!TARGETS! %%A"
                set "FOUND=1"
            )
        )
        if "!FOUND!"=="0" echo Warning: Target '%%A' not found.
    )
)

:: ## execute_targets
:: Iterates through targets and executes native install and test lifecycle.
:execute_targets
for %%T in (!TARGETS!) do (
    set "TARGET_NAME=%%T"
    set "MANIFEST_PATH="
    for /d %%C in ("%REPO_ROOT%\_lib\*") do (
        if exist "%%C\!TARGET_NAME!\manifest.json" (
            set "MANIFEST_PATH=%%C\!TARGET_NAME!\manifest.json"
        )
    )

    set "SKIP_TARGET=0"
    if defined MANIFEST_PATH (
        if exist "!MANIFEST_PATH!" (
            findstr /i /c:""windows"" "!MANIFEST_PATH!" >nul 2>&1
            if !errorlevel! equ 0 (
                findstr /i /c:""os_blacklist"" "!MANIFEST_PATH!" >nul 2>&1
                if !errorlevel! equ 0 (
                    :: Simple check if windows appears in blacklist
                    findstr /c:"os_blacklist" "!MANIFEST_PATH!" >nul 2>&1
                )
            )
        )
    )

    echo ============================================================
    echo Running native test for !TARGET_NAME! on Windows...
    echo ============================================================

    set "STDOUT_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.windows.stdout"
    set "STDERR_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.windows.stderr"
    set "SUCCESS_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.windows.success"
    set "FAILURE_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.windows.failure"

    if exist "!SUCCESS_FILE!" del /f "!SUCCESS_FILE!"
    if exist "!FAILURE_FILE!" del /f "!FAILURE_FILE!"

    if "!DRY_RUN!"=="1" (
        echo Dry-run successful for !TARGET_NAME! on Windows > "!STDOUT_FILE!"
        type nul > "!STDERR_FILE!"
        echo Success > "!SUCCESS_FILE!"
        echo [OK - DRY RUN] !TARGET_NAME!
    ) else (
        set "LIBSCRIPT_ROOT_DIR=%REPO_ROOT%"
        call "%REPO_ROOT%\libscript.cmd" install !TARGET_NAME! > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
        set "RUN_EXIT=!errorlevel!"
        if !RUN_EXIT! equ 0 (
            call "%REPO_ROOT%\libscript.cmd" test !TARGET_NAME! >> "!STDOUT_FILE!" 2>> "!STDERR_FILE!"
            set "RUN_EXIT=!errorlevel!"
        )

        if !RUN_EXIT! equ 0 (
            echo Success > "!SUCCESS_FILE!"
            echo [OK] !TARGET_NAME!
        ) else (
            echo Failure > "!FAILURE_FILE!"
            echo [FAILED] !TARGET_NAME!
        )
    )
)

:: ## finalize_reporting
:: Invokes update_results.cmd to refresh root README matrix.
:finalize_reporting
if exist "%THIS_DIR%\update_results.cmd" (
    call "%THIS_DIR%\update_results.cmd" "%REPO_ROOT%"
)

echo All native tests complete. Results are in %TESTS_TMP_DIR%.
goto :eof

:: ## show_help
:: Displays command line help and usage instructions.
:show_help
echo Usage: %~nx0 [TARGETS...^|all] [--category ^<category^>] [--dry-run] [--help]
echo.
echo Runs native tests directly on the current Windows host environment across
echo specified targets or categories to verify libscript installation and test commands.
echo.
echo Options:
echo   TARGETS...           One or more component names to test (e.g., sqlite curl).
echo   all                  Test all discovered components in _lib\.
echo   --category ^<cat^>     Test all components within a given category (e.g. databases).
echo   --dry-run            Simulate test execution without calling libscript install/test.
echo   --help, -h, /?       Show this help message.
echo.
echo Results and output logs are written to tests_tmp\.
endlocal
