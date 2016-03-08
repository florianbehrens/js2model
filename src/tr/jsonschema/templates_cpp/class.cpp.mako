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
        ${inst_name} = ${v.type.lower()}_from_string(${temp_name}.string_value());
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
    return true;
}

Json ${class_name}::to_json() const {

    auto object = Json::object();

% for v in classDef.variable_defs:
<%
    inst_name = "this->" + base.attr.inst_name(v.name)
%>\
% if not v.isRequired and not v.isArray:
    if (${inst_name}.is_initialized()) {
        object["${v.json_name}"] = ${inst_name}.get();
    }
% elif v.isArray:
    object["${v.json_name}"] = Json(${inst_name});
% elif v.isEnum:
    object["${v.json_name}"] = to_string(${inst_name});
% else:
    object["${v.json_name}"] = ${inst_name};
% endif

% endfor
    return Json(object);
}

} // namespace models
} // namespace ${namespace}

</%block>
