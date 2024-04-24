#include <iostream>
#include "/tmp/home/radhapatel/miniconda3/pkgs/mkl-include-2024.1.0-intel_691/include/mkl.h"
#include "../../deps/SparseRooflineBenchmark/src/benchmark.hpp"
#include "../../deps/taco/include/taco.h"
#include "../../deps/taco/include/taco/util/timers.h"

namespace fs = std::filesystem;

using namespace taco;

#define BENCH(CODE, NAME, REPEAT, TIMER, COLD)  { \
    TACO_TIME_REPEAT(CODE, REPEAT, TIMER, COLD); \
    std::cout << NAME << " time (ms)" << std::endl << TIMER << std::endl; \
}

int main(int argc, char **argv){
    auto params = parse(argc, argv);
    std::cout << params.input << std::endl;

    Tensor<double> _A = read(fs::path(params.input) / "A.ttx", Format({Dense, Sparse}), true);
    Tensor<double> _x = read(fs::path(params.input) / "x.ttx", Format({Dense}), true);
    int m = _A.getDimension(0);
    int n = _A.getDimension(1);
    int nnz = _A.getStorage().getValues().getSize();

    // convert to CSR
    std::cout << "check 3" << std::endl;
    Tensor<double> A({m, n}, Format({Dense, Dense}));
    for (auto &value : iterate<double>(_A)) {
        A.insert({value.first.toVector().at(0), value.first.toVector().at(1)}, value.second);
    }
    std::cout << "check 4" << std::endl;

    A.pack();

    Tensor<double> y_mkl({m}, Dense);
    y_mkl.pack();

    taco::util::TimeResults timevalue;
    double alpha = 1.0;
    double beta = 1.0;
    int incx = 1;
    int incy = 1;
    BENCH(dsymv("U", &n, &alpha, (double *)(A.getStorage().getValues().getData()), &n,
                (double *)(_x.getStorage().getValues().getData()), &incx, &beta,
                (double *)(y_mkl.getStorage().getValues().getData()), &incy);
          ,
          "\nMKL", 1, timevalue, true)

    write(fs::path(params.input) / "y.ttx", y_mkl);

    json measurements;
    measurements["time"] = timevalue.mean;
    measurements["memory"] = 0;
    std::ofstream measurements_file(fs::path(params.output) / "measurements.json");
    measurements_file << measurements;
    measurements_file.close();

    return 0;
}