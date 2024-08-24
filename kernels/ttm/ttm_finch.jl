using Finch
import Finch.FinchNotation: and, or
using BenchmarkTools

A = Tensor(Dense(SparseList(SparseList(Element(0.0)))))
B_T = Tensor(Dense(Dense(Element(0.0)))) 
C = Tensor(Dense(Dense(Dense(Element(0.0)))))
_C1 = Tensor(Dense(Dense(Dense(Element(0.0)))))

include("../../SySTeC/generated/ttm.jl")

eval(@finch_kernel mode=:fast function ttm_finch_ref_helper(C, A, B_T)
    C .= 0
    for l=_, j=_, k=_, i=_
        C[i, j, l] += A[k, j, l] * B_T[i, k]
    end
    return C
end)

function ttm_finch_ref(C, A, B)
    _C = Tensor(Dense(Dense(Dense(Element(0.0)))), C)
    _A = Tensor(Dense(SparseList(SparseList(Element(0.0)))), A)
    _B_T = Tensor(Dense(Dense(Element(0.0))))
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end 

    C = Ref{Any}()
    time = @belapsed $C[] = ttm_finch_ref_helper($_C, $_A, $_B_T)
    return (;time = time, C = C[])
end

function ttm_finch_opt(C, A, B)
    _C = Tensor(Dense(Dense(Dense(Element(0.0)))), C)
    _A = Tensor(Dense(SparseList(SparseList(Element(0.0)))), A)
    _B_T = Tensor(Dense(Dense(Element(0.0))))
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end

    time = @belapsed ttm_finch_opt_helper($_A, $_B_T, $_C)
    C_full = Tensor(Dense(Dense(Dense(Element(0.0)))), _C)
    @finch mode=:fast for l=_, j=_, i=_
        if j > l
            C_full[i, j, l] = _C[i, l, j]
        end
    end
    return (;time = time, C = C_full)
end