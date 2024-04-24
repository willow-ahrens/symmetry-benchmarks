#!/bin/bash

rm mttkrp_splatt

SPLATT="-I../../splatt/include -I../../splatt/src -I/data/scratch/radhapatel/symmetry-benchmarks/deps/taco/include -L/data/scratch/radhapatel/symmetry-benchmarks/deps/taco/build/lib -L../../splatt/build/Linux-x86_64/lib -lsplatt -fopenmp " 
CXX_FLAGS=" -O3 -mtune=corei7-avx -g0 -Wno-deprecated-declarations "
CXX_MACROS="-DNDEBUG"
LDFLAGS_SHARED="-ltaco -lm"
	
g++ ${CXX_FLAGS} ${CXX_MACROS} mttkrp_splatt.cpp -I.. ${SPLATT} ${LDFLAGS_SHARED} -o mttkrp_splatt