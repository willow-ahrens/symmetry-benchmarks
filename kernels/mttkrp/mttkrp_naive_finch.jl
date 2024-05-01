using Finch
using BenchmarkTools

n = 100
triA = fsprand(Int, n, n, n, 0.1)
symA = [triA[sort([i, j, k])...] for i = 1:n, j = 1:n, k = 1:n]
b = rand(Int, n, n)

A = Tensor(Dense(Dense(Dense(Element(0)))), symA)
B = Tensor(Dense(Dense(Element(0))), b)    
B_T = Tensor(Dense(Dense(Element(0))), transpose(b)) 
C = Tensor(Dense(Dense(Element(0))), zeros(Int, n, n))

eval(@finch_kernel mode=:fast function mttkrp_finch_ref_1(C, A, B)
    C .= 0
    for l=_, j=_, k=_, i=_
        C[i, j] += A[i, k, l] * B[l, j] * B[k, j]
    end
    return C
end)

eval(@finch_kernel mode=:fast function mttkrp_finch_ref_2(C, A, B_T)
    C .= 0
    for l=_, k=_, j=_, i=_
        C[i, j] += A[i, k, l] * B_T[j, l] * B_T[j, k]
    end
    return C
end)

eval(@finch_kernel mode=:fast function mttkrp_finch_ref_3(C, A, B)
    C .= 0
    for j=_, l=_, k=_, i=_
        C[i, j] += A[i, k, l] * B[l, j] * B[k, j]
    end
    return C
end)

eval(@finch_kernel mode=:fast function mttkrp_finch_ref_4(C, A, B_T)
    C .= 0
    for l=_, k=_, i=_, j=_
        C[j, i] += A[i, k, l] * B_T[j, l] * B_T[j, k]
    end
    return C
end)

@btime(mttkrp_finch_ref_1($C, $A, $B))
@btime(mttkrp_finch_ref_2($C, $A, $B))
@btime(mttkrp_finch_ref_3($C, $A, $B))
@btime(mttkrp_finch_ref_4($C, $A, $B))