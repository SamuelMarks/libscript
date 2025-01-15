Windows support
===============

First look in `PATH` for git bash, MSYS, Cygwin; if none are found then download the [ports](#ports) below using:

  0. `curl` ([installed by default since 2019's Windows 10](https://techcommunity.microsoft.com/blog/containers/tar-and-curl-come-to-windows/382409))
  1. Fallback to PowerShell's `iwr`
  2. Fallback to `wget`
  3. Fallback to `certutil`
  4. Fallback to `bitsadmin`
  5. Fallback to `cscript` with a `ActiveXObject` (e.g., follow [this code](https://superuser.com/a/536400))
  6. Fail with error. E.g., on DOS recommend manual downloading of `curl` from http://mik.dyndns.pro/dos-stuff/

NOTE: `curl` and `tar` were first introduced in [2017](https://blogs.windows.com/windows-insider/2017/12/19/announcing-windows-10-insider-preview-build-17063-pc/]) to Microsoft Windows; so should be usually available.

## Ports

  - BSD-3-clause `bc` and `dc` implementation: https://git.gavinhoward.com/gavin/bc
  - Consider porting dash—the most popular `/bin/sh`—from http://gondor.apana.org.au/~herbert/dash to Windows
  - `envsubst` looks trivial to port to Windows (MSVC): https://github.com/nekopsykose/envsubst

There also seems to be a busybox port for Windows: https://frippery.org/busybox/release-notes/current.html
Worth investigating if this busybox can generate all the scripts.
Or maybe busybox + https://github.com/SamuelMarks/win-bin/releases/download/0th/envsubst.zip (from 2005's GnuWin32 project)
