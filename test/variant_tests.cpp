#include <iostream>
#include <fstream>

#include "catch.hpp"

#include "Variant.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::js2model::test;

static Json LoadTestData() {
    ifstream data("jsonData/variant.data.json");
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

TEST_CASE( "Test" ) {
    auto testData = LoadTestData();

    SECTION( "Test" ) {
        auto obj = Variant(testData[0]);
        REQUIRE(obj.fill.get().type == FillLayer::Type::Fill);
        REQUIRE(obj.fill.get().color.r == 255);
        REQUIRE(obj.fill.get().color.g == 255);
        REQUIRE(obj.fill.get().color.b == 0);
        REQUIRE(obj.is_valid());
    }
}
