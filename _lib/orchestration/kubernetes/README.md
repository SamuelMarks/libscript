# Kubernetes

Documentation for Kubernetes components.

## Configuration

| Variable                    | Description                                                                                                                                                                | Default            | Required |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `KUBERNETES_INSTALL_METHOD` | How to install KUBERNETES. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

Libscript manages kubernetes versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/kubernetes/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                    | Description                                                          | Default            | Aliases/Examples |
| --------------------------- | -------------------------------------------------------------------- | ------------------ | ---------------- |
| `KUBERNETES_VERSION`        | Specific version of Kubernetes/kubectl to install.                   | `latest`           | latest, stable   |
| `KUBERNETES_INSTALL_METHOD` | How to install Kubernetes tools.                                     | `libscript_native` |                  |
| `KUBERNETES_DOWNLOAD_URL`   | Override URL for downloading kubernetes binary or archive artifacts. | `none`             |                  |
| `KUBERNETES_RELEASES_URL`   | Override URL for querying kubernetes available remote releases.      | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
