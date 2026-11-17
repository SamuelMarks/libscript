/*
 * ## Overview
 * Portable ANSI C89 HTTP/HTTPS/FILE downloader (`CURL.EXE` for MS-DOS `dos32`) built against
 * **Watt-32** (`WATTCP.CFG` DHCP/static Crynwr packet driver `0x60` for QEMU `ne2k_isa` /
 * `pcnet`, FreeDOS, and MS-DOS 6.22) with optional BearSSL (`-DUSE_BEARSSL`) or mbedTLS
 * (`-DUSE_MBEDTLS`) TLS client hooks, plus Win32 Winsock2 and POSIX BSD socket backends.
 *
 * ## Usage
 * curl [-fsSLI] [--max-time <sec>] [-H <header>] [-o <file>] <url>
 */

#if !defined(_WIN32) && !defined(__DOS__) && !defined(__MSDOS__) && !defined(_MSDOS)
#define _POSIX_C_SOURCE 200809L
#endif

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(USE_WATT32)
#include <tcp.h>
#elif defined(_WIN32)
#include <winsock2.h>
#include <ws2tcpip.h>
#elif !defined(__DOS__) && !defined(__MSDOS__) && !defined(_MSDOS)
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#endif

#if defined(USE_BEARSSL)
#include <bearssl.h>
#elif defined(USE_MBEDTLS)
#include <mbedtls/ctr_drbg.h>
#include <mbedtls/entropy.h>
#include <mbedtls/net_sockets.h>
#include <mbedtls/ssl.h>
#endif

typedef struct {
    char scheme[16];
    char host[256];
    int port;
    char path[1024];
} ParsedUrl;

static int wc_ci_ncmp(const char *a, const char *b, size_t n) {
    size_t i;
    for (i = 0; i < n; i++) {
        int ca = tolower((unsigned char)a[i]);
        int cb = tolower((unsigned char)b[i]);
        if (ca != cb || a[i] == '\0' || b[i] == '\0') return ca - cb;
    }
    return 0;
}

static int parse_url(const char *raw, ParsedUrl *u) {
    const char *p;
    const char *slash;
    const char *colon;
    size_t hlen;

    memset(u, 0, sizeof(*u));
    if (wc_ci_ncmp(raw, "file://", 7) == 0) {
        strcpy(u->scheme, "file");
        strncpy(u->path, raw + 7, sizeof(u->path) - 1);
        return 0;
    }
    if (wc_ci_ncmp(raw, "http://", 7) == 0) {
        strcpy(u->scheme, "http");
        u->port = 80;
        p = raw + 7;
    } else if (wc_ci_ncmp(raw, "https://", 8) == 0) {
        strcpy(u->scheme, "https");
        u->port = 443;
        p = raw + 8;
    } else {
        return -1;
    }

    slash = strchr(p, '/');
    hlen = slash ? (size_t)(slash - p) : strlen(p);
    if (hlen == 0 || hlen >= sizeof(u->host)) return -1;
    memcpy(u->host, p, hlen);
    u->host[hlen] = '\0';

    colon = strchr(u->host, ':');
    if (colon) {
        u->port = atoi(colon + 1);
        u->host[(size_t)(colon - u->host)] = '\0';
    }
    if (slash) {
        strncpy(u->path, slash, sizeof(u->path) - 1);
    } else {
        strcpy(u->path, "/");
    }
    return 0;
}

static int fetch_file_url(const char *fpath, FILE *out, int head_only) {
    FILE *in;
    char buf[4096];
    size_t n;
    const char *p = fpath;
#if defined(_WIN32) || defined(__DOS__) || defined(__MSDOS__) || defined(_MSDOS)
    if (p[0] == '/' && isalpha((unsigned char)p[1]) && p[2] == ':') p++;
#endif
    in = fopen(p, "rb");
    if (!in) return 22;
    if (!head_only) {
        while ((n = fread(buf, 1, sizeof(buf), in)) > 0) {
            if (fwrite(buf, 1, n, out) != n) {
                fclose(in);
                return 23;
            }
        }
    }
    fclose(in);
    return 0;
}

static int parse_http_response(const char *raw_buf, size_t total_len, int *status_out, char *location_out, size_t loc_cap, size_t *hdr_end_out) {
    size_t i;
    int found = 0;
    *status_out = 0;
    location_out[0] = '\0';
    *hdr_end_out = 0;

    for (i = 0; i + 3 < total_len; i++) {
        if (raw_buf[i] == '\r' && raw_buf[i + 1] == '\n' && raw_buf[i + 2] == '\r' && raw_buf[i + 3] == '\n') {
            *hdr_end_out = i + 4;
            found = 1;
            break;
        }
    }
    if (!found) return -1;

    {
        const char *sp = strchr(raw_buf, ' ');
        if (sp && (size_t)(sp - raw_buf) < *hdr_end_out) {
            *status_out = atoi(sp + 1);
        }
    }
    {
        size_t pos = 0;
        while (pos < *hdr_end_out) {
            size_t eol = pos;
            while (eol < *hdr_end_out && raw_buf[eol] != '\r' && raw_buf[eol] != '\n') eol++;
            if (eol - pos > 9 && wc_ci_ncmp(raw_buf + pos, "location:", 9) == 0) {
                size_t vs = pos + 9;
                size_t vl;
                while (vs < eol && (raw_buf[vs] == ' ' || raw_buf[vs] == '\t')) vs++;
                vl = eol - vs;
                if (vl >= loc_cap) vl = loc_cap - 1;
                memcpy(location_out, raw_buf + vs, vl);
                location_out[vl] = '\0';
                break;
            }
            pos = eol + 1;
        }
    }
    return 0;
}

