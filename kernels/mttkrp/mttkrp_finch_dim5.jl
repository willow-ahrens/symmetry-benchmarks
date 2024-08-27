using Finch
import Finch.FinchNotation: and, or
using BenchmarkTools

A = Tensor(Dense(SparseList(SparseList(SparseList(SparseList(Element(0.0)))))))
A_nondiag = Tensor(Dense(SparseList(SparseList(SparseList(SparseList(Element(0.0)))))))
A_diag = Tensor(Dense(Dense(SparseList(SparseList(SparseList(Element(0.0)))))))
B = Tensor(Dense(Dense(Element(0.0))))   
B_T = Tensor(Dense(Dense(Element(0.0)))) 
C = Tensor(Dense(Dense(Element(0.0))))
C_T = Tensor(Dense(Dense(Element(0.0))))
lookup = [0.0]

include("../../generated/mttkrp_dim5.jl")

eval(@finch_kernel mode=:fast function mttkrp_finch_ref_dim5_helper(C_T, A, B_T)
    C_T .= 0
    for n=_, m=_, l=_, k=_, i=_, j=_
        C_T[j, i] += A[i, k, l, m, n] * B_T[j, l] * B_T[j, k] * B_T[j, m] * B_T[j, n]
    end
    return C_T
end)

# eval(@finch_kernel mode=:fast function mttkrp_finch_opt_1_dim5_helper(C_T, A_nondiag, B_T)
#     C_T .= 0
#     for n=_, m=_, l=_, k=_, i=_, j=_
#         if i < k && k < l && l < m && m < n
#             let A_iklmn = A_nondiag[i, k, l, m, n], B_T_jl = B_T[j, l], B_T_jk = B_T[j, k], B_T_ji = B_T[j, i], B_T_jm = B_T[j, m], B_T_jn = B_T[j, n]
#                 C_T[j, i] += 24 * B_T_jl * A_iklmn * B_T_jk * B_T_jm * B_T_jn
#                 C_T[j, l] += 24 * A_iklmn * B_T_jk * B_T_ji * B_T_jm * B_T_jn
#                 C_T[j, k] += 24 * B_T_jl * A_iklmn * B_T_ji * B_T_jm * B_T_jn
#                 C_T[j, n] += 24 * B_T_jl * A_iklmn * B_T_jk * B_T_ji * B_T_jm
#                 C_T[j, m] += 24 * B_T_jl * A_iklmn * B_T_jk * B_T_ji * B_T_jn
#             end
#         end
#     end
#     return C_T
# end)

# eval(@finch_kernel mode=:fast function mttkrp_finch_opt_2_dim5_helper(C_T, A_diag, B_T, lookup)
#     C_T .= 0
#     for n=_, m=_, l=_, k=_, i=_, j=_
#         if i <= k && k <= l && l <= m && m <= n
#             let ik_eq = (i == k), mn_eq = (m == n), kl_eq = (identity(k) == identity(l)), lm_eq = (identity(l) == identity(m))
#                 let A_iklmn = A_diag[i, k, l, m, n], B_T_jl = B_T[j, l], B_T_jk = B_T[j, k], B_T_ji = B_T[j, i], B_T_jm = B_T[j, m], B_T_jn = B_T[j, n]
#                     let idx = (ik_eq) * 2 + (kl_eq) * 3 + (lm_eq) * 5 + (mn_eq) * 7 + 1
#                         let factor = lookup[idx]
#                             C_T[j, i] += factor * B_T_jl * A_iklmn * B_T_jk * B_T_jm * B_T_jn
#                             C_T[j, l] += factor * A_iklmn * B_T_jk * B_T_ji * B_T_jm * B_T_jn
#                             C_T[j, k] += factor * B_T_jl * A_iklmn * B_T_ji * B_T_jm * B_T_jn
#                             C_T[j, n] += factor * B_T_jl * A_iklmn * B_T_jk * B_T_ji * B_T_jm
#                             C_T[j, m] += factor * B_T_jl * A_iklmn * B_T_jk * B_T_ji * B_T_jn
#                         end
#                     end
#                 end
#             end
#         end
#     end
#     return C_T
# end)

