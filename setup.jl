using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(PackageSpec(path = joinpath(@__DIR__, "deps/SySTeC")))
Pkg.instantiate()
