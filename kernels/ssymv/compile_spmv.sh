#!/bin/bash

g++ -o mkl_spmv mkl.cpp -I/data/scratch/radhapatel/symmetry-benchmarks/deps/taco/include -L/tmp/home/radhapatel/miniconda3/pkgs/mkl-2024.1.0-intel_691/lib -L/data/scratch/radhapatel/symmetry-benchmarks/deps/taco/build/lib -lmkl_rt -lpthread -lm -ldl -ltaco