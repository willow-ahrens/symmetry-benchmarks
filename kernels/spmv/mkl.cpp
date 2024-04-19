#include <iostream>
#include "/tmp/home/radhapatel/miniconda3/pkgs/mkl-include-2023.1.0-h06a4308_46344/include/mkl.h"

int main()
{
    // Matrix dimensions
    const int N = 3;

    // Define a symmetric matrix A (stored in packed format)
    double A[N * (N + 1) / 2] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0};

    // Define the vector x
    double x[N] = {1.0, 2.0, 3.0};

    // Define the output vector y
    double y[N] = {0.0};

    // Perform symmetric matrix-vector multiplication
    char uplo = 'U'; // Use upper triangular part of A
    double alpha = 1.0;
    double beta = 0.0;
    int incx = 1;
    int incy = 1;
    cblas_dspmv(CblasRowMajor, CblasUpper, N, alpha, A, x, incx, beta, y, incy);

    // Print the result
    std::cout << "Result vector y:" << std::endl;
    for (int i = 0; i < N; ++i)
    {
        std::cout << y[i] << " ";
    }
    std::cout << std::endl;

    return 0;
}