#pragma once

#include "ocsnode/Section.h"
#include <string>
#include <vector>

namespace ocsnode {

class ProtocolEmitter {
public:
    std::string emit(const std::vector<Section> &sections) const;
    std::string emit(const Section &section) const;
};

} // namespace ocsnode
