/**
 * ## Overview
 * Public C11 declarations for LibScript REST API token validation, UUIDv4 generation,
 * RFC 8259 JSON serialization, root resolution, async job tracking, and HTTP routing.
 *
 * ## Usage
 * Included by src/rest_dispatch.c and src/main.c.
 */
#ifndef LIBSCRIPT_REST_API_H
#define LIBSCRIPT_REST_API_H

#include <stddef.h>

/**
 * @brief Validates a general parameter token (allows '/', ',', '.', '_', '-', alphanumeric; rejects '..', leading '-', or empty).
 * @param token Candidate string.
 * @return 1 if safe, 0 otherwise.
 */
int rest_is_safe_token(const char *token);

/**
 * @brief Validates a single path/identifier segment (alphanumeric, '_', '-'; rejects '/', '.', ',', '..', leading '-').
 * @param seg Candidate segment string.
 * @return 1 if safe, 0 otherwise.
 */
int rest_is_safe_segment(const char *seg);

/**
 * @brief Validates an experiment suite name against the OpenAPI 3.2.0 enum.
 * @param suite Candidate suite identifier.
 * @return 1 if valid, 0 otherwise.
 */
int rest_is_valid_experiment_suite(const char *suite);

/**
 * @brief Validates a target kernel family against the OpenAPI 3.2.0 enum.
 * @param kernel Candidate kernel identifier.
 * @return 1 if valid, 0 otherwise.
 */
int rest_is_valid_kernel_target(const char *kernel);

/**
 * @brief Validates an artifact packaging format against the OpenAPI 3.2.0 enum.
 * @param fmt Candidate format identifier.
 * @return 1 if valid, 0 otherwise.
 */
int rest_is_valid_artifact_format(const char *fmt);

/**
 * @brief Validates a package-as driver target against the OpenAPI 3.2.0 enum.
 * @param target Candidate package-as target identifier.
 * @return 1 if valid, 0 otherwise.
 */
int rest_is_valid_package_as_target(const char *target);

/**
 * @brief Generates a lowercase 36-character RFC 4122 UUIDv4 string using OS CSPRNG.
 * @param out Output buffer of at least 37 bytes.
 * @return 0 on success, -1 on CSPRNG failure.
 */
int rest_uuid_v4(char out[37]);

/**
 * @brief Escapes an arbitrary UTF-8 string for safe inclusion inside double-quoted RFC 8259 JSON.
 * @param src Source NUL-terminated string.
 * @param dst Destination buffer.
 * @param dst_cap Capacity of destination buffer in bytes.
 */
void rest_json_escape(const char *src, char *dst, size_t dst_cap);

/**
 * @brief Resolves LIBSCRIPT_ROOT_DIR from environment or upward directory search.
 * @param argv0 Executable path from argv[0] (may be NULL).
 * @param out Destination buffer.
 * @param out_cap Capacity of destination buffer.
 * @return 0 on success, -1 if not found.
 */
int rest_resolve_root_dir(const char *argv0, char *out, size_t out_cap);

/**
 * @brief Dispatches a sanitized topology, payload, trait, or component hook job.
 * @param root_dir Resolved LibScript root directory.
 * @param subcmd Subsystem command.
 * @param action Action verb.
 * @param target Target identifier or manifest path.
 * @param wait_sync If non-zero, waits synchronously when LIBSCRIPT_REST_EXEC_LIVE is set.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 on accepted/succeeded, non-zero on validation or execution error.
 */
int rest_dispatch_job(const char *root_dir, const char *subcmd, const char *action,
                      const char *target, int wait_sync, char *json_out, size_t json_cap);

/**
 * @brief Dispatches an /api/v1/experiments campaign job.
 * @param root_dir Resolved LibScript root directory.
 * @param suite Experiment suite enum value.
 * @param step Campaign step identifier.
 * @param host_arch Target OS/ISA tag.
 * @param wait_sync If non-zero, waits synchronously when LIBSCRIPT_REST_EXEC_LIVE is set.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 on accepted/succeeded, non-zero on validation or execution error.
 */
