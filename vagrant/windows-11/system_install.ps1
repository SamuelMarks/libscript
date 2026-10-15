# ## Overview
# Performs a system-wide installation of MongoDB, Memcached, and HTTPD.
#
# ## Usage
# .\system_install.ps1

$ErrorActionPreference = "Continue"
$env:LIBSCRIPT_DEFAULT_INSTALL_METHOD="system"
& "C:\libscript\libscript.cmd" install mongodb
& "C:\libscript\libscript.cmd" install memcached
& "C:\libscript\libscript.cmd" install httpd
