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
#include <vector>

#ifndef OCSNODE_FIXTURE_DIR
#define OCSNODE_FIXTURE_DIR "."
#endif

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

static bool sectionsLossless(const std::vector<ocsnode::Section> &a,
                             const std::vector<ocsnode::Section> &b)
{
    if (a.size() != b.size())
        return false;
    for (std::size_t i = 0; i < a.size(); ++i) {
        if (a[i].family != b[i].family || a[i].path != b[i].path
            || a[i].qualifier != b[i].qualifier || a[i].body != b[i].body)
            return false;
    }
    return true;
}

static const char *kMini = "\xE2\xAB\xBB" "protocol/ocs: [node=OCS/Root]\n"
                           "\xE2\xAB\xBB" "context/klmx:Kick/Lang\n"
                           "hello molecule\n"
                           "\n"
                           "\xE2\xAB\xBB" "data/tas:\n"
                           "- alpha\n"
                           "- beta\n";

static const char *kSecretDoc =
    "\xE2\xAB\xBB"
    "protocol/ocs: [node=OCS/Root]\n"
    "\xE2\xAB\xBB"
    "cmd/mode:Hybrid\n"
    "\xE2\xAB\xBB"
    "data/obj:\nkeep the objective\n"
    "\xE2\xAB\xBB"
    "data/tas:\nN2 export\nN6 tests\n"
    "\xE2\xAB\xBB"
    "flow/chat:host\n"
    "GEMINI_API_KEY=super-secret-test-value\n"
    "x-goog-api-key: AIzaSyDummyTestKeyValue0000000000\n";

