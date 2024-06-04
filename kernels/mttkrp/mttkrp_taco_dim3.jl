using Finch
using TensorMarket
using JSON

function mttkrp_taco_dim3_helper(args, A, B)
    mktempdir(prefix="input_") do tmpdir
        (n, r) = size(B)
        _B = Tensor(Dense(Dense(Element(0.0))), B)
        B_T = Tensor(Dense(Dense(Element(0.0))), zeros(r, n))
        @finch mode=:fast begin 
            B_T .= 0
            for j=_, i=_ 
                B_T[j, i] = _B[i, j] 
            end 
        end

        A_path = joinpath(tmpdir, "A.ttx")
        B_T_path = joinpath(tmpdir, "B_T.ttx")
        C_T_path = joinpath(tmpdir, "C_T.ttx")
        fwrite(A_path, Tensor(Dense(SparseList(SparseList(Element(0.0)))), A))
        fwrite(B_T_path, Tensor(Dense(Dense(Element(0.0))), B_T))
        taco_path = joinpath(@__DIR__, "../../deps/taco/build/lib")
        withenv("DYLD_FALLBACK_LIBRARY_PATH"=>"$taco_path", "LD_LIBRARY_PATH" => "$taco_path", "TACO_CFLAGS" => "-O3 -ffast-math -std=c99 -march=native -ggdb") do
            mttkrp_path = joinpath(@__DIR__, "mttkrp_taco_dim3")
            run(`$mttkrp_path -i $tmpdir -o $tmpdir $args`)
        end

        C_T = fread(C_T_path)
        C = Tensor(Dense(Dense(Element(0.0))))
        @finch begin 
            C .= 0
            for j=_, i=_
                C[i, j] = C_T[j, i]
            end
        end

        time = JSON.parsefile(joinpath(tmpdir, "measurements.json"))["time"]
        return (;time=time*10^-9, C=C)
    end
end

mttkrp_taco_dim3(C, A, B) = mttkrp_taco_dim3_helper("", A, B)