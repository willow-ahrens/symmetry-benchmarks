using Finch
using HDF5

n = 100
sparsities = [0.1, 0.01, 0.001, 0.0001]

for sp in sparsities
    println("sparsity $(sp)")
    triA = fsprand(n, n, n, n, n, sp)
    println("generated tensor")
    symA = [triA[sort([i, j, k, l, m])...] for i = 1:n, j = 1:n, k = 1:n, l = 1:n, m = 1:n]
    println("symmetrized tensor")
    A = Tensor(Dense(SparseList(SparseList(SparseList(SparseList(Element(0.0)))))), symA)
    bspwrite("../data/symmetric_5dim_n$(n)_sp$(sp).bsp.h5", A)
    println("wrote tensor")
end
