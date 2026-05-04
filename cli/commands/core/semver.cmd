@echo off
setlocal EnableDelayedExpansion
set "v1=%~2"
set "op=%~3"
set "v2=%~4"
if "!v1!"=="" (
    echo Usage: %~nx0 semver ^<v1^> ^<operator^> ^<v2^> 1>&2
    echo Operators: -eq -ne -gt -lt -ge -le 1>&2
    exit /b 1
)
if "!op!"=="=" set "op=-eq"
if "!op!"=="!=" set "op=-ne"
if "!op!"==">" set "op=-gt"
if "!op!"=="<" set "op=-lt"
if "!op!"==">=" set "op=-ge"
if "!op!"=="<=" set "op=-le"

powershell -Command "if ([version]'!v1!' !op! [version]'!v2!') { exit 0 } else { exit 1 }"
exit /b !errorlevel!
