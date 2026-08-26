@echo off
:: run_local_tests.cmd
::
:: Runs local tests using Vagrant across all toolchains, languages, and databases
:: to verify libscript installation and testing on isolated Vagrant VMs.
::
:: Results are written to the tests_tmp directory.

setlocal EnableDelayedExpansion

set "OS_TARGET=alpine-3.24"
set "ARGS="

:parse_args
if "%~1"=="" goto :done_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="--os" (
    set "OS_TARGET=%~2"
    shift
    shift
    goto :parse_args
)
set "ARGS=!ARGS! %1"
shift
goto :parse_args

:done_args

set "THIS_DIR=%~dp0"
:: Remove trailing slash
set "THIS_DIR=%THIS_DIR:~0,-1%"

set "REPO_ROOT=%THIS_DIR%\.."
set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"

if not exist "%TESTS_TMP_DIR%" mkdir "%TESTS_TMP_DIR%"

if "!ARGS!"=="" set "ARGS=databases languages toolchains"

if not exist "%REPO_ROOT%\vagrant\!OS_TARGET!\Vagrantfile" (
    echo Error: Vagrant environment '!OS_TARGET!' not found in %REPO_ROOT%\vagrant\
    exit /b 1
)

set "TARGETS="
for %%A in (!ARGS!) do (
    if /I "%%A"=="all" (
        for /d %%C in ("%REPO_ROOT%\_lib\*") do (
            if /I not "%%~nxC"=="_common" (
                for /d %%D in ("%%C\*") do (
                    set "TARGETS=!TARGETS! %%~nxD"
                )
            )
        )
    ) else if exist "%REPO_ROOT%\_lib\%%A\*" (
        for /d %%D in ("%REPO_ROOT%\_lib\%%A\*") do (
            set "TARGETS=!TARGETS! %%~nxD"
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

:: Extract OS_ID for log naming (e.g. alpine from alpine-3.24)
for /f "tokens=1 delims=-" %%I in ("!OS_TARGET!") do set "OS_ID=%%I"

:: Enumerate targets and test them
for %%T in (!TARGETS!) do (
    set "TARGET_NAME=%%T"
    
    echo ============================================================
    echo Running test for !TARGET_NAME! on !OS_TARGET!...
    echo ============================================================
        
        set "LIBSCRIPT_TEST_TARGET=!TARGET_NAME!"
        set "LIBSCRIPT_REPO_ROOT=%REPO_ROOT%"
        
        :: Create an isolated environment for this run
        set "RUN_DIR=%TESTS_TMP_DIR%\runs\!TARGET_NAME!-!OS_TARGET!"
        if not exist "!RUN_DIR!" mkdir "!RUN_DIR!"
        copy /Y "%REPO_ROOT%\vagrant\!OS_TARGET!\Vagrantfile" "!RUN_DIR!\Vagrantfile" >nul
        
        cd /d "!RUN_DIR!"
        
        :: Ensure clean state (in case of previous aborted runs in this dir)
        vagrant destroy -f >nul 2>&1
        timeout /t 2 /nobreak >nul
        
        set "STDOUT_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.linux.!OS_ID!.stdout"
        set "STDERR_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.linux.!OS_ID!.stderr"
        set "SUCCESS_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.linux.!OS_ID!.success"
        set "FAILURE_FILE=%TESTS_TMP_DIR%\!TARGET_NAME!.linux.!OS_ID!.failure"
        
        if exist "!SUCCESS_FILE!" del /f "!SUCCESS_FILE!"
        if exist "!FAILURE_FILE!" del /f "!FAILURE_FILE!"
        
        vagrant up > "!STDOUT_FILE!" 2> "!STDERR_FILE!"
        if !errorlevel! equ 0 (
            echo Success > "!SUCCESS_FILE!"
            echo [OK] !TARGET_NAME!
        ) else (
            echo Failure > "!FAILURE_FILE!"
            echo [FAILED] !TARGET_NAME!
        )
        
        vagrant destroy -f >nul 2>&1
        timeout /t 2 /nobreak >nul
)

echo All tests complete. Results are in %TESTS_TMP_DIR%.
goto :eof

:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0 [TARGETS...^|all] [--os OS_NAME]
echo.
echo Runs local tests using Vagrant across specified categories or individual targets
echo to verify libscript installation and testing.
echo.
echo Arguments:
echo   TARGETS...     A list of categories (e.g., databases, languages) or specific targets.
echo                  If no arguments are provided, defaults to: databases languages toolchains
echo   all            Run tests across all categories in the _lib directory.
echo   --os OS_NAME   The OS environment to use from the vagrant/ folder (default: alpine-3.24).
echo                  Example: --os debian-13-arm64
echo   --help, -h, /? Show this help message.
echo.
echo Results are written to the tests_tmp directory.
endlocal
