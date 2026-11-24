/**
 * ## Overview
 * Core C11 implementation of token sanitization, CSPRNG UUIDv4 generation, RFC 8259 JSON
 * serialization, LIBSCRIPT_ROOT_DIR discovery, and non-blocking async job management.
 *
 * ## Usage
 * Compiled as part of the libscript-rest-api target via src/CMakeLists.txt.
 */
#if !defined(_WIN32) && !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif

#include "rest_api.h"

#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#include <windows.h>
#include <bcrypt.h>
#include <direct.h>
#else
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

#define MAX_TRACKED_JOBS 128

typedef struct {
    char job_id[37];
    char endpoint[64];
#if !defined(_WIN32)
    pid_t pid;
#endif
    int active;
    int finished;
    int exit_code;
} rest_job_entry_t;

static rest_job_entry_t g_jobs[MAX_TRACKED_JOBS];
static size_t g_job_count = 0;

/**
 * @brief Validates a general parameter token while rejecting '..', leading '-', and shell metacharacters.
 */
int rest_is_safe_token(const char *token) {
    size_t i;
    if (token == NULL || token[0] == '\0' || token[0] == '-') {
        return 0;
    }
    if (strstr(token, "..") != NULL) {
        return 0;
    }
    for (i = 0; token[i] != '\0'; ++i) {
        unsigned char c = (unsigned char)token[i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
              (c >= '0' && c <= '9') || c == '-' || c == '_' ||
              c == '.' || c == '/' || c == ',')) {
            return 0;
        }
    }
    return 1;
}

/**
 * @brief Validates a single URL/component identifier segment (no '/', '.', or ',').
 */
int rest_is_safe_segment(const char *seg) {
    size_t i;
    if (seg == NULL || seg[0] == '\0' || seg[0] == '-') {
        return 0;
    }
    for (i = 0; seg[i] != '\0'; ++i) {
        unsigned char c = (unsigned char)seg[i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
              (c >= '0' && c <= '9') || c == '-' || c == '_')) {
            return 0;
        }
    }
    return 1;
}

/**
 * @brief Validates an Open/Closed experiment plugin identifier segment.
 */
int rest_is_valid_experiment_suite(const char *suite) {
    return rest_is_safe_segment(suite);
}

/**
 * @brief Validates a target kernel family against the OpenAPI 3.2.0 enum.
 */
int rest_is_valid_kernel_target(const char *kernel) {
    if (kernel == NULL) {
        return 0;
    }
    return (strcmp(kernel, "linux-glibc") == 0 ||
            strcmp(kernel, "linux-musl") == 0 ||
            strcmp(kernel, "freebsd") == 0 ||
            strcmp(kernel, "illumos") == 0 ||
            strcmp(kernel, "reactos") == 0 ||
            strcmp(kernel, "unikernel-unikraft") == 0 ||
            strcmp(kernel, "unikernel-nanos") == 0 ||
            strcmp(kernel, "unikernel-osv") == 0 ||
            strcmp(kernel, "unikernel-rumprun") == 0 ||
            strcmp(kernel, "unikernel-mirageos") == 0 ||
            strcmp(kernel, "microvm-firecracker") == 0 ||
            strcmp(kernel, "rtos-zephyr") == 0 ||
            strcmp(kernel, "rtos-freertos") == 0);
}

/**
 * @brief Validates an artifact format against the OpenAPI 3.2.0 enum.
 */
