#include <iostream>
#include <fstream>

#include "catch.hpp"

#include "ArrayTest.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::models;

static Json LoadTestData() {
    ifstream data("jsonData/array-test.data.json");
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

TEST_CASE( "Array serialization" ) {
    auto testData = LoadTestData();

    SECTION( "Required arrays must be present" ) {
        REQUIRE_THROWS_AS(auto obj = ArrayTest(testData[0]), AssertFailedError);
    }

    SECTION( "Required arrays must pass validation rules" ) {
        auto obj = ArrayTest(testData[1]);
        REQUIRE(obj.requiredArray.size() == 0);
        REQUIRE_FALSE(obj.is_valid());
    }

    SECTION( "Optional arrays don't need to be included, and then shouldn't appear in to_json output" ) {
        auto obj = ArrayTest(testData[2]);
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[2].dump());
    }

    SECTION( "Optional arrays that are present must pass validation rules" ) {
        auto obj = ArrayTest(testData[3]);
        REQUIRE(obj.optionalStrings->size() == 0);
        REQUIRE_FALSE(obj.is_valid());
    }

    SECTION( "Optional arrays should be present in to_json output" ) {
        auto obj = ArrayTest(testData[4]);
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[4].dump());
    }
}

TEST_CASE( "Array type support" ) {
    auto testData = LoadTestData();

    SECTION( "Bool" ) {
        auto data = testData[5];
        auto obj = ArrayTest(data);
        REQUIRE(obj.optionalBools.is_initialized());
        REQUIRE(obj.optionalBools.get()[0] == true);
        REQUIRE(obj.optionalBools.get()[1] == false);
        REQUIRE(obj.to_json().dump() == data.dump());
    }

    SECTION( "Numbers" ) {
        auto data = testData[6];
        auto obj = ArrayTest(data);
        REQUIRE(obj.optionalNumbers.is_initialized());
        REQUIRE(obj.optionalNumbers.get()[0] == 1.25);
        REQUIRE(obj.optionalNumbers.get()[1] == -2.5);
        REQUIRE(obj.to_json().dump() == data.dump());
    }

    SECTION( "Integers" ) {
        auto data = testData[7];
        auto obj = ArrayTest(data);
        REQUIRE(obj.optionalInts.is_initialized());
        REQUIRE(obj.optionalInts.get()[0] == -8);
        REQUIRE(obj.optionalInts.get()[1] == 16);
        REQUIRE(obj.to_json().dump() == data.dump());
    }

    SECTION( "Enums" ) {
        auto data = testData[8];
        auto obj = ArrayTest(data);
        REQUIRE(obj.optionalEnums.is_initialized());
        REQUIRE(obj.optionalEnums.get()[0] == ArrayTest::OptionalEnums::Home);
        REQUIRE(obj.optionalEnums.get()[1] == ArrayTest::OptionalEnums::Work);
        REQUIRE(obj.to_json().dump() == data.dump());
    }

    SECTION( "Objects" ) {
        auto data = testData[9];
        auto obj = ArrayTest(data);
        REQUIRE(obj.optionalObjects.is_initialized());
        REQUIRE(obj.optionalObjects.get()[0].foo.get() == 1);
        REQUIRE(obj.optionalObjects.get()[0].bar.get() == false);
        REQUIRE(obj.optionalObjects.get()[1].foo.get() == 2);
        REQUIRE(obj.optionalObjects.get()[1].bar.get() == true);
        REQUIRE(obj.to_json().dump() == data.dump());
    }

}
