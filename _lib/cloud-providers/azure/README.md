# Azure

This module configures the `azure` cloud provider capabilities within LibScript. It leverages the Azure CLI to provide provisioning and configuration targets for Microsoft Azure.

## Purpose & Current State
- Provides runtime context and authentication pathways for Azure targets.
- Serves as the foundation for multi-cloud deployments bridging to Azure VMs, AKS, and Blob Storage.
- Fully implements native lifecycle orchestration for `network` (VNets), `firewall` (NSGs), `node` (VMs), `dns` (Record Sets), and code `sync` logic across both POSIX (`setup_generic.sh`) and Windows (`setup.ps1`) endpoints.

## Usage
Used internally by the `libscript provision` and `libscript deprovision` systems when Azure is the target provider. You can also invoke these primitives manually to orchestrate shared instances:

```bash
# Example manual orchestration
./libscript.sh cloud azure network create my-vnet my-rg
./libscript.sh cloud azure firewall create my-nsg my-rg "22 80 443"
./libscript.sh cloud azure node create my-node Ubuntu2204 my-rg --size Standard_B2s --vnet-name my-vnet --nsg my-nsg
./libscript.sh cloud azure node deploy my-node my-rg ./ my-app
```
