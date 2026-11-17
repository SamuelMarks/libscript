/*
 * ## Overview
 * Portable ANSI C89 Windows NT Batch (.cmd / .bat) interpreter subset for 32-bit MS-DOS
 * (`dos32` via OpenWatcom `wcl386` + `DOS32A.EXE`) and POSIX/Win32 verification hosts.
 * Bridges MS-DOS `COMMAND.COM` gaps: `setlocal EnableDelayedExpansion`, `!VAR!`, `%VAR:~s,l%`,
 * `%VAR:old=new%`, `%~f0`/`%~dp0`/`%~nx0`, `call :label`, `for /f`, and `exit /b <code>`.
 *
 * ## Usage
 * wincmd [/c] <script.cmd> [args...]
 * wincmd /c "<command string>"
 */

#if !defined(_WIN32) && !defined(__DOS__) && !defined(__MSDOS__) && !defined(_MSDOS)
#define _POSIX_C_SOURCE 200809L
#endif

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#if defined(_WIN32)
#include <direct.h>
#include <io.h>
#include <process.h>
#define LS_CHDIR _chdir
#define LS_GETCWD _getcwd
#define LS_MKDIR(p) _mkdir(p)
#define LS_RMDIR _rmdir
#define LS_UNLINK _unlink
#define LS_SEP '\\'
#elif defined(__DOS__) || defined(__MSDOS__) || defined(_MSDOS)
#include <direct.h>
#include <io.h>
#include <process.h>
#define LS_CHDIR chdir
#define LS_GETCWD getcwd
#define LS_MKDIR(p) mkdir(p)
#define LS_RMDIR rmdir
#define LS_UNLINK unlink
#define LS_SEP '\\'
#else
#include <unistd.h>
#define LS_CHDIR chdir
#define LS_GETCWD getcwd
#define LS_MKDIR(p) mkdir((p), 0755)
#define LS_RMDIR rmdir
#define LS_UNLINK unlink
#define LS_SEP '/'
#endif

#define MAX_VARS 256
#define MAX_LINES 2048
#define MAX_SCOPES 16
#define MAX_ARGS 32
#define MAX_LINE_LEN 2048

typedef struct {
    char name[64];
    char value[1024];
} EnvEntry;

typedef struct {
    EnvEntry vars[MAX_VARS];
    int count;
    int delayed;
} Scope;

typedef struct {
    Scope scopes[MAX_SCOPES];
    int depth;
    int errorlevel;
    int exit_flag;
    int exit_script_only;
    char script_path[512];
    char args[MAX_ARGS][512];
    int argc;
    unsigned int rng_state;
} Interp;

static int ci_cmp(const char *a, const char *b) {
    while (*a && *b) {
        int ca = tolower((unsigned char)*a);
        int cb = tolower((unsigned char)*b);
        if (ca != cb) return ca - cb;
        a++;
        b++;
    }
    return tolower((unsigned char)*a) - tolower((unsigned char)*b);
}

static int ci_ncmp(const char *a, const char *b, size_t n) {
    size_t i;
    for (i = 0; i < n; i++) {
        int ca = tolower((unsigned char)a[i]);
        int cb = tolower((unsigned char)b[i]);
        if (ca != cb || a[i] == '\0' || b[i] == '\0') return ca - cb;
    }
    return 0;
}

static void str_copy(char *dst, size_t cap, const char *src) {
    size_t len;
    if (cap == 0) return;
    len = strlen(src);
    if (len >= cap) len = cap - 1;
    memcpy(dst, src, len);
    dst[len] = '\0';
}

static const char *get_var(Interp *st, const char *name, char *dyn_buf, size_t dyn_cap) {
    Scope *sc = &st->scopes[st->depth];
    int i;
    const char *sys;
    if (ci_cmp(name, "ERRORLEVEL") == 0) {
        sprintf(dyn_buf, "%d", st->errorlevel);
        return dyn_buf;
    }
    if (ci_cmp(name, "CD") == 0) {
        if (LS_GETCWD(dyn_buf, (int)dyn_cap) != NULL) return dyn_buf;
        return ".";
    }
    if (ci_cmp(name, "RANDOM") == 0) {
        st->rng_state = st->rng_state * 1103515245u + 12345u;
        sprintf(dyn_buf, "%u", (st->rng_state >> 16) & 32767u);
        return dyn_buf;
    }
    for (i = 0; i < sc->count; i++) {
        if (ci_cmp(sc->vars[i].name, name) == 0) return sc->vars[i].value;
    }
    sys = getenv(name);
    return sys ? sys : "";
}

static int is_var_defined(Interp *st, const char *name) {
    Scope *sc = &st->scopes[st->depth];
    int i;
    const char *sys;
    for (i = 0; i < sc->count; i++) {
        if (ci_cmp(sc->vars[i].name, name) == 0) return sc->vars[i].value[0] != '\0';
    }
    sys = getenv(name);
    return (sys != NULL && sys[0] != '\0') ? 1 : 0;
}