int rest_is_valid_artifact_format(const char *fmt) {
    if (fmt == NULL) {
        return 0;
    }
    return (strcmp(fmt, "iso") == 0 ||
            strcmp(fmt, "live-iso") == 0 ||
            strcmp(fmt, "live-usb") == 0 ||
            strcmp(fmt, "raw") == 0 ||
            strcmp(fmt, "qcow2") == 0 ||
            strcmp(fmt, "vmdk") == 0 ||
            strcmp(fmt, "vhd") == 0 ||
            strcmp(fmt, "vhdx") == 0 ||
            strcmp(fmt, "vagrant-box") == 0 ||
            strcmp(fmt, "zfs-stream") == 0 ||
            strcmp(fmt, "rootfs-tar") == 0 ||
            strcmp(fmt, "oci-image") == 0 ||
            strcmp(fmt, "direct-kernel") == 0 ||
            strcmp(fmt, "unikernel") == 0 ||
            strcmp(fmt, "firmware-elf") == 0 ||
            strcmp(fmt, "firmware-bin") == 0 ||
            strcmp(fmt, "firmware-hex") == 0 ||
            strcmp(fmt, "firmware-uf2") == 0 ||
            strcmp(fmt, "mcuboot-signed") == 0 ||
            strcmp(fmt, "renode-resc") == 0 ||
            strcmp(fmt, "docker") == 0 ||
            strcmp(fmt, "deb") == 0 ||
            strcmp(fmt, "rpm") == 0 ||
            strcmp(fmt, "raw-img") == 0 ||
            strcmp(fmt, "vdi") == 0 ||
            strcmp(fmt, "box") == 0 ||
            strcmp(fmt, "uki") == 0 ||
            strcmp(fmt, "elf") == 0 ||
            strcmp(fmt, "uefi-gpt") == 0 ||
            strcmp(fmt, "azure-vhd") == 0 ||
            strcmp(fmt, "dmg") == 0 ||
            strcmp(fmt, "apk") == 0 ||
            strcmp(fmt, "pkg") == 0 ||
            strcmp(fmt, "msi") == 0);
}

/**
 * @brief Validates a package-as driver target against the OpenAPI 3.2.0 enum.
 */
int rest_is_valid_package_as_target(const char *target) {
    if (target == NULL) {
        return 0;
    }
    return (strcmp(target, "linux-distro") == 0 ||
            strcmp(target, "linux-kernel") == 0 ||
            strcmp(target, "freebsd-distro") == 0 ||
            strcmp(target, "illumos-distro") == 0 ||
            strcmp(target, "reactos-distro") == 0 ||
            strcmp(target, "unikernel-distro") == 0 ||
            strcmp(target, "unikernel") == 0 ||
            strcmp(target, "rtos-distro") == 0 ||
            strcmp(target, "zephyr-distro") == 0 ||
            strcmp(target, "freertos-distro") == 0 ||
            strcmp(target, "firmware-bin") == 0 ||
            strcmp(target, "firmware-elf") == 0 ||
            strcmp(target, "firmware-hex") == 0 ||
            strcmp(target, "firmware-uf2") == 0 ||
            strcmp(target, "mcuboot-signed") == 0 ||
            strcmp(target, "renode-resc") == 0 ||
            strcmp(target, "qcow2") == 0 ||
            strcmp(target, "raw") == 0 ||
            strcmp(target, "iso") == 0 ||
            strcmp(target, "vhd") == 0 ||
            strcmp(target, "vmdk") == 0 ||
            strcmp(target, "vdi") == 0 ||
            strcmp(target, "box") == 0 ||
            strcmp(target, "uki") == 0 ||
            strcmp(target, "direct-kernel") == 0 ||
            strcmp(target, "docker") == 0 ||
            strcmp(target, "msi") == 0 ||
            strcmp(target, "deb") == 0 ||
            strcmp(target, "rpm") == 0 ||
            strcmp(target, "apk") == 0 ||
            strcmp(target, "pkg") == 0 ||
            strcmp(target, "dmg") == 0);
}

/**
 * @brief Serializes the catalog of supported /v1/package-as targets as RFC 8259 JSON.
 */
int rest_list_package_as_targets(char *json_out, size_t json_cap) {
    snprintf(json_out, json_cap,
             "{\"endpoint\":\"/v1/package-as\",\"targets\":["
             "\"linux-distro\",\"linux-kernel\",\"freebsd-distro\",\"illumos-distro\","
             "\"reactos-distro\",\"unikernel-distro\",\"unikernel\",\"rtos-distro\","
             "\"zephyr-distro\",\"freertos-distro\",\"firmware-bin\",\"firmware-elf\","
             "\"firmware-hex\",\"firmware-uf2\",\"mcuboot-signed\",\"renode-resc\","
             "\"qcow2\",\"raw\",\"iso\",\"vhd\",\"vmdk\",\"vdi\",\"box\",\"uki\",\"direct-kernel\"]}");
    return 0;
}

/**
 * @brief Generates 16 CSPRNG bytes and formats an RFC 4122 UUIDv4 string.
 */
