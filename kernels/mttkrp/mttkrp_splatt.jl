using Finch
using TensorMarket
using JSON

function mttkrp_splatt_helper(args, A, B)
    mktempdir(prefix="input_") do tmpdir
        A_path = joinpath(tmpdir, "A.tns")
        B_path = joinpath(tmpdir, "B.ttx")
        C_path = joinpath(tmpdir, "C.ttx")
        ftnswrite(A_path, Tensor(Dense(SparseList(SparseList(Element(0.0)))), A))
        fwrite(B_path, Tensor(Dense(Dense(Element(0.0))), B))
        taco_path = joinpath(@__DIR__, "../../deps/taco/build/lib")
        withenv("DYLD_FALLBACK_LIBRARY_PATH"=>"$taco_path", "LD_LIBRARY_PATH" => "$taco_path", "TACO_CFLAGS" => "-O3 -ffast-math -std=c99 -march=native -ggdb") do
            mttkrp_path = joinpath(@__DIR__, "mttkrp_splatt")
            run(`$mttkrp_path -i $tmpdir -o $tmpdir $args`)
        end
        # run(`mttkrp_splatt -i $tmpdir -o $tmpdir`)
        C = fread(C_path)
        time = JSON.parsefile(joinpath(tmpdir, "measurements.json"))["time"]
        return (;time=time*10^-3, C=C)
    end
end

mttkrp_splatt(C, A, B) = mttkrp_splatt_helper("", A, B)