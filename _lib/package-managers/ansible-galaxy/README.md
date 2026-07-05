# Ansible Galaxy

Bootstrap module for the `ansible-galaxy` package manager.

## Usage

Ensures the `ansible-galaxy` executable is available. This relies on the core language toolchain
appropriate for the tool.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Configuration

| Variable                        | Description                                                                                                                                                                    | Default            | Required |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | -------- |
| `ANSIBLE_GALAXY_INSTALL_METHOD` | How to install ANSIBLE GALAXY. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

Libscript manages ansible-galaxy versions natively by installing them into isolated directories
under `LIBSCRIPT_HOME/ansible-galaxy/<version>`.
