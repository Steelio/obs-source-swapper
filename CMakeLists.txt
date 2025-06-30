cmake_minimum_required(VERSION 3.28...3.30)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/bootstrap.cmake" NO_POLICY_SCOPE)

project(${_name} VERSION ${_version})

# Force-enable frontend API (required for obs_frontend_get_current_scene)
set(ENABLE_FRONTEND_API ON)

# Optional Qt UI support
option(ENABLE_QT "Use Qt functionality" OFF)

include(compilerconfig)
include(defaults)
include(helpers)

add_library(${CMAKE_PROJECT_NAME} MODULE)

# Required OBS core library
find_package(libobs REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::libobs)

# Required frontend API (for obs_frontend_get_current_scene, etc.)
find_package(obs-frontend-api REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::obs-frontend-api)

# Optional Qt GUI linking
if(ENABLE_QT)
  find_package(Qt6 COMPONENTS Widgets Core REQUIRED)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Core Qt6::Widgets)
  target_compile_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE $<$<C_COMPILER_ID:Clang,AppleClang>:-Wno-quoted-include-in-framework-header -Wno-comma>
  )
  set_target_properties(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON
  )
endif()

# Windows-specific: ensure keyboard functions like GetAsyncKeyState work
if(WIN32)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE user32)
endif()

# Source files
target_sources(${CMAKE_PROJECT_NAME} PRIVATE src/plugin-main.c)

# Generated support file
configure_file(src/plugin-support.c.in src/plugin-support.c)
target_sources(${CMAKE_PROJECT_NAME} PRIVATE src/plugin-support.c)

# Set proper output name from obs plugin metadata
set_target_properties_plugin(${CMAKE_PROJECT_NAME} PROPERTIES OUTPUT_NAME ${_name})
