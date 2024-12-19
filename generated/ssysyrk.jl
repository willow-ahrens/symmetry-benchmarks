eval(@finch_kernel mode=:fast function ssysyrk_finch_opt_helper(A, _B1)
    _B1 .= 0
    for k = _, j = _, i = _
        let A_ij = A[i, j], A_ik = A[i, k], A_jk = A[j, k]
            if and((i < j), (j < k))
                _B1[i, k] += *(A_ij, A_jk)
                _B1[i, j] += *(A_ik, A_jk)
                _B1[j, k] += *(A_ik, A_ij)
            end
        end
    end
    return _B1
end)

