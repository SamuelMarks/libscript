$ErrorActionPreference = "Continue"
$env:LIBSCRIPT_DEFAULT_INSTALL_METHOD="system"
& "C:\libscript\libscript.cmd" install mongodb
& "C:\libscript\libscript.cmd" install memcached
& "C:\libscript\libscript.cmd" install httpd
