#include "catch.hpp"
#include "load_test_data.hpp"
#include "optional_io.hpp"

#include "PatternPropertiesTest.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::js2model::test;

TEST_CASE( "Pattern properties" ) {
    auto testData = LoadTestData("jsonData/pattern-properties-test.data.json");

    SECTION( "No pattern properties are required" ) {
        auto obj = PatternPropertiesTest(testData[0]);
        REQUIRE(obj.is_valid());
        REQUIRE_FALSE(obj.has_property("anotherDescription"));
        REQUIRE(obj.to_json().dump() == testData[0].dump());
    }

    SECTION( "Pattern properties specifications are enforced" ) {
        REQUIRE_FALSE(PatternPropertiesTest::is_valid_key("location"));
        REQUIRE_FALSE(PatternPropertiesTest::is_valid_key("phoneNumbers"));
        REQUIRE_FALSE(PatternPropertiesTest::is_valid_key("prop_builtinProperty"));

        REQUIRE(PatternPropertiesTest::is_valid_key("prop_XXX"));
        REQUIRE_FALSE(PatternPropertiesTest::is_valid_key("XXX"));
    }

    SECTION( "Pattern properties are subject to validation" ) {
        REQUIRE_THROWS_AS(auto obj = PatternPropertiesTest(testData[1]), out_of_range);

        auto obj = PatternPropertiesTest(testData[2]);
        REQUIRE_FALSE(obj.is_valid());
    }

    SECTION( "Non-matching pattern properties are skipped" ) {
        // locWork doesn't match the pattern
        auto obj = PatternPropertiesTest(testData[3]);
        REQUIRE(obj.is_valid());
        REQUIRE(obj.location.to_json().dump() == "{}");
        REQUIRE(obj.location.dynamic_properties().empty());
    }

    SECTION( "Pattern properties are accepted" ) {
        auto obj = PatternPropertiesTest(testData[4]);
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[4].dump());

        REQUIRE(obj.location.has_property("loc_one"));
        REQUIRE(obj.location.has_property("loc_2"));
        REQUIRE(obj.location.has_property("loc_   ???***"));

        REQUIRE(obj.location["loc_one"] == PatternLocation::Location::Work);
        REQUIRE(obj.location["loc_2"] == PatternLocation::Location::Home);
        REQUIRE(obj.location["loc_   ???***"] == PatternLocation::Location::Home);

        REQUIRE(obj.location.dynamic_properties().size() == 3);
    }

    SECTION( "get_property_or works correctly" ) {
        auto obj = PatternLocation();
        auto key = "loc_number_one";

        // No keys should be set
        REQUIRE_FALSE(obj.has_property(key));

        // get_property_or should return the default value,
        // and not modify the object
        REQUIRE(obj.get_property_or(key, PatternLocation::Location::Home) == PatternLocation::Location::Home);
        REQUIRE_FALSE(obj.has_property(key));

        // Set the value. get_property_or should now return it
        obj[key] = PatternLocation::Location::Work;
        REQUIRE(obj.has_property(key));
        REQUIRE(obj.get_property_or(key, PatternLocation::Location::Home) == PatternLocation::Location::Work);
    }
}
