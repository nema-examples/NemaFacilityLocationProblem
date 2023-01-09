# Copyright 2023 Max Opgenoord. All Rights Reserved.

using Test

@info "Started running all tests"

@testset "All tests" begin

    for testfilename in filter(x -> occursin("test_", x) && occursin(".jl", x), readdir(joinpath(@__DIR__, ".")))
        include(testfilename)
    end

    runtests_filename = "runtests.jl"

    for testfolder in filter(x -> isdir(joinpath(@__DIR__, x)), readdir(joinpath(@__DIR__, ".")))
        flname = joinpath(@__DIR__, testfolder, runtests_filename)
        if isfile(flname)
            include(flname)
        end
    end

end
