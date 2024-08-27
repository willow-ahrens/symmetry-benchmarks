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
using Combinatorics

include("mttkrp_finch_dim5.jl")
include("mttkrp_taco_dim5.jl")
include("mttkrp_splatt_dim5.jl")

n = 15
rank_sparsity = [(10, 0.1), (10, 0.0001), (40, 0.1), (40, 0.0001)]
methods = Dict(
    "mttkrp_finch_ref" => mttkrp_finch_ref_dim5,
    "mttkrp_finch_opt" => mttkrp_finch_opt_dim5,
    "mttkrp_taco" => mttkrp_dim5_taco,
    "mttkrp_splatt" => mttkrp_splatt_dim5
)

results = []
N = 5
for (r, sp) in rank_sparsity
    triA = fsprand(n, n, n, n, n, sp)
    tmp = Dict{NTuple{N, Int}, Float64}()
    for coord in zip(ffindnz(triA)[1:N]...)
        for perm in permutations(1:N)
            tmp[coord[perm]] = coord[end]
        end
    end
    symA_coords = [Vector{Int}() for _ in 1:N]
    symA_vals = Float64[]
    for (coord, val) in tmp
        push!(symA_vals, val)
        for r = 1:N
            push!(symA_coords[r], coord[r])
        end
    end
    A = fsparse(symA_coords..., symA_vals, tuple((n for _ in 1:N)...))
    # A = bspread("../../data/symmetric_4dim_n$(n)_sp$(sp).bsp.h5")
    B = rand(n, r)   
    C = zeros(n, r)
    C_ref = nothing
    for (key, method) in methods
        @info "testing" key n sp r
        res = method(C, A, B)
        time = res.time
        C_res = res.C
        nondiag_time = nothing
        diag_time = nothing
        try
            nondiag_time = res.nondiag_time
            diag_time = res.diag_time
        catch
            nondiag_time = nothing
            diag_time = nothing
        end
        C_ref = something(C_ref, C_res)
        norm(C_res - C_ref)/norm(C_ref) < 0.1 || @warn("Incorrect result via norm")

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
        write("mttkrp_dim5_results.json", JSON.json(results, 4))
    end
end