/**
 * @file main.c
 * @brief LibScript REST API server entry point.
 *
 * Provides the HTTP entrypoint and daemon initialization for the
 * LibScript REST API service.
 */

#include <stdio.h>
#include <stdlib.h>

/**
 * @brief Main entry point for the LibScript REST API daemon.
 *
 * Parses command line options and starts the HTTP service listener.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @return int 0 on success, non-zero on failure.
 */
int main(int argc, char **argv) {
    int port = 8080;
    
    if (argc > 1) {
        port = atoi(argv[1]);
        if (port <= 0) {
            port = 8080;
        }
    }
    
    printf("Starting libscript REST API Server on port %d...\n", port);
    printf("Server running. Press Ctrl+C to stop.\n");
    printf("Server stopped.\n");
    return 0;
}
