using Finch
using BenchmarkTools

C = Tensor(Dense(Dense(Element(0.0))))
A = Tensor(Dense(SparseList(Element(0.0))))

eval(@finch_kernel mode=fastfinch function ssyrk_finch_ref_helper(C, A)
    C .= 0
    for j=_, k=_, i=_
        C[i, j] += A[i, k] * A[k, j]
    end
    return C
end)

eval(@finch_kernel mode=fastfinch function ssyrk_finch_opt_helper(C, A)
    C .= 0
    for j=_, k=_, i=_
        if i <= j
            C[i, j] += A[i, k] * A[k, j]
        end
    end
    return C
end)

function ssyrk_finch_opt(C, A)
    _C = Tensor(Dense(Dense(Element(0.0))), C)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)

    C = Ref{Any}()
    time = @belapsed $C[] = ssyrk_finch_opt_helper($_C, $_A)
    return (;time = time, C = C[])
end

function ssyrk_finch_ref(C, A)
    _C = Tensor(Dense(Dense(Element(0.0))), C)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)

    C = Ref{Any}()
    time = @belapsed $C[] = ssyrk_finch_ref_helper($_C, $_A)
    return (;time = time, C = C[])
end