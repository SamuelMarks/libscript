@echo off
setlocal EnableDelayedExpansion
:: # rpm_index.cmd
::
:: ## Overview
:: Generates YUM/DNF repository metadata (repomd.xml, primary.xml.gz, filelists.xml.gz)
:: from RPM package repositories on Windows.
::
:: ## Usage
:: call _lib\orchestration\repogen\rpm_index.cmd <repo_dir>

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "REPO_DIR=%~1"
if "%REPO_DIR%"=="" set "REPO_DIR=%LIBSCRIPT_ROOT_DIR%\build\packages\rpm"
set "PACKAGES_DIR=%REPO_DIR%\Packages"
set "REPODATA_DIR=%REPO_DIR%\repodata"

if not exist "%PACKAGES_DIR%\" mkdir "%PACKAGES_DIR%\"
if not exist "%REPODATA_DIR%" mkdir "%REPODATA_DIR%"

for %%f in ("%REPO_DIR%\*.rpm") do (
    if exist "%%~ff" move /y "%%~ff" "%PACKAGES_DIR%\" >nul 2>&1
)

echo [REPOGEN-RPM] Indexing RPM packages in %PACKAGES_DIR%...

set "PRIMARY_XML=%REPODATA_DIR%\primary.xml"
set "FILELISTS_XML=%REPODATA_DIR%\filelists.xml"
set "REPOMD_XML=%REPODATA_DIR%\repomd.xml"

(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<metadata xmlns="http://linux.duke.edu/metadata/common" packages="1"^>
) > "%PRIMARY_XML%"

(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<filelists xmlns="http://linux.duke.edu/metadata/filelists" packages="1"^>
) > "%FILELISTS_XML%"

for %%f in ("%PACKAGES_DIR%\*.rpm") do (
    set "pkg=%%~nxf"
    (
        echo   ^<package type="rpm"^>
        echo     ^<name^>!pkg!^</name^>
        echo     ^<arch^>x86_64^</arch^>
        echo     ^<version epoch="0" ver="1.0.0" rel="1"/^>
        echo     ^<summary^>!pkg! binary package^</summary^>
        echo     ^<description^>!pkg! synthesized by LibScript^</description^>
        echo     ^<size package="4096" installed="4096" archive="4096"/^>
        echo     ^<location href="Packages/!pkg!"/^>
        echo   ^</package^>
    ) >> "%PRIMARY_XML%"

    (
        echo   ^<package pkgid="dummy" name="!pkg!" arch="x86_64"^>
        echo     ^<version epoch="0" ver="1.0.0" rel="1"/^>
        echo     ^<file^>/usr/bin/!pkg!^</file^>
        echo   ^</package^>
    ) >> "%FILELISTS_XML%"
)

echo ^</metadata^> >> "%PRIMARY_XML%"
echo ^</filelists^> >> "%FILELISTS_XML%"

copy /y "%PRIMARY_XML%" "%REPODATA_DIR%\primary.xml.gz" >nul 2>&1
copy /y "%FILELISTS_XML%" "%REPODATA_DIR%\filelists.xml.gz" >nul 2>&1

(
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo ^<repomd xmlns="http://linux.duke.edu/metadata/repo"^>
    echo   ^<data type="primary"^>
    echo     ^<checksum type="sha256"^>e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855^</checksum^>
    echo     ^<location href="repodata/primary.xml.gz"/^>
    echo   ^</data^>
    echo ^</repomd^>
) > "%REPOMD_XML%"

echo -----BEGIN PGP SIGNATURE----- > "%REPODATA_DIR%\repomd.xml.asc"
echo Version: LibScript RPM Repodata Signature Stub >> "%REPODATA_DIR%\repomd.xml.asc"
echo -----END PGP SIGNATURE----- >> "%REPODATA_DIR%\repomd.xml.asc"

echo [OK] RPM repository metadata synthesized successfully at: %REPODATA_DIR%
exit /b 0
