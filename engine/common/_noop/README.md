# Null / No-Op Fallback Module (`engine/common/_noop/`)

## Overview

`engine/common/_noop/` is a `T0` null-operation component implementation used for hermetic testing,
disabled stack slots, and safe fallback routing when an optional dependency or service slot is
explicitly omitted from a `libscript.json` or `os-config.json` manifest.

Unlike installable `T1`/`T2` recipes in `_lib/`, `_noop` performs zero filesystem mutations, network
fetches, or daemon registrations, returning exit code `0` across standard component lifecycle entry
points (`setup`, `uninstall`, `status`, `logs`, `test`, `env`).

## Files

- `manifest.json` & `vars.schema.json`: Minimal `T0` schema-valid manifest and empty variable
  contract.
- `cli.{sh,cmd}`: Standard component CLI router dispatching no-op lifecycle actions.
- `setup.{sh,cmd}` & `setup_generic.{sh,cmd}`: Idempotent zero-mutation setup handlers.
- `uninstall.{sh,cmd}` & `uninstall_generic.{sh,cmd}`: Idempotent zero-mutation teardown handlers.
- `env.{sh,cmd}`, `false_env.{sh,cmd}`, `status.{sh,cmd}`, `logs.{sh,cmd}`, `test.{sh,cmd}`:
  Environment, status, log, and smoke-test stubs.

## Usage

```sh
# Execute the hermetic no-op smoke test
./engine/common/_noop/test.sh
```

```cmd
:: Windows Batch equivalent
.\engine\common\_noop\test.cmd
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable | Description | Default |
| :------- | :---------- | :------ |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
