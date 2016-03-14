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
<%def name='propertyDecl(variableDef)'>\
<%
varType = base.attr.convertType(variableDef)
%>\
    ${varType} ${base.attr.inst_name(variableDef.name)};\
</%def>\
<%def name='enumDecl(enumDef)'>\
    enum class ${enumDef.name} {
% for v in enumDef.values:
        ${ v.title() },
% endfor
    };
    static std::string ${enumDef.plain_name}_to_string(const ${enumDef.name} &val);
    static ${enumDef.name} string_to_${enumDef.plain_name}(const std::string &key);
</%def>\
<%block name="code">
#pragma once

<%
has_optionals = not all([v.isRequired for v in classDef.variable_defs])
has_variants = any([v.isVariant for v in classDef.variable_defs])
%>\
% if has_optionals:
#include <boost/optional.hpp>
% endif
% if has_variants:
#include <boost/variant.hpp>
% endif
#include <json11/json11.hpp>
#include <string>
#include <unordered_map>
#include <vector>

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

% for ns in namespace.split('::'):
namespace ${ns} {
% endfor
<%
class_name = classDef.name
superClass = classDef.superClasses[0] if len(classDef.superClasses) else None
%>
class ${class_name + ((': protected ' + superClass) if superClass else '')}
{
public:
% for e in [x.type.enum_def for x in classDef.variable_defs if x.type.enum_def]:
${enumDecl(e)}
% endfor
% for v in classDef.variable_defs:
${propertyDecl(v)}
% if v.isVariant:
<%
variant_type_return = "std::string" if v.isRequired else "boost::optional<std::string>"
%>\
% if v.isArray:
    ${variant_type_return} ${base.attr.inst_name(v.name)}Type(size_t pos) const;
% else:
    ${variant_type_return} ${base.attr.inst_name(v.name)}Type() const;
% endif
% endif
% endfor
% if include_additional_properties:
    std::unordered_map<std::string, std::string> additionalProperties;
% endif

public:
    ${class_name}() = default;
    ${class_name}(const ${class_name} &other) = default;
    ${class_name}(const json11::Json &value);

    /// Returns true if the contents of this object match the schema
    bool is_valid() const;
    /// Throws if the contents of this object do not match the schema
    void check_valid() const;

    json11::Json to_json() const;
}; // class ${class_name}

% for ns in reversed(namespace.split('::')):
} // namespace ${ns}
% endfor
</%block>
