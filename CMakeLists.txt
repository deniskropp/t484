cmake_minimum_required(VERSION 3.16)

project(t484 VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- protocol core (no Qt) -------------------------------------------------
add_library(ocsnode_protocol STATIC
    src/protocol/ProtocolParser.cpp
    src/protocol/ProtocolEmitter.cpp
    src/engine/ProtocolEngine.cpp
)
target_include_directories(ocsnode_protocol PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

add_executable(ocsnode_protocol_tests
    tests/test_protocol.cpp
)
target_link_libraries(ocsnode_protocol_tests PRIVATE ocsnode_protocol)
target_compile_definitions(ocsnode_protocol_tests PRIVATE
    OCSNODE_FIXTURE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/src/assets"
)

enable_testing()
add_test(NAME protocol_core
    COMMAND ocsnode_protocol_tests ${CMAKE_CURRENT_SOURCE_DIR}/src/assets/seed.ocs
)

# --- Qt display (optional) -------------------------------------------------
find_package(Qt6 QUIET COMPONENTS Core Gui Qml Quick QuickControls2)

if(Qt6_FOUND)
    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)

    qt_add_executable(t484
        src/main.cpp
        src/engine/ProtocolEngineQt.cpp
        src/engine/SectionListModel.cpp
        src/components/TasStatusModel.cpp
        src/components/KlmxMoleculeItem.cpp
    )

    qt_add_qml_module(t484
        URI OcsNode
        VERSION 1.0
        QML_FILES
            src/qml/main.qml
            src/qml/OcsNode/OcsSectionView.qml
            src/qml/OcsNode/ProtocolStatusBar.qml
            src/qml/OcsNode/TasStatusBarView.qml
            src/qml/OcsNode/KlmxMoleculeSpaceView.qml
        RESOURCES
            src/assets/seed.ocs
    )

    target_link_libraries(t484
        PRIVATE
            ocsnode_protocol
            Qt6::Core
            Qt6::Gui
            Qt6::Qml
            Qt6::Quick
            Qt6::QuickControls2
    )

    target_include_directories(t484 PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)

    install(TARGETS t484
        BUNDLE DESTINATION .
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
else()
    message(STATUS "Qt6 not found — building protocol core + tests only")
endif()
