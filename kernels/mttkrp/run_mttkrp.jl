using MatrixDepot
using BenchmarkTools
using ArgParse
using DataStructures
using JSON
using SparseArrays
using Printf
using LinearAlgebra
using Finch

include("mttkrp_finch.jl")

size_sparsities = [(100, 0.5), (100, 0.1), 
                    (200, 0.5), (200, 0.1), (200, 0.05), 
                    (500, 0.1), (500, 0.01), (500, 0.001), 
                    (750, 0.1), (750, 0.05), (750, 0.01), (750, 0.005), (750, 0.001),
                    (1000, 0.1), (1000, 0.05), (1000, 0.01), (1000, 0.005), (1000, 0.001)]
methods = Dict(
    "mttkrp_ref" => mttkrp_finch_ref,
    "mttkrp_opt" => mttkrp_finch_opt,
)

results = []
for (n, sp) in size_sparsities
    triA = fsprand(n, n, n, sp)
    A = [triA[sort([i, j, k])...] for i = 1:n, j = 1:n, k = 1:n]
    B = rand(n, n)   
    C = zeros(n, n)
    C_ref = nothing
    for (key, method) in methods
        @info "testing" key n sp
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
            "sparsity" => sp,
            "size" => n,
        ))
        write("mttkrp_results.json", JSON.json(results, 4))
    end
end
# test for both sparse and dense