# Copyright 2023 Max Opgenoord. All Rights Reserved.

using Test
using NemaFacilityLocationProblem


function test_coordinate_2D()

    c1 = Coordinate2D(0.0, 0.0)
    c2 = Coordinate2D(1.0, 1.0)

    @test NemaFacilityLocationProblem.compute_distance_in_m(c1, c2) ≈ sqrt(2)

end

function test_coordinate_lat_long()

    c1 = CoordinateLatLong(0.0, 0.0)
    c2 = CoordinateLatLong(180.0, 0.0)

    @test NemaFacilityLocationProblem.compute_distance_in_m(c1, c2) ≈ π * 6371.0e3

    c1 = CoordinateLatLong(0.0, 0.0)
    c2 = CoordinateLatLong(0.0, 90.0)

    @test NemaFacilityLocationProblem.compute_distance_in_m(c1, c2) ≈ π / 2 * 6371.0e3

end

function test_actual_cities()

    c1 = CoordinateLatLong(41.8781, 87.6298) # chicago
    c2 = CoordinateLatLong(25.7617, 80.1918) # miami

    @test NemaFacilityLocationProblem.compute_distance_in_m(c1, c2) ≈ 1913e3 rtol = 0.02

end


@testset "Coordinates" begin

    test_coordinate_2D()
    test_coordinate_lat_long()
    test_actual_cities()

end