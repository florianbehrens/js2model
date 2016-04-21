#include <iostream>
#include <fstream>

#include "catch.hpp"
#include "optional_io.hpp"

#include "PatternPropertiesTest.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::js2model::test;

static Json LoadTestData() {
    ifstream data("jsonData/pattern-properties-test.data.json");
    stringstream buffer;
    buffer << data.rdbuf();
    string error;
    auto testData = Json::parse(buffer.str(), error);
    if (!error.empty()) {
        cerr << "Error loading input data: " << error << endl;
        exit(-1);
    }
    return testData;
}

TEST_CASE( "Pattern properties" ) {
    auto testData = LoadTestData();

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
    }

    SECTION( "Pattern properties are accepted" ) {
        auto obj = PatternPropertiesTest(testData[4]);
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[4].dump());
    }
}
