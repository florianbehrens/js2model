#include "UTF8Utils.h"

using namespace std;

size_t js2model::utf8_codepoint_count(const string &input) {
    size_t count = 0;
    for (const auto &byte : input) {
        // Count all bytes except continuation bytes
        // https://en.wikipedia.org/wiki/UTF-8#Description
        if ((byte & 0xC0) != 0x80) {
            ++count;
        }
    }
    return count;
}
