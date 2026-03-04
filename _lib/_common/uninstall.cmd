@echo off
setlocal EnableDelayedExpansion
echo Running generic uninstaller for %PACKAGE_NAME%

set "PURGE_DATA=0"
:parse_args
if "%~1"=="" goto after_parse
if /i "%~1"=="--purge-data" set "PURGE_DATA=1"
shift
goto parse_args
:after_parse

if "!PURGE_DATA!"=="1" (
    echo [WARN] Purging data directories for %PACKAGE_NAME%...
    if exist "%LIBSCRIPT_ROOT_DIR%\data\%PACKAGE_NAME%" (
        rmdir /s /q "%LIBSCRIPT_ROOT_DIR%\data\%PACKAGE_NAME%"
    )
    :: Try to read DATA_DIR from schema defaults or env if possible
    set "pkg_upper=!PACKAGE_NAME!"
    for %%A in (
        "a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
        "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
        "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z" "-=_"
    ) do set "pkg_upper=!pkg_upper:%%~A!"
    
    :: Nuke service
    sc stop "libscript_!PACKAGE_NAME!" >nul 2>&1
    sc delete "libscript_!PACKAGE_NAME!" >nul 2>&1
) else (
    echo [INFO] Keeping data directory intact.
    sc stop "libscript_!PACKAGE_NAME!" >nul 2>&1
    sc config "libscript_!PACKAGE_NAME!" start= demand >nul 2>&1
)

if exist "%LIBSCRIPT_ROOT_DIR%\installed\%PACKAGE_NAME%" (
    rmdir /s /q "%LIBSCRIPT_ROOT_DIR%\installed\%PACKAGE_NAME%"
)
echo Uninstalled %PACKAGE_NAME%.
exit /b 0
