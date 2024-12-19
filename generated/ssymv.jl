eval(@finch_kernel mode=:fast function ssymv_finch_opt_helper(A, diag, temp, x, y)
    y .= 0
    for j = _
        temp .= 0
        for i = _
            let A_ij = A[i, j]
                temp[] += *(A_ij, x[i])
                y[i] += *(A_ij, x[j])
            end
        end
        y[j] += *(diag[j], x[j])
        y[j] += temp[]
    end
    return y
end)

