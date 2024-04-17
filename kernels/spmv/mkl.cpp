#include <iostream>
#include "/tmp/home/radhapatel/miniconda3/pkgs/mkl-include-2023.1.0-h06a4308_46344/include/mkl.h"

void spmv(MKL_INT m,
        MKL_INT n,
        float values[],
        MKL_INT row_offsets[],
        MKL_INT column_indices[],
        float x[],
        float y[])
{
        sparse_matrix_t A;
        mkl_sparse_s_create_csr(&A, SPARSE_INDEX_BASE_ZERO, m, n, row_offsets, row_offsets+1, column_indices, values);

        matrix_descr desr;
        desr.type = SPARSE_MATRIX_TYPE_GENERAL;
        mkl_sparse_s_mv(SPARSE_OPERATION_NON_TRANSPOSE, 1.0f, A, desr, x, 0.0f, y);
}


int main() {
    const int M = 3;
    const int N = 3;

    float A[N * (N + 1) / 2] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0};
    int row_offsets[] = {1, 4, 6};
    int column_indices[] = {1, 2, 3, 2, 3, 3};
    float x[N] = {1.0, 2.0, 3.0};
    float y[N] = {0.0};
    
    spmv(M, N, A, row_offsets, column_indices, x, y);
}