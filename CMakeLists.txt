cmake_minimum_required(VERSION 3.5)
project(lomiri-filemanager-app VERSION 0.7.9 LANGUAGES CXX)

include(FindGettext)
if(NOT GETTEXT_FOUND)
  message(FATAL_ERROR "Could not find gettext")
endif(NOT GETTEXT_FOUND)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fno-permissive -pedantic -Wall -Wextra -fPIC")

# Standard install paths
include(GNUInstallDirs)

option(INSTALL_TESTS "Install the tests on make install" on)
option(CLICK_MODE "Installs to a contained location" on)

set(APP_NAME ${PROJECT_NAME})
set(DESKTOP_FILE "${PROJECT_NAME}.desktop")
set(ICON_FILE filemanager.svg)
set(SPLASH_FILE splash.svg)
set(AUTOPILOT_DIR lomiri_filemanager_app)
set(EXEC "${APP_NAME}")
set(CONTENT_HUB_JSON content-hub.json)
set(MANIFEST_PATH "manifest.json.in" CACHE INTERNAL "Relative path to the manifest file")

# global FILE definitions for stat system call, it works for any sub module
add_definitions(-D_LARGEFILE_SOURCE)
add_definitions(-D_FILE_OFFSET_BITS=64)

if(CLICK_MODE)
    # Find out the architecture for package building
    # to determine the plugin's installation path
    execute_process(
        COMMAND dpkg-architecture -qDEB_HOST_MULTIARCH
        OUTPUT_VARIABLE ARCH_TRIPLET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(CMAKE_INSTALL_PREFIX /)
    set(CMAKE_INSTALL_BINDIR /)
    set(DATA_DIR /)
    set(ICON ${ICON_FILE})
    set(SPLASH ${SPLASH_FILE})
    set(QT_IMPORTS_DIR "/lib/${ARCH_TRIPLET}")
    set(BIN_DIR /lib/${ARCH_TRIPLET}/bin)
    set(DESKTOP_DIR ${DATA_DIR})

    if(NOT GIT_REVNO)
        execute_process(
          COMMAND git rev-list --first-parent --all --count
          WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
          OUTPUT_VARIABLE GIT_REVNO
          OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif(NOT GIT_REVNO)
    if(NOT GIT_REVNO)
        set(GIT_REVNO "latest")
    endif(NOT GIT_REVNO)

    if(NOT GIT_HASH)
        execute_process(
          COMMAND git rev-parse --short=7 HEAD
          WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
          OUTPUT_VARIABLE GIT_HASH
          OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif(NOT GIT_HASH)
    if(NOT GIT_HASH)
        set(GIT_HASH "unknownhash")
    endif(NOT GIT_HASH)

    #query the target architecture
    execute_process(
        COMMAND dpkg-architecture -qDEB_HOST_ARCH
        OUTPUT_VARIABLE CLICK_ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)

    # make the click files visible in qtcreator
    file(GLOB CLICK_FILES
         RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
         manifest.json.in *.apparmor)

    add_custom_target(filemanager_ubports_CLICKFiles ALL SOURCES ${CLICK_FILES})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json filemanager.apparmor ${CONTENT_HUB_JSON} DESTINATION ${CMAKE_INSTALL_PREFIX})
    get_filename_component(BLD_CONFIGURATION_NAME ${CMAKE_BINARY_DIR} NAME)

else(CLICK_MODE)
    execute_process(
        COMMAND qmake -query QT_INSTALL_QML
        OUTPUT_VARIABLE QT_IMPORTS_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(DATA_DIR ${CMAKE_INSTALL_DATADIR}/${APP_NAME})
    set(ICON ${CMAKE_INSTALL_PREFIX}/${DATA_DIR}/${ICON_FILE})
    set(SPLASH ${CMAKE_INSTALL_PREFIX}/${DATA_DIR}/${SPLASH_FILE})
    set(DESKTOP_DIR ${CMAKE_INSTALL_DATADIR}/applications)
endif(CLICK_MODE)

file(GLOB SRC_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     *.qml *.js *.png *.svg *.json)
list(REMOVE_ITEM SRC_FILES clickable.json)
install(FILES ${SRC_FILES}  DESTINATION ${DATA_DIR})

configure_file(${DESKTOP_FILE}.in.in ${DESKTOP_FILE}.in)

add_custom_target(${DESKTOP_FILE} ALL
    COMMENT "Merging translations into ${DESKTOP_FILE}..."
    COMMAND ${GETTEXT_MSGFMT_EXECUTABLE}
            --desktop --template=${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}.in
            -o ${DESKTOP_FILE}
            -d ${CMAKE_SOURCE_DIR}/po
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
    DESTINATION ${DESKTOP_DIR})

# Tests
enable_testing()

add_subdirectory(po)
add_subdirectory(tests)
add_subdirectory(src)
