#include "ocsnode/ChatSession.h"

#include <algorithm>
#include <cctype>
#include <sstream>

namespace ocsnode {
namespace {

std::string trim(const std::string &in)
{
    const auto b = in.find_first_not_of(" \t\r\n");
    if (b == std::string::npos)
        return {};
    const auto e = in.find_last_not_of(" \t\r\n");
    return in.substr(b, e - b + 1);
}

bool startsWithIgnoreCase(const std::string &text, const std::string &prefix)
{
    if (text.size() < prefix.size())
        return false;
    for (std::size_t i = 0; i < prefix.size(); ++i) {
        const auto a = std::tolower(static_cast<unsigned char>(text[i]));
        const auto b = std::tolower(static_cast<unsigned char>(prefix[i]));
        if (a != b)
            return false;
    }
    return true;
}

Section makeSection(std::string family, std::string path, std::string qualifier,
                    std::string body)
{
    Section s;
    s.family = std::move(family);
    s.path = std::move(path);
    s.qualifier = std::move(qualifier);
    s.body = std::move(body);
    return s;
}

std::string slashArg(const std::string &text, const std::string &cmd)
{
    if (text.size() <= cmd.size())
        return {};
    return trim(text.substr(cmd.size()));
}

bool looksLikeObjective(const std::string &text, const std::vector<Section> &ingested)
{
    for (const auto &s : ingested) {
        if (s.type() == "data/obj")
            return true;
    }
    return text.size() >= 48 && text.find('\n') != std::string::npos;
}

std::string extractTasBody(const std::string &text)
{
    std::istringstream in(text);
    std::string line;
    std::string out;
    int n = 0;
    while (std::getline(in, line)) {
        auto t = trim(line);
        if (t.empty())
            continue;
        if (t.size() >= 2 && (t[0] == '-' || t[0] == '*'))
            t = trim(t.substr(1));
        else if (t.size() >= 2 && std::isdigit(static_cast<unsigned char>(t[0]))) {
            const auto dot = t.find_first_of(".)");
            if (dot != std::string::npos && dot < 4)
                t = trim(t.substr(dot + 1));
        }
        if (t.empty())
            continue;
        if (!out.empty())
            out += '\n';
        out += t;
        ++n;
    }
    return n >= 2 ? out : std::string();
}

std::string joinErrors(const std::vector<ParseError> &errors)
{
    std::string out;
    for (const auto &e : errors) {
        if (!out.empty())
            out += '\n';
        out += "L" + std::to_string(e.line) + ": " + e.message;
    }
    return out;
}

} // namespace

ChatSession::ChatSession(ProtocolEngine &engine)
    : m_engine(engine)
{
}

bool ChatSession::containsSigil(const std::string &text)
{
    std::istringstream in(text);
    std::string line;
    while (std::getline(in, line)) {
        if (ProtocolParser::startsWithSigil(line))
            return true;
    }
    return false;
}

bool ChatSession::isStatefulType(const std::string &type)
{
    return type == "protocol/ocs" || type == "cmd/mode" || type == "cmd/halt"
        || type == "cmd/lang" || type == "data/obj" || type == "data/tas"
        || type == "data/ptas" || type == "context/klmx";
}

ChatTurnResult ChatSession::send(const std::string &text)
{
    ChatTurnResult out;
    const auto raw = trim(text);
    if (raw.empty()) {
        out.ok = false;
        out.error = "empty turn";
        auto q = makeSection("query", "clarify", "empty",
                             "KickForge: empty turn. Speak, paste ⫻ protocol, or use /mode /halt /exec /obj /tas.");
        m_engine.append(q);
        out.replies.push_back(std::move(q));
        out.gated = m_engine.state().gated;
        return out;
    }

    std::vector<Section> ingested;
    if (containsSigil(raw)) {
        auto parsed = m_parser.parse(raw);
        if (!parsed.ok()) {
            out.ok = false;
            out.error = joinErrors(parsed.errors);
            m_engine.append(makeSection("flow", "chat", "host", raw));
            auto q = makeSection("query", "clarify", "parse",
                                 "KickForge: protocol did not parse.\n" + out.error);
            m_engine.append(q);
            out.replies.push_back(std::move(q));
            out.gated = m_engine.state().gated;
            return out;
        }
        ingested = std::move(parsed.sections);
    } else if (startsWithIgnoreCase(raw, "/halt")) {
        ingested.push_back(makeSection("cmd", "halt", slashArg(raw, "/halt"), {}));
    } else if (startsWithIgnoreCase(raw, "/mode")) {
        ingested.push_back(makeSection("cmd", "mode", slashArg(raw, "/mode"), {}));
    } else if (startsWithIgnoreCase(raw, "/exec")) {
        ingested.push_back(makeSection("cmd", "exec", "ocs-node-engine", slashArg(raw, "/exec")));
    } else if (startsWithIgnoreCase(raw, "/obj")) {
        ingested.push_back(makeSection("data", "obj", {}, slashArg(raw, "/obj")));
    } else if (startsWithIgnoreCase(raw, "/tas")) {
        ingested.push_back(makeSection("data", "tas", {}, slashArg(raw, "/tas")));
    } else {
        ingested.push_back(makeSection("flow", "chat", "host", raw));
    }
    out.ingested = ingested;

    const bool replacedDocument = std::any_of(
        ingested.begin(), ingested.end(),
        [](const Section &s) { return s.type() == "protocol/ocs"; });

    if (replacedDocument) {
        ProtocolEmitter emitter;
        m_engine.loadText(emitter.emitText(ingested));
    } else {
        m_engine.append(makeSection("flow", "chat", "host", raw));
        applyIngested(ingested, out);
    }

    replyAfter(raw, ingested, replacedDocument, out);
    out.gated = m_engine.state().gated;
    if (out.ok && !out.gated && !replacedDocument) {
        bool protocolOnly = false;
        if (ingested.size() == 1) {
            const auto t = ingested[0].type();
            protocolOnly = (t == "cmd/halt" || t == "cmd/mode");
        }
        out.requestLlm = !protocolOnly;
    }
    return out;
}

void ChatSession::applyIngested(const std::vector<Section> &ingested, ChatTurnResult &out)
{
    const bool alreadyGated = m_engine.state().gated;
    for (const auto &sec : ingested) {
        const auto type = sec.type();
        // Host utterance is already recorded as flow/chat:host with the raw turn.
        if (type == "flow/chat"
            && (sec.qualifier == "host" || sec.qualifier == "user")) {
            continue;
        }
        if (alreadyGated && type != "cmd/halt" && type != "cmd/mode") {
            continue;
        }
        if (type == "cmd/halt") {
            m_engine.requestHalt(sec.qualifier.empty() ? sec.body : sec.qualifier);
        } else if (type == "cmd/mode") {
            const auto mode = sec.qualifier.empty() ? trim(sec.body) : sec.qualifier;
            if (mode.empty()) {
                auto q = makeSection("query", "clarify", "mode",
                                     "KickForge: /mode needs Fluid, Swarm, Predictive, or Hybrid.");
                m_engine.append(q);
                out.replies.push_back(std::move(q));
            } else {
                m_engine.setMode(mode);
            }
        } else if (isStatefulType(type)) {
            m_engine.submit(sec);
        } else {
            m_engine.append(sec);
        }
    }
}

void ChatSession::replyAfter(const std::string &raw, const std::vector<Section> &ingested,
                             bool replacedDocument, ChatTurnResult &out)
{
    const auto &st = m_engine.state();

    if (replacedDocument) {
        auto ack = makeSection(
            "flow", "chat", "KickFlow",
            "Document loaded. " + std::to_string(m_engine.sections().size())
                + " sections. status=" + st.status
                + " coherence=" + std::to_string(int(st.coherence * 100)) + "%.");
        m_engine.append(ack);
        out.replies.push_back(std::move(ack));
        if (st.gated) {
            auto g = makeSection("query", "clarify", "consent",
                                 "KickGuard: loaded document is gated (" + st.haltReason
                                     + "). Paste a ⫻protocol/ocs document without ⫻cmd/halt to resume.");
            m_engine.append(g);
            out.replies.push_back(std::move(g));
        }
        return;
    }

    if (st.gated) {
        auto g = makeSection(
            "flow", "chat", "KickGuard",
            "Halt gate is closed: " + (st.haltReason.empty() ? std::string("halt") : st.haltReason)
                + "\nPaste a ⫻protocol/ocs document without ⫻cmd/halt to resume. "
                  "/halt updates the reason; /mode is still recorded.");
        m_engine.append(g);
        out.replies.push_back(std::move(g));
        auto q = makeSection("query", "clarify", "consent",
                             "KickGuard: consent/halt is a first-class command. Resume is a new protocol document.");
        m_engine.append(q);
        out.replies.push_back(std::move(q));
        return;
    }

    if (looksLikeObjective(raw, ingested) && m_engine.findByType("data/obj") == nullptr) {
        m_engine.submit(makeSection("data", "obj", {}, raw));
    }

    const auto tas = extractTasBody(raw);
    bool extractedTas = false;
    if (!tas.empty() && m_engine.findByType("data/tas") == nullptr) {
        m_engine.submit(makeSection("data", "tas", {}, tas));
        extractedTas = true;
    }

    bool hadObj = false;
    bool hadTas = false;
    bool hadExec = false;
    bool hadMode = false;
    for (const auto &s : ingested) {
        if (s.type() == "data/obj")
            hadObj = true;
        if (s.type() == "data/tas" || s.type() == "data/ptas")
            hadTas = true;
        if (s.type() == "cmd/exec")
            hadExec = true;
        if (s.type() == "cmd/mode")
            hadMode = true;
    }

    if (hadObj || looksLikeObjective(raw, ingested)) {
        auto forge = makeSection(
            "flow", "chat", "KickForge",
            std::string("Living objective anchored.")
                + (extractedTas || hadTas
                       ? " TAS steps recorded: " + std::to_string(m_engine.state().activeSteps) + "."
                       : " Add /tas lines when you want a step list."));
        m_engine.append(forge);
        out.replies.push_back(std::move(forge));
    }

    if (hadMode) {
        auto ack = makeSection("flow", "chat", "KickFlow",
                               "Mode set to " + st.mode + ".");
        m_engine.append(ack);
        out.replies.push_back(std::move(ack));
        return;
    }

    if (hadExec) {
        auto ack = makeSection("flow", "chat", "KickFlow",
                               "cmd/exec recorded. KickFlow will call genai unless gated.");
        m_engine.append(ack);
        out.replies.push_back(std::move(ack));
    }
}

} // namespace ocsnode
