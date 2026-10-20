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

static void testFixtureRoundTrip(ocsnode::ProtocolParser &parser,
                                 ocsnode::ProtocolEmitter &emitter,
                                 const std::string &path, const char *label)
{
    auto fixture = slurp(path);
    if (fixture.empty()) {
        check(false, (std::string(label) + " fixture readable").c_str());
        return;
    }
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
    check(snap.find("[version=0.6.0]") != std::string::npos,
          (std::string(label) + " export stamps version").c_str());
    check(snap.find("Nexus axes (export)") != std::string::npos,
          (std::string(label) + " export writes axes").c_str());
    check(snap.find("GEMINI_API_KEY=") == std::string::npos
              && snap.find("AIza") == std::string::npos,
          (std::string(label) + " export has no raw secrets").c_str());

    ocsnode::ProtocolEngine imported;
    auto ir = imported.importNexus(snap);
    check(ir.ok(), (std::string(label) + " importNexus ok").c_str());
    check(imported.state().gated == fe.state().gated,
          (std::string(label) + " import restores gated").c_str());
    if (const auto *obj = fe.findByType("data/obj")) {
        const auto *importedObj = imported.findByType("data/obj");
        check(importedObj && importedObj->body == obj->body,
              (std::string(label) + " import restores data/obj").c_str());
    }
}

int main()
{
    using namespace ocsnode;
    std::cout << "ocsnode_qml_surface_tests\n";

    ProtocolParser parser;
    ProtocolEmitter emitter;

    const std::string fixtureDir = OCSNODE_FIXTURE_DIR;
    const char *fixtures[] = {
        "fixture-composer.ocs",
        "fixture-transcript.ocs",
        "fixture-tasboard.ocs",
        "fixture-editor.ocs",
        "fixture-display-surfaces.ocs"
    };

    for (const char *name : fixtures) {
        testFixtureRoundTrip(parser, emitter, fixtureDir + "/" + name, name);
    }

    // Extra invariant checks on the combined fixture
    {
        auto combined = slurp(fixtureDir + "/fixture-display-surfaces.ocs");
        auto cr = parser.parse(combined);
        check(cr.ok(), "combined fixture parses");
        bool hasHalt = false;
        bool hasObj = false;
        bool hasTas = false;
        bool hasChat = false;
        for (const auto &s : cr.sections) {
            if (s.type() == "cmd/halt") hasHalt = true;
            if (s.type() == "data/obj") hasObj = true;
            if (s.type() == "data/tas") hasTas = true;
            if (s.type() == "flow/chat") hasChat = true;
        }
        check(!hasHalt, "combined fixture is halt-free");
        check(hasObj && hasTas && hasChat, "combined fixture has obj+tas+chat");
    }

    std::cout << g_passed << " passed, " << g_failed << " failed\n";
    return g_failed ? EXIT_FAILURE : EXIT_SUCCESS;
}
