<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'azure' stack.

.DESCRIPTION
Execute this script to install and configure azure on the local system.
#>

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
$SubAction = $env:ARG1
$ResourceName = $env:ARG2
$ResourceGroup = $env:ARG3

switch ($Action) {
    "auth" {
        if ($SubAction -eq "login") {
            az login
        } elseif ($SubAction -eq "logout") {
            az logout
        } elseif ($SubAction -eq "status") {
            az account show
        }
        break
    }
    "location" {
        if ($SubAction -eq "list") {
            az account list-locations --query "[].name" -o tsv
        } elseif ($SubAction -eq "select") {
            if ($ResourceName) {
                az configure --defaults location=$ResourceName
                Write-Host "Default location set to $ResourceName."
            } else {
                Write-Host "Usage: location select <location>"
            }
        }
        break
    }
    "network" {
        if ($SubAction -eq "create") {
            $Loc = if ($env:location) { $env:location } else { "eastus" }
            Write-Host "Creating Azure VNet: $ResourceName in $ResourceGroup ($Loc)"
            
            $TagsArgs = @()
            $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
            if (Test-Path $TagsCmd) {
                & $TagsCmd :init | Out-Null
                if ($env:LIBSCRIPT_TAG_ENABLE -eq "true") {
                    $TagsArgs += "--tags"
                    $TagsArgs += "$env:LIBSCRIPT_TAG_KEY=$env:LIBSCRIPT_TAG_VALUE"
                }
            }
            $vnetExists = az network vnet show -g $ResourceGroup -n $ResourceName 2>&1
            if ($LASTEXITCODE -eq 0 -and $vnetExists -notmatch "ResourceNotFound") {
                Write-Host "VNet '$ResourceName' already exists in resource group '$ResourceGroup'."
            } else {
                az network vnet create --name $ResourceName --resource-group $ResourceGroup --location $Loc @TagsArgs
            }
        } elseif ($SubAction -eq "delete") {
            $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
            if (Test-Path $TagsCmd) {
                & $TagsCmd :libscript_verify_managed azure network $ResourceName $ResourceGroup
                if ($LASTEXITCODE -ne 0) { exit 1 }
            }
            Write-Host "Deleting Azure VNet: $ResourceName from $ResourceGroup"
            $vnetExists = az network vnet show -g $ResourceGroup -n $ResourceName 2>&1
            if ($LASTEXITCODE -eq 0 -and $vnetExists -notmatch "ResourceNotFound") {
                az network vnet delete --name $ResourceName --resource-group $ResourceGroup --yes
            } else {
                Write-Host "VNet '$ResourceName' already deleted or not found in resource group '$ResourceGroup'."
            }
        } elseif ($SubAction -eq "list") {
            if ($ResourceGroup) {
                az network vnet list --resource-group $ResourceGroup -o table
            } else {
                az network vnet list -o table
            }
        } elseif ($SubAction -eq "update") {
            $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
            if (Test-Path $TagsCmd) {
                & $TagsCmd :libscript_verify_managed azure network $ResourceName $ResourceGroup
                if ($LASTEXITCODE -ne 0) { exit 1 }
            }
            $Tags = $env:ARG4
            if ($Tags) {
                az network vnet update --name $ResourceName --resource-group $ResourceGroup --set tags=`"$Tags`"
            } else {
                Write-Host "Usage: network update <name> <resource-group> <tags>"
            }
        }
    }
    "firewall" {
        $Ports = $env:ARG4
        if ($SubAction -eq "create") {
            $Loc = if ($env:location) { $env:location } else { "eastus" }
            Write-Host "Creating Azure NSG: $ResourceName in $ResourceGroup ($Loc)"
            
            $TagsArgs = @()
            $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
            if (Test-Path $TagsCmd) {
                & $TagsCmd :init | Out-Null
                if ($env:LIBSCRIPT_TAG_ENABLE -eq "true") {
                    $TagsArgs += "--tags"
                    $TagsArgs += "$env:LIBSCRIPT_TAG_KEY=$env:LIBSCRIPT_TAG_VALUE"
                }
            }
            $nsgExists = az network nsg show -g $ResourceGroup -n $ResourceName 2>&1
            if ($LASTEXITCODE -eq 0 -and $nsgExists -notmatch "ResourceNotFound") {
                Write-Host "NSG '$ResourceName' already exists in resource group '$ResourceGroup'."
            } else {
                az network nsg create --name $ResourceName --resource-group $ResourceGroup --location $Loc @TagsArgs
            }
            if ($Ports) {
                $Priority = 1000
                foreach ($Port in $Ports.Split(' ')) {
                    if (-not [string]::IsNullOrWhiteSpace($Port)) {
                        Write-Host "Opening port $Port on $ResourceName"
                        az network nsg rule create --resource-group $ResourceGroup --nsg-name $ResourceName --name "Allow_$Port" --priority $Priority --destination-port-ranges $Port --access Allow --protocol Tcp
                        $Priority += 10
                    }
                }
            }
        } elseif ($SubAction -eq "delete") {
            $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
            if (Test-Path $TagsCmd) {
                & $TagsCmd :libscript_verify_managed azure firewall $ResourceName $ResourceGroup
                if ($LASTEXITCODE -ne 0) { exit 1 }
            }
            Write-Host "Deleting Azure NSG: $ResourceName from $ResourceGroup"
            $nsgExists = az network nsg show -g $ResourceGroup -n $ResourceName 2>&1
            if ($LASTEXITCODE -eq 0 -and $nsgExists -notmatch "ResourceNotFound") {
                az network nsg delete --name $ResourceName --resource-group $ResourceGroup --yes
            } else {
                Write-Host "NSG '$ResourceName' already deleted or not found in resource group '$ResourceGroup'."
            }
        } elseif ($SubAction -eq "list") {
            if ($ResourceGroup) {
                az network nsg list --resource-group $ResourceGroup -o table
            } else {
                az network nsg list -o table
            }
        } elseif ($SubAction -eq "update") {
            $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
            if (Test-Path $TagsCmd) {
                & $TagsCmd :libscript_verify_managed azure firewall $ResourceName $ResourceGroup
                if ($LASTEXITCODE -ne 0) { exit 1 }
            }
            $AddPort = $env:ARG4
            $RemovePort = $env:ARG5
            if ($AddPort) {
                az network nsg rule create --resource-group $ResourceGroup --nsg-name $ResourceName --name "Allow_$AddPort" --priority 2000 --destination-port-ranges $AddPort --access Allow --protocol Tcp
            }
            if ($RemovePort) {
                az network nsg rule delete --resource-group $ResourceGroup --nsg-name $ResourceName --name "Allow_$RemovePort"
            }
        }
    }
    "node" {
        if ($SubAction -eq "create") {
            $Image = $env:ARG3
            $ResourceGroup = $env:ARG4
            $Size = if ($env:size) { $env:size } else { "Standard_D2s_v7" }
            $ArgsList = @()
            if ($env:vnet_name) { $ArgsList += "--vnet-name"; $ArgsList += $env:vnet_name }
            if ($env:nsg) { $ArgsList += "--nsg"; $ArgsList += $env:nsg }
            if ($env:os_disk_size_gb) { $ArgsList += "--os-disk-size-gb"; $ArgsList += $env:os_disk_size_gb }

            $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
            if (Test-Path $TagsCmd) {
                & $TagsCmd :init | Out-Null
                if ($env:LIBSCRIPT_TAG_ENABLE -eq "true") {
                    $ArgsList += "--tags"
                    $ArgsList += "$env:LIBSCRIPT_TAG_KEY=$env:LIBSCRIPT_TAG_VALUE"
                }
            }
            
            Write-Host "Creating Azure VM: $ResourceName in $ResourceGroup ($Size, $Image)"
            $vmExists = az vm show -g $ResourceGroup -n $ResourceName 2>&1
            if ($LASTEXITCODE -eq 0 -and $vmExists -notmatch "ResourceNotFound") {
                Write-Host "VM '$ResourceName' already exists in resource group '$ResourceGroup'."
            } else {
                & az vm create --resource-group $ResourceGroup --name $ResourceName --image $Image --size $Size --admin-username azureuser --generate-ssh-keys --public-ip-sku Standard @ArgsList
            }
        } elseif ($SubAction -eq "delete") {
            $ResourceGroup = $env:ARG3
            $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
            if (Test-Path $TagsCmd) {
                & $TagsCmd :libscript_verify_managed azure node $ResourceName $ResourceGroup
                if ($LASTEXITCODE -ne 0) { exit 1 }
            }
            Write-Host "Deleting Azure VM: $ResourceName from $ResourceGroup"
            $vmExists = az vm show -g $ResourceGroup -n $ResourceName 2>&1
            if ($LASTEXITCODE -eq 0 -and $vmExists -notmatch "ResourceNotFound") {
                az vm delete --name $ResourceName --resource-group $ResourceGroup --yes
            } else {
                Write-Host "VM '$ResourceName' already deleted or not found in resource group '$ResourceGroup'."
            }
        } elseif ($SubAction -eq "list") {
            $ResourceGroup = $env:ARG3
            if ($ResourceGroup) { az vm list -g $ResourceGroup -o table } else { az vm list -o table }
        } elseif ($SubAction -eq "update") {
            $ResourceGroup = $env:ARG3
            $Size = $env:ARG4
            if ($ResourceGroup -and $Size) {
                $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
                if (Test-Path $TagsCmd) {
                    & $TagsCmd :libscript_verify_managed azure node $ResourceName $ResourceGroup
                    if ($LASTEXITCODE -ne 0) { exit 1 }
                }
                az vm resize -g $ResourceGroup -n $ResourceName --size $Size
            if ($Tags) { az vm update -g $ResourceGroup -n $ResourceName --set tags=`"$Tags`" }
        } elseif ($SubAction -eq "exec") {
            $ResourceGroup = $env:ARG3
            $CmdToRun = $env:ARG4
            if ($env:ARG5) { $CmdToRun += " $env:ARG5" }
            if ($env:ARG6) { $CmdToRun += " $env:ARG6" }
            Write-Host "Executing command on $ResourceName: $CmdToRun"
            $Ip = (az vm show -d -g $ResourceGroup -n $ResourceName --query publicIps -o tsv).Trim()
            ssh -o StrictHostKeyChecking=no "azureuser@$Ip" $CmdToRun
        } elseif ($SubAction -eq "deploy") {
            $ResourceGroup = $env:ARG3
            $Src = $env:ARG4
            $Dst = $env:ARG5
            $Ip = (az vm show -d -g $ResourceGroup -n $ResourceName --query publicIps -o tsv).Trim()
            Write-Host "Deploying $Src to azureuser@$Ip`:$Dst"
            if (Get-Command rsync -ErrorAction SilentlyContinue) {
                rsync -avz -e "ssh -o StrictHostKeyChecking=no" $Src "azureuser@$Ip`:$Dst"
            } else {
                scp -o StrictHostKeyChecking=no -r $Src "azureuser@$Ip`:$Dst"
            }
        } elseif ($SubAction -eq "scp") {
            $ResourceGroup = $env:ARG3
            $Src = $env:ARG4
            $Dst = $env:ARG5
            $Ip = (az vm show -d -g $ResourceGroup -n $ResourceName --query publicIps -o tsv).Trim()
            Write-Host "Copying $Src to azureuser@$Ip`:$Dst"
            scp -o StrictHostKeyChecking=no $Src "azureuser@$Ip`:$Dst"
        } elseif ($SubAction -eq "scp-from") {
            $ResourceGroup = $env:ARG3
            $Src = $env:ARG4
            $Dst = $env:ARG5
            $Ip = (az vm show -d -g $ResourceGroup -n $ResourceName --query publicIps -o tsv).Trim()
            Write-Host "Copying azureuser@$Ip`:$Src to $Dst"
            scp -o StrictHostKeyChecking=no "azureuser@$Ip`:$Src" $Dst
        } elseif ($SubAction -eq "sync") {
            $ResourceGroup = $env:ARG3
            $Ip = (az vm show -d -g $ResourceGroup -n $ResourceName --query publicIps -o tsv).Trim()
            Write-Host "Syncing LibScript to remote node $ResourceName"
            ssh -o StrictHostKeyChecking=no "azureuser@$Ip" "mkdir -p ~/libscript"
            if (Get-Command rsync -ErrorAction SilentlyContinue) {
                rsync -avz -e "ssh -o StrictHostKeyChecking=no" "$env:LIBSCRIPT_ROOT_DIR/" "azureuser@$Ip`:~/libscript/"
            } else {
                scp -o StrictHostKeyChecking=no -r "$env:LIBSCRIPT_ROOT_DIR/*" "azureuser@$Ip`:~/libscript/"
            }
        }
    }
    "dns" {
        $Domain = $env:ARG3
        $Zone = $env:ARG4
        $DnsRg = if ($env:ARG5) { $env:ARG5 } else { "$Zone-rg" }
        if ($SubAction -eq "zone") {
            $SubType = $env:ARG2
            $ZName = $env:ARG3
            $ZRg = $env:ARG4
            if ($SubType -eq "create") {
                $zoneExists = az network dns zone show -g $ZRg -n $ZName 2>&1
                if ($LASTEXITCODE -eq 0 -and $zoneExists -notmatch "ResourceNotFound") {
                    Write-Host "DNS zone '$ZName' already exists in resource group '$ZRg'."
                } else {
                    az network dns zone create -g $ZRg -n $ZName
                }
            } elseif ($SubType -eq "delete") {
                $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
                if (Test-Path $TagsCmd) {
                    & $TagsCmd :libscript_verify_managed azure dns $ZName $ZRg
                    if ($LASTEXITCODE -ne 0) { exit 1 }
                }
                $zoneExists = az network dns zone show -g $ZRg -n $ZName 2>&1
                if ($LASTEXITCODE -eq 0 -and $zoneExists -notmatch "ResourceNotFound") {
                    az network dns zone delete -g $ZRg -n $ZName --yes
                } else {
                    Write-Host "DNS zone '$ZName' already deleted or not found in resource group '$ZRg'."
                }
            } elseif ($SubType -eq "list") {
                if ($ZRg) { az network dns zone list -g $ZRg -o table } else { az network dns zone list -o table }
            }
        } elseif ($SubAction -eq "record") {
            $SubType = $env:ARG2
            $ZName = $env:ARG3
            $ZRg = $env:ARG4
            $RecName = $env:ARG5
            $RecType = $env:ARG6
            $RecValue = $env:ARG7
            if ($SubType -eq "create" -or $SubType -eq "update") {
                if ($SubType -eq "update") {
                    $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
                    if (Test-Path $TagsCmd) {
                        & $TagsCmd :libscript_verify_managed azure dns $ZName $ZRg
                        if ($LASTEXITCODE -ne 0) { exit 1 }
                    }
                }
                if ($RecType -eq "A") {
                    az network dns record-set a add-record -g $ZRg -z $ZName -n $RecName -a $RecValue
                } elseif ($RecType -eq "CNAME") {
                    az network dns record-set cname set-record -g $ZRg -z $ZName -n $RecName -c $RecValue
                } elseif ($RecType -eq "TXT") {
                    az network dns record-set txt add-record -g $ZRg -z $ZName -n $RecName -v $RecValue
                }
            } elseif ($SubType -eq "delete") {
                $TagsCmd = Join-Path $LibscriptRootDir "_lib\cloud\core\tags.cmd"
                if (Test-Path $TagsCmd) {
                    & $TagsCmd :libscript_verify_managed azure dns $ZName $ZRg
                    if ($LASTEXITCODE -ne 0) { exit 1 }
                }
                if ($RecType -eq "A") { az network dns record-set a delete -g $ZRg -z $ZName -n $RecName --yes }
                elseif ($RecType -eq "CNAME") { az network dns record-set cname delete -g $ZRg -z $ZName -n $RecName --yes }
                elseif ($RecType -eq "TXT") { az network dns record-set txt delete -g $ZRg -z $ZName -n $RecName --yes }
            } elseif ($SubType -eq "list") {
                az network dns record-set list -g $ZRg -z $ZName -o table
            }
        } elseif ($SubAction -eq "map-node") {
            Write-Host "Mapping $Domain to $ResourceName"
            $Ip = (az vm show -d -g $ResourceGroup -n $ResourceName --query publicIps -o tsv).Trim()
            $RecordName = $Domain.Replace(".$Zone", "")
            if ($RecordName -eq $Domain) { $RecordName = "@" }
            az network dns record-set a add-record -g $DnsRg -z $Zone -n $RecordName -a $Ip
        } elseif ($SubAction -eq "unmap-node") {
            Write-Host "Unmapping $Domain from $ResourceName"
            $Ip = (az vm show -d -g $ResourceGroup -n $ResourceName --query publicIps -o tsv).Trim()
            $RecordName = $Domain.Replace(".$Zone", "")
            if ($RecordName -eq $Domain) { $RecordName = "@" }
            az network dns record-set a remove-record -g $DnsRg -z $Zone -n $RecordName -a $Ip
        }
    }
    
    "start" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_azure" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "start" -ServiceName $ServiceName @args
        } else { Write-Host "start not natively implemented for `$InstallMethod." }
        break
    }
    "install-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_azure" }
        if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
            Libscript-InstallService -ServiceName $ServiceName @args
        } else { Write-Host "install-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_azure" }
        if (Get-Command Libscript-UninstallService -ErrorAction SilentlyContinue) {
            Libscript-UninstallService -ServiceName $ServiceName @args
        } else { Write-Host "uninstall-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall" {
        if ($InstallMethod -eq "libscript_native") {
            if (Get-Command Resolve-ExactVersion -ErrorAction SilentlyContinue) {
                $Info = Resolve-ExactVersion
                $Exact = $Info.ExactVersion
            } else {
                $Exact = if ($Version) { $Version } else { "latest" }
            }
            Write-Host "Uninstalling azure `$Exact..."
            if (Get-Command Get-LibscriptBaseDir -ErrorAction SilentlyContinue) {
                $LibscriptHome = Get-LibscriptBaseDir
            } else {
                $LibscriptHome = Join-Path $HOME ".libscript"
            }
            $TargetDir = Join-Path $LibscriptHome "azure\`$Exact"
            if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
        } else {
            Write-Host "Uninstall not implemented or supported for `$InstallMethod."
        }
        break
    }
    "ls" {
        if ($InstallMethod -eq "mise") { mise ls azure }
        elseif ($InstallMethod -eq "vfox") { vfox ls azure }
        elseif ($InstallMethod -eq "system") { Write-Host "System packages do not support ls here." }
        else {
            if (Get-Command Get-LibscriptBaseDir -ErrorAction SilentlyContinue) {
                $LibscriptHome = Get-LibscriptBaseDir
            } else {
                $LibscriptHome = Join-Path $HOME ".libscript"
            }
            $TargetDir = Join-Path $LibscriptHome "azure"
            if (Test-Path $TargetDir) { Get-ChildItem -Path $TargetDir -Directory | Select-Object -ExpandProperty Name }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") { mise ls-remote azure }
        elseif ($InstallMethod -eq "vfox") { vfox ls all azure }
        else { Write-Host "ls-remote not fully implemented natively yet." }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") { mise use "azure@`$Version" }
        elseif ($InstallMethod -eq "vfox") { vfox use "azure@`$Version" }
        elseif ($InstallMethod -eq "system") { Write-Host "System packages do not support use here." }
        else { Write-Host "Native 'use' requires symlink support which is partially implemented." }
        break
    }
    "download" {
        if ($InstallMethod -eq "libscript_native") {
            Write-Host "Downloading azure..."
        }
        break
    }
    default {
        Write-Host "Not implemented or nothing to do."
    }
}
exit 0
