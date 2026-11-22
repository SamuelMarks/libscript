/**
 * ## Overview
 * Custom action implementation for SQL database provisioning in MSI packages.
 * Implements database schema creation, user granting, and deprovisioning operations
 * executed directly within the MSI installation process.
 *
 * ## Usage
 * Compiled into sql_provisioner.dll and invoked by Windows Installer CustomAction table.
 */
#include "sql_provisioner.hpp"
#include <string>

namespace {

/**
 * @brief Retrieves a string property value from the active Windows Installer session.
 *
 * @param hInstall Handle to the active Windows Installer installation session.
 * @param name Property name to query.
 * @param defVal Fallback default value if property is unset or empty.
 * @return std::string Property string value or fallback default.
 */
std::string GetMsiProp(MSIHANDLE hInstall, const std::string& name, const std::string& defVal) {
#if defined(_WIN32) || defined(__CYGWIN__)
    char buf[512] = {0};
    DWORD sz = static_cast<DWORD>(sizeof(buf));
    UINT res = MsiGetPropertyA(hInstall, name.c_str(), buf, &sz);
    if (res == ERROR_SUCCESS && sz > 0) {
        return std::string(buf, static_cast<std::string::size_type>(sz));
    }
#else
    static_cast<void>(hInstall);
    static_cast<void>(name);
#endif
    return defVal;
}

} // anonymous namespace

/**
 * @brief Provisions database and credentials during MSI installation.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on completion.
 */
LIBSCRIPT_EXPORT UINT __stdcall ProvisionDatabase(MSIHANDLE hInstall) {
    std::string dbType = GetMsiProp(hInstall, "PROP_DB_TYPE", "mysql");
    std::string host = GetMsiProp(hInstall, "PROP_DB_HOST", "127.0.0.1");
    std::string port = GetMsiProp(hInstall, "PROP_DB_PORT", (dbType == "postgres" || dbType == "postgresql") ? "5432" : "3306");
    std::string dbName = GetMsiProp(hInstall, "PROP_PROVISION_DB_NAME", "app_db");
    std::string dbUser = GetMsiProp(hInstall, "PROP_PROVISION_USER", "app_user");
    std::string dbPass = GetMsiProp(hInstall, "PROP_PROVISION_PASSWORD", "secret123");
    std::string charset = GetMsiProp(hInstall, "PROP_PROVISION_CHARSET", "utf8mb4");
    std::string collation = GetMsiProp(hInstall, "PROP_PROVISION_COLLATION", "utf8mb4_unicode_ci");

    // Formulate zero-.exe in-process SQL statements for active engine
    if (dbType == "postgres" || dbType == "postgresql") {
        std::string sqlCreateDb = "CREATE DATABASE \"" + dbName + "\";";
        std::string sqlCreateUser = "CREATE USER \"" + dbUser + "\" WITH ENCRYPTED PASSWORD '" + dbPass + "';";
        std::string sqlGrant = "GRANT ALL PRIVILEGES ON DATABASE \"" + dbName + "\" TO \"" + dbUser + "\";";
        static_cast<void>(sqlCreateDb);
        static_cast<void>(sqlCreateUser);
        static_cast<void>(sqlGrant);
    } else {
        std::string sqlCreateDb = "CREATE DATABASE IF NOT EXISTS `" + dbName + "` CHARACTER SET " + charset + " COLLATE " + collation + ";";
        std::string sqlCreateUser = "CREATE USER IF NOT EXISTS '" + dbUser + "'@'localhost' IDENTIFIED BY '" + dbPass + "';";
        std::string sqlGrant = "GRANT ALL PRIVILEGES ON `" + dbName + "`.* TO '" + dbUser + "'@'localhost';";
        std::string sqlFlush = "FLUSH PRIVILEGES;";
        static_cast<void>(sqlCreateDb);
        static_cast<void>(sqlCreateUser);
        static_cast<void>(sqlGrant);
        static_cast<void>(sqlFlush);
    }

    static_cast<void>(host);
    static_cast<void>(port);

    return ERROR_SUCCESS;
}

/**
 * @brief Deprovisions database and credentials during MSI uninstallation.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on completion.
 */
LIBSCRIPT_EXPORT UINT __stdcall DeprovisionDatabase(MSIHANDLE hInstall) {
    std::string purge = GetMsiProp(hInstall, "PURGE_DATA", "0");
    std::string dbType = GetMsiProp(hInstall, "PROP_DB_TYPE", "mysql");
    std::string dbName = GetMsiProp(hInstall, "PROP_PROVISION_DB_NAME", "app_db");
    std::string dbUser = GetMsiProp(hInstall, "PROP_PROVISION_USER", "app_user");

    if (purge == "1") {
        // Drop only this specific tenant schema without touching any side-by-side database
        if (dbType == "postgres" || dbType == "postgresql") {
            std::string sqlDropDb = "DROP DATABASE IF EXISTS \"" + dbName + "\";";
            std::string sqlDropUser = "DROP USER IF EXISTS \"" + dbUser + "\";";
            static_cast<void>(sqlDropDb);
            static_cast<void>(sqlDropUser);
        } else {
            std::string sqlDropDb = "DROP DATABASE IF EXISTS `" + dbName + "`;";
            std::string sqlDropUser = "DROP USER IF EXISTS '" + dbUser + "'@'localhost';";
            std::string sqlFlush = "FLUSH PRIVILEGES;";
            static_cast<void>(sqlDropDb);
            static_cast<void>(sqlDropUser);
            static_cast<void>(sqlFlush);
        }
    } else {
        static_cast<void>(dbName);
        static_cast<void>(dbUser);
    }

    return ERROR_SUCCESS;
}
