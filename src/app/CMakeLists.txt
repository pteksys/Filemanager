file(GLOB_RECURSE QML_SRCS *.qml *.js *.png *.svg)

set(filemanager_SRCS
    main.cpp
    patharrowbackground.cpp
    patharrowbackground.h
    fmutils.cpp
    fmutils.h
    ${QML_SRCS}
)

add_executable(lomiri-filemanager-app ${filemanager_SRCS})

qt5_use_modules(lomiri-filemanager-app Gui Qml Quick)
target_link_libraries(lomiri-filemanager-app stdc++)

if(NOT "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")
add_custom_target(lomiri-filemanager-app-qmlfiles ALL
    COMMAND cp -r ${CMAKE_CURRENT_SOURCE_DIR}/qml ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS ${QMLFILES}
)
endif(NOT "${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")

install(DIRECTORY qml DESTINATION ${DATA_DIR})
if(CLICK_MODE)
  install(TARGETS lomiri-filemanager-app DESTINATION ${BIN_DIR})
else()
  install(TARGETS lomiri-filemanager-app RUNTIME DESTINATION bin)
endif()
