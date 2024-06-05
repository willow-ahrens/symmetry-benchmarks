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
MTTKRP = kernels/mttkrp/mttkrp_taco_dim3
MTTKRP_DIM4 = kernels/mttkrp/mttkrp_taco_dim4
MTTKRP_DIM5 = kernels/mttkrp/mttkrp_taco_dim5
MTTKRP_SPLATT_DIM3 = kernels/mttkrp/mttkrp_splatt_dim3

taco: $(SSYMV) $(SYPRD) $(SSYRK) $(TTM) $(MTTKRP) $(MTTKRP_DIM4) $(MTTKRP_DIM5)
splatt: $(MTTKRP_SPLATT_DIM3)

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

SPLATT_CXXFLAGS = -O3 -mtune=corei7-avx -g0 -Wno-deprecated-declarations -DNDEBUG -std=c++17 -fopenmp
SPLATT_INCLUDES = -Isplatt/include -Isplatt/src -Ideps/taco/include -Ideps/taco/src
SPLATT_LDLIBS = -Lsplatt/build/Linux-x86_64/lib -lsplatt -Ldeps/taco/build/lib -ltaco -ldl

$(TACO_CLONE): 
	git submodule update --init $(TACO_DIR)

$(TACO): $(TACO_CLONE)
	cd $(TACO_DIR) ;\
	mkdir -p build ;\
	cd build ;\
	cmake -DPYTHON=false -DCMAKE_BUILD_TYPE=Release .. ;\
	make taco -j$(NPROC_VAL)

clean:
	rm -f $(SSYMV) $(SYPRD) $(SSYRK) $(TTM) $(MTTKRP) $(MTTKRP_DIM4) $(MTTKRP_DIM5)
	rm -rf *.o *.dSYM *.trace

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

kernels/mttkrp/mttkrp_splatt_dim3: kernels/mttkrp/mttkrp_splatt_dim3.cpp
	$(CXX) $(SPLATT_CXXFLAGS) $(SPLATT_INCLUDES) kernels/mttkrp/mttkrp_splatt_dim3.cpp $(SPLATT_LDLIBS) -o kernels/mttkrp/mttkrp_splatt_dim3

kernels/mttkrp/mttkrp_splatt_dim4: kernels/mttkrp/mttkrp_splatt_dim4.cpp
	$(CXX) $(SPLATT_CXXFLAGS) $(SPLATT_INCLUDES) kernels/mttkrp/mttkrp_splatt_dim4.cpp $(SPLATT_LDLIBS) -o kernels/mttkrp/mttkrp_splatt_dim4

kernels/mttkrp/mttkrp_splatt_dim5: kernels/mttkrp/mttkrp_splatt_dim5.cpp
	$(CXX) $(SPLATT_CXXFLAGS) $(SPLATT_INCLUDES) kernels/mttkrp/mttkrp_splatt_dim5.cpp $(SPLATT_LDLIBS) -o kernels/mttkrp/mttkrp_splatt_dim5
