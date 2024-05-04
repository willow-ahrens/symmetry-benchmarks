using Finch
using BenchmarkTools

A = Tensor(Dense(SparseList(SparseList(Element(0.0)))))
A_nondiag = Tensor(Dense(SparseList(SparseList(Element(0.0)))))
A_diag = Tensor(Dense(SparseList(SparseList(Element(0.0)))))
B_T = Tensor(Dense(Dense(Element(0.0)))) 
C = Tensor(Dense(Dense(Dense(Element(0.0)))))

eval(@finch_kernel mode=:fast function ttm_finch_ref_helper(C, A, B_T)
    C .= 0
    for l=_, j=_, k=_, i=_
        C[i, j, l] += A[k, j, l] * B_T[i, k]
    end
    return C
end)

# eval(@finch_kernel mode=:fast function ttm_finch_opt_helper(C, A, B_T)
#     C .= 0
#     for l=_, k=_, j=_, i=_
#         let jk_leq = (j <= k), kl_leq = (k <= l)
#             let A_jkl = A[j, k, l]
#                 if jk_leq && kl_leq
#                     C[i, j, k] += A_jkl * B_T[i, l]
#                 end
#                 if j < k && kl_leq
#                     C[i, k, l] += A_jkl * B_T[i, j]
#                 end
#                 if jk_leq && k < l
#                     C[i, j, l] += A_jkl * B_T[i, k]
#                 end
#             end
#         end
#     end
#     return C
# end)

eval(@finch_kernel mode=:fast function ttm_finch_opt_1_helper(C, A_nondiag, B_T)
    C .= 0
    for l=_, k=_, j=_, i=_
        let A_jkl = A_nondiag[j, k, l], B_ik = B_T[i, k], B_il = B_T[i, l], B_ij = B_T[i, j]
            if j < k && k < l
                C[i, j, l] += A_jkl * B_ik
                C[i, j, k] += B_il * A_jkl
                C[i, k, l] += B_ij * A_jkl
            end
        end
    end
end)

eval(@finch_kernel mode=:fast function ttm_finch_opt_2_helper(C, A_diag, B_T)
    C .= 0
    for l=_, k=_, j=_, i=_
        if j <= k && k <= l
            let jk_eq = (identity(j) == identity(k)), kl_eq = (identity(k) == identity(l))
                let A_jkl = A_diag[j, k, l], B_ik = B_T[i, k], B_il = B_T[i, l], B_ij = B_T[i, j]
                    if (jk_eq && !kl_eq ) || (!jk_eq  && kl_eq)
                        C[i, j, k] += B_il * A_jkl
                        C[i, l, j] += A_jkl * B_ik
                        C[i, k, l] += B_ij * A_jkl
                    end
                    if jk_eq && kl_eq
                        C[i, l, j] += A_jkl * B_ik
                    end
                end
            end
        end
    end
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
    _C_nondiag = Tensor(Dense(Dense(Dense(Element(0.0)))), C)
    _C_diag = Tensor(Dense(Dense(Dense(Element(0.0)))), C)

    _A = Tensor(Dense(SparseList(SparseList(Element(0.0)))), A)
    nondiagA = zeros(n, n, n)
    diagA = zeros(n, n, n)
    for k=1:n, j=1:n, i=1:n
        if i != j && j != k && i != k
            nondiagA[i, j, k] = A[i, j, k]
        end
        if i == j || j == k || i == k
            diagA[i, j, k] = A[i, j, k]
        end
    end
    _A_nondiag = Tensor(Dense(SparseList(SparseList(Element(0.0)))), nondiagA)
    _A_diag = Tensor(Dense(SparseList(SparseList(Element(0.0)))), diagA)

    _B_T = Tensor(Dense(Dense(Element(0.0))))
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end

    time_1 = @belapsed ttm_finch_opt_1_helper($_C_nondiag, $_A_nondiag, $_B_T)
    time_2 = @belapsed ttm_finch_opt_2_helper($_C_diag, $_A_diag, $_B_T)
    C_full = Tensor(Dense(Dense(Dense(Element(0.0)))), C)
    @finch mode=:fast for l=_, j=_, i=_
        if j > l
            C_full[i, j, l] = _C_nondiag[i, l, j] + _C_diag[i, l, j]
        end
        if j <= l
            C_full[i, j, l] = _C_nondiag[i, j, l] + _C_diag[i, j, l]
        end
    end
    return (;time = time_1 + time_2, nondiag_time = time_1, diag_time = time_2, C = C_full)
end