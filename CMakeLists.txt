cmake_minimum_required(VERSION 3.16)

project(t484 VERSION 0.3.0 LANGUAGES CXX)

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

    qt_add_executable(t484
        src/main.cpp
        src/engine/ProtocolEngineQt.cpp
        src/engine/GenAiClient.cpp
        src/engine/SectionListModel.cpp
        src/components/TasStatusModel.cpp
        src/components/KlmxMoleculeItem.cpp
        # Q_OBJECT lives in these headers (not next to the .cpp files);
        # listing them is required for AUTOMOC to generate vtables/signals.
        include/ocsnode/qt/ProtocolEngineQt.h
        include/ocsnode/qt/GenAiClient.h
        include/ocsnode/qt/SectionListModel.h
        include/ocsnode/qt/TasStatusModel.h
        include/ocsnode/qt/KlmxMoleculeItem.h
    )

    # QTP0001: embed the module under qrc:/qt/qml/<URI>/ (matches src/main.cpp).
    if(QT_KNOWN_POLICY_QTP0001)
        qt_policy(SET QTP0001 NEW)
    endif()

    # Keep sources under src/{qml,assets}/ but flatten them to the module root.
    # Without aliases, qt_add_qml_module preserves those prefixes and the
    # engine looks for qrc:/qt/qml/OcsNode/main.qml (file not found).
    set_source_files_properties(src/qml/main.qml
        PROPERTIES QT_RESOURCE_ALIAS "main.qml")
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
    set_source_files_properties(src/assets/seed.ocs
        PROPERTIES QT_RESOURCE_ALIAS "seed.ocs")

    qt_add_qml_module(t484
        URI OcsNode
        VERSION 1.0
        RESOURCE_PREFIX /qt/qml
        QML_FILES
            src/qml/main.qml
            src/qml/OcsNode/OcsSectionView.qml
            src/qml/OcsNode/ProtocolStatusBar.qml
            src/qml/OcsNode/TasStatusBarView.qml
            src/qml/OcsNode/KlmxMoleculeSpaceView.qml
            src/qml/OcsNode/OcsChatTranscriptView.qml
            src/qml/OcsNode/OcsChatBubbleView.qml
            src/qml/OcsNode/OcsComposerView.qml
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
            Qt6::Network
    )

    add_executable(ocsnode_genai_tests
        tests/test_genai.cpp
        src/engine/GenAiClient.cpp
        include/ocsnode/qt/GenAiClient.h
    )
    target_link_libraries(ocsnode_genai_tests PRIVATE Qt6::Core Qt6::Network)
    target_include_directories(ocsnode_genai_tests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    add_test(NAME genai_parse COMMAND ocsnode_genai_tests)

    target_include_directories(t484 PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_compile_definitions(t484 PRIVATE
        T484_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
    )

    install(TARGETS t484
        BUNDLE DESTINATION .
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
else()
    message(STATUS "Qt6 not found — building protocol core + tests only")
endif()
