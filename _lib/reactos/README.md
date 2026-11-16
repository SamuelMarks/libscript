# ReactOS Kernel & Base World Engine (`_lib/reactos/`)

Top-level ReactOS operating system synthesis engine supporting both:

1. **Upstream ISO Repacking (Default)**: Delegates to `_lib/reactos/distro/base.{sh,cmd}` to fetch,
   SHA-256 verify, and extract official ReactOS `0.4.16` (`i686`) or nightly (`i686` / `x86_64`)
   `BootCD` / `LiveCD` archives into `${LIBSCRIPT_TARGET_SYSROOT}/iso_root/`.
2. **Full Source Compilation (`--from-source` / `REACTOS_BUILD_FROM_SOURCE=1`)**: Bootstraps
   `_lib/toolchains/rosbe/` (`i686-w64-mingw32` or `x86_64-w64-mingw32` + CMake + Ninja), stages
   slipstreamed payloads into `${REACTOS_SRC_DIR}/modules/optional/libscript/` via CMake
   `add_cd_file()`, compiles `host-tools` and `bootcd`/`livecd`, and populates the target sysroot.

## Usage

```sh
# Stage ReactOS sysroot via upstream ISO repack (or --allow-stub in offline tests)
./_lib/reactos/setup.sh --allow-stub install

# Compile ReactOS from REACTOS_SRC_DIR using RosBE
REACTOS_SRC_DIR=/path/to/reactos ./_lib/reactos/setup.sh --from-source compile
```
