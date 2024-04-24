#include <iostream>
#include "splatt.h"
#include "../../deps/SparseRooflineBenchmark/src/benchmark.hpp"
#include "../../deps/taco/include/taco.h"
#include "../../deps/taco/include/taco/util/timers.h"

namespace fs = std::filesystem;
using namespace taco;

int main(int argc, char **argv){
    auto params = parse(argc, argv);

    /* allocate default options */
    double *cpd_opts = splatt_default_opts();
    cpd_opts[SPLATT_OPTION_NTHREADS] = (argv[2][0] == 'p') ? 4 : 1;
    cpd_opts[SPLATT_OPTION_NITER] = 0;
    cpd_opts[SPLATT_OPTION_CSF_ALLOC] = SPLATT_CSF_ALLMODE;
    cpd_opts[SPLATT_OPTION_TILE] = SPLATT_NOTILE;

    /* load the tensor from a file */
    int ret;
    splatt_idx_t nmodes;
    splatt_csf *tt;
    ret = splatt_csf_load("/Users/radhapatel/mit/meng/symmetry-benchmarks/data/symmetric_10x10x10.tns", &nmodes, &tt, cpd_opts);
    std::cout << "Modes: " << nmodes << std::endl;

    // Tensor<double> _B = read(fs::path(params.input) / "B.ttx", Format({Dense, Dense}), true);

    /* perform mttkrp */
    // const int mode = 0;
    // BENCH_REPEAT(splatt_mttkrp(mode, nfactors, tt, factored.factors, factored.factors[mode], cpd_opts);, numTrials, results);
    // printResults("mode-1 mttkrp", results);
}