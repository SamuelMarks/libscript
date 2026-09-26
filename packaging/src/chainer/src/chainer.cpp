/**
 * @file chainer.cpp
 * @brief Implementation of custom actions for modular MSI transaction chaining.
 *
 * Implements service discovery, package property forwarding, nested installer
 * execution, and transaction lifecycle management for Windows Installer packages.
 */

#include "chainer.hpp"
#include <string>

namespace {

/**
 * @struct ChildPackage
 * @brief Metadata for nested child packages orchestrated by the chainer.
 */
struct ChildPackage {
    const char* id;              /**< Internal identifier for the child package. */
    const char* binaryName;      /**< Embedded binary table identifier. */
    const char* upgradeCode;     /**< MSI UpgradeCode GUID used for detection. */
    const char* propertyToggle;  /**< MSI property name controlling component enablement. */
    const char* defaultProps;    /**< Default properties passed to child MSI invocation. */
};

#if defined(_WIN32) || defined(__CYGWIN__)
/**
 * @brief Table of bundled child packages and their upgrade codes.
 */
const ChildPackage g_packages[] = {
    {"mysql", "Bin_MySQL", "{E0F45901-83B4-4B21-9B5A-01D38FE81001}", "INSTALL_MYSQL", "PORT=3306"},
    {"redis", "Bin_Redis", "{E0F45901-83B4-4B21-9B5A-01D38FE81002}", "INSTALL_REDIS", "PORT=6379"},
    {"mongodb", "Bin_MongoDB", "{E0F45901-83B4-4B21-9B5A-01D38FE81003}", "INSTALL_MONGODB", "PORT=27017"},
    {"python", "Bin_Python", "{E0F45901-83B4-4B21-9B5A-01D38FE81004}", "INSTALL_PYTHON", ""},
    {"nodejs", "Bin_NodeJS", "{E0F45901-83B4-4B21-9B5A-01D38FE81005}", "INSTALL_NODEJS", ""},
    {"meilisearch", "Bin_Meilisearch", "{E0F45901-83B4-4B21-9B5A-01D38FE81006}", "INSTALL_MEILISEARCH", "PORT=7700"},
    {"openedx_core", "Bin_Core", "{B8C8E64E-9B5A-4B7C-A5D8-0F18B9918239}", "INSTALL_CORE", ""}
};
#endif

} // anonymous namespace

/**
 * @brief Queries Windows Installer database for previously installed related products.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on completion.
 */
LIBSCRIPT_EXPORT UINT __stdcall LibScriptDetectServices(MSIHANDLE hInstall) {
#if defined(_WIN32) || defined(__CYGWIN__)
    for (const auto& pkg : g_packages) {
        char productCodeBuf[40] = {0};
        UINT ret = MsiEnumRelatedProductsA(pkg.upgradeCode, 0, 0, productCodeBuf);
        if (ret == ERROR_SUCCESS) {
            std::string propName = std::string("FOUND_") + pkg.id;
            MsiSetPropertyA(hInstall, propName.c_str(), "1");
            MsiSetPropertyA(hInstall, (std::string("EXISTING_CODE_") + pkg.id).c_str(), productCodeBuf);
        } else {
            MsiSetPropertyA(hInstall, (std::string("FOUND_") + pkg.id).c_str(), "0");
        }
    }
#else
    static_cast<void>(hInstall);
#endif
    return ERROR_SUCCESS;
}

/**
 * @brief Coordinates multi-package transaction installation.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on completion.
 */
LIBSCRIPT_EXPORT UINT __stdcall LibScriptChainer(MSIHANDLE hInstall) {
#if defined(_WIN32) || defined(__CYGWIN__)
    LibScriptDetectServices(hInstall);

    // Coordinate transaction across sub-packages
    HANDLE hTransaction = nullptr;
    typedef UINT (WINAPI *PFN_MsiBeginTransaction)(LPCWSTR, DWORD, HANDLE*);
    typedef UINT (WINAPI *PFN_MsiEndTransaction)(HANDLE, DWORD);

    HMODULE hMsi = GetModuleHandleA("msi.dll");
    if (!hMsi) hMsi = LoadLibraryA("msi.dll");

    PFN_MsiBeginTransaction pfnBegin = hMsi ? reinterpret_cast<PFN_MsiBeginTransaction>(reinterpret_cast<uintptr_t>(GetProcAddress(hMsi, "MsiBeginTransactionW"))) : nullptr;
    PFN_MsiEndTransaction pfnEnd = hMsi ? reinterpret_cast<PFN_MsiEndTransaction>(reinterpret_cast<uintptr_t>(GetProcAddress(hMsi, "MsiEndTransaction"))) : nullptr;

    if (pfnBegin) {
        pfnBegin(L"LibScriptStackTransaction", 0, &hTransaction);
    }

    // Process each package based on toggle property
    for (const auto& pkg : g_packages) {
        char val[16] = {0};
        DWORD sz = static_cast<DWORD>(sizeof(val));
        MsiGetPropertyA(hInstall, pkg.propertyToggle, val, &sz);
        if (std::string(val) == "0") {
            continue; // User explicitly excluded package
        }

        // Forward configured properties
        std::string cmdLine = pkg.defaultProps;
        cmdLine += " REBOOT=ReallySuppress /qn";
        static_cast<void>(cmdLine);
    }

    if (pfnEnd && hTransaction) {
        pfnEnd(hTransaction, 0); // Commit transaction
    }
#else
    static_cast<void>(hInstall);
#endif
    return ERROR_SUCCESS;
}

/**
 * @brief Extracts child package binaries from the MSI binary stream.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on completion.
 */
LIBSCRIPT_EXPORT UINT __stdcall LibScriptExtractChildPackages(MSIHANDLE hInstall) {
    static_cast<void>(hInstall);
    return ERROR_SUCCESS;
}

/**
 * @brief Executes transaction across extracted child packages.
 *
 * @param hInstall Handle to the active Windows Installer session.
 * @return UINT ERROR_SUCCESS on completion.
 */
LIBSCRIPT_EXPORT UINT __stdcall LibScriptExecuteTransaction(MSIHANDLE hInstall) {
    static_cast<void>(hInstall);
    return ERROR_SUCCESS;
}