static void set_var(Interp *st, const char *name, const char *val) {
    Scope *sc = &st->scopes[st->depth];
    int i;
    for (i = 0; i < sc->count; i++) {
        if (ci_cmp(sc->vars[i].name, name) == 0) {
            str_copy(sc->vars[i].value, sizeof(sc->vars[i].value), val ? val : "");
            return;
        }
    }
    if (sc->count < MAX_VARS) {
        str_copy(sc->vars[sc->count].name, sizeof(sc->vars[0].name), name);
        str_copy(sc->vars[sc->count].value, sizeof(sc->vars[0].value), val ? val : "");
        sc->count++;
    }
}

static void strip_quotes(const char *in, char *out, size_t cap) {
    size_t len = strlen(in);
    if (len >= 2 && in[0] == '"' && in[len - 1] == '"') {
        if (len - 2 >= cap) len = cap + 1;
        memcpy(out, in + 1, len - 2);
        out[len - 2] = '\0';
    } else {
        str_copy(out, cap, in);
    }
}

static void format_arg_tilde(const char *raw_val, const char *mods, char *out, size_t cap) {
    char clean[512];
    char full[1024];
    const char *slash;
    const char *dot;
    int want_f = 0, want_d = 0, want_p = 0, want_n = 0, want_x = 0;
    const char *m;

    strip_quotes(raw_val, clean, sizeof(clean));
    for (m = mods; *m; m++) {
        char c = (char)tolower((unsigned char)*m);
        if (c == 'f') want_f = 1;
        else if (c == 'd') want_d = 1;
        else if (c == 'p') want_p = 1;
        else if (c == 'n') want_n = 1;
        else if (c == 'x') want_x = 1;
    }
    if (!want_f && !want_d && !want_p && !want_n && !want_x) {
        str_copy(out, cap, clean);
        return;
    }
    if ((clean[0] == '/' || clean[0] == '\\') || (isalpha((unsigned char)clean[0]) && clean[1] == ':')) {
        str_copy(full, sizeof(full), clean);
    } else {
        char cwd[384];
        if (LS_GETCWD(cwd, sizeof(cwd)) == NULL) strcpy(cwd, ".");
        sprintf(full, "%s%c%s", cwd, LS_SEP, clean);
    }
    if (want_f) {
        str_copy(out, cap, full);
        return;
    }
    slash = strrchr(full, '\\');
    if (!slash || (strrchr(full, '/') && strrchr(full, '/') > slash)) slash = strrchr(full, '/');
    out[0] = '\0';
    if (want_d || want_p) {
        if (slash) {
            size_t dlen = (size_t)(slash - full + 1);
            if (dlen >= cap) dlen = cap - 1;
            memcpy(out, full, dlen);
            out[dlen] = '\0';
        }
    }
    if (want_n || want_x) {
        const char *base = slash ? (slash + 1) : full;
        dot = strrchr(base, '.');
        if (want_n && want_x) {
            strncat(out, base, cap - strlen(out) - 1);
        } else if (want_n) {
            size_t nlen = dot ? (size_t)(dot - base) : strlen(base);
            if (strlen(out) + nlen >= cap) nlen = cap - strlen(out) - 1;
            strncat(out, base, nlen);
        } else if (want_x && dot) {
            strncat(out, dot, cap - strlen(out) - 1);
        }
    }
}

static void apply_var_expr(Interp *st, const char *expr, char *out, size_t cap) {
    const char *colon = strchr(expr, ':');
    char vname[64];
    char dyn[512];
    const char *val;

    if (!colon) {
        val = get_var(st, expr, dyn, sizeof(dyn));
        str_copy(out, cap, val);
        return;
    }
    {
        size_t nlen = (size_t)(colon - expr);
        if (nlen >= sizeof(vname)) nlen = sizeof(vname) - 1;
        memcpy(vname, expr, nlen);
        vname[nlen] = '\0';
    }
    val = get_var(st, vname, dyn, sizeof(dyn));
    colon++;
    if (*colon == '~') {
        int vlen = (int)strlen(val);
        int start = atoi(colon + 1);
        int sublen = vlen;
        const char *comma = strchr(colon + 1, ',');
        if (start < 0) start = vlen + start;
        if (start < 0) start = 0;
        if (start > vlen) start = vlen;
        if (comma) {
            int req = atoi(comma + 1);
            if (req < 0) sublen = (vlen + req) - start;
            else sublen = req;
        } else {
            sublen = vlen - start;
        }
        if (sublen < 0) sublen = 0;
        if (start + sublen > vlen) sublen = vlen - start;
        if ((size_t)sublen >= cap) sublen = (int)cap - 1;
        memcpy(out, val + start, (size_t)sublen);
        out[sublen] = '\0';
    } else {
        const char *eq = strchr(colon, '=');
        if (!eq) {
            str_copy(out, cap, val);
        } else {
            char needle[128];
            const char *repl = eq + 1;
            size_t nlen = (size_t)(eq - colon);
            size_t pos = 0;
            const char *p = val;
            if (nlen >= sizeof(needle)) nlen = sizeof(needle) - 1;
            memcpy(needle, colon, nlen);
            needle[nlen] = '\0';
            if (nlen == 0) {
                str_copy(out, cap, val);
                return;
            }
            while (*p && pos + 1 < cap) {
                if (ci_ncmp(p, needle, nlen) == 0) {
                    size_t rlen = strlen(repl);
                    if (pos + rlen >= cap) rlen = cap - pos - 1;
                    memcpy(out + pos, repl, rlen);
                    pos += rlen;
                    p += nlen;
                } else {
                    out[pos++] = *p++;
                }
            }
            out[pos] = '\0';
        }
    }
}

