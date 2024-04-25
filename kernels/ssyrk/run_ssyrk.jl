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

methods = Dict(
    "ssyrk_opt" => ssyrk_finch_opt,
    "ssyrk_ref" => ssyrk_finch_ref,
)

results = []
for mtx in symmetric_oski 
    A = SparseMatrixCSC(matrixdepot(mtx))
    (n, n) = size(A)
    C = zeros(n, n)
    C_ref = nothing
    for (key, method) in methods
        @info "testing" key mtx
        res = method(C, A)
        time = res.time
        C_ref = something(C_ref, res.C.C)
        norm(res.C.C - C_ref)/norm(C_ref) < 0.1 || @warn("incorrect result via norm")

        @info "results" time
        push!(results, OrderedDict(
            "time" => time,
            "method" => key,
            "matrix" => mtx,
        ))
        write("ssyrk_results.json", JSON.json(results, 4))
    end
end
