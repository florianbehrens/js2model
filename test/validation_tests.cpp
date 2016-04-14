#include "catch.hpp"

#include "Validation.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::js2model::test;

TEST_CASE( "String validation" ) {

    SECTION( "Min length" ) {
        auto v = Validation();
        v.minLength2 = "a";
        REQUIRE(!v.is_valid());
        v.minLength2 = "abc";
        REQUIRE(v.is_valid());
    }

    SECTION( "Max length" ) {
        auto v = Validation();
        v.maxLength4 = "abc";
        REQUIRE(v.is_valid());
        v.maxLength4 = "abcdef";
        REQUIRE(!v.is_valid());
    }

    SECTION( "Min and max length" ) {
        auto v = Validation();
        v.minLength2MaxLength4 = "a";
        REQUIRE(!v.is_valid());
        v.minLength2MaxLength4 = "abc";
        REQUIRE(v.is_valid());
        v.minLength2MaxLength4 = "abcdef";
        REQUIRE(!v.is_valid());
    }

    SECTION( "Regex patterns" ) {
        auto v = Validation();

        v.uuidString = "de243a26e4064a9aa168bea0851a6817";
        REQUIRE(!v.is_valid()); // fails, doesn't match pattern

        v.uuidString = "DE243A26-E406-4A9A-A168-BEA0851A6817";
        REQUIRE(!v.is_valid()); // fails, uppercase

        v.uuidString = "de243a26-e406-4a9a-a168-bea0851a6817";
        REQUIRE(v.is_valid()); // ok
    }
}

 TEST_CASE( "Integer validation" ) {
     SECTION( "Minimum" ) {
         auto v = Validation();

         v.nonNegativeInt = -5;
         REQUIRE(!v.is_valid()); // fails

         v.nonNegativeInt = 0;
         REQUIRE(v.is_valid()); // ok

         v.nonNegativeInt = 1;
         REQUIRE(v.is_valid()); // ok
     }

     SECTION( "Minimum with exclusiveMinimum" ) {
         auto v = Validation();

         v.positiveInt = -5;
         REQUIRE(!v.is_valid()); // fails

         v.positiveInt = 0;
         REQUIRE(!v.is_valid()); // fails, 0 isn't positive

         v.positiveInt = 1;
         REQUIRE(v.is_valid()); // ok
     }

     SECTION( "Maximum" ) {
         auto v = Validation();

         v.nonPositiveInt = 5;
         REQUIRE(!v.is_valid()); // fails

         v.nonPositiveInt = 0;
         REQUIRE(v.is_valid()); // ok

         v.nonPositiveInt = -1;
         REQUIRE(v.is_valid()); // ok
     }

     SECTION( "Maximum with exclusiveMaximum" ) {
         auto v = Validation();

         v.negativeInt = 5;
         REQUIRE(!v.is_valid()); // fails

         v.negativeInt = 0;
         REQUIRE(!v.is_valid()); // fails, 0 isn't negative

         v.negativeInt = -1;
         REQUIRE(v.is_valid()); // ok
     }

     SECTION( "Ranged" ) {
         auto v = Validation();

         v.rangedInt = -8;
         REQUIRE(!v.is_valid()); // fails, exclusiveMinimum == true

         v.rangedInt = -7;
         REQUIRE(v.is_valid()); // ok

         v.rangedInt = 400;
         REQUIRE(v.is_valid()); // ok, exclusiveMaximum == false

         v.rangedInt = 401;
         REQUIRE(!v.is_valid()); // fails
     }
 }

TEST_CASE( "Floating-point validation" ) {
     SECTION( "Minimum" ) {
         auto v = Validation();

         v.nonNegativeDouble = -.25;
         REQUIRE(!v.is_valid()); // fails

         v.nonNegativeDouble = 0.0;
         REQUIRE(v.is_valid()); // ok

         v.nonNegativeDouble = 0.01;
         REQUIRE(v.is_valid()); // ok
     }

     SECTION( "Minimum with exclusiveMinimum" ) {
         auto v = Validation();

         v.positiveDouble = -0.0525;
         REQUIRE(!v.is_valid()); // fails

         v.positiveDouble = 0.0;
         REQUIRE(!v.is_valid()); // fails, 0 isn't positive

         v.positiveDouble = 1.25;
         REQUIRE(v.is_valid()); // ok
     }

     SECTION( "Maximum" ) {
         auto v = Validation();

         v.nonPositiveDouble = 0.05;
         REQUIRE(!v.is_valid()); // fails

         v.nonPositiveDouble = 0.0;
         REQUIRE(v.is_valid()); // ok

         v.nonPositiveDouble = -0.0001;
         REQUIRE(v.is_valid()); // ok
     }

     SECTION( "Maximum with exclusiveMaximum" ) {
         auto v = Validation();

         v.negativeDouble = 0.000015;
         REQUIRE(!v.is_valid()); // fails

         v.negativeDouble = 0.0;
         REQUIRE(!v.is_valid()); // fails, 0 isn't negative

         v.negativeDouble = -0.00000001;
         REQUIRE(v.is_valid()); // ok
     }

     SECTION( "Ranged" ) {
         auto v = Validation();

         v.rangedDouble = -80.25;
         REQUIRE(!v.is_valid()); // fails

         v.rangedDouble = -8.25;
         REQUIRE(v.is_valid()); // ok, exclusiveMinimum == false

         v.rangedDouble = -7.3;
         REQUIRE(v.is_valid()); // ok

         v.rangedDouble = 15.89;
         REQUIRE(v.is_valid()); // ok

         v.rangedDouble = 16.0;
         REQUIRE(!v.is_valid()); // fails, exclusiveMaximum == true

         v.rangedDouble = 401;
         REQUIRE(!v.is_valid()); // fails
     }
}

TEST_CASE( "Array validation" ) {
     SECTION( "Minimum" ) {
         auto v = Validation();

         v.minArray = vector<int>{ 1 };
         REQUIRE(!v.is_valid());

         v.minArray = vector<int>{ 1, 2 };
         REQUIRE(v.is_valid());
     }

     SECTION( "Maximum" ) {
         auto v = Validation();

         v.maxArray = vector<int>();
         REQUIRE(v.is_valid());

         v.maxArray = vector<int>{ 1, 2, 3, 4, 5, 6, 7, 8 };
         REQUIRE(v.is_valid());

         v.maxArray = vector<int>{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
         REQUIRE(!v.is_valid());
     }

     SECTION( "Range" ) {
         auto v = Validation();

         v.rangedArray = vector<int>();
         REQUIRE(!v.is_valid());

         v.rangedArray = vector<int>{ 1 };
         REQUIRE(v.is_valid());

         v.rangedArray = vector<int>{ 1, 2, 3, 4, 5, 6, 7, 8 };
         REQUIRE(v.is_valid());

         v.rangedArray = vector<int>{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
         REQUIRE(!v.is_valid());
     }
}
