abstract type Coordinate end

struct Coordinate2D <: Coordinate

    x_m::Float64
    y_m::Float64

end

function compute_distance_in_m(x1::Coordinate2D, x2::Coordinate2D)

    return sqrt((x2.x_m - x1.x_m)^2 + (x2.y_m - x1.y_m)^2)

end

struct CoordinateLatLong <: Coordinate

    latitude::Float64
    longitude::Float64

end

function compute_distance_in_m(x1::CoordinateLatLong, x2::CoordinateLatLong)

    return haversine([x1.longitude, x1.latitude], [x2.longitude, x2.latitude], 6371.0e3)

end

