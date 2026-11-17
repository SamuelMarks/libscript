/*
 * ## Overview
 * Zero-PowerShell Win32 C89 detached daemon launcher (`ls-daemon.exe`) for LibScript.
 * Spawns background daemons via CreateProcessW with
 * DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP | CREATE_NO_WINDOW, writes child PID
 * files directly, and provides an optional loopback TCP/HTTP health listener.
 * Includes a POSIX C89 fallback path for cross-platform compilation and unit testing.
 *
 * ## Usage
 * ls-daemon [-Port <port>] [-Executable <path>] [-DataDir <dir>] [-HttpJson <json>]
 */

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <winsock2.h>
#include <windows.h>
#ifdef _MSC_VER
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "ws2_32.lib")
#endif
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int parse_port_val(const char *s) {
    long v;
    char *endp = NULL;
    if (s == NULL || *s == '\0') {
        return 0;
    }
    v = strtol(s, &endp, 10);
    if (endp == s || v <= 0 || v > 65535) {
        return 0;
    }
    return (int)v;
}

static int str_eq_ci(const char *a, const char *b) {
    unsigned char ca;
    unsigned char cb;
    while (*a != '\0' && *b != '\0') {
        ca = (unsigned char)*a;
        cb = (unsigned char)*b;
        if (ca >= 'A' && ca <= 'Z') {
            ca = (unsigned char)(ca + ('a' - 'A'));
        }
        if (cb >= 'A' && cb <= 'Z') {
            cb = (unsigned char)(cb + ('a' - 'A'));
        }
        if (ca != cb) {
            return 0;
        }
        a++;
        b++;
    }
    return (*a == '\0' && *b == '\0') ? 1 : 0;
}

static void write_pid_file(const char *data_dir, int port, unsigned long pid) {
    char pid_path[1024];
    FILE *fp;
    if (data_dir == NULL || data_dir[0] == '\0') {
        return;
    }
    if (port > 0) {
        sprintf(pid_path, "%s/port_%d.pid", data_dir, port);
    } else {
        sprintf(pid_path, "%s/daemon.pid", data_dir);
    }
    fp = fopen(pid_path, "wb");
    if (fp != NULL) {
        fprintf(fp, "%lu\n", pid);
        fclose(fp);
    }
}

#ifdef _WIN32

static void ensure_dir_win32(const char *dir_utf8) {
    wchar_t wdir[MAX_PATH];
    int i;
    int len;
    if (dir_utf8 == NULL || dir_utf8[0] == '\0') {
        return;
    }
    len = MultiByteToWideChar(CP_UTF8, 0, dir_utf8, -1, wdir, MAX_PATH);
    if (len <= 0) {
        return;
    }
    for (i = 0; wdir[i] != L'\0'; i++) {
        if (wdir[i] == L'/') {
            wdir[i] = L'\\';
        }
        if (i > 2 && wdir[i] == L'\\') {
            wdir[i] = L'\0';
            CreateDirectoryW(wdir, NULL);
            wdir[i] = L'\\';
        }
    }
    CreateDirectoryW(wdir, NULL);
}

static int is_port_open_win32(int port) {
    WSADATA wsa;
    SOCKET s;
    struct sockaddr_in addr;
    int rc;
    if (port <= 0) {
        return 0;
    }
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        return 0;
    }
    s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (s == INVALID_SOCKET) {
        WSACleanup();
        return 0;
    }
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    rc = (connect(s, (struct sockaddr *)&addr, (int)sizeof(addr)) == 0) ? 1 : 0;
    closesocket(s);
    WSACleanup();
    return rc;
}

static int serve_loopback_win32(int port, const char *http_json) {
    WSADATA wsa;
    SOCKET srv;
    struct sockaddr_in addr;
    int opt = 1;
    if (port <= 0) {
        return 1;
    }
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        return 1;
    }
    srv = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (srv == INVALID_SOCKET) {
        WSACleanup();
        return 1;
    }
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, (const char *)&opt, (int)sizeof(opt));
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    if (bind(srv, (struct sockaddr *)&addr, (int)sizeof(addr)) != 0) {
        closesocket(srv);
        WSACleanup();
        return 1;
    }
    if (listen(srv, 16) != 0) {
        closesocket(srv);
        WSACleanup();
        return 1;
    }
    for (;;) {
        SOCKET cli = accept(srv, NULL, NULL);
        if (cli == INVALID_SOCKET) {
            Sleep(50);
            continue;
        }
        if (http_json != NULL && http_json[0] != '\0') {
            char hdr[512];
            char sink[256];
            size_t body_len = strlen(http_json);
            int hdr_len;
            recv(cli, sink, (int)sizeof(sink), 0);
            hdr_len = sprintf(
                hdr,
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %lu\r\nConnection: close\r\n\r\n",
                (unsigned long)body_len
            );
            if (hdr_len > 0) {
                send(cli, hdr, hdr_len, 0);
            }
            send(cli, http_json, (int)body_len, 0);
        }
        closesocket(cli);
    }
}

