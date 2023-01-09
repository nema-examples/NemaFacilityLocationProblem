struct CustomerSolution

    volume_from_facilities::Vector{Float64}

end

struct FacilitySolution
    is_active::Bool
    used_capacity::Float64
    volume_to_customers::Vector{Float64}
end

struct FacilityLocationProblemSolution

    is_feasible::Bool

    objective_value::Float64
    customer_solutions::Vector{CustomerSolution}
    facility_solutions::Vector{FacilitySolution}

end

function solve_flp(facilities::Vector{<:Facility}, customers::Vector{<:Customer})

    model = Model(GLPK.Optimizer)
    set_silent(model)

    # prepare problem

    ## set up design variables
    number_facilities = length(facilities)
    number_customers = length(customers)

    @variable(model, volume_served_facility[1:number_facilities] >= 0.0)
    @variable(model, is_facility_active[1:number_facilities], Bin)
    @variable(model, volume_between_customer_and_facility[1:number_facilities, 1:number_customers] >= 0.0)

    ## compute distances
    distance_customer_and_facility = [
        compute_distance_in_m(f.coordinate, c.coordinate) for f in facilities, c in customers
    ]

    # constraints

    ## link volume to is_facility_active: if a facility is not active, the volume served is 0
    @constraint(
        model,
        linked_volume_to_facility_active[ii in 1:number_facilities],
        volume_served_facility[ii] <= is_facility_active[ii] * facilities[ii].maximum_capacity,
    )

    ## ensure that each customers demand is met
    @constraint(
        model,
        ensure_customer_demand_met[jj in 1:number_customers],
        sum(volume_between_customer_and_facility[ii, jj] for ii in 1:number_facilities) == customers[jj].demand,
    )

    ## link volume served at facility to the volume moved between that facility and its customers
    @constraint(
        model,
        link_volume_served_to_volume_dispatched[ii in 1:number_facilities],
        sum(volume_between_customer_and_facility[ii, jj] for jj in 1:number_customers) == volume_served_facility[ii],
    )

    # objective

    ## add costs
    startup_costs = sum(is_facility_active[ii] * facilities[ii].cost_startup for ii in 1:number_facilities)
    yearly_lease_costs = sum(is_facility_active[ii] * facilities[ii].cost_yearly_lease for ii in 1:number_facilities) # this is wrong
    transportation_costs = sum(
        volume_between_customer_and_facility[ii, jj] * compute_transportation_costs(facilities[ii], distance_customer_and_facility[ii, jj])
        for ii in 1:number_facilities, jj in 1:number_customers
    )

    @objective(model, Min, startup_costs + yearly_lease_costs + transportation_costs)

    # solve
    optimize!(model)

    # extract solution
    is_feasible = termination_status(model) == MOI.OPTIMAL

    sol_volume_between_customer_and_facility = value.(volume_between_customer_and_facility)
    customer_sols = [
        CustomerSolution(
            sol_volume_between_customer_and_facility[:, jj],
        ) for jj in 1:number_customers
    ]

    facility_sols = [
        FacilitySolution(
            value(is_facility_active[ii]) == 1.0,
            sum(sol_volume_between_customer_and_facility[ii, :]),
            sol_volume_between_customer_and_facility[ii, :],
        ) for ii in 1:number_facilities
    ]

    return FacilityLocationProblemSolution(
        is_feasible,
        objective_value(model),
        customer_sols,
        facility_sols,
    )

end