#include "ocsnode/ProtocolParser.h"

#include <sstream>

namespace ocsnode {
namespace {

std::string trim(const std::string &in)
{
    const auto b = in.find_first_not_of(" \t\r");
    if (b == std::string::npos)
        return {};
    const auto e = in.find_last_not_of(" \t\r");
    return in.substr(b, e - b + 1);
}

std::string trimNewlines(const std::string &in)
{
    std::size_t b = 0;
    while (b < in.size() && (in[b] == '\n' || in[b] == '\r'))
        ++b;
    std::size_t e = in.size();
    while (e > b && (in[e - 1] == '\n' || in[e - 1] == '\r' || in[e - 1] == ' ' || in[e - 1] == '\t'))
        --e;
    return in.substr(b, e - b);
}

bool parseHeader(const std::string &rest, Section &out, ParseError *err, int line)
{
    const auto colon = rest.find(':');
    std::string head = trim(colon == std::string::npos ? rest : rest.substr(0, colon));
    std::string qual = colon == std::string::npos ? std::string() : trim(rest.substr(colon + 1));

    if (head.empty()) {
        if (err)
            *err = ParseError{line, "empty section header after sigil"};
        return false;
    }

    const auto slash = head.find('/');
    if (slash == std::string::npos) {
        out.family = head;
        out.path.clear();
    } else {
        out.family = head.substr(0, slash);
        out.path = head.substr(slash + 1);
    }
    out.qualifier = qual;
    out.line = line;
    return true;
}

} // namespace

bool ProtocolParser::startsWithSigil(const std::string &line, std::size_t *bytes)
{
    if (line.size() >= 3
        && static_cast<unsigned char>(line[0]) == 0xE2
        && static_cast<unsigned char>(line[1]) == 0xAB
        && static_cast<unsigned char>(line[2]) == 0xBB) {
        if (bytes)
            *bytes = 3;
        return true;
    }
    return false;
}

ParseResult ProtocolParser::parse(const std::string &text) const
{
    ParseResult result;
    std::istringstream in(text);
    std::string line;
    int lineNo = 0;

    bool have = false;
    Section current;
    std::string body;

    auto flush = [&]() {
        if (!have)
            return;
        current.body = trimNewlines(body);
        result.sections.push_back(std::move(current));
        current = {};
        body.clear();
        have = false;
    };

    while (std::getline(in, line)) {
        ++lineNo;
        if (!line.empty() && line.back() == '\r')
            line.pop_back();

        std::size_t sigilBytes = 0;
        if (startsWithSigil(line, &sigilBytes)) {
            flush();
            ParseError err;
            if (!parseHeader(line.substr(sigilBytes), current, &err, lineNo)) {
                if (!err.message.empty())
                    result.errors.push_back(err);
                continue;
            }
            have = true;
            continue;
        }

        if (have) {
            if (!body.empty())
                body.push_back('\n');
            body += line;
        }
    }

    flush();

    if (result.sections.empty() && result.errors.empty() && !trim(text).empty()) {
        result.errors.push_back(ParseError{1, "no sections found"});
    }

    return result;
}

} // namespace ocsnode
