using Finch
using BenchmarkTools

eval(@finch_kernel mode=fastfinch function spmv_finch_helper(y, A, x, temp)
    y .= 0
    for j = _
        let temp1 = x[j]
            temp .= 0
            for i = _
                let temp3 = A[i, j]
                    if i <= j
                        y[i] += temp1 * temp3
                    end
                    if i < j
                        temp[] += temp3 * x[i]
                    end
                end
            end
            y[j] += temp[]
        end
    end
    y
end)

function spmv_finch(y, A, x) 
    _y = Tensor(Dense(Element(0.0)), y)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _x = Tensor(Dense(Element(0.0)), x)
    temp = Scalar(0.0)

    y = Ref{Any}()
    time = @belapsed $y[] = spmv_finch_helper($y, $A, $x, $temp)
    return (;time = time, y = y[])
end