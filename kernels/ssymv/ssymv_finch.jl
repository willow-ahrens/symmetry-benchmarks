using Finch
using BenchmarkTools

A = Tensor(Dense(SparseList(Element(0.0))))
x = Tensor(Dense(Element(0.0)))
y = Tensor(Dense(Element(0.0)))
diag = Tensor(Dense(Element(0.0)))
temp = Scalar(0.0)

eval(@finch_kernel mode=:fast function ssymv_finch_opt_helper(y, A, x, diag, temp)
    y .= 0
    for j = _
        let x_j = x[j]
            temp .= 0
            for i = _
                let A_ij = A[i, j]
                    y[i] += x_j * A_ij
                    temp[] += A_ij * x[i]
                end
            end
            y[j] += temp[] + diag[j] * x_j
        end
    end
    return y
end)

eval(@finch_kernel mode=:fast function ssymv_finch_opt_2_helper(y, A, x, diag, temp)
    y .= 0
    for j = _
        for i = _
            let A_ij = A[i, j]
                y[i] += x[j] * A_ij
                y[j] += A_ij * x[i]
            end
        end
        y[j] += diag[j] * x[j]
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
    _x = Tensor(Dense(Element(0.0)), x)
    temp = Scalar(0.0)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _d = Tensor(Dense(Element(0.0)))
    @finch mode=:fast begin
        _A .= 0
        _d .= 0
        for j = _, i = _
            if i < j
                _A[i, j] = A[i, j]
            end
            if i == j
                _d[i] = A[i, j]
            end
        end
    end
    

    y = Ref{Any}()
    time = @belapsed $y[] = ssymv_finch_opt_helper($_y, $_A, $_x, $_d, $temp)
    return (;time = time, y = y[])
end

function ssymv_finch_opt_2(y, A, x) 
    _y = Tensor(Dense(Element(0.0)), y)
    _x = Tensor(Dense(Element(0.0)), x)
    temp = Scalar(0.0)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _d = Tensor(Dense(Element(0.0)))
    @finch mode=:fast begin
        _A .= 0
        _d .= 0
        for j = _, i = _
            if i < j
                _A[i, j] = A[i, j]
            end
            if i == j
                _d[i] = A[i, j]
            end
        end
    end
    

    y = Ref{Any}()
    time = @belapsed $y[] = ssymv_finch_opt_2_helper($_y, $_A, $_x, $_d, $temp)
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