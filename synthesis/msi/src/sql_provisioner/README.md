# SQL Provisioner Custom Action

Zero-.exe in-process SQL database provisioner DLL for Windows Installer packages.

## Purpose & Current State

This component compiles into a lightweight C++ custom action DLL (`sql_provisioner.dll`) that
executes inside `msiexec.exe`. It configures MySQL/MariaDB database schemas, user permissions, and
character sets directly during MSI transactions without requiring external shell executables or
external tooling.

## API Functions

- `ProvisionDatabase(MSIHANDLE hInstall)`: Reads database parameters from MSI properties
  (`PROP_MYSQL_HOST`, `PROP_MYSQL_PORT`, `PROP_PROVISION_DB_NAME`, `PROP_PROVISION_USER`,
  `PROP_PROVISION_PASSWORD`, `PROP_PROVISION_COLLATION`) and executes creation and grant statements.
- `DeprovisionDatabase(MSIHANDLE hInstall)`: Drops schemas and users upon package uninstallation
  when `PURGE_DATA` is set to `1`.
