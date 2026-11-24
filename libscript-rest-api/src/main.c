/**
 * ## Overview
 * LibScript C11 REST API HTTP/1.1 daemon and CLI job dispatcher conforming to openapi.yaml (3.2.0).
 *
 * ## Usage
 *   libscript-rest-api [--port <port>] [--bind <addr>] [--max-requests <N>] [--port-file <path>]
 *   libscript-rest-api --dispatch <subcmd> <action> <target>
 *   libscript-rest-api --dispatch-experiment <suite> <step> <host_arch>
 *   libscript-rest-api --dispatch-artifact <kernel> <format> <components_csv> [board]
 */
#if !defined(_WIN32) && !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif

#include "rest_api.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#include <winsock2.h>
#include <ws2tcpip.h>
typedef SOCKET rest_sock_t;
typedef int rest_sock_io_len_t;
#define REST_INVALID_SOCK INVALID_SOCKET
#define rest_close_sock closesocket
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
typedef int rest_sock_t;
typedef size_t rest_sock_io_len_t;
#define REST_INVALID_SOCK (-1)
#define rest_close_sock close
#endif

/**
 * @brief Sends a complete HTTP/1.1 JSON response over a connected client socket.
 */
static void send_json_response(rest_sock_t client, int status_code, const char *status_text,
                               const char *json_body) {
    char resp[4096];
    size_t body_len = strlen(json_body);
    int n = snprintf(resp, sizeof(resp),
                     "HTTP/1.1 %d %s\r\n"
                     "Content-Type: application/json; charset=utf-8\r\n"
                     "Content-Length: %zu\r\n"
                     "Connection: close\r\n"
                     "\r\n"
                     "%s",
                     status_code, status_text, body_len, json_body);
    if (n > 0) {
        size_t total = (size_t)n < sizeof(resp) ? (size_t)n : sizeof(resp) - 1u;
        (void)send(client, resp, (rest_sock_io_len_t)total, 0);
    }
}

/**
 * @brief Handles a single HTTP/1.1 request and writes an OpenAPI-compliant JSON response.
 */
