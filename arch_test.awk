{
   url = $0
   if (match(url, /(amd64|arm64|x86_64|aarch64|386|armv7l|x64|arm32v7|arm32v6)/)) {
       arch_str = substr(url, RSTART, RLENGTH)
       gsub(arch_str, "${TARGETARCH}", url)
   }
   if (match(url, /(linux|darwin|windows)/)) {
       os_str = substr(url, RSTART, RLENGTH)
       gsub(os_str, "${TARGETOS}", url)
   }
   print url
}
