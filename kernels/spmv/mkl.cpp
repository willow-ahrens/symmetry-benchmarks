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
    Tensor<double> ACSR({m, n}, CSR);
    for (auto &value : iterate<double>(_A)) {
        ACSR.insert({value.first.toVector().at(0), value.first.toVector().at(1)}, value.second);
    }

    ACSR.pack();
    double *a_CSR;
    int *ia_CSR;
    int *ja_CSR;
    getCSRArrays(ACSR, &ia_CSR, &ja_CSR, &a_CSR);
    for (int i = 0; i < m + 1; ++i) {
        ia_CSR[i] = ia_CSR[i] + 1;
    }
    for (int i = 0; i < nnz; ++i) {
        ja_CSR[i] = ja_CSR[i] + 1;
    }

    Tensor<double> y_mkl({m}, Dense);
    y_mkl.pack();

    sparse_matrix_t A;
    mkl_sparse_d_create_csr(&A, SPARSE_INDEX_BASE_ZERO, m, n, ia_CSR, ia_CSR + 1, ja_CSR, a_CSR);

    // Create a descriptor for the matrix
    struct matrix_descr descrA;
    descrA.type = SPARSE_MATRIX_TYPE_SYMMETRIC;
    descrA.mode = SPARSE_FILL_MODE_UPPER;
    descrA.diag = SPARSE_DIAG_NON_UNIT;

    // mkl_sparse_d_mv(SPARSE_OPERATION_NON_TRANSPOSE, 1.0, A, descrA,
    //                 (double *)(_x.getStorage().getValues().getData()), 0.0,
    //                 (double *)(y_mkl.getStorage().getValues().getData()));

    taco::util::TimeResults timevalue;
    BENCH(mkl_sparse_d_mv(SPARSE_OPERATION_NON_TRANSPOSE, 1.0, A, descrA,
                          (double *)(_x.getStorage().getValues().getData()), 0.0,
                          (double *)(y_mkl.getStorage().getValues().getData()));,
        "\nMKL", 1, timevalue, true)

    write(fs::path(params.input) / "y.ttx", y_mkl);

    json measurements;
    measurements["time"] = timevalue.mean;
    measurements["memory"] = 0;
    std::ofstream measurements_file(fs::path(params.output) / "measurements.json");
    measurements_file << measurements;
    measurements_file.close();

    std::cout
        << "Finished computation" << std::endl;

    // Print the result
    std::cout << "Result vector y:" << std::endl;
    for (int i = 0; i < m; ++i)
    {
        std::cout << y_mkl(i) << " ";
    }
    std::cout << std::endl;

    return 0;
}