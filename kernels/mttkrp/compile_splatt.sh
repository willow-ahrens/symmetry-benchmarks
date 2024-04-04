#!/bin/bash

rm splatt.out

SPLATT="-I../../splatt/include -std=c++11 -I../../splatt/src -L../../splatt/build/Linux-x86_64/lib -lsplatt -fopenmp " 
CXX_FLAGS=" -O3 -mtune=corei7-avx -g0 -Wno-deprecated-declarations "
CXX_MACROS="-DNDEBUG"
LDFLAGS_SHARED="-lm"
	
g++ ${CXX_FLAGS} ${CXX_MACROS} splatt.cpp -I.. ${SPLATT} ${LDFLAGS_SHARED} -o splatt.out