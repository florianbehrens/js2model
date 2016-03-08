High

[x] `to_json` not done yet
[x] Enum initialization from JSON: totally wrong
[ ] Enums nested in classes, or placed in root include file, but not in separate includes
[ ] Implement `is_valid`
[ ] Rationalize required vs. optional arrays
[x] Support "required" array

Medium

[ ] Could nest schema classes as appropriate
[x] Optional parameters should be emitted as boost::optional<T>
[ ] Add directive to bypass precommit/clang-format
[ ] Ctors that force you to fill all values...maybe. Tends to be annoying when there are many values.
[ ] Default values...does JSON Schema support those? It must.
[ ] Default + optional: shouldn't be optional, should just get the default
[x] More testing around arrays - not sure that's correct

Low

[ ] Support `pattern` for string types
[ ] Support min/max for numerics

