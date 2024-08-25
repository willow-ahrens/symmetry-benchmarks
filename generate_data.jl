if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

using Finch
using HDF5

for (n, N) = [(500, 3), (100, 4), (40, 5)]
    for sp = [0.1, 0.01, 0.001, 0.0001]
        println("n = $n, N = $N, sp = $sp")
        triA = fsprand([n for _ in 1:N]..., sp)
        println("generated tensor")
        symA_coords = unique(map(x->sort(collect(x)), zip(ffindnz(triA)[1:N]...)))
        symA = fsparse((map(coord -> coord[r], symA_coords) for r = 1:N)..., rand(length(symA_coords)), tuple((n for _ in 1:N)...))
        println("symmetrized tensor")
        fmt = Element(0.0)
        for _ = 1:N-1
            fmt = SparseList(fmt)
        end
        A = Tensor(Dense(fmt), symA)
        bspwrite("../data/symmetric_$(N)dim_n$(n)_sp$(sp).bsp.h5", A)
        println("wrote tensor")
    end
end