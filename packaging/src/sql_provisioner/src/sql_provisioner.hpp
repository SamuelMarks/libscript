/**
 * @file sql_provisioner.hpp
 * @brief Custom action DLL declarations for in-process SQL database provisioning.
 *
 * Provides entry points invoked during Windows Installer execution to provision
 * and deprovision relational database instances without spawning external shell processes.
 */

#ifndef LIBSCRIPT_SQL_PROVISIONER_HPP
#define LIBSCRIPT_SQL_PROVISIONER_HPP

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
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Provisions database and credentials during MSI installation.
 *
 * Reads database parameters from MSI properties (e.g. host, port, database name,
 * username, password, and collation) and executes SQL setup in-process.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on successful provisioning, ERROR_INSTALL_FAILURE on error.
 */
LIBSCRIPT_EXPORT UINT __stdcall ProvisionDatabase(MSIHANDLE hInstall);

/**
 * @brief Deprovisions database and users during MSI uninstallation or rollback.
 *
 * Inspects uninstallation properties and conditionally removes tenant schema
 * and credentials if purge options are requested.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on successful deprovisioning, ERROR_INSTALL_FAILURE on error.
 */
LIBSCRIPT_EXPORT UINT __stdcall DeprovisionDatabase(MSIHANDLE hInstall);

#ifdef __cplusplus
}
#endif

#endif // LIBSCRIPT_SQL_PROVISIONER_HPP
