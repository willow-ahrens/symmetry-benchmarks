using Finch
using BenchmarkTools

C = Tensor(SparseDict(SparseDict(Element(0.0))))
A = Tensor(Dense(SparseList(Element(0.0))))

include("../../generated/ssyrk.jl")

eval(@finch_kernel mode=:fast function ssyrk_finch_ref_helper(C, A)
    C .= 0
    for k=_, j=_, i=_
        C[i, j] += A[i, k] * A[j, k]
    end
    return C
end)

function ssyrk_finch_opt(C, A)
    _C = Tensor(SparseDict(SparseDict(Element(0.0))), C)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)

    _A2 = [_A]
    _C2 = [_C]
    time = @belapsed ssyrk_finch_opt_helper($_A2[], $_C2[])
    empty!(_A2)
    empty!(_C2)
    C_full = Tensor(SparseDict(SparseDict(Element(0.0))))
    @finch mode=:fast begin
        C_full .= 0
        for j=_, i=_
            if i > j
                C_full[i, j] = _C[j, i]
            end
            if i <= j
                C_full[j, i] = _C[j, i]
            end
        end
    end
    C_final = Tensor(Dense(SparseList(Element(0.0))), C_full)
    return (;time = time, C = C_final)
end

function ssyrk_finch_ref(C, A)
    _C = Tensor(SparseDict(SparseDict(Element(0.0))), C)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)

    C2 = [_C]
    _A2 = [_A]
    _C2 = [_C]
    time = @belapsed $C2[] = ssyrk_finch_ref_helper($_C2[], $_A2[]).C
    C = C2[]
    empty!(C2)
    empty!(_A2)
    empty!(_C2)
    return (;time = time, C = C)
end