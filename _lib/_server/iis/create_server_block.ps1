param (
    [string]$ServerName = $env:SERVER_NAME,
    [string]$ListenPort = $env:LISTEN,
    [string]$WwwRoot = $env:WWWROOT,
    [string]$PhpFpmListen = $env:PHP_FPM_LISTEN
)

if ([string]::IsNullOrWhiteSpace($ServerName)) { $ServerName = "localhost" }
if ([string]::IsNullOrWhiteSpace($ListenPort)) { $ListenPort = "80" }
if ([string]::IsNullOrWhiteSpace($WwwRoot)) { $WwwRoot = "C:\inetpub\wwwroot\wordpress" }

Write-Host "Configuring IIS Web Site for $ServerName on port $ListenPort -> $WwwRoot"

Import-Module WebAdministration

$siteName = "LibScript-$ServerName-$ListenPort"

# Create physical path if it doesn't exist
if (-not (Test-Path $WwwRoot)) {
    New-Item -ItemType Directory -Force -Path $WwwRoot | Out-Null
}

# Remove existing site if it exists
if (Test-Path "IIS:\Sites\$siteName") {
    Remove-WebSite -Name $siteName
}

# Create new site
New-WebSite -Name $siteName -Port $ListenPort -HostHeader $ServerName -PhysicalPath $WwwRoot -Force

# Register PHP FastCGI if PHP is configured
if (-not [string]::IsNullOrWhiteSpace($PhpFpmListen)) {
    Write-Host "PHP CGI Executable specified: $PhpFpmListen"
    # Example: PhpFpmListen might be the path to php-cgi.exe on Windows.
    # We map .php to the provided FastCGI executable.
    
    # Check if the fastCgi handler is already registered for this executable
    $fastCgi = Get-WebConfigurationProperty -Filter "/system.webServer/fastCgi" -Name "application" | Where-Object { $_.fullPath -eq $PhpFpmListen }
    if (-not $fastCgi) {
        Add-WebConfigurationProperty -Filter "/system.webServer/fastCgi" -Name "." -Value @{fullPath=$PhpFpmListen; maxInstances=4; idleTimeout=300; activityTimeout=30; requestTimeout=90; instanceMaxRequests=10000; protocol="NamedPipe"; flushNamedPipe=$false}
    }

    $handlerName = "PHP-FastCGI-$ServerName"
    Remove-WebConfigurationProperty -Filter "/system.webServer/handlers" -Name "." -AtElement @{name=$handlerName} -ErrorAction SilentlyContinue
    
    Add-WebConfigurationProperty -Filter "/system.webServer/handlers" -Name "." -Value @{
        name=$handlerName;
        path="*.php";
        verb="GET,HEAD,POST";
        modules="FastCgiModule";
        scriptProcessor=$PhpFpmListen;
        resourceType="Either";
        requireAccess="Script"
    } -Location $siteName
    
    # Set default document to index.php
    Add-WebConfigurationProperty -Filter "/system.webServer/defaultDocument/files" -Name "." -Value @{value="index.php"} -Location $siteName -ErrorAction SilentlyContinue
}

Write-Host "IIS Site created successfully."
