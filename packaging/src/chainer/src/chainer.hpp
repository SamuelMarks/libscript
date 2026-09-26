/**
 * @file chainer.hpp
 * @brief Custom action DLL declarations for modular MSI package chaining and transaction management.
 *
 * Implements transaction management, child MSI payload extraction, service detection,
 * and orchestration for composite installers without external runtime dependencies.
 */

#ifndef LIBSCRIPT_MSI_CHAINER_HPP
#define LIBSCRIPT_MSI_CHAINER_HPP

#if defined(_WIN32) || defined(__CYGWIN__)
  #include <windef.h>
  #include <winbase.h>
  #include <winerror.h>
  #include <msi.h>
  #include <msiquery.h>
  #define LIBSCRIPT_EXPORT __declspec(dllexport)
#else
  #include <cstdint>
  typedef uintptr_t MSIHANDLE;
  typedef uint32_t UINT;
  #define LIBSCRIPT_EXPORT __attribute__((visibility("default")))
  #define __stdcall
  #define ERROR_SUCCESS 0
  #define ERROR_INSTALL_FAILURE 1603
  #define INSTALLSTATE_DEFAULT 5
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Main entrypoint orchestrating sub-package chain execution.
 *
 * Detects installed components, extracts nested MSIs, and executes atomic transaction installs.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on success, ERROR_INSTALL_FAILURE on failure.
 */
LIBSCRIPT_EXPORT UINT __stdcall LibScriptChainer(MSIHANDLE hInstall);

/**
 * @brief Detects presence and health of required services before transaction execution.
 *
 * Checks Windows Service Control Manager or socket endpoints for dependent daemons.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on success, ERROR_INSTALL_FAILURE on failure.
 */
LIBSCRIPT_EXPORT UINT __stdcall LibScriptDetectServices(MSIHANDLE hInstall);

/**
 * @brief Extracts embedded child MSI payloads to temporary staging directories.
 *
 * Unpacks nested component MSIs from binary tables or embedded streams for subsequent installation.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on success, ERROR_INSTALL_FAILURE on failure.
 */
LIBSCRIPT_EXPORT UINT __stdcall LibScriptExtractChildPackages(MSIHANDLE hInstall);

/**
 * @brief Executes child MSI transaction batch installation.
 *
 * Invokes MsiInstallProduct or transaction API across staged sub-packages sequentially.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on success, ERROR_INSTALL_FAILURE on failure.
 */
LIBSCRIPT_EXPORT UINT __stdcall LibScriptExecuteTransaction(MSIHANDLE hInstall);

#ifdef __cplusplus
}
#endif

#endif // LIBSCRIPT_MSI_CHAINER_HPP
