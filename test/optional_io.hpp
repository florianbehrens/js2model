#pragma once

#include <boost/optional.hpp>

namespace boost
{
inline std::ostream& operator << ( std::ostream& os, none_t const& value ) {
    os << "boost::none";
    return os;
}

template<typename T>
std::ostream& operator << ( std::ostream& os, optional<T> const& value ) {
    if (value.is_initialized())
        os << "initialized";
    else
        os << none;
    return os;
}
}