int rest_uuid_v4(char out[37]) {
    unsigned char b[16];
#if defined(_WIN32)
    if (BCryptGenRandom(NULL, b, sizeof(b), BCRYPT_USE_SYSTEM_PREFERRED_RNG) != 0) {
        return -1;
    }
#else
    int fd = open("/dev/urandom", O_RDONLY);
    size_t got = 0;
    if (fd < 0) {
        return -1;
    }
    while (got < sizeof(b)) {
        ssize_t n = read(fd, b + got, sizeof(b) - got);
        if (n <= 0) {
            close(fd);
            return -1;
        }
        got += (size_t)n;
    }
    close(fd);
#endif
    b[6] = (unsigned char)((b[6] & 0x0Fu) | 0x40u);
    b[8] = (unsigned char)((b[8] & 0x3Fu) | 0x80u);
    snprintf(out, 37,
             "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
             b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
             b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]);
    return 0;
}

/**
 * @brief Escapes a C string for RFC 8259 double-quoted JSON output.
 */
void rest_json_escape(const char *src, char *dst, size_t dst_cap) {
    size_t di = 0;
    size_t si = 0;
    if (dst_cap == 0) {
        return;
    }
    if (src == NULL) {
        dst[0] = '\0';
        return;
    }
    while (src[si] != '\0' && di + 2 < dst_cap) {
        unsigned char c = (unsigned char)src[si++];
        if (c == '"' || c == '\\') {
            if (di + 3 >= dst_cap) {
                break;
            }
            dst[di++] = '\\';
            dst[di++] = (char)c;
        } else if (c == '\n') {
            if (di + 3 >= dst_cap) {
                break;
            }
            dst[di++] = '\\';
            dst[di++] = 'n';
        } else if (c == '\r') {
            if (di + 3 >= dst_cap) {
                break;
            }
            dst[di++] = '\\';
            dst[di++] = 'r';
        } else if (c == '\t') {
            if (di + 3 >= dst_cap) {
                break;
            }
            dst[di++] = '\\';
            dst[di++] = 't';
        } else if (c >= 0x20u) {
            dst[di++] = (char)c;
        }
    }
    dst[di] = '\0';
}

/**
 * @brief Checks if a candidate directory contains LibScript root markers.
 */
static int is_libscript_root(const char *dir) {
    char probe[1024];
    FILE *fp;
    snprintf(probe, sizeof(probe), "%s/libscript.sh", dir);
    fp = fopen(probe, "rb");
    if (fp != NULL) {
        fclose(fp);
        return 1;
    }
    snprintf(probe, sizeof(probe), "%s\\libscript.cmd", dir);
    fp = fopen(probe, "rb");
    if (fp != NULL) {
        fclose(fp);
        return 1;
    }
    return 0;
}

/**
 * @brief Resolves LIBSCRIPT_ROOT_DIR from environment, argv[0], or current working directory.
 */
int rest_resolve_root_dir(const char *argv0, char *out, size_t out_cap) {
    const char *env_root = getenv("LIBSCRIPT_ROOT_DIR");
    char buf[1024];
    int depth;

    if (env_root != NULL && env_root[0] != '\0' && is_libscript_root(env_root)) {
        snprintf(out, out_cap, "%s", env_root);
        return 0;
    }

    if (argv0 != NULL && argv0[0] != '\0') {
        char *slash;
        snprintf(buf, sizeof(buf), "%s", argv0);
        for (depth = 0; depth < 6; ++depth) {
            slash = strrchr(buf, '/');
#if defined(_WIN32)
            {
                char *bslash = strrchr(buf, '\\');
                if (bslash != NULL && (slash == NULL || bslash > slash)) {
                    slash = bslash;
                }
            }
#endif
            if (slash == NULL) {
                break;
            }
            *slash = '\0';
            if (buf[0] != '\0' && is_libscript_root(buf)) {
                snprintf(out, out_cap, "%s", buf);
                return 0;
            }
        }
    }

#if defined(_WIN32)
    if (_getcwd(buf, (int)sizeof(buf)) != NULL)
#else
    if (getcwd(buf, sizeof(buf)) != NULL)
#endif
    {
        for (depth = 0; depth < 6; ++depth) {
            char *slash;
            if (is_libscript_root(buf)) {
                snprintf(out, out_cap, "%s", buf);
                return 0;
            }
            slash = strrchr(buf, '/');
#if defined(_WIN32)
            {
                char *bslash = strrchr(buf, '\\');
                if (bslash != NULL && (slash == NULL || bslash > slash)) {
                    slash = bslash;
                }
            }
#endif
            if (slash == NULL || slash == buf) {
                break;
            }
            *slash = '\0';
        }
    }

    snprintf(out, out_cap, ".");
    return -1;
}

