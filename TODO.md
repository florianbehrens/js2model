High

[x] `to_json` not done yet
[x] Enum initialization from JSON: totally wrong
[x] Enums nested in classes, or placed in root include file, but not in separate includes
[x] Implement `is_valid`
[x] Support "required" array
[x] Support `pattern` for string types
[x] Support min/max for numerics
[x] Rationalize required vs. optional arrays
[x] Array size validation
[x] `to_json` broken for arrays
[x] Remove debugging code
[x] ~~Nested class names should probably default to title property if passed~~ Can use `typeName` property
[x] Remove base.hpp
[x] Remove models.h
[x] Don't emit empty classes (see Common.cpp)
[x] Different namespace to avoid conflicts (`schema`)
[x] Validation checks incorrect for arrays

Medium

[x] Optional parameters should be emitted as boost::optional<T>
[x] More testing around arrays - not sure that's correct
[x] Remove `additional_properties` support
[x] Emitting empty `is_valid` checks for optionals
[ ] `enum` is a modifier that should work on any type
    works: { "enum": [ "a", "b", c"] }
    fails: { "type": "string",
             "enum": [ "a", "b", c"] }

Low

[ ] Could nest schema classes as appropriate
[x] Add directive to bypass precommit/clang-format
[ ] Ctors that force you to fill all values...maybe. Tends to be annoying when there are many values.
