module NemaFacilityLocationProblem

using Distances: haversine
using JuMP:
    Model,
    @variable,
    set_lower_bound,
    @constraint,
    @objective,
    optimize!,
    termination_status,
    value,
    objective_value,
    set_silent,
    MOI

using Random: randstring

import GLPK

include("Coordinate.jl")
export Coordinate2D, CoordinateLatLong

include("Facility.jl")
export Facility, SimpleTransportationCosts, LocalVsNationalTransportationCosts

include("Customer.jl")
export Customer, YearlyCustomerDemand

include("CompanyInformation.jl")
export CompanyInformation

include("solve_flp.jl")
export solve_flp

end # module
