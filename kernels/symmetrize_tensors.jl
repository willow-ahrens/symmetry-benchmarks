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
using Combinatorics

frostt_tensors = [
    "nell-2"
]

for tn in frostt_tensors
    println("in for loop")
    _A = fread("../data/order-3/$(tn).bsp.h5")
    println("read tensor")
    n_i, n_j, n_k = size(_A)
    n = maximum([n_i, n_j, n_k])
    println(n)
    A = Tensor(SparseHash{3}(Element(0.0)), n, n, n)
    println("initialized A")
    for k=1:n_k, j=1:n_j, i=1:n_i
        A[i, j, k] += _A[i, j, k]
        A[i, k, j] += _A[i, j, k]
        A[j, i, k] += _A[i, j, k]
        A[j, k, i] += _A[i, j, k]
        A[k, i, j] += _A[i, j, k]
        A[k, j, i] += _A[i, j, k]
    end
    println("symmetrized tensor")
    bspwrite("../data/order-3/$(tn)_symmetric.bsp.h5", A)
    println("written tensor")
end