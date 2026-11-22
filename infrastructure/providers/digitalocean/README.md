# DigitalOcean

DigitalOcean cloud provider component for LibScript systems.

## Usage

```sh
./libscript.sh install digitalocean
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                      | Description                                                                                                                                                                  | Default            | Aliases/Examples |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DIGITALOCEAN_VERSION`        | Specific version of digitalocean CLI (doctl) to install.                                                                                                                     | `latest`           | latest, stable   |
| `DIGITALOCEAN_INSTALL_METHOD` | How to install DIGITALOCEAN. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `DIGITALOCEAN_REGION`         | Configuration variable DIGITALOCEAN_REGION for digitalocean.                                                                                                                 | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