function mttkrp_finch_ref_dim5(C, A, B)
    (n, r) = size(C)
    _C_T = Tensor(Dense(Dense(Element(0.0))), zeros(r, n))
    _A = Tensor(Dense(SparseList(SparseList(SparseList(SparseList(Element(0.0)))))), A)  
    _B_T = Tensor(Dense(Dense(Element(0.0))), B) 
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end  

    _C_T2 = [_C_T]
    _A2 = [_A]
    _B_T2 = [_B_T]
    time = @belapsed mttkrp_finch_ref_dim5_helper($_C_T2[], $_A2[], $_B_T2[])
    empty!(_C_T2)
    empty!(_A2)
    empty!(_B_T2)

    _C = Tensor(Dense(Dense(Element(0.0))), C)
    @finch begin 
        _C .= 0
        for j=_, i=_
            _C[i, j] = _C_T[j, i]
        end
    end
    
    return (;time = time, C = _C)
end

function mttkrp_finch_opt_dim5(C, A, B)
    (n, n, n, n) = size(A)
    (n, r) = size(C)
    _C_T_nondiag = Tensor(Dense(Dense(Element(0.0))), zeros(r, n))
    _C_T_diag = Tensor(Dense(Dense(Element(0.0))), zeros(r, n))

    nondiagA = zeros(n, n, n, n, n)
    diagA = zeros(n, n, n, n, n)
    for m=1:n, l=1:n, k=1:n, j=1:n, i=1:n
        if i != j && j != k && k != l && l != m && i != k && i != l && i != m && j != l && j != m && k != m
            nondiagA[i, j, k, l, m] = A[i, j, k, l, m]
        end
        if i == j || j == k || k == l || l == m || i == k || i == l || i == m || j == l || j == m || k == m
            diagA[i, j, k, l, m] = A[i, j, k, l, m]
        end
    end
    _A_nondiag = Tensor(Dense(SparseList(SparseList(SparseList(SparseList(Element(0.0)))))), nondiagA)
    _A_diag = Tensor(Dense(Dense(SparseList(SparseList(SparseList(Element(0.0)))))), diagA)

    _B_T = Tensor(Dense(Dense(Element(0.0))), B) 
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end


    # lookup = Tensor(Dense(Element(0.0)), zeros(211))
    # lookup[2 + 1] = 12
    # lookup[3 + 1] = 12
    # lookup[5 + 1] = 12
    # lookup[7 + 1] = 12
    # lookup[10 + 1] = 6
    # lookup[21 + 1] = 6
    # lookup[14 + 1] = 6
    # lookup[6 + 1] = 4
    # lookup[15 + 1] = 4
    # lookup[35 + 1] = 4
    # lookup[42 + 1] = 2
    # lookup[70 + 1] = 2
    # lookup[30 + 1] = 1
    # lookup[105 + 1] = 1
    # lookup[210 + 1] = 0.2
    _A_nondiag2 = [_A_nondiag]
    _A_diag2 = [_A_diag]
    _B_T2 = [_B_T]
    _C_T_nondiag2 = [_C_T_nondiag]
    _C_T_diag2 = [_C_T_diag]
    time_1 = @belapsed mttkrp_dim5_finch_opt_helper_base($_A_nondiag2[], $_B_T2[], $_C_T_nondiag2[])
    time_2 = @belapsed mttkrp_dim5_finch_opt_helper_edge($_A_diag2[], $_B_T2[], $_C_T_diag2[], $lookup)
    empty!( _A_nondiag2)
    empty!(_A_diag2)
    empty!(_B_T2)
    empty!(_C_T_nondiag2)
    empty!(_C_T_diag2)
    C_full = Tensor(Dense(Dense(Element(0.0))), C)
    @finch mode=:fast for i=_, j=_
        C_full[i, j] = _C_T_nondiag[j, i] + _C_T_diag[j, i]
    end
    return (;time = time_1 + time_2, C = C_full, nondiag_time = time_1, diag_time = time_2)
end