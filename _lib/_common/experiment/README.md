# Shared SIGPLAN Empirical Evaluation Harness (`_lib/_common/experiment/`)

Provides `harness.{sh,cmd}`, `c_probes/libscript_bench_probe.c`, provenance verification (`RULE-1`),
native ISA guards (`RULE-2`), cold/warm trial separation (`RULE-3`), C11 monotonic `ns`
quantiles/IQR (`RULE-4`), and 5-OS RSS accounting (`RULE-5`) for all `experiments/<suite-id>/`
plugins.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
