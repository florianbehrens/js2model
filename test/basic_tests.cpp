#define CATCH_CONFIG_MAIN  // This tells Catch to provide a main() - only do this in one cpp file
#include "catch.hpp"

#include "Quickstart.h"

using namespace boost;
using namespace json11;
using namespace std;

using namespace ft::js2model::test;

TEST_CASE( "JSON data can be loaded into classes" ) {
    ifstream data("jsonData/quickstart.data.json");
    stringstream buffer;
    buffer << data.rdbuf();
    string error;
    auto json = Json::parse(buffer.str(), error);
    if (!error.empty()) {
        cerr << "Error loading input data: " << error << endl;
        exit(-1);
    }
    REQUIRE(json.is_array());

    SECTION( "invalid JSON triggers assertion" ) {
        auto item = json[0];
        REQUIRE(item["invalid"] == "invalid");
        REQUIRE_THROWS_AS(auto q = Quickstart(item), AssertFailedError);
    }

    SECTION( "minimal valid JSON is parsed correctly" ) {
        auto item = json[1];
        auto q = Quickstart(item);
        REQUIRE(q.street == "150 Shady Lane");
        REQUIRE(!q.latitude.is_initialized());
        REQUIRE(q.location == Quickstart::Location::Home);
        REQUIRE(q.description.shortDescription == "Home Sweet Home");
        REQUIRE(!q.description.longDescription.is_initialized());
    }

    SECTION( "invalid enum value throws" ) {
        auto item = json[2];
        REQUIRE_THROWS_AS(auto q = Quickstart(item), std::out_of_range);
    }

    SECTION( "JSON with arrays and optionals is parsed correctly" ) {
        auto item = json[3];
        auto q = Quickstart(item);
        REQUIRE(q.street == "150 Shady Lane");
        REQUIRE(q.latitude.get() == Approx(22.5));
        REQUIRE(q.longitude.get() == Approx(46.7777));
        REQUIRE(q.location == Quickstart::Location::Work);
        REQUIRE(q.description.shortDescription == "Home Sweet Home");
        REQUIRE(q.description.longDescription.get() == "a little house");
        REQUIRE(q.phoneNumbers.size() == 4);
        REQUIRE(q.phoneNumbers[0].number == "(206)555-1212");
        REQUIRE(q.phoneNumbers[0].location.get() == PhoneNumbers::Location::Work);
        REQUIRE(q.phoneNumbers[1].number == "(206)555-1212");
        REQUIRE(q.phoneNumbers[1].location.get() == PhoneNumbers::Location::Home);
        REQUIRE(q.phoneNumbers[2].number == "(206)555-1212");
        REQUIRE(q.phoneNumbers[2].location.get() == PhoneNumbers::Location::Mobile);
        REQUIRE(q.phoneNumbers[3].number == "(206)555-1212");
        REQUIRE(!q.phoneNumbers[3].location.is_initialized());
    }

}

TEST_CASE( "JSON data can be dumped out from classes" ) {
    ifstream data("jsonData/quickstart.data.json");
    stringstream buffer;
    buffer << data.rdbuf();
    string error;
    auto json = Json::parse(buffer.str(), error);
    REQUIRE(error.empty());
    REQUIRE(json.is_array());

    SECTION( "minimal valid JSON can be reconstructed correctly" ) {
        auto item = json[1];
        auto q = Quickstart(item);
        REQUIRE(q.to_json().dump() == item.dump());
    }

    SECTION( "JSON with arrays and optionals can be reconstructed correctly" ) {
        auto item = json[3];
        auto q = Quickstart(item);
        REQUIRE(q.to_json().dump() == item.dump());
    }
}
