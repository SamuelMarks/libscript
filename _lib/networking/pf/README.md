# Packet Filter (PF)

**Tier**: `T2` (`_lib/networking/pf/`) | **Capabilities**: `sysroot-package`

FreeBSD stateful packet inspection firewall

## Usage

```sh
./libscript.sh install pf
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable | Description | Default | Aliases/Examples |
| -------- | ----------- | ------- | ---------------- |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