/**
 * @brief Records and optionally spawns a child LibScript process in the tracked job table.
 */
static int spawn_or_queue_job(const char *root_dir, const char *endpoint,
                              char *const argv_exec[], int wait_sync,
                              char job_id_out[37], int *exit_code_out) {
    rest_job_entry_t *slot;
    if (rest_uuid_v4(job_id_out) != 0) {
        return -1;
    }
    slot = &g_jobs[g_job_count % MAX_TRACKED_JOBS];
    g_job_count++;
    memset(slot, 0, sizeof(*slot));
    snprintf(slot->job_id, sizeof(slot->job_id), "%s", job_id_out);
    snprintf(slot->endpoint, sizeof(slot->endpoint), "%s", endpoint);
    slot->active = 1;
    *exit_code_out = 0;

#if !defined(_WIN32)
    if (getenv("LIBSCRIPT_REST_EXEC_LIVE") != NULL) {
        char script_path[1024];
        pid_t pid;
        snprintf(script_path, sizeof(script_path), "%s/libscript.sh", root_dir);
        pid = fork();
        if (pid < 0) {
            slot->finished = 1;
            slot->exit_code = 1;
            *exit_code_out = 1;
            return -1;
        }
        if (pid == 0) {
            setenv("LIBSCRIPT_ROOT_DIR", root_dir, 1);
            execv(script_path, argv_exec);
            _exit(127);
        }
        slot->pid = pid;
        if (wait_sync) {
            int st = 0;
            waitpid(pid, &st, 0);
            slot->finished = 1;
            slot->exit_code = WIFEXITED(st) ? WEXITSTATUS(st) : 1;
            *exit_code_out = slot->exit_code;
        }
        return 0;
    }
#else
    (void)root_dir;
    (void)argv_exec;
    (void)wait_sync;
#endif
    slot->finished = 1;
    slot->exit_code = 0;
    return 0;
}

/**
 * @brief Dispatches a sanitized topology, payload, trait, or component hook job.
 */
int rest_dispatch_job(const char *root_dir, const char *subcmd, const char *action,
                      const char *target, int wait_sync, char *json_out, size_t json_cap) {
    char job_id[37];
    char esc_sub[128], esc_act[128], esc_tgt[512];
    int exit_code = 0;
    char *argv_exec[6];

    if (!rest_is_safe_segment(subcmd) || !rest_is_safe_segment(action) || !rest_is_safe_token(target)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_token\",\"message\":\"Unsafe parameter rejected\"}");
        return 1;
    }

    argv_exec[0] = "libscript.sh";
    argv_exec[1] = (char *)subcmd;
    argv_exec[2] = (char *)action;
    argv_exec[3] = (char *)target;
    argv_exec[4] = NULL;

    if (spawn_or_queue_job(root_dir, "/api/v1/jobs", argv_exec, wait_sync, job_id, &exit_code) != 0) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"dispatch_failed\",\"message\":\"Unable to allocate or spawn job\"}");
        return 1;
    }

    rest_json_escape(subcmd, esc_sub, sizeof(esc_sub));
    rest_json_escape(action, esc_act, sizeof(esc_act));
    rest_json_escape(target, esc_tgt, sizeof(esc_tgt));
    snprintf(json_out, json_cap,
             "{\"job_id\":\"%s\",\"status\":\"%s\",\"subcmd\":\"%s\",\"action\":\"%s\",\"target\":\"%s\",\"status_url\":\"/api/v1/jobs/%s\"}",
             job_id, (getenv("LIBSCRIPT_REST_EXEC_LIVE") != NULL && !wait_sync) ? "running" : "queued",
             esc_sub, esc_act, esc_tgt, job_id);
    return exit_code;
}

/**
 * @brief Dispatches an /api/v1/experiments campaign request.
 */
