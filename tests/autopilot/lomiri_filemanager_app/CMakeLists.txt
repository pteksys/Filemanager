# make the emulator files visible on qtcreator
file(GLOB PYTHON_EMULATOR_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     *.py)

add_custom_target(filemanager_ubports_PYTHONEMULATORFiles ALL SOURCES ${PYTHON_EMULATOR_FILES})

add_subdirectory(tests)
