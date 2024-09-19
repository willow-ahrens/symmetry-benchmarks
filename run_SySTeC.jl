if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

using SySTeC
using Finch
using Finch.FinchNotation

function generate_code()
    output_dir = joinpath(@__DIR__, "generated")
    mkpath(output_dir)

    y = :y
    x = :x
    A = :A
    B = :B 
    C = :C

    i = index(:i)
    j = index(:j)
    k = index(:k)
    l = index(:l)
    m = index(:m)
    n = index(:n)

    ex = @finch_program y[i] += A[i, j] * x[j]
    func_name = "ssymv_finch_opt_helper"
    symmetric_tns = [A]
    loop_order = [i, j]
    filename = joinpath(output_dir, "ssymv.jl")
    compile_symmetric_kernel(ex, func_name, symmetric_tns, loop_order, filename)
    println("Generated SySTeC SSYMV Kernel")

    ex = @finch_program y[] += x[i] * A[i, j] * x[j]
    func_name = "syprd_finch_opt_helper"
    symmetric_tns = [A]
    loop_order = [i, j]
    filename = joinpath(output_dir, "syprd.jl")
    compile_symmetric_kernel(ex, func_name, symmetric_tns, loop_order, filename)
    println("Generated SySTeC SYPRD Kernel")

    ex = @finch_program C[i, j] += A[i, k] * A[j, k]
    func_name = "ssyrk_finch_opt_helper"
    symmetric_tns = []
    loop_order = [i, j, k]
    filename = joinpath(output_dir, "ssyrk.jl")
    compile_symmetric_kernel(ex, func_name, symmetric_tns, loop_order, filename)
    println("Generated SySTeC SSYRK Kernel")

    ex = @finch_program C[i, j, l] += A[k, j, l] * B[k, i]
    func_name = "ttm_finch_opt_helper"
    symmetric_tns = [A]
    loop_order = [i, j, k, l]
    filename = joinpath(output_dir, "ttm.jl")
    compile_symmetric_kernel(ex, func_name, symmetric_tns, loop_order, filename)
    println("Generated SySTeC TTM Kernel")

    ex = @finch_program C[i, j] += A[i, k, l] * B[l, j] * B[k, j]
    func_name = "mttkrp_dim3_finch_opt_helper"
    symmetric_tns = [A]
    loop_order = [j, i, k, l]
    filename = joinpath(output_dir, "mttkrp_dim3.jl")
    compile_symmetric_kernel(ex, func_name, symmetric_tns, loop_order, filename)
    println("Generated SySTeC 3D MTTKRP Kernel")

    ex = @finch_program C[i, j] += A[i, k, l, m] * B[l, j] * B[k, j] * B[m, j]
    func_name = "mttkrp_dim4_finch_opt_helper"
    symmetric_tns = [A]
    loop_order = [j, i, k, l, m]
    filename = joinpath(output_dir, "mttkrp_dim4.jl")
    compile_symmetric_kernel(ex, func_name, symmetric_tns, loop_order, filename)
    println("Generated SySTeC 4D MTTKRP Kernel")

    ex = @finch_program C[i, j] += A[i, k, l, m, n] * B[l, j] * B[k, j] * B[m, j] * B[n, j]
    func_name = "mttkrp_dim5_finch_opt_helper"
    symmetric_tns = [A]
    loop_order = [j, i, k, l, m, n]
    filename = joinpath(output_dir, "mttkrp_dim5.jl")
    compile_symmetric_kernel(ex, func_name, symmetric_tns, loop_order, filename)
    println("Generated SySTeC 5D MTTKRP Kernel")
end

generate_code()
