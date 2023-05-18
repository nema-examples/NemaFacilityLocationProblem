struct Customer{C<:Coordinate}

    ID::String
    coordinate::C
    demand::Float64

end

Customer(; coordinate::Coordinate, demand::Union{Float64,Int64}, ID::String=randstring(5)) = Customer(ID, coordinate, Float64(demand))

struct YearlyCustomerDemand{C<:Customer}

    customers::Vector{C}
    year::Int64

end