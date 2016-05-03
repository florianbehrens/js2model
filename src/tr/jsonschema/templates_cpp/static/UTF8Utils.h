//
//  UTF8Utils.h
//
//  Copyright (c) 2016 FiftyThree, Inc. All rights reserved.
//
//  clang-format off

#pragma once

#include <string>

namespace js2model {
    /// The number of unicode codepoints in a UTF-8 encoded string
    size_t utf8_codepoint_count(const std::string &string);
}
