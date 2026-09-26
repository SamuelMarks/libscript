# MSI Chainer Custom Action

Custom action DLL for nested package discovery and transaction chaining in Windows Installer.

## Purpose & Current State

This component compiles into a lightweight C++ custom action DLL (`chainer.dll`) that coordinates
multi-package installations inside `msiexec.exe`. It handles Windows service detection, child
package extraction, property pass-through, and atomic transaction execution across bundled
sub-installers.

## API Functions

- `LibScriptChainer(MSIHANDLE hInstall)`: Main entrypoint orchestrating sub-package chain execution
  and transaction boundaries.
- `LibScriptDetectServices(MSIHANDLE hInstall)`: Queries active installations and service endpoints
  prior to executing sub-package setups.
- `LibScriptExtractChildPackages(MSIHANDLE hInstall)`: Extracts embedded binary streams to staging
  directories.
- `LibScriptExecuteTransaction(MSIHANDLE hInstall)`: Sequentially runs MSI installations within an
  atomic transaction.
