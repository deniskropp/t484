#pragma once

#include "ocsnode/Section.h"
#include <string>
#include <vector>

namespace ocsnode {

class ProtocolEmitter {
public:
    // Named emitText (not emit) so Qt's emit macro does not eat the identifier.
    std::string emitText(const std::vector<Section> &sections) const;
    std::string emitText(const Section &section) const;
};

} // namespace ocsnode
