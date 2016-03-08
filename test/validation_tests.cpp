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
}
