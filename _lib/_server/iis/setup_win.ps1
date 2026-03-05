$ErrorActionPreference = "Stop"

Write-Host "Installing IIS and required features..."

# Check if Server or Client OS
$osInfo = Get-CimInstance Win32_OperatingSystem
if ($osInfo.ProductType -eq 1) {
    # Windows Client (10, 11, etc)
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CGI -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions -All
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter -All
} else {
    # Windows Server
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    Install-WindowsFeature -Name Web-CGI
    Install-WindowsFeature -Name Web-ISAPI-Ext
    Install-WindowsFeature -Name Web-ISAPI-Filter
}

Write-Host "IIS setup completed."
