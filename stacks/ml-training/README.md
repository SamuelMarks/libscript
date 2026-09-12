# Ml Training Stacks

This directory contains pre-configured application stack definitions and orchestration workflows for
ml training solutions in LibScript.

## Available Stacks

- **[gke-xpk-training](gke-xpk-training/)**: Deploys a generic ML training job to a Google Cloud TPU
  or GPU Pod via XPK.
- **[tpu-vm-eval-node](tpu-vm-eval-node/)**: This stack automates the provisioning of a single TPU
  VM optimized for heavy, long-running ML

## Usage

To provision and run any stack in this category:

```sh
./libscript.sh run <stack-name> latest
```
