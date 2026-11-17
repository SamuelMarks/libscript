# Vagrant `bento/freedos-1.4` (`GUEST-DOS32`)

Provides reproducible 16-bit and 32-bit protected-mode (`DOS4GW.EXE` / `DOS32A.EXE` + OpenWatcom v2
`wcl386` `LE`) execution inside the `../bento` FreeDOS 1.4 box using `Bento::VagrantFreedos`
(`:freedos` Telnet/Serial `COM1` communicator and bidirectional `:freedos_sync` `D:` drive).

## Usage

```sh
./vagrant/freedos-1.4/run_dos_ctest.sh --suite=auto-win-msvc --out=results/dos_ctest.json
```

```cmd
vagrant\freedos-1.4\run_dos_ctest.cmd --suite=auto-win-msvc --out=results\dos_ctest.json
```