static void handle_http_client(rest_sock_t client, const char *root_dir) {
    char req[8192];
    char method[16];
    char path[512];
    char json_out[2048];
    const char *body = "";
    const char *hdr_end;
    int recvd = (int)recv(client, req, (rest_sock_io_len_t)(sizeof(req) - 1u), 0);
    if (recvd <= 0) {
        return;
    }
    req[recvd] = '\0';

    if (sscanf(req, "%15s %511s", method, path) != 2) {
        send_json_response(client, 400, "Bad Request",
                           "{\"error\":\"malformed_request\",\"message\":\"Invalid HTTP request line\"}");
        return;
    }

    hdr_end = strstr(req, "\r\n\r\n");
    if (hdr_end != NULL) {
        body = hdr_end + 4;
    }

    if (strcmp(method, "GET") == 0 && strcmp(path, "/api/v1/health") == 0) {
        send_json_response(client, 200, "OK",
                           "{\"status\":\"ok\",\"service\":\"libscript-rest-api\",\"openapi\":\"3.2.0\"}");
        return;
    }

    if (strcmp(method, "GET") == 0 && strncmp(path, "/api/v1/jobs/", 13) == 0) {
        const char *job_id = path + 13;
        if (rest_query_job(job_id, json_out, sizeof(json_out)) == 0) {
            send_json_response(client, 200, "OK", json_out);
        } else {
            send_json_response(client, 404, "Not Found",
                               "{\"error\":\"job_not_found\",\"message\":\"Unknown job_id\"}");
        }
        return;
    }

    if (strcmp(method, "GET") == 0 &&
        (strcmp(path, "/v1/package-as") == 0 || strcmp(path, "/api/v1/package-as") == 0)) {
        (void)rest_list_package_as_targets(json_out, sizeof(json_out));
        send_json_response(client, 200, "OK", json_out);
        return;
    }

    if (strcmp(method, "POST") == 0 &&
        (strcmp(path, "/v1/package-as") == 0 || strcmp(path, "/api/v1/package-as") == 0)) {
        char target[128], profile[256], fmt[64], output_path[512];
        const char *prof_ptr = NULL;
        const char *fmt_ptr = NULL;
        const char *out_ptr = NULL;
        if (rest_json_get_string(body, "target", target, sizeof(target)) != 0) {
            send_json_response(client, 400, "Bad Request",
                               "{\"error\":\"missing_fields\",\"message\":\"target required\"}");
            return;
        }
        if (rest_json_get_string(body, "profile", profile, sizeof(profile)) == 0 && profile[0] != '\0') {
            prof_ptr = profile;
        }
        if (rest_json_get_string(body, "format", fmt, sizeof(fmt)) == 0 && fmt[0] != '\0') {
            fmt_ptr = fmt;
        }
        if (rest_json_get_string(body, "output", output_path, sizeof(output_path)) == 0 && output_path[0] != '\0') {
            out_ptr = output_path;
        }
        if (rest_dispatch_package_as(root_dir, target, prof_ptr, fmt_ptr, out_ptr, 0, json_out, sizeof(json_out)) == 0) {
            send_json_response(client, 202, "Accepted", json_out);
        } else {
            send_json_response(client, 400, "Bad Request", json_out);
        }
        return;
    }

    if (strcmp(method, "GET") == 0 &&
        (strcmp(path, "/v1/experiments") == 0 || strcmp(path, "/api/v1/experiments") == 0)) {
        (void)rest_list_experiments(root_dir, json_out, sizeof(json_out));
        send_json_response(client, 200, "OK", json_out);
        return;
    }

    if (strcmp(method, "POST") == 0 && strcmp(path, "/api/v1/marketplace/publish") == 0) {
        char offer[256], clouds[128];
        const char *clouds_ptr = NULL;
        if (rest_json_get_string(body, "offer", offer, sizeof(offer)) != 0) {
            send_json_response(client, 400, "Bad Request",
                               "{\"error\":\"missing_fields\",\"message\":\"offer required\"}");
            return;
        }
        if (rest_json_get_string(body, "clouds", clouds, sizeof(clouds)) == 0 && clouds[0] != '\0') {
            clouds_ptr = clouds;
        }
        if (rest_dispatch_marketplace_publish(root_dir, offer, clouds_ptr, 0, json_out, sizeof(json_out)) == 0) {
            send_json_response(client, 202, "Accepted", json_out);
        } else {
            send_json_response(client, 400, "Bad Request", json_out);
        }
        return;
    }

    if (strcmp(method, "GET") == 0 &&
        (strncmp(path, "/v1/recipes/", 12) == 0 || strncmp(path, "/api/v1/components/", 19) == 0)) {
        const char *rest = (strncmp(path, "/v1/recipes/", 12) == 0) ? (path + 12) : (path + 19);
        const char *cap_sfx = strstr(rest, "/capabilities");
        if (cap_sfx != NULL && strcmp(cap_sfx, "/capabilities") == 0) {
            char cname[128];
            size_t clen = (size_t)(cap_sfx - rest);
            if (clen > 0u && clen < sizeof(cname)) {
                memcpy(cname, rest, clen);
                cname[clen] = '\0';
                if (rest_query_component_capabilities(root_dir, cname, json_out, sizeof(json_out)) == 0) {
                    send_json_response(client, 200, "OK", json_out);
                    return;
                }
            }
            send_json_response(client, 404, "Not Found",
                               "{\"error\":\"component_not_found\",\"message\":\"Unknown component\"}");
            return;
        }
    }

    if (strcmp(method, "POST") == 0 &&
        (strcmp(path, "/v1/experiments") == 0 || strcmp(path, "/api/v1/experiments") == 0)) {
        char suite[64], step[64], host_arch[64];
        if (rest_json_get_string(body, "suite", suite, sizeof(suite)) != 0 ||
            rest_json_get_string(body, "step", step, sizeof(step)) != 0 ||
            rest_json_get_string(body, "host_arch", host_arch, sizeof(host_arch)) != 0) {
            send_json_response(client, 400, "Bad Request",
                               "{\"error\":\"missing_fields\",\"message\":\"suite, step, and host_arch required\"}");
            return;
        }
        if (rest_dispatch_experiment(root_dir, suite, step, host_arch, 0, json_out, sizeof(json_out)) == 0) {
            send_json_response(client, 202, "Accepted", json_out);
        } else {
            send_json_response(client, 400, "Bad Request", json_out);
        }
        return;
    }

    if (strcmp(method, "POST") == 0 &&
        (strcmp(path, "/v1/synthesis") == 0 || strcmp(path, "/api/v1/artifacts/generate") == 0)) {
        char kernel[64], fmt[64], comps[256], board[64];
        const char *board_ptr = NULL;
        if (rest_json_get_string(body, "kernel", kernel, sizeof(kernel)) != 0 ||
            rest_json_get_string(body, "format", fmt, sizeof(fmt)) != 0 ||
            rest_json_get_string(body, "components", comps, sizeof(comps)) != 0) {
            send_json_response(client, 400, "Bad Request",
                               "{\"error\":\"missing_fields\",\"message\":\"kernel, format, and components required\"}");
            return;
        }
        if (rest_json_get_string(body, "board", board, sizeof(board)) == 0 && board[0] != '\0') {
            board_ptr = board;
        }
        if (rest_dispatch_artifact(root_dir, kernel, fmt, comps, board_ptr, 0, json_out, sizeof(json_out)) == 0) {
            send_json_response(client, 202, "Accepted", json_out);
        } else {
            send_json_response(client, 400, "Bad Request", json_out);
        }
        return;
    }

    if (strcmp(method, "POST") == 0 &&
        (strcmp(path, "/v1/recipes") == 0 ||
         strcmp(path, "/v1/infrastructure") == 0 ||
         strcmp(path, "/v1/workloads") == 0 ||
         strcmp(path, "/v1/traits") == 0 ||
         strcmp(path, "/api/v1/infrastructure") == 0 ||
         strcmp(path, "/api/v1/workloads") == 0 ||
         strcmp(path, "/api/v1/traits") == 0)) {
        char action[64], target[256];
        const char *subcmd = "workload";
        if (strcmp(path, "/v1/recipes") == 0) {
            subcmd = "install";
        } else if (strcmp(path, "/v1/infrastructure") == 0 || strcmp(path, "/api/v1/infrastructure") == 0) {
            subcmd = "infrastructure";
        } else if (strcmp(path, "/v1/traits") == 0 || strcmp(path, "/api/v1/traits") == 0) {
            subcmd = "trait";
        }
        if (rest_json_get_string(body, "action", action, sizeof(action)) != 0 ||
            rest_json_get_string(body, "target", target, sizeof(target)) != 0) {
            send_json_response(client, 400, "Bad Request",
                               "{\"error\":\"missing_fields\",\"message\":\"action and target required\"}");
            return;
        }
        if (strcmp(path, "/v1/recipes") == 0) {
            subcmd = action;
        }
        if (rest_dispatch_job(root_dir, subcmd, action, target, 0, json_out, sizeof(json_out)) == 0) {
            send_json_response(client, 202, "Accepted", json_out);
        } else {
            send_json_response(client, 400, "Bad Request", json_out);
        }
        return;
    }

    if (strcmp(method, "POST") == 0 && strncmp(path, "/api/v1/components/", 19) == 0) {
        const char *rest = path + 19;
        const char *hooks_sep = strstr(rest, "/hooks/");
        char comp_name[128];
        char hook_name[128];
        size_t comp_len;
        if (hooks_sep == NULL) {
            send_json_response(client, 404, "Not Found",
                               "{\"error\":\"not_found\",\"message\":\"Expected /api/v1/components/{name}/hooks/{hook}\"}");
            return;
        }
        comp_len = (size_t)(hooks_sep - rest);
        if (comp_len == 0 || comp_len >= sizeof(comp_name)) {
            send_json_response(client, 400, "Bad Request",
                               "{\"error\":\"invalid_component\",\"message\":\"Invalid component identifier\"}");
            return;
        }
        memcpy(comp_name, rest, comp_len);
        comp_name[comp_len] = '\0';
        snprintf(hook_name, sizeof(hook_name), "%s", hooks_sep + 7);
        if (!rest_is_safe_segment(comp_name) || !rest_is_safe_segment(hook_name)) {
            send_json_response(client, 400, "Bad Request",
                               "{\"error\":\"invalid_token\",\"message\":\"Unsafe component or hook segment rejected\"}");
            return;
        }
        if (rest_dispatch_job(root_dir, hook_name, hook_name, comp_name, 0, json_out, sizeof(json_out)) == 0) {
            send_json_response(client, 202, "Accepted", json_out);
        } else {
            send_json_response(client, 400, "Bad Request", json_out);
        }
        return;
    }

    send_json_response(client, 404, "Not Found",
                       "{\"error\":\"not_found\",\"message\":\"Unknown API endpoint\"}");
}

