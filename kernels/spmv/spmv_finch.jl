using Finch
using BenchmarkTools

_A = Tensor(Dense(SparseList(Element(0.0))))
_x = Tensor(Dense(Element(0.0)))
_y = Tensor(Dense(Element(0.0)))
_temp = Scalar(0.0)

eval(@finch_kernel mode=fastfinch function spmv_finch_helper(_y, _A, _x, _temp)
    _y .= 0
    for j = _
        let x_j = _x[j]
            _temp .= 0
            for i = _
                let A_ij = _A[i, j]
                    if i <= j
                        _y[i] += x_j * A_ij
                    end
                    if i < j
                        _temp[] += A_ij * _x[i]
                    end
                end
            end
            _y[j] += _temp[]
        end
    end
    return _y
end)

function spmv_finch(y, A, x) 
    _y = Tensor(Dense(Element(0.0)), y)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _x = Tensor(Dense(Element(0.0)), x)
    temp = Scalar(0.0)

    y = Ref{Any}()
    time = @belapsed $y[] = spmv_finch_helper($_y, $_A, $_x, $temp)
    return (;time = time, y = y[])
end