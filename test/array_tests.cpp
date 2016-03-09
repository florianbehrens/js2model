#include <iostream>
#include <fstream>

#include "catch.hpp"

#include "ArrayTest.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::models;

TEST_CASE( "Array serialization" ) {

    ifstream data("jsonData/array-test.data.json");
    stringstream buffer;
    buffer << data.rdbuf();
    string error;
    auto testData = Json::parse(buffer.str(), error);
    if (!error.empty()) {
        cerr << "Error loading input data: " << error << endl;
        exit(-1);
    }
    REQUIRE(testData.is_array());

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
        REQUIRE(obj.optionalArray->size() == 0);
        REQUIRE_FALSE(obj.is_valid());
    }

    SECTION( "Optional arrays should be present in to_json output" ) {
        auto obj = ArrayTest(testData[4]);
        REQUIRE(obj.is_valid());
        REQUIRE(obj.to_json().dump() == testData[4].dump());
    }
}
