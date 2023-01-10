abstract type TransportationCosts end


struct SimpleTransportationCosts <: TransportationCosts

    cost_per_m::Float64

end

function compute_transportation_costs(TC::SimpleTransportationCosts, distance_m::Float64)

    return TC.cost_per_m * distance_m

end

struct Facility{C<:Coordinate,TC<:TransportationCosts}

    coordinate::C
    maximum_capacity::Float64
    is_already_in_operation::Bool

    yearly_operating_costs::Float64
    cost_startup::Float64
    cost_shutdown::Float64
    transportation_costs::TC

end

function Facility(;
    coordinate::Coordinate,
    maximum_capacity::Float64,
    yearly_operating_costs::Float64,
    transportation_costs::TransportationCosts,
    cost_startup::Float64=0.0,
    cost_shutdown::Float64=0.0,
    is_already_in_operation::Bool=false
)

    return Facility(
        coordinate,
        maximum_capacity,
        is_already_in_operation,
        yearly_operating_costs,
        cost_startup,
        cost_shutdown,
        transportation_costs,
    )

end

compute_transportation_costs(f::Facility, args...) = compute_transportation_costs(f.transportation_costs, args...)
