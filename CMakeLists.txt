# ======================================================================
#  larsoft main build file
#
#  cd .../path/to/build/directory
#  source .../path/to/larsoft/ups/setup_for_development <-d|-p>
#  cmake [-DCMAKE_INSTALL_PREFIX=/install/path]
#        -DCMAKE_BUILD_TYPE=$CETPKG_TYPE
#        $CETPKG_SOURCE
#  make
#  make test
#  make install
#  make package (builds distribution tarfile)
# ======================================================================

cmake_minimum_required(VERSION 3.20 FATAL_ERROR) ### MIGRATE-CHANGED (migrate-3.22.02) - VERSION 3.19 -> 3.20
# cmake_policy(VERSION 3.19) ### MIGRATE-ACTION-COMPATIBILITY (migrate-3.22.02) - Uncomment to preserve compatibility with older CMake versions

find_package(cetmodules REQUIRED) ### MIGRATE-ADDED (migrate-3.22.02) - find_package(cetmodules) must precede project()
project(duneutil LANGUAGES CXX C)
set(${PROJECT_NAME}_CMAKE_PROJECT_VERSION_STRING 09.83.01d00)


# cetbuildtools contains our cmake modules

find_package(canvas_root_io)

include(CetCMakeEnv)
cet_cmake_env()

cet_set_compiler_flags(DIAGS CAUTIOUS
  WERROR
  NO_UNDEFINED
  EXTRA_FLAGS -pedantic
)

cet_report_compiler_flags() ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - add args: REPORT_THRESHOLD VERBOSE

# these are minimum required versions, not the actual product versions
find_package( art 1.08.00 REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(art v1_08_00 ...) -> find_package(art 1.08.00 REQUIRED ...)
find_package( art_root_io REQUIRED ) ### MIGRATE-CHANGED (migrate-3.22.02) - find_ups_product(art_root_io ...) -> find_package(art_root_io REQUIRED ...)



# macros for dictionary and simple_plugin
include(ArtDictionary)
include(ArtMake)
include(BuildPlugins)

# ADD SOURCE CODE SUBDIRECTORIES HERE

# subdirectory for test code
add_subdirectory(test)

# ups - table and config files

# XML project files.
add_subdirectory(xml)

# Scripts and utilities.
add_subdirectory(scripts)

# Python modules.
add_subdirectory(python)

# packaging utility

# Scripts and utilities.
add_subdirectory(dhtools)

cet_cmake_config() ### MIGRATE-ADDED (migrate-3.22.02) - required cmd
