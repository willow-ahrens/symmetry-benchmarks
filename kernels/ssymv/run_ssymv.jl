using MatrixDepot
using BenchmarkTools
using ArgParse
using DataStructures
using JSON
using SparseArrays
using Printf
using LinearAlgebra
using Finch

include("spmv_mkl.jl")
include("symv_mkl.jl")
include("ssymv_finch.jl")

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
    "ssymv_ref" => ssymv_finch_ref,
    "ssymv_opt" => ssymv_finch_opt,
)

results = []
for mtx in symmetric_oski 
    A = SparseMatrixCSC(matrixdepot(mtx))
    (n, n) = size(A)
    x = rand(n)
    y = zeros(n)
    y_ref = nothing
    for (key, method) in methods
        @info "testing" key mtx
        res = method(y, A, x)
        time = res.time
        y_ref = something(y_ref, res.y.y)
        norm(res.y.y - y_ref)/norm(y_ref) < 0.1 || @warn("incorrect result via norm")

        @info "results" time
        push!(results, OrderedDict(
            "time" => time,
            "method" => key,
            "matrix" => mtx,
        ))
        write("ssymv_results.json", JSON.json(results, 4))
    end
end
