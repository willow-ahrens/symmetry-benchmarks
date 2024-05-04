using Finch
using HDF5

n = 100
sparsities = [0.1, 0.075, 0.05, 0.025, 0.01, 0.0075, 0.005, 0.0025, 0.001]

for sp in sparsities
    triA = fsprand(n, n, n, n, sp)
    symA = [triA[sort([i, j, k, l])...] for i = 1:n, j = 1:n, k = 1:n, l = 1:n]
    A = Tensor(Dense(SparseList(SparseList(SparseList(Element(0.0))))), symA)
    bspwrite("../data/symmetric_4dim_n$(n)_sp$(sp).bsp.h5", A)
end
