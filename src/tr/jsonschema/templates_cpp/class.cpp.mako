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

<%!
import functools
def indent(indent_level, str):
    return str.replace("\n", "\n" + " " * indent_level).rstrip()

indent4 = functools.partial(indent, 4)
indent8 = functools.partial(indent, 8)
indent12 = functools.partial(indent, 12)
indent16 = functools.partial(indent, 16)

%>\
<%
class_name = classDef.name
%>\
% for ns in namespace.split('::'):
namespace ${ns} {
% endfor

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
        % if v.isArray:
        auto &destination_array = ${inst_name};
        %endif
        assert(!${temp_name}.is_null());
    % else:
    // optional
    if ( !${temp_name}.is_null() ) {
        % if v.isArray:
        auto destination_array = decltype(${inst_name})::value_type();
        %endif
    % endif
    % if v.isArray:
        assert(${temp_name}.is_array());
        for( const auto array_item : ${temp_name}.array_items() ) {
        % if v.isVariant:
            assert(array_item.is_object());
            assert(array_item["type"].is_string());
            % for json_type, concrete_type in v.variantTypeMap().iteritems():
            ${"if" if loop.first else "else if"} (array_item["type"] == "${json_type}") {
                destination_array.emplace_back(${concrete_type}(array_item));
            }
            % endfor
        % elif v.type.schema_type == 'string':
            assert(array_item.is_string());
            % if v.type.isEnum:
            destination_array.emplace_back(string_to_${v.json_name}(array_item.string_value()));
            % else:
            destination_array.emplace_back(array_item.string_value());
            % endif:
        % elif v.type.schema_type == 'integer':
            assert(array_item.is_number());
            destination_array.emplace_back(int(array_item.number_value()));
        % elif v.type.schema_type == 'number':
            assert(array_item.is_number());
            destination_array.emplace_back(array_item.number_value());
        % elif v.type.schema_type == 'boolean':
            assert(array_item.is_bool());
            destination_array.emplace_back(array_item.bool_value());
        % elif v.type.schema_type == 'object':
            assert(array_item.is_object());
            destination_array.emplace_back(${v.type.name}(array_item));
        % elif v.schema_type == 'array':
            ## TODO: probably need to recursively handle arrays of arrays
            assert(array_item.is_array());
            vector<${v.type.name}> item_array;
            destination_array.emplace_back(${v.type.name}(item_array));
        % endif
        }
        % if not v.isRequired:
        // Copy the constructed array into the optional<vector>
        ${inst_name} = destination_array;
        % endif
    % else:
        % if v.isVariant:
        assert(${temp_name}.is_object());
        assert(${temp_name}["type"].is_string());
        % for json_type, concrete_type in v.variantTypeMap().iteritems():
        ${"if" if loop.first else "else if"} (${temp_name}["type"] == "${json_type}") {
            ${inst_name} = ${concrete_type}(${temp_name});
        }
        % endfor
        % elif v.type.schema_type == 'string':
        assert(${temp_name}.is_string());
            % if v.type.isEnum:
        ${inst_name} = string_to_${v.json_name}(${temp_name}.string_value());
            % else:
        ${inst_name} = ${temp_name}.string_value();
            % endif
        % elif v.type.schema_type == 'integer':
        assert(${temp_name}.is_number());
        ${inst_name} = int(${temp_name}.number_value());
        % elif v.type.schema_type == 'number':
        assert(${temp_name}.is_number());
        ${inst_name} = ${temp_name}.number_value();
        % elif v.type.schema_type == 'boolean':
        assert(${temp_name}.is_bool());
        ${inst_name} = ${temp_name}.bool_value();
        % elif v.type.schema_type == 'object':
        assert(${temp_name}.is_object());
        ${inst_name} = ${v.type.name}(${temp_name});
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

has_array_validation_checks = (v.minItems is not None or
                               v.maxItems is not None)

has_string_validation_checks = (v.minLength is not None or
                                v.maxLength is not None or
                                v.pattern is not None)

has_numeric_validation_checks = (v.minimum is not None or
                                 v.maximum is not None)

has_any_validation_checks = (has_array_validation_checks or
                             has_string_validation_checks or
                             has_numeric_validation_checks or
                             v.isVariant)
%>\
<%def name='emit_string_validation_checks(inst_name, var_def)'>\
% if var_def.minLength is not None:
if (${inst_name}.size() < ${var_def.minLength})
    throw out_of_range("${base.attr.inst_name(var_def.name)} too short");
% endif
% if var_def.maxLength is not None:
if (${inst_name}.size() > ${var_def.maxLength})
    throw out_of_range("${base.attr.inst_name(var_def.name)} too long");
% endif
% if var_def.pattern:
auto ${base.attr.inst_name(var_def.name)}_regex = regex(R"_(${var_def.pattern})_", regex_constants::ECMAScript);
if (!regex_match(${inst_name}, ${base.attr.inst_name(var_def.name)}_regex))
    throw invalid_argument("${base.attr.inst_name(var_def.name)} doesn't match regex pattern");
% endif
</%def>\
\
<%def name='emit_numeric_validation_checks(inst_name, var_def)'>\
% if var_def.minimum is not None:
<% op = "<=" if var_def.exclusiveMinimum else "<" %>\
if (${inst_name} ${op} ${var_def.minimum})
    throw out_of_range("${base.attr.inst_name(var_def.name)} too small");
% endif
% if var_def.maximum is not None:
<% op = ">=" if var_def.exclusiveMaximum else ">" %>\
if (${inst_name} ${op} ${var_def.maximum})
    throw out_of_range("${base.attr.inst_name(var_def.name)} too large");
% endif
</%def>\
\
<%def name='emit_variant_validation_checks(inst_name, var_def)'>\
class ${var_def.name}_validator : public boost::static_visitor<void>
{
public:
% for json_type, concrete_type in v.variantTypeMap().iteritems():
    void operator()(const ${concrete_type} &value) const {
        value.check_valid();
    }
% endfor
};
boost::apply_visitor(${var_def.name}_validator(), ${inst_name});
</%def>\
\
<%def name='emit_array_validation_checks(inst_name, var_def)'>\
% if has_array_validation_checks:
% if var_def.minItems is not None:
if (${inst_name}.size() < ${var_def.minItems})
    throw out_of_range("Array ${base.attr.inst_name(var_def.name)} has too few items");
% endif
% if var_def.maxItems is not None:
if (${inst_name}.size() > ${var_def.maxItems})
    throw out_of_range("Array ${base.attr.inst_name(var_def.name)} has too many items");
% endif
% endif
% if has_string_validation_checks or has_numeric_validation_checks or var_def.isVariant:
for (const auto &arrayItem : ${inst_name}) {
% if has_string_validation_checks:
    ${capture(emit_string_validation_checks, "arrayItem", var_def) | indent4}
% endif
% if has_numeric_validation_checks:
    ${capture(emit_numeric_validation_checks, "arrayItem", var_def) | indent4}
% endif
% if var_def.isVariant:
    ${capture(emit_variant_validation_checks, "arrayItem", var_def) | indent4}
% endif
}
% endif
</%def>\
\
% if not has_any_validation_checks:
<% continue %>\
% endif
\
% if not v.isRequired:
    if (${optional_inst_name}.is_initialized()) {
% if v.isArray:
        ${capture(emit_array_validation_checks, inst_name, v) | indent8}
% else:
% if has_string_validation_checks:
        ${capture(emit_string_validation_checks, inst_name, v) | indent8}
% endif
% if has_numeric_validation_checks:
        ${capture(emit_numeric_validation_checks, inst_name, v) | indent8}
% endif
% if v.isVariant:
    ${capture(emit_variant_validation_checks, inst_name, v) | indent8}
% endif
% endif
    }
% else:
% if v.isArray:
    ${capture(emit_array_validation_checks, inst_name, v) | indent4}
% else:
% if has_string_validation_checks:
    ${capture(emit_string_validation_checks, inst_name, v) | indent4}
% endif
% if has_numeric_validation_checks:
    ${capture(emit_numeric_validation_checks, inst_name, v) | indent4}
% endif
% if v.isVariant:
    ${capture(emit_variant_validation_checks, inst_name, v) | indent4}
% endif
% endif
% endif
% endfor
}

Json ${class_name}::to_json() const {
    assert(is_valid());
    auto object = Json::object();
% for v in classDef.variable_defs:
<%\
optional_inst_name = "this->" + base.attr.inst_name(v.name)
inst_name = optional_inst_name if v.isRequired else optional_inst_name + ".get()"
%>\
<%def name='emit_assignment(var_def)'>\
% if var_def.isVariant:
class ${var_def.name}_to_json : public boost::static_visitor<Json>
{
public:
% for json_type, concrete_type in v.variantTypeMap().iteritems():
    Json operator()(const ${concrete_type} &value) const {
        return value.to_json();
    }
% endfor
};
% endif
% if var_def.isArray:
% if var_def.isVariant:
{
    auto jsonArray = Json::array(${inst_name}.size());
    std::transform(${inst_name}.begin(),
                   ${inst_name}.end(),
                   jsonArray.begin(),
                   [](const auto &val) {
                       return boost::apply_visitor(${var_def.name}_to_json(), val);
                   });
    object["${var_def.json_name}"] = jsonArray;
}
% elif var_def.type.isEnum:
{
    auto enumStringArray = Json::array(${inst_name}.size());
    std::transform(${inst_name}.begin(),
                   ${inst_name}.end(),
                   enumStringArray.begin(),
                   [](const auto &val) {
                       return ${var_def.type.enum_def.plain_name}_to_string(val);
                   });
    object["${var_def.json_name}"] = enumStringArray;
}
% else:
object["${var_def.json_name}"] = Json(${inst_name});
% endif
% elif var_def.isVariant:
object["${var_def.json_name}"] = boost::apply_visitor(${var_def.name}_to_json(), ${inst_name});
% elif var_def.type.isEnum:
object["${var_def.json_name}"] = ${var_def.type.enum_def.plain_name}_to_string(${inst_name});
% else:
object["${var_def.json_name}"] = ${inst_name};
% endif
</%def>\
% if not v.isRequired:
    if (${optional_inst_name}.is_initialized()) {
        ${capture(emit_assignment, v) | indent8}
% if emit_empty_optionals_as_nulls:
    } else {
        object["${v.json_name}"] = Json(nullptr);
% endif
    }
% else:
    ${capture(emit_assignment, v) | indent4}
% endif
% endfor
    return Json(object);
}

% for v in classDef.variable_defs:
% if v.isVariant:
<%
inst_name = base.attr.inst_name(v.name)
item_name = "item" if v.isArray else inst_name
accessor = item_name if v.isRequired else item_name + ".get()"
variant_type_return = "std::string" if v.isRequired else "boost::optional<std::string>"
%>\
% if v.isArray:
${variant_type_return} ${class_name}::${inst_name}Type(size_t pos) const
% else:
${variant_type_return} ${class_name}::${inst_name}Type() const
% endif
{
% if not v.isRequired:
    if (!${inst_name}.is_initialized()) {
        return boost::none;
    }
% endif
% if v.isArray:
    const auto &item = ${inst_name if v.isRequired else inst_name + ".get()"}.at(pos);
% endif
    class ${inst_name}_get_type : public boost::static_visitor<string>
    {
    public:
    % for json_type, concrete_type in v.variantTypeMap().iteritems():
        string operator()(const ${concrete_type} &value) const {
            return ${concrete_type}::type_to_string(value.type);
        }
    % endfor
    };
    return boost::apply_visitor(${inst_name}_get_type(), ${item_name if v.isRequired or v.isArray else item_name + ".get()"});
}

% endif
% endfor

% for enumDef in [x.type.enum_def for x in classDef.variable_defs if x.type.enum_def]:
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

% for ns in reversed(namespace.split('::')):
} // namespace ${ns}
% endfor

</%block>
