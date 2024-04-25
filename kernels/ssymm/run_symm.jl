using MatrixDepot
using BenchmarkTools
using ArgParse
using DataStructures
using JSON
using SparseArrays
using Printf
using LinearAlgebra
using Finch

include("ssymm_finch.jl")

symmetric_oski = [
    # "Boeing/ct20stif", # julia killed
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

methods = Dict(
    "ssymm_ref" => ssymm_finch_ref,
    "ssymm_opt" => ssymm_finch_opt,
)

results = []
for mtx in symmetric_oski 
    A = SparseMatrixCSC(matrixdepot(mtx))
    (n, n) = size(A)
    B = rand(n, n)
    C = zeros(n, n)
    C_ref = nothing
    for (key, method) in methods
        @info "testing" key mtx
        res = method(C, A, B)
        time = res.time
        C_res = nothing
        try
            C_res = res.C.C
        catch
            C_res = res.C
        end
        C_ref = something(C_ref, C_res)
        norm(C_res - C_ref)/norm(C_ref) < 0.1 || @warn("incorrect result via norm")

        @info "results" time
        push!(results, OrderedDict(
            "time" => time,
            "method" => key,
            "matrix" => mtx,
        ))
        write("ssymm_results.json", JSON.json(results, 4))
    end
end