static int spawn_detached_win32(const wchar_t *cmdline_in, const wchar_t *work_dir, unsigned long *out_pid) {
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    wchar_t cmd_buf[4096];
    DWORD flags = DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP | CREATE_NO_WINDOW;
    size_t n = wcslen(cmdline_in);
    if (n >= 4095) {
        return 1;
    }
    memcpy(cmd_buf, cmdline_in, (n + 1) * sizeof(wchar_t));
    memset(&si, 0, sizeof(si));
    si.cb = (DWORD)sizeof(si);
    memset(&pi, 0, sizeof(pi));
    if (!CreateProcessW(NULL, cmd_buf, NULL, NULL, FALSE, flags, NULL, work_dir, &si, &pi)) {
        return 1;
    }
    if (out_pid != NULL) {
        *out_pid = (unsigned long)pi.dwProcessId;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
}

#else

static void ensure_dir_posix(const char *dir_path) {
    char buf[1024];
    size_t i;
    size_t len;
    if (dir_path == NULL || dir_path[0] == '\0') {
        return;
    }
    len = strlen(dir_path);
    if (len >= sizeof(buf)) {
        return;
    }
    memcpy(buf, dir_path, len + 1);
    for (i = 1; i < len; i++) {
        if (buf[i] == '/') {
            buf[i] = '\0';
            mkdir(buf, 0755);
            buf[i] = '/';
        }
    }
    mkdir(buf, 0755);
}

static int is_port_open_posix(int port) {
    int s;
    struct sockaddr_in addr;
    int rc;
    if (port <= 0) {
        return 0;
    }
    s = socket(AF_INET, SOCK_STREAM, 0);
    if (s < 0) {
        return 0;
    }
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    rc = (connect(s, (struct sockaddr *)&addr, (socklen_t)sizeof(addr)) == 0) ? 1 : 0;
    close(s);
    return rc;
}

static int serve_loopback_posix(int port, const char *http_json) {
    int srv;
    struct sockaddr_in addr;
    int opt = 1;
    srv = socket(AF_INET, SOCK_STREAM, 0);
    if (srv < 0) {
        return 1;
    }
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &opt, (socklen_t)sizeof(opt));
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    if (bind(srv, (struct sockaddr *)&addr, (socklen_t)sizeof(addr)) != 0) {
        close(srv);
        return 1;
    }
    if (listen(srv, 16) != 0) {
        close(srv);
        return 1;
    }
    for (;;) {
        int cli = accept(srv, NULL, NULL);
        if (cli < 0) {
            continue;
        }
        if (http_json != NULL && http_json[0] != '\0') {
            char hdr[512];
            char sink[256];
            size_t body_len = strlen(http_json);
            int hdr_len;
            if (read(cli, sink, sizeof(sink)) < 0) {
                /* ignore request body read errors */
            }
            hdr_len = sprintf(
                hdr,
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %lu\r\nConnection: close\r\n\r\n",
                (unsigned long)body_len
            );
            if (hdr_len > 0 && write(cli, hdr, (size_t)hdr_len) < 0) {
                /* ignore write error */
            }
            if (write(cli, http_json, body_len) < 0) {
                /* ignore write error */
            }
        }
        close(cli);
    }
}

#endif

