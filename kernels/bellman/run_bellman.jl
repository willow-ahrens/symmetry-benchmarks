if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(joinpath(@__DIR__, "../.."))
    Pkg.instantiate()
end
using MatrixDepot
using BenchmarkTools
using ArgParse
using DataStructures
using JSON
using SparseArrays
using Printf
using LinearAlgebra
using Finch

include("bellman_finch.jl")
include("bellman_taco.jl")

symmetric_oski = [
    "Boeing/ct20stif",
    "Simon/olafu",
    "Boeing/bcsstk35",
    "Boeing/crystk02",
    "Boeing/crystk03",
    "Nasa/nasasrb",
    "Simon/raefsky4",
    "Mulvey/finan512",
    "Cote/vibrobox",
    "HB/saylr4",
]

unsymmetric_oski = [
    "Simon/raefsky3",
    "Simon/venkat01", 
    "FIDAP/ex11",
    "Zitney/rdist1",
    "HB/orani678",
    "Goodwin/rim",
    "Hamm/memplus",
    "HB/gemat11",
    "Mallya/lhr10",
    "Goodwin/goodwin",
    "Grund/bayer02",
    "Grund/bayer10",
    "Brethour/coater2",
    "ATandT/onetone2",
    "Wang/wang4",
    "HB/lnsp3937",
    "HB/sherman5",
    "HB/sherman3",
    "Shyy/shyy161", 
    "Wang/wang3",
]

methods = Dict(
    "bellman_finch_ref" => bellman_finch_ref,
    "bellman_finch_opt" => bellman_finch_opt,
    "bellman_taco" => bellman_taco,
)

results = []
for (symmetric, dataset) in [(true, symmetric_oski), (false, unsymmetric_oski)]
    for mtx in dataset 
        A = SparseMatrixCSC(matrixdepot(mtx))
        if !symmetric
            A += transpose(A)
        end
        A = set_fill_value!(Tensor(A), Inf)
        (n, n) = size(A)
        x = rand(n)
        y = zeros(n)
        y_ref = nothing
        for (key, method) in methods
            @info "testing" key mtx
            res = method(y, A, x)
            time = res.time
            y_res = res.y
            y_ref = something(y_ref, y_res)
            norm(y_res - y_ref)/norm(y_ref) < 0.1 || @warn("Incorrect result via norm")

            @info "results" time
            push!(results, OrderedDict(
                "time" => time,
                "method" => key,
                "matrix" => mtx,
            ))
            write("bellman_results.json", JSON.json(results, 4))
        end
    end
end
