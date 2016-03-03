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
<%def name='propertyDecl(variableDef, usePrimitives=False, useOptionals=True)'>\
    <%
    (varType, isRef, itemsType) = base.attr.convertType(variableDef, usePrimitives, useOptionals)
    %>\
${varType} ${base.attr.inst_name(variableDef.name)};\
</%def>\
<%block name="code">
#pragma once

#include <json11/json11.hpp>
#include <string>
#include <unordered_map>
#include <vector>

#include "Core/Optional.hpp"
% if classDef.dependencies:
% for dep in classDef.dependencies:
#include "${dep}"
% endfor
% endif
% if import_files:
% for import_file in import_files:
#import <${import_file}>
% endfor
% endif
% if classDef.super_types:
% for dep in classDef.super_types:
#import "${dep}.h"
% endfor
% endif

namespace ${namespace} {
namespace models {
<%
class_name = classDef.name
superClass = classDef.superClasses[0] if len(classDef.superClasses) else None
%>
class ${class_name} ${(': protected ' + superClass) if superClass else ''}
{
public:
% for v in classDef.variable_defs:
${propertyDecl(v)}
% endfor
% if include_additional_properties:
    std::unordered_map<std::string, std::string> additionalProperties;
% endif

public:
    ${class_name}() = default;
    ${class_name}(const ${class_name} &other) = default;
    ${class_name}(const json11::Json &value);

    json11::Json to_json() const;

}; // class ${class_name}

} // namespace models
} // namespace ${namespace}
</%block>
