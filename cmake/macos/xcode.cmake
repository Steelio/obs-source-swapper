# CMake macOS Xcode module

include_guard(GLOBAL)

set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

# Use a compiler wrapper to enable ccache in Xcode projects
if(ENABLE_CCACHE AND CCACHE_PROGRAM)
  configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/macos/resources/ccache-launcher-c.in" ccache-launcher-c)
  configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/macos/resources/ccache-launcher-cxx.in" ccache-launcher-cxx)

  execute_process(
    COMMAND chmod a+rx "${CMAKE_CURRENT_BINARY_DIR}/ccache-launcher-c" "${CMAKE_CURRENT_BINARY_DIR}/ccache-launcher-cxx"
  )
  set(CMAKE_XCODE_ATTRIBUTE_CC "${CMAKE_CURRENT_BINARY_DIR}/ccache-launcher-c")
  set(CMAKE_XCODE_ATTRIBUTE_CXX "${CMAKE_CURRENT_BINARY_DIR}/ccache-launcher-cxx")
  set(CMAKE_XCODE_ATTRIBUTE_LD "${CMAKE_C_COMPILER}")
  set(CMAKE_XCODE_ATTRIBUTE_LDPLUSPLUS "${CMAKE_CXX_COMPILER}")
endif()

# Set project variables
set(CMAKE_XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION ${PLUGIN_BUILD_NUMBER})
set(CMAKE_XCODE_ATTRIBUTE_DYLIB_COMPATIBILITY_VERSION 1.0.0)
set(CMAKE_XCODE_ATTRIBUTE_MARKETING_VERSION ${PLUGIN_VERSION})

# Set deployment target
set(CMAKE_XCODE_ATTRIBUTE_MACOSX_DEPLOYMENT_TARGET ${CMAKE_OSX_DEPLOYMENT_TARGET})

if(NOT CODESIGN_TEAM)
  # Switch to manual codesigning if no codesigning team is provided
  set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE Manual)
  set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${CODESIGN_IDENTITY}")
else()
  if(CODESIGN_IDENTITY AND NOT CODESIGN_IDENTITY STREQUAL "-")
    # Switch to manual codesigning if a non-adhoc codesigning identity is provided
    set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE Manual)
    set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${CODESIGN_IDENTITY}")
  else()
    # Switch to automatic codesigning via valid team ID
    set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE Automatic)
    set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Apple Development")
  endif()
  set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${CODESIGN_TEAM}")
endif()

# Only create a single Xcode project file
set(CMAKE_XCODE_GENERATE_TOP_LEVEL_PROJECT_ONLY TRUE)
# Add all libraries to project link phase (lets Xcode handle linking)
set(CMAKE_XCODE_LINK_BUILD_PHASE_MODE KNOWN_LOCATION)

# Enable codesigning with secure timestamp when not in Debug configuration (required for Notarization)
set(CMAKE_XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS[variant=Release] "--timestamp")
set(CMAKE_XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS[variant=RelWithDebInfo] "--timestamp")
set(CMAKE_XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS[variant=MinSizeRel] "--timestamp")

# Enable codesigning with hardened runtime option when not in Debug configuration (required for Notarization)
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME[variant=Release] YES)
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME[variant=RelWithDebInfo] YES)
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME[variant=MinSizeRel] YES)

# Disable injection of Xcode's base entitlements used for debugging when not in Debug configuration (required for
# Notarization)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_INJECT_BASE_ENTITLEMENTS[variant=Release] NO)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_INJECT_BASE_ENTITLEMENTS[variant=RelWithDebInfo] NO)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_INJECT_BASE_ENTITLEMENTS[variant=MinSizeRel] NO)

# Use Swift version 5.0 by default
set(CMAKE_XCODE_ATTRIBUTE_SWIFT_VERSION 5.0)

# Use DWARF with separate dSYM files when in Release or MinSizeRel configuration.
#
# * Currently overruled by CMake's Xcode generator, requires adding '-g' flag to raw compiler command line for desired
#   output configuration. Report to KitWare.
#
set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Debug] dwarf)
set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=RelWithDebInfo] dwarf)
set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=Release] dwarf-with-dsym)
set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT[variant=MinSizeRel] dwarf-with-dsym)

