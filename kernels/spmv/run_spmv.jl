using SparseArrays

n = 100
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
println(results.y)
results = spmv_mkl(y, A, x)
println(results.time)
println(results.y)