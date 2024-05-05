using Finch
using BenchmarkTools

A = Tensor(Dense(SparseList(Element(0.0))))
x = Tensor(Dense(Element(0.0)))
y = Scalar(0.0)

eval(@finch_kernel mode=:fast function syprd_finch_ref_helper(y, A, x)
    y .= 0
    for j=_, i=_
        y[] += x[i] * A[i, j] * x[j]
    end
    return y
end)

eval(@finch_kernel mode=:fast function syprd_finch_opt_helper(y, A, x)
    y .= 0
    for j=_, i=_
        let x_i = x[i], A_ij = A[i, j], x_j = x[j]
            if i < j
                y[] += 2 * A_ij * x_i * x_j
            end
            if i == j
                y[] += A_ij * x_i * x_j
            end
        end
    end
    return y
end)

function syprd_finch_ref(y, A, x)
    _y = Scalar(0.0)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _x = Tensor(Dense(Element(0.0)), x)

    y = Ref{Any}()
    time = @belapsed $y[] = syprd_finch_ref_helper($_y, $_A, $_x)
    return (;time = time, y = y[])
end

function syprd_finch_opt(y, A, x)
    _y = Scalar(0.0)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _x = Tensor(Dense(Element(0.0)), x)

    y = Ref{Any}()
    time = @belapsed $y[] = syprd_finch_opt_helper($_y, $_A, $_x)
    return (;time = time, y = y[])
end
