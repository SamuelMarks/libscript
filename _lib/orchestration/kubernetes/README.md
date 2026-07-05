# Kubernetes

Documentation for Kubernetes components.

## Configuration

| Variable                    | Description                                                                                                                                                                | Default            | Required |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `KUBERNETES_INSTALL_METHOD` | How to install KUBERNETES. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

Libscript manages kubernetes versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/kubernetes/<version>`.
