BEGIN { in_vars = 0; in_platforms = 0; }
/<!-- BEGIN_VARS -->/ {
    print
    while ((getline line < ARGV[2]) > 0)
        print line
    in_vars = 1
    next
}
/<!-- END_VARS -->/ {
    in_vars = 0
    print
    next
}
/<!-- BEGIN_PLATFORMS -->/ {
    print
    while ((getline line < ARGV[3]) > 0)
        print line
    in_platforms = 1
    next
}
/<!-- END_PLATFORMS -->/ {
    in_platforms = 0
    print
    next
}
!in_vars && !in_platforms { print }
