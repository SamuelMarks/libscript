# Helm

Bootstrap module for the `helm` Kubernetes package manager.

## Usage

Installs the `helm` executable via its official get-helm-3 script.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `helm` versions natively by default (`HELM_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages helm versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/helm/<version>`.
