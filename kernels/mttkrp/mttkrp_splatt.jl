using Finch
using TensorMarket
using JSON

function mttkrp_splatt_helper(args, A, B)
    mktempdir(prefix="input_") do tmpdir
        A_path = joinpath(tmpdir, "A.ttx")
        B_path = joinpath(tmpdir, "B.ttx")
        C_path = joinpath(tmpdir, "C.ttx")
        fwrite(A_path, Tensor(Dense(SparseList(SparseList(Element(0.0)))), A))
        fwrite(B_path, Tensor(Dense(Dense(Element(0.0))), B))
        run(`mttkrp_splatt -i $tmpdir -o $tmpdir`)
        C = fread(C_path)
        return (C=C)
    end
end

# spmv_mkl(y, A, x) = spmv_mkl_helper("", A, x)

n = 10
A = rand(n, n, n)
B = rand(n, n)
result = mttkrp_splatt_helper("", A, B)
print(result)

