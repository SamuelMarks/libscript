/*
 * ## Overview
 * Portable ANSI C89 POSIX `/bin/sh` subset with `spawnvp` temporary-file pipeline staging
 * for single-tasking 32-bit MS-DOS (`dos32` via OpenWatcom `wcl386` + `DOS32A.EXE`), plus
 * Win32 and POSIX host compatibility.
 *
 * On MS-DOS (where `fork()` and kernel `pipe()` do not exist), multi-stage pipelines
 * `cmd1 | cmd2 | cmd3` and `$(cmd)` command substitutions are staged sequentially through
 * temporary files (`%TEMP%\LSP_XXXX.TMP`) with file-descriptor `dup`/`dup2` redirection around
 * `spawnvp(P_WAIT, ...)`.
 *
 * ## Usage
 * sh [-c "command"] [script.sh] [args...]
 */

#if !defined(_WIN32) && !defined(__DOS__) && !defined(__MSDOS__) && !defined(_MSDOS)
#define _POSIX_C_SOURCE 200809L
#endif

#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#if defined(_WIN32)
#include <direct.h>
#include <io.h>
#include <process.h>
#define SH_DUP _dup
#define SH_DUP2 _dup2
#define SH_OPEN _open
#define SH_CLOSE _close
#define SH_CHDIR _chdir
#define SH_GETCWD _getcwd
#define SH_UNLINK _unlink
#define SH_SPAWN_WAIT _P_WAIT
#define SH_HAS_SPAWNVP 1
#elif defined(__DOS__) || defined(__MSDOS__) || defined(_MSDOS)
#include <direct.h>
#include <io.h>
#include <process.h>
#define SH_DUP dup
#define SH_DUP2 dup2
#define SH_OPEN open
#define SH_CLOSE close
#define SH_CHDIR chdir
#define SH_GETCWD getcwd
#define SH_UNLINK unlink
#define SH_SPAWN_WAIT P_WAIT
#define SH_HAS_SPAWNVP 1
#else
#include <sys/wait.h>
#include <unistd.h>
#define SH_DUP dup
#define SH_DUP2 dup2
#define SH_OPEN open
#define SH_CLOSE close
#define SH_CHDIR chdir
#define SH_GETCWD getcwd
#define SH_UNLINK unlink
#define SH_HAS_SPAWNVP 0
#endif

#define MAX_SH_VARS 256
#define MAX_STAGE_ARGV 64
#define MAX_STAGES 16
#define MAX_CMD_LEN 4096

typedef struct {
    char key[64];
    char val[1024];
    int exported;
} ShVar;

typedef struct {
    ShVar vars[MAX_SH_VARS];
    int var_count;
    int last_status;
    int opt_errexit;
    int opt_nounset;
    int exit_requested;
    unsigned int tmp_seq;
    char argv0[256];
    char pos_args[32][512];
    int pos_count;
} ShState;

static void sh_copy(char *dst, size_t cap, const char *src) {
    size_t len = strlen(src);
    if (cap == 0) return;
    if (len >= cap) len = cap - 1;
    memcpy(dst, src, len);
    dst[len] = '\0';
}

static const char *sh_get(ShState *st, const char *name, char *num_buf) {
    int i;
    const char *ev;
    if (strcmp(name, "?") == 0) {
        sprintf(num_buf, "%d", st->last_status);
        return num_buf;
    }
    if (strcmp(name, "0") == 0) return st->argv0;
    if (strcmp(name, "#") == 0) {
        sprintf(num_buf, "%d", st->pos_count);
        return num_buf;
    }
    if (isdigit((unsigned char)name[0]) && name[1] == '\0') {
        int idx = name[0] - '1';
        return (idx >= 0 && idx < st->pos_count) ? st->pos_args[idx] : "";
    }
    for (i = 0; i < st->var_count; i++) {
        if (strcmp(st->vars[i].key, name) == 0) return st->vars[i].val;
    }
    ev = getenv(name);
    return ev ? ev : NULL;
}

static void sh_export_os(const char *k, const char *v) {
#if defined(_WIN32)
    _putenv_s(k, v);
#elif defined(__DOS__) || defined(__MSDOS__) || defined(_MSDOS)
    static char env_pool[64][256];
    static int pool_idx = 0;
    sprintf(env_pool[pool_idx % 64], "%s=%s", k, v);
    putenv(env_pool[pool_idx % 64]);
    pool_idx++;
#else
    setenv(k, v, 1);
#endif
}

