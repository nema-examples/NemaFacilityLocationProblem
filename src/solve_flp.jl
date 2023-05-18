struct CustomerSolution

    ID::String
    volume_from_facilities::Vector{Float64}

end

struct CustomerSolutionSingleYear

    customers::Vector{CustomerSolution}
    year::Int64

end

struct FacilitySolution
    ID::String
    is_active::Bool
    used_capacity::Float64
    volume_to_customers::Vector{Float64}
end

struct FacilitySolutionSingleYear

    facilities::Vector{FacilitySolution}
    year::Int64

end

struct FacilityLocationProblemSolution

    is_feasible::Bool

    objective_value::Float64
    customer_solutions_per_year::Vector{CustomerSolutionSingleYear}
    facility_solutions_per_year::Vector{FacilitySolutionSingleYear}

    total_costs::Float64
    total_startup_costs::Float64
    total_shutdown_costs::Float64
    total_facility_operating_costs::Float64
    total_transportation_costs::Float64

end

function solve_flp(
    facilities::Vector{<:Facility},
    customer_demand_per_year::Vector{<:YearlyCustomerDemand},
    company_info::CompanyInformation,
)

    model = Model(GLPK.Optimizer)
    set_silent(model)

    # prepare problem

    ## set up design variables
    number_facilities = length(facilities)
    number_customers_per_year = [length(cd.customers) for cd in customer_demand_per_year]
    customer_names = [[c.ID for c in cd.customers] for cd in customer_demand_per_year]
    number_years = length(customer_demand_per_year)
    years = [d.year for d in customer_demand_per_year]

    @variable(model, volume_served_facility[1:number_facilities, 1:number_years] >= 0.0)
    @variable(model, is_facility_active[1:number_facilities, 1:number_years], Bin)
    volume_between_customer_and_facility = [@variable(model, [1:number_facilities, 1:number_customers]) for number_customers in number_customers_per_year]
    for v in volume_between_customer_and_facility
        set_lower_bound.(v, 0.0)
    end

    ## compute distances
    distance_customer_and_facility_per_year = [
        [
            compute_distance_in_m(f.coordinate, c.coordinate) for f in facilities, c in this_year.customers
        ] for this_year in customer_demand_per_year
    ]

    # constraints

    ## link volume to is_facility_active: if a facility is not active, the volume served is 0
    for idx_year in 1:number_years, idx_facility in 1:number_facilities
        @constraint(
            model,
            volume_served_facility[idx_facility, idx_year] <= is_facility_active[idx_facility, idx_year] * facilities[idx_facility].maximum_capacity,
        )
    end

    ## ensure that each customers demand is met
    for idx_year in 1:number_years, idx_customer in 1:number_customers_per_year[idx_year]
        customers = customer_demand_per_year[idx_year].customers
        @constraint(
            model,
            sum(volume_between_customer_and_facility[idx_year][ii, idx_customer] for ii in 1:number_facilities) == customers[idx_customer].demand,
        )
    end

    ## link volume served at facility to the volume moved between that facility and its customers
    for idx_year in 1:number_years, idx_facility in 1:number_facilities
        number_customers = length(customer_demand_per_year[idx_year].customers)
        @constraint(
            model,
            sum(volume_between_customer_and_facility[idx_year][idx_facility, jj] for jj in 1:number_customers) == volume_served_facility[idx_facility, idx_year],
        )
    end

    # objective

    ## add costs
    discount_rate = company_info.discount_rate

    facility_operating_costs = [
        is_facility_active[ii, idx_year] * facilities[ii].yearly_operating_costs / (1 + discount_rate)^(idx_year - 1)
        for ii in 1:number_facilities, idx_year in 1:number_years
    ]
    total_facility_operating_costs = sum(facility_operating_costs)

    transportation_costs_per_year = [sum(
        volume_between_customer_and_facility[idx_year][ii, jj] * compute_transportation_costs(facilities[ii], distance_customer_and_facility_per_year[idx_year][ii, jj]) /
        (1 + discount_rate)^(idx_year - 1)
        for ii in 1:number_facilities, jj in 1:length(customer_demand_per_year[idx_year].customers)
    ) for idx_year in 1:number_years]

    ## add startup costs
    startup_costs = @variable(model, [1:number_facilities, 1:number_years])
    shutdown_costs = @variable(model, [1:number_facilities, 1:number_years])
    set_lower_bound.(startup_costs, 0.0)
    set_lower_bound.(shutdown_costs, 0.0)

    for (idx_facility, f) in enumerate(facilities)
        # the startup/shutdown costs for the first year depend on whether the facility is already in operation
        @constraint(model, startup_costs[idx_facility, 1] >= f.cost_startup * (is_facility_active[idx_facility, 1] - f.is_already_in_operation))
        @constraint(model, shutdown_costs[idx_facility, 1] >= f.cost_shutdown * (f.is_already_in_operation - is_facility_active[idx_facility, 1]))
    end

    for (idx_facility, f) in enumerate(facilities), idx_year in 1:number_years-1
        discount_term = 1.0 / (1 + discount_rate)^(idx_year - 1)
        @constraint(model, startup_costs[idx_facility, idx_year] >= f.cost_startup * (is_facility_active[idx_facility, idx_year+1] - is_facility_active[idx_facility, idx_year]) * discount_term)
        @constraint(model, shutdown_costs[idx_facility, idx_year] >= f.cost_shutdown * (is_facility_active[idx_facility, idx_year] - is_facility_active[idx_facility, idx_year+1]) * discount_term)
    end

    total_cost = total_facility_operating_costs + sum(transportation_costs_per_year) + sum(startup_costs) + sum(shutdown_costs)

    @objective(model, Min, total_cost)

    # solve
    optimize!(model)

    # extract solution
    is_feasible = termination_status(model) == MOI.OPTIMAL

    sol_volume_between_customer_and_facility = [value.(v) for v in volume_between_customer_and_facility]
    customer_sols = [
        CustomerSolutionSingleYear([
                CustomerSolution(
                    customer_name,
                    sol_volume_between_customer_and_facility[idx_year][:, jj],
                ) for (jj, customer_name) in enumerate(current_year_customer_names)
            ],
            years[idx_year]) for (idx_year, current_year_customer_names) in zip(1:number_years, customer_names)
    ]

    facility_sols = [
        FacilitySolutionSingleYear([
                FacilitySolution(
                    facilities[ii].ID,
                    value(is_facility_active[ii, idx_year]) == 1.0,
                    sum(sol_volume_between_customer_and_facility[idx_year][ii, :]),
                    sol_volume_between_customer_and_facility[idx_year][ii, :]
                ) for ii in 1:number_facilities
            ],
            years[idx_year]) for idx_year in 1:number_years
    ]

    sol_total_costs = value(total_cost)
    sol_total_startup_costs = value(sum(startup_costs))
    sol_total_shutdown_costs = value(sum(shutdown_costs))
    sol_total_facility_operating_costs = value(total_facility_operating_costs)
    sol_total_transportation_costs = value(sum(transportation_costs_per_year))

    return FacilityLocationProblemSolution(
        is_feasible,
        objective_value(model),
        customer_sols,
        facility_sols,
        sol_total_costs,
        sol_total_startup_costs,
        sol_total_shutdown_costs,
        sol_total_facility_operating_costs,
        sol_total_transportation_costs,
    )

end

struct FacilityLocationProblemSolutionSingleYear

    is_feasible::Bool

    objective_value::Float64
    customer_solutions::Vector{CustomerSolution}
    facility_solutions::Vector{FacilitySolution}

    total_costs::Float64
    total_startup_costs::Float64
    total_shutdown_costs::Float64
    total_facility_operating_costs::Float64
    total_transportation_costs::Float64

end

function solve_flp(facilities::Vector{<:Facility}, customers::Vector{<:Customer})

    # single year

    yearly_customer_demand = [YearlyCustomerDemand(customers, 0)]

    # if only one year, discount rate does not matter
    company_info = CompanyInformation(0.0)

    solution_per_year = solve_flp(facilities, yearly_customer_demand, company_info)

    return FacilityLocationProblemSolutionSingleYear(
        solution_per_year.is_feasible,
        solution_per_year.objective_value,
        solution_per_year.customer_solutions_per_year[1].customers,
        solution_per_year.facility_solutions_per_year[1].facilities,
        solution_per_year.total_costs,
        solution_per_year.total_startup_costs,
        solution_per_year.total_shutdown_costs,
        solution_per_year.total_facility_operating_costs,
        solution_per_year.total_transportation_costs,
    )

end