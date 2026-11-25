# Declarative DOS Synthesis Profiles (`synthesis/profiles/dos/`)

Reference profiles covering all three DOS capability strata supported by LibScript:

- `freedos-1.4-djgpp-i586.json` (`dos32-dpmi`): FreeDOS 1.4 (`FAT32`), `win-cmd-rs` (`WINCMD.EXE` +
  `CWSDPMI.EXE`), `win-cmd-asm` (`WINCMD.COM` + 17 utilities), DJGPP `bash` + `coreutils`, `Watt-32`
  (`PCNTPKT`), and `dos32` ports.
- `msdos-4.0-djgpp-i586.json` (`dos32-dpmi`): MIT MS-DOS 4.00 (`FAT16 BIGDOS`, strict 8.3 `LFN=n`),
  `win-cmd-rs`, `win-cmd-asm`, `CWSDPMI` + `DOS32A`, and DJGPP userland.
- `msdos-2.0-realmode-i8086.json` (`dos16-handle`): MIT MS-DOS 2.0 (`FAT12` hierarchical 8.3) with
  `win-cmd-asm` (`SHELL=C:\DOS\WINCMD.COM` + 17 CRT-free 8086 utilities including `FINDSTR.COM` and
  `WHERE.COM`), unlocking canonical LibScript `.cmd` scripts on pure 16-bit 8086 VMs.
- `msdos-1.25-heritage-i8086.json` (`dos16-fcb`): MIT MS-DOS 1.25 (`FAT12` flat root directory,
  FCB-only `INT 21h`) with clean-room `IO.SYS` and `win-cmd-asm` `WINCMD1.COM`.
