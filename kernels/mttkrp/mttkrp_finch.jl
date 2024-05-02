using Finch
using BenchmarkTools

A = Tensor(Dense(SparseList(SparseList(Element(0.0)))))
A_nondiag = Tensor(Dense(SparseList(SparseList(Element(0.0)))))
A_diag = Tensor(Dense(SparseList(SparseList(Element(0.0)))))
B = Tensor(Dense(Dense(Element(0.0))))   
B_T = Tensor(Dense(Dense(Element(0.0)))) 
C = Tensor(Dense(Dense(Element(0.0))))
C_T = Tensor(Dense(Dense(Element(0.0))))

eval(@finch_kernel mode=:fast function mttkrp_finch_ref_helper(C_T, A, B_T)
    C_T .= 0
    for l=_, k=_, i=_, j=_
        C_T[j, i] += A[i, k, l] * B_T[j, l] * B_T[j, k]
    end
    return C_T
end)

eval(@finch_kernel mode=:fast function mttkrp_finch_opt_1_helper(C_T, A_nondiag, B_T)
    C_T .= 0
    for l=_, k=_, i=_, j=_
        if i < k && k < l 
            let B_ij = B_T[j, i], A_ikl = A_nondiag[i, k, l], B_kj = B_T[j, k], B_lj = B_T[j, l]
                C_T[j, l] += 2 * B_kj * B_ij * A_ikl
                C_T[j, k] += 2 * B_lj * B_ij * A_ikl
                C_T[j, i] += 2 * B_kj * B_lj * A_ikl
            end
        end
    end
    return C_T
end)

eval(@finch_kernel mode=:fast function mttkrp_finch_opt_2_helper(C_T, A_diag, B_T)
    C_T .= 0
    for l=_, k=_, i=_, j=_
        if identity(i) <= identity(k) && identity(k) <= identity(l) 
            let ik_eq = (i == k), kl_eq = (k == l)
                let B_ij = B_T[j, i], A_ikl = A_diag[i, k, l], B_kj = B_T[j, k], B_lj = B_T[j, l]
                    if (ik_eq && !kl_eq) || (!ik_eq && kl_eq)
                        C_T[j, i] += B_kj * B_lj * A_ikl
                        C_T[j, i] += B_lj * B_ij * A_ikl
                        C_T[j, i] += B_kj * B_ij * A_ikl
                    end
                    if ik_eq && kl_eq 
                        C_T[j, i] += B_kj * B_lj * A_ikl
                    end
                end
            end
        end
    end
    return C_T
end)

function mttkrp_finch_ref(C, A, B)
    _C_T = Tensor(Dense(Dense(Element(0.0))), C)
    _A = Tensor(Dense(SparseList(SparseList(Element(0.0)))), A)  
    _B_T = Tensor(Dense(Dense(Element(0.0))), B) 
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end  

    time = @belapsed mttkrp_finch_ref_helper($_C_T, $_A, $_B_T)
    _C = Tensor(Dense(Dense(Element(0.0))), C)
    @finch begin 
        _C .= 0
        for j=_, i=_
            _C[i, j] = _C_T[j, i]
        end
    end
    
    return (;time = time, C = _C)
end

function mttkrp_finch_opt(C, A, B)
    (n, n, n) = size(A)
    _C_T_nondiag = Tensor(Dense(Dense(Element(0.0))), C)
    _C_T_diag = Tensor(Dense(Dense(Element(0.0))), C)

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

    _B_T = Tensor(Dense(Dense(Element(0.0))), B) 
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end

    time_1 = @belapsed mttkrp_finch_opt_1_helper($_C_T_nondiag, $_A_nondiag, $_B_T)
    time_2 = @belapsed mttkrp_finch_opt_2_helper($_C_T_diag, $_A_diag, $_B_T)
    C_full = Tensor(Dense(Dense(Element(0.0))), C)
    @finch mode=:fast for i=_, j=_
        C_full[i, j] = _C_T_nondiag[j, i] + _C_T_diag[j, i]
    end
    return (;time = time_1 + time_2, C = C_full)
end