using Finch
using TensorMarket
using JSON
function ttm_taco_helper(args, A, B)
    mktempdir(prefix="input_") do tmpdir
        _B = Tensor(Dense(Dense(Element(0.0))), B)
        B_T = Tensor(Dense(Dense(Element(0.0))))
        @finch mode=:fast begin 
            B_T .= 0
            for j=_, i=_ 
                B_T[j, i] = _B[i, j] 
            end 
        end

        A_path = joinpath(tmpdir, "A.ttx")
        B_T_path = joinpath(tmpdir, "B_T.ttx")
        C_path = joinpath(tmpdir, "C.ttx")
        fwrite(A_path, Tensor(Dense(SparseList(SparseList(Element(0.0)))), A))
        fwrite(B_T_path, Tensor(Dense(Dense(Element(0.0))), B_T))
        taco_path = joinpath(@__DIR__, "../../deps/taco/build/lib")
        withenv("DYLD_FALLBACK_LIBRARY_PATH"=>"$taco_path", "LD_LIBRARY_PATH" => "$taco_path", "TACO_CFLAGS" => "-O3 -ffast-math -std=c99 -march=native -ggdb") do
            ttm_path = joinpath(@__DIR__, "ttm_taco")
            run(`$ttm_path -i $tmpdir -o $tmpdir $args`)
        end
        C = fread(C_path)
        (r, n, n) = size(C)
        C_transposed = Tensor(Dense(Dense(Dense(Element(0.0)))))
        @finch mode=:fast begin
            C_transposed .= 0
            for l=_, j=_, i=_
                C_transposed[l, j, i] = C[i, j, l]
            end
        end
        C_transposed = resize!(C_transposed, r, n, n)
        time = JSON.parsefile(joinpath(tmpdir, "measurements.json"))["time"]
        return (;time=time*10^-9, C=C_transposed)
        # return (;time=time*10^-9, C=C)
    end
end

ttm_taco(C, A, B) = ttm_taco_helper("", A, B)