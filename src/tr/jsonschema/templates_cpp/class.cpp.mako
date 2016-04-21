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

<%doc>
Indentation helpers, used to indent the output of other def() calls
Sample usage:
    ${capture(generateAssignmentFromJson, v, "destination_array", "array_item", lhsIsArray = True) | indent12};
</%doc>
<%!
import functools

def quote(str):
    return '"' + str + '"'

def indent(indent_level, str):
    return str.replace("\n", "\n" + " " * indent_level).rstrip()

indent4 = functools.partial(indent, 4)
indent8 = functools.partial(indent, 8)
indent12 = functools.partial(indent, 12)
indent16 = functools.partial(indent, 16)

%>\

<%doc>
Emit the json11 is_*() check for the given value and schema type
</%doc>
<%def name='valueIsOfJsonInputType(json_schema_type, jsonValue)'>\
% if json_schema_type == 'string':
${jsonValue}.is_string()\
% elif json_schema_type == 'integer':
${jsonValue}.is_number()\
% elif json_schema_type == 'number':
${jsonValue}.is_number()\
% elif json_schema_type == 'boolean':
${jsonValue}.is_bool()\
% elif json_schema_type == 'object':
${jsonValue}.is_object()\
% endif
</%def>\

<%doc>
Emit an expression that instantiates a native instance from a json11 value
</%doc>
<%def name='jsonValueForType(variableDef, jsonValue)'>\
% if variableDef.type.schema_type == 'string':
    % if variableDef.type.isEnum:
string_to_${variableDef.json_name}(${jsonValue}.string_value())\
    % else:
${jsonValue}.string_value()\
    % endif
% elif variableDef.type.schema_type == 'integer':
int(${jsonValue}.number_value())\
% elif variableDef.type.schema_type == 'number':
${jsonValue}.number_value()\
% elif variableDef.type.schema_type == 'boolean':
${jsonValue}.bool_value()\
% elif variableDef.type.schema_type == 'object':
${variableDef.type.name}(${jsonValue})\
% endif
</%def>\

<%doc>
Emit an expression that takes a json11 value on the RHS, and assigns to a variable
or emplaces into an array on the lhs.
</%doc>
<%def name='generateBasicAssignmentFromJson(variableDef, lhs, rhs, lhsIsArray = False)'>\
% if lhsIsArray:
${lhs}.emplace_back(${jsonValueForType(variableDef, rhs)});\
% else:
${lhs} = ${jsonValueForType(variableDef, rhs)};\
% endif
</%def>\

<%doc>
Emit full code for an assignment of a json11 value to a native instance. The emitted block
is aware of variant types.
</%doc>
<%def name='generateAssignmentFromJson(variableDef, lhs, rhs, lhsIsArray = False)'>\
% if variableDef.isVariant:
    % for variant in variableDef.variantTypeList():
${"if" if loop.first else "else if"} (${valueIsOfJsonInputType(variant["json_schema_type"], rhs)}\
        % if variant["json_schema_type"] == "object":
 && ${rhs}["${variableDef.variantTypeIdPath}"] == "${variant["json_type_id"]}"\
        % endif
) {
    ${capture(generateBasicAssignmentFromJson, variant["variable_def"], lhs, rhs, lhsIsArray) | indent4}
}
    % endfor
else {
    ${assert_macro}(false); // Expected to find a valid value
}
% else:
${assert_macro}(${valueIsOfJsonInputType(variableDef.type.schema_type, rhs)});
${generateBasicAssignmentFromJson(variableDef, lhs, rhs, lhsIsArray)}
% endif
</%def>\

<%doc>
String validation
</%doc>
<%def name='emit_string_validation_checks(inst_name, var_def)'>\
% if var_def.minLength is not None:
if (${inst_name}.size() < ${var_def.minLength})
    throw out_of_range("${var_def.name} too short");
% endif
% if var_def.maxLength is not None:
if (${inst_name}.size() > ${var_def.maxLength})
    throw out_of_range("${var_def.name} too long");
% endif
% if var_def.pattern:
auto ${var_def.name}_regex = regex(R"_(${var_def.pattern})_", regex_constants::ECMAScript);
if (!regex_match(${inst_name}, ${var_def.name}_regex))
    throw invalid_argument("${var_def.name} doesn't match regex pattern");
% endif
</%def>\