static void testFixtureRoundTrip(ocsnode::ProtocolParser &parser,
                                 ocsnode::ProtocolEmitter &emitter,
                                 const std::string &path, const char *label)
{
    auto fixture = slurp(path);
    auto fr = parser.parse(fixture);
    check(fr.ok() && !fr.sections.empty(), (std::string(label) + " parses").c_str());
    auto again = parser.parse(emitter.emitText(fr.sections));
    check(again.ok() && sectionsLossless(fr.sections, again.sections),
          (std::string(label) + " lossless parse(emit(parse))").c_str());

    ocsnode::ProtocolEngine fe;
    auto loaded = fe.loadText(fixture);
    check(loaded.ok(), (std::string(label) + " engine load").c_str());
    auto fromEngine = parser.parse(fe.emitText());
    check(fromEngine.ok() && sectionsLossless(fe.sections(), fromEngine.sections),
          (std::string(label) + " engine emit lossless").c_str());

    const auto snap = fe.exportNexus();
    check(snap.find("GEMINI_API_KEY=") == std::string::npos
              && snap.find("AIza") == std::string::npos,
          (std::string(label) + " export has no raw secrets").c_str());
    check(snap.find("[version=0.6.0]") != std::string::npos,
          (std::string(label) + " export stamps version").c_str());
    check(snap.find("Nexus axes (export)") != std::string::npos,
          (std::string(label) + " export writes axes").c_str());

    ocsnode::ProtocolEngine imported;
    auto ir = imported.importNexus(snap);
    check(ir.ok(), (std::string(label) + " importNexus ok").c_str());
    check(imported.state().activeSteps == fe.state().activeSteps,
          (std::string(label) + " import restores activeSteps").c_str());
    check(imported.state().gated == fe.state().gated,
          (std::string(label) + " import restores gated").c_str());
    if (const auto *obj = fe.findByType("data/obj")) {
        const auto *importedObj = imported.findByType("data/obj");
        check(importedObj && importedObj->body == obj->body,
              (std::string(label) + " import restores data/obj").c_str());
    }
    auto snapAgain = parser.parse(imported.emitText());
    auto snapParsed = parser.parse(snap);
    check(snapParsed.ok() && snapAgain.ok()
              && sectionsLossless(snapParsed.sections, snapAgain.sections),
          (std::string(label) + " imported snapshot lossless").c_str());
}

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

    ProtocolEngine nexusEngine;
    nexusEngine.loadText(kMini);
    ChatSession nexusSession(nexusEngine);
    auto exported = nexusSession.send("/exec nexus-export");
    check(exported.ok, "slash nexus-export ok");
    check(!exported.requestLlm, "slash nexus-export does not call llm");
    check(nexusEngine.findByType("protocol/ocs") != nullptr, "export keeps protocol/ocs");
    check(nexusEngine.emitText().find("[version=0.6.0]") != std::string::npos,
          "slash export stamps version on living document");
    check(nexusEngine.findByType("display/meta") != nullptr, "slash export writes display/meta");

    ProtocolEngine secretEngine;
    secretEngine.loadText(kSecretDoc);
    const auto secretSnap = secretEngine.exportNexus();
    check(secretSnap.find("super-secret-test-value") == std::string::npos, "export scrubs GEMINI_API_KEY value");
    check(secretSnap.find("AIzaSyDummyTestKeyValue0000000000") == std::string::npos,
          "export scrubs Google API key material");
    check(secretSnap.find("env:GEMINI_API_KEY") != std::string::npos
              || secretSnap.find("env:x-goog-api-key") != std::string::npos,
          "export keeps env: label");
    check(secretSnap.find("keep the objective") != std::string::npos, "export keeps living objective");
    ProtocolEngine secretImported;
    secretImported.importNexus(secretSnap);
    check(secretImported.state().activeSteps == secretEngine.state().activeSteps,
          "secret-scrubbed import restores TAS steps");

    ProtocolEngine gatedExport;
    gatedExport.loadText(kMini);
    gatedExport.requestHalt("export-while-gated");
    ChatSession gatedSession(gatedExport);
    const auto beforeGated = gatedExport.findByType("data/obj");
    auto gatedTurn = gatedSession.send("/exec nexus-export");
    check(gatedTurn.gated && gatedExport.state().gated, "gated export stays gated");
    check(!gatedTurn.requestLlm, "gated export does not call llm");
    check(gatedExport.findByType("cmd/halt") != nullptr, "gated export keeps halt");
    const auto snapGated = gatedExport.exportNexus();
    check(snapGated.find("cmd/halt") != std::string::npos, "gated snapshot includes halt");
    ProtocolEngine gatedImported;
    gatedImported.importNexus(snapGated);
    check(gatedImported.state().gated, "import of halted snapshot stays gated");
    (void)beforeGated;

    ProtocolEngine importChat;
    importChat.loadText(kMini);
    ChatSession importSession(importChat);
    const std::string importPaste = std::string("\xE2\xAB\xBB") + "protocol/ocs: [node=OCS/Root] [version=0.6.0]\n"
                                    + "\xE2\xAB\xBB" + "cmd/mode:Fluid\n"
                                    + "\xE2\xAB\xBB" + "data/obj:\nimported objective\n"
                                    + "\xE2\xAB\xBB" + "data/tas:\nI1 one\nI2 two\nI3 three\n";
    auto importedTurn = importSession.send(importPaste);
    check(importedTurn.ok, "protocol/ocs paste import ok");
    check(importChat.state().mode == "Fluid", "import restores mode");
    check(importChat.findByType("data/obj") && importChat.findByType("data/obj")->body.find("imported objective") != std::string::npos,
          "import restores objective");
    check(importChat.state().activeSteps == 3, "import restores three TAS steps");
    check(!importChat.state().gated, "halt-free import is not gated");

    check(nexusEngine.state().axes.protocol == 1.0, "axis protocol");
    check(nexusEngine.state().axes.klmx == 1.0, "axis klmx");
    check(nexusEngine.state().axes.consent == 1.0, "axis consent open");
    check(gatedExport.state().axes.consent == 0.0, "axis consent gated");
    check(secretEngine.state().axes.objective == 1.0, "axis objective");
    check(secretEngine.state().axes.tas > 0.0, "axis tas");

    const std::string fixtureDir = OCSNODE_FIXTURE_DIR;
    testFixtureRoundTrip(parser, emitter, fixtureDir + "/seed.ocs", "seed.ocs");
    testFixtureRoundTrip(parser, emitter, fixtureDir + "/nexus-v0.6.ocs", "nexus-v0.6.ocs");
    testFixtureRoundTrip(parser, emitter, fixtureDir + "/seed-nexus.ocs", "seed-nexus.ocs");

    if (argc > 1) {
        testFixtureRoundTrip(parser, emitter, argv[1], "argv fixture");
    }

    std::cout << g_passed << " passed, " << g_failed << " failed\n";
    return g_failed ? EXIT_FAILURE : EXIT_SUCCESS;
}
