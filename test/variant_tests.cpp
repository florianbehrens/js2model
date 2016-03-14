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

    SECTION( "Fill layer" ) {
        auto obj = Variant(testData[0]);
        const auto &fillLayer = boost::get<FillLayer>(obj.layer);
        REQUIRE(fillLayer.type == FillLayer::Type::Fill);
        REQUIRE(FillLayer::type_to_string(fillLayer.type) == "fill");
        REQUIRE(fillLayer.color.r == 255);
        REQUIRE(fillLayer.color.g == 255);
        REQUIRE(fillLayer.color.b == 0);
        REQUIRE(obj.is_valid());
    }
}
