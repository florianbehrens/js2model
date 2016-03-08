#define CATCH_CONFIG_MAIN  // This tells Catch to provide a main() - only do this in one cpp file
#include "catch.hpp"

#include <boost/optional.hpp>
#include <sstream>

#include "models.h"

using namespace json11;
using namespace boost;
using namespace std;

// FIXME wrong namespace
using namespace tr::models;

TEST_CASE( "JSON data can be loaded into classes" ) {
    ifstream data("jsonData/quickstart.data.json");
    stringstream buffer;
    buffer << data.rdbuf();
    string error;
    auto json = Json::parse(buffer.str(), error);
    REQUIRE(error.empty());
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
        REQUIRE(q.location == Location::Home);
    }
}

