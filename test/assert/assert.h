// This file replaces the default behavior of assert() with a thrown exception,
// so that test code can detect when assertions fire in the generated classes.

#pragma once

#include <sstream>
#include <stdexcept>

class AssertFailedError : public std::runtime_error
{
public:
    using std::runtime_error::runtime_error;
};

#define assert(X) do {                   \
        if (!(X)) {                      \
        std::stringstream msg; \
            msg << "Assertion failed: " << #X << "\nFile: " << __FILE__ << "\nLine: " << __LINE__ << std::endl; \
                throw AssertFailedError(msg.str());                     \
        }                                \
    } while (0)
