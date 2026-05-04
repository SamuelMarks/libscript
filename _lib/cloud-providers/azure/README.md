# Azure

This module configures the `azure` cloud provider capabilities within LibScript. It leverages the Azure CLI to provide provisioning and configuration targets for Microsoft Azure.

## Purpose & Current State
- Provides runtime context and authentication pathways for Azure targets.
- Serves as the foundation for multi-cloud deployments bridging to Azure VMs, AKS, and Blob Storage.

## Usage
Used internally by the `libscript deploy` and `libscript teardown` systems when Azure is the target provider.
