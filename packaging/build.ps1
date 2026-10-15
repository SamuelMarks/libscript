# ## Overview
# Compiles MSI installers for Open edX.
#
# ## Usage
# .build.ps1

$env:Path += ';' + $env:USERPROFILE + '\.libscript\wix\3.14\bin'
Set-Location C:\libscript\packaging
Write-Host "[INFO] Building Online MSI..."
candle.exe -nologo -out OpenEdX-Setup.wixobj OpenEdX-Setup.wxs
candle.exe -nologo -out OpenEdX-Setup_payload.wixobj OpenEdX-Setup_payload.wxs
light.exe -nologo -sval -ext WixUIExtension -out OpenEdX-Setup.msi OpenEdX-Setup.wixobj OpenEdX-Setup_payload.wixobj

Write-Host "[INFO] Building Offline MSI..."
candle.exe -nologo -out OpenEdX-Setup-Offline.wixobj OpenEdX-Setup-Offline.wxs
candle.exe -nologo -out OpenEdX-Setup-Offline_payload.wixobj OpenEdX-Setup-Offline_payload.wxs
light.exe -nologo -sval -ext WixUIExtension -out OpenEdX-Setup-Offline.msi OpenEdX-Setup-Offline.wixobj OpenEdX-Setup-Offline_payload.wixobj
