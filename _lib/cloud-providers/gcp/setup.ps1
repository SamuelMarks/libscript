<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'gcp' stack.

.DESCRIPTION
Execute this script to install and configure gcp on the local system.
#>

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
$SubAction = $env:ARG1
$ResourceName = $env:ARG2

switch ($Action) {
    "node" {
        if ($SubAction -eq "create") {
            $Type = if ($env:ARG3) { $env:ARG3 } else { "n1-standard-1" }
            $Image = if ($env:ARG4) { $env:ARG4 } else { "debian-11" }
            if ($ResourceName) {
                Write-Host "Creating GCP VM: $ResourceName ($Type, $Image)"
                gcloud compute instances create $ResourceName --machine-type=$Type --image-family=$Image --image-project="debian-cloud"
            } else {
                Write-Host "Usage: node create <name> <type> <image>"
                exit 1
            }
        } elseif ($SubAction -eq "delete") {
            if ($ResourceName) {
                Write-Host "Deleting GCP VM: $ResourceName"
                gcloud compute instances delete $ResourceName --quiet
            } else {
                Write-Host "Usage: node delete <name>"
                exit 1
            }
        } elseif ($SubAction -eq "list") {
            gcloud compute instances list
        } elseif ($SubAction -eq "update") {
            $Type = $env:ARG3
            if ($ResourceName -and $Type) {
                gcloud compute instances set-machine-type $ResourceName --machine-type=$Type
            } else {
                Write-Host "Usage: node update <name> <type>"
                exit 1
            }
        } elseif ($SubAction -eq "exec") {
            $Cmd = $env:ARG3
            if ($ResourceName -and $Cmd) {
                gcloud compute ssh $ResourceName --command=$Cmd
            } else {
                Write-Host "Usage: node exec <name> <cmd>"
                exit 1
            }
        }
        exit 0
    }
    "dns" {
        $SubType = $env:ARG2
        if ($SubAction -eq "zone") {
            $Zone = $env:ARG3
            $DnsName = $env:ARG4
            if ($SubType -eq "create") {
                if ($Zone -and $DnsName) {
                    gcloud dns managed-zones create $Zone --dns-name=$DnsName --description="Libscript managed"
                } else {
                    Write-Host "Usage: dns zone create <zone> <dns-name>"
                }
            } elseif ($SubType -eq "delete") {
                if ($Zone) {
                    gcloud dns managed-zones delete $Zone --quiet
                } else {
                    Write-Host "Usage: dns zone delete <zone>"
                }
            } elseif ($SubType -eq "list") {
                gcloud dns managed-zones list
            }
        } elseif ($SubAction -eq "record") {
            $Zone = $env:ARG3
            $RecName = $env:ARG4
            $RecType = $env:ARG5
            $RecData = $env:ARG6
            $RecTtl = if ($env:ARG7) { $env:ARG7 } else { 300 }
            if ($SubType -eq "create") {
                if ($RecData) {
                    gcloud dns record-sets create $RecName --zone=$Zone --type=$RecType --rrdatas=$RecData --ttl=$RecTtl
                } else {
                    Write-Host "Usage: dns record create <zone> <name> <type> <data> [ttl]"
                }
            } elseif ($SubType -eq "update") {
                if ($RecData) {
                    gcloud dns record-sets update $RecName --zone=$Zone --type=$RecType --rrdatas=$RecData --ttl=$RecTtl
                } else {
                    Write-Host "Usage: dns record update <zone> <name> <type> <data> [ttl]"
                }
            } elseif ($SubType -eq "delete") {
                if ($RecType) {
                    gcloud dns record-sets delete $RecName --zone=$Zone --type=$RecType --quiet
                } else {
                    Write-Host "Usage: dns record delete <zone> <name> <type>"
                }
            } elseif ($SubType -eq "list") {
                if ($Zone) {
                    gcloud dns record-sets list --zone=$Zone
                } else {
                    Write-Host "Usage: dns record list <zone>"
                }
            }
        }
        exit 0
    }
    "firewall" {
        if ($SubAction -eq "create") {
            $Network = if ($env:ARG3) { $env:ARG3 } else { "default" }
            $Allow = $env:ARG4
            if ($ResourceName) {
                Write-Host "Creating GCP Firewall Rule: $ResourceName"
                $ArgsList = @("compute", "firewall-rules", "create", $ResourceName, "--network=$Network")
                if ($Allow) { $ArgsList += "--allow=$Allow" }
                & gcloud @ArgsList
            } else {
                Write-Host "Usage: firewall create <name> <network> <allow>"
                exit 1
            }
        } elseif ($SubAction -eq "delete") {
            if ($ResourceName) {
                Write-Host "Deleting GCP Firewall Rule: $ResourceName"
                gcloud compute firewall-rules delete $ResourceName --quiet
            } else {
                Write-Host "Usage: firewall delete <name>"
                exit 1
            }
        } elseif ($SubAction -eq "list") {
            gcloud compute firewall-rules list
        } elseif ($SubAction -eq "update") {
            $Allow = $env:ARG3
            if ($ResourceName -and $Allow) {
                gcloud compute firewall-rules update $ResourceName --allow=$Allow
            } else {
                Write-Host "Usage: firewall update <name> <allow>"
                exit 1
            }
        }
        exit 0
    }
    "network" {
        if ($SubAction -eq "create") {
            if ($ResourceName) {
                Write-Host "Creating GCP Network: $ResourceName"
                gcloud compute networks create $ResourceName
            } else {
                Write-Host "Usage: network create <name>"
                exit 1
            }
        } elseif ($SubAction -eq "delete") {
            if ($ResourceName) {
                Write-Host "Deleting GCP Network: $ResourceName"
                gcloud compute networks delete $ResourceName --quiet
            } else {
                Write-Host "Usage: network delete <name>"
                exit 1
            }
        } elseif ($SubAction -eq "list") {
            gcloud compute networks list
        } elseif ($SubAction -eq "update") {
            $Mode = $env:ARG4
            if ($ResourceName -and $Mode) {
                gcloud compute networks update $ResourceName --bgp-routing-mode=$Mode
            } else {
                Write-Host "Usage: network update <name> <resource-group> <bgp-routing-mode>"
                exit 1
            }
        }
        exit 0
    }
    "auth" {
        if ($SubAction -eq "login") {
            gcloud auth login
            gcloud auth application-default login
        } elseif ($SubAction -eq "logout") {
            gcloud auth revoke
        } elseif ($SubAction -eq "status") {
            gcloud auth list
        }
        exit 0
    }
    "location" {
        if ($SubAction -eq "list") {
            gcloud compute regions list
        } elseif ($SubAction -eq "select") {
            if ($ResourceName) {
                gcloud config set compute/region $ResourceName
                Write-Host "Default location set to $ResourceName."
            } else {
                Write-Host "Usage: location select <location>"
                exit 1
            }
        }
        exit 0
    }
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "mise") { mise ls gcp; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls gcp; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "gcp"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "mise") { mise ls-remote gcp; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls all gcp; exit 0 }
    Write-Output "ls-remote not fully implemented natively yet."
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "mise") { mise use "gcp@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox use "gcp@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    Write-Output "Native 'use' requires symlink support which is partially implemented."
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading gcp to $DownloadDir\gcp..."
    }
    exit 0
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        if (Get-Command libscript_service -ErrorAction SilentlyContinue) {
            libscript_service $Action $ServiceName
        } else {
            if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
                Libscript-Service -Action $Action -ServiceName $ServiceName @args
            } else { Write-Output "$Action not natively implemented for `$InstallMethod." }
        }
    } else {
        Write-Output "$Action not natively implemented for `$InstallMethod."
    }
    exit 0
}

if ($Action -eq "install-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        if (Get-Command libscript_install_service -ErrorAction SilentlyContinue) {
            libscript_install_service $ServiceName
        } else {
            if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
                Libscript-InstallService -ServiceName $ServiceName @args
            } else { Write-Output "install-service not implemented for `$InstallMethod." }
        }
    } else {
        Write-Output "install-service not implemented for `$InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        if (Get-Command libscript_uninstall_service -ErrorAction SilentlyContinue) {
            libscript_uninstall_service $ServiceName
        } else {
            if (Get-Command Libscript-UninstallService -ErrorAction SilentlyContinue) {
                Libscript-UninstallService -ServiceName $ServiceName @args
            } else { Write-Output "uninstall-service not implemented for `$InstallMethod." }
        }
    } else {
        Write-Output "uninstall-service not implemented for `$InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Uninstalling gcp $CompVersion..."
        if (-not $LibscriptHome) { $LibscriptHome = Join-Path $HOME ".libscript" }
        $TargetDir = Join-Path (Join-Path $LibscriptHome "gcp") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for `$InstallMethod."
    }
    exit 0
}
