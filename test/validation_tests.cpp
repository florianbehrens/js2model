#include "catch.hpp"

#include "Validation.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::models;

TEST_CASE( "Classes respect validation rules" ) {

    SECTION( "Min length on strings" ) {
        auto v = Validation();
        v.minLength2 = "a";
        REQUIRE(!v.is_valid());
        v.minLength2 = "abc";
        REQUIRE(v.is_valid());
    }

    SECTION( "Max length on strings" ) {
        auto v = Validation();
        v.maxLength4 = "abc";
        REQUIRE(v.is_valid());
        v.maxLength4 = "abcdef";
        REQUIRE(!v.is_valid());
    }

    SECTION( "Min and max length on strings" ) {
        auto v = Validation();
        v.minLength2MaxLength4 = "a";
        REQUIRE(!v.is_valid());
        v.minLength2MaxLength4 = "abc";
        REQUIRE(v.is_valid());
        v.minLength2MaxLength4 = "abcdef";
        REQUIRE(!v.is_valid());
    }

    SECTION( "Regex patterns on strings" ) {
        auto v = Validation();

        v.uuidString = "de243a26e4064a9aa168bea0851a6817";
        REQUIRE(!v.is_valid()); // fails, doesn't match pattern

        v.uuidString = "DE243A26-E406-4A9A-A168-BEA0851A6817";
        REQUIRE(!v.is_valid()); // fails, uppercase

        v.uuidString = "de243a26-e406-4a9a-a168-bea0851a6817";
        REQUIRE(v.is_valid()); // ok
    }
}
