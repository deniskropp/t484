#include "ocsnode/ProtocolEngine.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <string>

namespace ocsnode {
namespace {

constexpr const char *kNexusNode = "OCS/Root";
constexpr const char *kNexusRepo = "deniskropp/t484";
constexpr const char *kNexusRef = "main";
constexpr const char *kNexusVersion = "0.6.0";
constexpr const char *kAxesMarker = "Nexus axes (export)";

std::string formatAxis(double v)
{
    char buf[16];
    std::snprintf(buf, sizeof(buf), "%.2f", v);
    return buf;
}

std::string padName(const char *name)
{
    std::string s(name);
    if (s.size() < 10)
        s.append(10 - s.size(), ' ');
    return s;
}

bool hasBracketKey(const std::string &qual, const std::string &key)
{
    return qual.find("[" + key + "=") != std::string::npos;
}

std::string setBracketAttr(std::string qual, const std::string &key, const std::string &value,
                           bool overwrite)
{
    const std::string prefix = "[" + key + "=";
    const auto p = qual.find(prefix);
    if (p != std::string::npos) {
        if (!overwrite)
            return qual;
        const auto end = qual.find(']', p);
        if (end != std::string::npos)
            qual.replace(p, end - p + 1, prefix + value + "]");
        return qual;
    }
    if (!qual.empty() && qual.back() != ' ')
        qual += ' ';
    qual += prefix + value + "]";
    return qual;
}

std::string stampOcsQualifier(std::string qual)
{
    qual = setBracketAttr(std::move(qual), "node", kNexusNode, !hasBracketKey(qual, "node"));
    qual = setBracketAttr(std::move(qual), "repo", kNexusRepo, !hasBracketKey(qual, "repo"));
    qual = setBracketAttr(std::move(qual), "ref", kNexusRef, !hasBracketKey(qual, "ref"));
    qual = setBracketAttr(std::move(qual), "version", kNexusVersion, true);
    return qual;
}

std::string axesBlock(const CoherenceState &st)
{
    std::string b;
    b += kAxesMarker;
    b += '\n';
    b += "  " + padName("protocol") + formatAxis(st.axes.protocol) + "\n";
    b += "  " + padName("klmx") + formatAxis(st.axes.klmx) + "\n";
    b += "  " + padName("objective") + formatAxis(st.axes.objective) + "\n";
    b += "  " + padName("tas") + formatAxis(st.axes.tas) + "\n";
    b += "  " + padName("consent") + formatAxis(st.axes.consent) + "\n";
    b += "  " + padName("dialogue") + formatAxis(st.axes.dialogue) + "\n";
    b += "  " + padName("genai") + formatAxis(st.axes.genai) + "\n";
    b += "  " + padName("scalar") + formatAxis(st.coherence);
    return b;
}

std::string upsertAxesBlock(std::string body, const std::string &block)
{
    const auto p = body.find(kAxesMarker);
    if (p != std::string::npos) {
        body.erase(p);
        while (!body.empty()
               && (body.back() == '\n' || body.back() == ' ' || body.back() == '\t'
                   || body.back() == '\r')) {
            body.pop_back();
        }
    }
    if (!body.empty())
        body += "\n\n";
    body += block;
    return body;
}

bool isIdentChar(unsigned char c)
{
    return std::isalnum(c) || c == '_' || c == '-';
}

void redactAfterKey(std::string &text, const std::string &key)
{
    std::size_t pos = 0;
    while (pos < text.size()) {
        const auto found = text.find(key, pos);
        if (found == std::string::npos)
            return;
        if (found >= 4 && text.compare(found - 4, 4, "env:") == 0) {
            pos = found + key.size();
            continue;
        }
        if (found > 0 && isIdentChar(static_cast<unsigned char>(text[found - 1]))) {
            pos = found + key.size();
            continue;
        }
        std::size_t i = found + key.size();
        while (i < text.size() && (text[i] == ' ' || text[i] == '\t' || text[i] == '"'))
            ++i;
        if (i >= text.size() || (text[i] != '=' && text[i] != ':')) {
            pos = found + key.size();
            continue;
        }
        ++i;
        while (i < text.size() && (text[i] == ' ' || text[i] == '\t'))
            ++i;
        if (i < text.size() && (text[i] == '"' || text[i] == '\''))
            ++i;
        const std::size_t valueStart = i;
        while (i < text.size() && text[i] != '\n' && text[i] != '\r' && text[i] != '"'
               && text[i] != '\'' && text[i] != ' ' && text[i] != '\t' && text[i] != ',')
            ++i;
        if (i > valueStart) {
            const std::string label = "env:" + key;
            text.replace(valueStart, i - valueStart, label);
            pos = valueStart + label.size();
        } else {
            pos = i;
        }
    }
}

void redactGoogleApiKeys(std::string &text)
{
    std::size_t pos = 0;
    while (pos + 4 < text.size()) {
        const auto found = text.find("AIza", pos);
        if (found == std::string::npos)
            return;
        std::size_t i = found + 4;
        while (i < text.size()
               && (std::isalnum(static_cast<unsigned char>(text[i])) || text[i] == '_'
                   || text[i] == '-'))
            ++i;
        if (i - found >= 24)
            text.replace(found, i - found, "env:GEMINI_API_KEY");
        pos = found + 1;
    }
}

std::string scrubSecrets(std::string text)
{
    redactAfterKey(text, "GEMINI_API_KEY");
    redactAfterKey(text, "GOOGLE_API_KEY");
    redactAfterKey(text, "GOOGLE_GENAI_API_KEY");
    redactAfterKey(text, "GOOGLE_AI_API_KEY");
    redactAfterKey(text, "x-goog-api-key");
    redactAfterKey(text, "X-Goog-Api-Key");
    redactGoogleApiKeys(text);
    return text;
}

} // namespace

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

ParseResult ProtocolEngine::importNexus(const std::string &text)
{
    return loadText(text);
}

std::string ProtocolEngine::exportNexus(double genaiAxis)
{
    Section *ocs = nullptr;
    for (auto &sec : m_sections) {
        if (sec.type() == "protocol/ocs") {
            ocs = &sec;
            break;
        }
    }
    if (ocs) {
        ocs->qualifier = stampOcsQualifier(ocs->qualifier);
    } else {
        Section header;
        header.family = "protocol";
        header.path = "ocs";
        header.qualifier = stampOcsQualifier({});
        m_sections.insert(m_sections.begin(), std::move(header));
    }

    refreshState();
    m_state.axes.genai = std::clamp(genaiAxis, 0.0, 1.0);

    Section *meta = nullptr;
    for (auto &sec : m_sections) {
        if (sec.type() == "display/meta") {
            meta = &sec;
            break;
        }
    }
    const auto block = axesBlock(m_state);
    if (meta) {
        meta->body = upsertAxesBlock(meta->body, block);
    } else {
        Section s;
        s.family = "display";
        s.path = "meta";
        s.body = block;
        m_sections.push_back(std::move(s));
    }

    return scrubSecrets(m_emitter.emitText(m_sections));
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

bool ProtocolEngine::resumeFromHalt()
{
    const auto it = std::remove_if(m_sections.begin(), m_sections.end(), [](const Section &s) {
        return s.type() == "cmd/halt";
    });
    if (it != m_sections.end()) {
        m_sections.erase(it, m_sections.end());
        refreshState();
        return true;
    }
    return false;
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
