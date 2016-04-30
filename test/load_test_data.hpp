#pragma once

#include <iostream>
#include <fstream>

#include <json11/json11.hpp>

inline json11::Json LoadTestData(const std::string & fileName) {
    std::ifstream data(fileName);
    std::stringstream buffer;
    buffer << data.rdbuf();
    std::string error;
    auto testData = json11::Json::parse(buffer.str(), error);
    if (!error.empty()) {
        std::cerr << "Error loading input data: " << error << std::endl;
        exit(-1);
    }
    return testData;
}

