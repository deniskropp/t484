#pragma once

#include "ocsnode/CoherenceState.h"
#include "ocsnode/ProtocolEmitter.h"
#include "ocsnode/ProtocolParser.h"
#include "ocsnode/Section.h"

#include <functional>
#include <string>
#include <vector>

namespace ocsnode {

// Qt-free engine core. ProtocolEngineQt wraps this for QML.
class ProtocolEngine {
public:
    using HaltHandler = std::function<void(const std::string &reason)>;

    ParseResult loadText(const std::string &text);
    std::string emitText() const;

    const std::vector<Section> &sections() const { return m_sections; }
    const CoherenceState &state() const { return m_state; }
    const std::vector<ParseError> &errors() const { return m_errors; }

    void setMode(const std::string &mode);
    void submit(const Section &section);
    void append(const Section &section);
    void requestHalt(const std::string &reason);
    void setHaltHandler(HaltHandler h) { m_halt = std::move(h); }

    std::vector<Section> sectionsByFamily(const std::string &family) const;
    const Section *findByType(const std::string &type) const;

private:
    void refreshState();

    std::vector<Section> m_sections;
    std::vector<ParseError> m_errors;
    CoherenceState m_state;
    HaltHandler m_halt;
    ProtocolParser m_parser;
    ProtocolEmitter m_emitter;
};

} // namespace ocsnode
