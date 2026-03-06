# Experimental Ideas

This document tracks experimental features and potential use-cases for LibScript's architecture. These concepts explore capabilities beyond standard software provisioning.

## AI and Machine Learning Toolchains

Investigating the viability of generically provisioning complex, hardware-dependent stacks (such as CUDA drivers, vLLM, and Jupyter) locally on host machines to avoid the overhead associated with containerized GPU passthrough.

## Interactive TUI Generation

Expanding the generator capabilities to include a full Terminal User Interface (`package_as TUI`). This would allow end-users to interactively configure environment variables and ports before finalizing an installation or generating an artifact.

## Immutable OS Deployment

Exploring integrations with tools like `ostree` to compile declarative `libscript.json` definitions into customized, bootable operating system images.

## Edge Computing Constraints

Because LibScript operates without heavy runtimes (like Python or Ruby), it presents an opportunity to provision resource-constrained embedded and edge devices more efficiently than traditional configuration management tools.