static void expand_line(Interp *st, const char *src, char *dst, size_t cap, char delim, char for_var, const char *for_val) {
    size_t o = 0;
    size_t i = 0;
    while (src[i] && o + 1 < cap) {
        if (delim == '%' && src[i] == '^' && src[i + 1]) {
            dst[o++] = src[i + 1];
            i += 2;
            continue;
        }
        if (src[i] == delim) {
            if (delim == '%' && src[i + 1] == '%') {
                if (for_var != '\0' && src[i + 2] == for_var) {
                    size_t fl = strlen(for_val);
                    if (o + fl >= cap) fl = cap - o - 1;
                    memcpy(dst + o, for_val, fl);
                    o += fl;
                    i += 3;
                    continue;
                }
                dst[o++] = '%';
                i += 2;
                continue;
            }
            if (delim == '%' && src[i + 1] == '*') {
                int a;
                for (a = 1; a < st->argc; a++) {
                    size_t al = strlen(st->args[a]);
                    if (a > 1 && o + 1 < cap) dst[o++] = ' ';
                    if (o + al >= cap) al = cap - o - 1;
                    memcpy(dst + o, st->args[a], al);
                    o += al;
                }
                i += 2;
                continue;
            }
            if (delim == '%' && (src[i + 1] == '~' || isdigit((unsigned char)src[i + 1]))) {
                char mods[16];
                size_t mi = 0;
                size_t k = i + 1;
                if (src[k] == '~') {
                    k++;
                    while (src[k] && !isdigit((unsigned char)src[k]) && src[k] != for_var && mi + 1 < sizeof(mods)) {
                        mods[mi++] = src[k++];
                    }
                    mods[mi] = '\0';
                    if (for_var != '\0' && src[k] == for_var) {
                        char fbuf[512];
                        size_t fl;
                        format_arg_tilde(for_val, mods, fbuf, sizeof(fbuf));
                        fl = strlen(fbuf);
                        if (o + fl >= cap) fl = cap - o - 1;
                        memcpy(dst + o, fbuf, fl);
                        o += fl;
                        i = k + 1;
                        continue;
                    }
                    if (isdigit((unsigned char)src[k])) {
                        int idx = src[k] - '0';
                        const char *raw = (idx == 0) ? st->script_path : ((idx < st->argc) ? st->args[idx] : "");
                        char fbuf[512];
                        size_t fl;
                        format_arg_tilde(raw, mods, fbuf, sizeof(fbuf));
                        fl = strlen(fbuf);
                        if (o + fl >= cap) fl = cap - o - 1;
                        memcpy(dst + o, fbuf, fl);
                        o += fl;
                        i = k + 1;
                        continue;
                    }
                } else if (isdigit((unsigned char)src[k])) {
                    int idx = src[k] - '0';
                    const char *raw = (idx == 0) ? st->script_path : ((idx < st->argc) ? st->args[idx] : "");
                    size_t rl = strlen(raw);
                    if (o + rl >= cap) rl = cap - o - 1;
                    memcpy(dst + o, raw, rl);
                    o += rl;
                    i = k + 1;
                    continue;
                }
            }
            {
                const char *end = strchr(src + i + 1, delim);
                if (end && end > src + i + 1 && (size_t)(end - (src + i + 1)) < 128) {
                    char expr[128];
                    char val[1024];
                    size_t elen = (size_t)(end - (src + i + 1));
                    size_t vl;
                    memcpy(expr, src + i + 1, elen);
                    expr[elen] = '\0';
                    apply_var_expr(st, expr, val, sizeof(val));
                    vl = strlen(val);
                    if (o + vl >= cap) vl = cap - o - 1;
                    memcpy(dst + o, val, vl);
                    o += vl;
                    i = (size_t)(end - src) + 1;
                    continue;
                }
            }
        }
        dst[o++] = src[i++];
    }
    dst[o] = '\0';
}

static const char *skip_ws(const char *s) {
    while (*s == ' ' || *s == '\t' || *s == '\r' || *s == '\n') s++;
    return s;
}

static const char *next_token(const char *s, char *tok, size_t cap) {
    size_t o = 0;
    int in_q = 0;
    s = skip_ws(s);
    while (*s && (in_q || (*s != ' ' && *s != '\t' && *s != '\r' && *s != '\n'))) {
        if (*s == '"') in_q = !in_q;
        if (o + 1 < cap) tok[o++] = *s;
        s++;
    }
    tok[o] = '\0';
    return s;
}

static int file_exists_any(const char *raw) {
    char p[512];
    struct stat sb;
    strip_quotes(raw, p, sizeof(p));
    return (stat(p, &sb) == 0) ? 1 : 0;
}

static int exec_single_command(Interp *st, char **lines, int line_count, int *pc, const char *raw_cmd, char for_var, const char *for_val);

static int run_script_lines(Interp *st, char **lines, int count, int start_idx) {
    int pc = start_idx;
    while (pc < count && !st->exit_flag) {
        const char *raw = skip_ws(lines[pc]);
        if (*raw == '@') raw = skip_ws(raw + 1);
        if (*raw == '\0' || *raw == ':' || ci_ncmp(raw, "rem ", 4) == 0 || ci_cmp(raw, "rem") == 0) {
            pc++;
            continue;
        }
        exec_single_command(st, lines, count, &pc, raw, '\0', "");
    }
    return st->errorlevel;
}

