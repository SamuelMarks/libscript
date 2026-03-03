nginx server roadmap
====================

  - [ ] simple secure (for template interpolation)
  - [ ] simple insecure (for template interpolation)
  - [ ] letsencrypt auto-setup and auto-renew
  - [ ] alternative to letsencrypt (e.g., ZeroSSL, cloud-vendor, user-provided)
  - [ ] setup nginx.conf with sites-available or `/etc/nginx/conf.d/*.conf` as include dir (if not set that way already)
  - [ ] backups and rollbacks, so; e.g.; if `nginx -t` fails rollback to previous working version and show error
  - [ ] checksums (so if nothing changed don't `restart`|`stop`+`start`|`reload` nginx daemon)
  - [ ] translate [compile!] `location` block to IIS and Apache Web Server equivalents
  - [ ] `setup.cmd` for Windows
  - [ ] `setup_generic.sh`
  - [ ] `setup_alpine.sh`
  - [ ] `setup_debian.sh`
  - [ ] `setup_macOS.sh`



## Dependency Installation Methods

`libscript` provides a flexible dependency management system, allowing you to control how dependencies are installed—either globally across the entire setup or locally on a per-toolchain basis.

### Global Configuration

You can set a global preference for how tools should be installed by defining `LIBSCRIPT_GLOBAL_INSTALL_METHOD` in your environment or global configuration (`install.json`).

Supported global methods typically include:
- `system`: Uses the system's package manager (e.g., `apt`, `apk`, `pacman`).
- `source`: Builds or downloads the tool from source/official binaries (fallback behavior depends on the tool).

Example:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
```

### Local Overrides

You can override the global setting for specific dependencies by setting their respective `[TOOL]_INSTALL_METHOD` variable. The local override takes highest precedence. 

For example, to globally use the system package manager but strictly install Python via `uv`:
```sh
export LIBSCRIPT_GLOBAL_INSTALL_METHOD="system"
export PYTHON_INSTALL_METHOD="uv"
```

### Python-Specific Support

The Python toolchain (`_lib/_toolchain/python`) is extensively integrated with this feature and supports the following `PYTHON_INSTALL_METHOD` values:
- `uv` (default fallback): Installs Python and creates virtual environments using astral's `uv` tool.
- `pyenv`: Installs Python versions using `pyenv`, managing them in `~/.pyenv`.
- `system`: Uses the system's package manager to provide Python.
- `from-source`: Compiles Python directly from its source code.

By combining global methods with local overrides, you can mix and match system-provided stable packages with newer or custom-compiled toolchains as needed.
