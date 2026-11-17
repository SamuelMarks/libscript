# Vagrant `bento/msdos-1.25` (`GUEST-DOS32`)

Provides reproducible 16-bit and 32-bit protected-mode (`DOS32A.EXE` + OpenWatcom v2 `wcl386` `LE`)
execution inside the `../bento` MS-DOS 1.25 box using `Bento::VagrantMsdos` (`:msdos` Telnet/Serial
`COM1` communicator and bidirectional `:msdos_sync` `D:` drive).

## Usage

```sh
./vagrant/msdos-1.25/run_dos_ctest.sh --suite=auto-win-msvc --out=results/dos_ctest.json
```

```cmd
vagrant\msdos-1.25\run_dos_ctest.cmd --suite=auto-win-msvc --out=results\dos_ctest.json
```
