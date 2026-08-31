#pragma once

#include "ocsnode/ProtocolEngine.h"
#include <string>

namespace ocsnode {

// Facade for three-agent-core bridges (KickForge / KickFlow / KickGuard).
// v0.2: delegates to ProtocolEngine and records the last actor label.
class NodeEngine {
public:
    ProtocolEngine &protocol() { return m_protocol; }
    const ProtocolEngine &protocol() const { return m_protocol; }

    void setActor(const std::string &actor) { m_actor = actor; }
    const std::string &actor() const { return m_actor; }

    ParseResult ingest(const std::string &text) { return m_protocol.loadText(text); }

private:
    ProtocolEngine m_protocol;
    std::string m_actor = "KickFlow";
};

} // namespace ocsnode