int main(int argc, char **argv) {
    int port = 0;
    const char *executable = "";
    const char *data_dir = "";
    const char *http_json = "";
    int serve_mode = 0;
    char default_dir[1024];
    int i;

    for (i = 1; i < argc; i++) {
        if ((str_eq_ci(argv[i], "-Port") || str_eq_ci(argv[i], "--port")) && i + 1 < argc) {
            port = parse_port_val(argv[++i]);
        } else if ((str_eq_ci(argv[i], "-Executable") || str_eq_ci(argv[i], "--executable")) && i + 1 < argc) {
            executable = argv[++i];
        } else if ((str_eq_ci(argv[i], "-DataDir") || str_eq_ci(argv[i], "--data-dir")) && i + 1 < argc) {
            data_dir = argv[++i];
        } else if ((str_eq_ci(argv[i], "-HttpJson") || str_eq_ci(argv[i], "--http-json")) && i + 1 < argc) {
            http_json = argv[++i];
        } else if (str_eq_ci(argv[i], "-ServeLoopback") || str_eq_ci(argv[i], "--serve-loopback")) {
            serve_mode = 1;
        }
    }

#ifdef _WIN32
    if (serve_mode) {
        return serve_loopback_win32(port, http_json);
    }
    if (port > 0 && is_port_open_win32(port)) {
        return 0;
    }
    if (data_dir[0] == '\0') {
        const char *up = getenv("USERPROFILE");
        if (up != NULL && up[0] != '\0') {
            sprintf(default_dir, "%s\\.libscript\\run", up);
            data_dir = default_dir;
        } else {
            data_dir = "C:\\LIBSCRIP\\RUN";
        }
    }
    ensure_dir_win32(data_dir);

    if (executable[0] != '\0') {
        wchar_t wexe[MAX_PATH];
        wchar_t wcmd[MAX_PATH + 8];
        wchar_t wwork[MAX_PATH];
        wchar_t *slash;
        DWORD attrs;
        unsigned long child_pid = 0;
        if (MultiByteToWideChar(CP_UTF8, 0, executable, -1, wexe, MAX_PATH) > 0) {
            attrs = GetFileAttributesW(wexe);
            if (attrs != INVALID_FILE_ATTRIBUTES && (attrs & FILE_ATTRIBUTE_DIRECTORY) == 0) {
                wcscpy(wcmd, L"\"");
                wcscat(wcmd, wexe);
                wcscat(wcmd, L"\"");
                wcscpy(wwork, wexe);
                slash = wcsrchr(wwork, L'\\');
                if (slash == NULL) {
                    slash = wcsrchr(wwork, L'/');
                }
                if (slash != NULL) {
                    *slash = L'\0';
                }
                if (spawn_detached_win32(wcmd, (slash != NULL) ? wwork : NULL, &child_pid) == 0) {
                    write_pid_file(data_dir, port, child_pid);
                    Sleep(1000);
                    if (port <= 0 || is_port_open_win32(port)) {
                        return 0;
                    }
                }
            }
        }
    }

    if (port > 0) {
        wchar_t self_path[MAX_PATH];
        wchar_t wjson[2048];
        wchar_t wcmd[3072];
        unsigned long child_pid = 0;
        if (GetModuleFileNameW(NULL, self_path, MAX_PATH) > 0) {
            if (http_json[0] != '\0' && MultiByteToWideChar(CP_UTF8, 0, http_json, -1, wjson, 2048) > 0) {
                wsprintfW(wcmd, L"\"%s\" -ServeLoopback -Port %d -HttpJson \"%s\"", self_path, port, wjson);
            } else {
                wsprintfW(wcmd, L"\"%s\" -ServeLoopback -Port %d", self_path, port);
            }
            if (spawn_detached_win32(wcmd, NULL, &child_pid) == 0) {
                write_pid_file(data_dir, port, child_pid);
                Sleep(500);
                return 0;
            }
        }
    }
    return 0;
#else
    if (serve_mode) {
        return serve_loopback_posix(port, http_json);
    }
    if (port > 0 && is_port_open_posix(port)) {
        return 0;
    }
    if (data_dir[0] == '\0') {
        const char *hm = getenv("HOME");
        sprintf(default_dir, "%s/.libscript/run", (hm != NULL && hm[0] != '\0') ? hm : "/tmp");
        data_dir = default_dir;
    }
    ensure_dir_posix(data_dir);

    if (executable[0] != '\0' && access(executable, X_OK) == 0) {
        pid_t pid = fork();
        if (pid == 0) {
            setsid();
            execl(executable, executable, (char *)NULL);
            _exit(127);
        }
        if (pid > 0) {
            write_pid_file(data_dir, port, (unsigned long)pid);
            return 0;
        }
    }
    if (port > 0) {
        pid_t pid = fork();
        if (pid == 0) {
            setsid();
            _exit(serve_loopback_posix(port, http_json));
        }
        if (pid > 0) {
            write_pid_file(data_dir, port, (unsigned long)pid);
            usleep(200000);
            return 0;
        }
    }
    return 0;
#endif
}