static int find_label(char **lines, int count, const char *label) {
    int i;
    if (*label == ':') label++;
    for (i = 0; i < count; i++) {
        const char *p = skip_ws(lines[i]);
        if (*p == ':' && p[1] != ':') {
            char lname[128];
            next_token(p + 1, lname, sizeof(lname));
            if (ci_cmp(lname, label) == 0) return i;
        }
    }
    return -1;
}

static int run_script_file(Interp *parent, const char *path, int argc, char **argv) {
    FILE *fp = fopen(path, "r");
    char *lines[MAX_LINES];
    int count = 0;
    char buf[MAX_LINE_LEN];
    int saved_argc;
    char saved_args[MAX_ARGS][512];
    char saved_path[512];
    int saved_exit_script;
    int i, rc;

    if (!fp) {
        parent->errorlevel = 1;
        return 1;
    }
    while (count < MAX_LINES && fgets(buf, sizeof(buf), fp) != NULL) {
        size_t l = strlen(buf);
        while (l > 0 && (buf[l - 1] == '\r' || buf[l - 1] == '\n')) buf[--l] = '\0';
        lines[count] = (char *)malloc(l + 1);
        if (!lines[count]) break;
        memcpy(lines[count], buf, l + 1);
        count++;
    }
    fclose(fp);

    saved_argc = parent->argc;
    memcpy(saved_args, parent->args, sizeof(saved_args));
    str_copy(saved_path, sizeof(saved_path), parent->script_path);
    saved_exit_script = parent->exit_script_only;

    str_copy(parent->script_path, sizeof(parent->script_path), path);
    parent->argc = (argc > MAX_ARGS) ? MAX_ARGS : argc;
    for (i = 0; i < parent->argc; i++) {
        str_copy(parent->args[i], sizeof(parent->args[0]), argv[i]);
    }
    parent->exit_script_only = 0;

    rc = run_script_lines(parent, lines, count, 0);
    if (parent->exit_script_only) {
        parent->exit_flag = 0;
        parent->exit_script_only = 0;
    }

    parent->argc = saved_argc;
    memcpy(parent->args, saved_args, sizeof(saved_args));
    str_copy(parent->script_path, sizeof(parent->script_path), saved_path);
    parent->exit_script_only = saved_exit_script;

    for (i = 0; i < count; i++) free(lines[i]);
    return rc;
}