int rest_dispatch_experiment(const char *root_dir, const char *suite, const char *step,
                             const char *host_arch, int wait_sync, char *json_out, size_t json_cap) {
    char suite_arg[96];
    char arch_arg[96];
    char job_id[37];
    char esc_step[128], esc_arch[128];
    int exit_code = 0;
    char *argv_exec[6];

    if (!rest_is_valid_experiment_suite(suite) || !rest_is_safe_segment(step) || !rest_is_safe_token(host_arch)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_experiment_request\",\"message\":\"Invalid suite, step, or host_arch\"}");
        return 1;
    }

    snprintf(suite_arg, sizeof(suite_arg), "--suite=%s", suite);
    snprintf(arch_arg, sizeof(arch_arg), "--host-arch=%s", host_arch);

    argv_exec[0] = "libscript.sh";
    argv_exec[1] = "experiment";
    argv_exec[2] = (char *)step;
    argv_exec[3] = suite_arg;
    argv_exec[4] = arch_arg;
    argv_exec[5] = NULL;

    if (spawn_or_queue_job(root_dir, "/api/v1/experiments", argv_exec, wait_sync, job_id, &exit_code) != 0) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"dispatch_failed\",\"message\":\"Unable to allocate or spawn experiment job\"}");
        return 1;
    }

    rest_json_escape(step, esc_step, sizeof(esc_step));
    rest_json_escape(host_arch, esc_arch, sizeof(esc_arch));
    snprintf(json_out, json_cap,
             "{\"job_id\":\"%s\",\"endpoint\":\"/api/v1/experiments\",\"suite\":\"%s\",\"step\":\"%s\",\"host_arch\":\"%s\",\"status_url\":\"/api/v1/jobs/%s\"}",
             job_id, suite, esc_step, esc_arch, job_id);
    return exit_code;
}

/**
 * @brief Dispatches an /api/v1/artifacts/generate synthesis job.
 */
int rest_dispatch_artifact(const char *root_dir, const char *kernel, const char *fmt,
                           const char *components_csv, const char *board, int wait_sync,
                           char *json_out, size_t json_cap) {
    char kernel_arg[96];
    char fmt_arg[64];
    char comps_arg[512];
    char board_arg[96];
    char job_id[37];
    char esc_comps[512], esc_board[128];
    int exit_code = 0;
    char *argv_exec[7];

    if (!rest_is_valid_kernel_target(kernel) || !rest_is_valid_artifact_format(fmt) ||
        !rest_is_safe_token(components_csv)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_artifact_request\",\"message\":\"Invalid kernel, format, or components\"}");
        return 1;
    }
    if (board != NULL && board[0] != '\0' && !rest_is_safe_segment(board)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_artifact_request\",\"message\":\"Invalid board token\"}");
        return 1;
    }

    snprintf(kernel_arg, sizeof(kernel_arg), "--kernel=%s", kernel);
    snprintf(fmt_arg, sizeof(fmt_arg), "--format=%s", fmt);
    snprintf(comps_arg, sizeof(comps_arg), "--components=%s", components_csv);

    argv_exec[0] = "libscript.sh";
    argv_exec[1] = "build-image";
    argv_exec[2] = kernel_arg;
    if (board != NULL && board[0] != '\0') {
        snprintf(board_arg, sizeof(board_arg), "--board=%s", board);
        argv_exec[3] = board_arg;
        argv_exec[4] = fmt_arg;
        argv_exec[5] = comps_arg;
        argv_exec[6] = NULL;
    } else {
        board_arg[0] = '\0';
        argv_exec[3] = fmt_arg;
        argv_exec[4] = comps_arg;
        argv_exec[5] = NULL;
    }

    if (spawn_or_queue_job(root_dir, "/api/v1/artifacts/generate", argv_exec, wait_sync, job_id, &exit_code) != 0) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"dispatch_failed\",\"message\":\"Unable to allocate or spawn artifact job\"}");
        return 1;
    }

    rest_json_escape(components_csv, esc_comps, sizeof(esc_comps));
    if (board != NULL && board[0] != '\0') {
        rest_json_escape(board, esc_board, sizeof(esc_board));
        snprintf(json_out, json_cap,
                 "{\"job_id\":\"%s\",\"endpoint\":\"/api/v1/artifacts/generate\",\"kernel\":\"%s\",\"board\":\"%s\",\"format\":\"%s\",\"components\":\"%s\",\"status_url\":\"/api/v1/jobs/%s\"}",
                 job_id, kernel, esc_board, fmt, esc_comps, job_id);
    } else {
        snprintf(json_out, json_cap,
                 "{\"job_id\":\"%s\",\"endpoint\":\"/api/v1/artifacts/generate\",\"kernel\":\"%s\",\"format\":\"%s\",\"components\":\"%s\",\"status_url\":\"/api/v1/jobs/%s\"}",
                 job_id, kernel, fmt, esc_comps, job_id);
    }
    return exit_code;
}

