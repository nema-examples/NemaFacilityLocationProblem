struct Customer{C<:Coordinate}

    ID::String
    coordinate::C
    demand::Float64

end

Customer(; coordinate::Coordinate, demand::Float64, ID::String=randstring(5)) = Customer(ID, coordinate, demand)

struct YearlyCustomerDemand{C<:Customer}

    customers::Vector{C}

end