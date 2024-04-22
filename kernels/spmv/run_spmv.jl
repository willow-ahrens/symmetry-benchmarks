using SparseArrays

n = 10000
A = rand(n, n)
x = rand(n)
y = zeros(n)

include("spmv_mkl.jl")
include("spmv_finch.jl")

# methods = Dict(
#     "mkl" => spmv_mkl,

# )

results = spmv_finch(y, A, x)
println(results.time)
results = spmv_mkl(y, A, x)
println(results.time)
