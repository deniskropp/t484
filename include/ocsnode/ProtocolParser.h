#pragma once

#include "ocsnode/Section.h"
#include <string>

namespace ocsnode {

// Line-oriented parser. UTF-8 input. Sigil is U+2AFB (UTF-8 e2 ab bb).
class ProtocolParser {
public:
    ParseResult parse(const std::string &text) const;

    static constexpr const char *kSigilUtf8 = "\xE2\xAB\xBB";
    static bool startsWithSigil(const std::string &line, std::size_t *bytes = nullptr);
};

} // namespace ocsnode
