using Finch
import Finch.FinchNotation: and, or
using BenchmarkTools

A = Tensor(Dense(SparseList(SparseList(Element(0.0)))))
B_T = Tensor(Dense(Dense(Element(0.0)))) 
C = Tensor(Dense(Dense(Dense(Element(0.0)))))
_C1 = Tensor(Dense(Dense(Dense(Element(0.0)))))

include("../../generated/ttm.jl")

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

    C2 = [_C]
    _C2 = [_C]
    _A2 = [_A]
    _B_T2 = [_B_T]
    time = @belapsed $C2[] = ttm_finch_ref_helper($_C2[], $_A2[], $_B_T2[]).C
    C = C2[]
    empty!(C2)
    empty!(_C2)
    empty!(_A2)
    empty!(_B_T2)
    return (;time = time, C = C)
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

    _A2 = [_A]
    _B_T2 = [_B_T]
    _C2 = [_C]
    time = @belapsed ttm_finch_opt_helper($_A2[], $_B_T2[], $_C2[])
    empty!(_A2)
    empty!(_B_T2)
    empty!(_C2)
    C_full = Tensor(Dense(Dense(Dense(Element(0.0)))), _C)
    @finch mode=:fast for l=_, j=_, i=_
        if j > l
            C_full[i, j, l] = _C[i, l, j]
        end
    end
    return (;time = time, C = C_full)
end