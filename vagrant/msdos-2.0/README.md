# Vagrant `anondos/msdos-2.0` (`GUEST-DOS32`)

Provides reproducible 32-bit protected-mode (`DOS32A.EXE` + OpenWatcom v2 `wcl386` `LE`) `CTest`
execution over the `COM1` serial communicator for `win_port` Experiment 3C (`E3C`).

## Usage

```sh
./vagrant/msdos-2.0/run_dos_ctest.sh --suite=auto-win-msvc --out=results/dos_ctest.json
```

```cmd
vagrant\msdos-2.0\run_dos_ctest.cmd --suite=auto-win-msvc --out=results\dos_ctest.json
```
