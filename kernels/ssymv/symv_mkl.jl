using Finch
using TensorMarket
using JSON
using MKLSparse

function symv_mkl_helper(args, A, x)
    A = SparseMatrixCSC(A)
    (m, n) = size(A)
    y = zeros(m)
    zcolptr = A.colptr .- 1
    ia = pointer(zcolptr)
    zrowval = A.rowval .- 1
    ja = pointer(zrowval)
    px = pointer(x)
    py = pointer(y)
    pm = Ref(m)
    uplo = Ref(Cchar('U'))
    MKLSparse.mkl_dcsrsymv(uplo, pm, a, ia, ja, px, py)
    time = @belapsed MKLSparse.mkl_dcsrsymv($uplo, $pm, $a, $ia, $ja, $px, $py)
    fill!(y, 0)
    MKLSparse.mkl_dcsrsymv(uplo, pm, a, ia, ja, px, py)
    return (;time=time, y=y)
end

symv_mkl(y, A, x) = symv_mkl_helper("", A, x)