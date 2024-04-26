using Finch
using BenchmarkTools

A = Tensor(Dense(SparseList(Element(0.0))))
B = Tensor(Dense(Dense(Element(0.0))))
B_T = Tensor(Dense(Dense(Element(0.0))))
C = Tensor(Dense(Dense(Element(0.0))))
C_T = Tensor(Dense(Dense(Element(0.0))))

eval(@finch_kernel mode=:fast function ssymm_finch_opt_helper(C_T, A, B_T)
    C_T .= 0
    for k=_, i=_, j=_
        let A_ik = A[i, k]
            if i <= k
                C_T[j, i] += A_ik * B_T[j, k]
            end
            if i < k
                C_T[j, k] += A_ik * B_T[j, i]
            end
        end
    end
    return C_T
end)

eval(@finch_kernel mode=:fast function ssymm_finch_ref_helper(C, A, B)
    C .= 0
    for j=_, k=_, i=_
        C[i, j] += A[i, k] * B[k, j]
    end
    return C
end)

function ssymm_finch_opt(C, A, B)
    _C_T = Tensor(Dense(Dense(Element(0.0))), C)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _B_T = Tensor(Dense(Dense(Element(0.0))))
    @finch begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end

    time = @belapsed ssymm_finch_opt_helper($_C_T, $_A, $_B_T)
    _C = Tensor(Dense(Dense(Element(0.0))), C)
    @finch begin 
        _C .= 0
        for j=_, i=_ 
            _C[j, i] = _C_T[i, j] 
        end
    end
    return (;time = time, C = _C)
end

function ssymm_finch_ref(C, A, B)
    _C = Tensor(Dense(Dense(Element(0.0))), C)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _B = Tensor(Dense(Dense(Element(0.0))), B)
    temp = Scalar(0.0)

    C = Ref{Any}()
    time = @belapsed $C[] = ssymm_finch_ref_helper($_C, $_A, $_B)
    return (;time = time, C = C[])
end