static void sh_set(ShState *st, const char *name, const char *val, int do_export) {
    int i;
    for (i = 0; i < st->var_count; i++) {
        if (strcmp(st->vars[i].key, name) == 0) {
            sh_copy(st->vars[i].val, sizeof(st->vars[0].val), val);
            if (do_export) st->vars[i].exported = 1;
            if (st->vars[i].exported) sh_export_os(name, val);
            return;
        }
    }
    if (st->var_count < MAX_SH_VARS) {
        sh_copy(st->vars[st->var_count].key, sizeof(st->vars[0].key), name);
        sh_copy(st->vars[st->var_count].val, sizeof(st->vars[0].val), val);
        st->vars[st->var_count].exported = do_export;
        st->var_count++;
        if (do_export) sh_export_os(name, val);
    }
}

static void sh_make_tmp(ShState *st, char *buf, size_t cap) {
    const char *td = getenv("TMPDIR");
    (void)cap;
    if (!td || !td[0]) td = getenv("TEMP");
    if (!td || !td[0]) td = getenv("TMP");
#if defined(__DOS__) || defined(__MSDOS__) || defined(_MSDOS)
    if (!td || !td[0]) td = "C:";
    sprintf(buf, "%s\\LSP_%04u.TMP", td, (++st->tmp_seq) & 0xFFFFu);
#else
    if (!td || !td[0]) td = "/tmp";
    sprintf(buf, "%s/lsp_%u_%u.tmp", td, (unsigned int)getpid(), ++st->tmp_seq);
#endif
}

static int sh_eval_line(ShState *st, const char *line);

