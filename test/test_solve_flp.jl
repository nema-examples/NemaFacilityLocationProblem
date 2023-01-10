# Copyright 2023 Max Opgenoord. All Rights Reserved.

using Test
using NemaFacilityLocationProblem


function test_small_flp_single_year()

    xf_coordinates = [0.0, 0.0, 1.0, 1.0]
    yf_coordinates = [0.0, 1.0, 1.0, 0.0]
    transportation_costs = [0.4, 0.35, 0.45, 0.42]

    max_facility_capacity = 500.0
    startup_cost_single_facility = 100.0

    facilities = [
        Facility(
            coordinate=Coordinate2D(x, y),
            maximum_capacity=max_facility_capacity,
            yearly_operating_costs=200.0,
            cost_startup=startup_cost_single_facility,
            transportation_costs=SimpleTransportationCosts(tc)
        ) for (x, y, tc) in zip(xf_coordinates, yf_coordinates, transportation_costs)
    ]

    xc_coordinates = [0.5, -1, -1, 2.0, 2.0]
    yc_coordinates = [0.5, -1, 2.0, 2.0, -1.0]
    customer_demand = [350.0, 250.0, 150.0, 400, 550.0]

    customers = [
        Customer(
            coordinate=Coordinate2D(x, y),
            demand=d,
        ) for (x, y, d) in zip(xc_coordinates, yc_coordinates, customer_demand)
    ]

    result = solve_flp(facilities, customers)

    @test result.is_feasible

    # customer 1 (which is equidistant from the other nodes) needs to be served by facility 2 as that has the cheapest transportation costs
    @test result.customer_solutions[1].volume_from_facilities[2] == 350.0

    # check that customer demand is met exactly
    for (customer_result, demand) in zip(result.customer_solutions, customer_demand)
        @test sum(customer_result.volume_from_facilities) == demand
    end

    # check that facility capacity is not exceeded
    for facility_result in result.facility_solutions
        @test sum(facility_result.volume_to_customers) <= max_facility_capacity
    end

    # every facility needs to be used because the demand cannot be served with only three facilities
    @test result.total_startup_costs == 4 * startup_cost_single_facility

end


@testset "Solve FLP" begin

    test_small_flp_single_year()

end