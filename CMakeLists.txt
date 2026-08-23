cmake_minimum_required(VERSION 3.16)

project(t484 VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

qt_add_executable(t484
    src/main.cpp
)

qt_add_qml_module(t484
    URI OcsNode
    VERSION 1.0
    QML_FILES
        src/qml/main.qml
        src/qml/OcsNode/OcsSectionView.qml
        src/qml/OcsNode/ProtocolStatusBar.qml
)

target_link_libraries(t484
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::QuickControls2
)

install(TARGETS t484
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