int rest_dispatch_experiment(const char *root_dir, const char *suite, const char *step,
                             const char *host_arch, int wait_sync, char *json_out, size_t json_cap);

/**
 * @brief Dispatches an /api/v1/artifacts/generate synthesis job.
 * @param root_dir Resolved LibScript root directory.
 * @param kernel Target kernel enum value.
 * @param fmt Target artifact format enum value.
 * @param components_csv Comma-separated component list.
 * @param board Optional RTOS board identifier (may be NULL).
 * @param wait_sync If non-zero, waits synchronously when LIBSCRIPT_REST_EXEC_LIVE is set.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 on accepted/succeeded, non-zero on validation or execution error.
 */
int rest_dispatch_artifact(const char *root_dir, const char *kernel, const char *fmt,
                           const char *components_csv, const char *board, int wait_sync,
                           char *json_out, size_t json_cap);

/**
 * @brief Dispatches a /v1/package-as profile-driven synthesis job.
 * @param root_dir Resolved LibScript root directory.
 * @param target Canonical package-as target (e.g. linux-distro, freebsd-distro, unikernel-distro).
 * @param profile Optional profile preset or relative JSON path (may be NULL).
 * @param fmt Optional output format override (may be NULL).
 * @param output_path Optional relative output path (may be NULL).
 * @param wait_sync If non-zero, waits synchronously when LIBSCRIPT_REST_EXEC_LIVE is set.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 on accepted/succeeded, non-zero on validation or execution error.
 */
int rest_dispatch_package_as(const char *root_dir, const char *target, const char *profile,
                             const char *fmt, const char *output_path, int wait_sync,
                             char *json_out, size_t json_cap);

/**
 * @brief Serializes the catalog of supported /v1/package-as targets as RFC 8259 JSON.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 on success.
 */
int rest_list_package_as_targets(char *json_out, size_t json_cap);

/**
 * @brief Dispatches an /api/v1/marketplace/publish job across AWS, Azure, and GCP Marketplaces.
 * @param root_dir Resolved LibScript root directory.
 * @param offer_path Relative path to offer.json.
 * @param clouds_csv Comma-separated target clouds (e.g. aws,azure,gcp).
 * @param wait_sync If non-zero, waits synchronously when LIBSCRIPT_REST_EXEC_LIVE is set.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 on accepted/succeeded, non-zero on validation or execution error.
 */
int rest_dispatch_marketplace_publish(const char *root_dir, const char *offer_path,
                                      const char *clouds_csv, int wait_sync,
                                      char *json_out, size_t json_cap);

/**
 * @brief Lists auto-discovered Open/Closed experiment plugins under experiments/<suite-id>/suite.json.
 * @param root_dir Resolved LibScript root directory.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 on success.
 */
int rest_list_experiments(const char *root_dir, char *json_out, size_t json_cap);

/**
 * @brief Queries declared capabilities from _lib/<category>/<name>/manifest.json.
 * @param root_dir Resolved LibScript root directory.
 * @param comp_name Sanitized component segment identifier.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 if component manifest found, -1 if not found or invalid.
 */
int rest_query_component_capabilities(const char *root_dir, const char *comp_name,
                                      char *json_out, size_t json_cap);

/**
 * @brief Queries non-blocking status of a previously dispatched job by UUID.
 * @param job_id 36-character UUIDv4 identifier.
 * @param json_out Output buffer receiving RFC 8259 JSON response.
 * @param json_cap Capacity of json_out.
 * @return 0 if found, -1 if unknown job_id.
 */
int rest_query_job(const char *job_id, char *json_out, size_t json_cap);

/**
 * @brief Extracts a simple string field from a flat JSON request body.
 * @param body Raw JSON body text.
 * @param key Field name to extract.
 * @param out Destination buffer.
 * @param out_cap Capacity of destination buffer.
 * @return 0 if found, -1 otherwise.
 */
int rest_json_get_string(const char *body, const char *key, char *out, size_t out_cap);

#endif /* LIBSCRIPT_REST_API_H */