static void sh_expand(ShState *st, const char *in, char *out, size_t cap) {
    size_t i = 0, o = 0;
    int in_sq = 0, in_dq = 0;

    while (in[i] && o + 1 < cap) {
        if (in[i] == '\'' && !in_dq) {
            in_sq = !in_sq;
            out[o++] = in[i++];
            continue;
        }
        if (in[i] == '"' && !in_sq) {
            in_dq = !in_dq;
            out[o++] = in[i++];
            continue;
        }
        if (!in_sq && in[i] == '\\' && in[i + 1] == '$') {
            out[o++] = '$';
            i += 2;
            continue;
        }
        if (!in_sq && in[i] == '$' && in[i + 1] == '(') {
            int depth = 1;
            size_t k = i + 2;
            while (in[k] && depth > 0) {
                if (in[k] == '(') depth++;
                else if (in[k] == ')') depth--;
                if (depth > 0) k++;
            }
            if (depth == 0) {
                char sub[1024], tmpf[256];
                size_t slen = k - (i + 2);
                int saved_out, fd;
                FILE *rf;
                if (slen >= sizeof(sub)) slen = sizeof(sub) - 1;
                memcpy(sub, in + i + 2, slen);
                sub[slen] = '\0';
                sh_make_tmp(st, tmpf, sizeof(tmpf));
                fflush(stdout);
                saved_out = SH_DUP(1);
                fd = SH_OPEN(tmpf, O_WRONLY | O_CREAT | O_TRUNC, 0600);
                if (fd >= 0) {
                    SH_DUP2(fd, 1);
                    SH_CLOSE(fd);
                    sh_eval_line(st, sub);
                    fflush(stdout);
                }
                if (saved_out >= 0) {
                    SH_DUP2(saved_out, 1);
                    SH_CLOSE(saved_out);
                }
                rf = fopen(tmpf, "r");
                if (rf) {
                    char cbuf[1024];
                    size_t n = fread(cbuf, 1, sizeof(cbuf) - 1, rf);
                    cbuf[n] = '\0';
                    fclose(rf);
                    while (n > 0 && (cbuf[n - 1] == '\n' || cbuf[n - 1] == '\r')) cbuf[--n] = '\0';
                    if (o + n >= cap) n = cap - o - 1;
                    memcpy(out + o, cbuf, n);
                    o += n;
                }
                SH_UNLINK(tmpf);
                i = k + 1;
                continue;
            }
        }
        if (!in_sq && in[i] == '$' && in[i + 1] == '{') {
            const char *end = strchr(in + i + 2, '}');
            if (end) {
                char expr[256], key[64], nbuf[32];
                const char *val;
                const char *op = NULL;
                size_t elen = (size_t)(end - (in + i + 2));
                if (elen >= sizeof(expr)) elen = sizeof(expr) - 1;
                memcpy(expr, in + i + 2, elen);
                expr[elen] = '\0';
                op = strstr(expr, ":-");
                if (op) {
                    size_t kl = (size_t)(op - expr);
                    const char *def = op + 2;
                    if (kl >= sizeof(key)) kl = sizeof(key) - 1;
                    memcpy(key, expr, kl);
                    key[kl] = '\0';
                    val = sh_get(st, key, nbuf);
                    if (!val || val[0] == '\0') val = def;
                } else if ((op = strchr(expr, '#')) != NULL && op > expr) {
                    size_t kl = (size_t)(op - expr);
                    const char *pre = op + 1;
                    size_t pl = strlen(pre);
                    if (kl >= sizeof(key)) kl = sizeof(key) - 1;
                    memcpy(key, expr, kl);
                    key[kl] = '\0';
                    val = sh_get(st, key, nbuf);
                    if (!val) val = "";
                    if (strncmp(val, pre, pl) == 0) val += pl;
                } else if ((op = strchr(expr, '%')) != NULL && op > expr) {
                    static char trimmed[512];
                    size_t kl = (size_t)(op - expr);
                    const char *suf = op + 1;
                    size_t sl = strlen(suf), vl;
                    if (kl >= sizeof(key)) kl = sizeof(key) - 1;
                    memcpy(key, expr, kl);
                    key[kl] = '\0';
                    val = sh_get(st, key, nbuf);
                    if (!val) val = "";
                    sh_copy(trimmed, sizeof(trimmed), val);
                    vl = strlen(trimmed);
                    if (vl >= sl && strcmp(trimmed + vl - sl, suf) == 0) trimmed[vl - sl] = '\0';
                    val = trimmed;
                } else {
                    val = sh_get(st, expr, nbuf);
                    if (!val) {
                        if (st->opt_nounset) {
                            fprintf(stderr, "sh: %s: parameter not set\n", expr);
                            st->last_status = 1;
                            st->exit_requested = 1;
                            out[o] = '\0';
                            return;
                        }
                        val = "";
                    }
                }
                {
                    size_t vl = strlen(val);
                    if (o + vl >= cap) vl = cap - o - 1;
                    memcpy(out + o, val, vl);
                    o += vl;
                }
                i = (size_t)(end - in) + 1;
                continue;
            }
        }
        if (!in_sq && in[i] == '$' && (isalnum((unsigned char)in[i + 1]) || in[i + 1] == '_' || in[i + 1] == '?' || in[i + 1] == '#')) {
            char key[64], nbuf[32];
            size_t kl = 0;
            size_t k = i + 1;
            const char *val;
            if (in[k] == '?' || in[k] == '#' || isdigit((unsigned char)in[k])) {
                key[0] = in[k++];
                key[1] = '\0';
            } else {
                while ((isalnum((unsigned char)in[k]) || in[k] == '_') && kl + 1 < sizeof(key)) {
                    key[kl++] = in[k++];
                }
                key[kl] = '\0';
            }
            val = sh_get(st, key, nbuf);
            if (!val) val = "";
            {
                size_t vl = strlen(val);
                if (o + vl >= cap) vl = cap - o - 1;
                memcpy(out + o, val, vl);
                o += vl;
            }
            i = k;
            continue;
        }
        out[o++] = in[i++];
    }
    out[o] = '\0';
}

