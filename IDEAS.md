# Experimental Ideas

This document tracks experimental features and potential use-cases for LibScript's architecture.
These concepts explore capabilities beyond standard software provisioning.

## AI and Machine Learning Toolchains (Partially Implemented)

We have implemented automation for provisioning GPU and TPU Virtual Machines on Google Cloud
(including XPK and vLLM stacks). We are now investigating the viability of generically provisioning
complex, hardware-dependent stacks (such as CUDA drivers and vLLM) locally on bare-metal host
machines to avoid the overhead associated with containerized GPU passthrough.

## Immutable OS Deployment (Partially Implemented)

Tier 2 now natively synthesizes signed Unified Kernel Images (UKI), immutable SquashFS + OverlayFS
hybrid live ISOs, and Firecracker microVM direct boot kernels. We are now exploring integrations
with tools like `ostree` and transactional A/B sysroot update partitions for atomic over-the-air
upgrades.

## Auto-Scaling Native Clusters

Design a mechanism to automatically spin up additional compute nodes and register them with a
dynamic `netctl` load balancer configuration, effectively mimicking Kubernetes Horizontal Pod
Autoscaler (HPA) using raw VMs and native orchestration primitives.

## Edge Computing Constraints

Because LibScript operates without heavy runtimes (like Python or Ruby), it presents an opportunity
to provision resource-constrained embedded and edge devices more efficiently than traditional
configuration management tools.
