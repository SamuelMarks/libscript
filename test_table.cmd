@echo off
set "THIS_FILE=%~f0"
:: # test_table.cmd
::
:: ## Overview
:: Generates a markdown table displaying the testing status of components.
::
:: ## Usage
:: call "%~dp0test_table.cmd"

setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "REPO_ROOT=%SCRIPT_DIR%"
set "TMP_TABLE=%REPO_ROOT%\components_table.tmp"

(
  echo ## Supported Components
  echo.
  echo ^| Component ^| Linux ^| Windows ^| DOS ^| SunOS ^| FreeBSD ^|
  echo ^|---^|---^|---^|---^|---^|---^|
) > "!TMP_TABLE!"

for /d %%C in ("%REPO_ROOT%\_lib\*") do (
  set "CAT_NAME=%%~nxC"
  if not "!CAT_NAME!"=="_common" (
    for /d %%P in ("%%C\*") do (
      set "COMP_NAME=%%~nxP"
      set "LINUX_STATUS=❓"
      if exist "%REPO_ROOT%\tests_tmp\!COMP_NAME!.linux.alpine.success" (
        set "LINUX_STATUS=✅"
      ) else if exist "%REPO_ROOT%\tests_tmp\!COMP_NAME!.linux.alpine.failure" (
        set "LINUX_STATUS=❌"
      )
      echo ^| `!COMP_NAME!` ^| !LINUX_STATUS! ^| - ^| - ^| - ^| - ^| >> "!TMP_TABLE!"
    )
  )
)

type "!TMP_TABLE!"
exit /b 0