/**
 * @brief Dispatches a /v1/package-as profile-driven synthesis job.
 */
int rest_dispatch_package_as(const char *root_dir, const char *target, const char *profile,
                             const char *fmt, const char *output_path, int wait_sync,
                             char *json_out, size_t json_cap) {
    char prof_arg[280];
    char fmt_arg[80];
    char out_arg[540];
    char job_id[37];
    char esc_prof[280];
    char esc_fmt[80];
    char esc_out[540];
    int exit_code = 0;
    size_t ai = 0;
    char *argv_exec[8];

    if (!rest_is_valid_package_as_target(target)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_package_as_request\",\"message\":\"Invalid package-as target\"}");
        return 1;
    }
    if (profile != NULL && profile[0] != '\0' && !rest_is_safe_token(profile)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_package_as_request\",\"message\":\"Invalid profile token\"}");
        return 1;
    }
    if (fmt != NULL && fmt[0] != '\0' && !rest_is_valid_artifact_format(fmt)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_package_as_request\",\"message\":\"Invalid package-as format\"}");
        return 1;
    }
    if (output_path != NULL && output_path[0] != '\0' && !rest_is_safe_token(output_path)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_package_as_request\",\"message\":\"Invalid output path token\"}");
        return 1;
    }

    argv_exec[ai++] = "libscript.sh";
    argv_exec[ai++] = "package-as";
    argv_exec[ai++] = (char *)target;
    if (profile != NULL && profile[0] != '\0') {
        snprintf(prof_arg, sizeof(prof_arg), "--profile=%s", profile);
        argv_exec[ai++] = prof_arg;
    }
    if (fmt != NULL && fmt[0] != '\0') {
        snprintf(fmt_arg, sizeof(fmt_arg), "--format=%s", fmt);
        argv_exec[ai++] = fmt_arg;
    }
    if (output_path != NULL && output_path[0] != '\0') {
        snprintf(out_arg, sizeof(out_arg), "--output=%s", output_path);
        argv_exec[ai++] = out_arg;
    }
    argv_exec[ai] = NULL;

    if (spawn_or_queue_job(root_dir, "/v1/package-as", argv_exec, wait_sync, job_id, &exit_code) != 0) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"dispatch_failed\",\"message\":\"Unable to allocate or spawn package-as job\"}");
        return 1;
    }

    rest_json_escape((profile != NULL) ? profile : "", esc_prof, sizeof(esc_prof));
    rest_json_escape((fmt != NULL) ? fmt : "", esc_fmt, sizeof(esc_fmt));
    rest_json_escape((output_path != NULL) ? output_path : "", esc_out, sizeof(esc_out));
    snprintf(json_out, json_cap,
             "{\"job_id\":\"%s\",\"endpoint\":\"/v1/package-as\",\"target\":\"%s\",\"profile\":\"%s\",\"format\":\"%s\",\"output\":\"%s\",\"status_url\":\"/api/v1/jobs/%s\"}",
             job_id, target, esc_prof, esc_fmt, esc_out, job_id);
    return exit_code;
}

/**
 * @brief Dispatches an /api/v1/marketplace/publish job across AWS, Azure, and GCP Marketplaces.
 */
