#pragma once

#include <string>
#include <vector>

namespace ocsnode {

struct Section {
    std::string family;
    std::string path;
    std::string qualifier;
    std::string body;
    int line = 1;

    std::string type() const
    {
        if (path.empty())
            return family;
        return family + "/" + path;
    }

    bool empty() const
    {
        return family.empty() && path.empty() && qualifier.empty() && body.empty();
    }
};

struct ParseError {
    int line = 0;
    std::string message;
};

struct ParseResult {
    std::vector<Section> sections;
    std::vector<ParseError> errors;

    bool ok() const { return errors.empty(); }
};

} // namespace ocsnode
