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
<%block name="code">
#include "${classDef.header_file}"

#include <assert.h>
% if classDef.has_var_patterns:
#include <regex>
% endif
#include <vector>

using namespace std;
using namespace json11;

<%
class_name = classDef.name
%>\
namespace ${namespace} {
namespace models {

${class_name}::${class_name}(const Json &json) {

    assert(json.is_object());

% for v in classDef.variable_defs:
<%
inst_name = "this->" + base.attr.inst_name(v.name)
temp_name = v.name + "Temp"
%>\
    auto ${temp_name} = json["${v.json_name}"];
% if v.isRequired:
    // required
    {
        assert(!${temp_name}.is_null());
% else:
    // optional
    if ( !${temp_name}.is_null() ) {
% endif
        % if v.isArray:
        assert(${temp_name}.is_array());
        for( const auto array_item : ${temp_name}.array_items() ) {
            % if v.schema_type == 'string':
            if (!array_item.is_null()) {
                assert(array_item.is_string());
                ${inst_name}.emplace_back(array_item.string_value());
            }
            % elif v.schema_type == 'integer':
            assert(array_item.is_number());
            ${inst_name}.emplace_back(int(array_item.number_value()));
            % elif v.schema_type == 'boolean':
            assert(array_item.is_bool());
            ${inst_name}.emplace_back(array_item.bool_value());
            % elif v.schema_type == 'object':
            assert(array_item.is_object());
            ${inst_name}.emplace_back(${v.type}(array_item));
            % elif v.schema_type == 'array':
            ## TODO: probably need to recursively handle arrays of arrays
            assert(array_item.is_array());
            vector<${v.type}> item_array;
            ${inst_name}.emplace_back(${v.type}(item_array));
            % endif
        }
        % else:
        % if v.schema_type == 'string':
        assert(${temp_name}.is_string());
        % if v.isEnum:
        ${inst_name} = string_to_${v.json_name}(${temp_name}.string_value());
        % else:
        ${inst_name} = ${temp_name}.string_value();
        % endif
        % elif v.schema_type == 'integer':
        assert(${temp_name}.is_number());
        ${inst_name} = int(${temp_name}.number_value());
        % elif v.schema_type == 'number':
        assert(${temp_name}.is_number());
        ${inst_name} = ${temp_name}.number_value();
        % elif v.schema_type == 'boolean':
        assert(${temp_name}.is_bool());
        ${inst_name} = ${temp_name}.bool_value();
        % elif v.schema_type == 'object':
        assert(${temp_name}.is_object());
        ${inst_name} = ${v.type}(${temp_name});
        % endif
        % endif
    }

    % endfor
}

bool ${class_name}::is_valid() const {
    try {
        check_valid();
    } catch (const exception &) {
        return false;
    }
    return true;
}

void ${class_name}::check_valid() const {
% for v in classDef.variable_defs:
<%
optional_inst_name = "this->" + base.attr.inst_name(v.name)
inst_name = optional_inst_name if v.isRequired else optional_inst_name + ".get()"
_ = "" if v.isRequired else "    "
%>\
    /*
    ${v}
    */
% if v.isArray:
    // array
% else:
    % if not v.isRequired:
    if (${optional_inst_name}.is_initialized()) {
    % endif
    % if v.type == "string":
        % if v.minLength:
    ${_}if (${inst_name}.size() < ${v.minLength})
    ${_}    throw out_of_range("${base.attr.inst_name(v.name)} too short");
        % endif
        % if v.maxLength:
    ${_}if (${inst_name}.size() > ${v.maxLength})
    ${_}    throw out_of_range("${base.attr.inst_name(v.name)} too long");
        % endif
        % if v.pattern:
    ${_}auto ${base.attr.inst_name(v.name)}_regex = regex(R"_(${v.pattern})_", regex_constants::ECMAScript);
    ${_}if (!regex_match(${inst_name}, ${base.attr.inst_name(v.name)}_regex))
    ${_}    throw invalid_argument("${base.attr.inst_name(v.name)} doesn't match regex pattern");
        % endif
    % endif
    % if not v.isRequired:
    }
    % endif
% endif
% endfor
}

Json ${class_name}::to_json() const {

    assert(is_valid());

    auto object = Json::object();

% for v in classDef.variable_defs:
<%
    inst_name = "this->" + base.attr.inst_name(v.name)
%>\
<%def name='emit_assignment(var_def)'>\
<%
if var_def.isRequired:
    value = inst_name
else:
    value = inst_name + ".get()"
%>
% if var_def.isArray:
    object["${var_def.json_name}"] = Json(${value});
% elif var_def.isEnum:
    object["${var_def.json_name}"] = ${var_def.enum_def.plain_name}_to_string(${value});
% else:
    object["${var_def.json_name}"] = ${value};
% endif
</%def>\
% if not v.isRequired and not v.isArray:
    if (${inst_name}.is_initialized()) {
        ${emit_assignment(v)}
    }
% else:
    ${emit_assignment(v)}
% endif

% endfor
    return Json(object);
}

% for enumDef in [x.enum_def for x in classDef.variable_defs if x.enum_def]:
std::string ${class_name}::${enumDef.plain_name}_to_string(const ${class_name}::${enumDef.name} &val)
{
    switch (val) {
    % for v in enumDef.values:
    case ${enumDef.name}::${ v.title() }:
        return "${v}";
    % endfor
    }
}

${class_name}::${enumDef.name} ${class_name}::string_to_${enumDef.plain_name}(const std::string &key)
{
    static const std::map<std::string, ${enumDef.name}> values = {
        % for v in enumDef.values:
        { "${v}", ${enumDef.name}::${v.title()} },
        % endfor
    };
    // Throws std::out_of_range if an invalid string is passed
    return values.at(key);
}
% endfor

} // namespace models
} // namespace ${namespace}

</%block>
