#pragma once

#include "ocsnode/ProtocolEngine.h"
#include "ocsnode/ProtocolParser.h"
#include "ocsnode/Section.h"

#include <string>
#include <vector>

namespace ocsnode {

// One interactive turn against a living protocol document.
// Host input is always a first-class section; replies are tagged with
// KickForge / KickFlow / KickGuard. No new command families.
struct ChatTurnResult {
    std::vector<Section> ingested;
    std::vector<Section> replies;
    bool ok = true;
    bool gated = false;
    bool requestLlm = false;
    std::string error;
};

class ChatSession {
public:
    explicit ChatSession(ProtocolEngine &engine);

    ChatTurnResult send(const std::string &text);

    static bool containsSigil(const std::string &text);
    static bool isStatefulType(const std::string &type);
    static bool isNexusExport(const Section &section);
    static bool isNexusImport(const Section &section);

private:
    void applyIngested(const std::vector<Section> &ingested, ChatTurnResult &out);
    void replyAfter(const std::string &raw, const std::vector<Section> &ingested,
                    bool replacedDocument, ChatTurnResult &out);

    ProtocolEngine &m_engine;
    ProtocolParser m_parser;
};

} // namespace ocsnode
