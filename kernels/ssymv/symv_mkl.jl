using Finch
using TensorMarket
using JSON
using MKLSparse

foo = IdDict()

function symv_mkl_helper(args, A, x)
    global foo
    A = SparseMatrixCSC(A)
    foo[A] = A
    (m, n) = size(A)
    y = zeros(m)
    a = pointer(A.nzval)
    zcolptr = A.colptr .- 0
    foo[zcolptr] = zcolptr
    ia = pointer(zcolptr)
    zrowval = A.rowval .- 0
    foo[zrowval] = zrowval
    ja = pointer(zrowval)
    px = pointer(x)
    py = pointer(y)
    pm = Ref(m)
    uplo = Ref(Cchar('L'))
    MKLSparse.mkl_dcsrsymv(uplo, pm, a, ia, ja, px, py)
    println("Hello")
    time = @belapsed MKLSparse.mkl_dcsrsymv($uplo, $pm, $a, $ia, $ja, $px, $py)
    fill!(y, 0)
    MKLSparse.mkl_dcsrsymv(uplo, pm, a, ia, ja, px, py)
    empty!(foo)
    return (;time=time, y=y)
end

symv_mkl(y, A, x) = symv_mkl_helper("", A, x)