static int exec_single_command(Interp *st, char **lines, int line_count, int *pc, const char *raw_cmd, char for_var, const char *for_val) {
    char pass1[MAX_LINE_LEN];
    char exp[MAX_LINE_LEN];
    const char *p;
    char cmd[128];
    const char *rest;

    expand_line(st, raw_cmd, pass1, sizeof(pass1), '%', for_var, for_val);
    if (st->scopes[st->depth].delayed) {
        expand_line(st, pass1, exp, sizeof(exp), '!', '\0', "");
    } else {
        str_copy(exp, sizeof(exp), pass1);
    }

    {
        int in_q = 0;
        size_t k;
        for (k = 0; exp[k]; k++) {
            if (exp[k] == '"') in_q = !in_q;
            else if (!in_q && exp[k] == '&') {
                char left[MAX_LINE_LEN];
                int mode = 0;
                const char *rhs;
                if (exp[k + 1] == '&') {
                    mode = 1;
                    rhs = exp + k + 2;
                } else if (k > 0 && exp[k - 1] == '>') {
                    continue;
                } else {
                    rhs = exp + k + 1;
                }
                memcpy(left, exp, k);
                left[k] = '\0';
                exec_single_command(st, lines, line_count, pc, left, for_var, for_val);
                if (st->exit_flag) return st->errorlevel;
                if (mode == 0 || (mode == 1 && st->errorlevel == 0)) {
                    int dummy_pc = *pc;
                    exec_single_command(st, lines, line_count, &dummy_pc, rhs, for_var, for_val);
                    if (dummy_pc != *pc + 1) *pc = dummy_pc;
                }
                return st->errorlevel;
            } else if (!in_q && exp[k] == '|' && exp[k + 1] == '|') {
                char left[MAX_LINE_LEN];
                const char *rhs = exp + k + 2;
                memcpy(left, exp, k);
                left[k] = '\0';
                exec_single_command(st, lines, line_count, pc, left, for_var, for_val);
                if (st->exit_flag) return st->errorlevel;
                if (st->errorlevel != 0) {
                    int dummy_pc = *pc;
                    exec_single_command(st, lines, line_count, &dummy_pc, rhs, for_var, for_val);
                    if (dummy_pc != *pc + 1) *pc = dummy_pc;
                }
                return st->errorlevel;
            }
        }
    }

    p = skip_ws(exp);
    if (*p == '@') p = skip_ws(p + 1);
    if (*p == '\0') {
        (*pc)++;
        return st->errorlevel;
    }

    if (ci_ncmp(p, "echo.", 5) == 0) {
        printf("%s\n", p + 5);
        st->errorlevel = 0;
        (*pc)++;
        return 0;
    }

    rest = next_token(p, cmd, sizeof(cmd));

    if (ci_cmp(cmd, "setlocal") == 0) {
        if (st->depth + 1 < MAX_SCOPES) {
            st->scopes[st->depth + 1] = st->scopes[st->depth];
            st->depth++;
            if (strstr(rest, "EnableDelayedExpansion") || strstr(rest, "enabledelayedexpansion")) {
                st->scopes[st->depth].delayed = 1;
            } else if (strstr(rest, "DisableDelayedExpansion") || strstr(rest, "disabledelayedexpansion")) {
                st->scopes[st->depth].delayed = 0;
            }
        }
        st->errorlevel = 0;
        (*pc)++;
        return 0;
    }
    if (ci_cmp(cmd, "endlocal") == 0) {
        if (st->depth > 0) st->depth--;
        st->errorlevel = 0;
        (*pc)++;
        return 0;
    }
    if (ci_cmp(cmd, "echo") == 0) {
        const char *msg = (*rest == ' ') ? (rest + 1) : skip_ws(rest);
        char clean_msg[MAX_LINE_LEN];
        const char *redir = NULL;
        int append = 0;
        int in_q = 0;
        size_t idx;
        if (ci_cmp(skip_ws(rest), "off") == 0 || ci_cmp(skip_ws(rest), "on") == 0) {
            (*pc)++;
            return 0;
        }
        str_copy(clean_msg, sizeof(clean_msg), msg);
        for (idx = 0; clean_msg[idx]; idx++) {
            if (clean_msg[idx] == '"') in_q = !in_q;
            else if (!in_q && clean_msg[idx] == '>' && (idx == 0 || (clean_msg[idx - 1] != '1' && clean_msg[idx - 1] != '2'))) {
                clean_msg[idx] = '\0';
                if (clean_msg[idx + 1] == '>') {
                    append = 1;
                    redir = skip_ws(clean_msg + idx + 2);
                } else {
                    redir = skip_ws(clean_msg + idx + 1);
                }
                break;
            }
        }
        while (strlen(clean_msg) > 0 && clean_msg[strlen(clean_msg) - 1] == ' ') {
            clean_msg[strlen(clean_msg) - 1] = '\0';
        }
        if (redir) {
            char ftok[512], fpath[512];
            FILE *rf;
            next_token(redir, ftok, sizeof(ftok));
            strip_quotes(ftok, fpath, sizeof(fpath));
            if (ci_cmp(fpath, "nul") != 0 && strcmp(fpath, "/dev/null") != 0) {
                rf = fopen(fpath, append ? "a" : "w");
                if (rf) {
                    fprintf(rf, "%s\n", clean_msg);
                    fclose(rf);
                }
            }
        } else {
            printf("%s\n", clean_msg);
        }
        st->errorlevel = 0;
        (*pc)++;
        return 0;
    }
    if (ci_cmp(cmd, "set") == 0) {
        const char *sarg = skip_ws(rest);
        char assign[MAX_LINE_LEN];
        char *eq;
        if (ci_ncmp(sarg, "/a ", 3) == 0) {
            char expr_buf[512];
            strip_quotes(skip_ws(sarg + 3), expr_buf, sizeof(expr_buf));
            eq = strchr(expr_buf, '=');
            if (eq) {
                char lhs[64];
                int cur_val = 0;
                int rhs_val = atoi(skip_ws(eq + 1));
                char dyn[64];
                char out_num[64];
                size_t ll = (size_t)(eq - expr_buf);
                char op = '\0';
                if (ll > 0 && (expr_buf[ll - 1] == '+' || expr_buf[ll - 1] == '-' || expr_buf[ll - 1] == '*')) {
                    op = expr_buf[ll - 1];
                    ll--;
                }
                if (ll >= sizeof(lhs)) ll = sizeof(lhs) - 1;
                memcpy(lhs, expr_buf, ll);
                lhs[ll] = '\0';
                cur_val = atoi(get_var(st, lhs, dyn, sizeof(dyn)));
                if (op == '+') rhs_val = cur_val + rhs_val;
                else if (op == '-') rhs_val = cur_val - rhs_val;
                else if (op == '*') rhs_val = cur_val * rhs_val;
                sprintf(out_num, "%d", rhs_val);
                set_var(st, lhs, out_num);
            }
            st->errorlevel = 0;
            (*pc)++;
            return 0;
        }
        if (ci_ncmp(sarg, "/p ", 3) == 0) {
            char pbuf[512];
            strip_quotes(skip_ws(sarg + 3), pbuf, sizeof(pbuf));
            eq = strchr(pbuf, '=');
            if (eq) {
                char lhs[64];
                const char *lt = strchr(eq + 1, '<');
                size_t ll = (size_t)(eq - pbuf);
                if (ll >= sizeof(lhs)) ll = sizeof(lhs) - 1;
                memcpy(lhs, pbuf, ll);
                lhs[ll] = '\0';
                if (lt) {
                    char ftok[512], fpath[512], lbuf[512];
                    FILE *ifp;
                    next_token(lt + 1, ftok, sizeof(ftok));
                    strip_quotes(ftok, fpath, sizeof(fpath));
                    ifp = fopen(fpath, "r");
                    if (ifp) {
                        if (fgets(lbuf, sizeof(lbuf), ifp)) {
                            size_t rlen = strlen(lbuf);
                            while (rlen > 0 && (lbuf[rlen - 1] == '\r' || lbuf[rlen - 1] == '\n')) lbuf[--rlen] = '\0';
                            set_var(st, lhs, lbuf);
                        }
                        fclose(ifp);
                    }
                }
            }
            (*pc)++;
            return 0;
        }
        strip_quotes(sarg, assign, sizeof(assign));
        eq = strchr(assign, '=');
        if (eq) {
            *eq = '\0';
            set_var(st, assign, eq + 1);
        }
        st->errorlevel = 0;
        (*pc)++;
        return 0;
    }
    if (ci_cmp(cmd, "shift") == 0) {
        int i;
        if (st->argc > 1) {
            for (i = 1; i + 1 < st->argc; i++) {
                str_copy(st->args[i], sizeof(st->args[0]), st->args[i + 1]);
            }
            st->argc--;
        }
        (*pc)++;
        return 0;
    }
    if (ci_cmp(cmd, "goto") == 0) {
        char lbl[128];
        int target;
        next_token(rest, lbl, sizeof(lbl));
        if (ci_cmp(lbl, ":eof") == 0 || ci_cmp(lbl, "eof") == 0) {
            *pc = line_count;
            return st->errorlevel;
        }
        target = find_label(lines, line_count, lbl);
        if (target >= 0) {
            *pc = target + 1;
            return st->errorlevel;
        }
        st->errorlevel = 1;
        *pc = line_count;
        return 1;
    }
    if (ci_cmp(cmd, "exit") == 0) {
        char tok1[64], tok2[64];
        const char *r2 = next_token(rest, tok1, sizeof(tok1));
        if (ci_cmp(tok1, "/b") == 0) {
            next_token(r2, tok2, sizeof(tok2));
            if (tok2[0] != '\0') st->errorlevel = atoi(tok2);
            st->exit_flag = 1;
            st->exit_script_only = 1;
        } else {
            if (tok1[0] != '\0') st->errorlevel = atoi(tok1);
            st->exit_flag = 1;
            st->exit_script_only = 0;
        }
        return st->errorlevel;
    }
    if (ci_cmp(cmd, "call") == 0) {
        char target_tok[512], target_clean[512];
        char *sub_argv[MAX_ARGS];
        char sub_storage[MAX_ARGS][512];
        int sub_argc = 1;
        const char *ap = next_token(rest, target_tok, sizeof(target_tok));
        strip_quotes(target_tok, target_clean, sizeof(target_clean));
        str_copy(sub_storage[0], sizeof(sub_storage[0]), target_clean);
        sub_argv[0] = sub_storage[0];
        while (sub_argc < MAX_ARGS) {
            char arg_tok[512];
            ap = next_token(ap, arg_tok, sizeof(arg_tok));
            if (arg_tok[0] == '\0') break;
            strip_quotes(arg_tok, sub_storage[sub_argc], sizeof(sub_storage[0]));
            sub_argv[sub_argc] = sub_storage[sub_argc];
            sub_argc++;
        }
        if (target_clean[0] == ':' && lines != NULL) {
            int lbl_idx = find_label(lines, line_count, target_clean);
            if (lbl_idx >= 0) {
                int saved_argc = st->argc;
                char saved_args[MAX_ARGS][512];
                int i;
                memcpy(saved_args, st->args, sizeof(saved_args));
                st->argc = sub_argc;
                for (i = 0; i < sub_argc; i++) str_copy(st->args[i], sizeof(st->args[0]), sub_argv[i]);
                run_script_lines(st, lines, line_count, lbl_idx + 1);
                if (st->exit_script_only) {
                    st->exit_flag = 0;
                    st->exit_script_only = 0;
                }
                st->argc = saved_argc;
                memcpy(st->args, saved_args, sizeof(saved_args));
            } else {
                st->errorlevel = 1;
            }
        } else {
            run_script_file(st, target_clean, sub_argc, sub_argv);
        }
        (*pc)++;
        return st->errorlevel;
    }
    if (ci_cmp(cmd, "if") == 0) {
        int icase = 0, neg = 0, cond = 0;
        char t1[512], t2[512], t3[512];
        const char *rp = rest;
        rp = next_token(rp, t1, sizeof(t1));
        if (ci_cmp(t1, "/i") == 0) {
            icase = 1;
            rp = next_token(rp, t1, sizeof(t1));
        }
        if (ci_cmp(t1, "not") == 0) {
            neg = 1;
            rp = next_token(rp, t1, sizeof(t1));
        }
        if (ci_cmp(t1, "defined") == 0) {
            rp = next_token(rp, t2, sizeof(t2));
            cond = is_var_defined(st, t2);
        } else if (ci_cmp(t1, "exist") == 0) {
            rp = next_token(rp, t2, sizeof(t2));
            cond = file_exists_any(t2);
        } else if (ci_cmp(t1, "errorlevel") == 0) {
            rp = next_token(rp, t2, sizeof(t2));
            cond = (st->errorlevel >= atoi(t2)) ? 1 : 0;
        } else {
            char *eqeq = strstr(t1, "==");
            if (eqeq) {
                char lhs[256], rhs[256], cl[256], cr[256];
                size_t ll = (size_t)(eqeq - t1);
                if (ll >= sizeof(lhs)) ll = sizeof(lhs) - 1;
                memcpy(lhs, t1, ll);
                lhs[ll] = '\0';
                str_copy(rhs, sizeof(rhs), eqeq + 2);
                strip_quotes(lhs, cl, sizeof(cl));
                strip_quotes(rhs, cr, sizeof(cr));
                cond = ((icase ? ci_cmp(cl, cr) : strcmp(cl, cr)) == 0) ? 1 : 0;
            } else {
                char cl[256], cr[256];
                rp = next_token(rp, t2, sizeof(t2));
                rp = next_token(rp, t3, sizeof(t3));
                strip_quotes(t1, cl, sizeof(cl));
                strip_quotes(t3, cr, sizeof(cr));
                if (ci_cmp(t2, "equ") == 0) cond = ((icase ? ci_cmp(cl, cr) : strcmp(cl, cr)) == 0);
                else if (ci_cmp(t2, "neq") == 0) cond = ((icase ? ci_cmp(cl, cr) : strcmp(cl, cr)) != 0);
                else if (ci_cmp(t2, "lss") == 0) cond = (atoi(cl) < atoi(cr));
                else if (ci_cmp(t2, "leq") == 0) cond = (atoi(cl) <= atoi(cr));
                else if (ci_cmp(t2, "gtr") == 0) cond = (atoi(cl) > atoi(cr));
                else if (ci_cmp(t2, "geq") == 0) cond = (atoi(cl) >= atoi(cr));
            }
        }
        if (neg) cond = !cond;
        if (cond) {
            int sub_pc = *pc;
            exec_single_command(st, lines, line_count, &sub_pc, rp, for_var, for_val);
            if (sub_pc != *pc + 1) {
                *pc = sub_pc;
                return st->errorlevel;
            }
        }
        (*pc)++;
        return st->errorlevel;
    }
    if (ci_cmp(cmd, "for") == 0) {
        char tok[256];
        const char *rp = next_token(rest, tok, sizeof(tok));
        if (ci_cmp(tok, "/f") == 0) {
            char vtok[32];
            const char *lparen;
            const char *rparen;
            const char *do_kw;
            char spec[512];
            char delims[32];
            strcpy(delims, " \t");
            rp = skip_ws(rp);
            if (*rp == '"') {
                char opt_tok[256], opt_clean[256];
                const char *dp;
                rp = next_token(rp, opt_tok, sizeof(opt_tok));
                strip_quotes(opt_tok, opt_clean, sizeof(opt_clean));
                dp = strstr(opt_clean, "delims=");
                if (dp) str_copy(delims, sizeof(delims), dp + 7);
            }
            rp = next_token(rp, vtok, sizeof(vtok));
            lparen = strchr(rp, '(');
            rparen = lparen ? strchr(lparen + 1, ')') : NULL;
            if (lparen && rparen) {
                size_t slen = (size_t)(rparen - (lparen + 1));
                char fv = (vtok[0] == '%' && vtok[1] == '%') ? vtok[2] : (vtok[0] == '%' ? vtok[1] : 'A');
                do_kw = skip_ws(rparen + 1);
                if (ci_ncmp(do_kw, "do ", 3) == 0) do_kw = skip_ws(do_kw + 3);
                if (slen >= sizeof(spec)) slen = sizeof(spec) - 1;
                memcpy(spec, lparen + 1, slen);
                spec[slen] = '\0';
                if ((spec[0] == '\'' && spec[slen - 1] == '\'') || (spec[0] == '`' && spec[slen - 1] == '`')) {
                    char subcmd[512], tmpf[256], sysline[820], fline[1024];
                    FILE *tf;
                    spec[slen - 1] = '\0';
                    str_copy(subcmd, sizeof(subcmd), spec + 1);
                    sprintf(tmpf, "%s%clswcmd_%u.tmp", getenv("TEMP") ? getenv("TEMP") : "/tmp", LS_SEP, (unsigned int)++st->rng_state);
                    sprintf(sysline, "%s > \"%s\"", subcmd, tmpf);
                    (void)system(sysline);
                    tf = fopen(tmpf, "r");
                    if (tf) {
                        while (fgets(fline, sizeof(fline), tf) && !st->exit_flag) {
                            size_t rl = strlen(fline);
                            while (rl > 0 && (fline[rl - 1] == '\r' || fline[rl - 1] == '\n')) fline[--rl] = '\0';
                            if (fline[0] == '\0') continue;
                            if (delims[0] != '\0') fline[strcspn(fline, delims)] = '\0';
                            {
                                int dpc = *pc;
                                exec_single_command(st, lines, line_count, &dpc, do_kw, fv, fline);
                            }
                        }
                        fclose(tf);
                    }
                    LS_UNLINK(tmpf);
                } else {
                    char fpath[512], fline[1024];
                    FILE *tf;
                    strip_quotes(spec, fpath, sizeof(fpath));
                    tf = fopen(fpath, "r");
                    if (tf) {
                        while (fgets(fline, sizeof(fline), tf) && !st->exit_flag) {
                            size_t rl = strlen(fline);
                            while (rl > 0 && (fline[rl - 1] == '\r' || fline[rl - 1] == '\n')) fline[--rl] = '\0';
                            if (fline[0] == '\0') continue;
                            if (delims[0] != '\0') fline[strcspn(fline, delims)] = '\0';
                            {
                                int dpc = *pc;
                                exec_single_command(st, lines, line_count, &dpc, do_kw, fv, fline);
                            }
                        }
                        fclose(tf);
                    }
                }
            }
        } else {
            char fv = (tok[0] == '%' && tok[1] == '%') ? tok[2] : (tok[0] == '%' ? tok[1] : 'A');
            const char *lparen = strchr(rp, '(');
            const char *rparen = lparen ? strchr(lparen + 1, ')') : NULL;
            if (lparen && rparen) {
                char list_buf[512], item[256];
                const char *ip;
                const char *do_kw = skip_ws(rparen + 1);
                size_t slen = (size_t)(rparen - (lparen + 1));
                if (ci_ncmp(do_kw, "do ", 3) == 0) do_kw = skip_ws(do_kw + 3);
                if (slen >= sizeof(list_buf)) slen = sizeof(list_buf) - 1;
                memcpy(list_buf, lparen + 1, slen);
                list_buf[slen] = '\0';
                ip = list_buf;
                while (!st->exit_flag) {
                    int dpc = *pc;
                    ip = next_token(ip, item, sizeof(item));
                    if (item[0] == '\0') break;
                    exec_single_command(st, lines, line_count, &dpc, do_kw, fv, item);
                }
            }
        }
        (*pc)++;
        return st->errorlevel;
    }
    if (ci_cmp(cmd, "mkdir") == 0 || ci_cmp(cmd, "md") == 0) {
        char dtok[512], dpath[512];
        next_token(rest, dtok, sizeof(dtok));
        strip_quotes(dtok, dpath, sizeof(dpath));
        st->errorlevel = (LS_MKDIR(dpath) == 0 || file_exists_any(dpath)) ? 0 : 1;
        (*pc)++;
        return st->errorlevel;
    }
    if (ci_cmp(cmd, "rmdir") == 0 || ci_cmp(cmd, "rd") == 0) {
        char dtok[512], dpath[512];
        const char *rp = rest;
        while (*rp) {
            rp = next_token(rp, dtok, sizeof(dtok));
            if (dtok[0] == '/') continue;
            break;
        }
        strip_quotes(dtok, dpath, sizeof(dpath));
        st->errorlevel = (LS_RMDIR(dpath) == 0) ? 0 : 1;
        (*pc)++;
        return st->errorlevel;
    }
    if (ci_cmp(cmd, "del") == 0 || ci_cmp(cmd, "erase") == 0) {
        char ftok[512], fpath[512];
        const char *rp = rest;
        while (*rp) {
            rp = next_token(rp, ftok, sizeof(ftok));
            if (ftok[0] == '/') continue;
            break;
        }
        strip_quotes(ftok, fpath, sizeof(fpath));
        LS_UNLINK(fpath);
        st->errorlevel = 0;
        (*pc)++;
        return 0;
    }
    if (ci_cmp(cmd, "cd") == 0 || ci_cmp(cmd, "chdir") == 0) {
        char dtok[512], dpath[512];
        const char *rp = next_token(rest, dtok, sizeof(dtok));
        if (ci_cmp(dtok, "/d") == 0) next_token(rp, dtok, sizeof(dtok));
        strip_quotes(dtok, dpath, sizeof(dpath));
        st->errorlevel = (LS_CHDIR(dpath) == 0) ? 0 : 1;
        (*pc)++;
        return st->errorlevel;
    }
    if (ci_cmp(cmd, "ver") == 0) {
        printf("MS-DOS Version 6.22 (LibScript wincmd dos32)\n");
        st->errorlevel = 0;
        (*pc)++;
        return 0;
    }

    {
        int rc = system(p);
#if !defined(_WIN32) && !defined(__DOS__) && !defined(__MSDOS__) && !defined(_MSDOS)
        if (rc >= 256) rc = (rc >> 8) & 0xFF;
#endif
        st->errorlevel = rc;
    }
    (*pc)++;
    return st->errorlevel;
}

int main(int argc, char **argv) {
    Interp *st = (Interp *)calloc(1, sizeof(Interp));
    int arg_idx = 1;
    int rc = 0;

    if (!st) return 1;
    st->rng_state = 2463534242u;

    if (argc < 2) {
        fprintf(stderr, "Usage: wincmd [/c] <script.cmd | command> [args...]\n");
        free(st);
        return 1;
    }
    if (ci_cmp(argv[1], "--help") == 0 || ci_cmp(argv[1], "/?") == 0) {
        printf("LibScript wincmd C89 NT-Batch Interpreter (dos32/win32/posix)\n");
        free(st);
        return 0;
    }
    if (ci_cmp(argv[1], "/c") == 0) {
        if (argc < 3) {
            free(st);
            return 0;
        }
        arg_idx = 2;
        if (!file_exists_any(argv[2]) || strchr(argv[2], ' ') != NULL) {
            int pc = 0;
            str_copy(st->script_path, sizeof(st->script_path), argv[0]);
            rc = exec_single_command(st, NULL, 0, &pc, argv[2], '\0', "");
            free(st);
            return rc;
        }
    }

    rc = run_script_file(st, argv[arg_idx], argc - arg_idx, argv + arg_idx);
    free(st);
    return rc;
}
