using SparseArrays

n = 10000
A = sprand(n, n, 0.1)
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
