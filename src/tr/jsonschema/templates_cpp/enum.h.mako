<%doc>
Copyright (c) 2015 Thomson Reuters

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
</%doc>
<%inherit file="base.mako" />
<%namespace name="base" file="base.mako" />
<%block name='code'>
#pragma once

#include <map>
#include <string>

enum class ${enumDef.name} {
% for v in enumDef.values:
    ${ v },
% endfor
};

inline std::string to_string(const ${enumDef.name} &val) {
    switch (val) {
% for v in enumDef.values:
    case ${enumDef.name}::${ v }:
        return "${v}";
% endfor
    }
}

inline ${enumDef.name} ${enumDef.name.lower()}_from_string(const std::string &key) {
    static const std::map<std::string, ${enumDef.name}> values = {
    % for v in enumDef.values:
        { "${v}", ${enumDef.name}::${v} },
    % endfor
    };
    // Throws std::out_of_range if an invalid string is passed
    return values.at(key);
}

</%block>\
