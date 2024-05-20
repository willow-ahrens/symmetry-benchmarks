using MatrixDepot
using BenchmarkTools
using ArgParse
using DataStructures
using JSON
using SparseArrays
using Printf
using LinearAlgebra
using Finch
using TensorMarket
using HDF5

include("mttkrp_finch.jl")
include("mttkrp_taco.jl")
include("mttkrp_splatt.jl")

frostt_tensors = [
    "nell-2"
]
rank = [10]
methods = Dict(
    "mttkrp_finch_ref" => mttkrp_finch_ref,
    "mttkrp_finch_opt" => mttkrp_finch_opt,
    "mttkrp_taco" => mttkrp_taco,
    "mttkrp_splatt" => mttkrp_splatt,
)

results = []
for r in rank
    for tn in frostt_tensors
        A = fread("../../data/order-3/$(tn).bsp.h5")
        B = rand(n, r)   
        C = zeros(n, r)
        C_ref = nothing
        for (key, method) in methods
            @info "testing" key n sp r
            res = method(C, A, B)
            time = res.time
            C_res = nothing
            nondiag_time = nothing
            diag_time = nothing
            try
                nondiag_time = res.nondiag_time
                diag_time = res.diag_time
            catch
                nondiag_time = nothing
                diag_time = nothing
            end
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
                "nondiag_time" => nondiag_time,
                "diag_time" => diag_time,
                "method" => key,
                "sparsity" => sp,
                "size" => n,
                "rank" => r,
            ))
            write("mttkrp_results.json", JSON.json(results, 4))
        end
    end
end