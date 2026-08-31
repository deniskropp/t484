#pragma once

#include "ocsnode/Section.h"
#include <algorithm>
#include <string>
#include <vector>

namespace ocsnode {

struct CoherenceState {
    std::string mode = "Hybrid";   // Fluid | Swarm | Predictive | Hybrid
    std::string status = "idle";   // idle | running | gated | complete | error
    double coherence = 0.5;
    bool gated = false;
    std::string haltReason;
    std::string currentTasId;
    int activeSteps = 0;
};

// Deterministic v0.2 heuristic — replaced later by CoherenceMonitorBridge.
inline CoherenceState deriveCoherence(const std::vector<Section> &sections)
{
    CoherenceState s;
    bool hasProtocol = false;
    bool hasKlmx = false;
    bool hasObj = false;
    bool hasTas = false;
    bool hasHalt = false;

    for (const auto &sec : sections) {
        const auto t = sec.type();
        if (t == "protocol/ocs")
            hasProtocol = true;
        if (t == "context/klmx")
            hasKlmx = true;
        if (t == "data/obj")
            hasObj = true;
        if (t == "data/tas" || t == "data/ptas") {
            hasTas = true;
            int steps = 0;
            std::string firstId;
            std::string line;
            for (char c : sec.body) {
                if (c == '\n') {
                    auto start = line.find_first_not_of(" \t-");
                    if (start != std::string::npos) {
                        ++steps;
                        if (firstId.empty())
                            firstId = line.substr(start, 32);
                    }
                    line.clear();
                } else {
                    line.push_back(c);
                }
            }
            if (!line.empty()) {
                auto start = line.find_first_not_of(" \t-");
                if (start != std::string::npos) {
                    ++steps;
                    if (firstId.empty())
                        firstId = line.substr(start, 32);
                }
            }
            s.activeSteps += steps;
            if (s.currentTasId.empty())
                s.currentTasId = firstId;
        }
        if (t == "cmd/halt") {
            hasHalt = true;
            s.haltReason = sec.qualifier.empty() ? sec.body : sec.qualifier;
        }
        if (t == "cmd/mode" && !sec.qualifier.empty())
            s.mode = sec.qualifier;
    }

    double c = 0.45;
    if (hasProtocol)
        c += 0.12;
    if (hasKlmx)
        c += 0.12;
    if (hasObj)
        c += 0.10;
    if (hasTas)
        c += 0.16;
    if (hasHalt)
        c -= 0.20;

    s.coherence = std::clamp(c, 0.0, 1.0);
    s.gated = hasHalt;
    s.status = hasHalt ? "gated" : (hasTas ? "running" : "idle");
    return s;
}

} // namespace ocsnode
