@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # update_results.cmd
::
:: ## Overview
:: Updates the Supported Components table in README.md (or custom output file)
:: with test results from tests_tmp, updates component tasks in TODO_PLAN.md if present,
:: and optionally exports an aggregated JSON test results matrix on Windows.
::
:: ## Usage
:: tests\update_results.cmd [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]

set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"

set "REPO_ROOT="
set "OUTPUT_FILE="
set "JSON_FILE="

:: ## parse_args
:: Parses command line arguments and switches.
:parse_args
if "%~1"=="" goto :done_args
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--output" (
    set "OUTPUT_FILE=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--json" (
    if not "%~2"=="" (
        set "peek=%~2"
        if not "!peek:~0,2!"=="--" (
            set "JSON_FILE=%~2"
            shift
            shift
            goto :parse_args
        )
    )
    set "JSON_FILE=default"
    shift
    goto :parse_args
)
if "%REPO_ROOT%"=="" (
    set "REPO_ROOT=%~1"
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## done_args
:: Sets default values for any omitted configuration options.
:done_args
if "%REPO_ROOT%"=="" set "REPO_ROOT=%THIS_DIR%\.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"

if "%OUTPUT_FILE%"=="" set "OUTPUT_FILE=%REPO_ROOT%\README.md"
for %%I in ("%OUTPUT_FILE%") do set "OUTPUT_FILE=%%~fI"

set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"
if "%JSON_FILE%"=="default" set "JSON_FILE=%TESTS_TMP_DIR%\matrix_results.json"
if defined JSON_FILE (
    for %%I in ("%JSON_FILE%") do set "JSON_FILE=%%~fI"
)

set "README_FILE=%OUTPUT_FILE%"
set "TODO_FILE=%REPO_ROOT%\TODO_PLAN.md"
set "TMP_TABLE=%TEMP%\components_table_%RANDOM%.tmp"
set "TMP_ROWS=%TEMP%\components_rows_%RANDOM%.tmp"
set "TMP_JSON=%TEMP%\components_json_%RANDOM%.tmp"
set "TMP_README=%TEMP%\readme_update_%RANDOM%.tmp"
set "TMP_TODO=%TEMP%\todo_update_%RANDOM%.tmp"

if not exist "%REPO_ROOT%\_lib" goto :done

:: ## update_supported_components
:: Writes markdown table header and component rows with test results.
> "%TMP_TABLE%" (
    echo ## Supported Components
    echo.
    echo ^| Component ^| Linux ^(apk^) ^| Linux ^(deb^) ^| Linux ^(rpm^) ^| Windows ^| SunOS ^| FreeBSD ^|
    echo ^|---^|---^|---^|---^|---^|---^|
)

if defined JSON_FILE (
    > "%TMP_JSON%" echo [
    set "FIRST_JSON_ROW=1"
)

for /d %%C in ("%REPO_ROOT%\_lib\*" "%REPO_ROOT%\stacks\*") do (
    set "cat_name=%%~nxC"
    if not "!cat_name:~0,1!"=="_" (
        for /d %%D in ("%%C\*") do (
            set "comp_name=%%~nxD"
            if not "!comp_name:~0,1!"=="_" (
                set "apk_status=❓"
                set "deb_status=❓"
                set "rpm_status=❓"
                set "win_status=-"
                set "sunos_status=-"
                set "freebsd_status=-"

                if exist "%%D\manifest.json" (
                    findstr /i /c:"\"all\"" "%%D\manifest.json" >nul 2>&1
                    if not errorlevel 1 (
                        set "win_status=❓"
                        set "sunos_status=❓"
                        set "freebsd_status=❓"
                    )
                    findstr /i /c:"\"windows\"" "%%D\manifest.json" >nul 2>&1
                    if not errorlevel 1 set "win_status=❓"
                    findstr /i /c:"\"sunos\"" "%%D\manifest.json" >nul 2>&1
                    if not errorlevel 1 set "sunos_status=❓"
                    findstr /i /c:"\"freebsd\"" "%%D\manifest.json" >nul 2>&1
                    if not errorlevel 1 set "freebsd_status=❓"
                    findstr /i /c:"\"bsd\"" "%%D\manifest.json" >nul 2>&1
                    if not errorlevel 1 set "freebsd_status=❓"
                )

                if exist "%README_FILE%" (
                    for /f "tokens=3-8 delims=|" %%a in ('findstr /r /c:"^| `!comp_name!` |" "%README_FILE%" 2^>nul') do (
                        for /f "tokens=* delims= " %%v in ("%%a") do set "e_apk=%%v"
                        for /f "tokens=* delims= " %%v in ("%%b") do set "e_deb=%%v"
                        for /f "tokens=* delims= " %%v in ("%%c") do set "e_rpm=%%v"
                        for /f "tokens=* delims= " %%v in ("%%d") do set "e_win=%%v"
                        for /f "tokens=* delims= " %%v in ("%%e") do set "e_sun=%%v"
                        for /f "tokens=* delims= " %%v in ("%%f") do set "e_bsd=%%v"
                        if not "!e_apk!"=="" set "apk_status=!e_apk!"
                        if not "!e_deb!"=="" set "deb_status=!e_deb!"
                        if not "!e_rpm!"=="" set "rpm_status=!e_rpm!"
                        if not "!e_win!"=="" set "win_status=!e_win!"
                        if not "!e_sun!"=="" set "sunos_status=!e_sun!"
                        if not "!e_bsd!"=="" set "freebsd_status=!e_bsd!"
                    )
                )

                if exist "%TESTS_TMP_DIR%" (
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.alpine.success" set "apk_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.alpine.success" set "apk_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.apk.success" set "apk_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.alpine.failure" set "apk_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.alpine.failure" set "apk_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.apk.failure" set "apk_status=❌"

                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.debian.success" set "deb_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.debian.success" set "deb_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.ubuntu.success" set "deb_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.deb.success" set "deb_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.debian.failure" set "deb_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.debian.failure" set "deb_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.ubuntu.failure" set "deb_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.deb.failure" set "deb_status=❌"

                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.rhel.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rhel.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.fedora.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.almalinux.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.centos.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.rocky.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.rockylinux.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rocky.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rockylinux.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rpm.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.rhel.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rhel.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.fedora.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.almalinux.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.centos.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.rocky.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.rockylinux.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rocky.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rockylinux.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rpm.failure" set "rpm_status=❌"

                    if exist "%TESTS_TMP_DIR%\!comp_name!.windows.success" set "win_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.win.success" set "win_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.windows.failure" set "win_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.win.failure" set "win_status=❌"

                    if exist "%TESTS_TMP_DIR%\!comp_name!.sunos.success" set "sunos_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.solaris.success" set "sunos_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.illumos.success" set "sunos_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.sunos.failure" set "sunos_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.solaris.failure" set "sunos_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.illumos.failure" set "sunos_status=❌"

                    if exist "%TESTS_TMP_DIR%\!comp_name!.freebsd.success" set "freebsd_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.bsd.success" set "freebsd_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.freebsd.success" set "freebsd_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.freebsd.failure" set "freebsd_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.bsd.failure" set "freebsd_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.freebsd.failure" set "freebsd_status=❌"
                )

                >> "%TMP_ROWS%" echo ^| `!comp_name!` ^| !apk_status! ^| !deb_status! ^| !rpm_status! ^| !win_status! ^| !sunos_status! ^| !freebsd_status! ^|

                if defined JSON_FILE (
                    if not "!FIRST_JSON_ROW!"=="1" >> "%TMP_JSON%" echo   ,
                    set "FIRST_JSON_ROW=0"
                    >> "%TMP_JSON%" echo   {
                    >> "%TMP_JSON%" echo     "component": "!comp_name!",
                    >> "%TMP_JSON%" echo     "apk": "!apk_status!",
                    >> "%TMP_JSON%" echo     "deb": "!deb_status!",
                    >> "%TMP_JSON%" echo     "rpm": "!rpm_status!",
                    >> "%TMP_JSON%" echo     "windows": "!win_status!",
                    >> "%TMP_JSON%" echo     "sunos": "!sunos_status!",
                    >> "%TMP_JSON%" echo     "freebsd": "!freebsd_status!"
                    >> "%TMP_JSON%" echo   }
                )
            )
        )
    )
)

if exist "%TMP_ROWS%" (
    sort "%TMP_ROWS%" >> "%TMP_TABLE%"
    del "%TMP_ROWS%" >nul 2>&1
)

if defined JSON_FILE (
    >> "%TMP_JSON%" echo ]
    move /y "%TMP_JSON%" "%JSON_FILE%" >nul
)

if exist "%README_FILE%" (
    findstr /c:"## Supported Components" "%README_FILE%" >nul 2>&1
    if not errorlevel 1 (
        set "in_table=0"
        (for /f "delims=" %%L in ('findstr /n "^" "%README_FILE%"') do (
            set "line=%%L"
            set "line=!line:*:=!"
            if "!line!"=="## Supported Components" (
                set "in_table=1"
                type "%TMP_TABLE%"
                echo.
            ) else (
                if "!in_table!"=="1" (
                    if "!line:~0,3!"=="## " (
                        set "in_table=0"
                        echo(!line!
                    )
                ) else (
                    echo(!line!
                )
            )
        )) > "%TMP_README%"
        move /y "%TMP_README%" "%README_FILE%" >nul
    ) else (
        type "%TMP_TABLE%" >> "%README_FILE%"
    )
    where npx >nul 2>&1
    if !errorlevel! equ 0 (
        call npx --yes prettier --write "%README_FILE%" >nul 2>&1
    )
)
if exist "%TMP_TABLE%" del "%TMP_TABLE%" >nul 2>&1

:: ## update_todo_plan
:: Checks off completed tasks in TODO_PLAN.md if result files exist in tests_tmp.
if exist "%TODO_FILE%" if exist "%TESTS_TMP_DIR%" (
    set "curr_comp="
    (for /f "delims=" %%L in ('findstr /n "^" "%TODO_FILE%"') do (
        set "line=%%L"
        set "line=!line:*:=!"
        set "is_todo=0"
        if "!line:~0,6!"=="- [ ] " set "is_todo=1"
        if "!line:~0,6!"=="- [x] " (
            set "item=!line:~6!"
            for /f "tokens=1 delims=:" %%A in ("!item!") do set "comp_path=%%A"
            set "comp_path=!comp_path:`=!"
            for %%P in ("!comp_path!") do set "curr_comp=%%~nxP"
            echo(!line!
        ) else if "!is_todo!"=="1" (
            set "item=!line:~6!"
            for /f "tokens=1 delims=:" %%A in ("!item!") do set "comp_path=%%A"
            set "comp_path=!comp_path:`=!"
            for %%P in ("!comp_path!") do set "curr_comp=%%~nxP"
            set "has_result=0"
            if exist "%TESTS_TMP_DIR%\!curr_comp!*.success" set "has_result=1"
            if exist "%TESTS_TMP_DIR%\!curr_comp!*.failure" set "has_result=1"
            if "!has_result!"=="1" (
                echo - [x] !item!
            ) else (
                echo(!line!
            )
        ) else if not "!line:Double-check & Idempotency=!"=="!line!" (
            if exist "%TESTS_TMP_DIR%\!curr_comp!.idempotent.success" (
                echo   - [x] **Double-check ^& Idempotency Verified ^(2x run^)**
            ) else (
                echo(!line!
            )
        ) else (
            echo(!line!
        )
    )) > "%TMP_TODO%"
    move /y "%TMP_TODO%" "%TODO_FILE%" >nul
)
if exist "%TMP_TODO%" del "%TMP_TODO%" >nul 2>&1

:: ## done
:: Executes done functionality.
:done
exit /b 0

:: ## show_help
:: Displays command-line help and parameters.
:show_help
echo Usage: %~nx0 [REPO_ROOT] [--output ^<markdown_file^>] [--json [json_file]] [--help]
echo.
echo Aggregates test result marker files from tests_tmp and updates
echo the Supported Components table in README.md.
echo.
echo Options:
echo   REPO_ROOT              Target repository root path (default: auto-detected).
echo   --output ^<file^>        Custom markdown file to update (default: README.md).
echo   --json [json_file]     Export matrix results as JSON (default: tests_tmp\matrix_results.json).
echo   --help, -h, /?         Show this help message.
endlocal
