using Finch
using TensorMarket
using JSON

function mttkrp_splatt_helper(args, B)
    mktempdir(prefix="input_") do tmpdir
        B_path = joinpath(tmpdir, "B.ttx")
        C_path = joinpath(tmpdir, "C.ttx")
        fwrite(B_path, Tensor(Dense(Dense(Element(0.0))), B))
        run(`mttkrp_splatt -i $tmpdir -o $tmpdir`)
        C = fread(C_path)
        return (C=C)
    end
end

# spmv_mkl(y, A, x) = spmv_mkl_helper("", A, x)


B = rand(10, 10)
result = mttkrp_splatt_helper("", B)
print(result)

