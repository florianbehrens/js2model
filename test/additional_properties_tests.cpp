#include "catch.hpp"
#include "load_test_data.hpp"
#include "optional_io.hpp"

#include "AdditionalPropertiesTest.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::js2model::test;

TEST_CASE( "Additional properties" ) {
    auto testData = LoadTestData("jsonData/additional-properties-test.data.json");

    SECTION( "No additional properties are required" ) {
        auto obj = AdditionalPropertiesTest(testData[0]);
        REQUIRE(obj.is_valid());
        REQUIRE_FALSE(obj.has_property("anotherDescription"));
        REQUIRE(obj.to_json().dump() == testData[0].dump());
    }

    SECTION( "Additional properties are accepted" ) {
        auto obj = AdditionalPropertiesTest(testData[1]);
        REQUIRE(obj.has_property("anotherDescription"));
        REQUIRE(obj["anotherDescription"].shortDescription == "another is short");
        REQUIRE(obj["anotherDescription"].longDescription.get() == "another is long");
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[1].dump());
    }

    SECTION( "Additional properties are subject to validation" ) {
        REQUIRE_THROWS_AS(auto obj = AdditionalPropertiesTest(testData[2]), AssertFailedError);
    }

    SECTION( "Additional properties with crazy keys are accepted" ) {
        auto obj = AdditionalPropertiesTest(testData[3]);
        REQUIRE(obj.has_property("*** ??? !!! :)"));
        REQUIRE(obj["*** ??? !!! :)"].shortDescription == "is short");
        REQUIRE(obj["*** ??? !!! :)"].longDescription == boost::none);
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[3].dump());
    }

}
