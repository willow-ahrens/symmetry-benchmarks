eval(@finch_kernel mode=:fast function ssysyrk_finch_opt_helper_base(A_nondiag, _C1)
    _C1 .= 0
    for k = _, j = _, i = _
        if and((i < j), (j < k))
            let A_jk = A_nondiag[j, k], A_ij = A_nondiag[i, j], A_ik = A_nondiag[i, k]
                _C1[i, k] += *(A_ij, A_jk)
                _C1[j, k] += *(A_ik, A_ij)
                _C1[i, j] += *(A_ik, A_jk)
            end
        end
    end
    return _C1
end)

eval(@finch_kernel mode=:fast function ssysyrk_finch_opt_helper_edge(A_diag, _C1)
    _C1 .= 0
    for k = _, j = _, i = _
        if and((identity(i) <= identity(j)), (identity(j) <= identity(k)))
            let jk_eq = (j == k), ij_eq = (i == j), A_jk = A_diag[j, k], A_ij = A_diag[i, j], A_ik = A_diag[i, k]
                if and(ij_eq, !jk_eq)
                    _C1[i, k] += *(A_ij, A_jk)
                    _C1[i, j] += *(A_ik, A_jk)
                end
                if and(!ij_eq, jk_eq)
                    _C1[j, k] += *(A_ik, A_ij)
                    _C1[i, j] += *(A_ik, A_jk)
                end
                if and(ij_eq, jk_eq)
                    _C1[i, j] += *(A_ik, A_jk)
                end
            end
        end
    end
    return _C1
end)

