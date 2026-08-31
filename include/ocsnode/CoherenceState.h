#pragma once

#include "ocsnode/Section.h"
#include <algorithm>
#include <string>
#include <vector>

namespace ocsnode {

struct VolumetricAxes {
    double protocol = 0.0;
    double klmx = 0.0;
    double objective = 0.0;
    double tas = 0.0;
    double consent = 1.0;
    double dialogue = 0.0;
    double genai = 0.5; // STL default; Qt façade overlays ready && !busy
};

struct CoherenceState {
    std::string mode = "Hybrid";   // Fluid | Swarm | Predictive | Hybrid
    std::string status = "idle";   // idle | running | gated | complete | error
    double coherence = 0.5;
    bool gated = false;
    std::string haltReason;
    std::string currentTasId;
    int activeSteps = 0;
    VolumetricAxes axes;
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
    int hostTurns = 0;
    int replies = 0;

    for (const auto &sec : sections) {
        const auto t = sec.type();
        if (t == "protocol/ocs")
            hasProtocol = true;
        if (t == "context/klmx")
            hasKlmx = true;
        if (t == "data/obj")
            hasObj = true;
        if (t == "flow/chat") {
            if (sec.qualifier == "host" || sec.qualifier == "user")
                ++hostTurns;
            else
                ++replies;
        }
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

    s.axes.protocol = hasProtocol ? 1.0 : 0.0;
    s.axes.klmx = hasKlmx ? 1.0 : 0.0;
    s.axes.objective = hasObj ? 1.0 : 0.0;
    s.axes.tas = s.activeSteps > 0 ? std::min(1.0, s.activeSteps / 5.0) : 0.0;
    s.axes.consent = hasHalt ? 0.0 : 1.0;
    s.axes.dialogue = std::min(1.0, hostTurns * 0.25 + replies * 0.15);
    s.axes.genai = 0.5;
    return s;
}

} // namespace ocsnode
