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
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
