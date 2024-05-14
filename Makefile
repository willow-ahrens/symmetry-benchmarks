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
TTM = kernels/ttm/ttm_taco
MTTKRP = kernels/mttkrp/mttkrp_taco
MTTKRP_DIM4 = kernels/mttkrp/mttkrp_dim4_taco

all: $(SSYMV) $(TTM) $(MTTKRP) $(MTTKRP_DIM4)

SPARSE_BENCH_DIR = deps/SparseRooflineBenchmark
SPARSE_BENCH_CLONE = $(SPARSE_BENCH_DIR)/.git
SPARSE_BENCH = deps/SparseRooflineBenchmark/build/hello

$(SPARSE_BENCH_CLONE): 
	git submodule update --init $(SPARSE_BENCH_DIR)

$(SPARSE_BENCH): $(SPARSE_BENCH_CLONE)
	mkdir -p $(SPARSE_BENCH) ;\
	touch $(SPARSE_BENCH)

TACO_DIR = deps/taco
TACO_CLONE = $(TACO_DIR)/.git
TACO = deps/taco/build/lib/libtaco.*
TACO_CXXFLAGS = $(CXXFLAGS) -I$(TACO_DIR)/include -I$(TACO_DIR)/src
TACO_LDLIBS = $(LDLIBS) -L$(TACO_DIR)/build/lib -ltaco -ldl

$(TACO_CLONE): 
	git submodule update --init $(TACO_DIR)

$(TACO): $(TACO_CLONE)
	cd $(TACO_DIR) ;\
	mkdir -p build ;\
	cd build ;\
	cmake -DPYTHON=false -DCMAKE_BUILD_TYPE=Release .. ;\
	make taco -j$(NPROC_VAL)

clean:
	rm -f $(SSYMV) $(TTM) $(MTTKRP) $(MTTKRP_DIM4)
	rm -rf *.o *.dSYM *.trace

kernels/ssymv/ssymv_taco: $(SPARSE_BENCH) $(TACO) kernels/ssymv/ssymv_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/ssymv/ssymv_taco.cpp $(TACO_LDLIBS)

kernels/ttm/ttm_taco: $(SPARSE_BENCH) $(TACO) kernels/ttm/ttm_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/ttm/ttm_taco.cpp $(TACO_LDLIBS)

kernels/mttkrp/mttkrp_taco: $(SPARSE_BENCH) $(TACO) kernels/mttkrp/mttkrp_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/mttkrp/mttkrp_taco.cpp $(TACO_LDLIBS)

kernels/mttkrp/mttkrp_dim4_taco: $(SPARSE_BENCH) $(TACO) kernels/mttkrp/mttkrp_dim4_taco.cpp
	$(CXX) $(TACO_CXXFLAGS) -o $@ kernels/mttkrp/mttkrp_dim4_taco.cpp $(TACO_LDLIBS)