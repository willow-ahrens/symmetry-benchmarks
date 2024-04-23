using SparseArrays
using MatrixDepot

include("spmv_mkl.jl")
include("spmv_finch.jl")

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

# methods = Dict(
#     "mkl" => spmv_mkl,

# )

for mtx in symmetric_oski 
    AA = SparseMatrixCSC(matrixdepot(mtx))
    (n, n) = size(AA)
    x = rand(n)
    y = zeros(n)
    println(mtx)
    results = spmv_finch(y, AA, x)
    println(results.time)
    results = spmv_mkl(y, AA, x)
    println(results.time)
end
