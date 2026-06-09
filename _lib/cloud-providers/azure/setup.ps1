$ErrorActionPreference = "Stop"

$Action = $env:ACTION
$SubAction = $env:ARG1
$ResourceName = $env:ARG2
$ResourceGroup = $env:ARG3

switch ($Action) {
    "network" {
        if ($SubAction -eq "create") {
            $Loc = if ($env:location) { $env:location } else { "eastus" }
            Write-Host "Creating Azure VNet: $ResourceName in $ResourceGroup ($Loc)"
            az network vnet create --name $ResourceName --resource-group $ResourceGroup --location $Loc
        } elseif ($SubAction -eq "delete") {
            Write-Host "Deleting Azure VNet: $ResourceName from $ResourceGroup"
            az network vnet delete --name $ResourceName --resource-group $ResourceGroup --yes
        }
    }
    "firewall" {
        $Ports = $env:ARG4
        if ($SubAction -eq "create") {
            $Loc = if ($env:location) { $env:location } else { "eastus" }
            Write-Host "Creating Azure NSG: $ResourceName in $ResourceGroup ($Loc)"
            az network nsg create --name $ResourceName --resource-group $ResourceGroup --location $Loc
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
            Write-Host "Deleting Azure NSG: $ResourceName from $ResourceGroup"
            az network nsg delete --name $ResourceName --resource-group $ResourceGroup --yes
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
            
            Write-Host "Creating Azure VM: $ResourceName in $ResourceGroup ($Size, $Image)"
            & az vm create --resource-group $ResourceGroup --name $ResourceName --image $Image --size $Size --admin-username azureuser --generate-ssh-keys --public-ip-sku Standard @ArgsList
        } elseif ($SubAction -eq "delete") {
            $ResourceGroup = $env:ARG3
            Write-Host "Deleting Azure VM: $ResourceName from $ResourceGroup"
            az vm delete --name $ResourceName --resource-group $ResourceGroup --yes
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
        if ($SubAction -eq "map-node") {
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
    default {
        Write-Host "Not implemented or nothing to do."
    }
}
exit 0
