#include "chainer.hpp"
#include <string>

namespace {

struct ChildPackage {
    const char* id;
    const char* binaryName;
    const char* upgradeCode;
    const char* propertyToggle;
    const char* defaultProps;
};

#if defined(_WIN32) || defined(__CYGWIN__)
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

LIBSCRIPT_EXPORT UINT __stdcall LibScriptExtractChildPackages(MSIHANDLE hInstall) {
    static_cast<void>(hInstall);
    return ERROR_SUCCESS;
}

LIBSCRIPT_EXPORT UINT __stdcall LibScriptExecuteTransaction(MSIHANDLE hInstall) {
    static_cast<void>(hInstall);
    return ERROR_SUCCESS;
}
