#include <iostream>
#include "splatt.h"
#include "../../deps/SparseRooflineBenchmark/src/benchmark.hpp"
#include "../../deps/taco/include/taco.h"
#include "../../deps/taco/include/taco/util/timers.h"

namespace fs = std::filesystem;
using namespace taco;

#define BENCH(CODE, NAME, REPEAT, TIMER, COLD)         \
    {                                                  \
        TACO_TIME_REPEAT(CODE, REPEAT, TIMER, COLD);   \          \
    }

int main(int argc, char **argv){
    auto params = parse(argc, argv);

    /* allocate default options */
    double *cpd_opts = splatt_default_opts();
    cpd_opts[SPLATT_OPTION_NTHREADS] = 1;
    cpd_opts[SPLATT_OPTION_NITER] = 0;
    cpd_opts[SPLATT_OPTION_CSF_ALLOC] = SPLATT_CSF_ALLMODE;
    cpd_opts[SPLATT_OPTION_TILE] = SPLATT_NOTILE;

    /* load the tensor from a file */
    int ret;
    splatt_idx_t nmodes;
    splatt_csf *tt;
    fs::path file = fs::path(params.input) / "A.tns";
    std::string filename = file.string();
    ret = splatt_csf_load(filename.c_str(), &nmodes, &tt, cpd_opts);

    Tensor<double> _B = read(fs::path(params.input) / "B.ttx", Format({Dense, Dense}), true);
    int n = _B.getDimension(0);
    int r = _B.getDimension(1);
    double **factors = new double *[nmodes];
    for (int i = 0; i < nmodes; ++i) {
        factors[i] = (double *)(_B.getStorage().getValues().getData());
    }

    Tensor<double> C_splatt({n, r}, Format({Dense, Dense}));
    C_splatt.pack();
    double *matout = (double *)(C_splatt.getStorage().getValues().getData());

        /* perform mttkrp */
        const int mode = 0;
    taco::util::TimeResults timevalue;
    BENCH(splatt_mttkrp(mode, r, tt, factors, matout, cpd_opts);,
          "\nSPLATT", 1, timevalue, true);
    // splatt_mttkrp(mode, n, tt, factors, matout, cpd_opts);

    write(fs::path(params.input) / "C.ttx", C_splatt);

    json measurements;
    measurements["time"] = timevalue.median;
    measurements["memory"] = 0;
    std::ofstream measurements_file(fs::path(params.output) / "measurements.json");
    measurements_file << measurements;
    measurements_file.close();
    return 0;
}