<%doc>
Number validation
</%doc>
<%def name='emit_numeric_validation_checks(inst_name, var_def)'>\
% if var_def.minimum is not None:
<% op = "<=" if var_def.exclusiveMinimum else "<" %>\
if (${inst_name} ${op} ${var_def.minimum})
    throw out_of_range("${var_def.name} too small");
% endif
% if var_def.maximum is not None:
<% op = ">=" if var_def.exclusiveMaximum else ">" %>\
if (${inst_name} ${op} ${var_def.maximum})
    throw out_of_range("${var_def.name} too large");
% endif
</%def>\

<%doc>
Object validation
</%doc>
<%def name='emit_object_validation_checks(inst_name, var_def)'>\
${inst_name}.check_valid();
</%def>\

<%doc>
Variant validation
</%doc>
<%def name='emit_variant_validation_checks(inst_name, var_def)'>\
class ${var_def.name}_validator : public boost::static_visitor<void>
{
public:
% for variant in var_def.variantTypeList():
    % if variant["json_schema_type"] == "object":
    void operator()(const ${variant["native_type"]} &value) const {
        value.check_valid();
    }
    % else:
    void operator()(const ${base.attr.typeMap[variant["json_schema_type"]]} &value) const {
        // TODO - support for multiple variant types is limited
        // value.check_valid();
    }
    % endif
% endfor
};
boost::apply_visitor(${var_def.name}_validator(), ${inst_name});
</%def>\

<%doc>
Array validation
</%doc>
<%def name='emit_array_validation_checks(inst_name, var_def)'>\
% if var_def.minItems is not None:
if (${inst_name}.size() < ${var_def.minItems})
    throw out_of_range("Array ${var_def.name} has too few items");
% endif
% if var_def.maxItems is not None:
if (${inst_name}.size() > ${var_def.maxItems})
    throw out_of_range("Array ${var_def.name} has too many items");
% endif
% if var_def.has_string_validation_checks or var_def.has_numeric_validation_checks or var_def.has_object_validation_checks or var_def.isVariant:
for (const auto &arrayItem : ${inst_name}) {
% if var_def.has_string_validation_checks:
    ${capture(emit_string_validation_checks, "arrayItem", var_def) | indent4}
% endif
% if var_def.has_numeric_validation_checks:
    ${capture(emit_numeric_validation_checks, "arrayItem", var_def) | indent4}
% endif
% if var_def.has_object_validation_checks:
    ${capture(emit_object_validation_checks, "arrayItem", var_def) | indent4}
% endif
% if var_def.isVariant:
    ${capture(emit_variant_validation_checks, "arrayItem", var_def) | indent4}
% endif
}
% endif
</%def>\

<%doc>
Validation for a non-optional instance
</%doc>
<%def name='emit_validation_checks(inst_name, v)'>\
% if v.isArray:
${capture(emit_array_validation_checks, inst_name, v)}
% elif v.has_string_validation_checks:
${capture(emit_string_validation_checks, inst_name, v)}
% elif v.has_numeric_validation_checks:
${capture(emit_numeric_validation_checks, inst_name, v)}
% elif v.has_object_validation_checks:
${capture(emit_object_validation_checks, inst_name, v)}
% elif v.isVariant:
${capture(emit_variant_validation_checks, inst_name, v)}
% endif
</%def>\

<%doc>
This block contains the generated code
</%doc>
<%block name="code">
#include "${classDef.header_file}"

% if assert_macro == "assert":
#include <assert.h>
% endif
% if classDef.has_var_patterns or classDef.has_pattern_properties:
#include <regex>
% endif
% if classDef.has_pattern_properties:
#include <unordered_set>
% endif
#include <vector>

using namespace std;
using namespace json11;

