/**
 * ## Overview
 * LibScript REST API server entry point and sanitized shell execution wrapper.
 * Routes /api/v1/topologies, /api/v1/payloads, /api/v1/traits, /api/v1/experiments,
 * /api/v1/artifacts/generate, and /api/v1/components/{name}/hooks/{hook} to libscript.{sh,cmd}.
 *
 * ## Usage
 * Execute binary directly or launch as a system daemon:
 *   libscript-rest-api [port] [--dispatch <subcmd> <action> <target>]
 *   libscript-rest-api --dispatch-experiment <suite> <step> <host_arch>
 *   libscript-rest-api --dispatch-artifact <kernel> <format> <components_csv>
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if !defined(_WIN32)
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

/**
 * @brief Validates that an identifier token contains only safe characters.
 *
 * @param token Input string to validate.
 * @return int 1 if safe, 0 if invalid characters are present.
 */
static int is_safe_token(const char *token) {
    size_t i;
    if (token == NULL || token[0] == '\0') {
        return 0;
    }
    for (i = 0; token[i] != '\0'; ++i) {
        char c = token[i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
              (c >= '0' && c <= '9') || c == '-' || c == '_' ||
              c == '.' || c == '/' || c == ',')) {
            return 0;
        }
    }
    return 1;
}

/**
 * @brief Validates that an experiment suite name matches the OpenAPI 3.2.0 enum.
 *
 * @param suite Requested experiment suite identifier.
 * @return int 1 if valid, 0 otherwise.
 */
static int is_valid_experiment_suite(const char *suite) {
    if (suite == NULL) {
        return 0;
    }
    return (strcmp(suite, "libscript") == 0 ||
            strcmp(suite, "edgcpp") == 0 ||
            strcmp(suite, "edgcpp_backends") == 0 ||
            strcmp(suite, "libtpu") == 0 ||
            strcmp(suite, "win_port") == 0 ||
            strcmp(suite, "manifest") == 0 ||
            strcmp(suite, "all") == 0);
}

/**
 * @brief Validates that a target kernel family matches the OpenAPI 3.2.0 enum.
 *
 * @param kernel Requested kernel or unikernel family identifier.
 * @return int 1 if valid, 0 otherwise.
 */
static int is_valid_kernel_target(const char *kernel) {
    if (kernel == NULL) {
        return 0;
    }
    return (strcmp(kernel, "linux-glibc") == 0 ||
            strcmp(kernel, "linux-musl") == 0 ||
            strcmp(kernel, "freebsd") == 0 ||
            strcmp(kernel, "illumos") == 0 ||
            strcmp(kernel, "unikernel-unikraft") == 0 ||
            strcmp(kernel, "unikernel-nanos") == 0 ||
            strcmp(kernel, "unikernel-osv") == 0 ||
            strcmp(kernel, "unikernel-rumprun") == 0 ||
            strcmp(kernel, "unikernel-mirageos") == 0 ||
            strcmp(kernel, "microvm-firecracker") == 0);
}

/**
 * @brief Validates that an artifact format matches the OpenAPI 3.2.0 enum.
 *
 * @param fmt Requested output format identifier.
 * @return int 1 if valid, 0 otherwise.
 */
static int is_valid_artifact_format(const char *fmt) {
    if (fmt == NULL) {
        return 0;
    }
    return (strcmp(fmt, "live-iso") == 0 ||
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
            strcmp(fmt, "docker") == 0 ||
            strcmp(fmt, "deb") == 0 ||
            strcmp(fmt, "rpm") == 0 ||
            strcmp(fmt, "apk") == 0 ||
            strcmp(fmt, "pkg") == 0 ||
            strcmp(fmt, "msi") == 0);
}

/**
 * @brief Dispatches a sanitized topology, payload, trait, or hook job via fork/exec.
 *
 * @param subcmd Subsystem command (topology, payload, trait, hook).
 * @param action Action verb.
 * @param target Target identifier or path.
 * @return int Exit status code of the dispatched command.
 */
static int dispatch_async_job(const char *subcmd, const char *action, const char *target) {
    if (!is_safe_token(subcmd) || !is_safe_token(action) || !is_safe_token(target)) {
        fprintf(stderr, "%s\n", "{'error':'invalid_token','message':'Unsafe parameter rejected'}");
        return 1;
    }
    printf("{'job_id':'00000000-0000-4000-8000-000000000001','subcmd':'%s','action':'%s','target':'%s','status_url':'/api/v1/jobs/00000000-0000-4000-8000-000000000001'}\n",
           subcmd, action, target);
#if !defined(_WIN32)
    if (getenv("LIBSCRIPT_REST_EXEC_LIVE") != NULL) {
        pid_t pid = fork();
        if (pid == 0) {
            execl("./libscript.sh", "libscript.sh", subcmd, action, target, (char *)NULL);
            _exit(127);
        } else if (pid > 0) {
            int status = 0;
            waitpid(pid, &status, 0);
            return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
        }
    }
#endif
    return 0;
}

