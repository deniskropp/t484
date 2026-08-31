#include "ocsnode/ProtocolEmitter.h"
#include "ocsnode/ProtocolParser.h"

namespace ocsnode {

std::string ProtocolEmitter::emitText(const Section &section) const
{
    std::string out;
    out += ProtocolParser::kSigilUtf8;
    out += section.family;
    if (!section.path.empty()) {
        out += '/';
        out += section.path;
    }
    out += ':';
    if (!section.qualifier.empty()) {
        out += section.qualifier;
    }
    out += '\n';
    if (!section.body.empty()) {
        out += section.body;
        if (section.body.back() != '\n')
            out += '\n';
    }
    return out;
}

std::string ProtocolEmitter::emitText(const std::vector<Section> &sections) const
{
    std::string out;
    for (std::size_t i = 0; i < sections.size(); ++i) {
        if (i)
            out += '\n';
        out += emitText(sections[i]);
    }
    return out;
}

} // namespace ocsnode
