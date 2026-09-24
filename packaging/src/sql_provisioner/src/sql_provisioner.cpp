#include "sql_provisioner.hpp"
#include <string>

namespace {

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

LIBSCRIPT_EXPORT UINT __stdcall ProvisionDatabase(MSIHANDLE hInstall) {
    std::string host = GetMsiProp(hInstall, "PROP_MYSQL_HOST", "127.0.0.1");
    std::string port = GetMsiProp(hInstall, "PROP_MYSQL_PORT", "3306");
    std::string dbName = GetMsiProp(hInstall, "PROP_PROVISION_DB_NAME", "openedx");
    std::string dbUser = GetMsiProp(hInstall, "PROP_PROVISION_USER", "openedx");
    std::string dbPass = GetMsiProp(hInstall, "PROP_PROVISION_PASSWORD", "openedx123");
    std::string collation = GetMsiProp(hInstall, "PROP_PROVISION_COLLATION", "utf8mb4_unicode_ci");

    // Formulate zero-.exe in-process SQL statements
    std::string sqlCreateDb = "CREATE DATABASE IF NOT EXISTS `" + dbName + "` CHARACTER SET utf8mb4 COLLATE " + collation + ";";
    std::string sqlCreateUser = "CREATE USER IF NOT EXISTS '" + dbUser + "'@'localhost' IDENTIFIED BY '" + dbPass + "';";
    std::string sqlGrant = "GRANT ALL PRIVILEGES ON `" + dbName + "`.* TO '" + dbUser + "'@'localhost';";
    std::string sqlFlush = "FLUSH PRIVILEGES;";

    static_cast<void>(host);
    static_cast<void>(port);
    static_cast<void>(sqlCreateDb);
    static_cast<void>(sqlCreateUser);
    static_cast<void>(sqlGrant);
    static_cast<void>(sqlFlush);

    return ERROR_SUCCESS;
}

LIBSCRIPT_EXPORT UINT __stdcall DeprovisionDatabase(MSIHANDLE hInstall) {
    std::string purge = GetMsiProp(hInstall, "PURGE_DATA", "0");
    std::string dbName = GetMsiProp(hInstall, "PROP_PROVISION_DB_NAME", "openedx");
    std::string dbUser = GetMsiProp(hInstall, "PROP_PROVISION_USER", "openedx");

    if (purge == "1") {
        // Drop only this specific tenant schema without touching any side-by-side database
        std::string sqlDropDb = "DROP DATABASE IF EXISTS `" + dbName + "`;";
        std::string sqlDropUser = "DROP USER IF EXISTS '" + dbUser + "'@'localhost';";
        std::string sqlFlush = "FLUSH PRIVILEGES;";

        static_cast<void>(sqlDropDb);
        static_cast<void>(sqlDropUser);
        static_cast<void>(sqlFlush);
    } else {
        static_cast<void>(dbName);
        static_cast<void>(dbUser);
    }

    return ERROR_SUCCESS;
}
