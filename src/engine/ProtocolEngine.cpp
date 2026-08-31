#include "ocsnode/ProtocolEngine.h"

namespace ocsnode {

ParseResult ProtocolEngine::loadText(const std::string &text)
{
    auto result = m_parser.parse(text);
    m_sections = result.sections;
    m_errors = result.errors;
    refreshState();
    return result;
}

std::string ProtocolEngine::emitText() const
{
    return m_emitter.emitText(m_sections);
}

void ProtocolEngine::setMode(const std::string &mode)
{
    bool replaced = false;
    for (auto &sec : m_sections) {
        if (sec.type() == "cmd/mode") {
            sec.qualifier = mode;
            sec.body.clear();
            replaced = true;
        }
    }
    if (!replaced) {
        Section s;
        s.family = "cmd";
        s.path = "mode";
        s.qualifier = mode;
        m_sections.push_back(std::move(s));
    }
    refreshState();
}

void ProtocolEngine::submit(const Section &section)
{
    bool replaced = false;
    for (auto &sec : m_sections) {
        if (sec.type() == section.type()) {
            sec = section;
            replaced = true;
            break;
        }
    }
    if (!replaced)
        m_sections.push_back(section);
    refreshState();
}

void ProtocolEngine::append(const Section &section)
{
    m_sections.push_back(section);
    refreshState();
}

void ProtocolEngine::requestHalt(const std::string &reason)
{
    Section halt;
    halt.family = "cmd";
    halt.path = "halt";
    halt.qualifier = reason;
    submit(halt);
    if (m_halt)
        m_halt(reason);
}

void ProtocolEngine::refreshState()
{
    m_state = deriveCoherence(m_sections);
}

std::vector<Section> ProtocolEngine::sectionsByFamily(const std::string &family) const
{
    std::vector<Section> out;
    for (const auto &sec : m_sections) {
        if (sec.family == family)
            out.push_back(sec);
    }
    return out;
}

const Section *ProtocolEngine::findByType(const std::string &type) const
{
    for (const auto &sec : m_sections) {
        if (sec.type() == type)
            return &sec;
    }
    return nullptr;
}

} // namespace ocsnode
