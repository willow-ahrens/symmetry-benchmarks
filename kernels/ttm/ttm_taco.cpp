#include "taco.h"
// #include "taco/format.h"
// #include "taco/lower/lower.h"
// #include "taco/ir/ir.h"
#include <chrono>
#include <sys/stat.h>
#include <iostream>
#include <cstdint>
#include "../../deps/SparseRooflineBenchmark/src/benchmark.hpp"

namespace fs = std::filesystem;

using namespace taco;

int main(int argc, char **argv)
{
    auto params = parse(argc, argv);
    Tensor<double> A = read(fs::path(params.input) / "A.ttx", Format({Dense, Sparse, Sparse}, {2, 1, 0}), true);
    Tensor<double> B_T = read(fs::path(params.input) / "B_T.ttx", Format({Dense, Dense}, {1, 0}), true);
    int n = A.getDimension(0);
    int r = B_T.getDimension(0);

    Tensor<double> C("C", {r, n, n}, Format({Dense, Dense, Dense}));

    IndexVar i, j, k, l;

    C(i, j, l) += A(k, j, l) * B_T(i, k);

    C.compile();

    // Assemble output indices and numerically compute the result
    auto time = benchmark(
        [&C]()
        {
            C.setNeedsAssemble(true);
            C.setNeedsCompute(true);
        },
        [&C]()
        {
            C.assemble();
            C.compute();
        });

    write(fs::path(params.input) / "C.ttx", C);

    json measurements;
    measurements["time"] = time;
    measurements["memory"] = 0;
    std::ofstream measurements_file(fs::path(params.output) / "measurements.json");
    measurements_file << measurements;
    measurements_file.close();
    return 0;
}