int rest_dispatch_marketplace_publish(const char *root_dir, const char *offer_path,
                                      const char *clouds_csv, int wait_sync,
                                      char *json_out, size_t json_cap) {
    char clouds_arg[128];
    char job_id[37];
    char esc_offer[512], esc_clouds[128];
    const char *eff_clouds = (clouds_csv != NULL && clouds_csv[0] != '\0') ? clouds_csv : "aws,azure,gcp";
    int exit_code = 0;
    char *argv_exec[6];

    if (!rest_is_safe_token(offer_path) || !rest_is_safe_token(eff_clouds)) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"invalid_marketplace_request\",\"message\":\"Invalid offer path or clouds list\"}");
        return 1;
    }

    snprintf(clouds_arg, sizeof(clouds_arg), "--clouds=%s", eff_clouds);
    argv_exec[0] = "libscript.sh";
    argv_exec[1] = "publish-marketplace";
    argv_exec[2] = (char *)offer_path;
    argv_exec[3] = clouds_arg;
    argv_exec[4] = "--dry-run";
    argv_exec[5] = NULL;

    if (spawn_or_queue_job(root_dir, "/api/v1/marketplace/publish", argv_exec, wait_sync, job_id, &exit_code) != 0) {
        snprintf(json_out, json_cap,
                 "{\"error\":\"dispatch_failed\",\"message\":\"Unable to allocate or spawn marketplace job\"}");
        return 1;
    }

    rest_json_escape(offer_path, esc_offer, sizeof(esc_offer));
    rest_json_escape(eff_clouds, esc_clouds, sizeof(esc_clouds));
    snprintf(json_out, json_cap,
             "{\"job_id\":\"%s\",\"endpoint\":\"/api/v1/marketplace/publish\",\"offer\":\"%s\",\"clouds\":\"%s\",\"status_url\":\"/api/v1/jobs/%s\"}",
             job_id, esc_offer, esc_clouds, job_id);
    return exit_code;
}

/**
 * @brief Lists auto-discovered Open/Closed experiment plugins under experiments/<suite-id>/suite.json.
 */
int rest_list_experiments(const char *root_dir, char *json_out, size_t json_cap) {
    size_t pos = 0;
    int first = 1;
    pos += (size_t)snprintf(json_out, json_cap, "{\"suites\":[");
#if !defined(_WIN32)
    {
        char exp_dir[1024];
        DIR *dp;
        snprintf(exp_dir, sizeof(exp_dir), "%s/experiments", root_dir);
        dp = opendir(exp_dir);
        if (dp != NULL) {
            struct dirent *de;
            while ((de = readdir(dp)) != NULL) {
                char probe[1280];
                FILE *fp;
                if (de->d_name[0] == '.') {
                    continue;
                }
                snprintf(probe, sizeof(probe), "%s/%s/suite.json", exp_dir, de->d_name);
                fp = fopen(probe, "rb");
                if (fp != NULL) {
                    char esc[128];
                    fclose(fp);
                    rest_json_escape(de->d_name, esc, sizeof(esc));
                    if (pos + strlen(esc) + 6u < json_cap) {
                        pos += (size_t)snprintf(json_out + pos, json_cap - pos, "%s\"%s\"", first ? "" : ",", esc);
                        first = 0;
                    }
                }
            }
            closedir(dp);
        }
    }
#else
    (void)root_dir;
    (void)first;
#endif
    if (pos + 3u < json_cap) {
        (void)snprintf(json_out + pos, json_cap - pos, "]}");
    }
    return 0;
}

/**
 * @brief Queries declared capabilities from _lib/<category>/<name>/manifest.json.
 */
