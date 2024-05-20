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
    A = fread("../data/order-3/$(tn).bsp.h5")
    println("read tensor")
    n = maximum(size(A))
    println(n)
    B = Tensor(SparseHash{3}(Element(0.0)), n, n, n)
    C = Tensor(Dense(SparseList(SparseList(Element(0.0)))), undef, n, n, n);

    @finch begin
        C .= 0
        for k = _, j = _, i = _
            C[i, j, k] = coalesce(A[~i, ~j, ~k], 0)
        end
    end
    println("coalesced tensor")

    for perm in permutations(1:3)
        D = swizzle(B, perm...)
        @finch for k=_, j=_, i=_
            D[i, j, k] += C[i, j, k]
        end
    end
    println("symmetrized tensor")
    
    bspwrite("../data/order-3/$(tn)_symmetric.bsp.h5", D)
    println("written tensor")
end