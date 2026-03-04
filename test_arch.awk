BEGIN {
  url = "https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64"
  if (match(url, /(amd64|arm64|x86_64|aarch64|386|armv7l)/)) {
    arch_str = substr(url, RSTART, RLENGTH)
    gsub(arch_str, "${TARGETARCH}", url)
    print "Found arch: " arch_str
  }
  print url
}
