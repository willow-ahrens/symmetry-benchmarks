CC = gcc
CXX = g++
LD = ld
CXXFLAGS += -std=c++17
LDLIBS +=

ifeq ("$(shell uname)","Darwin")
export NPROC_VAL := $(shell sysctl -n hw.logicalcpu_max )
else
export NPROC_VAL := $(shell lscpu -p | egrep -v '^\#' | wc -l)
endif

SSYMV = kernels/ssymv/ssymv_taco
SYPRD = kernels/syprd/syprd_taco
SSYRK = kernels/ssyrk/ssyrk_taco
TTM = kernels/ttm/ttm_taco
BELLMAN = kernels/bellman/bellman_taco
MTTKRP_TACO_DIM3 = kernels/mttkrp/mttkrp_taco_dim3
MTTKRP_TACO_DIM4 = kernels/mttkrp/mttkrp_taco_dim4
MTTKRP_TACO_DIM5 = kernels/mttkrp/mttkrp_taco_dim5
MTTKRP_SPLATT_DIM3 = kernels/mttkrp/mttkrp_splatt_dim3
MTTKRP_SPLATT_DIM4 = kernels/mttkrp/mttkrp_splatt_dim4
MTTKRP_SPLATT_DIM5 = kernels/mttkrp/mttkrp_splatt_dim5

SPARSE_BENCH_DIR = deps/SparseRooflineBenchmark
SPARSE_BENCH = deps/SparseRooflineBenchmark/build/hello

TACO_DIR = deps/taco
TACO = deps/taco/build/lib/libtaco.*
TACO_CXXFLAGS = $(CXXFLAGS) -I$(TACO_DIR)/include -I$(TACO_DIR)/src
TACO_INCLUDES = -I$(TACO_DIR)/include -I$(TACO_DIR)/src
TACO_LDLIBS = $(LDLIBS) -L$(TACO_DIR)/build/lib -ltaco -ldl

SPLATT_DIR = deps/splatt
SPLATT_BUILD_DIR = $(SPLATT_DIR)/build/$(shell uname -s)-$(shell uname -m)
SPLATT = $(SPLATT_BUILD_DIR)/lib/libsplatt.*
SPLATT_CXXFLAGS = -O3 -Wno-deprecated-declarations -DNDEBUG -std=c++17 -fopenmp
SPLATT_INCLUDES = -I$(SPLATT_DIR)/include -I$(SPLATT_DIR)/src
SPLATT_LDLIBS = -L$(SPLATT_BUILD_DIR)/lib -lsplatt -llapack -lblas

TACO_KERNELS = $(SSYMV) $(SYPRD) $(SSYRK) $(TTM) $(MTTKRP_TACO_DIM3) $(MTTKRP_TACO_DIM4) $(MTTKRP_TACO_DIM5) $(BELLMAN)

SPLATT_KERNELS = $(MTTKRP_SPLATT_DIM3) $(MTTKRP_SPLATT_DIM4) $(MTTKRP_SPLATT_DIM5)

KERNELS = $(TACO_KERNELS) $(SPLATT_KERNELS)

all: deps envs kernels

taco: $(TACO_KERNELS)

clean:
	rm -f $(SSYMV) $(SYPRD) $(SSYRK) $(TTM) $(MTTKRP_TACO_DIM3) $(MTTKRP_TACO_DIM4) $(MTTKRP_TACO_DIM5) $(MTTKRP_SPLATT_DIM3) $(MTTKRP_SPLATT_DIM4) $(MTTKRP_SPLATT_DIM5) $(BELLMAN)
	rm -rf *.o *.dSYM *.trace

envs: Manifest.toml poetry.lock

Manifest.toml:
	julia setup.jl

poetry.lock:
	poetry install --no-root

deps: $(SPARSE_BENCH) $(TACO) $(SPLATT)

$(SPLATT):
	cd $(SPLATT_DIR) ;\
	./configure --prefix=build ;\
	make ;\
	make install

$(TACO):
	cd $(TACO_DIR) ;\
	mkdir -p build ;\
	cd build ;\
	cmake -DPYTHON=false -DCMAKE_BUILD_TYPE=Release .. ;\
	make taco -j$(NPROC_VAL)

$(SPARSE_BENCH):
	mkdir -p $(SPARSE_BENCH) ;\
	touch $(SPARSE_BENCH)

kernels: $(KERNELS)

kernels/ssymv/ssymv_taco: $(SPARSE_BENCH) $(TACO) kernels/ssymv/ssymv_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/ssymv/ssymv_taco.cpp $(TACO_LDLIBS)

kernels/syprd/syprd_taco: $(SPARSE_BENCH) $(TACO) kernels/syprd/syprd_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/syprd/syprd_taco.cpp $(TACO_LDLIBS)

kernels/ssyrk/ssyrk_taco: $(SPARSE_BENCH) $(TACO) kernels/ssyrk/ssyrk_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/ssyrk/ssyrk_taco.cpp $(TACO_LDLIBS)

kernels/ttm/ttm_taco: $(SPARSE_BENCH) $(TACO) kernels/ttm/ttm_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/ttm/ttm_taco.cpp $(TACO_LDLIBS)

kernels/mttkrp/mttkrp_taco_dim3: $(SPARSE_BENCH) $(TACO) kernels/mttkrp/mttkrp_taco_dim3.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/mttkrp/mttkrp_taco_dim3.cpp $(TACO_LDLIBS)

kernels/mttkrp/mttkrp_taco_dim4: $(SPARSE_BENCH) $(TACO) kernels/mttkrp/mttkrp_taco_dim4.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/mttkrp/mttkrp_taco_dim4.cpp $(TACO_LDLIBS)

kernels/mttkrp/mttkrp_taco_dim5: $(SPARSE_BENCH) $(TACO) kernels/mttkrp/mttkrp_taco_dim5.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/mttkrp/mttkrp_taco_dim5.cpp $(TACO_LDLIBS)

kernels/mttkrp/mttkrp_splatt_dim3: $(TACO) $(SPLATT) kernels/mttkrp/mttkrp_splatt_dim3.cpp
	$(CXX) $(SPLATT_CXXFLAGS) $(SPLATT_INCLUDES) $(TACO_INCLUDES) kernels/mttkrp/mttkrp_splatt_dim3.cpp $(SPLATT_LDLIBS) $(TACO_LDLIBS) -o kernels/mttkrp/mttkrp_splatt_dim3

kernels/mttkrp/mttkrp_splatt_dim4: $(TACO) $(SPLATT) kernels/mttkrp/mttkrp_splatt_dim4.cpp
	$(CXX) $(SPLATT_CXXFLAGS) $(SPLATT_INCLUDES) $(TACO_INCLUDES)  kernels/mttkrp/mttkrp_splatt_dim4.cpp $(SPLATT_LDLIBS) $(TACO_LDLIBS) -o kernels/mttkrp/mttkrp_splatt_dim4

kernels/mttkrp/mttkrp_splatt_dim5: $(TACO) $(SPLATT) kernels/mttkrp/mttkrp_splatt_dim5.cpp
	$(CXX) $(SPLATT_CXXFLAGS) $(SPLATT_INCLUDES) $(TACO_INCLUDES) kernels/mttkrp/mttkrp_splatt_dim5.cpp $(SPLATT_LDLIBS) $(TACO_LDLIBS) -o kernels/mttkrp/mttkrp_splatt_dim5

kernels/bellman/bellman_taco: $(SPARSE_BENCH) $(TACO) kernels/bellman/bellman_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/bellman/bellman_taco.cpp $(TACO_LDLIBS)