# Make all symbols hidden by default (currently overriden by CMake's compiler flags)
set(CMAKE_XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_INLINES_ARE_PRIVATE_EXTERN YES)

# Strip unused code
set(CMAKE_XCODE_ATTRIBUTE_DEAD_CODE_STRIPPING YES)

# Build active architecture only in Debug configuration
set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH[variant=Debug] YES)

# Enable testability in Debug configuration
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_TESTABILITY[variant=Debug] YES)

# Enable using ARC in ObjC by default
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES)
# Enable weak references in manual retain release
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_WEAK YES)
# Disable strict aliasing
set(CMAKE_XCODE_ATTRIBUTE_GCC_STRICT_ALIASING NO)

# Set C++ language default to c17
#
# * CMake explicitly sets the version via compiler flag when transitive dependencies require specific compiler feature
#   set, resulting in the flag being added twice. Report to KitWare as a feature request for Xcode generator
# * See also: https://gitlab.kitware.com/cmake/cmake/-/issues/17183
#
# set(CMAKE_XCODE_ATTRIBUTE_GCC_C_LANGUAGE_STANDARD c17)
#
# Set C++ language default to c++17
#
# * See above. Report to KitWare as a feature request for Xcode generator
#
# set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD c++17)

# Enable support for module imports in ObjC
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES YES)
# Enable automatic linking of imported modules in ObjC
set(CMAKE_XCODE_ATTRIBUTE_CLANG_MODULES_AUTOLINK YES)
# Enable strict msg_send rules for ObjC
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_STRICT_OBJC_MSGSEND YES)

# Set default warnings for ObjC and C++
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING YES_ERROR)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_BOOL_CONVERSION YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_COMMA YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_CONSTANT_CONVERSION YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_EMPTY_BODY YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_ENUM_CONVERSION YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_INFINITE_RECURSION YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_INT_CONVERSION YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_NON_LITERAL_NULL_CONVERSION YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_OBJC_LITERAL_CONVERSION YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_OBJC_REPEATED_USE_OF_WEAK YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_RANGE_LOOP_ANALYSIS YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_STRICT_PROTOTYPES NO)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_SUSPICIOUS_IMPLICIT_CONVERSION NO)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_SUSPICIOUS_MOVE YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN_UNREACHABLE_CODE YES)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_WARN__DUPLICATE_METHOD_MATCH YES)

# Set default warnings for C and C++
set(CMAKE_XCODE_ATTRIBUTE_GCC_NO_COMMON_BLOCKS YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_64_TO_32_BIT_CONVERSION YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_ABOUT_MISSING_FIELD_INITIALIZERS NO)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_ABOUT_MISSING_NEWLINE YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_ABOUT_RETURN_TYPE YES_ERROR)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_CHECK_SWITCH_STATEMENTS YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_FOUR_CHARACTER_CONSTANTS YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_SHADOW NO)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_SIGN_COMPARE YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_TYPECHECK_CALLS_TO_PRINTF YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_UNDECLARED_SELECTOR YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_UNINITIALIZED_AUTOS YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_UNUSED_FUNCTION NO)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_UNUSED_PARAMETER YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_UNUSED_VALUE YES)
set(CMAKE_XCODE_ATTRIBUTE_GCC_WARN_UNUSED_VARIABLE YES)

# Add additional warning compiler flags
set(CMAKE_XCODE_ATTRIBUTE_WARNING_CFLAGS "-Wvla -Wformat-security")

if(CMAKE_COMPILE_WARNING_AS_ERROR)
  set(CMAKE_XCODE_ATTRIBUTE_GCC_TREAT_WARNINGS_AS_ERRORS YES)
endif()

# Enable color diagnostics
set(CMAKE_COLOR_DIAGNOSTICS TRUE)

# Disable usage of RPATH in build or install configurations
set(CMAKE_SKIP_RPATH TRUE)
# Have Xcode set default RPATH entries
set(CMAKE_XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "@executable_path/../Frameworks")
