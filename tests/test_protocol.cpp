#include "ocsnode/ChatSession.h"
#include "ocsnode/CoherenceState.h"
#include "ocsnode/NodeEngine.h"
#include "ocsnode/ProtocolEmitter.h"
#include "ocsnode/ProtocolEngine.h"
#include "ocsnode/ProtocolParser.h"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

static int g_failed = 0;
static int g_passed = 0;

static void check(bool cond, const char *name)
{
    if (cond) {
        ++g_passed;
        std::cout << "  PASS  " << name << "\n";
    } else {
        ++g_failed;
        std::cout << "  FAIL  " << name << "\n";
    }
}

static std::string slurp(const std::string &path)
{
    std::ifstream in(path);
    std::ostringstream ss;
    ss << in.rdbuf();
    return ss.str();
}

static const char *kMini = "\xE2\xAB\xBB" "protocol/ocs: [node=OCS/Root]\n"
                           "\xE2\xAB\xBB" "context/klmx:Kick/Lang\n"
                           "hello molecule\n"
                           "\n"
                           "\xE2\xAB\xBB" "data/tas:\n"
                           "- alpha\n"
                           "- beta\n";

int main(int argc, char **argv)
{
    using namespace ocsnode;
    std::cout << "ocsnode_protocol_tests\n";

    ProtocolParser parser;
    auto r = parser.parse(kMini);
    check(r.ok(), "parse ok");
    check(r.sections.size() == 3, "three sections");
    if (r.sections.size() >= 3) {
        check(r.sections[0].type() == "protocol/ocs", "section0 type");
        check(r.sections[0].qualifier == "[node=OCS/Root]", "section0 qualifier");
        check(r.sections[1].type() == "context/klmx", "section1 type");
        check(r.sections[1].qualifier == "Kick/Lang", "section1 qualifier");
        check(r.sections[1].body.find("hello molecule") != std::string::npos, "section1 body");
        check(r.sections[2].type() == "data/tas", "section2 type");
        check(r.sections[2].body.find("alpha") != std::string::npos, "tas body alpha");
    }

    ProtocolEmitter emitter;
    auto text = emitter.emitText(r.sections);
    auto r2 = parser.parse(text);
    check(r2.ok() && r2.sections.size() == r.sections.size(), "round-trip count");
    if (r2.ok() && r2.sections.size() == r.sections.size()) {
        check(r2.sections[1].qualifier == r.sections[1].qualifier, "round-trip qualifier");
        check(r2.sections[1].body == r.sections[1].body, "round-trip body");
    }

    auto empty = parser.parse("");
    check(empty.sections.empty() && empty.errors.empty(), "empty input silent");

    auto nosigil = parser.parse("just text\nno sigil\n");
    check(!nosigil.ok(), "no-sigil is error");

    ProtocolEngine engine;
    auto loaded = engine.loadText(kMini);
    check(loaded.ok(), "engine load");
    check(engine.state().activeSteps == 2, "derived activeSteps");
    check(engine.state().status == "running", "derived status running");
    check(engine.state().coherence > 0.7, "derived coherence > 0.7");
    check(engine.findByType("context/klmx") != nullptr, "find klmx");

    engine.requestHalt("test-gate");
    check(engine.state().gated, "halt sets gated");
    check(engine.state().status == "gated", "halt status");
    check(engine.findByType("cmd/halt") != nullptr, "halt section present");

    engine.setMode("Predictive");
    check(engine.state().mode == "Predictive", "setMode");

    NodeEngine node;
    node.setActor("KickForge");
    check(node.actor() == "KickForge", "node actor");
    check(node.ingest(kMini).ok(), "node ingest");

    ProtocolEngine chatEngine;
    chatEngine.loadText(kMini);
    const auto before = chatEngine.sections().size();
    Section turn;
    turn.family = "flow";
    turn.path = "chat";
    turn.qualifier = "host";
    turn.body = "first";
    chatEngine.append(turn);
    turn.body = "second";
    chatEngine.append(turn);
    check(chatEngine.sections().size() == before + 2, "append keeps both chat turns");
    int hostTurns = 0;
    for (const auto &s : chatEngine.sections()) {
        if (s.type() == "flow/chat" && s.qualifier == "host")
            ++hostTurns;
    }
    check(hostTurns == 2, "two host flow/chat sections");

    ProtocolEngine sessionEngine;
    sessionEngine.loadText(kMini);
    ChatSession session(sessionEngine);
    auto t1 = session.send("hello node");
    check(t1.ok, "plain chat ok");
    check(!t1.gated, "plain chat not gated");
    check(t1.requestLlm, "plain chat requests llm");
    const Section *last = nullptr;
    int hostCount = 0;
    for (const auto &s : sessionEngine.sections()) {
        if (s.type() == "flow/chat" && s.qualifier == "host") {
            ++hostCount;
            last = &s;
        }
    }
    check(hostCount == 1 && last && last->body == "hello node", "plain chat host body");

    auto tMode = session.send("/mode Predictive");
    check(tMode.ok && sessionEngine.state().mode == "Predictive", "slash mode");
    check(!tMode.requestLlm, "slash mode does not call llm");

    auto tHalt = session.send("/halt user-gate");
    check(tHalt.gated && sessionEngine.state().gated, "slash halt gates");
    check(!tHalt.requestLlm, "slash halt does not call llm");
    check(sessionEngine.findByType("cmd/halt") != nullptr, "halt section after slash");
    const auto gatedSize = sessionEngine.sections().size();
    auto blocked = session.send("/obj should not replace");
    check(blocked.gated, "gated turn still gated");
    const auto *obj = sessionEngine.findByType("data/obj");
    check(obj == nullptr || obj->body.find("should not replace") == std::string::npos,
          "gated /obj does not mutate data/obj");
    check(sessionEngine.sections().size() > gatedSize, "gated turn still records host + KickGuard");

    auto emptyTurn = session.send("   ");
    check(!emptyTurn.ok, "empty turn not ok");

    ProtocolEngine loadEngine;
    ChatSession loader(loadEngine);
    auto loadedDoc = loader.send(kMini);
    check(loadedDoc.ok && loadEngine.findByType("context/klmx") != nullptr, "sigil paste loads document");
    check(loadEngine.findByType("data/tas") != nullptr, "loaded tas preserved");

    if (argc > 1) {
        auto fixture = slurp(argv[1]);
        auto fr = parser.parse(fixture);
        check(fr.ok() && fr.sections.size() >= 4, "fixture seed.ocs parses");
        ProtocolEngine fe;
        fe.loadText(fixture);
        check(fe.findByType("data/obj") != nullptr, "fixture has data/obj");
        check(fe.findByType("data/tas") != nullptr, "fixture has data/tas");
        auto again = parser.parse(emitter.emitText(fr.sections));
        check(again.ok() && again.sections.size() == fr.sections.size(), "fixture round-trip");
    }

    std::cout << g_passed << " passed, " << g_failed << " failed\n";
    return g_failed ? EXIT_FAILURE : EXIT_SUCCESS;
}
