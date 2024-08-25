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

include("ssyrk_finch.jl")
include("ssyrk_taco.jl")

symmetric_oski = [
    # "Boeing/ct20stif", # OOM error
    "Simon/olafu",
    "Boeing/bcsstk35",
    "Boeing/crystk02",
    "Boeing/crystk03",
    # "Nasa/nasasrb", # OOM error
    "Rothberg/3dtube",
    "Simon/raefsky4",
    # "Mulvey/finan512", # OOM error
    "Pothen/pwt",
    "Cote/vibrobox",
    "HB/saylr4",
]


unsymmetric_oski = [
    "Simon/raefsky3",
    # "Simon/venkat01", # OOM error
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
    # "Shyy/shyy161", # OOM error
    "Wang/wang3",
]

methods = Dict(
    "ssyrk_opt" => ssyrk_finch_opt,
    "ssyrk_ref" => ssyrk_finch_ref,
    # "ssyrk_taco" => ssyrk_taco, # skip due to TACO sparse output problem
)

results = []
for (symmetric, dataset) in [(true, symmetric_oski), (false, unsymmetric_oski)]
    for mtx in dataset 
        A = SparseMatrixCSC(matrixdepot(mtx)) 
        if !symmetric
            A += transpose(A)
        end
        (n, n) = size(A)
        C = zeros(n, n)
        C_ref = nothing
        for (key, method) in methods
            @info "testing" key mtx
            res = method(C, A)
            time = res.time
            C_res = nothing
            try
                C_res = res.C.C
            catch
                C_res = res.C
            end
            C_ref = something(C_ref, C_res)
            norm(C_res - C_ref)/norm(C_ref) < 0.1 || throw("Incorrect result via norm")

            @info "results" time
            push!(results, OrderedDict(
                "time" => time,
                "method" => key,
                "matrix" => mtx,
            ))
            write("ssyrk_results.json", JSON.json(results, 4))
        end
    end
end