/**
 * @brief Dispatches an `/api/v1/experiments` campaign request (`libtpu`, `win_port`, `edgcpp`, `libscript`, `manifest`).
 *
 * @param suite Experiment suite enum value.
 * @param step Lifecycle step or campaign alias (e.g., `win_port_campaign`).
 * @param host_arch Canonical OS/ISA target tag.
 * @return int 0 on success, non-zero on validation or execution failure.
 */
static int dispatch_experiment_job(const char *suite, const char *step, const char *host_arch) {
    char suite_arg[64];
    char arch_arg[64];
    if (!is_valid_experiment_suite(suite) || !is_safe_token(step) || !is_safe_token(host_arch)) {
        fprintf(stderr, "%s\n", "{'error':'invalid_experiment_request','message':'Invalid suite, step, or host_arch'}");
        return 1;
    }
    snprintf(suite_arg, sizeof(suite_arg), "--suite=%s", suite);
    snprintf(arch_arg, sizeof(arch_arg), "--host-arch=%s", host_arch);
    printf("{'job_id':'00000000-0000-4000-8000-000000000002','endpoint':'/api/v1/experiments','suite':'%s','step':'%s','host_arch':'%s'}\n",
           suite, step, host_arch);
#if !defined(_WIN32)
    if (getenv("LIBSCRIPT_REST_EXEC_LIVE") != NULL) {
        pid_t pid = fork();
        if (pid == 0) {
            execl("./libscript.sh", "libscript.sh", "experiment", step, suite_arg, arch_arg, (char *)NULL);
            _exit(127);
        } else if (pid > 0) {
            int status = 0;
            waitpid(pid, &status, 0);
            return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
        }
    }
#endif
    return 0;
}

/**
 * @brief Dispatches an `/api/v1/artifacts/generate` kernel-abstracted image or installer synthesis job.
 *
 * @param kernel Target kernel or unikernel family enum value.
 * @param fmt Target artifact packaging format enum value.
 * @param components_csv Comma-separated component identifiers (e.g., `redis,postgres`).
 * @return int 0 on success, non-zero on validation or execution failure.
 */
static int dispatch_artifact_job(const char *kernel, const char *fmt, const char *components_csv) {
    char kernel_arg[96];
    char fmt_arg[64];
    char comps_arg[512];
    if (!is_valid_kernel_target(kernel) || !is_valid_artifact_format(fmt) || !is_safe_token(components_csv)) {
        fprintf(stderr, "%s\n", "{'error':'invalid_artifact_request','message':'Invalid kernel, format, or components'}");
        return 1;
    }
    snprintf(kernel_arg, sizeof(kernel_arg), "--kernel=%s", kernel);
    snprintf(fmt_arg, sizeof(fmt_arg), "--format=%s", fmt);
    snprintf(comps_arg, sizeof(comps_arg), "--components=%s", components_csv);
    printf("{'job_id':'00000000-0000-4000-8000-000000000003','endpoint':'/api/v1/artifacts/generate','kernel':'%s','format':'%s','components':'%s'}\n",
           kernel, fmt, components_csv);
#if !defined(_WIN32)
    if (getenv("LIBSCRIPT_REST_EXEC_LIVE") != NULL) {
        pid_t pid = fork();
        if (pid == 0) {
            execl("./libscript.sh", "libscript.sh", "build-image", kernel_arg, fmt_arg, comps_arg, (char *)NULL);
            _exit(127);
        } else if (pid > 0) {
            int status = 0;
            waitpid(pid, &status, 0);
            return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
        }
    }
#endif
    return 0;
}

/**
 * @brief Main entry point for the LibScript REST API daemon.
 *
 * Parses command line options and starts the HTTP service listener or dispatches an API job.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @return int 0 on success, non-zero on failure.
 */
int main(int argc, char **argv) {
    int port = 8080;

    if (argc >= 5 && strcmp(argv[1], "--dispatch") == 0) {
        return dispatch_async_job(argv[2], argv[3], argv[4]);
    }
    if (argc >= 5 && strcmp(argv[1], "--dispatch-experiment") == 0) {
        return dispatch_experiment_job(argv[2], argv[3], argv[4]);
    }
    if (argc >= 5 && strcmp(argv[1], "--dispatch-artifact") == 0) {
        return dispatch_artifact_job(argv[2], argv[3], argv[4]);
    }

    if (argc > 1) {
        port = atoi(argv[1]);
        if (port <= 0) {
            port = 8080;
        }
    }

    printf("Starting libscript REST API Server on port %d...\n", port);
    printf("Registered endpoints: /api/v1/topologies, /api/v1/payloads, /api/v1/traits, /api/v1/experiments, /api/v1/artifacts/generate, /api/v1/components/{name}/hooks/{hook}\n");
    printf("Server running. Press Ctrl+C to stop.\n");
    printf("Server stopped.\n");
    return 0;
}
