struct CompanyInformation

    discount_rate::Float64

end

# discount rate with keyword
CompanyInformation(; discount_rate::Float64) = CompanyInformation(discount_rate)