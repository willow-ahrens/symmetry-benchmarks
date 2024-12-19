eval(@finch_kernel mode=:fast function mttkrp_dim5_finch_opt_helper_base(A_nondiag, B_T, C_T)
    C_T .= 0
    for n = _, m = _, l = _, k = _, i = _, j = _
        if and((i < k), (k < l), (l < m), (m < n))
            let B_T_jl = B_T[j, l], B_T_jm = B_T[j, m], B_T_jk = B_T[j, k], B_T_ji = B_T[j, i], A_iklmn = A_nondiag[i, k, l, m, n], B_T_jn = B_T[j, n]
                C_T[j, n] += *(24, *(B_T_jk, B_T_jm, B_T_jl, A_iklmn, B_T_ji))
                C_T[j, l] += *(24, *(B_T_jk, B_T_jm, B_T_jn, A_iklmn, B_T_ji))
                C_T[j, m] += *(24, *(B_T_jk, B_T_jn, B_T_jl, A_iklmn, B_T_ji))
                C_T[j, k] += *(24, *(B_T_jm, B_T_jn, B_T_jl, A_iklmn, B_T_ji))
                C_T[j, i] += *(24, *(B_T_jk, B_T_jm, B_T_jn, B_T_jl, A_iklmn))
            end
        end
    end
    return C_T
end)

eval(@finch_kernel mode=:fast function mttkrp_dim5_finch_opt_helper_edge(A_diag, B_T, C_T, lookup)
    C_T .= 0
    for n = _, m = _, l = _, k = _, i = _, j = _
        if and((i <= k), (k <= l), (l <= m), (m <= n))
            let B_T_ji = B_T[j, i], B_T_jk = B_T[j, k], A_iklmn = A_diag[i, k, l, m, n], B_T_jm = B_T[j, m], B_T_jl = B_T[j, l], B_T_jn = B_T[j, n]
                let idx = +(+(+(*(2, (i == k)), *(3, (k == l))), *(5, (identity(l) == identity(m)))), *(7, (identity(m) == identity(n)))), factor = lookup[idx]
                    C_T[j, n] += *(factor, *(B_T_jk, B_T_jm, B_T_jl, A_iklmn, B_T_ji))
                    C_T[j, k] += *(factor, *(B_T_jm, B_T_jn, B_T_jl, A_iklmn, B_T_ji))
                    C_T[j, i] += *(factor, *(B_T_jk, B_T_jm, B_T_jn, B_T_jl, A_iklmn))
                    C_T[j, l] += *(factor, *(B_T_jk, B_T_jm, B_T_jn, A_iklmn, B_T_ji))
                    C_T[j, m] += *(factor, *(B_T_jk, B_T_jn, B_T_jl, A_iklmn, B_T_ji))
                end
            end
        end
    end
    return C_T
end)

lookup = [0.0, 12.0, 12.0, 0.0, 12.0, 4.0, 12.0, 0.0, 0.0, 6.0, 0.0, 0.0, 0.0, 6.0, 4.0,
0.0, 0.0, 0.0, 0.0, 0.0, 6.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0,
0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2]