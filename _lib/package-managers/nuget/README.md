# Nuget

Bootstrap module for the `nuget` package manager.

## Usage

Ensures the `nuget` executable is available. Uses libscript_native package manager mapping (e.g.,
`nuget` package on Debian).

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

Libscript manages nuget versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/nuget/<version>`.

## Configuration

| Variable               | Description                                                                                                                                                           | Default            | Required |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `NUGET_INSTALL_METHOD` | How to install NUGET. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |
