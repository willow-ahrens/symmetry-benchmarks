using Finch
using BenchmarkTools

C = Tensor(SparseHash{2}(Element(0.0)))
A = Tensor(Dense(SparseList(Element(0.0))))

include("../../SySTeC/generated/ssyrk.jl")

eval(@finch_kernel mode=:fast function ssyrk_finch_ref_helper(C, A)
    C .= 0
    for k=_, j=_, i=_
        C[i, j] += A[i, k] * A[j, k]
    end
    return C
end)

function ssyrk_finch_opt(C, A)
    _C = Tensor(SparseHash{2}(Element(0.0)), C)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)

    time = @belapsed ssyrk_finch_opt_helper($_A, $_C)
    C_full = Tensor(Dense(Dense(Element(0.0))))
    @finch mode=:fast begin
        C_full .= 0
        for j=_, i=_
            if i > j
                C_full[i, j] = _C[j, i]
            end
            if i <= j
                C_full[i, j] = _C[i, j]
            end
        end
    end
    C_final = Tensor(Dense(SparseList(Element(0.0))), C_full)
    return (;time = time, C = C_final)
end

function ssyrk_finch_ref(C, A)
    _C = Tensor(SparseHash{2}(Element(0.0)), C)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)

    C = Ref{Any}()
    time = @belapsed $C[] = ssyrk_finch_ref_helper($_C, $_A)
    return (;time = time, C = C[])
end