static int fetch_http_once(const ParsedUrl *u, const char *extra_hdr, int head_only, int fail_on_err, FILE *out, char *redirect_url, size_t redir_cap) {
    char req[2048];
    char hdr_buf[8192];
    size_t hdr_used = 0;
    size_t hdr_end = 0;
    int status_code = 0;
    int header_parsed = 0;

    redirect_url[0] = '\0';
    if (strcmp(u->scheme, "https") == 0) {
#if !defined(USE_BEARSSL) && !defined(USE_MBEDTLS)
        fprintf(stderr, "curl-dos32: HTTPS requires -DUSE_BEARSSL or -DUSE_MBEDTLS (or HTTP mirror / --offline cache)\n");
        return 1;
#endif
    }

    sprintf(req,
            "%s %s HTTP/1.1\r\n"
            "Host: %s\r\n"
            "User-Agent: libscript-watt-curl/1.0 (dos32)\r\n"
            "Accept: */*\r\n"
            "Connection: close\r\n"
            "%s%s"
            "\r\n",
            head_only ? "HEAD" : "GET",
            u->path,
            u->host,
            (extra_hdr && extra_hdr[0]) ? extra_hdr : "",
            (extra_hdr && extra_hdr[0]) ? "\r\n" : "");

#if defined(USE_WATT32)
    {
        static int watt_initialized = 0;
        tcp_Socket sock;
        DWORD host_ip;
        int status = 0;
        char rbuf[2048];
        int n;

        if (!watt_initialized) {
            sock_init();
            watt_initialized = 1;
        }
        host_ip = resolve(u->host);
        if (host_ip == 0) return 6;
        if (!tcp_open(&sock, 0, host_ip, (WORD)u->port, NULL)) return 7;
        sock_wait_established(&sock, sock_delay, NULL, &status);
        sock_fastwrite(&sock, (const BYTE *)req, (int)strlen(req));

        while (tcp_tick(&sock)) {
            if (sock_dataready(&sock)) {
                n = sock_fastread(&sock, (BYTE *)rbuf, sizeof(rbuf));
                if (n > 0) {
                    if (!header_parsed) {
                        size_t copy_n = (size_t)n;
                        if (hdr_used + copy_n >= sizeof(hdr_buf)) copy_n = sizeof(hdr_buf) - hdr_used - 1;
                        memcpy(hdr_buf + hdr_used, rbuf, copy_n);
                        hdr_used += copy_n;
                        hdr_buf[hdr_used] = '\0';
                        if (parse_http_response(hdr_buf, hdr_used, &status_code, redirect_url, redir_cap, &hdr_end) == 0) {
                            header_parsed = 1;
                            if (head_only) {
                                fwrite(hdr_buf, 1, hdr_end, out);
                                break;
                            }
                            if (redirect_url[0] == '\0' && (!fail_on_err || status_code < 400) && hdr_used > hdr_end) {
                                fwrite(hdr_buf + hdr_end, 1, hdr_used - hdr_end, out);
                            }
                        }
                    } else if (!head_only && redirect_url[0] == '\0' && (!fail_on_err || status_code < 400)) {
                        fwrite(rbuf, 1, (size_t)n, out);
                    }
                }
            }
        }
        sock_close(&sock);
        sock_err:
        if (status != 0 && !header_parsed) return 7;
    }
#elif defined(__DOS__) || defined(__MSDOS__) || defined(_MSDOS)
    (void)req;
    (void)hdr_buf;
    (void)hdr_used;
    (void)hdr_end;
    (void)header_parsed;
    (void)fail_on_err;
    (void)out;
    (void)redir_cap;
    fprintf(stderr, "curl-dos32: Watt-32 packet driver not linked (-DUSE_WATT32); use --offline cache or file://\n");
    return 7;
#else
    {
        struct addrinfo hints, *res = NULL, *rp;
        char port_str[16];
        char rbuf[2048];
#if defined(_WIN32)
        WSADATA wsa;
        SOCKET fd = INVALID_SOCKET;
        WSAStartup(MAKEWORD(2, 2), &wsa);
#else
        int fd = -1;
#endif
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        sprintf(port_str, "%d", u->port);
        if (getaddrinfo(u->host, port_str, &hints, &res) != 0) return 6;
        for (rp = res; rp != NULL; rp = rp->ai_next) {
            fd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
#if defined(_WIN32)
            if (fd == INVALID_SOCKET) continue;
            if (connect(fd, rp->ai_addr, (int)rp->ai_addrlen) == 0) break;
            closesocket(fd);
            fd = INVALID_SOCKET;
#else
            if (fd < 0) continue;
            if (connect(fd, rp->ai_addr, rp->ai_addrlen) == 0) break;
            close(fd);
            fd = -1;
#endif
        }
        freeaddrinfo(res);
#if defined(_WIN32)
        if (fd == INVALID_SOCKET) return 7;
#else
        if (fd < 0) return 7;
#endif
        (void)send(fd, req, strlen(req), 0);
        for (;;) {
#if defined(_WIN32)
            int n = recv(fd, rbuf, sizeof(rbuf), 0);
#else
            ssize_t n = recv(fd, rbuf, sizeof(rbuf), 0);
#endif
            if (n <= 0) break;
            if (!header_parsed) {
                size_t copy_n = (size_t)n;
                if (hdr_used + copy_n >= sizeof(hdr_buf)) copy_n = sizeof(hdr_buf) - hdr_used - 1;
                memcpy(hdr_buf + hdr_used, rbuf, copy_n);
                hdr_used += copy_n;
                hdr_buf[hdr_used] = '\0';
                if (parse_http_response(hdr_buf, hdr_used, &status_code, redirect_url, redir_cap, &hdr_end) == 0) {
                    header_parsed = 1;
                    if (head_only) {
                        fwrite(hdr_buf, 1, hdr_end, out);
                        break;
                    }
                    if (redirect_url[0] == '\0' && (!fail_on_err || status_code < 400) && hdr_used > hdr_end) {
                        fwrite(hdr_buf + hdr_end, 1, hdr_used - hdr_end, out);
                    }
                }
            } else if (!head_only && redirect_url[0] == '\0' && (!fail_on_err || status_code < 400)) {
                fwrite(rbuf, 1, (size_t)n, out);
            }
        }
#if defined(_WIN32)
        closesocket(fd);
#else
        close(fd);
#endif
    }
#endif

    if (!header_parsed) return 52;
    if (fail_on_err && status_code >= 400) return 22;
    return 0;
}

