# Developing LibScript

This guide covers how to add new components, maintain existing ones, and contribute to the LibScript ecosystem.

## Adding a New Component

To create a new component (e.g., a new database or toolchain), follow these steps:

1. **Choose the Right Directory:**
   - Toolchains (languages, compilers): `_lib/_toolchain/`
   - Servers (web servers, proxies): `_lib/_server/`
   - Storage (databases, caches): `_lib/_storage/`
   - Applications: `app/`

2. **Scaffold the Component:**
   Create the directory and the base files:
   ```sh
   mkdir -p _lib/_toolchain/mytool
   ln -s ../../_common/cli.sh _lib/_toolchain/mytool/cli.sh _lib/_toolchain/mytool/setup.sh _lib/_toolchain/mytool/setup_generic.sh _lib/_toolchain/mytool/vars.schema.json
   chmod +x _lib/_toolchain/mytool/*.sh
   ```

3. **Implement `vars.schema.json`:**
   Define the configuration options your component accepts. This schema is used by the global CLI to generate help text.

4. **Implement `cli.sh`:**
   Symlink `_lib/_common/cli.sh` and `_lib/_common/cli.cmd` into your component directory. These scripts automatically handle argument parsing, `--help`, and routing to `setup.sh`.

5. **Implement `setup.sh`:**
   This script should source `_lib/_common/os_info.sh` to detect the OS, load `env.sh` (if any), and route execution to `setup_generic.sh` or OS-specific scripts.

6. **Write the Installation Logic (`setup_generic.sh`):**
   - Source `_lib/_common/pkg_mgr.sh`.
   - Use `depends <pkg>` to install OS-level requirements.
   - Perform the download, extraction, and configuration.
   - Ensure the script is idempotent (can run multiple times without failing or duplicating work).

7. **Add Tests:**
   Create a `test.sh` and `test.cmd` (or `test.bat` for DOS) that actually verifies the software works. For a compiler, build a simple script. For a server, ping its port.

8. **MS-DOS Support (Optional):**
   If you want to support MS-DOS, create a `setup.bat` and `cli.bat`. The global routers (`libscript.bat` and `install.bat`) will prioritize these over `.cmd` scripts for backward compatibility without breaking modern Windows setups.

## Best Practices

- **Idempotency:** Always assume your script has been run before. Use checks like `if command -v tool >/dev/null; then return; fi` or check for the existence of configuration files before appending to them.
- **Fail Fast:** Use `set -feu` (or `set -e`) in all shell scripts to fail immediately on errors or unbound variables.
- **ShellCheck:** Validate all shell scripts using `shellcheck`.
- **No Interactive Prompts:** Do not use `read` or prompt the user during installation. Assume non-interactive headless execution. Use environment variables for configuration.
