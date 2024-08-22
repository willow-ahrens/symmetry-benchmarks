echo "----Generating SySTeC Kernels----"
julia SySTeC/run.jl

echo "----Building TACO and SPLATT----"
make

echo "Benchmarking SSYMV kernel"
julia kernels/ssymv/run_ssymv.jl