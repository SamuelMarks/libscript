@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

:: # template_msi.cmd
::
:: ## Overview
:: Universal WiX XML (.wxs) manifest generator on Windows.
:: Synthesizes WiX manifests driven purely by packaging.json.
::
:: ## Usage
::   call packaging\template_msi.cmd <path_to_stack_or_packaging.json> --out <file.wxs> [OPTIONS]

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root

set "TARGET_SPEC=%~1"
if "%TARGET_SPEC%"=="" (
    echo [ERROR] Target stack directory or packaging.json required >&2
    exit /b 1
)
shift

set "OUT_FILE="
set "VARIANT=online"
set "VERSION_OVERRIDE="

:arg_loop
if "%~1"=="" goto done_args
if /i "%~1"=="--out" ( set "OUT_FILE=%~2" & shift & shift & goto arg_loop )
if /i "%~1"=="--variant" ( set "VARIANT=%~2" & shift & shift & goto arg_loop )
if /i "%~1"=="--version" ( set "VERSION_OVERRIDE=%~2" & shift & shift & goto arg_loop )
shift
goto arg_loop

:done_args

if "%OUT_FILE%"=="" (
    echo [ERROR] --out parameter is required >&2
    exit /b 1
)

set "PKG_JSON=%TARGET_SPEC%"
if exist "%TARGET_SPEC%\packaging.json" set "PKG_JSON=%TARGET_SPEC%\packaging.json"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$pkgJson = '%PKG_JSON%';" ^
    "$outFile = '%OUT_FILE%';" ^
    "$variant = '%VARIANT%';" ^
    "$verOverride = '%VERSION_OVERRIDE%';" ^
    "$spec = Get-Content $pkgJson -Raw | ConvertFrom-Json;" ^
    "$name = if ($spec.name) { $spec.name } else { 'app' };" ^
    "$title = if ($spec.title) { $spec.title } else { $name };" ^
    "$ver = if ($verOverride) { $verOverride } elseif ($spec.version) { $spec.version } else { '1.0.0.0' };" ^
    "$pub = if ($spec.publisher) { $spec.publisher } else { 'LibScript Open Source Project' };" ^
    "$upgradeCode = if ($spec.upgrade_code) { $spec.upgrade_code } else { '{A0B1C2D3-E4F5-6A7B-8C9D-0E1F2A3B4C5D}' };" ^
    "$prodCode = [System.Guid]::NewGuid().ToString('B').ToUpper();" ^
    "$hasChainer = ($spec.orchestrator -eq $true -or $spec.embedded_chainer -eq $true -or $spec.topology -eq 'suite_orchestrator' -or ($spec.chained_packages -and $spec.chained_packages.Count -gt 0) -or ($spec.dependencies -and $spec.dependencies.Count -gt 0));" ^
    "$lines = @(" ^
    "  '<?xml version=\"1.0\" encoding=\"UTF-8\"?>'," ^
    "  '<Wix xmlns=\"http://schemas.microsoft.com/wix/2006/wi\">'," ^
    "  ('  <Product Id=\"' + $prodCode + '\" Name=\"' + $title + '\" Language=\"1033\" Version=\"' + $ver + '\" Manufacturer=\"' + $pub + '\" UpgradeCode=\"' + $upgradeCode + '\">')," ^
    "  ('    <Package Id=\"*\" InstallerVersion=\"405\" Compressed=\"yes\" InstallScope=\"perMachine\" Description=\"' + $title + ' Installer\" />')," ^
    "  '    <MajorUpgrade DowngradeErrorMessage=\"A newer version is already installed.\" Schedule=\"afterInstallInitialize\" />'," ^
    "  '    <Media Id=\"1\" Cabinet=\"payload.cab\" EmbedCab=\"yes\" />'," ^
    "  ('    <Property Id=\"PROP_VARIANT\" Value=\"' + $variant + '\" Secure=\"yes\" />')," ^
    "  ('    <Property Id=\"PROP_APP_IDENTIFIER\" Value=\"' + $name + '\" Secure=\"yes\" />')," ^
    "  '    <Property Id=\"MsiHiddenProperties\" Value=\"PROP_PROVISION_PASSWORD;PROP_MYSQL_ROOT_PASSWORD;PROP_MONGODB_ROOT_PASSWORD;PROP_REDIS_PASSWORD\" />'," ^
    "  '    <Directory Id=\"TARGETDIR\" Name=\"SourceDir\">'," ^
    "  '      <Directory Id=\"ProgramFiles64Folder\">'," ^
    "  ('        <Directory Id=\"INSTALLFOLDER\" Name=\"' + $name + '\">')," ^
    "  '          <Directory Id=\"BUNDLE_DIR\" Name=\"bundle\" />'," ^
    "  '        </Directory>'," ^
    "  '      </Directory>'," ^
    "  '    </Directory>'," ^
    "  ('    <Feature Id=\"DefaultFeature\" Title=\"' + $title + '\" Level=\"1\">')," ^
    "  '      <ComponentRef Id=\"AppIdentityComponent\" />'," ^
    "  '    </Feature>'," ^
    "  '    <DirectoryRef Id=\"INSTALLFOLDER\">'," ^
    "  '      <Component Id=\"AppIdentityComponent\" Guid=\"*\">'," ^
    "  ('        <RegistryKey Root=\"HKLM\" Key=\"Software\LibScript\' + $name + '\">')," ^
    "  '          <RegistryValue Name=\"Installed\" Type=\"integer\" Value=\"1\" KeyPath=\"yes\" />'," ^
    "  '        </RegistryKey>'," ^
    "  '      </Component>'," ^
    "  '    </DirectoryRef>'" ^
    ");" ^
    "if ($hasChainer) {" ^
    "  $lines += '    <UI Id=\"DatabaseConfigUI\">';" ^
    "  $lines += '      <Dialog Id=\"Dlg_DatabaseConfig\" Width=\"370\" Height=\"270\" Title=\"Database Configuration\">';" ^
    "  $lines += '        <Control Id=\"Title\" Type=\"Text\" X=\"15\" Y=\"6\" Width=\"260\" Height=\"15\" Transparent=\"yes\" NoPrefix=\"yes\" Text=\"Database Configuration\" />';" ^
    "  $lines += '        <Control Id=\"Description\" Type=\"Text\" X=\"25\" Y=\"22\" Width=\"260\" Height=\"20\" Transparent=\"yes\" NoPrefix=\"yes\" Text=\"Select your database deployment strategy.\" />';" ^
    "  $lines += '        <Control Id=\"RadioGroup\" Type=\"RadioButtonGroup\" X=\"20\" Y=\"60\" Width=\"330\" Height=\"50\" Property=\"USER_DB_STRATEGY\">';" ^
    "  $lines += '          <RadioButtonGroup Property=\"USER_DB_STRATEGY\">';" ^
    "  $lines += '            <RadioButton Value=\"local\" X=\"0\" Y=\"0\" Width=\"320\" Height=\"20\" Text=\"Install Local Database Component\" />';" ^
    "  $lines += '            <RadioButton Value=\"remote\" X=\"0\" Y=\"25\" Width=\"320\" Height=\"20\" Text=\"Connect to Existing/Remote Database\" />';" ^
    "  $lines += '          </RadioButtonGroup>';" ^
    "  $lines += '        </Control>';" ^
    "  $lines += '        <Control Id=\"Lbl_DbHost\" Type=\"Text\" X=\"20\" Y=\"120\" Width=\"100\" Height=\"15\" Text=\"Database Host:\" />';" ^
    "  $lines += '        <Control Id=\"Txt_DbHost\" Type=\"Edit\" X=\"120\" Y=\"118\" Width=\"200\" Height=\"18\" Property=\"USER_DB_HOST\" />';" ^
    "  $lines += '        <Control Id=\"Lbl_DbName\" Type=\"Text\" X=\"20\" Y=\"145\" Width=\"100\" Height=\"15\" Text=\"Database Name:\" />';" ^
    "  $lines += '        <Control Id=\"Txt_DbName\" Type=\"Edit\" X=\"120\" Y=\"143\" Width=\"200\" Height=\"18\" Property=\"USER_DB_NAME\" />';" ^
    "  $lines += '      </Dialog>';" ^
    "  $lines += '      <EmbeddedChainer Id=\"LibScriptChainer\" SourceFile=\"binary\libscript_chainer.dll\" />';" ^
    "  $lines += '    </UI>';" ^
    "}" ^
    "$lines += '  </Product>';" ^
    "$lines += '</Wix>';" ^
    "$wxs = $lines -join \"`r`n\";" ^
    "[System.IO.File]::WriteAllText($outFile, $wxs);" ^
    "Write-Output ('[SUCCESS] Generated WiX XML: ' + $outFile);"

exit /b %ERRORLEVEL%
