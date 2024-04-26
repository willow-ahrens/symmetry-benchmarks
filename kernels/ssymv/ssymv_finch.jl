using Finch
using BenchmarkTools

A = Tensor(Dense(SparseList(Element(0.0))))
x = Tensor(Dense(Element(0.0)))
y = Tensor(Dense(Element(0.0)))
temp = Scalar(0.0)

eval(@finch_kernel mode=:fast function ssymv_finch_opt_helper(y, A, x, temp)
    y .= 0
    for j = _
        temp .= 0
        for i = _
            let A_ij = A[i, j]
                if i <= j
                    y[i] += x[j] * A_ij
                end
                if i < j
                    temp[] += A_ij * x[i]
                end
            end
        end
        y[j] += temp[]
    end
    return y
end)

eval(@finch_kernel mode=:fast function ssymv_finch_ref_helper(y, A, x)
    y .= 0
    for j = _, i = _
        y[i] += A[i, j] * x[j]
    end
    return y
end)

function ssymv_finch_opt(y, A, x) 
    _y = Tensor(Dense(Element(0.0)), y)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _x = Tensor(Dense(Element(0.0)), x)
    temp = Scalar(0.0)

    y = Ref{Any}()
    time = @belapsed $y[] = ssymv_finch_opt_helper($_y, $_A, $_x, $temp)
    return (;time = time, y = y[])
end

function ssymv_finch_ref(y, A, x) 
    _y = Tensor(Dense(Element(0.0)), y)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _x = Tensor(Dense(Element(0.0)), x)

    y = Ref{Any}()
    time = @belapsed $y[] = ssymv_finch_ref_helper($_y, $_A, $_x)
    return (;time = time, y = y[])
end