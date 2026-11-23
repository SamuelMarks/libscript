# ML & TPU Shared Orchestration (`workloads/ai/_common`)

## Purpose

Domain-scoped POSIX `/bin/sh` and Windows Batch (`.cmd`) libraries for Google Cloud TPU VM
provisioning, TFRC zero-cost billing guardrails (`tfrc_guard.{sh,cmd}`), and multi-backend TPU
benchmark isolation (`tpu_matrix.{sh,cmd}`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

> **Global Framework Variables**: Core paths, offline cache controls, and experiment schema packs
> (`schemas/vars/experiment.schema.json`) are documented in
> [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