int rest_query_component_capabilities(const char *root_dir, const char *comp_name,
                                      char *json_out, size_t json_cap) {
    if (!rest_is_safe_segment(comp_name)) {
        return -1;
    }
#if !defined(_WIN32)
    {
        char lib_dir[1024];
        DIR *dp;
        snprintf(lib_dir, sizeof(lib_dir), "%s/_lib", root_dir);
        dp = opendir(lib_dir);
        if (dp != NULL) {
            struct dirent *de;
            while ((de = readdir(dp)) != NULL) {
                char mf_path[1280];
                FILE *fp;
                if (de->d_name[0] == '.' || strcmp(de->d_name, "_common") == 0) {
                    continue;
                }
                snprintf(mf_path, sizeof(mf_path), "%s/%s/%s/manifest.json", lib_dir, de->d_name, comp_name);
                fp = fopen(mf_path, "rb");
                if (fp != NULL) {
                    char buf[4096];
                    size_t nread = fread(buf, 1u, sizeof(buf) - 1u, fp);
                    const char *cap_key;
                    const char *tier_val = "T1";
                    fclose(fp);
                    buf[nread] = '\0';
                    if (strstr(buf, "\"T2\"") != NULL && strstr(buf, "\"tier\"") != NULL) {
                        tier_val = "T2";
                    }
                    cap_key = strstr(buf, "\"capabilities\"");
                    if (cap_key != NULL) {
                        const char *lb = strchr(cap_key, '[');
                        const char *rb = (lb != NULL) ? strchr(lb, ']') : NULL;
                        if (lb != NULL && rb != NULL && rb >= lb) {
                            size_t arr_len = (size_t)(rb - lb + 1);
                            char arr_buf[512];
                            if (arr_len >= sizeof(arr_buf)) {
                                arr_len = sizeof(arr_buf) - 1u;
                            }
                            memcpy(arr_buf, lb, arr_len);
                            arr_buf[arr_len] = '\0';
                            closedir(dp);
                            snprintf(json_out, json_cap,
                                     "{\"component\":\"%s\",\"tier\":\"%s\",\"category\":\"%s\",\"capabilities\":%s}",
                                     comp_name, tier_val, de->d_name, arr_buf);
                            return 0;
                        }
                    }
                    closedir(dp);
                    snprintf(json_out, json_cap,
                             "{\"component\":\"%s\",\"tier\":\"%s\",\"category\":\"%s\",\"capabilities\":[\"userland-package\"]}",
                             comp_name, tier_val, de->d_name);
                    return 0;
                }
            }
            closedir(dp);
        }
    }
#else
    (void)root_dir;
#endif
    return -1;
}

/**
 * @brief Queries non-blocking job state by UUID, reaping completed POSIX child processes via WNOHANG.
 */
int rest_query_job(const char *job_id, char *json_out, size_t json_cap) {
    size_t i;
    size_t limit = g_job_count < MAX_TRACKED_JOBS ? g_job_count : MAX_TRACKED_JOBS;
    if (job_id == NULL || strlen(job_id) != 36) {
        return -1;
    }
    for (i = 0; i < limit; ++i) {
        rest_job_entry_t *e = &g_jobs[i];
        if (e->active && strcmp(e->job_id, job_id) == 0) {
            const char *state_str = "succeeded";
#if !defined(_WIN32)
            if (!e->finished && e->pid > 0) {
                int st = 0;
                pid_t w = waitpid(e->pid, &st, WNOHANG);
                if (w == e->pid) {
                    e->finished = 1;
                    e->exit_code = WIFEXITED(st) ? WEXITSTATUS(st) : 1;
                }
            }
#endif
            if (!e->finished) {
                state_str = "running";
            } else if (e->exit_code != 0) {
                state_str = "failed";
            }
            snprintf(json_out, json_cap,
                     "{\"job_id\":\"%s\",\"endpoint\":\"%s\",\"status\":\"%s\",\"exit_code\":%d}",
                     e->job_id, e->endpoint, state_str, e->exit_code);
            return 0;
        }
    }
    return -1;
}

/**
 * @brief Minimal, zero-dependency RFC 8259 string property extractor for flat JSON request payloads.
 */
int rest_json_get_string(const char *body, const char *key, char *out, size_t out_cap) {
    char pat[128];
    const char *p;
    size_t oi = 0;
    if (body == NULL || key == NULL || out_cap == 0) {
        return -1;
    }
    out[0] = '\0';
    snprintf(pat, sizeof(pat), "\"%s\"", key);
    p = strstr(body, pat);
    if (p == NULL) {
        return -1;
    }
    p += strlen(pat);
    while (*p != '\0' && isspace((unsigned char)*p)) {
        p++;
    }
    if (*p != ':') {
        return -1;
    }
    p++;
    while (*p != '\0' && isspace((unsigned char)*p)) {
        p++;
    }
    if (*p != '"') {
        return -1;
    }
    p++;
    while (*p != '\0' && *p != '"' && oi + 1 < out_cap) {
        if (*p == '\\' && p[1] != '\0') {
            p++;
        }
        out[oi++] = *p++;
    }
    if (*p != '"') {
        out[0] = '\0';
        return -1;
    }
    out[oi] = '\0';
    return 0;
}