/**
 * @brief Runs the blocking C11 HTTP/1.1 TCP listener loop.
 */
static int serve_http_loop(const char *bind_ip, int port, int max_requests,
                           const char *port_file, const char *root_dir) {
    rest_sock_t srv;
    struct sockaddr_in addr;
    int opt = 1;
    int handled = 0;

#if defined(_WIN32)
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        fprintf(stderr, "{\"error\":\"winsock_init_failed\"}\n");
        return 1;
    }
#endif

    srv = socket(AF_INET, SOCK_STREAM, 0);
    if (srv == REST_INVALID_SOCK) {
        fprintf(stderr, "{\"error\":\"socket_failed\"}\n");
        return 1;
    }
    (void)setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, (const char *)&opt, (socklen_t)sizeof(opt));

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    if (inet_pton(AF_INET, bind_ip, &addr.sin_addr) != 1) {
        addr.sin_addr.s_addr = htonl(0x7f000001u);
    }

    if (bind(srv, (struct sockaddr *)&addr, (socklen_t)sizeof(addr)) != 0) {
        fprintf(stderr, "{\"error\":\"bind_failed\",\"port\":%d}\n", port);
        rest_close_sock(srv);
        return 1;
    }
    if (listen(srv, 16) != 0) {
        fprintf(stderr, "{\"error\":\"listen_failed\"}\n");
        rest_close_sock(srv);
        return 1;
    }

    {
        struct sockaddr_in bound_addr;
        socklen_t blen = (socklen_t)sizeof(bound_addr);
        if (getsockname(srv, (struct sockaddr *)&bound_addr, &blen) == 0) {
            port = (int)ntohs(bound_addr.sin_port);
        }
    }

    if (port_file != NULL && port_file[0] != '\0') {
        FILE *pf = fopen(port_file, "wb");
        if (pf != NULL) {
            fprintf(pf, "%d\n", port);
            fclose(pf);
        }
    }

    printf("{\"event\":\"listening\",\"bind\":\"%s\",\"port\":%d}\n", bind_ip, port);
    fflush(stdout);

    while (max_requests <= 0 || handled < max_requests) {
        rest_sock_t client = accept(srv, NULL, NULL);
        if (client == REST_INVALID_SOCK) {
            continue;
        }
        handle_http_client(client, root_dir);
        rest_close_sock(client);
        handled++;
    }

    rest_close_sock(srv);
