using Finch
using TensorMarket
using JSON

function symm_mkl_helper(args, A, B)
    mktempdir(prefix="input_") do tmpdir
        A_path = joinpath(tmpdir, "A.ttx")
        B_path = joinpath(tmpdir, "B.ttx")
        C_path = joinpath(tmpdir, "C.ttx")
        fwrite(A_path, Tensor(Dense(SparseList(Element(0.0))), A))
        fwrite(B_path, Tensor(Dense(Dense(Element(0.0))), B))
        run(`mkl_symm -i $tmpdir -o $tmpdir`)
        C = fread(C_path)
        time = JSON.parsefile(joinpath(tmpdir, "measurements.json"))["time"]
        return (;time=time*10^-3, C=C)
    end
end

# symm_mkl(C, A, B) = symm_mkl_helper("", A, B)


n = 5
A = rand(n, n)
B = rand(n, n)
result = symm_mkl_helper("", A, B)
println(result)