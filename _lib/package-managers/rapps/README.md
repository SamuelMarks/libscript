# ReactOS Applications Manager (`rapps`)

Standalone LibScript package and version manager recipe for **RAPPS** (ReactOS Applications
Manager). On ReactOS/Windows guests it wraps `rapps.exe /install` and silent pre-fetched installer
execution; on Linux, macOS, BSD, illumos, and Windows build hosts it parses `rapps-db` `.txt` INI
manifests (`[Section]`, `[Section.amd64]`, `[Section.x86]`) and prefetches SHA-256 verified
installers for air-gapped ReactOS distribution baking.

## Usage

```sh
# Install isolated rapps CLI & catalog database
./libscript.sh install rapps 0.4.16

# Parse a RAPPS .txt INI manifest
./_lib/package-managers/rapps/cli.sh parse-ini <file.txt>

# Prefetch a package installer for offline ReactOS image staging
./_lib/package-managers/rapps/cli.sh prefetch 7zip --arch=i686 --dest=build/reactos/cache/rapps
```

## Configuration Variables

See [`vars.schema.json`](./vars.schema.json) for all supported configuration variables including
`RAPPS_VERSION`, `LIBSCRIPT_RAPPS_DB_URL`, `LIBSCRIPT_RAPPS_CACHE_DIR`, and `LIBSCRIPT_RAPPS_ARCH`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                            | Default                                                                | Aliases/Examples |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ---------------- |
| `RAPPS_INSTALL_METHOD`      | Installation strategy for rapps ('libscript_native' stages isolated rapps-db catalog and CLI wrapper, 'system' uses native rapps.exe). | `libscript_native`                                                     |                  |
| `RAPPS_VERSION`             | Specific version or branch alias of rapps / rapps-db to install.                                                                       | `0.4.16`                                                               | latest, 0.4.16   |
| `RAPPS_DOWNLOAD_URL`        | Override URL for downloading the rapps-db package catalog archive.                                                                     | `none`                                                                 |                  |
| `RAPPS_RELEASES_URL`        | Override URL for querying available rapps / ReactOS release tags.                                                                      | `none`                                                                 |                  |
| `RAPPS_FETCH_UPSTREAM_DB`   | Set to '1' to download and overlay the upstream GitHub rapps-db archive during native setup.                                           | `0`                                                                    |                  |
| `LIBSCRIPT_RAPPS_VERSION`   | Target rapps catalog version override when invoked from ReactOS distribution profiles.                                                 | `0.4.16`                                                               |                  |
| `LIBSCRIPT_RAPPS_DB_URL`    | Upstream archive URL for the ReactOS Applications Manager package database (rapps-db).                                                 | `https://github.com/reactos/rapps-db/archive/refs/heads/master.tar.gz` |                  |
| `LIBSCRIPT_RAPPS_DB_DIR`    | Filesystem directory containing extracted RAPPS .txt INI package definitions.                                                          | `none`                                                                 |                  |
| `LIBSCRIPT_RAPPS_CACHE_DIR` | Destination directory for pre-fetched and verified RAPPS application installers.                                                       | `none`                                                                 |                  |
| `LIBSCRIPT_RAPPS_ARCH`      | Target PE CPU architecture used when resolving architecture-specific RAPPS sections.                                                   | `i686`                                                                 |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