static int tokenize_stage(const char *stage, char argv_buf[MAX_STAGE_ARGV][512], char *argv_ptrs[MAX_STAGE_ARGV], char *in_file, char *out_file, int *append_out) {
    int argc = 0;
    size_t i = 0;
    in_file[0] = '\0';
    out_file[0] = '\0';
    *append_out = 0;

    while (stage[i] && argc + 1 < MAX_STAGE_ARGV) {
        while (stage[i] == ' ' || stage[i] == '\t' || stage[i] == '\r' || stage[i] == '\n') i++;
        if (!stage[i]) break;

        if ((stage[i] == '<' || stage[i] == '>') || (stage[i] == '2' && stage[i + 1] == '>')) {
            int is_in = (stage[i] == '<');
            int app = 0;
            size_t fpos = 0;
            char target[512];
            if (stage[i] == '2' && stage[i + 1] == '>' && stage[i + 2] == '&' && stage[i + 3] == '1') {
                i += 4;
                continue;
            }
            if (stage[i] == '2') i++;
            i++;
            if (!is_in && stage[i] == '>') {
                app = 1;
                i++;
            }
            while (stage[i] == ' ' || stage[i] == '\t') i++;
            while (stage[i] && stage[i] != ' ' && stage[i] != '\t' && fpos + 1 < sizeof(target)) {
                if (stage[i] == '\'' || stage[i] == '"') {
                    char q = stage[i++];
                    while (stage[i] && stage[i] != q && fpos + 1 < sizeof(target)) target[fpos++] = stage[i++];
                    if (stage[i] == q) i++;
                } else {
                    target[fpos++] = stage[i++];
                }
            }
            target[fpos] = '\0';
            if (is_in) sh_copy(in_file, 512, target);
            else if (strcmp(target, "/dev/null") != 0) {
                sh_copy(out_file, 512, target);
                *append_out = app;
            }
            continue;
        }

        {
            size_t o = 0;
            while (stage[i] && stage[i] != ' ' && stage[i] != '\t' && stage[i] != '<' && stage[i] != '>' && o + 1 < 512) {
                if (stage[i] == '\'' || stage[i] == '"') {
                    char q = stage[i++];
                    while (stage[i] && stage[i] != q && o + 1 < 512) {
                        if (q == '"' && stage[i] == '\\' && stage[i + 1]) i++;
                        argv_buf[argc][o++] = stage[i++];
                    }
                    if (stage[i] == q) i++;
                } else if (stage[i] == '\\' && stage[i + 1]) {
                    i++;
                    argv_buf[argc][o++] = stage[i++];
                } else {
                    argv_buf[argc][o++] = stage[i++];
                }
            }
            argv_buf[argc][o] = '\0';
            argv_ptrs[argc] = argv_buf[argc];
            argc++;
        }
    }
    argv_ptrs[argc] = NULL;
    return argc;
}