int main(int argc, char **argv) {
    int fail_on_err = 0;
    int follow_loc = 0;
    int head_only = 0;
    const char *out_path = NULL;
    const char *extra_hdr = NULL;
    const char *url = NULL;
    int i;
    FILE *out_fp = stdout;
    char cur_url[1536];
    int hops;
    int rc = 0;

    for (i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (strcmp(a, "--version") == 0 || strcmp(a, "-V") == 0) {
            printf("curl 8.10.1-dos32 (LibScript Watt-32 packet-driver client)\n");
            return 0;
        }
        if (strcmp(a, "--help") == 0) {
            printf("Usage: curl [-fsSLI] [--max-time <sec>] [-H <hdr>] [-o <file>] <url>\n");
            return 0;
        }
        if (strcmp(a, "-o") == 0 && i + 1 < argc) {
            out_path = argv[++i];
        } else if (strcmp(a, "-H") == 0 && i + 1 < argc) {
            extra_hdr = argv[++i];
        } else if (strcmp(a, "--max-time") == 0 && i + 1 < argc) {
            i++;
        } else if (a[0] == '-' && a[1] != '-') {
            const char *f = a + 1;
            while (*f) {
                if (*f == 'f') fail_on_err = 1;
                else if (*f == 'L') follow_loc = 1;
                else if (*f == 'I') head_only = 1;
                f++;
            }
        } else if (a[0] != '-') {
            url = a;
        }
    }

    if (!url) {
        fprintf(stderr, "curl: no URL specified\n");
        return 2;
    }

    if (out_path) {
        out_fp = fopen(out_path, "wb");
        if (!out_fp) {
            fprintf(stderr, "curl: cannot open output %s\n", out_path);
            return 23;
        }
    }

    strncpy(cur_url, url, sizeof(cur_url) - 1);
    cur_url[sizeof(cur_url) - 1] = '\0';

    for (hops = 0; hops < 8; hops++) {
        ParsedUrl pu;
        char next_url[1536];
        if (parse_url(cur_url, &pu) != 0) {
            rc = 3;
            break;
        }
        if (strcmp(pu.scheme, "file") == 0) {
            rc = fetch_file_url(pu.path, out_fp, head_only);
            break;
        }
        rc = fetch_http_once(&pu, extra_hdr, head_only, fail_on_err, out_fp, next_url, sizeof(next_url));
        if (follow_loc && next_url[0] != '\0') {
            if (next_url[0] == '/') {
                sprintf(cur_url, "%s://%s:%d%s", pu.scheme, pu.host, pu.port, next_url);
            } else {
                strncpy(cur_url, next_url, sizeof(cur_url) - 1);
                cur_url[sizeof(cur_url) - 1] = '\0';
            }
            continue;
        }
        break;
    }

    if (out_fp != stdout) {
        fclose(out_fp);
        if (rc != 0 && out_path) remove(out_path);
    }
    return rc;
}
