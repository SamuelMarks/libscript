# Tier 3 (`T3`) Offline Package Repository Generator (`synthesis/repogen/`)

## Overview

`synthesis/repogen/` builds signed, air-gapped native OS package repositories from locally built or
cached `.deb`, `.rpm`, and `.apk` artifacts so synthesized images and isolated enterprise networks
can install packages via standard OS tools without internet access.

## Scripts

- **`repogen.{sh,cmd}`**: Unified repository index dispatcher.
- **`deb_index.{sh,cmd}`**: Generates Debian/Ubuntu `Packages`, `Packages.gz`, and `Release` /
  `InRelease` metadata (`dpkg-scanpackages` / `apt-ftparchive`).
- **`rpm_index.{sh,cmd}`**: Generates Red Hat/Fedora `repodata/repomd.xml` indices (`createrepo_c`).
- **`apk_index.{sh,cmd}`**: Generates Alpine `APKINDEX.tar.gz` signed indices.

## Usage

```sh
./synthesis/repogen/cli.sh --format deb --dir build/repo/deb
./synthesis/repogen/cli.sh --format rpm --dir build/repo/rpm
./synthesis/repogen/cli.sh --format apk --dir build/repo/apk
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                              | Default  |
| :----------------------- | :------------------------------------------------------------------------------------------------------- | :------- |
| `REPOGEN_VERSION`        | Specific version of repogen to install.                                                                  | `latest` |
| `REPOGEN_INSTALL_METHOD` | How to install REPOGEN. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