static int eval_builtin_or_spawn(ShState *st, int argc, char **argv) {
    struct stat sb;
    if (argc == 0) return 0;

    if (strcmp(argv[0], "true") == 0 || strcmp(argv[0], ":") == 0) return 0;
    if (strcmp(argv[0], "false") == 0) return 1;
    if (strcmp(argv[0], "cd") == 0) {
        const char *d = (argc >= 2) ? argv[1] : (getenv("HOME") ? getenv("HOME") : ".");
        return (SH_CHDIR(d) == 0) ? 0 : 1;
    }
    if (strcmp(argv[0], "pwd") == 0) {
        char cwd[512];
        if (SH_GETCWD(cwd, sizeof(cwd)) != NULL) {
            printf("%s\n", cwd);
            fflush(stdout);
            return 0;
        }
        return 1;
    }
    if (strcmp(argv[0], "echo") == 0) {
        int i;
        for (i = 1; i < argc; i++) {
            if (i > 1) putchar(' ');
            fputs(argv[i], stdout);
        }
        putchar('\n');
        fflush(stdout);
        return 0;
    }
    if (strcmp(argv[0], "printf") == 0) {
        if (argc >= 2) {
            const char *fmt = argv[1];
            int ai = 2;
            size_t k;
            for (k = 0; fmt[k]; k++) {
                if (fmt[k] == '\\' && fmt[k + 1] == 'n') {
                    putchar('\n');
                    k++;
                } else if (fmt[k] == '\\' && fmt[k + 1] == 't') {
                    putchar('\t');
                    k++;
                } else if (fmt[k] == '%' && fmt[k + 1] == 's') {
                    if (ai < argc) fputs(argv[ai++], stdout);
                    k++;
                } else {
                    putchar(fmt[k]);
                }
            }
            fflush(stdout);
        }
        return 0;
    }
    if (strcmp(argv[0], "export") == 0) {
        int i;
        for (i = 1; i < argc; i++) {
            char *eq = strchr(argv[i], '=');
            if (eq) {
                char k[64];
                size_t kl = (size_t)(eq - argv[i]);
                if (kl >= sizeof(k)) kl = sizeof(k) - 1;
                memcpy(k, argv[i], kl);
                k[kl] = '\0';
                sh_set(st, k, eq + 1, 1);
            } else {
                char nbuf[32];
                const char *v = sh_get(st, argv[i], nbuf);
                sh_set(st, argv[i], v ? v : "", 1);
            }
        }
        return 0;
    }
    if (strcmp(argv[0], "set") == 0) {
        int i;
        for (i = 1; i < argc; i++) {
            if (argv[i][0] == '-') {
                const char *f = argv[i] + 1;
                while (*f) {
                    if (*f == 'e') st->opt_errexit = 1;
                    else if (*f == 'u') st->opt_nounset = 1;
                    f++;
                }
            }
        }
        return 0;
    }
    if (strcmp(argv[0], "exit") == 0) {
        int rc = (argc >= 2) ? atoi(argv[1]) : st->last_status;
        st->last_status = rc;
        st->exit_requested = 1;
        return rc;
    }
    if (strcmp(argv[0], "[") == 0 || strcmp(argv[0], "test") == 0) {
        int end = argc;
        int neg = 0;
        int idx = 1;
        int res = 0;
        if (strcmp(argv[0], "[") == 0 && end > 1 && strcmp(argv[end - 1], "]") == 0) end--;
        if (idx < end && strcmp(argv[idx], "!") == 0) {
            neg = 1;
            idx++;
        }
        if (end - idx == 1) {
            res = (argv[idx][0] != '\0');
        } else if (end - idx == 2) {
            const char *op = argv[idx];
            const char *arg = argv[idx + 1];
            if (strcmp(op, "-n") == 0) res = (arg[0] != '\0');
            else if (strcmp(op, "-z") == 0) res = (arg[0] == '\0');
            else if (strcmp(op, "-f") == 0) res = (stat(arg, &sb) == 0 && S_ISREG(sb.st_mode));
            else if (strcmp(op, "-d") == 0) res = (stat(arg, &sb) == 0 && S_ISDIR(sb.st_mode));
            else if (strcmp(op, "-e") == 0) res = (stat(arg, &sb) == 0);
            else if (strcmp(op, "-s") == 0) res = (stat(arg, &sb) == 0 && sb.st_size > 0);
        } else if (end - idx >= 3) {
            const char *a = argv[idx];
            const char *op = argv[idx + 1];
            const char *b = argv[idx + 2];
            if (strcmp(op, "=") == 0 || strcmp(op, "==") == 0) res = (strcmp(a, b) == 0);
            else if (strcmp(op, "!=") == 0) res = (strcmp(a, b) != 0);
            else if (strcmp(op, "-eq") == 0) res = (atoi(a) == atoi(b));
            else if (strcmp(op, "-ne") == 0) res = (atoi(a) != atoi(b));
            else if (strcmp(op, "-lt") == 0) res = (atoi(a) < atoi(b));
            else if (strcmp(op, "-le") == 0) res = (atoi(a) <= atoi(b));
            else if (strcmp(op, "-gt") == 0) res = (atoi(a) > atoi(b));
            else if (strcmp(op, "-ge") == 0) res = (atoi(a) >= atoi(b));
        }
        if (neg) res = !res;
        return res ? 0 : 1;
    }

#if SH_HAS_SPAWNVP
    {
        int rc = spawnvp(SH_SPAWN_WAIT, argv[0], (const char *const *)argv);
        return (rc < 0) ? 127 : rc;
    }
#else
    {
        pid_t pid = fork();
        if (pid < 0) return 127;
        if (pid == 0) {
            execvp(argv[0], argv);
            _exit(127);
        }
        {
            int wstatus = 0;
            if (waitpid(pid, &wstatus, 0) < 0) return 1;
            if (WIFEXITED(wstatus)) return WEXITSTATUS(wstatus);
            return 1;
        }
    }
#endif
}

