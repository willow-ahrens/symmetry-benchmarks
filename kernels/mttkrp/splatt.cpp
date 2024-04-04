#include "splatt.h"

#include <chrono>
#include <fstream>
#include <cstdlib>
#include <algorithm>
#include <vector>
#include <iostream>
#include <numeric>

#include <time.h>

using namespace std::chrono;

static inline double getCpuTime()
{
  timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double(ts.tv_sec) + 1e-9 * double(ts.tv_nsec)) * 1000.;
}

static double clear_cache(double* a, double* b, int size) {
  double ret = 0.0;
  for (int i=0; i< 100; i++) {
    a[rand() % size] = rand()/RAND_MAX;
    b[rand() % size] = rand()/RAND_MAX;
  }
  for (int i=0; i<size; i++) {
    ret += a[i] * b[i];
  }
  return ret;
}

#define BENCH(CODE, d) { \
    const auto a = getCpuTime(); \
    CODE; \
    const auto b = getCpuTime(); \
    d = b - a; \
  }

#define BENCH_REPEAT(CODE, r, m) { \
    m.clear(); \
    for (size_t i = 0; i < r; ++i) { \
      double d; \
      double v = warm ? 0 : clear_cache(dummyA, dummyB, size); \
      BENCH(CODE, d); \
      m.push_back(d); \
    } \
  }

#define restrict __restrict__

void printResults(std::string test, std::vector<double> results) {
  std::sort(results.begin(), results.end());
  double mean = std::accumulate(results.begin(), results.end(), 0.0) / results.size();
  double median = (results.size() % 2 == 0) ? ((results[results.size()/2] + results[results.size()/2-1]) / 2) : results[(results.size() - 1)/2]; 
  std::cout << test << ": " << mean << " " << median << std::endl;
}

int main(int argc, char *argv[]) {
  int size = 60000000;
  double *dummyA = new double[size];
  double *dummyB = new double[size];

  const bool warm = (argv[1][0] == 'w');
  const int numTrials = atoi(argv[4]);

  /* allocate default options */
  double * cpd_opts = splatt_default_opts();
  cpd_opts[SPLATT_OPTION_NTHREADS] = (argv[2][0] == 'p') ? 4 : 1;
  cpd_opts[SPLATT_OPTION_NITER] = 0;
  cpd_opts[SPLATT_OPTION_CSF_ALLOC] = SPLATT_CSF_ALLMODE;
  cpd_opts[SPLATT_OPTION_TILE] = SPLATT_NOTILE;
  
  /* load the tensor from a file */
  int ret;
  splatt_idx_t nmodes;
  splatt_csf * tt;
 
  const int nfactors = 25;
  
  splatt_kruskal factored;
  ret = splatt_csf_load(argv[3], &nmodes, &tt, cpd_opts);
  ret = splatt_cpd_als(tt, nfactors, cpd_opts, &factored);

  for (splatt_idx_t i = 0; i < nfactors; ++i) {
    factored.lambda[i] = (double)(i + 1);
    for (splatt_idx_t k = 0; k < nmodes; ++k) {
      for (splatt_idx_t j = 0; j < factored.dims[k]; ++j) {
        factored.factors[k][i + j*nfactors] = 1.;
      }
    }
  }
  
  std::vector<double> results;

  const int mode = 0;
  BENCH_REPEAT(splatt_mttkrp(mode, nfactors, tt, factored.factors, factored.factors[mode], cpd_opts);, numTrials, results);
  printResults("mode-1 mttkrp", results);

  /* cleanup */
  splatt_free_csf(tt, cpd_opts);
  splatt_free_kruskal(&factored);
  splatt_free_opts(cpd_opts);

  return 0;
}