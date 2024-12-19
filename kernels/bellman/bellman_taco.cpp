#include "taco.h"
//#include "taco/format.h"
//#include "taco/lower/lower.h"
//#include "taco/ir/ir.h"
#include <chrono>
#include <sys/stat.h>
#include <iostream>
#include <cstdint>
#include "../../deps/SparseRooflineBenchmark/src/benchmark.hpp"

namespace fs = std::filesystem;

using namespace taco;

ir::Expr addImpl(const std::vector<ir::Expr>& v) {
  return ir::Add::make(v[0], v[1]);
}
Func AddOp("add", addImpl, {Annihilator(std::numeric_limits<double>::infinity()), Identity(0), Commutative(), Associative()});

ir::Expr minImpl(const std::vector<ir::Expr>& v) {
  return ir::Min::make(v[0], v[1]);
}
Func MinOp("min", minImpl, {Identity(std::numeric_limits<double>::infinity()), Commutative(), Associative()});


int main(int argc, char **argv){
    auto params = parse(argc, argv);

    // Read data tensors
    Tensor<double> A_data = read(fs::path(params.input) / "A.ttx", Format({Dense, Sparse}, {1, 0}), true);
    Tensor<double> x_data = read(fs::path(params.input) / "x.ttx", Format({Dense}), true);

    // Get dimensions
    int m = A_data.getDimension(0);
    int n = A_data.getDimension(1);

    // Define the fill value (Inf)
    double inf = std::numeric_limits<double>::infinity();

    // Create a new tensor with the same dimensions and format, but with a fill value
    TensorBase A("A2", Datatype::Float64, {m, n}, Format({Dense, Sparse}, {1, 0}), inf);
    TensorBase x("x2", Datatype::Float64, {n}, Format({Dense}), inf);

    // Transfer storage from the read tensors
    A.setStorage(A_data.getStorage());
    x.setStorage(x_data.getStorage());

    // Create the output tensor
    Tensor<double> y("y2", {n}, Format({Dense}), inf);
    
    IndexVar i, j;

    y(i) = Reduction(MinOp(), j, AddOp(A(i,j), x(j)));

    //perform an spmv of the matrix in c++

    y.compile();

    // Assemble output indices and numerically compute the result
    auto time = benchmark(
      [&y]() {
        y.setNeedsAssemble(true);
        y.setNeedsCompute(true);
      },
      [&y]() {
        y.assemble();
        y.compute();
      }
    );

    write(fs::path(params.output)/"y.ttx", y);

    json measurements;
    measurements["time"] = time;
    measurements["memory"] = 0;
    std::ofstream measurements_file(fs::path(params.output)/"measurements.json");
    measurements_file << measurements;
    measurements_file.close();
    return 0;
}