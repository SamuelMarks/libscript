@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # update_results.cmd
::
:: ## Overview
:: Updates the Supported Components table in README.md with test results from tests_tmp,
:: and updates task completion in TODO_PLAN.md if present on Windows.
::
:: ## Usage
:: tests\update_results.cmd [REPO_ROOT]

set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"

set "REPO_ROOT=%~1"
if "%REPO_ROOT%"=="" set "REPO_ROOT=%THIS_DIR%\.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"

set "README_FILE=%REPO_ROOT%\README.md"
set "TESTS_TMP_DIR=%REPO_ROOT%\tests_tmp"
set "TODO_FILE=%REPO_ROOT%\TODO_PLAN.md"
set "TMP_TABLE=%TEMP%\components_table_%RANDOM%.tmp"
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

for /d %%C in ("%REPO_ROOT%\_lib\*") do (
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
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.ubuntu.success" set "deb_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.debian.success" set "deb_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.ubuntu.success" set "deb_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.deb.success" set "deb_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.debian.failure" set "deb_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.ubuntu.failure" set "deb_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.debian.failure" set "deb_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.ubuntu.failure" set "deb_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.deb.failure" set "deb_status=❌"

                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.rhel.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.fedora.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.almalinux.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.centos.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.rpm.success" set "rpm_status=✅"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.rhel.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.fedora.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.almalinux.failure" set "rpm_status=❌"
                    if exist "%TESTS_TMP_DIR%\!comp_name!.linux.centos.failure" set "rpm_status=❌"
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

                >> "%TMP_TABLE%" echo ^| `!comp_name!` ^| !apk_status! ^| !deb_status! ^| !rpm_status! ^| !win_status! ^| !sunos_status! ^| !freebsd_status! ^|
            )
        )
    )
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
)
if exist "%TMP_TABLE%" del "%TMP_TABLE%" >nul 2>&1

:: ## update_todo_plan
:: Checks off completed tasks in TODO_PLAN.md if result files exist in tests_tmp.
if exist "%TODO_FILE%" if exist "%TESTS_TMP_DIR%" (
    (for /f "delims=" %%L in ('findstr /n "^" "%TODO_FILE%"') do (
        set "line=%%L"
        set "line=!line:*:=!"
        if "!line:~0,6!"=="- [ ] " (
            set "item=!line:~6!"
            for %%P in ("!item!") do set "comp=%%~nxP"
            set "has_result=0"
            if exist "%TESTS_TMP_DIR%\!comp!.*.success" set "has_result=1"
            if exist "%TESTS_TMP_DIR%\!comp!.*.failure" set "has_result=1"
            if "!has_result!"=="1" (
                echo - [x] !item!
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
