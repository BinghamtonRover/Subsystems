cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "BURT_Subsystems")
project(${PROJECT_NAME} LANGUAGES C)

# ==================== Libserialport  ====================
# The following is adapted from flutter_libserialport
set(SOURCE_PATH "./libserialport")

add_library(serialport SHARED
  "${SOURCE_PATH}/serialport.c"
  "${SOURCE_PATH}/timing.c"
  "${SOURCE_PATH}/windows.c"
)

#target_compile_options(serialport PRIVATE
#  -std=c99 -Wall -Wextra -pedantic -Wmissing-prototypes -Wshadow)
target_compile_definitions(serialport PRIVATE LIBSERIALPORT_MSBUILD)
target_include_directories(serialport PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE_PATH}")
target_link_libraries(serialport PRIVATE cfgmgr32 SetupAPI)