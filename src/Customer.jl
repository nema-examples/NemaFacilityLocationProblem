struct Customer{C<:Coordinate}

    coordinate::C
    demand::Float64

end

Customer(; coordinate::Coordinate, demand::Float64) = Customer(coordinate, demand)