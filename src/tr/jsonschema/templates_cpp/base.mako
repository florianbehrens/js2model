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
</%doc>\
<%doc>
Maps for mapping JSON types to Obj C types.
</%doc>\
<%!
    typeMap = {
        'string':  'std::string',
        'dict':    'std::unordered_map',
        'integer': 'int',
        'number':  'double',
        'boolean': 'bool',
        'null':    'void',
        'any':     'void'
    }
%>\
<%doc>
Convert a JSON type to an Objective C type.
</%doc>\
<%!
    def itemType(variableDef):

        if variableDef.isVariant:
            typelist = [convertType(x) for x in variableDef.variantDefs]
            cppType = "boost::variant<%s>" % ", ".join(typelist)
        else:
            type = variableDef.type
            cppType = type.name if not type.name in typeMap else typeMap[type.name]

        return cppType

    def convertType(variableDef):

        cppType = itemType(variableDef)

        if variableDef.isArray:
            varType = "std::vector<%s>" % cppType
        else:
            varType = cppType

        if variableDef.isOptional:
            varType = "boost::optional<%s>" % varType

        return varType

    def arrayItemType(variableDef):

        if not variableDef.isArray:
            raise TypeError("Not an array type " + str(variableDef))

        return itemType(variableDef)
%>\
//
//  ${file_name}
//
//  Copyright (c) ${year} FiftyThree, Inc. All rights reserved.
//
//  WARNING: Do NOT manually edit this file.
//  This file was generated by js2model from a JSON schema
//
//  clang-format off
<%block name="code" />\
