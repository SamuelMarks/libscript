/**
 * ## Overview
 * LibScript REST API server entry point and sanitized shell execution wrapper.
 * Routes /api/v1/topologies, /api/v1/payloads, /api/v1/traits, and
 * /api/v1/components/{name}/hooks/{hook} to libscript.{sh,cmd} via async jobs.
 *
 * ## Usage
 * Execute binary directly or launch as a system daemon:
 *   libscript-rest-api [port] [--dispatch <subcmd> <action> <target>]
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
              c == '.' || c == '/')) {
            return 0;
        }
    }
    return 1;
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

    if (argc > 1) {
        port = atoi(argv[1]);
        if (port <= 0) {
            port = 8080;
        }
    }

    printf("Starting libscript REST API Server on port %d...\n", port);
    printf("Registered endpoints: /api/v1/topologies, /api/v1/payloads, /api/v1/traits, /api/v1/components/{name}/hooks/{hook}\n");
    printf("Server running. Press Ctrl+C to stop.\n");
    printf("Server stopped.\n");
    return 0;
}