<%
class_name = classDef.name
%>\
% for ns in namespace.split('::'):
namespace ${ns} {
% endfor

<%doc>
Constructor from Json object
</%doc>\
${class_name}::${class_name}(const Json &json) {

    ${assert_macro}(json.is_object());

% for v in classDef.variable_defs:
<%
inst_name = "this->" + v.name
temp_name = v.name + "Temp"
%>\
    auto ${temp_name} = json["${v.json_name}"];
    % if not v.isOptional:
    // required
    {
        % if v.isArray:
        auto &destination_array = ${inst_name};
        %endif
        ${assert_macro}(!${temp_name}.is_null());
    % else:
    // optional
    if ( !${temp_name}.is_null() ) {
        % if v.isArray:
        auto destination_array = decltype(${inst_name})::value_type();
        %endif
    % endif
    % if v.isArray:
        ${assert_macro}(${temp_name}.is_array());
        for( const auto &array_item : ${temp_name}.array_items() ) {
            ${capture(generateAssignmentFromJson, v, "destination_array", "array_item", lhsIsArray = True) | indent12}
        }
        % if v.isOptional:
        // Copy the constructed array into the optional<vector>
        ${inst_name} = destination_array;
        % endif
    % else:
        ${capture(generateAssignmentFromJson, v, inst_name, temp_name) | indent8}
    % endif
    }

% endfor
% if classDef.has_pattern_properties:
<%
assert(len(classDef.pattern_properties) == 1)
pattern, variableDef = classDef.pattern_properties[0]
varType = base.attr.convertType(variableDef)
if (variableDef.type.isEnum):
    varType = class_name + "::" + varType
acceptsAnyKey = (pattern == '.*')
%>\
    // Assign all other properties to pattern properties
    for (const auto kv : json.object_items()) {
        if (!is_valid_key(kv.first)) {
            continue;
        }
    % if variableDef.isArray:
        ${assert_macro}(kv.second.is_array());
        auto destination_array = ${varType}();
        for( const auto array_item : kv.second.array_items() ) {
            ${capture(generateAssignmentFromJson, variableDef, "destination_array", "array_item", lhsIsArray = True) | indent12}
        }
        (*this)[kv.first] = destination_array;
    % else:
        ${capture(generateAssignmentFromJson, variableDef, "(*this)[kv.first]", "kv.second") | indent8}
    % endif
    }
% endif
}

<%doc>
is_valid()
</%doc>\
bool ${class_name}::is_valid() const {
    try {
        check_valid();
    } catch (const exception &) {
        return false;
    }
    return true;
}

<%doc>
check_valid()
</%doc>\
void ${class_name}::check_valid() const {
% for v in classDef.variable_defs:
% if v.has_any_validation_checks:
% if v.isOptional:
    if (${v.name}.is_initialized()) {
        ${capture(emit_validation_checks, v.name + ".get()", v) | indent8}
    }
% else:
    ${capture(emit_validation_checks, v.name, v) | indent4}
% endif
% endif
% endfor
% if classDef.has_pattern_properties:
<%
assert(len(classDef.pattern_properties) == 1)
pattern, variableDef = classDef.pattern_properties[0]
%>\
% if variableDef.has_any_validation_checks:
    for (const auto kv : _patternProperties) {
        // TODO: should embed the actual key value here
        ${capture(emit_validation_checks, "kv.second", variableDef) | indent8}
    }
% endif
% endif
}
\
<%doc>
Helper routine for to_json()
</%doc>\
<%def name='emit_assignment(inst_name, json_path, var_def)'>\
% if var_def.isVariant:
class ${var_def.name}_to_json : public boost::static_visitor<Json>
{
public:
% for variant in v.variantTypeList():
    % if variant["json_schema_type"] == "object":
    Json operator()(const ${variant["native_type"]} &value) const {
        return value.to_json();
    }
    % else:
    Json operator()(const ${base.attr.typeMap[variant["json_schema_type"]]} &value) const {
        return Json(value);
    }
    % endif
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
    object[${json_path}] = jsonArray;
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
    object[${json_path}] = enumStringArray;
}
% else:
object[${json_path}] = Json(${inst_name});
% endif
% elif var_def.isVariant:
object[${json_path}] = boost::apply_visitor(${var_def.name}_to_json(), ${inst_name});
% elif var_def.type.isEnum:
object[${json_path}] = ${var_def.type.enum_def.plain_name}_to_string(${inst_name});
% else:
object[${json_path}] = ${inst_name};
% endif
</%def>\
\
<%doc>
to_json()
</%doc>\
Json ${class_name}::to_json() const {
    ${assert_macro}(is_valid());
    auto object = Json::object();
% for v in classDef.variable_defs:
% if v.isOptional:
    if (${v.name}.is_initialized()) {
        ${capture(emit_assignment, v.name + ".get()", quote(v.json_name), v) | indent8}
% if v.isNullable:
    } else {
        object["${v.json_name}"] = Json(nullptr);
% endif
    }
% else:
    ${capture(emit_assignment, v.name, quote(v.json_name), v) | indent4}
% endif
% endfor
% if classDef.has_pattern_properties:
<%
assert(len(classDef.pattern_properties) == 1)
pattern, variableDef = classDef.pattern_properties[0]
%>\
    for (const auto kv : _patternProperties) {
        ${capture(emit_assignment, "kv.second", "kv.first", variableDef) | indent8}
    }
% endif
    return Json(object);
}
% for v in classDef.variable_defs:
% if v.isVariant:
<%
inst_name = v.name
inst_name = inst_name + "Value" if v.isArray else inst_name
accessor = inst_name + ".get()" if v.isOptional and not v.isArray else inst_name
variant_type_return = "boost::optional<std::string>" if v.isOptional and not v.isArray else "std::string"
%>\

% if v.isArray:
${variant_type_return} ${class_name}::${inst_name}Type(const ${base.attr.arrayItemType(v)}& ${inst_name}) const
% else:
${variant_type_return} ${class_name}::${inst_name}Type() const
% endif
{
% if v.isOptional and not v.isArray:
    if (!${inst_name}.is_initialized()) {
        return boost::none;
    }
% endif
    class ${inst_name}_get_type : public boost::static_visitor<string>
    {
    public:
    % for variant in v.variantTypeList():
        % if variant["json_schema_type"] == "object":
        string operator()(const ${variant["native_type"]} &value) const {
            return ${variant["native_type"]}::${v.variantTypeIdPath}_to_string(value.${v.variantTypeIdPath});
        }
        % else:
        string operator()(const ${base.attr.typeMap[variant["json_schema_type"]]} &value) const {
            return "${variant["json_schema_type"]}";
        }
        % endif
    % endfor
    };
    return boost::apply_visitor(${inst_name}_get_type(), ${accessor});
}
% endif
% endfor
<%doc>
Enum handling: enum_to_string and string_to_enum for all enums in class
</%doc>\
% for enumDef in classDef.enum_defs:

std::string ${class_name}::${enumDef.plain_name}_to_string(const ${class_name}::${enumDef.name} &val)
{
    switch (val) {
    % for v in enumDef.values:
    case ${enumDef.name}::${ v[0].title() + v[1:] }:
        return "${v}";
    % endfor
    }
}

${class_name}::${enumDef.name} ${class_name}::string_to_${enumDef.plain_name}(const std::string &key)
{
    static const std::map<std::string, ${enumDef.name}> values = {
        % for v in enumDef.values:
        { "${v}", ${enumDef.name}::${v[0].title() + v[1:]} },
        % endfor
    };
    // Throws std::out_of_range if an invalid string is passed
    return values.at(key);
}
% endfor
<%doc>

Pattern properties support

</%doc>\
% if classDef.has_pattern_properties:
<%
assert(len(classDef.pattern_properties) == 1)
pattern, variableDef = classDef.pattern_properties[0]
varType = base.attr.convertType(variableDef)
if (variableDef.type.isEnum):
    varType = class_name + "::" + varType
acceptsAnyKey = (pattern == '.*')
%>\

${varType}& ${class_name}::operator[](const std::string &key) {
    ${assert_macro}(is_valid_key(key));
    if (!is_valid_key(key)) {
        throw invalid_argument(string("invalid key ") + key);
    }
    return _patternProperties[key];
}

bool ${class_name}::is_valid_key(const std::string &key) const {
    return !is_intrinsic_key(key)\
% if not acceptsAnyKey:
 && regex_match(key, regex(R"_(${pattern})_", regex_constants::ECMAScript))\
% endif
;
}

bool ${class_name}::has_property(const std::string &key) const {
    return _patternProperties.find(key) != _patternProperties.end();
}

const ${varType}& ${class_name}::get_property_or(const std::string &key, const ${varType} &defaultValue) const {
    auto iter = _patternProperties.find(key);
    return iter != _patternProperties.end() ? iter->second : defaultValue;
}

bool ${class_name}::is_intrinsic_key(const std::string &key) const {
% if len(classDef.variable_defs):
    static unordered_set<string> intrinsicProperties = {
    % for v in classDef.variable_defs:
        "${v.name}"
    % endfor
    };
    return intrinsicProperties.find(key) != intrinsicProperties.end();
% else:
    return false;
% endif
}
% endif

% for ns in reversed(namespace.split('::')):
} // namespace ${ns}
% endfor

</%block>