#if defined(_WIN32)
    WSACleanup();
#endif
    return 0;
}

/**
 * @brief Main entry point for libscript-rest-api.
 */
int main(int argc, char **argv) {
    char root_dir[1024];
    char json_out[2048];
    const char *bind_ip = "127.0.0.1";
    const char *port_file = NULL;
    int port = 8080;
    int max_requests = 0;
    int i;

    (void)rest_resolve_root_dir((argc > 0) ? argv[0] : NULL, root_dir, sizeof(root_dir));

    if (argc >= 5 && strcmp(argv[1], "--dispatch") == 0) {
        int rc = rest_dispatch_job(root_dir, argv[2], argv[3], argv[4], 1, json_out, sizeof(json_out));
        fprintf(rc == 0 ? stdout : stderr, "%s\n", json_out);
        return rc;
    }
    if (argc >= 5 && strcmp(argv[1], "--dispatch-experiment") == 0) {
        int rc = rest_dispatch_experiment(root_dir, argv[2], argv[3], argv[4], 1, json_out, sizeof(json_out));
        fprintf(rc == 0 ? stdout : stderr, "%s\n", json_out);
        return rc;
    }
    if (argc >= 3 && strcmp(argv[1], "--dispatch-package-as") == 0) {
        int rc = rest_dispatch_package_as(root_dir, argv[2],
                                          (argc >= 4) ? argv[3] : NULL,
                                          (argc >= 5) ? argv[4] : NULL,
                                          (argc >= 6) ? argv[5] : NULL,
                                          1, json_out, sizeof(json_out));
        fprintf(rc == 0 ? stdout : stderr, "%s\n", json_out);
        return rc;
    }
    if (argc >= 5 && strcmp(argv[1], "--dispatch-artifact") == 0) {
        int rc = rest_dispatch_artifact(root_dir, argv[2], argv[3], argv[4],
                                        (argc >= 6) ? argv[5] : NULL, 1, json_out, sizeof(json_out));
        fprintf(rc == 0 ? stdout : stderr, "%s\n", json_out);
        return rc;
    }

    for (i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--port") == 0 && i + 1 < argc) {
            port = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--bind") == 0 && i + 1 < argc) {
            bind_ip = argv[++i];
        } else if (strcmp(argv[i], "--max-requests") == 0 && i + 1 < argc) {
            max_requests = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--port-file") == 0 && i + 1 < argc) {
            port_file = argv[++i];
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            printf("Usage: libscript-rest-api [--port <port>] [--bind <ip>] [--max-requests <N>] [--port-file <path>]\n");
            return 0;
        } else if (argv[i][0] >= '0' && argv[i][0] <= '9') {
            port = atoi(argv[i]);
        }
    }

    return serve_http_loop(bind_ip, port, max_requests, port_file, root_dir);
}