static int exec_pipeline_spawnvp(ShState *st, const char *pipeline) {
    char stages[MAX_STAGES][1024];
    int nstages = 0;
    size_t i = 0, start = 0;
    int in_sq = 0, in_dq = 0;
    char prev_tmp[256];
    char next_tmp[256];
    int s;
    int rc = 0;

    prev_tmp[0] = '\0';
    for (i = 0;; i++) {
        char c = pipeline[i];
        if (c == '\'' && !in_dq) in_sq = !in_sq;
        else if (c == '"' && !in_sq) in_dq = !in_dq;
        if (!in_sq && !in_dq && (c == '|' || c == '\0')) {
            size_t slen = i - start;
            if (nstages < MAX_STAGES) {
                if (slen >= sizeof(stages[0])) slen = sizeof(stages[0]) - 1;
                memcpy(stages[nstages], pipeline + start, slen);
                stages[nstages][slen] = '\0';
                nstages++;
            }
            if (c == '\0') break;
            start = i + 1;
        }
    }

    for (s = 0; s < nstages; s++) {
        char argv_buf[MAX_STAGE_ARGV][512];
        char *argv_ptrs[MAX_STAGE_ARGV];
        char in_file[512], out_file[512];
        int append_out = 0;
        int argc;
        int saved_in = -1, saved_out = -1;

        if (nstages == 1) {
            const char *trimmed = stages[0];
            const char *eq;
            while (*trimmed == ' ' || *trimmed == '\t') trimmed++;
            eq = strchr(trimmed, '=');
            if (eq && eq > trimmed) {
                int valid_name = isalpha((unsigned char)trimmed[0]) || trimmed[0] == '_';
                const char *p;
                for (p = trimmed; valid_name && p < eq; p++) {
                    if (!isalnum((unsigned char)*p) && *p != '_') valid_name = 0;
                }
                if (valid_name && strchr(trimmed, ' ') == NULL) {
                    char k[64], v[1024];
                    size_t kl = (size_t)(eq - trimmed);
                    if (kl >= sizeof(k)) kl = sizeof(k) - 1;
                    memcpy(k, trimmed, kl);
                    k[kl] = '\0';
                    argc = tokenize_stage(eq + 1, argv_buf, argv_ptrs, in_file, out_file, &append_out);
                    sh_copy(v, sizeof(v), (argc >= 1) ? argv_buf[0] : "");
                    sh_set(st, k, v, 0);
                    st->last_status = 0;
                    return 0;
                }
            }
        }

        argc = tokenize_stage(stages[s], argv_buf, argv_ptrs, in_file, out_file, &append_out);
        next_tmp[0] = '\0';
        if (s + 1 < nstages) {
            sh_make_tmp(st, next_tmp, sizeof(next_tmp));
        }

        fflush(stdout);
        if (prev_tmp[0] != '\0' || in_file[0] != '\0') {
            const char *src_in = (in_file[0] != '\0') ? in_file : prev_tmp;
            int fd_in = SH_OPEN(src_in, O_RDONLY, 0);
            if (fd_in >= 0) {
                saved_in = SH_DUP(0);
                SH_DUP2(fd_in, 0);
                SH_CLOSE(fd_in);
            }
        }
        if (next_tmp[0] != '\0' || out_file[0] != '\0') {
            const char *dst_out = (out_file[0] != '\0') ? out_file : next_tmp;
            int flags = O_WRONLY | O_CREAT | ((out_file[0] != '\0' && append_out) ? O_APPEND : O_TRUNC);
            int fd_out = SH_OPEN(dst_out, flags, 0644);
            if (fd_out >= 0) {
                saved_out = SH_DUP(1);
                SH_DUP2(fd_out, 1);
                SH_CLOSE(fd_out);
            }
        }

        rc = eval_builtin_or_spawn(st, argc, argv_ptrs);
        fflush(stdout);

        if (saved_in >= 0) {
            SH_DUP2(saved_in, 0);
            SH_CLOSE(saved_in);
        }
        if (saved_out >= 0) {
            SH_DUP2(saved_out, 1);
            SH_CLOSE(saved_out);
        }
        if (prev_tmp[0] != '\0') {
            SH_UNLINK(prev_tmp);
            prev_tmp[0] = '\0';
        }
        if (next_tmp[0] != '\0') {
            sh_copy(prev_tmp, sizeof(prev_tmp), next_tmp);
        }
    }

    st->last_status = rc;
    return rc;
}

