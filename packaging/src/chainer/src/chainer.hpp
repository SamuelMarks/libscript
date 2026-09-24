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

LIBSCRIPT_EXPORT UINT __stdcall LibScriptChainer(MSIHANDLE hInstall);
LIBSCRIPT_EXPORT UINT __stdcall LibScriptDetectServices(MSIHANDLE hInstall);
LIBSCRIPT_EXPORT UINT __stdcall LibScriptExtractChildPackages(MSIHANDLE hInstall);
LIBSCRIPT_EXPORT UINT __stdcall LibScriptExecuteTransaction(MSIHANDLE hInstall);

#ifdef __cplusplus
}
#endif

#endif // LIBSCRIPT_MSI_CHAINER_HPP
