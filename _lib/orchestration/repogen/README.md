# LibScript Repository Generation Engines

This directory provides universal repository metadata synthesis tools:

- `apk_index.sh` / `apk_index.cmd`: Generates `APKINDEX.tar.gz` and RSA signing stubs for Alpine
  package archives.
- `deb_index.sh` / `deb_index.cmd`: Generates `Packages.gz`, `Release`, and `InRelease` manifests
  for Debian APT repositories.
- `rpm_index.sh` / `rpm_index.cmd`: Generates `repomd.xml`, `primary.xml.gz`, and `filelists.xml.gz`
  for Red Hat YUM/DNF repositories.
- `repogen.sh` / `repogen.cmd`: Unified CLI orchestrator generating all repository indices and
  optionally running an embedded local HTTP testing server.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                              | Default  | Aliases/Examples |
| ------------------------ | -------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `REPOGEN_VERSION`        | Specific version of repogen to install.                                                                  | `latest` |                  |
| `REPOGEN_INSTALL_METHOD` | How to install REPOGEN. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
