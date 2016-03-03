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
temp_name = v.name + "_temp"
%>\
<%def name="emit_initializer(value, member_name, local_name)">
    % if value.schema_type == 'string':
        if (${temp_name}->value.is_null()) {
        ${inst_name}.clear();
        }
        else {
        assert(${temp_name}->value.IsString());
        ${inst_name} = ${temp_name}->value.GetString();
        }
    %elif value.schema_type == 'integer':
        if (!${temp_name}->value.is_null()) {
        assert(${temp_name}->value.IsInt());
        ${inst_name} = ${temp_name}->value.GetInt();
        }
    %elif value.schema_type == 'boolean':
        if (!${temp_name}->value.is_null()) {
        assert(${temp_name}->value.IsBool());
        ${inst_name} = ${temp_name}->value.GetBool();
        }
    %elif value.schema_type == 'object':
        if (!${temp_name}->value.is_null()) {
        assert(${temp_name}->value.IsObject());
        ${inst_name} = ${value.type}(${temp_name}->value);
        }
    %endif
</%def>

    auto ${temp_name} = json["${v.json_name}"];
% if v.isRequired:
    // required
    assert(!${temp_name}.is_null());
% else:
    // optional
% endif
    if ( !${temp_name}.is_null() ) {

        %if v.isArray:
        for( auto array_item = ${temp_name}->value.Begin(); array_item != ${temp_name}->value.End(); array_item++  ) {

            % if v.schema_type == 'string':
            if (!array_item->is_null()) {
                assert(array_item->IsString());
                ${inst_name}.push_back(array_item->GetString());
            }
            %elif v.schema_type == 'integer':
            assert(array_item->IsInt());
            ${inst_name}.push_back(array_item->GetInt());
            %elif v.schema_type == 'boolean':
            assert(array_item->IsBool());
            ${inst_name}.push_back(array_item->GetBool());
            %elif v.schema_type == 'object':
            assert(array_item->IsObject());
            ${inst_name}.push_back(${v.type}(*array_item));
            %elif v.schema_type == 'array':
            ## TODO: probably need to recursively handle arrays of arrays
            assert(array_item->IsArray());
            vector<${v.type}> item_array;
            ${inst_name}.push_back(${v.type}(item_array));
            %endif
        }
        %else:
        % if v.schema_type == 'string':
        if (${temp_name}->value.is_null()) {
            ${inst_name}.clear();
        }
        else {
            assert(${temp_name}->value.IsString());
            ${inst_name} = ${temp_name}->value.GetString();
        }
        %elif v.schema_type == 'integer':
        if (!${temp_name}->value.is_null()) {
            assert(${temp_name}->value.IsInt());
            ${inst_name} = ${temp_name}->value.GetInt();
        }
        %elif v.schema_type == 'boolean':
        if (!${temp_name}->value.is_null()) {
            assert(${temp_name}->value.IsBool());
            ${inst_name} = ${temp_name}->value.GetBool();
        }
        %elif v.schema_type == 'object':
        if (!${temp_name}->value.is_null()) {
            assert(${temp_name}->value.IsObject());
            ${inst_name} = ${v.type}(${temp_name}->value);
        }
        %endif
        %endif
    }

    % endfor
}

string to_string(const ${class_name} &val, std::string indent/* = "" */, std::string pretty_print/* = "" */) {

    ostringstream os;

    os << indent << "{" << endl;
    % for v in classDef.variable_defs:
<%
    inst_name = base.attr.inst_name(v.name)
%>\
    %if v.isArray:
    os << indent << pretty_print << "\"${v.name}\": [";
    for( auto &array_item : val.${inst_name} ) {

        % if v.schema_type == 'string':
        os << "\"" << array_item << "\",";
        %elif v.schema_type == 'integer':
        os << array_item << ",";
        %elif v.schema_type == 'boolean':
        os << (array_item ? "true" : "false") << ",";
        %elif v.schema_type == 'object':
        os << endl << to_string(array_item, indent + pretty_print + pretty_print, pretty_print) << "," << endl;
##        %elif v.schema_type == 'array':
##        ## TODO: probably need to recursively handle arrays of arrays
##        assert(array_item->IsArray());
##        vector<${v.type}> item_array;
##        ${inst_name}.push_back(${v.type}(item_array));
        %endif
    }
    os << indent << pretty_print << "]," << endl;
    %else:
    % if v.schema_type == 'string':
    os << indent << pretty_print << "\"${v.name}\": \"" << val.${inst_name} << "\"," << endl;
    %elif v.schema_type == 'integer':
    os << indent << pretty_print << "\"${v.name}\": " << val.${inst_name} << "," << endl;
    %elif v.schema_type == 'boolean':
    os << indent << pretty_print << "\"${v.name}\": " << (val.${inst_name} ? "true" : "false") << "," << endl;
    %elif v.schema_type == 'object':
    os << indent << pretty_print << "\"${v.name}\": " << to_string(val.${inst_name}, indent + pretty_print, pretty_print) << "," << endl;
    %endif
    %endif
    % endfor
    os << indent << "}";

    return os.str();
}


<%
staticInitName = classDef.plain_name
%>\
${class_name} ${staticInitName}FromJsonData(const char *data, size_t len) {

    std::vector<char> buffer(len + 1);

    std::memcpy(&buffer[0], data, len);

    Document doc;

    doc.ParseInsitu(&buffer[0]);

    return ${class_name}(doc);
}

${class_name} ${staticInitName}FromFile(string filename) {

    ifstream is;

    stringstream buffer;

    is.open(filename);
    buffer << is.rdbuf();

    ${class_name} instance = ${staticInitName}FromJsonData(buffer.str().c_str(), buffer.str().length());

    return instance;
}

<%
array_var_name = staticInitName + 'Array'
%>\
std::vector<${class_name}> ${staticInitName}ArrayFromData(const char *jsonData, size_t len) {

    std::vector<char> buffer(len + 1);

    std::memcpy(&buffer[0], jsonData, len);

    Document doc;

    doc.ParseInsitu(&buffer[0]);

    assert(doc.IsArray());

    std::vector<${class_name}> ${array_var_name};
    ${array_var_name}.reserve(doc.Size());

    for( auto array_item = doc.Begin(); array_item != doc.End(); array_item++  ) {

        ${class_name} instance = ${class_name}(*array_item);
        ${array_var_name}.push_back(instance);
    }

    return ${array_var_name};
}

} // namespace models
} // namespace ${namespace}

</%block>
