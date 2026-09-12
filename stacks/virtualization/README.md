# Virtualization Stacks

This directory contains pre-configured application stack definitions and orchestration workflows for
virtualization solutions in LibScript.

## Available Stacks

- **[bento-builder](bento-builder/)**: Provisioning stack for Chef Bento box building on Linux,
  macOS, and cloud VMs (such as Azure nested virtualization VMs).

## Usage

To provision and run any stack in this category:

```sh
./libscript.sh run <stack-name> latest
```
