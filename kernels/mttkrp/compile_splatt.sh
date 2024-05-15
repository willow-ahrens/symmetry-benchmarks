#!/bin/bash

rm -f splatt.out

SPLATT="-I../../splatt/include -std=c++11 -I../../splatt/src -L../../splatt/build/Linux-x86_64/lib -lsplatt -fopenmp"
CXX_FLAGS="-O3 -mtune=corei7-avx -g0 -Wno-deprecated-declarations"
CXX_MACROS="-DNDEBUG"
LDFLAGS_SHARED="-lm"

# Display the command to debug variable expansion
# echo g++ ${CXX_FLAGS} ${CXX_MACROS} mttkrp_splatt.cpp -I.. ${SPLATT} ${LDFLAGS_SHARED} -o splatt.out

# g++ ${CXX_FLAGS} ${CXX_MACROS} mttkrp_splatt.cpp -I.. ${SPLATT} ${LDFLAGS_SHARED} -o splatt.out

export LD_LIBRARY_PATH=/data/scratch/radhapatel/symmetry-benchmarks/deps/taco/build/lib:$LD_LIBRARY_PATH

g++ -O3 -mtune=corei7-avx -g0 -Wno-deprecated-declarations -DNDEBUG mttkrp_splatt.cpp -I../../splatt/include -std=c++17 -I../../splatt/src -L../../splatt/build/Linux-x86_64/lib -lsplatt -fopenmp -I../../deps/taco/include -I../../deps/taco/src -L../../deps/taco/build/lib -ltaco -ldl -o mttkrp_splatt
