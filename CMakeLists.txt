cmake_minimum_required(VERSION 3.16)

project(t484 VERSION 0.4.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- protocol core (no Qt) -------------------------------------------------
add_library(ocsnode_protocol STATIC
    src/protocol/ProtocolParser.cpp
    src/protocol/ProtocolEmitter.cpp
    src/protocol/ChatSession.cpp
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
find_package(Qt6 QUIET COMPONENTS Core Gui Qml Quick QuickControls2 Network)

if(Qt6_FOUND)
    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)

    if(QT_KNOWN_POLICY_QTP0001)
        qt_policy(SET QTP0001 NEW)
    endif()

    # Shared once — qt_add_qml_module forbids two targets writing URI OcsNode
    # into the same output directory (t484 + t484-console).
    set(T484_ENGINE_SOURCES
        src/engine/ProtocolEngineQt.cpp
        src/engine/GenAiClient.cpp
        src/engine/SectionListModel.cpp
        src/components/TasStatusModel.cpp
        src/components/KlmxMoleculeItem.cpp
        src/components/EventLogModel.cpp
        include/ocsnode/qt/ProtocolEngineQt.h
        include/ocsnode/qt/GenAiClient.h
        include/ocsnode/qt/SectionListModel.h
        include/ocsnode/qt/TasStatusModel.h
        include/ocsnode/qt/KlmxMoleculeItem.h
        include/ocsnode/qt/EventLogModel.h
    )

    add_library(ocsnode_engine STATIC ${T484_ENGINE_SOURCES})
    target_link_libraries(ocsnode_engine
        PUBLIC
            ocsnode_protocol
            Qt6::Core
            Qt6::Gui
            Qt6::Qml
            Qt6::Network
    )
    target_include_directories(ocsnode_engine PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_compile_definitions(ocsnode_engine PUBLIC
        T484_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
    )

    set(T484_QML_FILES
        src/qml/main.qml
        src/qml/console.qml
        src/qml/OcsNode/Theme.qml
        src/qml/OcsNode/OcsSectionView.qml
        src/qml/OcsNode/ProtocolStatusBar.qml
        src/qml/OcsNode/TasStatusBarView.qml
        src/qml/OcsNode/KlmxMoleculeSpaceView.qml
        src/qml/OcsNode/OcsChatTranscriptView.qml
        src/qml/OcsNode/OcsChatBubbleView.qml
        src/qml/OcsNode/OcsComposerView.qml
        src/qml/OcsNode/OcsSettingsPanelView.qml
        src/qml/OcsNode/OcsEventLogView.qml
        src/qml/OcsNode/OcsMetricsPanelView.qml
    )

    # Keep sources under src/{qml,assets}/ but flatten them to the module root.
    set_source_files_properties(src/qml/main.qml
        PROPERTIES QT_RESOURCE_ALIAS "main.qml")
    set_source_files_properties(src/qml/console.qml
        PROPERTIES QT_RESOURCE_ALIAS "console.qml")
    set_source_files_properties(src/qml/OcsNode/Theme.qml
        PROPERTIES
            QT_RESOURCE_ALIAS "Theme.qml"
            QT_QML_SINGLETON_TYPE TRUE)
    set_source_files_properties(src/qml/OcsNode/OcsSectionView.qml
        PROPERTIES QT_RESOURCE_ALIAS "OcsSectionView.qml")
    set_source_files_properties(src/qml/OcsNode/ProtocolStatusBar.qml
        PROPERTIES QT_RESOURCE_ALIAS "ProtocolStatusBar.qml")
    set_source_files_properties(src/qml/OcsNode/TasStatusBarView.qml
        PROPERTIES QT_RESOURCE_ALIAS "TasStatusBarView.qml")
    set_source_files_properties(src/qml/OcsNode/KlmxMoleculeSpaceView.qml
        PROPERTIES QT_RESOURCE_ALIAS "KlmxMoleculeSpaceView.qml")
    set_source_files_properties(src/qml/OcsNode/OcsChatTranscriptView.qml
        PROPERTIES QT_RESOURCE_ALIAS "OcsChatTranscriptView.qml")
    set_source_files_properties(src/qml/OcsNode/OcsChatBubbleView.qml
        PROPERTIES QT_RESOURCE_ALIAS "OcsChatBubbleView.qml")
    set_source_files_properties(src/qml/OcsNode/OcsComposerView.qml
        PROPERTIES QT_RESOURCE_ALIAS "OcsComposerView.qml")
    set_source_files_properties(src/qml/OcsNode/OcsSettingsPanelView.qml
        PROPERTIES QT_RESOURCE_ALIAS "OcsSettingsPanelView.qml")
    set_source_files_properties(src/qml/OcsNode/OcsEventLogView.qml
        PROPERTIES QT_RESOURCE_ALIAS "OcsEventLogView.qml")
    set_source_files_properties(src/qml/OcsNode/OcsMetricsPanelView.qml
        PROPERTIES QT_RESOURCE_ALIAS "OcsMetricsPanelView.qml")
    set_source_files_properties(src/assets/seed.ocs
        PROPERTIES QT_RESOURCE_ALIAS "seed.ocs")

    qt_add_library(ocsnode_qml STATIC)
    qt_add_qml_module(ocsnode_qml
        URI OcsNode
        VERSION 1.0
        RESOURCE_PREFIX /qt/qml
        OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OcsNode
        QML_FILES ${T484_QML_FILES}
        RESOURCES src/assets/seed.ocs
    )
    target_link_libraries(ocsnode_qml
        PUBLIC
            ocsnode_engine
            Qt6::Quick
            Qt6::QuickControls2
    )

    function(t484_add_app target)
        cmake_parse_arguments(APP "CONSOLE" "" "" ${ARGN})

        qt_add_executable(${target} src/main.cpp)
        # Shared Qt loads Quick plugins at runtime; skip import-scanner so
        # Debian's missing Qt6::*plugin CMake targets do not warn.
        set_target_properties(${target} PROPERTIES QT_QML_MODULE_NO_IMPORT_SCAN TRUE)

        target_link_libraries(${target}
            PRIVATE
                ocsnode_qml
                Qt6::Quick
                Qt6::QuickControls2
        )
        if(TARGET ocsnode_qmlplugin)
            target_link_libraries(${target} PRIVATE ocsnode_qmlplugin)
        endif()
        if(APP_CONSOLE)
            target_compile_definitions(${target} PRIVATE T484_SHELL_CONSOLE)
        endif()

        install(TARGETS ${target}
            BUNDLE DESTINATION .
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        )
    endfunction()

    t484_add_app(t484)
    t484_add_app(t484_console CONSOLE)
    set_target_properties(t484_console PROPERTIES OUTPUT_NAME t484-console)

    add_executable(ocsnode_genai_tests
        tests/test_genai.cpp
        src/engine/GenAiClient.cpp
        include/ocsnode/qt/GenAiClient.h
    )
    target_link_libraries(ocsnode_genai_tests PRIVATE Qt6::Core Qt6::Network)
    target_include_directories(ocsnode_genai_tests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    add_test(NAME genai_parse COMMAND ocsnode_genai_tests)
else()
    message(STATUS "Qt6 not found — building protocol core + tests only")
endif()
