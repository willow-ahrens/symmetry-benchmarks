using Finch
using TensorMarket
using JSON
function ssyrk_taco_helper(args, A)
    mktempdir(prefix="input_") do tmpdir
        A_path = joinpath(tmpdir, "A.ttx")
        C_path = joinpath(tmpdir, "C.ttx")
        fwrite(A_path, Tensor(Dense(SparseList(Element(0.0))), A))
        taco_path = joinpath(@__DIR__, "../../deps/taco/build/lib")
        withenv("DYLD_FALLBACK_LIBRARY_PATH"=>"$taco_path", "LD_LIBRARY_PATH" => "$taco_path", "TACO_CFLAGS" => "-O3 -ffast-math -std=c99 -march=native -ggdb") do
            ssyrk_path = joinpath(@__DIR__, "ssyrk_taco")
            run(`$ssyrk_path -i $tmpdir -o $tmpdir $args`)
        end
        C = fread(C_path)
        time = JSON.parsefile(joinpath(tmpdir, "measurements.json"))["time"]
        return (;time=time*10^-9, C=C)
    end
end

ssyrk_taco(C, A) = ssyrk_taco_helper("", A)