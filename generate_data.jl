if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

using Finch
using Combinatorics
using HDF5

function symmetrize(A)
end

for (n, N) = [(100, 3), (30, 4), (15, 5)]
    for sp = [0.1, 0.01, 0.001, 0.0001]
        println("n = $n, N = $N, sp = $sp")
        A = fsprand([n for _ in 1:N]..., sp)
        println("generated tensor")
        tmp = Dict{NTuple{N, Int}, Float64}()
        for coord in zip(ffindnz(A)[1:N]...)
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
        symA = fsparse(symA_coords..., symA_vals, tuple((n for _ in 1:N)...))
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