static int sh_eval_line(ShState *st, const char *raw) {
    char clean[MAX_CMD_LEN];
    size_t i = 0, seg_start = 0;
    int in_sq = 0, in_dq = 0;
    int pending_op = 0;

    for (i = 0; raw[i] && i + 1 < sizeof(clean); i++) {
        if (raw[i] == '\'' && !in_dq) in_sq = !in_sq;
        else if (raw[i] == '"' && !in_sq) in_dq = !in_dq;
        else if (!in_sq && !in_dq && raw[i] == '#' && (i == 0 || isspace((unsigned char)raw[i - 1]))) {
            break;
        }
        clean[i] = raw[i];
    }
    clean[i] = '\0';

    in_sq = 0;
    in_dq = 0;
    for (i = 0;; i++) {
        char c = clean[i];
        int is_sep = 0;
        int next_op = 0;
        size_t adv = 0;

        if (c == '\'' && !in_dq) in_sq = !in_sq;
        else if (c == '"' && !in_sq) in_dq = !in_dq;

        if (!in_sq && !in_dq) {
            if (c == '\0' || c == ';') {
                is_sep = 1;
                next_op = 0;
                adv = 1;
            } else if (c == '&' && clean[i + 1] == '&') {
                is_sep = 1;
                next_op = 1;
                adv = 2;
            } else if (c == '|' && clean[i + 1] == '|') {
                is_sep = 1;
                next_op = 2;
                adv = 2;
            }
        }
        if (is_sep) {
            char seg[MAX_CMD_LEN];
            char exp[MAX_CMD_LEN];
            size_t slen = i - seg_start;
            if (slen >= sizeof(seg)) slen = sizeof(seg) - 1;
            memcpy(seg, clean + seg_start, slen);
            seg[slen] = '\0';

            if (pending_op == 0 || (pending_op == 1 && st->last_status == 0) || (pending_op == 2 && st->last_status != 0)) {
                const char *sp = seg;
                while (*sp == ' ' || *sp == '\t' || *sp == '\r' || *sp == '\n') sp++;
                if (*sp != '\0') {
                    sh_expand(st, sp, exp, sizeof(exp));
                    if (st->exit_requested) return st->last_status;
                    exec_pipeline_spawnvp(st, exp);
                    if (st->exit_requested) return st->last_status;
                    if (st->opt_errexit && st->last_status != 0 && next_op == 0 && c == '\0') {
                        st->exit_requested = 1;
                        return st->last_status;
                    }
                }
            }
            if (c == '\0') break;
            pending_op = next_op;
            i += adv - 1;
            seg_start = i + 1;
        }
    }
    return st->last_status;
}

static int sh_run_stream(ShState *st, FILE *fp) {
    char line[MAX_CMD_LEN];
    while (!st->exit_requested && fgets(line, sizeof(line), fp) != NULL) {
        size_t l = strlen(line);
        while (l > 0 && (line[l - 1] == '\r' || line[l - 1] == '\n')) line[--l] = '\0';
        sh_eval_line(st, line);
    }
    return st->last_status;
}

int main(int argc, char **argv) {
    ShState *st = (ShState *)calloc(1, sizeof(ShState));
    int rc = 0;
    int i;

    if (!st) return 1;
    sh_copy(st->argv0, sizeof(st->argv0), argv[0]);

    if (argc >= 2 && (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-V") == 0)) {
        printf("dash-dos32 0.5.12 (LibScript spawnvp pipeline shell)\n");
        free(st);
        return 0;
    }
    if (argc >= 3 && strcmp(argv[1], "-c") == 0) {
        if (argc >= 4) sh_copy(st->argv0, sizeof(st->argv0), argv[3]);
        for (i = 4; i < argc && st->pos_count < 32; i++) {
            sh_copy(st->pos_args[st->pos_count++], sizeof(st->pos_args[0]), argv[i]);
        }
        rc = sh_eval_line(st, argv[2]);
        free(st);
        return rc;
    }
    if (argc >= 2) {
        FILE *fp = fopen(argv[1], "r");
        if (!fp) {
            fprintf(stderr, "sh: cannot open %s\n", argv[1]);
            free(st);
            return 127;
        }
        sh_copy(st->argv0, sizeof(st->argv0), argv[1]);
        for (i = 2; i < argc && st->pos_count < 32; i++) {
            sh_copy(st->pos_args[st->pos_count++], sizeof(st->pos_args[0]), argv[i]);
        }
        rc = sh_run_stream(st, fp);
        fclose(fp);
        free(st);
        return rc;
    }

    rc = sh_run_stream(st, stdin);
    free(st);
    return rc;
}
