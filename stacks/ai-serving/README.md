# Ai Serving Stacks

This directory contains pre-configured application stack definitions and orchestration workflows for
ai serving solutions in LibScript.

## Available Stacks

- **[gke-xpk-inference](gke-xpk-inference/)**: This component manages the installation and execution
  of `gke-xpk-inference` within the libscript
- **[tpu-vm-vllm](tpu-vm-vllm/)**: This component manages the installation and execution of
  `tpu-vm-vllm` within the libscript

## Usage

To provision and run any stack in this category:

```sh
./libscript.sh run <stack-name> latest
```
