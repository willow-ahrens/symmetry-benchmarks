echo "Benchmarking SSYMV kernel"
julia kernels/ssymv/run_ssymv.jl

echo "Benchmarking SYPRD kernel"
julia kernels/syprd/run_syprd.jl

#echo "Benchmarking SSYRK kernel"
#julia kernels/ssyrk/run_ssyrk.jl

echo "Benchmarking TTM kernel"
julia kernels/ttm/run_ttm.jl

echo "Benchmarking 3D MTTKRP kernel"
julia kernels/mttkrp/run_mttkrp_dim3.jl

echo "Benchmarking 4D MTTKRP kernel"
julia kernels/mttkrp/run_mttkrp_dim4.jl

echo "Benchmarking 5D MTTKRP kernel"
julia kernels/mttkrp/run_mttkrp_dim5.jl