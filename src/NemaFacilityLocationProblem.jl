module NemaFacilityLocationProblem

using Distances: haversine
using JuMP
import GLPK

include("Coordinate.jl")
export Coordinate2D, CoordinateLatLong

include("Facility.jl")
export Facility, SimpleTransportationCosts

include("Customer.jl")
export Customer

include("solve_flp.jl")
export solve_flp

end # module
