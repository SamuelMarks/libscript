/*
 * ## Overview
 * Zero-PowerShell Win32 C89 UAC privilege elevation helper (`ls-elevate.exe`).
 * Invokes ShellExecuteExW("runas") with SEE_MASK_NOCLOSEPROCESS and propagates
 * the elevated process exit status.
 *
 * ## Usage
 * ls-elevate <command> [args...]
 */

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <shellapi.h>
#ifdef _MSC_VER
#pragma comment(lib, "kernel32.lib")
#pragma comment(lib, "shell32.lib")
#endif
#else
#include <unistd.h>
#endif

#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    if (argc < 2 || argv[1][0] == '\0') {
        fprintf(stderr, "Usage: ls-elevate <command> [args...]\n");
        return 1;
    }
#ifdef _WIN32
    {
        wchar_t wfile[MAX_PATH];
        wchar_t wparams[4096];
        SHELLEXECUTEINFOW sei;
        DWORD exit_code = 0;
        int i;

        if (MultiByteToWideChar(CP_UTF8, 0, argv[1], -1, wfile, MAX_PATH) <= 0) {
            return 1;
        }
        wparams[0] = L'\0';
        for (i = 2; i < argc; i++) {
            wchar_t warg[1024];
            if (MultiByteToWideChar(CP_UTF8, 0, argv[i], -1, warg, 1024) <= 0) {
                continue;
            }
            if (i > 2 && wcslen(wparams) + 2 < 4095) {
                wcscat(wparams, L" ");
            }
            if (wcschr(warg, L' ') != NULL || wcschr(warg, L'\t') != NULL) {
                if (wcslen(wparams) + wcslen(warg) + 4 < 4095) {
                    wcscat(wparams, L"\"");
                    wcscat(wparams, warg);
                    wcscat(wparams, L"\"");
                }
            } else if (wcslen(wparams) + wcslen(warg) + 2 < 4095) {
                wcscat(wparams, warg);
            }
        }

        memset(&sei, 0, sizeof(sei));
        sei.cbSize = (DWORD)sizeof(sei);
        sei.fMask = SEE_MASK_NOCLOSEPROCESS;
        sei.lpVerb = L"runas";
        sei.lpFile = wfile;
        sei.lpParameters = (wparams[0] != L'\0') ? wparams : NULL;
        sei.nShow = SW_HIDE;

        if (!ShellExecuteExW(&sei)) {
            return 1;
        }
        if (sei.hProcess != NULL) {
            WaitForSingleObject(sei.hProcess, INFINITE);
            if (!GetExitCodeProcess(sei.hProcess, &exit_code)) {
                exit_code = 1;
            }
            CloseHandle(sei.hProcess);
        }
        return (int)exit_code;
    }
#else
    execvp(argv[1], &argv[1]);
    return 127;
#endif
}
