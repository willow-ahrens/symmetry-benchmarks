#!/bin/bash

rm bench.out

SPLATT="-I../include -std=c++11 -I../src -L../build/Linux-x86_64/lib -lsplatt -fopenmp " 
CXX_FLAGS=" -O3 -mtune=corei7-avx -g0 -Wno-deprecated-declarations "
CXX_MACROS="-DNDEBUG"
LDFLAGS_SHARED="-lm"

if [[ ${MACHINE} = lanka* ]] ; then
	echo "Compiling for Lanka "
	#### Lanka
	#export LD_LIBRARY_PATH=/data/scratch/lugato/Taco/taco/build/lib:${LD_LIBRARY_PATH}
	export LD_LIBRARY_PATH=/data/scratch/s3chou/taco-eval/splatt/build/Linux-x86_84/lib:${LD_LIBRARY_PATH}
else 
	echo "Compiling on " ${MACHINE}
	#### Local
	export LD_LIBRARY_PATH=/data/scratch/s3chou/taco-eval/splatt/build/Linux-x86_84/lib:${LD_LIBRARY_PATH}
	#export LD_LIBRARY_PATH=${HOME}/taco/build/lib:${LD_LIBRARY_PATH}
fi
	
g++ ${CXX_FLAGS} ${CXX_MACROS} bench.cpp -I.. ${SPLATT} ${LDFLAGS_SHARED} -o bench.out

#numactl -N 1 ./bench.out c p
./bench.out c s ../../data/tensor/facebook/facebook.tns
