param(
  [string]$PackageName,
  [string]$DataDir,
  [string]$RunAsUser,
  [string]$RunAsPassword,
  [string]$BinPath,
  [string]$CustomServiceName
)

if ($CustomServiceName) {
    $ServiceName = $CustomServiceName
} else {
    $ServiceName = "libscript_$PackageName"
}

# Apply ACLs to Data Directory
if ($DataDir -and (Test-Path $DataDir)) {
    Write-Host "Applying ACLs to Data Directory: $DataDir"
    $user = if ($RunAsUser) { $RunAsUser } else { "NT AUTHORITY\NetworkService" }
    icacls.exe $DataDir /grant "$($user):(OI)(CI)F" /T
}

# Stop service if exists
if (Get-Service $ServiceName -ErrorAction SilentlyContinue) {
    Stop-Service $ServiceName -ErrorAction SilentlyContinue
} else {
    Write-Host "Creating service $ServiceName..."
    if (-not $BinPath) { $BinPath = "C:\Program Files\$PackageName\bin\$PackageName.exe" }
    & sc.exe create $ServiceName binPath= $BinPath start= auto
}

# Configure service via sc.exe
if ($RunAsUser) {
    $userObj = if ($RunAsUser.Contains("\") -or $RunAsUser.Contains("@")) { $RunAsUser } else { ".\$RunAsUser" }
    Write-Host "Configuring service to run as $userObj"
    & sc.exe config $ServiceName obj= $userObj password= $RunAsPassword
} else {
    Write-Host "Configuring service to run as Network Service"
    & sc.exe config $ServiceName obj= "NT AUTHORITY\NetworkService" password= ""
}

Write-Host "Service $ServiceName configured successfully."
