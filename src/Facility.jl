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

    cost_yearly_lease::Float64
    cost_startup::Float64
    transportation_costs::TC

end

function Facility(;
    coordinate::Coordinate,
    maximum_capacity::Float64,
    cost_yearly_lease::Float64,
    cost_startup::Float64,
    transportation_costs::TransportationCosts
)

    return Facility(
        coordinate,
        maximum_capacity,
        cost_yearly_lease,
        cost_startup,
        transportation_costs,
    )

end

compute_transportation_costs(f::Facility, args...) = compute_transportation_costs(f.transportation_costs, args...)